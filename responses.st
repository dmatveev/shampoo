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
            ^(XML.Element tag: 'response')
                addAttribute: (XML.Attribute name: 'id' value: id asString);
                addAttribute: (XML.Attribute name: 'type' value: self type);
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
                addAttribute: (XML.Attribute name: 'status' value: self statusString);
                yourself
        ]
    ]

    Behavior subclass: AggregatedResponseBehavior [
        | items |

        items [
            ^items ifNil: [items := Dictionary new]
        ]

        itemsAt: itemTypeString put: anArray [
            self items at: itemTypeString put: anArray copy
        ]

        asXML [
            | root |
            root := super asXML.

            self items keysAndValuesDo:
                [:key :values | values do: [:each |
                root addNode: ((XML.Element tag: key asString)
                                   addNode: (XML.Text text: each);
                                   yourself)]].

            ^root
        ]
    ]

    Response subclass: NamespacesResponse [
        NamespacesResponse class >> id: anInteger names: anArray [
            ^(self id: anInteger)
                itemsAt: 'namespace' put: anArray;
                yourself
        ]

        type [
            ^'Namespaces'
        ]
    ]

    Response subclass: ClassesResponse [
        ClassesResponse class >> id: anInteger names: anArray [
            ^(self id: anInteger)
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
            attrs := Dictionary from: anArray
        ]

        asXML [
            | r |
            r := super asXML.
            r addAttribute: (XML.Attribute name: 'class' value: class).
            attrs ifNotNil:
              [:dict |
              dict keysAndValuesDo:
                  [:key :value |
                  r addAttribute: (XML.Attribute name: key value: value)]]
        ]
    ]

    ClassInfoResponse subclass: ClassResponse [
        ClassResponse class >> id: anInteger class: aClass superclass: aSuperClass
                               instvars: anInstVars classvars: aClassVars poolvars: aPoolDicts [
            ^(ClassResponse id: anInteger class: aClass attrs: {'superclass' -> aSuperClass})
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
            ^(MethodCategoriesResponse id: anInteger class: aClass)
                itemsAt: 'category' put: anArray;
                yourself
        ]

        type [
            ^'Categories'
        ]
    ]

    ClassInfoResponse subclass: MethodsResponse [
        MethodsResponse class >> id: anInteger class: aClass methods: anArray [
            ^(self id: anInteger class: aClass)
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
                addAttribute: (XML.Attribute name: 'method' value: methodName);
                addNode: (XML.Text text: methodSource);
                yourself
        ]
    ]

    Eval [
        {   NamespacesResponse.
            ClassesResponse.
            ClassResponse.
            MethodCategoriesResponse.
            MethodsResponse
        } do: [:each | each mergeBehaviorFrom: AggregatedResponseBehavior]
    ]
]
