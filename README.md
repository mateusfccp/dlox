# dlox

![https://pub.dev/packages/dlox](https://img.shields.io/pub/v/dlox?include_prereleases) ![https://www.gnu.org/licenses/gpl-3.0.en.html](https://img.shields.io/badge/license-GPLv3-blue)

An implementation of the Lox language in Dart.

Lox is a didactic language as proposed in the book [Crafting Interpreters](https://www.craftinginterpreters.com). In the first part of the book, the autor guides the reader in the process of making an interpreter for the Lox language in Java.

This is a Dart adaptation of the proposed Java code for fun and for learning. Although most of the implementation is near identical to the Java one, there are some adaptations that I chose to made and some simplifications that the Dart language allowed me to do.

After I implement all the proposed code in the book (i.e. up to chapter 13), I am going to implement some of the challenges that the author left, as an extra, and maybe even some personal changes, as long as they don't break the base Lox language. Thus, this can be viewed as a superset of Lox.

## Roadmap

### Book roadmap

- [x] Scanner (Chapter 4)
- [x] Basic code representation, visitors (Chapter 5)
- [x] Expressions (Chapter 6, 7)
- [x] Statements (Chapter 8)
- [x] Control Flow (Chapter 9)
- [x] Functions (Chapter 10)
- [x] Resolving and Binding (Chapter 11)
- [x] Classes (Chapter 12)
- [x] Inheritance (Chapter 13)

### Challenges

- [ ] Multiline comments (Chapter 4, challenge 4)
- [ ] Comma expressions (Chapter 6, challenge 1)
- [ ] Conditional ternary operator (Chapter 6, challenge 2)
- [ ] Handle binary operators without a left-hand operand (Chapter 6, challenge 3)
- [ ] Allow adding `string` + `any` with implicitly conversion (Chapter 7, challenge 2)
- [ ] Handle division by zero (Chapter 7, challenge 3)
- [ ] Support REPL after it was removed (Chapter 8, challenge 1)
- [ ] `break` keyword for loops (Chapter 9, challenge 3)
- [ ] Anonymous functions (Chapter 10, challenge 2)
- [ ] Non-used variables (Chapter 11, challenge 2)
- [ ] Use integer index instead of name in variable resolution (Chapter 11, challenge 3)
- [ ] Static methods (Chapter 12, challenge 1)
- [ ] Getters/setters (Chapter 12, challenge 2)

### Intended features not proposed by the book

- [x] `unless` control flow (syntax sugar)
- [ ] `do-while` control flow (syntax sugar) 

### Other intended improvements

- [ ] Use Dart macros to generate AST
- [x] Implement tests
  - Maybe the tests are not extremely exhaustive, but it covers everything I could think of. More tests can be added every time we find a language bug.
