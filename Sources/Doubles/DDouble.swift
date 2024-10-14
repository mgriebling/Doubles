import Foundation

//  Translated to Swift from an original work called qd-2.3.15
//  by Yozo Hida, Xiaoye S. Li, and David H. Bailey
//  Bug fixes incorporated from qd-2.3.23 - MG - 24 Mar 2019.
//
//  Created by Mike Griebling on 30 Jun 2015.
//  Copyright (c) 2015-2022 Computer Inspirations. All rights reserved.
//
// (Original) work was supported by the Director, Office of Science, Division
// of Mathematical, Information, and Computational Sciences of the
// U.S. Department of Energy under contract number DE-AC03-76SF00098.

/// Double-precision Double (aka Double-Double) floating point implementation.
///
public struct DDouble {
    
    // MARK: - Storage for the data type
    public var x : SIMD2<Double>
    
    private static let IEEE_ADD = false     // set to true for slower IEEE-compliant adds
    private static let SLOPPY_DIV = true    // set to false for an accurate division
    private static let QD_FMS = false       // set to true for Fused-Multiply-Subtract
    
    // MARK: - Initializers
    public init()                          		{ x = SIMD2.zero }
    public init(_ d: Double)                	{ x = SIMD2(d, 0.0) }
    public init(_ h: Int)                   	{ x = SIMD2(Double(h), 0.0) }
    public init(_ hi: Double, _ lo: Double) 	{ x = SIMD2(hi, lo) }
    public init(_ s: SIMD2<Double>)         	{ x = s }
    
    public init (_ s: String) {
        if let q : DDouble = Common.toFloat(s) {
            x = q.x
        } else {
            Common.error("\(#function): STRING CONVERT ERROR.")
            x = DDouble.nan.x
        }
    }
    
    // MARK: - Access functions
    public var hi: Double { x.x }
    public var lo: Double { x.y }
    
    // MARK: - Micellaneous
    public var isZero:Bool   		{ x[0].isZero }
	public var isOne:Bool     		{ x[0] == 1.0 && x[1].isZero }
    public var isPositive:Bool		{ x[0] > 0.0 }
    public var isNegative:Bool		{ x[0] < 0.0 }
    public var isNaN:Bool     		{ x[0].isNaN || x[1].isNaN }
    public var isFinite:Bool 	  	{ x[0].isFinite }
    public var isInfinite :Bool 	{ x[0].isInfinite }
    
    /** Absolute value */
    public var abs: DDouble { x[0] < 0.0 ? DDouble(-x) : DDouble(x) }
    
    /** Round to Nearest integer */
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
    
    // MARK: - Internal constants
    static private let _2pi = DDouble(6.283185307179586232e+00, 2.449293598294706414e-16);
    static private let _pi = DDouble(3.141592653589793116e+00, 1.224646799147353207e-16);
    static private let _pi2 = DDouble(1.570796326794896558e+00, 6.123233995736766036e-17);
    static private let _pi4 = DDouble(7.853981633974482790e-01, 3.061616997868383018e-17);
    static private let _3pi4 = DDouble(2.356194490192344837e+00, 9.1848509936051484375e-17);
    static private let _e = DDouble(2.718281828459045091e+00, 1.445646891729250158e-16);
    static public  let Log2 = DDouble(6.931471805599452862e-01, 2.319046813846299558e-17);
    static public  let Log10 = DDouble(2.302585092994045901e+00, -2.170756223382249351e-16);
    static private let _nan = DDouble(Double.nan, Double.nan)
    static private let _snan = DDouble(Double.signalingNaN, Double.signalingNaN)
    static private let _inf = DDouble(Double.infinity, Double.infinity)

    static private let _eps = 4.93038065763132e-32;  // 2^-104
    static private let _min_normalized = 2.0041683600089728e-292;  // = 2^(-1022 + 53)
    static private let _max = DDouble(1.79769313486231570815e+308, 9.97920154767359795037e+291);
    static private let _safe_max = DDouble(1.7976931080746007281e+308, 9.97920154767359795037e+291);
    static private let _ndigits = 31
    
