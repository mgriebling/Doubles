//
//  DDouble.swift
//  ExtendedFloat
//
//  Created by Mike Griebling on 2022-01-06.
//

import Foundation

public struct DDouble {
    
    /// Storage for double-precision data type
    private(set) var x : SIMD2<Double>
    
    private static let IEEE_ADD = false     // set to true for slower IEEE-compliant adds
    private static let SLOPPY_DIV = true    // set to false for an accurate division
    private static let QD_FMS = false       // set to true for Fused-Multiply-Subtract
    
    /// Initializers
    public init()                           { x = SIMD2.zero }
    public init(_ d: Double)                { x = SIMD2(d, 0.0) }
    public init(_ h: Int)                   { x = SIMD2(Double(h), 0.0) }
    public init(_ hi: Double, _ lo: Double) { x = SIMD2(hi, lo) }
    public init(_ s: SIMD2<Double>)         { x = s }
    
    public init(_ s: String) { x = SIMD2.zero }  // TBD
    
    /// Access functions
    var hi: Double { x.x }
    var lo: Double { x.y }
    
    /*********** Micellaneous ************/
    public var isZero:Bool      { x[0].isZero }
    public var isOne:Bool       { x[0] == 1.0 && x[1].isZero }
    public var isPositive:Bool  { x[0] > 0.0 }
    public var isNegative:Bool  { x[0] < 0.0 }
    public var isNaN:Bool       { x[0].isNaN || x[1].isNaN }
    public var isFinite:Bool    { x[0].isFinite }
    public var isInfinite :Bool { x[0].isInfinite }
    
    /* Absolute value */
    public var abs: DDouble { x[0] < 0.0 ? DDouble(-x) : DDouble(x) }
    
    /* Round to Nearest integer */
    public static func nint(_ a:DDouble) -> DDouble {
        var hi = DDouble.nint(a.x[0])
        var lo = 0.0
        
        if hi == a.x[0] {
            /* High word is an integer already.  Round the low word.*/
            lo = DDouble.nint(a.x[1]);
            
            /* Renormalize. This is needed if x[0] = some integer, x[1] = 1/2.*/
            hi = DDouble.quick_two_sum(hi, lo, &lo);
        } else {
            /* High word is not an integer. */
            lo = 0.0;
            if Foundation.fabs(hi-a.x[0]) == 0.5 && a.x[1] < 0.0 {
                /* There is a tie in the high word, consult the low word
                 to break the tie. */
                hi -= 1.0      /* NOTE: This does not cause INEXACT. */
            }
        }
        return DDouble(hi, lo)
    }

    public static func floor(_ a:DDouble) -> DDouble {
        var hi = Foundation.floor(a.x[0])
        var lo = 0.0
        if hi == a.x[0] {
            /* High word is integer already.  Round the low word. */
            lo = Foundation.floor(a.x[1])
            hi = quick_two_sum(hi, lo, &lo)
        }
        return DDouble(hi, lo)
    }
    
    public static func ceil(_ a:DDouble) -> DDouble  {
        var hi = Foundation.ceil(a.x[0])
        var lo = 0.0
        
        if (hi == a.x[0]) {
            /* High word is integer already.  Round the low word. */
            lo = Foundation.ceil(a.x[1])
            hi = quick_two_sum(hi, lo, &lo)
        }
        return DDouble(hi, lo);
    }

    public static func aint(_ a: DDouble) -> DDouble { a.x[0] >= 0.0 ? floor(a) : ceil(a) }

    public var double: Double { x[0] }
    public var int: Int { Int(x[0]) }
    
    /// Internal constants
    static private var _2pi = DDouble(6.283185307179586232e+00, 2.449293598294706414e-16);
    static private var _pi = DDouble(3.141592653589793116e+00, 1.224646799147353207e-16);
    static private var _pi2 = DDouble(1.570796326794896558e+00, 6.123233995736766036e-17);
    static private var _pi4 = DDouble(7.853981633974482790e-01, 3.061616997868383018e-17);
    static private var _3pi4 = DDouble(2.356194490192344837e+00, 9.1848509936051484375e-17);
    static private var _e = DDouble(2.718281828459045091e+00, 1.445646891729250158e-16);
    static private var _log2 = DDouble(6.931471805599452862e-01, 2.319046813846299558e-17);
    static private var _log10 = DDouble(2.302585092994045901e+00, -2.170756223382249351e-16);
    static private var _nan = DDouble(Double.nan, Double.nan)
    static private var _snan = DDouble(Double.signalingNaN, Double.signalingNaN)
    static private var _inf = DDouble(Double.infinity, Double.infinity)

    static private var _eps = 4.93038065763132e-32;  // 2^-104
    static private var _min_normalized = 2.0041683600089728e-292;  // = 2^(-1022 + 53)
    static private var _max = DDouble(1.79769313486231570815e+308, 9.97920154767359795037e+291);
    static private var _safe_max = DDouble(1.7976931080746007281e+308, 9.97920154767359795037e+291);
    static private var _ndigits = 31
    
