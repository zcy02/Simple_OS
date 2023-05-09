if [ $# = 1 ]
then
    echo $(nm build/kernel.bin | grep $1)
else
    nm build/kernel.bin > symbol.txt
fi