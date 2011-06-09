Namespace current: Smalltalk [
    Namespace current: ShampooSamples [
        Object subclass: SampleClassA [
            | a b c |

            one := 1.
            two := 2.
            three := 3.
        ]

        SampleClassA class extend [
            | d |
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

        nil subclass: SampleClassE [
        ]

        Object subclass: SampleClassSide [
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
        className [^class]
        attrs [^attrs]
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

    ShampooTestCase subclass: LoginTest [
        | login server |

        setUp [
            login := self requestFrom: self loginSample.
        ]

        testCreds [
            self should: [login creds = (UserCreds login: 'dmitry' pass: 'pass')]
        ]

        loginSample [
            ^'<request id="25" type="Login">
      <creds login="dmitry" pass="1a1dc91c907325c69271ddf0c944bc72" />
  </request>'
        ]
    ]

    ShampooTestCase subclass: NamespacesTest [
        | namespaces r items |

        setUp [
            namespaces := self requestFrom: self namespacesSample.
            r := namespaces execute.
            items := r items at: 'namespace'
        ]

        testNamespaces [
            self should: [items includes: 'Shampoo'];
                 should: [items includes: 'ShampooSamples']
        ]

        testIndirectSubspaces [
            "Currently Shampoo supports only 'root' namespaces. Indirect subspaces should not
             be included in the response"
            | indirect |
            indirect := [Namespace allInstances detect: [:each | each environment ~= Smalltalk]]
                        ifError: [nil].
            indirect ifNotNil: [self shouldnt: [items includes: indirect name]]
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
        | class nilSubclass classSide r nilr classr |

        setUp [
            class := self requestFrom: self classSample.
            nilSubclass := self requestFrom: self nilSubclassSample.
            classSide := self requestFrom: self classSideSample.
            r := class execute.
            nilr := nilSubclass execute.
            classr := classSide execute
        ]

        testSuperclass [
            self should: [(r attrs at: 'superclass') = 'Object'];
                 should: [(nilr attrs at: 'superclass') = 'nil']
        ]

        testInstvars [
            | vars |
            vars := r items at: 'instvar'.
            self should: [vars includes: 'a'];
                 should: [vars includes: 'b'];
                 should: [vars includes: 'c']
        ]

        performClassVarsTestFor: aResponse [
            | vars |
            vars := aResponse items at: 'classvar'.
            self should: [vars includes: 'one'];
                 should: [vars includes: 'two'];
                 should: [vars includes: 'three']
        ]

        testClassvars [
            self performClassVarsTestFor: r
        ]

        testClassSideInstvars [
            | vars |
            vars := classr items at: 'instvar'.
            self should: [vars includes: 'd'];
                 shouldnt: [vars includes: 'a'];
                 shouldnt: [vars includes: 'b'];
                 shouldnt: [vars includes: 'c']
        ]

        testClassSideClassvars [
            self performClassVarsTestFor: classr
        ]

        classSample [
            ^'<request id="15" type="Class" namespace="ShampooSamples"
               class="SampleClassA" side="instance"/>'
        ]

        nilSubclassSample [
            ^'<request id="15" type="Class" namespace="ShampooSamples"
               class="SampleClassE" side="instance"/>'
        ]

        classSideSample [
            ^'<request id="15" type="Class" namespace="ShampooSamples"
               class="SampleClassA" side="class"/>'
        ]
    ]

    ShampooTestCase subclass: CatsTest [
        | cats emptyCats |

        setUp [
            cats := self requestFrom: self catsSample.
            emptyCats := self requestFrom: self emptyCatsSample.
        ]

        testCats [
            | r items |
            r := cats execute.
            items := r items at: 'category'.
            self should: [items includes: 'sample-category'];
                 should: [items includes: 'accessors']
        ]

        testEmptyCats [
            | r items |
            r := emptyCats execute.
            items := r items at: 'category'.
            self should: [items isEmpty]
        ]

        catsSample [
            ^'<request id="500" type="Categories" namespace="ShampooSamples"
               class="SampleClassB" side="instance"/>'
        ]

        emptyCatsSample [
            ^'<request id="500" type="Categories" namespace="ShampooSamples"
               class="SampleClassA" side="instance"/>'
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
        | compileClass r compiledClass |

        setUp [
            compileClass := self requestFrom: self compileClassSample.
            r := compileClass execute.
            compiledClass := ShampooSamples at: #SampleClassC.
        ]

        testCompiledClass [
            self should: [compiledClass ~= nil]
        ]

        testInstvars [
            | vars |
            vars := compiledClass instVarNames asStringArray.
            self should: [vars includes: 'one'];
                 should: [vars includes: 'two'];
                 should: [vars includes: 'three']
        ]

        testClassvars [
            | vars |
            vars := compiledClass classVarNames asStringArray.
            self should: [vars includes: 'classOne'];
                 should: [vars includes: 'classTwo'];
                 should: [vars includes: 'classThree']
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

    ShampooTestCase subclass: CompileClassSideTest [
        | classSide rside classSideResult |

        setUp [
            classSide := self requestFrom: self classSideSample.
            rside := classSide execute.
            classSideResult := ShampooSamples.SampleClassSide class
        ]

        testClassInstVars [
            | vars |
            vars := classSideResult instVarNames asStringArray.
            self should: [vars includes: 'classOne'];
                 should: [vars includes: 'classTwo'];
                 should: [vars includes: 'classThree']
        ]

        classSideSample [
            ^'<request id="80" type="CompileClass" namespace="ShampooSamples" class="SampleClassSide" side="class">
      <instvar>classOne</instvar>
      <instvar>classTwo</instvar>
      <instvar>classThree</instvar>
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