    /// Base 10 digits
    static public var digits:Int { _ndigits }
    
    /// Functions

    /* Computes fl(a+b) and err(a+b).  */
    static func two_sum(_ a:Double, _ b:Double, _ err: inout Double) -> Double {
      let s = a + b
      let bb = s - a
      err = (a - (s - bb)) + (b - bb)
      return s
    }
    
    /* Computes fl(a-b) and err(a-b).  */
    static func two_diff(_ a:Double, _ b:Double, _ err: inout Double) -> Double {
      let s = a - b
      let bb = s - a
      err = (a - (s - bb)) - (b + bb)
      return s
    }
    
    /* Computes fl(a*a) and err(a*a).  Faster than the above method. */
    static func two_sqr(_ a:Double, _ err:inout Double) -> Double {
        let p = a * a
        if QD_FMS {
            err = 0 // QD_FMS(a, a, p);
        } else {
            let ai = split(a)
            err = ((ai.h * ai.h - p) + 2.0 * ai.h * ai.l) + ai.l * ai.l
        }
        return p
    }
    
    /* Computes the nearest integer to d. */
    static func nint(_ d:Double) -> Double {
        if (d == Foundation.floor(d)) { return d }
        return Foundation.floor(d + 0.5)
    }

    /* Computes the truncated integer. */
    static func aint(_ d:Double) -> Double { (d >= 0.0) ? Foundation.floor(d) : Foundation.ceil(d) }

    /* These are provided to give consistent
       interface for double with double-double and quad-double. */
    static func sincosh(_ t:Double) -> (sinht: Double, cosht: Double) { (sinht: sinh(t), cosht: cosh(t)) }

    /*********** Squaring **********/
    public static func sqr(_ a:DDouble) -> DDouble {
        var p2 = 0.0
        let p1 = two_sqr(a.x[0], &p2)
        p2 += 2.0 * a.x[0] * a.x[1]
        p2 += a.x[1] * a.x[1]
        var s2 = 0.0
        let s1 = quick_two_sum(p1, p2, &s2)
        return DDouble(s1, s2)
    }
    
    public static func sqr(_ a:Double) -> DDouble {
        var p2 = 0.0
        let p1 = two_sqr(a, &p2)
        return DDouble(p1, p2)
    }
    
    /* double-double * (2.0 ^ exp) */
    static func ldexp(_ a:DDouble, _ exp:Int) -> DDouble { DDouble(Foundation.scalbn(a.x[0], exp), Foundation.scalbn(a.x[1], exp)) }
    static func sqr(_ t:Double) -> Double { t * t }
    
    static let _QD_SPLITTER = 134217729.0               // = 2^27 + 1
    static let _QD_SPLIT_THRESH = 6.69692879491417e+299 // = 2^996
    
    /* Computes high word and lo word of a */
    static func split(_ a:Double) -> (h: Double, l: Double) {
        if (a > _QD_SPLIT_THRESH || a < -_QD_SPLIT_THRESH) {
            let a2 = a*3.7252902984619140625e-09;  // 2^-28
            let temp = _QD_SPLITTER * a2;
            let hi = temp - (temp - a2);
            let lo = a2 - hi;
            return (h: hi * 268435456.0, l: lo * 268435456.0)
        } else {
            let temp = _QD_SPLITTER * a
            let hi = temp - (temp - a)
            return (h: hi, l: a - hi)
        }
    }
    
    /* Computes fl(a*b) and err(a*b). */
    static func two_prod(_ a:Double, _ b:Double, _ err: inout Double) -> Double {
        let p = a * b;
        if QD_FMS {
            err = 0 // QD_FMS(a, b, p)
        } else {
            let ai = split(a)
            let bi = split(b)
            err = ((ai.h * bi.h - p) + ai.h * bi.l + ai.l * bi.h) + ai.l * bi.l
        }
        return p
    }
    
    /* Computes fl(a+b) and err(a+b).  Assumes |a| >= |b|. */
    static func quick_two_sum(_ a:Double, _ b:Double, _ err: inout Double) -> Double {
      let s = a + b
      err = b - (s - a)
      return s
    }
    
    static func add(_ a:Double, _ b:Double) -> DDouble {
        var e = 0.0
        let s = two_sum(a, b, &e)
        return DDouble(s, e)
    }
    
    public static func + (_ a:DDouble, _ b:Double) -> DDouble {
        var s2 = 0.0
        var s1 = two_sum(a.x[0], b, &s2);
        s2 += a.x[1];
        s1 = quick_two_sum(s1, s2, &s2);
        return DDouble(s1, s2)
    }
    
