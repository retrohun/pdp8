#!/bin/bash
#
# Simple PDP5/PDP8 emulator v0.8
#
memory=(0{,,,}{,,,}{,,,}{,,,}{,,,}{,,,})  # Memory array - 4kW
pc=0             # Program counter
lac=0            # L = carry, AC = accumulator "13 bit integer"
hlt=0            # Halt "flag"
keycode=0        # Keycode, for input device #3, TBD

echo '
Simple PDP5/PDP8 emulator v0.8
by NASZVADI Peter, 1980-2018

(: Now in bash :)

For non-commercial use only.

Loading vintage helloworld.pal
'
source siralom.pal
echo '
Press enter or wait 5 seconds!
'
read -d '' -n 1 -r -s -t 5
echo '
Running vintage helloworld.pal
'

while ((!hlt)); do
# uncomment next line if want virtual keyboard input /untested, SLOW!/
#    ((!keycode))&&keycode=$(printf %d "'$(read -d '' -n 1 -r -t 0.01)")
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
        4) ((pc+=f0,f2))&&printf '\x'"$(printf %x $[lac&0177])" ;;
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
done
