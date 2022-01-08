//
//  Hold some common functions that share an algorithm
//  
//
//  Created by Mike Griebling on 2022-01-07.
//

import Foundation

protocol FP:FloatingPoint {
    static func log10(_ a:Self) -> Self
    static func ldexp(_ a:Self, _ e:Int) -> Self
    static func abs(_ a:Self) -> Self
    init(_ d:Double)
    var int:Int { get }
    var double:Double { get }
}

extension DDouble:FP {}
extension QDouble:FP {}

struct Common {
    
    static func error(_ msg: String) { print("ERROR " + msg) }
    
    static func doubleInfo(_ x:Double) -> String {
        var str = String(format: "%27.19e ", x)
        if x.isNaN || x.isInfinite || x.isZero {
            str += "".padding(toLength: 58, withPad: " ", startingAt: 0)
        } else {
            let expn = x.exponent
            let mask = UInt64(1) << 53 - 1
            let bits = x.bitPattern & mask
            let bin = String(bits, radix: 2)
            let padding = "".padding(toLength: 53-bin.count, withPad: "0", startingAt: 0)
            str += String(format: "%5d ", expn) + padding + String(bits, radix: 2)
        }
        return str
    }
    
    static public func pow<T:FloatingPoint> (_ a: T, _ n: Int) -> T {
        if n == 0 { return 1 }
        
        var r: T = a        /* odd-case multiplier */
        var s: T = 1        /* current answer */
        var N = Swift.abs(n)
        
        /* Use binary exponentiation. */
        while N > 0 {
            /* If odd, multiply by r */
            if !N.isMultiple(of: 2) { s *= r }
            N /= 2
            if N > 0 { r = r*r }
        }
        return n < 0 ? T(1) / s : s
    }
    
    /** Initialize a quad-Double from string *s*. */
    static public func toFloat<T:FloatingPoint>(_ s: String) -> T? {
        var p = s.trimmingCharacters(in: CharacterSet.whitespaces)
        
        func getChar() -> Character {
            if p.isEmpty { return "\0" }
            return p.remove(at: s.startIndex)
        }
        
        var ch: Character = getChar()
        var sign = 0
        var point = -1        /* location of decimal point */
        var nd = 0            /* number of digits read */
        var e = 0            /* exponent. */
        var done = false
        var r = T(0)    /* number being read */
        
        while !done && ch != "\0" {
            if ch >= "0" && ch <= "9" {
                /* It's a digit */
                if let d = Int(String(ch)) {
                    r *= T(10)
                    r = r + T(d)
                    nd += 1
                }
            } else {
                /* Non-digit */
                switch ch {
                case ".":
                    if point >= 0 { return nil }   /* we"ve already encountered a decimal point. */
                    point = nd
                case "-", "+":
                    if sign != 0 || nd > 0 { return nil }  /* we"ve already encountered a sign, or if its
                    not at first position. */
                    sign = ch == "-" ? -1 : 1
                case "E", "e":
                    if let n = Int(p) {
                        e = n
                        done = true
                    } else {
                        return nil  /* read of exponent failed. */
                    }
                case " ":
                    done = true
                default:
                    return nil
                }
            }
            ch = getChar()
        }
        
        /* Adjust exponent to account for decimal point */
        if point >= 0 { e -= (nd - point) }
        
        /* Multiply by the exponent */
        let p2 = pow(T(10), e)
        if e != 0 { r *= p2 }
        
        return (sign < 0) ? -r : r
    }
    
    private static func to_digits<T:FP>(_ r:T, _ s: inout String, expn: inout Int, precision: Int) {
        let D = precision + 1  /* number of digits to compute */
        
        var r = T.abs(r)
        var e: Int  /* exponent */
        var d: Int
        let ten = T(10)
        let one = T(1)
        
        s = ""
        if r.isZero {
            /* self == 0.0 */
            expn = 0
            for _ in 0..<precision { s += "0" }
            return
        }
        
        /* First determine the (approximate) exponent. */
        e = Int(Foundation.floor(log10(Swift.abs(r.double))))
        
        if e < -300 {
            r *= Common.pow(ten, 300) // T(10.0) ** 300
            r /= Common.pow(ten, e + 300)
        } else if e > 300 {
            r = T.ldexp(r, -53)
            r /= Common.pow(ten, e)
            r = T.ldexp(r, 53)
        } else {
            r /= Common.pow(ten, e)
        }
        
        /* Fix exponent if we are off by one */
        if r >= ten {
            r /= ten
            e += 1
        } else if r < one {
            r *= ten
            e -= 1
        }
        
        if r >= ten || r < one { Common.error("(Quad.to_digits): can't compute exponent."); return }
        
        /* Extract the digits */
        for _ in 0..<D {
            d = Int(r.double)
            r -= T(d)
            r *= ten
            s += "\(d)"
        }
        
        /* Fix out of range digits. */
        for i in (0..<D).reversed() {
            if s[i] < "0" {
                s[i-1] -= 1
                s[i] += 10
            } else if s[i] > "9" {
                s[i-1] += 1
                s[i] -= 10
            }
        }
        
        if s[0] < "0" { Common.error("(Quad.to_digits): non-positive leading digit."); return }
        
        /* Round, handle carry */
        if s[D-1] >= "5" {
            s[D-2] += 1
            
            var i = D-2
            while i > 0 && s[i] > "9" {
                s[i] -= 10
                i -= 1; s[i] += 1
            }
        }
        
        /* If first digit is 10, shift everything. */
        if s[0] > "9" {
            e += 1
            s = "1" + s
            s[1] = "0"
        }

        expn = e
    }
    