    static public let eps = _eps
    static public let e = _e
    static public let max = _max
    
    /// Number of base 10 digits
    static public var digits:Int { _ndigits }
    
    // MARK: - Functions
    
    /** Computes fl(a*a) and err(a*a).  Faster than the above method. */
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
    
    /** Computes the nearest integer to d. */
    static func nint(_ d:Double) -> Double {
        if (d == Foundation.floor(d)) { return d }
        return Foundation.floor(d + 0.5)
    }

    /** Computes the truncated integer. */
    static func aint(_ d:Double) -> Double { (d >= 0.0) ? Foundation.floor(d) : Foundation.ceil(d) }

    /* These are provided to give consistent
       interface for double with double-double and quad-double. */
 //   static func sincosh(_ t:Double) -> (sinht: Double, cosht: Double) { (sinht: sinh(t), cosht: cosh(t)) }

    /// Squares *a*.
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
    
    /** double-double * (2.0 ^ exp) */
    public static func ldexp(_ a:DDouble, _ exp:Int) -> DDouble { DDouble(Foundation.scalbn(a.x[0], exp), Foundation.scalbn(a.x[1], exp)) }
    static func sqr(_ t:Double) -> Double { t * t }

    
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

    /** double + double-double */
    public static func + (_ a:Double, _ b:DDouble) -> DDouble { b + a }
    
    /** double-double += double */
    public static func += (_ x: inout DDouble, _ a:Double) {
        var s2 = 0.0
        let s1 = two_sum(x.x[0], a, &s2)
        s2 += x.x[1]
        x.x[0] = quick_two_sum(s1, s2, &x.x[1])
    }
    
    /** double-double += double-double */
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
    
    /** Unary Minus */
    public static prefix func - (_ x:DDouble) -> DDouble { DDouble(-x.x[0], -x.x[1]) }
    
    /** double-double - double-double */
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
    
    /** double-double -= double-double */
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

    /** double-double * double-double */
    public static func * (_ a:DDouble, _ b:DDouble) -> DDouble {
        var p2 = 0.0
        var p1 = two_prod(a.x[0], b.x[0], &p2);
        p2 += (a.x[0] * b.x[1] + a.x[1] * b.x[0]);
        p1 = quick_two_sum(p1, p2, &p2)
        return DDouble(p1, p2)
    }

    /** double * double-double */
    public static func * (_ a:Double, _ b:DDouble) -> DDouble { b * a }
    
    /// MARK: - Self-Multiplications
    /** double-double *= double */
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
    
    /** double-double * double,  where double is a power of 2. */
    public static func mul_pwr2(_ a:DDouble, _ b:Double) -> DDouble {
        DDouble(a.x[0] * b, a.x[1] * b)
    }
    
    /** double-double / double */
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
    
    static public func inv(_ a:DDouble) -> DDouble { 1.0 / a }
    
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
    
    /** Exponentiation */
    static public func pow (_ a: DDouble, _ b: DDouble) -> DDouble { exp(b * log(a)) }
    
    /// Power function a ** n
    public static func ** (a:DDouble, n:Int) -> DDouble { Common.pow(a, n) }
    
}

infix operator ** : ExponentPrecedence
precedencegroup ExponentPrecedence {
    associativity: left
    higherThan: MultiplicationPrecedence
}

extension DDouble : Comparable {
    /// MARK: - Equality Comparisons
    public static func == (_ a:DDouble,_ b:Double) -> Bool  { a.x[0] == b && a.x[1] == 0.0 }
    public static func == (_ a:DDouble,_ b:DDouble) -> Bool { a.x[0] == b.x[0] && a.x[1] == b.x[1] }
    public static func == (_ a:Double, _ b:DDouble) -> Bool { a == b.x[0] && b.x[1] == 0.0 }
    