    static func ieeeAdd(_ a:DDouble, _ b:DDouble) -> DDouble {
        var s2 = 0.0
        var s1 = two_sum(a.x[0], b.x[0], &s2);
        var t2 = 0.0
        let t1 = two_sum(a.x[1], b.x[1], &t2);
        s2 += t1;
        s1 = quick_two_sum(s1, s2, &s2);
        s2 += t2;
        s1 = quick_two_sum(s1, s2, &s2);
        return DDouble(s1, s2)
    }
    
    static func sloppyAdd(_ a:DDouble, _ b:DDouble) -> DDouble {
        var e = 0.0
        var s = two_sum(a.x[0], b.x[0], &e)
        e += (a.x[1] + b.x[1])
        s = quick_two_sum(s, e, &e)
        return DDouble(s, e)
    }
    
    static public func + (_ a:DDouble, _ b:DDouble) -> DDouble {
        if !IEEE_ADD {
            return sloppyAdd(a, b)
        } else {
            return ieeeAdd(a, b)
        }
    }

    /* double + double-double */
    public static func + (_ a:Double, _ b:DDouble) -> DDouble { b + a }
    
    /* double-double += double-double */
    public static func += (_ x: inout DDouble, _ a:DDouble) {
        if !IEEE_ADD {
            var e = 0.0
            let s = two_sum(x.x[0], a.x[0], &e)
            e += x.x[1]
            e += a.x[1]
            x.x[0] = quick_two_sum(s, e, &x.x[1])
        } else {
            var s2 = 0.0, t2 = 0.0
            var s1 = two_sum(x.x[0], a.x[0], &s2)
            let t1 = two_sum(x.x[1], a.x[1], &t2)
            s2 += t1
            s1 = quick_two_sum(s1, s2, &s2)
            s2 += t2
            x.x[0] = quick_two_sum(s1, s2, &x.x[1])
        }
    }
    
    /*********** Unary Minus ***********/
    public static prefix func - (_ x:DDouble) -> DDouble { DDouble(-x.x[0], -x.x[1]) }
    
    /* double-double - double-double */
    public static func - (_ a:DDouble, _ b:DDouble) -> DDouble {
        if !IEEE_ADD {
            var e = 0.0
            var s = two_diff(a.x[0], b.x[0], &e)
            e += a.x[1]
            e -= b.x[1]
            s = quick_two_sum(s, e, &e)
            return DDouble(s, e)
        } else {
            var s2 = 0.0
            var s1 = two_diff(a.x[0], b.x[0], &s2)
            var t2 = 0.0
            let t1 = two_diff(a.x[1], b.x[1], &t2)
            s2 += t1
            s1 = quick_two_sum(s1, s2, &s2)
            s2 += t2
            s1 = quick_two_sum(s1, s2, &s2)
            return DDouble(s1, s2)
        }
    }
    
    /* double-double -= double-double */
    public static func -= (_ x: inout DDouble, _ a: DDouble) {
        if !IEEE_ADD {
            var e = 0.0
            let s = two_diff(x.x[0], a.x[0], &e)
            e += x.x[1]
            e -= a.x[1]
            x.x[0] = quick_two_sum(s, e, &x.x[1])
        } else {
            var s2 = 0.0
            var s1 = two_diff(x.x[0], a.x[0], &s2)
            var t2 = 0.0
            let t1 = two_diff(x.x[1], a.x[1], &t2)
            s2 += t1
            s1 = quick_two_sum(s1, s2, &s2)
            s2 += t2
            x.x[0] = quick_two_sum(s1, s2, &x.x[1])
        }
    }
    
    /* double-double * double */
    public static func * (_ a:DDouble, _ b:Double) -> DDouble {
        var p2 = 0.0
        var p1 = two_prod(a.x[0], b, &p2);
        p2 += (a.x[1] * b);
        p1 = quick_two_sum(p1, p2, &p2);
        return DDouble(p1, p2)
    }

    /* double-double * double-double */
    public static func * (_ a:DDouble, _ b:DDouble) -> DDouble {
        var p2 = 0.0
        var p1 = two_prod(a.x[0], b.x[0], &p2);
        p2 += (a.x[0] * b.x[1] + a.x[1] * b.x[0]);
        p1 = quick_two_sum(p1, p2, &p2)
        return DDouble(p1, p2)
    }

    /* double * double-double */
    public static func * (_ a:Double, _ b:DDouble) -> DDouble { b * a }
    
    /*********** Self-Multiplications ************/
    /* double-double *= double */
    public static func *= (_ x: inout DDouble, _ a:Double) {
        var p2 = 0.0
        let p1 = two_prod(x.x[0], a, &p2)
        p2 += x.x[1] * a
        x.x[0] = quick_two_sum(p1, p2, &x.x[1])
    }
    
