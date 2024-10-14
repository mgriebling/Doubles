# ``Doubles``
Two types (*DDouble* and *QDouble*) extending the precision of *Double*
numbers to 31 and 62 digits, respectively.

## Overview
A quad-double number ``QDouble`` is an unevaluated sum of four IEEE 
double-precision numbers, capable of representing at least 212 bits or 
62 digits of significand.

A secondary double-double number ``DDouble`` is also available with twice 
the Double precision at 31 digits (106 bits) but is faster then ``QDouble``.

Calculations are much faster than an equivalent software implementation since 
FP hardware is used.

Algorithms for various arithmetic operations (including the four basic operations and various algebraic and transcendental operations) are presented. 

Please report and/or fix any errors.  

Operation | Execution Time |  Operations per Second
---------:|-------------:|---------------:
   add:   | 0.000212 μs  | 4705.8824 mop/s 
   mul:   | 0.000215 μs  | 4651.1628 mop/s 
   div:   | 0.000748 μs  | 1337.7926 mop/s 
  sqrt:   | 0.001200 μs  |  833.3333 mop/s 
   sin:   | 0.018250 μs  |   54.7945 mop/s 
   log:   | 0.001000 μs  | 1000.0000 mop/s 
   dot:   | 0.000214 μs  | 4678.3626 mop/s 
   exp:   | 0.001000 μs  | 1000.0000 mop/s 
   cos:   | 0.030750 μs  |   32.5203 mop/s

## Topics

### Structures

``DDouble``

``QDouble``