    // MARK: - Less-Than Comparisons
    public static func < (_ a:DDouble,_ b:Double) -> Bool   { a.x[0] < b || (a.x[0] == b && a.x[1] < 0.0) }
    public static func < (_ a:DDouble,_ b:DDouble) -> Bool  { a.x[0] < b.x[0] || (a.x[0] == b.x[0] && a.x[1] < b.x[1]) }
    public static func < (_ a:Double, _ b:DDouble) -> Bool  { a < b.x[0] || (a == b.x[0] && b.x[1] > 0.0) }
    
    // MARK: - Greater-Than Comparisons
    public static func > (_ a: DDouble,_ b:Double) -> Bool  { a.x[0] > b || (a.x[0] == b && a.x[1] > 0.0) }
    public static func > (_ a: DDouble,_ b:DDouble) -> Bool { a.x[0] > b.x[0] || (a.x[0] == b.x[0] && a.x[1] > b.x[1]) }
    public static func > ( _ a:Double, _ b:DDouble) -> Bool { a > b.x[0] || (a == b.x[0] && b.x[1] < 0.0) }
    
    public static func >= (_ a:DDouble,_ b:Double) -> Bool  { a.x[0] > b || (a.x[0] == b && a.x[1] >= 0.0) }
    public static func >= (_ a:DDouble,_ b:DDouble) -> Bool { a.x[0] > b.x[0] || (a.x[0] == b.x[0] && a.x[1] >= b.x[1]) }
    
    public static func <= (_ a:DDouble,_ b:Double) -> Bool  { a.x[0] < b || (a.x[0] == b && a.x[1] <= 0.0) }
    public static func <= (_ a:DDouble,_ b:DDouble) -> Bool { a.x[0] < b.x[0] || (a.x[0] == b.x[0] && a.x[1] <= b.x[1]) }
}

public struct Format: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) { self.rawValue = rawValue }

    static let dec = Format(rawValue: 1 << 0)
    static let oct = Format(rawValue: 1 << 1)
    static let hex = Format(rawValue: 1 << 2)
    
    static let left = Format(rawValue: 1 << 3)
    static let right = Format(rawValue: 1 << 4)
    static let intern = Format(rawValue: 1 << 5)
    
    static let scientific = Format(rawValue: 1 << 6)
    static let fixed = Format(rawValue: 1 << 7)
    
    static let baseField: Format = [.dec, .oct, .hex]
    static let adjustField: Format = [.left, .right, .intern]
    static let floatField: Format = [.scientific, .fixed]
}

extension DDouble : CustomStringConvertible {
    public func string(_ precision: Int, width: Int=0, fmt:Format=[], showpos: Bool = false, uppercase: Bool = false, fill: String = " ") -> String {
        Common.string(self, precision, width: width, fmt: fmt, showpos: showpos, uppercase: uppercase, fill: fill)
    }
    public var description: String { self.string(DDouble.digits) }
}

extension DDouble : CustomDebugStringConvertible {
    public var debugDescription: String {
        var str = "[\n"
        str += Common.doubleInfo(x.x) + ",\n"
        str += Common.doubleInfo(x.y) + "\n]"
        return str
    }
}

extension DDouble : Codable { }

extension DDouble : ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) { self.init(value) }
}

extension DDouble : ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) { self.init(value) }
}

extension DDouble : ExpressibleByStringLiteral {
    public init(stringLiteral value: String) { self.init(value) }
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
    
    /// Computes the square root of the double-double number *a*.
    ///   NOTE: *a* must be a non-negative number.
    ///
    /// Strategy:  Use Karp's trick:  if x is an approximation
    /// to sqrt(a), then
    ///
    /// sqrt(a) = a*x + [a - (a*x)^2] * x / 2   (approx)
    ///
    /// The approximation is accurate to twice the accuracy of x.
    /// Also, the multiplication (a*x) and [-]*x can be done with
    /// only half the precision.
    public static func sqrt(_ a:DDouble) -> DDouble {
        if a.isZero { return 0.0 }
        
        if a.isNegative {
            Common.error("\(#function): Negative argument.")
            return _nan
        }
        
        let x = 1.0 / a.x[0].squareRoot()
        let ax = a.x[0] * x
        return DDouble.add(ax, (a - DDouble.sqr(ax)).x[0] * (x * 0.5))
    }
    
