#!/bin/bash
#bash lddscript.sh /bin/ls /tmp/test
if [ ${#} != 2 ]
then
    echo "usage $0 PATH_TO_BINARY target_folder"
    exit 1
fi

path_to_binary="$1"
target_folder="$2"

# if we cannot find the the binary we have to abort
if [ ! -f "${path_to_binary}" ]
then
    echo "The file '${path_to_binary}' was not found. Aborting!"
    exit 1
fi

# copy the binary itself
echo "---> copy binary itself"
cp --parents -v "${path_to_binary}" "${target_folder}"

# copy the library dependencies
echo "---> copy libraries"
ldd "${path_to_binary}" | awk -F'[> ]' '{print $(NF-1)}' | while read -r lib
do
    [ -f "$lib" ] && cp -v --parents "$lib" "${target_folder}"
done