    public static func *= (_ x: inout DDouble, _ a:DDouble) {
        var p2 = 0.0
        let p1 = two_prod(x.x[0], a.x[0], &p2);
        p2 += a.x[1] * x.x[0];
        p2 += a.x[0] * x.x[1];
        x.x[0] = quick_two_sum(p1, p2, &x.x[1]);
    }
    
    /* double-double * double,  where double is a power of 2. */
    public static func mul_pwr2(_ a:DDouble, _ b:Double) -> DDouble {
        DDouble(a.x[0] * b, a.x[1] * b)
    }
    
    /* double-double / double */
    public static func / (_ a:DDouble, _ b:Double) -> DDouble {
        let q1 = a.x[0] / b   /* approximate quotient. */
        
        /* Compute  this - q1 * d */
        var p2 = 0.0
        let p1 = two_prod(q1, b, &p2)
        var e = 0.0
        let s = two_diff(a.x[0], p1, &e)
        e += a.x[1]
        e -= p2
        
        /* get next approximation. */
        let q2 = (s + e) / b
        
        /* renormalize */
        var r = DDouble()
        r.x[0] = quick_two_sum(q1, q2, &r.x[1])
        return r
    }
    
    static func sloppyDiv(_ a:DDouble, _ b:DDouble) -> DDouble {
        let q1 = a.x[0] / b.x[0];  /* approximate quotient */
        
        /* compute  this - q1 * dd */
        var r = b * q1;
        var s2 = 0.0
        let s1 = two_diff(a.x[0], r.x[0], &s2)
        s2 -= r.x[1];
        s2 += a.x[1];
        
        /* get next approximation */
        let q2 = (s1 + s2) / b.x[0];
        
        /* renormalize */
        r.x[0] = quick_two_sum(q1, q2, &r.x[1])
        return r
    }

    static func accurateDiv(_ a:DDouble, _ b:DDouble) -> DDouble {
      var q1 = a.x[0] / b.x[0];  /* approximate quotient */

      var r = a - q1 * b;
      
      var q2 = r.x[0] / b.x[0]
      r -= (q2 * b)

      let q3 = r.x[0] / b.x[0]

      q1 = quick_two_sum(q1, q2, &q2)
      r = DDouble(q1, q2) + q3
      return r
    }

    public static func / (_ a:DDouble, _ b:DDouble) -> DDouble { SLOPPY_DIV ? sloppyDiv(a, b) : accurateDiv(a, b) }
    public static func / ( _ a:Double, _ b: DDouble) -> DDouble { DDouble(a) / b }
    public static func /= (_ x: inout DDouble, _ a:DDouble) { x = x / a }
    public static func /= (_ x: inout DDouble, _ a:Double)  { x = x / a }
    
    /********** Exponentiation **********/
    /* Computes the n-th power of a double-double number.
       NOTE:  0^0 causes an error.                         */
    static func npwr(_ a:DDouble, _ n:Int) -> DDouble {
        if n == 0 {
            if a.isZero {
                print("(DDouble::npwr): Invalid argument.");
                return DDouble._nan
            }
            return DDouble(1.0)
        }
        
        var r = a
        var s = DDouble(1.0)
        var N = Foundation.abs(Int32(n))
        
        if N > 1 {
            /* Use binary exponentiation */
            while N > 0 {
                if N % 2 == 1 {
                    s *= r;
                }
                N /= 2;
                if N > 0 { r = DDouble.sqr(r) }
            }
        } else {
            s = r
        }
        
        /* Compute the reciprocal if n is negative. */
        return (n < 0) ? (1.0 / s) : s
    }

    /// Power function a ** n
    public static func ** (_ a:DDouble, _ n:Int) -> DDouble { npwr(a, n) }
    
}

infix operator ** : ExponentPrecedence
precedencegroup ExponentPrecedence {
    associativity: left
    higherThan: MultiplicationPrecedence
}

extension DDouble : Comparable {
    /*********** Equality Comparisons ************/
    public static func == (_ a:DDouble,_ b:Double) -> Bool  { a.x[0] == b && a.x[1] == 0.0 }
    public static func == (_ a:DDouble,_ b:DDouble) -> Bool { a.x[0] == b.x[0] && a.x[1] == b.x[1] }
    public static func == (_ a:Double, _ b:DDouble) -> Bool { a == b.x[0] && b.x[1] == 0.0 }
    
    /*********** Less-Than Comparisons ************/
    public static func < (_ a:DDouble,_ b:Double) -> Bool   { a.x[0] < b || (a.x[0] == b && a.x[1] < 0.0) }
    public static func < (_ a:DDouble,_ b:DDouble) -> Bool  { a.x[0] < b.x[0] || (a.x[0] == b.x[0] && a.x[1] < b.x[1]) }
    public static func < (_ a:Double, _ b:DDouble) -> Bool  { a < b.x[0] || (a == b.x[0] && b.x[1] > 0.0) }
    
