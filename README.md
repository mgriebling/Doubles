# Doubles

A quad-double number (QDouble) is an unevaluated sum of four IEEE double-precision numbers, capable of representing at least 212 bits or 62 digits of significand.
A secondary double-double number (DDouble) is also available with twice the Double precision at 31 digits (106 bits) but is faster then QDouble.
Calculations are much faster than an equivalent software implementation since FP hardware is used.
Algorithms for various arithmetic operations (including the four basic operations and various algebraic and transcendental operations) are presented. 
A Swift implementation of these algorithms is attached, along with its interfaces.  Please report and/or fix any errors.  

If anyone can speed up the Swift benchmarks to match the C++ benchmarks (see original package https://www.davidhbailey.com/dhbsoftware/qd-2.3.23.tar.gz), that would also be appreciated.
I spent some time looking at doing this without much success.  I suspect some intrinsic overhead with type-checking or other safety-related mechanism that C++ doesn't have.
Too bad these checks can't be turned off in performance-critical code.  I know some people have success in 

Translated to Swift from an original work called qd-2.3.15 by Yozo Hida, Xiaoye S. Li, and David H. Bailey
Bug fixes incorporated from qd-2.3.22 - MG - 24 Mar 2019.

Note: Source code was translated from an original work that is:
Copyright (c) 2003-2009, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of
any required approvals from U.S. Dept. of Energy) All rights reserved. 

# Swift Examples

```
import Doubles

let x = QDouble("12345678901234567890123456789012345678901234567890123456789012")
let y = 123456789012345678901234567890.0
let two : QDouble = 2
let ptOne = QDouble("0.1")
     
print("QDouble precision \(x)\nDouble precision  \(y)")
print("Sqrt(2) = \(two.sqrt())")
print("2^1000 = \(two.pow(1000))")
print("Sqrt(\(x)^2) = \(x.sqr().sqrt())")
print("π = \(QDouble.pi)")
print("1/3 = \(QDouble(1)/3)")
print("sqrt(0.1) = \(ptOne.sqrt())")
print("sqrt(0.1)^2 = \(ptOne.sqrt().sqr())")
print("Comparison operations: \(x) == \(y) -> \(x == QDouble.zero+y)")
```

The corresponding output:

```
QDouble precision 1.23456789012345678901234567890123456789012345678901234567890120e+61
Double precision  1.2345678901234568e+29
Sqrt(2) = 1.41421356237309504880168872420969807856967187537694807317667974e+00
2^1000 = 1.07150860718626732094842504906000181056140481170553360744375039e+301
Sqrt(1.23456789012345678901234567890123456789012345678901234567890120e+61^2) = 1.23456789012345678901234567890123456789012345678901234567890120e+61
π = 3.14159265358979323846264338327950288419716939937510582097494459e+00
1/3 = 3.33333333333333333333333333333333333333333333333333333333333333e-01
sqrt(0.1) = 3.16227766016837933199889354443271853371955513932521682685750485e-01
sqrt(0.1)^2 = 1.00000000000000000000000000000000000000000000000000000000000000e-02
Comparison operations: 1.23456789012345678901234567890123456789012345678901234567890120e+61 == 1.2345678901234568e+29 -> false
```

Following are some benchmarks from a 3.6GHz 10-Core Intel Core i9:

#Swift Benchmarks

##Timing Double

```
   add:   0.000212 μs  4705.8824 mop/s 
   mul:   0.000215 μs  4651.1628 mop/s 
   div:   0.000748 μs  1337.7926 mop/s 
  sqrt:   0.001200 μs   833.3333 mop/s 
   sin:   0.018250 μs    54.7945 mop/s 
   log:   0.001000 μs  1000.0000 mop/s 
   dot:   0.000214 μs  4678.3626 mop/s 
   exp:   0.001000 μs  1000.0000 mop/s 
   cos:   0.030750 μs    32.5203 mop/s
```

##Timing DDouble

```
   add:   0.012675 μs    78.8955 mop/s 
   mul:   0.005585 μs   179.0510 mop/s 
   div:   0.009395 μs   106.4396 mop/s 
  sqrt:   0.042325 μs    23.6267 mop/s 
   sin:   0.454000 μs     2.2026 mop/s 
   log:   0.341000 μs     2.9326 mop/s 
   dot:   0.004325 μs   231.2139 mop/s 
   exp:   0.368000 μs     2.7174 mop/s 
   cos:   0.460750 μs     2.1704 mop/s
```

##Timing QDouble

```
   add:   0.053525 μs    18.6829 mop/s 
   mul:   0.124817 μs     8.0117 mop/s 
   div:   0.527525 μs     1.8956 mop/s 
  sqrt:   1.626325 μs     0.6149 mop/s 
   sin:   5.922500 μs     0.1688 mop/s 
   log:  11.939000 μs     0.0838 mop/s 
   dot:   0.046288 μs    21.6041 mop/s 
   exp:   3.253000 μs     0.3074 mop/s 
   cos:   5.614750 μs     0.1781 mop/s
```

#C++ Benchmarks

##Timing double

```
   add:   0.000208 us 4819.2771 mop/s
   mul:   0.000210 us 4761.9048 mop/s
   div:   0.000733 us 1365.1877 mop/s
  sqrt:   0.001150 us  869.5652 mop/s
   sin:   0.007250 us  137.9310 mop/s
   log:   0.005000 us  200.0000 mop/s
   dot:   0.000209 us 4790.4192 mop/s
   exp:   0.005000 us  200.0000 mop/s
   cos:   0.007500 us  133.3333 mop/s
```

##Timing dd_real

```
   add:   0.002230 us  448.4305 mop/s
   mul:   0.002975 us  336.1345 mop/s
   div:   0.006390 us  156.4945 mop/s
  sqrt:   0.011300 us   88.4956 mop/s
   sin:   0.236500 us    4.2283 mop/s
   log:   0.287000 us    3.4843 mop/s
   dot:   0.002363 us  423.2804 mop/s
   exp:   0.251000 us    3.9841 mop/s
   cos:   0.254000 us    3.9370 mop/s
```

##Timing qd_real

```
   add:   0.021325 us   46.8933 mop/s
   mul:   0.044258 us   22.5950 mop/s
   div:   0.256070 us    3.9052 mop/s
  sqrt:   0.666375 us    1.5007 mop/s
   sin:   2.489750 us    0.4016 mop/s
   log:   8.771000 us    0.1140 mop/s
   dot:   0.037615 us   26.5851 mop/s
   exp:   2.707000 us    0.3694 mop/s
   cos:   2.527750 us    0.3956 mop/s
```
