#!/bin/bash
#
# Simple PDP5/PDP8 emulator v0.9
#
memory=(0{,,,}{,,,}{,,,}{,,,}{,,,}{,,,})  # Memory array - 4kW
pc=0             # Program counter
lac=0            # L = carry, AC = accumulator "13 bit integer"
hlt=1            # Halt "flag"
keycode=0        # Keycode, for input device #3, TBD
prompt=1         # View interactive prompt "flag"
dumpaddress=-1   # Initial dump address
helptext='[
 G[address]       run from specified address otherwise from pc
 H                this help text
 L[value]         toggle/assign value to l flag
 P<address>       change pc value
 Q                exit program
 R                toggle pRompt view
 S                execute one step
 T <filename>     directly load ram data stored in specified tapedump file
 =<value>         enter l+ac value
 ?                this help text
 . <filename>     source (insert) shellscript
]'
dumptext='[
 %04o: %04o %04o %04o %04o  %04o %04o %04o %04o
 %04o: %04o %04o %04o %04o  %04o %04o %04o %04o
]
'
readtext='[memory[pc]=%04o pc=%04o l+ac=%05o keycode=%03o]
[Enter pdp8 debugger command]:'
erortext="[
 ERROR: unrecognized command: '%q'
 enter '?' for some help
]
"
echo '
Simple PDP5/PDP8 emulator v0.9
by NASZVADI Peter, 1980-2018

(: Now in bash :)

For non-commercial use only.
'

while :; do
    lineprev="${linecurr:-${lineprev}}"
    if ((prompt));then
        printf "$readtext" "${memory[$pc]}" "$pc" "$lac" "$keycode"
        read -r linecurr
    else
        read -d '' -n1 -r -s linecurr
    fi
    linecurr="${linecurr## }"
    linecurr="${linecurr^}"
    case "$linecurr" in
    '') hlt=1;if [[ ${lineprev^} = S ]];then step=1;hlt=0; fi ;;
    D)  hlt=1;((dumpaddress=(dumpaddress<0)?(pc&07770):((dumpaddress+020)&07777)));
        printf "$dumptext" $((dumpaddress)) ${memory[@]:$dumpaddress:8} \
                         $((dumpaddress+8)) ${memory[@]:$((dumpaddress+8)):8} ;;
    D*) hlt=1;dumpaddress=$((${linecurr#D}&07770));
        printf "$dumptext" $((dumpaddress)) ${memory[@]:$dumpaddress:8} \
                         $((dumpaddress+8)) ${memory[@]:$((dumpaddress+8)):8} ;;
    G)  lineprev='';step=0;hlt=0;dumpaddress=-1 ;;
    G*) lineprev='';pc=$((${linecurr#G}));step=0;hlt=0;dumpaddress=-1 ;;
    L0) ((lac&=07777));hlt=1;step=0;dumpaddress=-1 ;;
    L1) ((lac|=010000));hlt=1;step=0;dumpaddress=-1 ;;
    L*) ((lac^=010000));hlt=1;step=0;dumpaddress=-1 ;;
    P*) pc=$((${linecurr#P}));hlt=1;step=0;dumpaddress=-1 ;;
    R*) ((prompt^=1));hlt=1;step=0;dumpaddress=-1 ;;
    Q*) break ;;
    S*) step=1;hlt=0;lineprev=S;dumpaddress=-1 ;;
    T*) hlt=1;echo '[ERROR: not implemented yet]';step=0;dumpaddress=-1 ;;
    '. '*) step=0;hlt=1;dumpaddress=-1;eval "$linecurr" ;;
    \?*|H*) echo "$helptext";hlt=1;step=0 ;;
    =*) lac=$((${linecurr#=}));hlt=1;step=0;dumpaddress=-1 ;;
    *)  hlt=1;printf "$erortext" "$linecurr" ;;
    esac
    while ((!hlt)); do
        : read -d '' -n1 -r -s -t 0
        if ((!keycode));then
            read -d '' -n 1 -r -s -t 0.005 dev3
            ((keycode=keycode?keycode:$(printf %d "'$dev3")))
        fi
        ((
            pc=pc&07777, f8=memory[pc], device=f8>>3&077,
            f0=f8&1,     f1=f8>>1&1,    f2=f8>>2&1,
            f3=f8>>3&1,  f4=f8>>4&1,    f5=f8>>5&1,
            f6=f8>>6&1,  f7=f8>>7&1,    f8=f8>>8&1,
            address=(pc&(f7*07600))|(memory[pc]&0177),
            operand=memory[pc]>>9
        ))
        if((f8&&operand<6)) # Indirect addressing
        then
            (((address&07770)==010))&&((memory[address]=memory[address]+1&07777))
            ((address=memory[address]))
        fi
        case $operand in
        0) ((memory[address]&=lac,++pc)) ;; # AND
        1) ((lac+=memory[address],lac&=017777,++pc)) ;; # TAD
        2) ((++memory[address],memory[address]&=07777,pc+=1+!memory[address])) ;; # ISZ
        3) ((memory[address]=lac&07777,lac&=010000,++pc)) ;; # DCA
        4) ((memory[address]=pc+1&07777,pc=address+1)) ;; # JMS
        5) ((pc=address)) ;; # JMP
        6)  case $device in # I/O
            3)  ((pc+=keycode&&f0))
                ((f2&&(lac=keycode&0177|0200|(f1?lac&010000:lac))))
                ((f1))&&keycode=0
            ;;
            4) ((pc+=f0,f2))&&printf '\x'"$(printf %x $((lac&0177)))" ;;
            esac
            ((++pc))
        ;;
        7)  if ((f8))
            then
                if ((f0))
                then
                    ((++pc))
                else
                    ((
                        pc=pc+1+(((f6&!!(lac&04000))|(f5&!(lac&07777))|(f4&!!(lac&010000)))^f3),
                        hlt=f1,
                        (f7&&(lac&=010000))
                    ))
                fi
            else
                ((
                    lac&=f7?010000:017777, lac&=f6?07777:017777,
                    lac^=f5?007777:0,      lac^=f4?010000:0,
                    lac=f0+lac&017777,     lac=f3?((lac&1)<<12)|lac>>1:lac,
                    lac=(f1&&f3)?((lac&1)<<12)|lac>>1:lac,
                    lac=f2?((lac<<1)|(lac>>12))&017777:lac,
                    lac=(f1&&f2)?((lac<<1)|(lac>>12))&017777:lac,
                    ++pc
                ))
            fi
        ;;
        esac
        if((step));then
            ((pc&=07777))
            break
        fi
    done
done
