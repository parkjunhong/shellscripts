#!/usr/bin/env bash


help(){
    echo "Usage for 'file-size.sh'"
    echo " ./file-size.sh -p {search-path} -n {rank-count} -f -d -w"
    echo " ex) ./file-size.sh -p . -n 100 -f"
    echo "     : search only files top 100 at current directory"
    echo
    echo "[Options]"
    echo " -p: search patth. default: ."
    echo " -n: rank max count, default: 10"
    echo " -f: search only file"
    echo " -d: search only directory"
    echo " -w: print raw byte using thousand comma"
    echo "*) if set -d -f, apply 1st configuration"
}

# $1: exit code
# $2: error message
exit_on_error(){
    echo $2
    
    help

    exit $1
}

SEARCH_PATH="."
RANK=10
SEARCH_TYPE=""
THOUSAND_COMMA=0

while getopts ":p:n:hfdw" opt;
do
    case "$opt" in
        p)
            SEARCH_PATH=$OPTARG
        ;;
        n)
            RANK=$OPTARG
        ;;
        f)
            if [ ! $SEARCH_TYPE ]
            then
                SEARCH_TYPE="f"
            fi
        ;;
        d)
            if [ ! $SEARCH_TYPE ]
            then
                SEARCH_TYPE="d"
            fi
        ;;
        w)
            THOUSAND_COMMA=1
        ;;
        h)
            help

            exit 0
        ;;
        :)
            echo "[Error] option -$OPTARG requries an argument!!!" >$2
            exit_on_error 1
        ;;
        \?)
            echo "?: " $OPTARG
        ;;
        *)
            echo $OPTARG
        ;;
    esac
done

filesize=0
blocksize="B "
prettyfilesize=0
PRETTY_FILESIZE_FORMAT="%'6d"
adjust_filesize(){
    
    pb=1125899906842624 # Petabyte
    tb=1099511627776 # Terabyte
    gb=1073741824 # Gigabyte
    mb=1048576 # Megabyte
    kb=1024 # Kilobyte

    bs=1

    if [ $1 -ge $pb ];
    then
        bs=$pb
        blocksize="PB"
    elif [ $1 -ge $tb ];
    then
        bs=$tb
        blocksize="TB"
    elif [ $1 -ge $gb ];
    then
        bs=$gb
        blocksize="GB"
    elif [ $1 -ge $mb ];
    then
        bs=$mb 
        blocksize="MB"
    elif [ $1 -ge $kb ];
    then
        bs=$kb
        blocksize="MB"
    fi

    prettyfilesize=`expr $filesize / $bs`
}

FILETYPE_FORMAT="%1s"
FILESIZE_FORMAT="%10d"
# $1 searched list
filesize_length(){

    LIST=$@

    filetype_max_len=0
    filesize_max_len=0
    idx=0

    for item in ${LIST[@]}
    do
        mod=`expr $idx % 2`
        
        if [ $mod -eq 0 ];
        then
            #if [ $2 -eq 1 ];
            #then
            #    item=$(printf "%'d" $item)
            #fi

            if [ $filesize_max_len -lt ${#item} ];
            then
                filesize_max_len=${#item}
            fi
        else

            fml=0

            if [ -d $item ];
            then    
                fml=9
            else
                fml=4
            fi

            if [ $filetype_max_len -lt $fml ];
            then
                #filetype_max_len=$fml
                filetype_max_len=1
            fi
        fi

        idx=`expr $idx + 1`
    done

    if [ $THOUSAND_COMMA -eq 1 ];
    then
        #filesize_max_len =  $filesize_max_len + ( $filesize_max_len - 1 ) / 3 
        filesize_max_len=`expr $filesize_max_len + \( $filesize_max_len - 1 \) / 3`
        FILESIZE_FORMAT="%'"$filesize_max_len"d"
    else
        FILESIZE_FORMAT="%"$filesize_max_len"d"
    fi

    FILETYPE_FORMAT="%-"$filetype_max_len"s"
}

SEARCH_LIST=()
search_target(){
    LIST=$(du $SEARCH_PATH -ab | sort -n -r)

    rank=0
    idx=0
    filetype="" # directory | file
    for item in $LIST
    do
        mod=`expr $idx % 2`

        if [ $mod -eq 0 ];
        then
            filesize=$item
        else
            if [ -d $item ];
            then  
                filetype="d"
            else
                filetype="f"
            fi

            if [ $filetype == $1 ]
            then
                SEARCH_LIST+=($filesize)
                SEARCH_LIST+=($item)

                rank=`expr $rank + 1`
            fi
        fi
        idx=`expr $idx + 1`

        if [ $rank -ge $RANK ]
        then
            break
        fi
    done
}

# #$1 searched list
print_result(){
    LIST=$@

    filesize_length $LIST

    idx=0
    filetype=""
    for item in $LIST
    do
        mod=`expr $idx % 2`

        if [ $mod -eq 0 ];
        then
            filesize=$item
        else
            adjust_filesize $filesize
            
            prettyfilesize=$(printf $PRETTY_FILESIZE_FORMAT $prettyfilesize)
            
            filesize=$(printf $FILESIZE_FORMAT $filesize)
            
            if [ -d $item ];
            then    
                filetype=$(printf $FILETYPE_FORMAT "d")
            else
                filetype=$(printf $FILETYPE_FORMAT "f")
            fi
            
            echo "$prettyfilesize $blocksize ( $filesize, $filetype ) $item"
        fi

        idx=`expr $idx + 1`
    done
}


if [ $SEARCH_TYPE ]
then
    search_target $SEARCH_TYPE

    print_result ${SEARCH_LIST[@]}
else
    
    SEARCH_LIST=$(du $SEARCH_PATH -ab | sort -n -r | head -n $RANK)

    print_result ${SEARCH_LIST[@]}
fi
