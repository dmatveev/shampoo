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
    ]

    Response subclass: NamespacesResponse [
        "TODO Subnamespaces"
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

    ClassInfoResponse subclass: MethodCategoriesResponse [
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
    ]
]
