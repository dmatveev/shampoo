Namespace current: Smalltalk [
    Namespace current: ShampooSamples [
        Object subclass: SampleClassA [
            <category: 'Shampoo-Tests'>
            | a b c |

            one := 1.
            two := 2.
            three := 3.
        ]

        SampleClassA class extend [
            | d |
        ]

        Object subclass: SampleClassB [
            <category: 'Shampoo-Tests'>
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
            <category: 'Shampoo-Tests'>
        ]

        nil subclass: SampleClassE [
            <category: 'Shampoo-Tests'>
        ]

        Object subclass: SampleClassSide [
            <category: 'Shampoo-Tests'>
        ]
    ]
]

Namespace current: Shampoo [
    "We do not need these methods in the original implementation but do need it
for tests"

    Response extend [
        id [
            <category: '*Shampoo-Tests'>
            ^id
        ]
    ]

    OperationalResponse extend [
        success [
            <category: '*Shampoo-Tests'>
            ^success
        ]
    ]

    ClassInfoResponse extend [
        className [
            <category: '*Shampoo-Tests'>
            ^class
        ]

        attrs [
            <category: '*Shampoo-Tests'>
            ^attrs
        ]
    ]

    MethodResponse extend [
        methodName [
            <category: '*Shampoo-Tests'>
            ^methodName
        ]
        
        methodSource [
            <category: '*Shampoo-Tests'>
            ^methodSource
        ]
    ]

    TestCase subclass: ShampooTestCase [
        <category: 'Shampoo-Tests'>

        defaultLogPolicyClass [
            <category: 'logging'>
            ^TestVerboseLog
        ]

        requestFrom: aString [
            ^Request from: (ShampooXML.ShNode from: aString)
        ]
    ]

    ShampooTestCase subclass: LoginTest [
        <category: 'Shampoo-Tests'>

        | login server info |

        setUp [
            "Magic is 1337"
            info := AuthInfo login: 'dmitry' pass: 'pass'.
            login := self requestFrom: self loginSample.
        ]

        testCreds [
            self should: [login creds = (info with: 1337)]
        ]

        loginSample [
            ^'<request id="25" type="Login">
      <creds login="dmitry" magic="0bf2f198be57c763af1c9a6f2359fdc8" />
  </request>'
        ]
    ]

    ShampooTestCase subclass: NamespacesTest [
        <category: 'Shampoo-Tests'>

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
        <category: 'Shampoo-Tests'>

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
        <category: 'Shampoo-Tests'>

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
        <category: 'Shampoo-Tests'>

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
        <category: 'Shampoo-Tests'>

        | methods asterisk |

        setUp [
            methods := self requestFrom: self methodsSample.
            asterisk := self requestFrom: self asteriskSample.
        ]

        testMethods [
            | r items |
            r := methods execute.
            items := r items at: 'method'.
            self should: [items includes: 'doSomethingElse:withArg:'];
                 should: [items includes: 'doSomething'];
                 shouldnt: [items includes: 'foo'];
                 shouldnt: [items includes: 'bar']
        ]

        testAsterisk [
            | r items |
            r := asterisk execute.
            items := r items at: 'method'.
            self should: [items includes: 'doSomethingElse:withArg:'];
                 should: [items includes: 'doSomething'];
                 should: [items includes: 'foo'];
                 should: [items includes: 'bar']
        ]

        methodsSample [
            ^'<request id="500" type="Methods" namespace="ShampooSamples"
               class="SampleClassB" side="instance" category="sample-category"/>'
        ]

        asteriskSample [
            ^'<request id="500" type="Methods" namespace="ShampooSamples"
               class="SampleClassB" side="instance" category="*"/>'
        ]
    ]

    ShampooTestCase subclass: MethodTest [
        <category: 'Shampoo-Tests'>

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
        <category: 'Shampoo-Tests'>

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
        <category: 'Shampoo-Tests'>

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
        <category: 'Shampoo-Tests'>

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

    ShampooTestCase subclass: DoItTest [
        <category: 'Shampoo-Tests'>

        | doit locals |

        setUp [
            ShampooSamples at: #someUniqueKeyForDoIt put: nil.
            doit := self requestFrom: self doItSample.
            locals := self requestFrom: self localsDoItSample.
        ]

        testDoIt [
            | r |
            r := doit execute.
            self should: [42 = (ShampooSamples at: #someUniqueKeyForDoIt)];
                 should: [r statusString = 'success']
        ]

        testWithLocals [
            | r |
            r := locals execute.
            self should: ['149' = (ShampooSamples at: #someUniqueKeyForLocals)]
        ]

        doItSample [
            ^'<request id="80" type="DoIt">ShampooSamples at: #someUniqueKeyForDoIt put: 42</request>'
        ]

        localsDoItSample [
            ^'<request id="80" type="DoIt">
            | c d |
            c := OrderedCollection new.
            c add: 1; add: 2; add: 3.
            d := (c collect: [:e | e squared])
                inject: String new
                into: [:a :e | a, e asString].
            ShampooSamples at: #someUniqueKeyForLocals put: d
            </request>'
        ]
    ]

    ShampooTestCase subclass: PrintItTest [
        <category: 'Shampoo-Tests'>

        | printit |

        setUp [
            printit := self requestFrom: self printItSample
        ]

        testPrintIt [
            | r |
            r := printit execute.
            self should: [r value = 8]
        ]

        printItSample [
            ^'<request id="80" type="PrintIt">2 + 2 * 2</request>'
        ]
    ]

    ShampooTestCase subclass: OperationalResponseTest [
        <category: 'Shampoo-Tests'>

        | succ fail |

        setUp [
            succ := OperationalResponse success: 1.
            fail := OperationalResponse failure: 1.
        ]

        testSuccess [
            self should: [succ statusString = 'success']
        ]

        testFailure [
            self should: [fail statusString = 'failure']
        ]
    ]
]
