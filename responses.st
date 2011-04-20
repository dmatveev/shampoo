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

    Response subclass: NamespacesResponse [
        | list |

        NamespacesResponse class >> id: anInteger names: anArray [
            ^(self id: anInteger)
                names: anArray;
                yourself
        ]

        names: anArray [
            list := anArray
        ]

        type [
            ^'Namespaces'
        ]

        asXML [
            | root |
            root := super asXML.
            root addAttribute: (XML.Attribute name: 'type' value: self type).

            list ifNotNil: [:lst | lst do:
                [:each |
                root addNode: ((XML.Element tag: 'namespace')
                                   addAttribute: (XML.Attribute name: 'name' value: each);
                                   yourself)]].

            ^root
        ]
    ]

    Response subclass: ClassesResponse [
        | classes |

        ClassesResponse class >> id: anInteger classes: anArray [
            ^(self id: anInteger)
                classes: anArray;
                yourself
        ]

        classes: anArray [
            classes := anArray copy
        ]

        type [
            ^'Classes'
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
    ]

    ClassInfoResponse subclass: ClassResponse [
        type [
            ^'Class'
        ]
    ]

    ClassInfoResponse subclass: MethodCategoriesResponse [
        type [
            ^'Categories'
        ]
    ]

    ClassInfoResponse subclass: MethodsResponse [
        | category |

        MethodsResponse class >> id: anInteger class: aClass category: aString [
            ^(self id: anInteger class: aClass)
                category: aString;
                yourself
        ]

        category: aString [
            category := aString
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
    ]
]
