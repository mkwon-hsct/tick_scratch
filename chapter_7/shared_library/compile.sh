#!/bin/sh

## @file compile.sh
## @overview Compile a shared library for q.

## @param $1 name: Name of the shared object.
## @param $2.. sources: Source files.

CSTD="";

echo -n "standard? 0: default, 1: c99 [0]> ";
read RESPONSE;
case ${RESPONSE:=0} in
  0) ;;
  1) CSTD="-std=c99";;
  *) echo -e "\e[31mUnknown mode: ${RESPONSE}\e[0m";
     exit 1 ;;
esac

command="gcc -DKXVER=3 -I include/ -shared -fPIC ${CSTD} -o lib/${1} ";

## Remove artefact name
shift;
for source in $@
do
  ## Add source file
  command="${command} src/${source}";
done

## Execute the command
${command};