    /*********** Greater-Than Comparisons ************/
    public static func > (_ a: DDouble,_ b:Double) -> Bool  { a.x[0] > b || (a.x[0] == b && a.x[1] > 0.0) }
    public static func > (_ a: DDouble,_ b:DDouble) -> Bool { a.x[0] > b.x[0] || (a.x[0] == b.x[0] && a.x[1] > b.x[1]) }
    public static func > ( _ a:Double, _ b:DDouble) -> Bool { a > b.x[0] || (a == b.x[0] && b.x[1] < 0.0) }
    
    public static func >= (_ a:DDouble,_ b:Double) -> Bool  { a.x[0] > b || (a.x[0] == b && a.x[1] >= 0.0) }
    public static func >= (_ a:DDouble,_ b:DDouble) -> Bool { a.x[0] > b.x[0] || (a.x[0] == b.x[0] && a.x[1] >= b.x[1]) }
    
    public static func <= (_ a:DDouble,_ b:Double) -> Bool  { a.x[0] < b || (a.x[0] == b && a.x[1] <= 0.0) }
    public static func <= (_ a:DDouble,_ b:DDouble) -> Bool { a.x[0] < b.x[0] || (a.x[0] == b.x[0] && a.x[1] <= b.x[1]) }
}

public struct FmtFlags: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) { self.rawValue = rawValue }

    static let dec = FmtFlags(rawValue: 1 << 0)
    static let oct = FmtFlags(rawValue: 1 << 1)
    static let hex = FmtFlags(rawValue: 1 << 2)
    
    static let left = FmtFlags(rawValue: 1 << 3)
    static let right = FmtFlags(rawValue: 1 << 4)
    static let intern = FmtFlags(rawValue: 1 << 5)
    
    static let scientific = FmtFlags(rawValue: 1 << 6)
    static let fixed = FmtFlags(rawValue: 1 << 7)
    
    static let baseField: FmtFlags = [.dec, .oct, .hex]
    static let adjustField: FmtFlags = [.left, .right, .intern]
    static let floatField: FmtFlags = [.scientific, .fixed]
}

extension DDouble : CustomStringConvertible {
    
    func to_digits(_ s: inout String, _ expn: inout Int, _ precision:Int) {
        let D = precision + 1  /* number of digits to compute */
        var r = self.abs
        
        if x[0] == 0.0 {
            /* self == 0.0 */
            expn = 0
            s += "".padding(toLength: precision, withPad: "0", startingAt: 0)
            return
        }
        
        /* First determine the (approximate) exponent. */
        var e = Int(Foundation.floor(Foundation.log10(Foundation.fabs(x[0]))))
        if e < -300 {
            r *= DDouble(10.0) ** 300
            r /= DDouble(10.0) ** (e + 300)
        } else if e > 300 {
            r = DDouble.ldexp(r, -53)
            r /= DDouble(10.0) ** e
            r = DDouble.ldexp(r, 53)
        } else {
            r /= DDouble(10.0) ** e
        }
        
        /* Fix exponent if we are off by one */
        if (r >= 10.0) {
            r /= 10.0;
            e+=1
        } else if (r < 1.0) {
            r *= 10.0;
            e-=1
        }
        
        if (r >= 10.0 || r < 1.0) {
            print("(DDouble.to_digits): can't compute exponent.")
            return
        }
        
        /* Extract the digits */
        for _ in 0..<D {
            let d = Int(r.x[0])
            r -= DDouble(d)
            r *= 10.0
            s += String(d)
        }
        
        /* Fix out of range digits. */
        for i in stride(from: D-1, to: 0, by: -1) {
            if s[i] < "0" {
                s[i-1]-=1
                s[i] += 10
            } else if s[i] > "9" {
                s[i-1]+=1
                s[i] -= 10
            }
        }
        
        if s[0] <= "0" {
            print("(DDouble.to_digits): non-positive leading digit.")
            return
        }
        
        /* Round, handle carry */
        if s[D-1] >= "5" {
            s[D-2]+=1
            
            var i = D-2
            while i > 0 && s[i] > "9" {
                s[i] -= 10
                i -= 1
                s[i] += 1
            }
        }
        
        /* If first digit is 10, shift everything. */
        if s[0] > "9" {
            e+=1
            s = "10" + s
        }
        expn = e
    }
    
    func roundString(_ s: inout String, _ precision: inout Int, offset: inout Int) {
        /*
         Input string must be all digits or errors will occur.
         */
        let D = precision
        var chs = [Character](s)
        
        /* Round, handle carry */
        if D>0 && chs[D] >= "5" {
            chs[D-1] += 1
            
            var i = D-1
            while i > 0 && chs[i] > "9" {
                chs[i] -= 10
                i -= 1
                s[i] += 1
            }
        }
        
        /* If first digit is 10, shift everything. */
        if (chs[0] > "9") {
            // e++; // don't modify exponent here
            for i in stride(from: precision, through: 1, by: -1) { s[i+1] = s[i] }
            s[0] = "1";
            s[1] = "0";
            
            offset+=1    // now offset needs to be increased by one
            precision+=1
        }
        s = String(chs)
    }
 