    private static func append_expn(_ str: inout String, expn: Int) {
        var expn = expn
        var k: Int
        
        str += expn < 0 ? "-" : "+"
        expn = Swift.abs(expn)
        
        if expn >= 100 {
            k = expn / 100
            str += "\(k)"
            expn -= 100*k
        }
        
        k = expn / 10
        str += "\(k)"
        expn -= 10*k
        
        str += "\(expn)"
    }

    private static func round_string(_ s: inout String, precision: Int, offset: inout Int) {
        /*
            Input string must be all digits or errors will occur.
        */
        let D = precision
        
        /* Round, handle carry */
        if D>0 && s[D] >= "5" {
            s[D-1] += 1
            
            var i = D-1
            while i > 0 && s[i] > "9" {
                s[i] -= 10
                i -= 1; s[i] += 1
            }
        }
        
        /* If first digit is 10, shift everything. */
        if s.first! > "9" {
            // e++ // don't modify exponent here
            s = "1" + s
            s[1] = "0"
            offset += 1    // now offset needs to be increased by one
        }
    }

    public static func string<T:FP>(_ a: T, _ precision: Int, width: Int=0, fmt:Format=[], showpos: Bool = false, uppercase: Bool = false, fill: String = " ") -> String {
        var s: String = ""
        let fixed : Bool = fmt.contains(.fixed)
        var sgn = true
        var e = 0
        
        if a.isInfinite {
            if a.sign == .minus { s += "-" }
            else if showpos { s += "+" }
            else { sgn = false }
            s += uppercase ? "INF" : "inf"
        } else if a.isNaN {
            s = uppercase ? "NAN" : "nan"
            sgn = false
        } else {
            if a.sign == .minus { s += "-" }
            else if showpos { s += "+" }
            else { sgn = false }
            
            if a.isZero {
                /* Zero case */
                s += "0"
                if precision > 0 {
                    s += "."
                    s = s.padding(toLength: precision, withPad: "0", startingAt: s.count)
                }
            } else {
                /* Non-zero case */
                var off = fixed ? (1 + floor(T.log10(a.magnitude)).int) : 1
                let d = precision + off
                
                var d_with_extra = d
                if fixed { d_with_extra = Swift.max(120, d) } // longer than the max accuracy for DD
                
                // highly special case - fixed mode, precision is zero, abs(*this) < 1.0
                // without this trap a number like 0.9 printed fixed with 0 precision prints as 0
                // should be rounded to 1.
                if fixed && precision == 0 && a.magnitude < T(1) {
                    if a.magnitude >= T(0.5) {
                        s += "1"
                    } else {
                        s += "0"
                    }
                    
                    return s
                }
                
                // handle near zero to working precision (but not exactly zero)
                if fixed && d <= 0 {
                    s += "0"
                    if precision > 0 {
                        s += "."
                        s = s.padding(toLength: precision, withPad: "0", startingAt: 0)
                    }
                } else {  // default
                    var t : String  = ""
                    
                    if fixed { to_digits(a, &t, expn: &e, precision: d_with_extra) }
                    else     { to_digits(a, &t, expn: &e, precision: d) }
                    
                    off = e + 1
                    
                    if fixed {
                        // fix the string if it's been computed incorrectly
                        // round here in the decimal string if required
                        Common.round_string(&t, precision: d, offset: &off)
                        
                        if off > 0 {
                            for i in 0..<off { s += String(t[i]) }
                            if precision > 0 {
                                s += "."
                                var i = off
                                for _ in 0..<precision { s += String(t[i]); i += 1 }
                            }
                        } else {
                            s += "0."
                            if off < 0 { s = s.padding(toLength: -off, withPad: "0", startingAt: s.count) }
                            for i in 0..<d { s += String(t[i]) }
                        }
                    } else {
                        s += String(t[0])
                        if precision > 0 { s += "." }
                        
                        for i in 1...precision {
                            s += String(t[i])
                        }
                    }
                }
            }
            
            // trap for improper offset with large values
            // without this trap, output of values of the for 10^j - 1 fail for j > 28
            // and are output with the point in the wrong place, leading to a dramatically off value
            if fixed && precision > 0 {
                // make sure that the value isn't dramatically larger
                var from_string = atof(s)
                
                // if this ratio is large, then we"ve got problems
                if fabs( from_string / a.double ) > 3.0 {
                    
                    // loop on the string, find the point, move it up one
                    // don't act on the first character
                    for i in 1...s.count {
                        if s[i] == "." {
                            s[i] = s[i-1]
                            s[i-1] = "."
                            break
                        }
                    }
                    
                    from_string = atof(s)
                    // if this ratio is large, then the string has not been fixed
                    if fabs( from_string / a.double ) > 3.0 {
                        Common.error("Re-rounding unsuccessful in large number fixed point trap.")
                    }
                }
            }
            
            if !fixed {
                /* Fill in exponent part */
                s += uppercase ? "E" : "e"
                Common.append_expn(&s, expn: e)
            }
        }
        
        /* Fill in the blanks */
        let len = s.count
        if len < width {
            if fmt.contains(.intern) {
                if sgn {
                    s = s.padding(toLength: width, withPad: fill, startingAt: 1)
                } else {
                    s = s.padding(toLength: width, withPad: fill, startingAt: 0)
                }
            } else if fmt.contains(.left) {
                s = s.padding(toLength: width, withPad: fill, startingAt: s.count)
            } else {
                s = s.padding(toLength: width, withPad: fill, startingAt: 0)
            }
        }
        
        return s
    }
    
    
}
