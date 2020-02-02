Project 0: Bootloader

## NOTICE
Attempting to copy these codes and use it on your own assignment will be considered plagiarism. Your professor will know it because since you can Google out this place then so can he/she.


## TO COMPILE
```
$ make all
```

## TO RUN IMAGE
```
$ qemu-system-i386 -smp 1 -hda project0.img -serial mon:stdio -m 512 -k en-us
```
