# [Mojo🔥: a deep dive on ownership with Chris Lattner](https://www.youtube.com/watch?v=9ag0fPMmYPQ)

## LValue vs RValue vs BValue

### RValue: an owned value
- unqiue ownership
    - funcion results are typically "owned"
    - result of transfer operator is owned: `somevalue^`
- can be passed to "owned" arguments without copy
    - similar to pass by value in C++  

### LValue: that which can be assigned / mutated
- something that may be mutated
    - assigned to
    - passed `inout`
    - mutable reference taken
    - no-alias due to exclusivity (TODO)
- similar to pass by reference in C++
- Owned args take `RValue` on caller but are `LValue` on callee side

### BValue: Borrowing someone else's toy
- a reference to value owned by someone else
    - can read from it
    - can form an immutable reference
    - very important to avoid copies
    - can alias other BValues, but not LValues (TODO)
- similar to `borrowed` arguments (like C++'s `const&`)

### Conversions between RValue, LValue, and BValue

| From | BValue <br> `fn f1(bv: String):` | RValue <br> `String("🔥")` | LValue <br> `fn f2(inout lv: String):` |
| :--- | :--- | :--- | :--- |
| **To: BValue** <br> `fn b(s: String):` | ✅ <br> `b(bv)` | "decay reference" <br> `b("🔥")` | "decay reference" <br> `b(lv)` |
| **To: RValue** <br> `fn r(owned s: String):` | "copyinit" <br> `r(bv)` | ✅ <br> `r("🔥")` | "copyinit" <br> `r(lv)` |
| **To: LValue** <br> `fn l(inout s: String):` | ☠️ | ☠️ | ✅ <br> `l(lv)` |

## What if I know this is the last use?
- Common pattern: build something up, then hand it off
- Transfer operator `^` forms an RValue from BValue or LValue without copying
    - "Just" a performance optimization for types like String
    - Required for correctness for non-copyable types
- Only safe if unused after this point, but type checker isn't context sensitive
    -> dataflow

## Dataflow Lifetime Tracking "Check Lifetimes"

### Problems
- Uninitalization checking
    - Flow sensitive problem, must handle if, loop, exceptions, reincarantion, closures....
    - argument conventions
- "ASAP" Destructor insertion
    - As before, requires precise reasoning about value cretion and destruction
    - Upside
        - early release enables tail calls - dtors doesn't end up after the tail call
        - reduces memory usage by freeing values earlier
        - enables automatic copy => move optimizations...
    - Rust references living too long end up conflicting for exclusivity checks (Non-Lexical Lifetimes solved this)
        - Getting this right eliminates a bunch of special cases and weirdness
    - Downside: defeats RAII patterns... but...
        - should use "with" in Python anyway (== handle resource explicitly is better)
        - we want freedom to optimize temporaries away

### 🔥 is a smartypants: "field sensitive" as well
- only "trackable values" are field sensitive:
    - supporting field sensitivity is key for usability, a hopefully user-intuitive concept
    - values obviously exposed directly to the compiler, vars, arg decls etc, not aliased pointers
