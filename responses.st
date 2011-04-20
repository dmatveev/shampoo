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

        success: aBoolean [
            success := aBoolean
        ]

        type [
            ^'OperationalResponse'
        ]
    ]

    Response subclass: CollectionResponse [
        | items |

        items: anArray [
            items := anArray copy
        ]

        asXML [
            | root |
            root := super asXML.

            items ifNotNil: [:lst | lst do:
                [:each |
                root addNode: ((XML.Element tag: self itemType)
                                   addAttribute: (XML.Attribute name: 'name' value: each);
                                   yourself)]].

            ^root
        ]

        itemType [
            ^self shouldNotImplement
        ]
    ]

    CollectionResponse subclass: NamespacesResponse [
        NamespacesResponse class >> id: anInteger names: anArray [
            ^(self id: anInteger)
                items: anArray;
                yourself
        ]

        type [
            ^'Namespaces'
        ]

        itemType [
            ^'namespace'
        ]
    ]

    CollectionResponse subclass: ClassesResponse [
        ClassesResponse class >> id: anInteger classes: anArray [
            ^(self id: anInteger)
                items: anArray;
                yourself
        ]

        type [
            ^'Classes'
        ]

        itemType [
            ^'namespace'
        ]
    ]

    Response subclass: ClassInfoResponse [
        | class |

        ClassInfoResponse class >> id: anInteger class: aClass [
            ^(ClassInfoResponse id: anInteger)
                class: aClass;
                yourself
        ]

        class: aClass [
            class := aClass
        ]

        asXML [
            ^(super asXML)
                addAttribute: (XML.Attribute name: 'class' value: class);
                yourself
        ]
    ]

    ClassInfoResponse subclass: ClassResponse [
        | instvars |

        ClassResponse class >> id: anInteger class: aClass instvars: anArray [
            ^(ClassResponse id: anInteger class: aClass)
                instvars: anArray;
                yourself
        ]

        instvars: anArray [
            instvars := anArray copy
        ]

        type [
            ^'Class'
        ]

        itemType [
            ^'instvar'
        ]
   ]

    ClassInfoResponse subclass: MethodCategoriesResponse [
        | categories |

        MethodCategoriesResponse class >> id: anInteger class: aClass categories: anArray [
            ^(MethodCategoriesResponse id: anInteger class: aClass)
                categories: anArray;
                yourself
        ]

        categories: anArray [
            categories := anArray copy
        ]

        type [
            ^'Categories'
        ]
    
        asXML [
            | root |
            root := super asXML.

            categories ifNotNil: [:lst | lst do:
                [:each |
                root addNode: ((XML.Element tag: 'category')
                                   addAttribute: (XML.Attribute name: 'name' value: each);
                                   yourself)]].

            ^root
        ]
    ]

    ClassInfoResponse subclass: MethodsResponse [
        | methods |

        MethodsResponse class >> id: anInteger class: aClass methods: anArray [
            ^(self id: anInteger class: aClass)
                methods: aString;
                yourself
        ]

        methods: anArray [
            methods := anArray copy
        ]

        type [
            ^'Methods'
        ]
    
        asXML [
            | root |
            root := super asXML.

            methods ifNotNil: [:lst | lst do:
                [:each |
                root addNode: ((XML.Element tag: 'method')
                                   addAttribute: (XML.Attribute name: 'name' value: each);
                                   yourself)]].

            ^root
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
]
