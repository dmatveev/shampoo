Namespace current: Shampoo [
    Object subclass: MethodSource [
        <category: 'Shampoo-Pretty printing'>
        
        | selectorWithArguments body |

        MethodSource class >> from: aString [
            <category: 'instance creation'>
            ^(self new)
                init: aString;
                yourself
        ]

        MethodSource >> init: aString [
            <category: 'private'>
            | r |
            r := ReadStream on: aString.
            selectorWithArguments := (r upTo: $[) trimSeparators.
            body := ((r upToEnd) copyUpToLast: $]) lines.
        ]

        selectorWithArguments [
            <category: 'accessors'>
            ^selectorWithArguments
        ]

        body [
            <category: 'accessors'>
            ^body
        ]

        methodIndent [
            <category: 'accessors'>
            | notEmpty spaceLens |

            "At first, drop all empty strings"
            notEmpty := body select:
            [:each | each trimSeparators isEmpty not].

            spaceLens := notEmpty collect:
            [:each | (each takeWhile: [:c | c isSeparator]) size].

            ^spaceLens isEmpty
                ifTrue:  [0]
                ifFalse: [spaceLens fold: [:a :b | a min: b]]
        ]

        compact [
            <category: 'pretty printing'>
            | r fst |

            "Remove empty lines from the beginning, if any"
            r := ReadStream on: body.
            r forwardWhile: [:line | line trimSeparators isEmpty].
            body := body drop: r position.
            body isEmpty ifTrue: [^self].

            "Remove newline characters from the beginning of the
             first line"
            fst := body first breakIf: [:c | c isSeparator not].
            fst := (fst first copyWithout: Character nl), fst second.
            body at: 1 put: fst.

            "Remove empty lines from the end, if any"
            r := ReadStream on: body reverse.
            r forwardWhile: [:line | line trimSeparators isEmpty].
            body := body take: body size - r position.
        ]

        stripIndent [
            <category: 'pretty printing'>
            | indent |
            indent := self methodIndent.
            body := body collect: [:each | each drop: indent].
        ]

        indentWith: aString [
            <category: 'pretty printing'>
            body := body collect: [:each | aString, each].
        ]

        printOn: aStream [
            aStream
                nextPutAll: selectorWithArguments;
                space;
                nextPut: $[;
                nl.
            body do: [:line | aStream nextPutAll: line; nl].
            aStream nextPut: $]; nl.
        ]

        sourceString [
            <category: 'pretty printing'>
            | w |
            w := WriteStream on: String new.
            self printOn: w.
            ^w contents
        ]
    ]

    Object subclass: ClassSource [
        <category: 'Shampoo-Pretty printing'>

        | printedClass namespaces |

        ClassSource class >> of: aClass [
            <category: 'instance creation'>
            ^self new
                printedClass: aClass;
                yourself
        ]

        printedClass: aClass [
            <category: 'private'>
            printedClass := aClass.
            namespaces := printedClass namespaceChain.
        ]

        enclosingNamespaces: aStream do: aBlock [
            <category: 'pretty printing'>
            namespaces do:
            [:ns | aStream
                       nextPutAll: 'Namespace current:';
                       space;
                       nextPutAll: ns name asString;
                       space;
                       nextPut: $[;
                       space].
            aStream nl.
            aBlock value.
            namespaces size timesRepeat: [aStream nextPut: $]].
            aStream nl
        ]

        enclosingClassDefinition: aStream do: aBlock [
            <category: 'pretty printing'>
            | superName |
            superName := printedClass superclass
                ifNil:    ['nil']
                ifNotNil: [printedClass superclass name asString].
            aStream
                nextPutAll: superName;
                space;
                nextPutAll: 'subclass:';
                space;
                nextPutAll: printedClass name asString;
                space;
                nextPut: $[;
                nl.
            aStream increasingIndent: [aBlock value].
            aStream nextPut: $]; nl
        ]

        writePragma: aPragmaName value: aString on: aStream [
            <category: 'pretty printing'>
            aStream
                nextPut: $<;
                nextPutAll: aPragmaName;
                nextPut: $:;
                space;
                nextPutAll: aString printString;
                nextPut: $>
        ]

        writeCommentsOn: aStream [
            <category: 'pretty printing'>
            printedClass category isNil ifFalse:
            [self writePragma: 'category'
                  value: printedClass category
                  on: aStream.
             aStream nl].
            printedClass comment isNil ifFalse:
            [self writePragma: 'comment'
                  value: printedClass comment
                  on: aStream.
             aStream nl]
        ]

        writeInstVarsOn: aStream [
            <category: 'pretty printing'>
            | instvars |
            instvars := printedClass instVarNames asStringArray.
            instvars isEmpty ifFalse:
            [aStream
                nl;
                nextPut: $|;
                space;
                nextPutAll: instvars elementsString;
                space;
                nextPut: $|;
                nl]
        ]

        writeClassVarsOn: aStream [
            <category: 'pretty printing'>
            printedClass classVarNames asStringArray do:
            [:each | aStream
                         nextPutAll: each;
                         space;
                         nextPutAll: ':= nil.';
                         nl]
        ]

        writeMethod: aMethod on: aStream [
            <category: 'pretty printing'>
            | ms |
            ms := MethodSource from: aMethod methodSourceString.
            ms compact; stripIndent.
            aStream nl.
            ms printOn: aStream.
        ]

        writeClassMethod: aMethod on: aStream [
            <category: 'pretty printing'>
            | ms start |
            ms := MethodSource from: aMethod methodSourceString.
            ms compact; stripIndent. 
            aStream nl.
            start := aStream position.
            aStream
                nextPutAll: printedClass name asString;
                space;
                nextPutAll: 'class >> '.
            aStream position + ms selectorWithArguments size - start
            >= 67 ifTrue: [aStream nl].
            ms printOn: aStream.
        ]

        writeMethodsOn: aStream [
            <category: 'pretty printing'>
            printedClass methodDictionary ifNotNil:
            [printedClass methodDictionary values do:
             [:each | self writeMethod: each on: aStream]]
        ]

        writeClassMethodsOn: aStream [
            <category: 'pretty printing'>
            printedClass class methodDictionary ifNotNil:
            [printedClass class methodDictionary values do:
             [:each | self writeClassMethod: each on: aStream]]
        ]

        sourceString [
            <category: 'pretty printing'>
            | w is ns |
            w := WriteStream on: String new.
            is := IndentedStreamDecorator on: w.
            self enclosingNamespaces: is do:
            [self enclosingClassDefinition: is do:
             [self
                  writeCommentsOn: is;
                  writeInstVarsOn: is;
                  writeClassVarsOn: is;
                  writeClassMethodsOn: is;
                  writeMethodsOn: is
             ]].
            ^is contents.
        ]
    ]

    Object subclass: PrettyPrinter [
        <category: 'Shampoo-Pretty printing'>

        PrettyPrinter class >> prettifyMethod: aSourceString [
            <category: 'pretty printing'>
            ^(MethodSource from: aSourceString)
                compact;
                stripIndent;
                indentWith: '    ';
                sourceString
        ]

        PrettyPrinter class >> prettifyClass: aClass [
            <category: 'pretty printing'>
            ^(ClassSource of: aClass)
                sourceString
        ]

        PrettyPrinter class >> prettifyClasses: aCollectionOfClasses [
            <category: 'pretty printing'>
            | prettified |
            prettified := aCollectionOfClasses collect:
            [:each | self prettifyClass: each].

            ^String join: prettified
        ]
    ]

    Decorator subclass: IndentedStreamDecorator [
        <category: 'Shampoo-Pretty printing'>

        | state indentLevel levelSpaces |

        prepareIndent [
            <category: 'indentation fsm'>
            state := #preparingToIndent
        ]

        tryIndent [
            <category: 'indentation fsm'>
            self state = #preparingToIndent ifTrue: [self indent]
        ]

        increasingIndent: aBlock [
            <category: 'indentation'>
            indentLevel := self indentLevel + 1.
            [aBlock value] ensure:
            [indentLevel := self indentLevel - 1]
        ]

        indent [
            <category: 'indentation fsm'>
            self indentLevel * self levelSpaces timesRepeat:
            [self underlyingObject space].
            state := #indented
        ]

        nl [
            <category: 'stream decorator'>
            self prepareIndent.
            self underlyingObject nl
        ]
        
        nextPut: anObject [
            <category: 'stream decorator'>
            anObject = Character nl
                ifTrue:  [self prepareIndent]
                ifFalse: [self tryIndent].
            self underlyingObject nextPut: anObject.
        ]

        nextPutAll: aCollection [
            <category: 'stream decorator'>
            aCollection do: [:each | self nextPut: each]
        ]

        state [
            <category: 'accessors'>
            ^state ifNil: [state := #preparingToIndent]
        ]

        indentLevel [
            <category: 'accessors'>
            ^indentLevel ifNil: [indentLevel := 0]
        ]

        levelSpaces [
            <category: 'accessors'>
            ^levelSpaces ifNil: [levelSpaces := 4]
        ]
    ]
]
