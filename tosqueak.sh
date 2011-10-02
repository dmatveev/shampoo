#!/usr/bin/env bash

FILES=$(grep filein package.xml | sed 's/<[/a-z]*>//g')
OUTPUT=shampoo-squeak-$(git rev-parse --short HEAD).st
TRANSCRIPT=ShampooTranscript
XMLNODE=ShNode
XMLTEXT=ShText

gst-convert -v \
    -f gst \
    -F squeak \
    -C -$TRANSCRIPT -C -$XMLNODE -C -$XMLTEXT \
    -o $OUTPUT \
    $FILES

if [ "$?" -ne "0" ]; then
    echo "Fatal error, exiting"
    exit 1
fi

sed -i \
    -e 's/ShampooXML\.ShNode/ShampooXMLNode/g' \
    -e 's/ShampooXML\.ShText/ShampooXMLText/g' \
    -e 's/ShNode/ShampooXMLNode/g' \
    -e 's/ShText/ShampooXMLText/g' \
    -e 's/Shampoo.ShampooTranscript install\!//g' \
    -e "s/methodsFor: nil/methodsFor: 'as yet unclassified'/g" \
    -e 's/LoginTest/ShampooLoginTest/g' \
    -e 's/NamespacesTest/ShampooNamespacesTest/g' \
    -e 's/ClassesTest/ShampooClassesTest/g' \
    -e 's/ClassTest/ShampooClassTest/g' \
    -e 's/CatsTest/ShampooCatsTest/g' \
    -e 's/MethodsTest/ShampooMethodsTest/g' \
    -e 's/MethodTest/ShampooMethodTest/g' \
    -e 's/CompileClassTest/ShampooCompileClassTest/g' \
    -e 's/CompileClassSideTest/ShampooCompileClassSideTest/g' \
    -e 's/CompileMethodTest/ShampooCompileMethodTest/g' \
    -e 's/DoItTest/ShampooDoItTest/g' \
    -e 's/PrintItTest/ShampooPrintItTest/g' \
    $OUTPUT