    /// Computes the square root of a double in double-double precision.
    /// NOTE: d must not be negative.                                   */
    public static func sqrt(_ a:Double) -> DDouble { sqrt(DDouble(a)) }
    
    /// Computes the n-th root of the double-double number a.
    ///   NOTE: n must be a positive integer.
    ///   NOTE: If n is even, then a must not be negative.
    public static func nroot(_ a:DDouble, _ n:Int) -> DDouble {
        /* Strategy:  Use Newton iteration for the function
         
         f(x) = x^(-n) - a
         
         to find its root a^{-1/n}.  The iteration is thus
         
         x' = x + x * (1 - a * x^n) / n
         
         which converges quadratically.  We can then find
         a^{1/n} by taking the reciprocal.
         */
        guard n>=0 else {
            Common.error("\(#function): N must be positive.")
            return _nan
        }
        
        guard !(n.isMultiple(of: 2) && a.isNegative) else {
            Common.error("(\(#function): Negative argument.");
            return _nan
        }
        
        if n == 1 { return a }
        if n == 2 { return sqrt(a) }
        if a.isZero { return 0.0 }
        
        /* Note  a^{-1/n} = exp(-log(a)/n) */
        let r = a.abs
        var x = DDouble(Foundation.exp(-Foundation.log(r.x[0]) / Double(n)))
        
        /* Perform Newton's iteration. */
        x += x * (1.0 - r * x ** n) / Double(n)
        if a.x[0] < 0.0 { x = -x }
        return 1.0/x
    }
    
    /// Exponential.  Computes exp(x) in double-double precision.
    ///
    /// Strategy:  We first reduce the size of x by noting that
    
