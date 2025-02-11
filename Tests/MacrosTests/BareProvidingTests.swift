import SwiftMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MacrosImplementation)
import MacrosImplementation
#endif

final class BareProvidingExpansionTests: XCTestCase {

    #if canImport(MacrosImplementation)

    // Test the marco without any parameters, with completely omitted access level explicitly (from the parameter)
    // and implicitly (from the enum declaration).
    func testExpansion_whenWithoutParameters_shouldWork() throws {
        assertMacroExpansion(
            """
            @BareProviding
            enum E {
                case a(A)
                case b(B, String)
                case cA
            }
            """,
            expandedSource: """
            enum E {
                case a(A)
                case b(B, String)
                case cA

                enum Bare: CaseIterable, Codable, Hashable, Sendable {
                    case a
                    case b
                    case cA
                }

                var bare: Bare {
                    switch self {
                    case .a:
                        .a
                    case .b:
                        .b
                    case .cA:
                        .cA
                    }
                }
            }
            """,
            macros: ["BareProviding": BareProviding.self]
        )
    }

    func testExpansion_whenWithInlineCasesDeclaration_shouldExpandAll() throws {
        assertMacroExpansion(
            """
            @BareProviding
            enum E {
                // don't expand this comment
                case a(A), b(B, String), c // don't expand this comment
                case d, e(Bool)
                /// don't expand this comment
                case f // don't expand this comment
            }
            """,
            expandedSource: """
            enum E {
                // don't expand this comment
                case a(A), b(B, String), c // don't expand this comment
                case d, e(Bool)
                /// don't expand this comment
                case f // don't expand this comment

                enum Bare: CaseIterable, Codable, Hashable, Sendable {
                    case a
                    case b
                    case c
                    case d
                    case e
                    case f
                }

                var bare: Bare {
                    switch self {
                    case .a:
                        .a
                    case .b:
                        .b
                    case .c:
                        .c
                    case .d:
                        .d
                    case .e:
                        .e
                    case .f:
                        .f
                    }
                }
            }
            """,
            macros: ["BareProviding": BareProviding.self]
        )
    }

    /// Tests also with intervening elements.
    func testExpansion_whenNilAccessModifier_shouldUseDeclarationAccessLevel() throws {
        assertMacroExpansion(
            """
            @BareProviding(accessModifier: nil, typeName: "Foo")
            public enum E: Whateverable {
                enum Intervening {}
                case a(A)
                var interveningDeclaration: String { "hello" }
                /// intervening trivia :-)
                case b(B, String)
            }
            """,
            expandedSource: """
            public enum E: Whateverable {
                enum Intervening {}
                case a(A)
                var interveningDeclaration: String { "hello" }
                /// intervening trivia :-)
                case b(B, String)

                public enum Foo: CaseIterable, Codable, Hashable, Sendable {
                    case a
                    case b
                }

                public var foo: Foo {
                    switch self {
                    case .a:
                        .a
                    case .b:
                        .b
                    }
                }
            }
            """,
            macros: ["BareProviding": BareProviding.self]
        )
    }

    func testExpansion_whenExplicitAccessModifierOnly_shouldUseIt() throws {
        assertMacroExpansion(
            """
            @BareProviding(accessModifier: .fileprivate)
            enum E {
                case a(A)
                case b(B, String)
                case cA
            }
            """,
            expandedSource: """
            enum E {
                case a(A)
                case b(B, String)
                case cA

                fileprivate enum Bare: CaseIterable, Codable, Hashable, Sendable {
                    case a
                    case b
                    case cA
                }

                fileprivate var bare: Bare {
                    switch self {
                    case .a:
                        .a
                    case .b:
                        .b
                    case .cA:
                        .cA
                    }
                }
            }
            """,
            macros: ["BareProviding": BareProviding.self]
        )
    }

    func testExpansion_whenExplicitAndImplicitAccessModifier_shouldUseExplicit() throws {
        assertMacroExpansion(
            """
            @BareProviding(accessModifier: .fileprivate)
            public enum E {
                case a(A)
            }
            """,
            expandedSource: """
            public enum E {
                case a(A)

                fileprivate enum Bare: CaseIterable, Codable, Hashable, Sendable {
                    case a
                }

                fileprivate var bare: Bare {
                    switch self {
                    case .a:
                        .a
                    }
                }
            }
            """,
            macros: ["BareProviding": BareProviding.self]
        )
    }