    public func toString(_ precision:Int=0, _ width:Int=0, _ fmt:FmtFlags=[], _ showpos:Bool = false, _ uppercase:Bool = false, _ fill: Character = " ") -> String {
        var s = ""
        let fixed = fmt.contains(.fixed)
        var sgn = true
        var e = 0
        
        if self.isNaN {
            s = uppercase ? "NAN" : "nan"
            sgn = false
        } else {
            if self < 0.0 {
                s += "-"
            } else if showpos {
                s += "+"
            } else {
                sgn = false
            }
            
            if self.isInfinite {
                s += uppercase ? "INF" : "inf"
            } else if self.isZero {
                /* Zero case */
                s += "0"
                if precision > 0 {
                    s += "."
                    s += "".padding(toLength: precision, withPad: "0", startingAt: 0)
                }
            } else {
                /* Non-zero case */
                var off = fixed ? (1 + DDouble.floor(DDouble.log10(self.abs)).int) : 1
                var d = precision + off
                
                var d_with_extra = d
                if fixed {
                    d_with_extra = max(60, d) // longer than the max accuracy for DD
                }
                
                // highly special case - fixed mode, precision is zero, abs(*this) < 1.0
                // without this trap a number like 0.9 printed fixed with 0 precision prints as 0
                // should be rounded to 1.
                if fixed && (precision == 0) && (self.abs < 1.0) {
                    if self.abs >= 0.5 {
                        s += "1"
                    } else {
                        s += "0"
                    }
                    return s
                }
                
                // handle near zero to working precision (but not exactly zero)
                if (fixed && d <= 0) {
                    s += "0";
                    if (precision > 0) {
                        s += ".";
                        s += "".padding(toLength: precision, withPad: "0", startingAt: 0)
                    }
                } else { // default
                    var t="" //  = new char[d+1];
                    if (fixed) {
                        to_digits(&t, &e, d_with_extra);
                    } else {
                        to_digits(&t, &e, d);
                    }
                    
                    off = e + 1;
                    
                    if fixed {
                        // fix the string if it"s been computed incorrectly
                        // round here in the decimal string if required
                        roundString(&t, &d, offset: &off);
                        
                        if (off > 0) {
                            for _ in 0..<off { s.append(t.removeFirst()) }
                            if precision > 0 {
                                s += "."
                                for _ in 0..<precision { s.append(t.removeFirst()) }
                            }
                        } else {
                            s += "0."
                            if off < 0 { s += "".padding(toLength: -off, withPad: "0", startingAt: 0) }
                            for _ in 0..<d { s.append(t.removeFirst()) }
                        }
                    } else {
                        s.append(t.removeFirst())
                        if (precision > 0) { s += "." }
                        for _ in 1...precision { s.append(t.removeFirst()) }
                    }
                }
            }
            
            // trap for improper offset with large values
            // without this trap, output of values of the for 10^j - 1 fail for j > 28
            // and are output with the point in the wrong place, leading to a dramatically off value
            if (fixed && (precision > 0)) {
                // make sure that the value isn't dramatically larger
                let from_string = atof(s.cString(using: .ascii))
                
                // if this ratio is large, then we"ve got problems
                if fabs(from_string / self.x[0]) > 3.0 {
                    // loop on the string, find the point, move it up one
                    // don't act on the first character
                    for (i,c) in s.dropFirst().enumerated() {
                        if c == "." {
                            let dot = s.remove(at: s.index(s.startIndex, offsetBy: i))
                            s.insert(dot, at: s.index(s.startIndex, offsetBy: i-1))
                            break
                        }
                    }
                    
                    let from_string = atof(s.cString(using: .ascii))
                    // if this ratio is large, then the string has not been fixed
                    if fabs(from_string / self.x[0]) > 3.0 {
                        print("Re-rounding unsuccessful in large number fixed point trap.") ;
                    }
                }
            }
            
            
            if !fixed && !self.isInfinite {
                /* Fill in exponent part */
                s += uppercase ? "E" : "e";
                append_expn(&s, e);
            }
        }
        
        /* Fill in the blanks */
        let len = s.count
        if len < width {
            let delta = width - len
            let pad = "".padding(toLength: delta, withPad: String(fill), startingAt: 0)
            if fmt.contains(.intern) {
                if sgn {
                    let index = s.index(s.startIndex, offsetBy: 1)
                    s.insert(contentsOf: pad, at:index)
                } else {
                    s.insert(contentsOf: pad, at: s.startIndex)
                }
            } else if fmt.contains(.left) {
                s += pad
            } else {
                s.insert(contentsOf: pad, at: s.startIndex)
            }
        }
        
        return s
    }
    
