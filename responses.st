Namespace current: Shampoo [

    Object subclass: Response [
        | id |

        Response class >> id: anInteger [
            ^(self new)
                id: anInteger;
                yourself
        ]

        id: anInteger [
            id := anInteger
        ]

        type [
            ^self shouldNotImplement
        ]

        asXML [
            ^(ShampooXML.ShNode tagname: 'response')
                addAttribute: 'id' value: id asString;
                addAttribute: 'type' value: self type;
                yourself
        ]
    ]

    Response subclass: ServerInfoResponse [
        type [
            ^'Info'
        ]

        asXML [
            ^(super asXML)
                addNode: (ShampooXML.ShText text: Smalltalk version);
                yourself
        ]
    ]

    Response subclass: OperationalResponse [
        | success |

        OperationalResponse class >> success: anInteger [
            <category: 'convenience'>
            ^(OperationalResponse id: anInteger)
                success: true;
                yourself
        ]

        OperationalResponse class >> failure: anInteger [
            <category: 'convenience'>
            ^(OperationalResponse id: anInteger)
                success: true;
                yourself
        ]

        statusString [
            ^success ifTrue: ['success'] ifFalse: ['failure']
        ]

        success: aBoolean [
            success := aBoolean
        ]

        type [
            ^'OperationalResponse'
        ]

        asXML [
            ^(super asXML)
                addAttribute: 'status' value: self statusString;
                yourself
        ]
    ]

    Object subclass: AggregatedResponseDecorator [
        | items wrapped |

        AggregatedResponseDecorator class >> on: aWrappedObject [
            <category: 'instance creation'>
            ^self new on: aWrappedObject
        ]

        on: aWrappedObject [
            wrapped := aWrappedObject
        ]

        items [
            ^items ifNil: [items := Dictionary new]
        ]

        itemsAt: itemTypeString put: anArray [
            self items at: itemTypeString put: anArray copy
        ]

        asXML [
            | root |
            root := wrapped asXML.

            self items keysAndValuesDo:
                [:key :values | values do: [:each |
                root addNode: ((ShampooXML.ShNode tagname: key asString)
                                   addNode: (ShampooXML.ShText text: each);
                                   yourself)]].

            ^root
        ]

        doesNotUnderstand: aMessage [
            "Proxy an unknown message to an underlying object"
            ^wrapped perform: aMessage selector
                     withArguments: aMessage arguments
        ]
    ]

    Response subclass: NamespacesResponse [
        NamespacesResponse class >> id: anInteger names: anArray [
            ^(AggregatedResponseDecorator on: (self id: anInteger))
                itemsAt: 'namespace' put: anArray;
                yourself
        ]

        type [
            ^'Namespaces'
        ]
    ]

    Response subclass: ClassesResponse [
        ClassesResponse class >> id: anInteger names: anArray [
            ^(AggregatedResponseDecorator on: (self id: anInteger))
                itemsAt: 'class' put: anArray;
                yourself
        ]

        type [
            ^'Classes'
        ]
    ]

    Response subclass: ClassInfoResponse [
        | class attrs |

        ClassInfoResponse class >> id: anInteger class: aClass [
            ^self id: anInteger class: aClass attrs: nil
        ]

        ClassInfoResponse class >> id: anInteger class: aClass attrs: anArray [
            ^(self id: anInteger)
                class: aClass attrs: anArray
                yourself
        ]

        class: aClass attrs: anArray [
            class := aClass.
            anArray isNil ifFalse: [attrs := Dictionary from: anArray].
        ]

        asXML [
            | r |
            r := super asXML.
            r addAttribute: 'class' value: class.
            attrs ifNotNil:
              [:dict |
              dict keysAndValuesDo: 
                  [:key :value | r addAttribute: key value: value]].
            ^r
        ]
    ]

    ClassInfoResponse subclass: ClassResponse [
        ClassResponse class >> id: anInteger class: aClass superclass: aSuperClass
                               instvars: anInstVars classvars: aClassVars poolvars: aPoolDicts [
            ^(AggregatedResponseDecorator on: (self id: anInteger class: aClass attrs: {'superclass' -> aSuperClass}))
                itemsAt: 'instvar'  put: anInstVars;
                itemsAt: 'classvar' put: aClassVars;
                itemsAt: 'poolvar'  put: aPoolDicts;
                yourself
        ]

        type [
            ^'Class'
        ]
   ]

    ClassInfoResponse subclass: MethodCategoriesResponse [
        MethodCategoriesResponse class >> id: anInteger class: aClass categories: anArray [
            ^(AggregatedResponseDecorator on: (self id: anInteger class: aClass))
                itemsAt: 'category' put: anArray;
                yourself
        ]

        type [
            ^'Categories'
        ]
    ]

    ClassInfoResponse subclass: MethodsResponse [
        MethodsResponse class >> id: anInteger class: aClass methods: anArray [
            ^(AggregatedResponseDecorator on: (self id: anInteger class: aClass))
                itemsAt: 'method' put: anArray;
                yourself
        ]

        type [
            ^'Methods'
        ]
    ]

    ClassInfoResponse subclass: MethodResponse [
        | methodName methodSource |

        MethodResponse class >> id: anInteger class: aClass method: aNameString source: aSourceString [
            ^(self id: anInteger class: aClass)
                method: aNameString methodSource: aSourceString;
                yourself
        ]

        method: aNameString methodSource: aSourceString [
            methodName := aNameString.
            methodSource := aSourceString
        ]

        type [
            ^'MethodSource'
        ]

        asXML [
            ^(super asXML)
                addAttribute: 'method' value: methodName;
                addNode: (ShampooXML.ShText text: methodSource);
                yourself
        ]
    ]

    Response subclass: PrintItResponse [
        | value |

        PrintItResponse class >> id: anInteger value: anObject [
            ^(self id: anInteger)
                value: anObject;
                yourself
        ]

        value: anObject [
            value := anObject
        ]

        value [
            ^value
        ]

        type [
            ^'PrintIt'
        ]

        asXML [
            ^(super asXML)
                addNode: (ShampooXML.ShText text: value printString);
                yourself
        ]
    ]

    Response subclass: EchoResponse [
        | text |

        EchoResponse class >> id: anInteger text: aString [
            ^(self id: anInteger)
                text: aString;
                yourself
        ]

        text: aString [
            text := aString
        ]

        type [
            ^'Echo'
        ]

        asXML [
            ^(super asXML)
                addNode: (ShampooXML.ShText text: text);
                yourself
        ]
    ]

    Response subclass: MagicResponse [
        | number |
        "Not actually a response, the only request that goes from a server
         to a client"

        MagicResponse class >> number: anInteger [
            ^(self id: 0)
                number: anInteger;
                yourself
        ]

        number: anInteger [
            number := anInteger
        ]

        type [
            ^'Magic'
        ]

        asXML [
            ^(super asXML)
                addNode: (ShampooXML.ShText text: number printString);
                yourself
        ]
    ]
]
