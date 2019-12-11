#!/bin/bash

# 'reverse'
echo
echo "# 'reverse'"
echo "echo \$STRING | rev"

# example
STRING="12345"

REVERSED=$(echo $STRING | rev)

echo
echo "string  =$STRING"
echo "reversed=$REVERSED"

exit 0