    private func append_expn(_ str: inout String, _ expn: Int) {
        str += expn < 0 ? "-" : "+"
        var expn = Swift.abs(expn)
        
        var k: Int
        if expn >= 100 {
            k = (expn / 100);
            str += String(k)
            expn -= 100*k;
        }
        
        k = (expn / 10);
        str += String(k)
        expn -= 10*k
        
        str += String(expn)
    }
    
    public var description: String { self.toString() }
    
}

extension DDouble : ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) { self.init(value) }
}

extension DDouble : ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) { self.init(value) }
}

extension DDouble : Strideable {
    public func distance(to other: DDouble) -> DDouble { (self - other).abs }
    public func advanced(by n: DDouble) -> DDouble { self + n }
}

extension DDouble : Numeric {
    
    public var magnitude: DDouble { self.abs }
    
    private static var bits:Int { 104 }
    
    public init?<T>(exactly source: T) where T : BinaryInteger {
        if source.bitWidth > DDouble.bits  { return nil }
        self.init(source)
    }
}

extension DDouble : FloatingPoint {
    
    public mutating func round(_ rule: FloatingPointRoundingRule) {
        switch rule {
            case .awayFromZero: break;
            case .down: break;
            case .toNearestOrAwayFromZero: self = DDouble.nint(self) // normal rounding
            case .toNearestOrEven: break;
            case .up: break;
            case .towardZero: self = DDouble.aint(self)  // aka truncate
            @unknown default: assertionFailure("DDouble: Unknown rounding rule \(rule)")
        }
    }
    
    public static var radix: Int { Double.radix }
    public static var nan: DDouble { _nan }
    public static var pi: DDouble { _pi  }
    public static var infinity: DDouble { _inf }
    public static var signalingNaN: DDouble { _snan }
    public static var greatestFiniteMagnitude: DDouble { _max }
    public static var leastNormalMagnitude: DDouble { DDouble(_min_normalized) }
    public static var leastNonzeroMagnitude: DDouble { DDouble(_eps) }
    
    public var sign: FloatingPointSign { self.isNegative ? .minus : .plus }
    public var ulp: DDouble {
        DDouble(DDouble._eps) // TBD
    }
    
    public var exponent: Int { self.x[0].exponent }
    
    public var significand: DDouble {
        self * 2 ** -self.exponent // TBD
    }
    
    public mutating func formRemainder(dividingBy other: DDouble) { self = self * other - self / other }
    
    public mutating func formTruncatingRemainder(dividingBy other: DDouble) {
        self.formRemainder(dividingBy: other)
        self = DDouble.aint(self)
    }
    
    public mutating func formSquareRoot() { self = DDouble.sqrt(self) }
    public mutating func addProduct(_ lhs: DDouble, _ rhs: DDouble) { self += lhs * rhs }
    
    public var nextUp: DDouble { self+self.ulp }
    
    public func isEqual(to other: DDouble) -> Bool { self == other }
    public func isLess(than other: DDouble) -> Bool { self < other }
    public func isLessThanOrEqualTo(_ other: DDouble) -> Bool { self <= other }
    public func isTotallyOrdered(belowOrEqualTo other: DDouble) -> Bool { self <= other }
    
    public var isNormal: Bool { self.x[0].isNormal }
    public var isSubnormal: Bool { self.x[0].isSubnormal }
    public var isSignalingNaN: Bool { self.x[0].isSignalingNaN }
    public var isCanonical: Bool { self.x[0].isCanonical }
    
    
    public init(sign: FloatingPointSign, exponent: Int, significand: DDouble) {
        let n = sign == .minus ? -1.0 : 1.0
        self = n * significand * 2 ** exponent
    }
    
    public init(signOf s: DDouble, magnitudeOf m: DDouble) {
        let n = s.sign == .minus ? -1.0 : 1.0
        self = m.abs * n
    }
    
    public init<Source>(_ value: Source) where Source : BinaryInteger {
        var a = DDouble()
        let sign = value.signum()
        var x = value.magnitude
        let divisor = 1 << Swift.min(value.bitWidth, 31)
        var scaling = DDouble(1.0)
        while x > 0 {
            let qr = x.quotientAndRemainder(dividingBy: Source.Magnitude(divisor))
            a += Double(Int(qr.remainder)) * scaling
            scaling *= Double(divisor)
            x = qr.quotient
        }
        a *= Double(Int(sign))
        self.init(a.x)
    }
    