    /// exp(kr + m * log(2)) = 2^m * exp(r)^k
    ///
    /// where m and k are integers.  By choosing m appropriately
    /// we can make |kr| <= log(2) / 2 = 0.347.  Then exp(r) is
    /// evaluated using the familiar Taylor series.  Reducing the
    /// argument substantially speeds up the convergence.
    public static func exp(_ a: DDouble) -> DDouble {

        let k = 512.0
        let inv_k = 1.0 / k
        
        if a.x[0] <= -709.0 { return 0.0 }
        if a.x[0] >= 709.0 { return _inf }
        if a.isZero { return 1.0 }
        if a.isOne { return _e }
        
        let m = Foundation.floor(a.x[0] / Log2.x[0] + 0.5)
        let r = mul_pwr2(a - Log2 * m, inv_k)
        
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
    ///
    ///          /* Strategy.  The Taylor series for log converges much more
    /// slowly than that of exp, due to the lack of the factorial
    /// term in the denominator.  Hence this routine instead tries
    /// to determine the root of the function
    ///
    ///    f(x) = exp(x) - a
    ///
    /// using Newton iteration.  The iteration is given by
    ///
    /// x' = x - f(x)/f'(x)
    /// = x - (1 - a * exp(-x))
    /// = x + a * exp(-x) - 1.
    ///
    /// Only one iteration is needed, since Newton's iteration
    /// approximately doubles the number of digits per iteration.
    public static func log(_ a: DDouble) -> DDouble {
 
        
        if a.isOne { return 0.0 }
        
        if a.x[0] <= 0.0 {
            Common.error("\(#function): Non-positive argument.")
            return _nan
        }
        
        var x = DDouble(Foundation.log(a.x[0]))  /* Initial approximation */
        x = x + a * exp(-x) - 1.0
        return x
    }
    
    /// Computes sin(a) using Taylor series.
    /// Assumes |a| <= pi/32.
    static private func sin_taylor(_ a: DDouble) -> DDouble {
        let thresh = 0.5 * Foundation.fabs(a.double) * _eps
        
        if a.isZero { return 0.0 }
        
        var i = 0
        let x = -sqr(a)
        var s = a
        var r = a
        var t: DDouble
        repeat {
            r *= x
            t = r * DDouble(inv_fact[i][0], inv_fact[i][1])
            s += t
            i += 2
        } while (i < inv_fact.count && Foundation.fabs(t.double) > thresh)
        
        return s
    }

    static private func cos_taylor(_ a: DDouble) -> DDouble {
        let thresh = 0.5 * Foundation.fabs(a.double) * _eps
        
        if a.isZero { return 1.0 }
        
        let x = -sqr(a)
        var r = x
        var s = 1.0 + mul_pwr2(r, 0.5);
        var i = 1
        var t: DDouble
        repeat {
            r *= x
            t = r * DDouble(inv_fact[i][0], inv_fact[i][1])
            s += t
            i += 2
        } while (i < inv_fact.count && Foundation.fabs(t.double) > thresh)
        
        return s
    }

    static private func sincos_taylor(_ a: DDouble) -> (sina: DDouble, cosa: DDouble) {
        if a.isZero { return (0.0, 1.0) }
        let sina = sin_taylor(a)
        return (sina, sqrt(1.0 - sqr(sina)))
    }
    
    /// Strategy.  To compute sin(x), we choose integers a, b so that
    ///
    ///  x = s + a * (pi/2) + b * (pi/16)
    ///
    ///  and |s| <= pi/32.  Using the fact that
    ///
    ///  sin(pi/16) = 0.5 * sqrt(2 - sqrt(2 + sqrt(2)))
    ///
    ///  we can compute sin(x) from sin(s), cos(s).  This greatly
    ///  increases the convergence of the sine Taylor series.
    static public func sin(_ a: DDouble) -> DDouble {

        if a.isZero { return 0.0 }
        
        // approximately reduce modulo 2*pi
        let z : DDouble = nint(a / _2pi)
        var r = a - _2pi * z
        
        // approximately reduce modulo pi/2 and then modulo pi/16.
        var q = Foundation.floor(r.x[0] / _pi2.x[0] + 0.5)
        var t = r - _pi2 * q
        let j = Int(q)
        q = Foundation.floor(t.x[0] / _pi16.x[0] + 0.5)
        t -= _pi16 * q
        let k = Int(q)
        let abs_k = Swift.abs(k)
        
        if (j < -2 || j > 2) {
            Common.error("\(#function): Cannot reduce modulo pi/2.")
            return _nan
        }
        
        if (abs_k > 4) {
            Common.error("\(#function): Cannot reduce modulo pi/16.")
            return _nan
        }
        
        if k == 0 {
            switch j {
                case 0:  return sin_taylor(t)
                case 1:  return cos_taylor(t)
                case -1: return -cos_taylor(t)
                default: return -sin_taylor(t)
            }
        }
        
        let u = DDouble(cos_table[abs_k-1][0], cos_table[abs_k-1][1])
        let v = DDouble(sin_table[abs_k-1][0], sin_table[abs_k-1][1])
        let (sin_t, cos_t) = sincos_taylor(t)
        if j == 0 {
            if k > 0 {
                r = u * sin_t + v * cos_t
            } else {
                r = u * sin_t - v * cos_t
            }
        } else if j == 1 {
            if k > 0 {
                r = u * cos_t - v * sin_t
            } else {
                r = u * cos_t + v * sin_t
            }
        } else if j == -1 {
            if k > 0 {
                r = v * sin_t - u * cos_t
            } else if k < 0 {
                r = -u * cos_t - v * sin_t
            }
        } else {
            if k > 0 {
                r = -u * sin_t - v * cos_t
            } else {
                r = v * cos_t - u * sin_t
            }
        }
        return r
    }

    static public func cos(_ a: DDouble) -> DDouble {
        if a.isZero { return 1.0 }
        
        // approximately reduce modulo 2*pi
        let z : DDouble = nint(a / _2pi)
        var r = a - z * _2pi
        
        // approximately reduce modulo pi/2 and then modulo pi/16
        var q = Foundation.floor(r.x[0] / _pi2.x[0] + 0.5);
        var t = r - _pi2 * q;
        let j = Int(q);
        q = Foundation.floor(t.x[0] / _pi16.x[0] + 0.5);
        t -= _pi16 * q;
        let k = Int(q)
        let abs_k = Swift.abs(k)
        
        if (j < -2 || j > 2) {
            Common.error("\(#function): Cannot reduce modulo pi/2.")
            return _nan
        }
        
        if (abs_k > 4) {
            Common.error("\(#function): Cannot reduce modulo pi/16.")
            return _nan
        }
        
        if k == 0 {
            switch j {
                case 0:  return cos_taylor(t)
                case 1:  return -sin_taylor(t)
                case -1: return sin_taylor(t)
                default: return -cos_taylor(t)
            }
        }
        
        let (sin_t, cos_t) = sincos_taylor(t)
        let u = DDouble(cos_table[abs_k-1][0], cos_table[abs_k-1][1])
        let v = DDouble(sin_table[abs_k-1][0], sin_table[abs_k-1][1])
        
        if (j == 0) {
            if (k > 0) {
                r = u * cos_t - v * sin_t;
            } else {
                r = u * cos_t + v * sin_t;
            }
        } else if (j == 1) {
            if (k > 0) {
                r = -u * sin_t - v * cos_t;
            } else {
                r = v * cos_t - u * sin_t;
            }
        } else if (j == -1) {
            if (k > 0) {
                r = u * sin_t + v * cos_t;
            } else {
                r = u * sin_t - v * cos_t;
            }
        } else {
            if (k > 0) {
                r = v * sin_t - u * cos_t;
            } else {
                r = -u * cos_t - v * sin_t;
            }
        }
        return r
    }

    static public func sincos(_ a: DDouble) -> (sina: DDouble, cosa: DDouble) {
        if a.isZero { return (0.0, 1.0) }
        
        // approximately reduce modulo 2*pi
        let z = nint(a / _2pi);
        let r = a - _2pi * z;
        
        // approximately reduce module pi/2 and pi/16
        var q = Foundation.floor(r.x[0] / _pi2.x[0] + 0.5)
        var t = r - _pi2 * q
        let j = Int(q)
        let abs_j = Swift.abs(j)
        q = Foundation.floor(t.x[0] / _pi16.x[0] + 0.5)
        t -= _pi16 * q
        let k = Int(q)
        let abs_k = Swift.abs(k)
        
        if abs_j > 2 {
            Common.error("\(#function): Cannot reduce modulo pi/2.")
            return (_nan, _nan)
        }
        
        if abs_k > 4 {
            Common.error("\(#function): Cannot reduce modulo pi/16.")
            return (_nan, _nan)
        }
        
        let (sin_t, cos_t) = sincos_taylor(t)
        let s,c: DDouble
        if abs_k == 0 {
            s = sin_t
            c = cos_t
        } else {
            let u = DDouble(cos_table[abs_k-1][0], cos_table[abs_k-1][1])
            let v = DDouble(sin_table[abs_k-1][0], sin_table[abs_k-1][1])
            
            if (k > 0) {
                s = u * sin_t + v * cos_t;
                c = u * cos_t - v * sin_t;
            } else {
                s = u * sin_t - v * cos_t;
                c = u * cos_t + v * sin_t;
            }
        }
        
        if abs_j == 0   { return (s, c) }
        else if j == 1  { return (c, -s) }
        else if j == -1 { return (-c, s) }
        else            { return (-s, -c) }
    }

    static public func atan(_ a: DDouble) -> DDouble { atan2(a, DDouble(1.0)) }

    /** Strategy: Instead of using Taylor series to compute
     arctan, we instead use Newton's iteration to solve
     the equation
     
     sin(z) = y/r    or    cos(z) = x/r
     
     where r = sqrt(x^2 + y^2).
     The iteration is given by
     
     z' = z + (y - sin(z)) / cos(z)          (for equation 1)
     z' = z - (x - cos(z)) / sin(z)          (for equation 2)
     
     Here, x and y are normalized so that x^2 + y^2 = 1.
     If |x| > |y|, then first iteration is used since the
     denominator is larger.  Otherwise, the second is used.
     */
    static public func atan2(_ y: DDouble, _ x: DDouble) -> DDouble {
        if x.isZero {
            if y.isZero {
                /* Both x and y are zero. */
                Common.error("\(#function): Both arguments zero.");
                return _nan
            }
            return y.isPositive ? _pi2 : -_pi2
        } else if y.isZero {
            return x.isPositive ? 0.0 : _pi
        }
        
        if x == y {
            return y.isPositive ? _pi4 : -_3pi4
        }
        
        if x == -y {
            return y.isPositive ? _3pi4 : -_pi4
        }
        
        let r = sqrt(sqr(x) + sqr(y))
        let xx = x / r;
        let yy = y / r;
        
        /* Compute double precision approximation to atan. */
        var z = DDouble(Foundation.atan2(y.double, x.double))
        let (sin_z, cos_z) = sincos(z)
        if Swift.abs(xx.x[0]) > Swift.abs(yy.x[0]) {
            /* Use Newton iteration 1.  z' = z + (y - sin(z)) / cos(z)  */
            z += (yy - sin_z) / cos_z
        } else {
            /* Use Newton iteration 2.  z' = z - (x - cos(z)) / sin(z)  */
            z -= (xx - cos_z) / sin_z
        }
        return z
    }
    
    static public func tan(_ a: DDouble) -> DDouble {
      let (s, c) = sincos(a)
      return s/c
    }

    static public func asin(_ a: DDouble) -> DDouble {
        let abs_a = abs(a);
        
        if abs_a > 1.0 {
            Common.error("\(#function): Argument out of domain.");
            return _nan;
        }
        
        if abs_a.isOne {
            return a.isPositive ? _pi2 : -_pi2
        }
        
        return atan2(a, sqrt(1.0 - sqr(a)))
    }

    static public func acos(_ a: DDouble) -> DDouble {
        let abs_a = abs(a);
        
        if abs_a > 1.0 {
            Common.error("\(#function): Argument out of domain.");
            return _nan;
        }
        
        if abs_a.isOne {
            return a.isPositive ? 0.0 : _pi
        }
        return atan2(sqrt(1.0 - sqr(a)), a)
    }
    
    static public func sinh(_ a: DDouble) -> DDouble {
        if a.isZero { return 0.0 }
        
        if abs(a) > 0.05 {
            let ea = exp(a);
            return mul_pwr2(ea - inv(ea), 0.5);
        }
        
        /* since a is small, using the above formula gives
         a lot of cancellation.  So use Taylor series.   */
        var s = a;
        var t = a;
        let r = sqr(t)
        var m = 1.0
        let thresh = Swift.abs(a.double) * _eps
        
        repeat {
            m += 2.0;
            t *= r;
            t /= (m-1) * m;
            s += t
        } while (abs(t) > thresh)

        return s
    }

    static public func cosh(_ a: DDouble) -> DDouble {
        if a.isZero { return 1.0 }
        
        let ea = exp(a)
        return mul_pwr2(ea + inv(ea), 0.5)
    }

    static public func tanh(_ a: DDouble) -> DDouble {
        if a.isZero { return 0.0 }
        
        if Swift.abs(a.double) > 0.05 {
            let ea = exp(a);
            let inv_ea = inv(ea)
            return (ea - inv_ea) / (ea + inv_ea)
        } else {
            let s = sinh(a)
            let c = sqrt(1.0 + sqr(s))
            return s / c
        }
    }

    static public func sinhcosh(_ a: DDouble) -> (sina: DDouble, cosa: DDouble) {
        let s,c:DDouble
        if Swift.abs(a.double) <= 0.05 {
            s = sinh(a);
            c = sqrt(1.0 + sqr(s));
        } else {
            let ea = exp(a)
            let inv_ea = inv(ea)
            s = mul_pwr2(ea - inv_ea, 0.5)
            c = mul_pwr2(ea + inv_ea, 0.5)
        }
        return (s,c)
    }

    static public func asinh(_ a: DDouble) -> DDouble { log(a + sqrt(sqr(a) + 1.0)) }

    static public func acosh(_ a: DDouble) -> DDouble {
        if a < 1.0 {
            Common.error("\(#function): Argument out of domain.")
            return _nan
        }
        return log(a + sqrt(sqr(a) - 1.0))
    }

    static public func atanh(_ a: DDouble) -> DDouble {
        if abs(a) >= 1.0 {
            Common.error("\(#function): Argument out of domain.")
            return _nan
        }
        return mul_pwr2(log((1.0 + a) / (1.0 - a)), 0.5)
    }

    static public func fmod(_ a: DDouble, _ b: DDouble) -> DDouble {
        let n = aint(a / b)
        return a - b * n
    }
    
    static public func ddrand() -> DDouble {
        let m_const = 4.6566128730773926e-10  /* = 2^{-31} */
        var m = m_const
        var r = DDouble(0.0)
        
        /* Strategy:  Generate 31 bits at a time, using lrand48
         random number generator.  Shift the bits, and reapeat
         4 times. */
        
        for _ in 0..<4 {
            //    d = lrand48() * m;
            let d = Double(Foundation.arc4random()) * m
            r += d
            m *= m_const
        }
        return r
    }

    /// polyeval(c, n, x)
    ///   Evaluates the given n-th degree polynomial at x.
    ///   The polynomial is given by the array of (n+1) coefficients.
    static public func polyeval(_ c:[DDouble], _ n:Int, _ x:DDouble) -> DDouble {
      /* Just use Horner's method of polynomial evaluation. */
      var r = c[n]
      
      for i in stride(from: n-1, through: 0, by: -1) {
        r *= x
        r += c[i]
      }
      return r
    }

    /** polyroot(c, n, x0)
       Given an n-th degree polynomial, finds a root close to
       the given guess x0.  Note that this uses simple Newton
       iteration scheme, and does not work for multiple roots.  */
    static public func polyroot(_ c:[DDouble], _ n:Int, _ x0:DDouble, _ max_iter:Int=32, _ thresh:Double=0.0) -> DDouble {
        var x = x0
        var d = [DDouble](repeating: 0, count: n)
        var conv = false;
        var max_c = Swift.abs(c[0].double)
        var thresh = thresh
        
        if thresh == 0.0 { thresh = _eps }
        
        /* Compute the coefficients of the derivatives. */
        for i in 1...n {
            let v = Swift.abs(c[i].double)
            if v > max_c { max_c = v }
            d[i-1] = c[i] * Double(i)
        }
        thresh *= max_c;
        
        /* Newton iteration. */
        for _ in 0..<max_iter {
            let f = polyeval(c, n, x)
            if abs(f) < thresh {
                conv = true
                break
            }
            x -= (f / polyeval(d, n-1, x))
        }
        if !conv {
            Common.error("\(#function): Failed to converge.")
            return _nan
        }
        return x
    }

    public static func log10(_ a: DDouble) -> DDouble { log(a) / Log10 }
    public static func abs(_ a: DDouble) -> DDouble { a.abs }
    
    static private let _pi16 = DDouble(1.963495408493620697e-01, 7.654042494670957545e-18)

    /* Table of sin(k * pi/16) and cos(k * pi/16). */
    static private let sin_table : [[Double]] = [
      [1.950903220161282758e-01, -7.991079068461731263e-18],
      [3.826834323650897818e-01, -1.005077269646158761e-17],
      [5.555702330196021776e-01,  4.709410940561676821e-17],
      [7.071067811865475727e-01, -4.833646656726456726e-17]
    ]

    static private let cos_table : [[Double]] = [
      [9.807852804032304306e-01, 1.854693999782500573e-17],
      [9.238795325112867385e-01, 1.764504708433667706e-17],
      [8.314696123025452357e-01, 1.407385698472802389e-18],
      [7.071067811865475727e-01, -4.833646656726456726e-17]
    ]
    
    static private let inv_fact : [[Double]] = [
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

