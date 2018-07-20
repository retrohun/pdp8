# Simple PDP5/PDP8 emulator

## Usage
The all-in-one shellscript, and tape images and/or include files should be in the same folder.
To start from shell, simply enter as an executable command:

```
/home/etelkoz$ ./pdp8.sh

Simple PDP5/PDP8 emulator v0.9.1
by NASZVADI Peter, 1980-2018

(: Now in bash :)

For non-commercial use only.

[memory[pc]=0000 pc=0000 l+ac=00000 keycode=000]
[Enter pdp8 debugger command]:?
[
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
]
[memory[pc]=0000 pc=0000 l+ac=00000 keycode=000]
[Enter pdp8 debugger command]:
```

Press H or ? and then enter to get a brief list of commands.

## Tape files
| filename    | starting address (octal) |
| ----------- | ------------------------:|
| binhalt-pm  |                    07600 |
| siralom.tap |                     0200 |

Some of them can be downloaded from:
[bitsavers.org](http://bitsavers.org/bits/DEC/pdp8/From_Vince_Slyngstad/misc/)

## An example session with a vintage DEC binhalt tape execution and benchmark
binhalt-pm fills memory below address 07600 with word value 07402, then halts.
Notice that there is no space after the "T" command, the filename immediately follows it.
```
$ echo $BASH_VERSION
4.3.48(1)-release
$
$ time ./pdp8.sh

Simple PDP5/PDP8 emulator v0.9.1
by NASZVADI Peter, 1980-2018

(: Now in bash :)

For non-commercial use only.

[memory[pc]=0000 pc=0000 l+ac=00000 keycode=000]
[Enter pdp8 debugger command]:tbinhalt-pm
[memory[pc]=0000 pc=0000 l+ac=00000 keycode=000]
[Enter pdp8 debugger command]:d0
[
 0000: 0000 0000 0000 0000  0000 0000 0000 0000
 0010: 0000 0000 0000 0000  0000 0000 0000 0000
]
[memory[pc]=0000 pc=0000 l+ac=00000 keycode=000]
[Enter pdp8 debugger command]:d07550
[
 7550: 0000 0000 0000 0000  0000 0000 0000 0000
 7560: 0000 0000 0000 0000  0000 0000 0000 0000
]
[memory[pc]=0000 pc=0000 l+ac=00000 keycode=000]
[Enter pdp8 debugger command]:d
[
 7570: 0000 0000 0000 0000  0000 0000 0000 0000
 7600: 1211 3212 3213 1214  3613 2213 2212 5203
]
[memory[pc]=0000 pc=0000 l+ac=00000 keycode=000]
[Enter pdp8 debugger command]:p07600
[memory[pc]=1211 pc=7600 l+ac=00000 keycode=000]
[Enter pdp8 debugger command]:g
[memory[pc]=0200 pc=7611 l+ac=00000 keycode=000]
[Enter pdp8 debugger command]:d0
[
 0000: 7402 7402 7402 7402  7402 7402 7402 7402
 0010: 7402 7402 7402 7402  7402 7402 7402 7402
]
[memory[pc]=0200 pc=7611 l+ac=00000 keycode=000]
[Enter pdp8 debugger command]:d
[
 0020: 7402 7402 7402 7402  7402 7402 7402 7402
 0030: 7402 7402 7402 7402  7402 7402 7402 7402
]
[memory[pc]=0200 pc=7611 l+ac=00000 keycode=000]
[Enter pdp8 debugger command]:d07550
[
 7550: 7402 7402 7402 7402  7402 7402 7402 7402
 7560: 7402 7402 7402 7402  7402 7402 7402 7402
]
[memory[pc]=0200 pc=7611 l+ac=00000 keycode=000]
[Enter pdp8 debugger command]:d
[
 7570: 7402 7402 7402 7402  7402 7402 7402 7402
 7600: 1211 3212 3213 1214  3613 2213 2212 5203
]
[memory[pc]=0200 pc=7611 l+ac=00000 keycode=000]
[Enter pdp8 debugger command]:d
[
 7610: 7402 0200 0000 7600  7402 4260 7041 1306
 7620: 7402 6032 6014 7604  7700 1304 1303 3270
]
[memory[pc]=0200 pc=7611 l+ac=00000 keycode=000]
[Enter pdp8 debugger command]:q

real    3m36.96s
user    0m8.62s
sys     0m8.24s
$
```

## Caveats
Depends on *od*, a 3rd party program in order to load punch tape image files - as memory patch files.
Command "T" won't work without it.

## TODO
A lot. Cleanup, optimization, add correct implementation of devices, add support for bash 3.x in OSX etc.
