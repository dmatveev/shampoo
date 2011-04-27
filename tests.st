Eval [
    PackageLoader fileInPackages: #(#Shampoo #SUnit).
]

Namespace current: Smalltalk [
    Namespace current: ShampooSamples [
        Object subclass: SampleClassA [
            | a b c |

            one := 1.
            two := 2.
            three := 3.
        ]

        Object subclass: SampleClassB [
            doSomething [
                <category: 'sample-category'>
                ^42
            ]

            doSomethingElse: something withArg: anArg [
                <category: 'sample-category'>
                ^something + anArg
            ]

            aMethodWithoutCategory [
                ^self class name
            ]

            foo [
                <category: 'accessors'>
                ^1337
            ]

            bar [
                <category: 'accessors'>
                ^'Smalltalk is cool!'
            ]
        ]
    ]
]

Namespace current: Shampoo [
    "Warning! This is a great kludge. I do not need these methods in the
     original implementation but do need for tests"

    Response extend [
        id [^id]
    ]

    OperationalResponse extend [
        success [^success]
    ]

    ClassInfoResponse extend [
        class [^class]
    ]

    MethodResponse extend [
        methodName [^methodName]
        methodSource [^methodSource]
    ]


    TestCase subclass: RequestsTest [
        | namespaces classes class cats methods method |

        defaultLogPolicyClass [
            <category: 'logging'>
            ^TestVerboseLog
        ]

        allTestCases [
            ^{ 'namespaces' -> self testNamespaces.
            }
        ]

        setUp [
            namespaces := self request: NamespacesRequest from: self namespacesSample.
            classes := self request: ClassesRequest from: self classesSample.
            class := self request: ClassRequest from: self classSample.
            cats := self request: CategoriesRequest from: self catsSample.
            methods := self request: MethodsRequest from: self methodsSample.
            method := self request: MethodSourceRequest from: self methodSample.
        ]

        testNamespaces [
            | r items |
            r := namespaces execute.
            items := r items at: 'namespace'.
            self should: [items includes: 'Shampoo'];
                 should: [items includes: 'ShampooSamples']
        ]

        testClasses [
            | r items |
            r := classes execute.
            items := r items at: 'class'.
            self should: [items includes: 'SampleClassA'];
                 should: [items includes: 'SampleClassB']
        ]

        testClass [
            | r instvars classvars |
            r := class execute.
            instvars := r items at: 'instvar'.
            classvars := r items at: 'classvar'.
            self should: [instvars includes: 'a'];
                 should: [instvars includes: 'b'];
                 should: [instvars includes: 'c'];
                 should: [classvars includes: 'one'];
                 should: [classvars includes: 'two'];
                 should: [classvars includes: 'three']
        ]

        testCats [
            | r items |
            r := cats execute.
            items := r items at: 'category'.
            self should: [items includes: 'sample-category'];
                 should: [items includes: 'accessors']
        ]

        testMethods [
            | r items |
            r := methods execute.
            items := r items at: 'method'.
            self should: [items includes: 'doSomethingElse:withArg:'];
                 should: [items includes: 'doSomething']
        ]

        testMethod [
            | r |
            "I am not sure about this test"
            r := method execute.
            self should: [r methodName = 'doSomethingElse:withArg:']
        ]

        namespacesSample [
            ^'<request id="23" type="Namespaces" />'
        ]

        classesSample [
            ^'<request id="10" type="Classes" namespace="ShampooSamples" />'
        ]

        classSample [
            ^'<request id="15" type="Class" namespace="ShampooSamples"
               class="SampleClassA" />'
        ]

        catsSample [
            ^'<request id="500" type="Categories" namespace="ShampooSamples"
               class="SampleClassB" side="instance"/>'
        ]

        methodsSample [
            ^'<request id="500" type="Methods" namespace="ShampooSamples"
               class="SampleClassB" side="instance" category="sample-category"/>'
        ]

        methodSample [
            ^'<request id="123" type="MethodSource" namespace="ShampooSamples"
               class="SampleClassB" side="instance" method="doSomethingElse:withArg:"/>'
        ]

        request: aRequestClass from: aString [
            | xml |
            xml := XML.XMLParser
                        processDocumentString: aString
                        beforeScanDo: [:p | p validate: false].
            ^aRequestClass from: xml root
        ]
    ]
]