    /// Computes the square root of the double-double number dd.
    ///   NOTE: dd must be a non-negative number.
    public static func sqrt(_ a:DDouble) -> DDouble {
        /* Strategy:  Use Karp's trick:  if x is an approximation
         to sqrt(a), then
         
         sqrt(a) = a*x + [a - (a*x)^2] * x / 2   (approx)
         
         The approximation is accurate to twice the accuracy of x.
         Also, the multiplication (a*x) and [-]*x can be done with
         only half the precision.
         */
        
        if a.isZero { return 0.0 }
        
        if a.isNegative {
            print("(DDouble.sqrt): Negative argument.")
            return _nan
        }
        
        let x = 1.0 / a.x[0].squareRoot()
        let ax = a.x[0] * x
        return DDouble.add(ax, (a - DDouble.sqr(ax)).x[0] * (x * 0.5))
    }
    
    
    /// Exponential.  Computes exp(x) in double-double precision.
    public static func exp(_ a: DDouble) -> DDouble {
        /* Strategy:  We first reduce the size of x by noting that
         
         exp(kr + m * log(2)) = 2^m * exp(r)^k
         
         where m and k are integers.  By choosing m appropriately
         we can make |kr| <= log(2) / 2 = 0.347.  Then exp(r) is
         evaluated using the familiar Taylor series.  Reducing the
         argument substantially speeds up the convergence.       */
        let k = 512.0
        let inv_k = 1.0 / k
        
        if a.x[0] <= -709.0 { return 0.0 }
        if a.x[0] >= 709.0 { return _inf }
        if a.isZero { return 1.0 }
        if a.isOne { return _e }
        
        let m = Foundation.floor(a.x[0] / _log2.x[0] + 0.5)
        let r = mul_pwr2(a - _log2 * m, inv_k)
        
        var p = sqr(r);
        var s = r + mul_pwr2(p, 0.5);
        p *= r;
        var t = p * DDouble(inv_fact[0][0], inv_fact[0][1])
        var i = 0
        repeat {
            s += t;
            p *= r;
            i += 1
            t = p * DDouble(inv_fact[i][0], inv_fact[i][1]);
        } while (Swift.abs(t.double) > inv_k * _eps && i < 5)
        
        s += t
        
        s = mul_pwr2(s, 2.0) + sqr(s)
        s = mul_pwr2(s, 2.0) + sqr(s)
        s = mul_pwr2(s, 2.0) + sqr(s)
        s = mul_pwr2(s, 2.0) + sqr(s)
        s = mul_pwr2(s, 2.0) + sqr(s)
        s = mul_pwr2(s, 2.0) + sqr(s)
        s = mul_pwr2(s, 2.0) + sqr(s)
        s = mul_pwr2(s, 2.0) + sqr(s)
        s = mul_pwr2(s, 2.0) + sqr(s)
        s += 1.0
        
        return ldexp(s, Int(m))
    }
    
    /// Logarithm.  Computes log(x) in double-double precision.
    ///   This is a natural logarithm (i.e., base e).
    public static func log(_ a: DDouble) -> DDouble {
        /* Strategy.  The Taylor series for log converges much more
         slowly than that of exp, due to the lack of the factorial
         term in the denominator.  Hence this routine instead tries
         to determine the root of the function
         
         f(x) = exp(x) - a
         
         using Newton iteration.  The iteration is given by
         
         x' = x - f(x)/f'(x)
         = x - (1 - a * exp(-x))
         = x + a * exp(-x) - 1.
         
         Only one iteration is needed, since Newton's iteration
         approximately doubles the number of digits per iteration. */
        
        if a.isOne { return 0.0 }
        
        if a.x[0] <= 0.0 {
            print("(DDouble.log): Non-positive argument.")
            return _nan
        }
        
        var x = DDouble(Foundation.log(a.x[0]))  /* Initial approximation */
        x = x + a * exp(-x) - 1.0
        return x
    }

    public static func log10(_ a: DDouble) -> DDouble { log(a) / _log10 }
    
    static let inv_fact : [[Double]] = [
      [ 1.66666666666666657e-01,  9.25185853854297066e-18],
      [ 4.16666666666666644e-02,  2.31296463463574266e-18],
      [ 8.33333333333333322e-03,  1.15648231731787138e-19],
      [ 1.38888888888888894e-03, -5.30054395437357706e-20],
      [ 1.98412698412698413e-04,  1.72095582934207053e-22],
      [ 2.48015873015873016e-05,  2.15119478667758816e-23],
      [ 2.75573192239858925e-06, -1.85839327404647208e-22],
      [ 2.75573192239858883e-07,  2.37677146222502973e-23],
      [ 2.50521083854417202e-08, -1.44881407093591197e-24],
      [ 2.08767569878681002e-09, -1.20734505911325997e-25],
      [ 1.60590438368216133e-10,  1.25852945887520981e-26],
      [ 1.14707455977297245e-11,  2.06555127528307454e-28],
      [ 7.64716373181981641e-13,  7.03872877733453001e-30],
      [ 4.77947733238738525e-14,  4.39920548583408126e-31],
      [ 2.81145725434552060e-15,  1.65088427308614326e-31]
    ]
    
}