    func testExpansion_whenPrivate_shouldExpandAsFileprivate() throws {
        assertMacroExpansion(
            """
            @BareProviding
            private enum E {
                case a(A)
            }
            """,
            expandedSource: """
            private enum E {
                case a(A)

                fileprivate enum Bare: CaseIterable, Codable, Hashable, Sendable {
                    case a
                }

                fileprivate var bare: Bare {
                    switch self {
                    case .a:
                        .a
                    }
                }
            }
            """,
            macros: ["BareProviding": BareProviding.self]
        )
    }

    func testExpansion_whenExplicitTypeName_shouldUseIt() throws {
        assertMacroExpansion(
            """
            @BareProviding(typeName: "Baz")
            enum E {
                case a(A)
            }
            """,
            expandedSource: """
            enum E {
                case a(A)

                enum Baz: CaseIterable, Codable, Hashable, Sendable {
                    case a
                }

                var baz: Baz {
                    switch self {
                    case .a:
                        .a
                    }
                }
            }
            """,
            macros: ["BareProviding": BareProviding.self]
        )
    }

    func testExpansion_whenInvalidAccessModifier_shouldEmitDiagnostic() {
        assertMacroExpansion(
            """
            @BareProviding(accessModifier: TypeAccessModifier.public)
            enum WithInvalidAccessModifier {
                case a(Void)
            }
            """,
            expandedSource:
            """
            enum WithInvalidAccessModifier {
                case a(Void)
            }
            """,
            diagnostics: [.init(message: "Expansion type cannot have less restrictive access than its anchor declaration.", line: 1, column: 1)],
            macros: ["BareProviding": BareProviding.self]
        )
    }

    func testExpansion_whenNoAssociatedValue_shouldEmitDiagnostic() {
        assertMacroExpansion(
            """
            @BareProviding
            enum NoAssociatedValue {
                case a
            }
            """,
            expandedSource:
            """
            enum NoAssociatedValue {
                case a
            }
            """,
            diagnostics: [.init(message: "'@BareProviding' can only be attached to an enum with associated values.", line: 1, column: 1)],
            macros: ["BareProviding": BareProviding.self]
        )
    }

    func testExpansion_whenCorruptedTypeName_shouldEmitDiagnostic() {
        assertMacroExpansion(
            """
            @BareProviding(typeName: "Oh uh")
            enum Whoops {
                case a(String)
            }
            """,
            expandedSource:
            """
            enum Whoops {
                case a(String)
            }
            """,
            diagnostics: [.init(message: "Invalid type name: 'Oh uh'.", line: 1, column: 1)],
            macros: ["BareProviding": BareProviding.self]
        )
    }

    #else

    func testExpansions() throws {
        XCTSkip("macros are only supported when running tests for the host platform")
    }

    #endif
}

final class BareProvidingTests: XCTestCase {

    func testBareProviding_whenComparingAnchorWithBareCounterpart_shouldEqual() {
        XCTAssertEqual(E.a("hello").bare, .a)
        XCTAssertEqual(E.Bare.allCases, [.a, .b, .d, .c])
        XCTAssertEqual(Foo.x("dd").bar, .x)
        XCTAssertEqual(Foo.Bar.allCases, [.x, .y])
    }

    func testCoding() throws {
        let bareCase = E.Bare.a
        let encoded = try JSONEncoder().encode(bareCase)
        let decoded = try JSONDecoder().decode(E.Bare.self, from: encoded)
        XCTAssertEqual(decoded, bareCase)
    }

}

@BareProviding
private enum E {
    case a(String)
    case b(String, Int), /* don't expand this comment */ d(String) // don't expand this comment
    case c // don't expand this comment
}

@BareProviding(accessModifier: TypeAccessModifier.fileprivate, typeName: "Bar")
enum Foo {
    case x(String)
    case y(String, Int)
}
