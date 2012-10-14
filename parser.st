Namespace current: Shampoo [

    Object subclass: MessageParserState [
        <category: 'Shampoo-Protocol'>
        <comment: 'My subclasses represent various states of the message parser
FSM. I contain the most common methods for all states and define the state
interface (see the "fsm" category).'>

        | parser buffer |

        MessageParserState class >> new: aString [
            <category: 'instance creation'>
            ^self basicNew
                initialize: aString;
                yourself
        ]

        initialize: aString [
            <category: 'initialization'>
            buffer := aString
        ]

        invalidateBuffer [
            <category: 'private'>
            buffer := String new.
        ]

        parser: aParser [
            <category: 'accessors'>
            parser := aParser.
        ]

        consume: aString [
            <category: 'accessors'>
            buffer := buffer, aString
        ]

        canProcess [
            <category: 'fsm'>
            self subclassResponsibility
        ]

        processInto: aCollection [
            <category: 'fsm'>
            [self tryParse: buffer readStream into: aCollection
            ] on: Error do: [:e | e inspect. self handleFail]
        ]

        switchToContent: aLength rest: aString [
            <category: 'fsm'>
            | st |
            st := ParseContentState buffer: aString length: aLength.
            parser switchTo: st
        ]

        switchToHeader: aString [
            <category: 'fsm'>
            parser switchTo: (ParseHeaderState buffer: aString)
        ]

        tryParse: aStream into: aCollection [
            <category: 'private'>
            self subclassResponsibility
        ]

        fail [
            <category: 'private'>
            self error: 'Error occured during parsing'
        ]

        handleFail [
            <category: 'private'>
            self subclassResponsibility
        ]
    ]

    MessageParserState subclass: ParseHeaderState [
        <category: 'Shampoo-Protocol'>
        <comment: 'My instances parse the header part of the message. The
main purpose is to extract the content length ("Content-Length" header)
and then to switch the FSM to the ParseContentState state and to pass the
rest of the message and the expected content length to it.'>

        ParseHeaderState class >> buffer: aString [
            <category: 'instance creation'>
            ^(self new: aString)
                yourself
        ]

        canProcess [
            <category: 'fsm'>
            ^buffer lines size >= 2
        ]
    
        tryParse: aStream into: aCollection [
            <category: 'private'>
            | sz |
            aStream upToAll: 'Content-Length: '.
            aStream atEnd ifTrue: [self fail].
            sz := Integer readFrom: aStream.
            sz = 0 ifTrue: [self fail].
            2 timesRepeat:
            [(aStream next: 2) = String crlf ifFalse: [self fail]].
            self switchToContent: sz rest: aStream upToEnd
        ]

        handleFail [
            <category: 'private'>
            self invalidateBuffer
        ]
    ]

    MessageParserState subclass: ParseContentState [
        <category: 'Shampoo-Protocol'>
        <comment: 'My instances parse the content part of the message. When
there are enough bytes in the message (i.e. more than or equal to expected),
my instance will put the content into a collection and then will switch the
FSM to the ParseHeaderState state and will pass the rest of the buffer to it.'>

        | expected |

        ParseContentState class >> buffer: aString length: anInteger [
            <category: 'instance creation'>
            ^(self new: aString)
                expected: anInteger;
                yourself
        ]

        expected: anInteger [
            <category: 'accessors'>
            expected := anInteger
        ]

        canProcess [
            <category: 'fsm'>
            ^buffer size >= expected
        ]

        tryParse: aStream into: aCollection [
            <category: 'fsm'>
            aCollection add: (aStream next: expected).
            self switchToHeader: aStream upToEnd
        ]

        handleFail [
            <category: 'private'>
            "Do nothing"
        ]
    ]

    Object subclass: MessageParser [
        <category: 'Shampoo-Protocol'>
        <comment: 'I am the main class to handle the incoming messages.
My instances take the received raw data and extract the contents from it.'>

        | state |

        MessageParser class >> new [
            <category: 'instance creation'>
            ^(self basicNew)
                initialize;
                yourself
        ]

        initialize [
            <category: 'initialization'>
            self switchTo: (ParseHeaderState buffer: '')
        ]

        process: aString [
            <category: 'parsing'>
            | results |
            results := OrderedCollection new.
            state consume: aString.
            [state canProcess] whileTrue:
            [state processInto: results].
            ^results
        ]

        switchTo: aState [
            <category: 'fsm'>
            state := aState.
            state parser: self.
        ]
    ]
]
