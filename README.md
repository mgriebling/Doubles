# QuadReals

A quad-double number (Quad) is an unevaluated sum of four IEEE double precision numbers, capable of representing at least 212 bits of significand. Algorithms for various arithmetic operations (including the four basic operations and various algebraic and transcendental operations) are presented. A Swift implementation of these algorithms is attached, along with its interfaces.

Translated to Swift from an original work called qd-2.3.15 by Yozo Hida, Xiaoye S. Li, and David H. Bailey
Bug fixes incorporated from qd-2.3.22 - MG - 24 Mar 2019.

(Original) work was supported by the Director, Office of Science, Division of Mathematical, Information, and Computational Sciences of the U.S. Department of Energy under contract number DE-AC03-76SF00098.

Copyright (c) 2000-2007

# Swift Examples

```
   let x = Quad("123456789012345678901234567890")
   let y = 123456789012345678901234567890.0
   let two : Quad = "2"
   let ptOne = Quad("0.1")
        
   print("Quad-Double precision \(x)\nDouble precision \(y)")
   print("Sqrt(2) = \(two.sqrt())")
   print("2^1000 = \(two.pow(1000))")
   print("Sqrt(\(x)^2) = \(x.sqr().sqrt())")
   print("π = \(Quad.pi)")
   print("1/3 = \(Quad(1)/3)")
   print("sqrt(0.1) = \(ptOne.sqrt())")
   print("sqrt(0.1)^2 = \(ptOne.sqrt().sqr())")
   print("Comparison operations: \(x) == \(y) -> \(x == Quad.zero+y)")
```

The corresponding output:

```
Quad-Double precision 1.23456789012345678901234567890000000000000000000000000000000000e+29
Double precision 1.2345678901234568e+29
Sqrt(2) = 1.41421356237309504880168872420969807856967187537694807317667974e+00
2^1000 = 1.07150860718626732094842504906000181056140481170553360744375039e+301
Sqrt(1.23456789012345678901234567890000000000000000000000000000000000e+29^2) = 1.23456789012345678901234567890000000000000000000000000000000000e+29
π = 3.14159265358979323846264338327950288419716939937510582097494459e+00
1/3 = 3.33333333333333333333333333333333333333333333333333333333333333e-01
sqrt(0.1) = 3.16227766016837933199889354443271853371955513932521682685750485e-01
sqrt(0.1)^2 = 1.00000000000000000000000000000000000000000000000000000000000000e-02
Comparison operations: 1.23456789012345678901234567890000000000000000000000000000000000e+29 == 1.2345678901234568e+29 -> false
```
