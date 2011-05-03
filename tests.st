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

        Object subclass: SampleClassD [
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

    TestCase subclass: ShampooTestCase [
        defaultLogPolicyClass [
            <category: 'logging'>
            ^TestVerboseLog
        ]

        requestFrom: aString [
            | xml |
            xml := XML.XMLParser
                        processDocumentString: aString
                        beforeScanDo: [:p | p validate: false].
            ^Request from: xml root
        ]
    ]

    ShampooTestCase subclass: NamespacesTest [
        | namespaces |

        setUp [
            namespaces := self requestFrom: self namespacesSample
        ]

        testNamespaces [
            | r items |
            r := namespaces execute.
            items := r items at: 'namespace'.
            self should: [items includes: 'Shampoo'];
                 should: [items includes: 'ShampooSamples']
        ]

        namespacesSample [
            ^'<request id="23" type="Namespaces" />'
        ]
    ]

    ShampooTestCase subclass: ClassesTest [
        | classes |

        setUp [
            classes := self requestFrom: self classesSample
        ]

        testClasses [
            | r items |
            r := classes execute.
            items := r items at: 'class'.
            self should: [items includes: 'SampleClassA'];
                 should: [items includes: 'SampleClassB']
        ]

        classesSample [
            ^'<request id="10" type="Classes" namespace="ShampooSamples" />'
        ]
    ]

    ShampooTestCase subclass: ClassTest [
        | class |

        setUp [
            class := self requestFrom: self classSample
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

        classSample [
            ^'<request id="15" type="Class" namespace="ShampooSamples"
               class="SampleClassA" />'
        ]
    ]

    ShampooTestCase subclass: CatsTest [
        | cats |

        setUp [
            cats := self requestFrom: self catsSample
        ]

        testCats [
            | r items |
            r := cats execute.
            items := r items at: 'category'.
            self should: [items includes: 'sample-category'];
                 should: [items includes: 'accessors']
        ]

        catsSample [
            ^'<request id="500" type="Categories" namespace="ShampooSamples"
               class="SampleClassB" side="instance"/>'
        ]
    ]

    ShampooTestCase subclass: MethodsTest [
        | methods |

        setUp [
            methods := self requestFrom: self methodsSample
        ]

        testMethods [
            | r items |
            r := methods execute.
            items := r items at: 'method'.
            self should: [items includes: 'doSomethingElse:withArg:'];
                 should: [items includes: 'doSomething']
        ]

        methodsSample [
            ^'<request id="500" type="Methods" namespace="ShampooSamples"
               class="SampleClassB" side="instance" category="sample-category"/>'
        ]
    ]

    ShampooTestCase subclass: MethodTest [
        | method |

        setUp [
            method := self requestFrom: self methodSample
        ]

        testMethod [
            | r |
            "I am not sure about this test"
            r := method execute.
            self should: [r methodName = 'doSomethingElse:withArg:']
        ]

        methodSample [
            ^'<request id="123" type="MethodSource" namespace="ShampooSamples"
               class="SampleClassB" side="instance" method="doSomethingElse:withArg:"/>'
        ]
    ]

    ShampooTestCase subclass: CompileClassTest [
        | compileClass |

        setUp [
            compileClass := self requestFrom: self compileClassSample.
        ]

        testCompileClass [
            | r compiledClass instVars classVars |
            r := compileClass execute.
            compiledClass := ShampooSamples at: #SampleClassC.
            self should: [compiledClass ~= nil].

            instVars := compiledClass instVarNames asStringArray.
            classVars := compiledClass classVarNames asStringArray.
            self should: [instVars includes: 'one'; includes: 'two'; includes: 'three'];
                 should: [classVars includes: 'classOne'; includes: 'classTwo'; includes: 'classThree']
        ]

        compileClassSample [
            ^'<request id="80" type="CompileClass" superspace="Smalltalk" super="Object" namespace="ShampooSamples" class="SampleClassC">
      <instvar>one</instvar>
      <instvar>two</instvar>
      <instvar>three</instvar>
      <classvar>classOne</classvar>
      <classvar>classTwo</classvar>
      <classvar>classThree</classvar>
      <poolvar>poolOne</poolvar>
      <poolvar>poolTwo</poolvar>
      <poolvar>poolThree</poolvar>
  </request>'
        ]
    ]

    ShampooTestCase subclass: CompileMethodTest [
         | compileMethod |

        setUp [
            compileMethod := self requestFrom: self compileMethodSample
        ]

        testCompileMethod [
            | r value |
            r := compileMethod execute.
            value := ShampooSamples.SampleClassD new sampleCompiledMethod: 11.
            self should: [value = 42]
        ]

        compileMethodSample [
            ^'<request id="80" type="CompileMethod" namespace="ShampooSamples" class="SampleClassD" side="instance">
    sampleCompiledMethod: anInteger [
        ^anInteger * 4 - 2
    ]
  </request>'
        ]
    ]
]
