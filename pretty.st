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
            body := body collect: [:each | aString, each].
        ]

        sourceString [
            <category: 'pretty printing'>
            | w |
            w := WriteStream on: String new.
            w
                nextPutAll: selectorWithArguments;
                space;
                nextPut: $[;
                nl.
            body do: [:line | w putStrLn: line].
            w nextPut: $]; nl.
            ^w contents
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
    ]
]
