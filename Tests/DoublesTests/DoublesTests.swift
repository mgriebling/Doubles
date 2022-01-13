import XCTest
@testable import Doubles

//
//  Test.swift
//  QuadReal
//
//  Created by Mike Griebling on 10 Jul 2015.
//  Copyright © 2015 Computer Inspirations. All rights reserved.
//

protocol MyFloatingPoint : FloatingPoint, ExpressibleByFloatLiteral {
    init(_ d:Double)
    init?(_ s:String)
    func string(_ precision: Int, width: Int, fmt:Format, showpos: Bool, uppercase: Bool, fill: String) -> String
    static func += (lhs: inout Self, rhs:Self)
    static func / (lhs: Self, rhs: Double) -> Self
    static func /= (lhs: inout Self, rhs: Double)
    static func exp(_ a:Self) -> Self
    static func sqrt(_ a:Self) -> Self
    static func nroot(_ a:Self, _ n:Int) -> Self
    static func sin(_ a:Self) -> Self
    static func cos(_ a:Self) -> Self
    static func log(_ a:Self) -> Self
    static func abs(_ a:Self) -> Self
    static func sqr(_ a:Self) -> Self
    static func < (lhs:Self, rhs: Double) -> Bool
    static func > (lhs:Self, rhs: Double) -> Bool
    static func **(_ a:Self, _b:Int) -> Self
    static func polyroot(_ c:[Self], _ n:Int, _ x0:Self, _ max_iter:Int, _ thresh:Double) -> Self
    static func polyeval(_ c: [Self], _ n: Int, _ x:Self) -> Self
    static var eps:Double { get }
    static var Log2:Self { get }
    static var pi:Self { get }
    static var e:Self { get }
    static var digits:Int { get }
    static var max:Self { get }
    
    var double:Double { get }
}

extension MyFloatingPoint {
    func string(_ digits:Int, width:Int = 0, fmt: Format = []) -> String { self.string(digits, width: width, fmt: fmt, showpos: false, uppercase: false, fill: " ") }
    static func string2(_ a: Self) -> String { a > 0 ? " " : "" }  // just to fool the optimizer
    static func / (lhs: Double, rhs: Self) -> Self { Self(lhs) / rhs }
    static func + (lhs: Double, rhs: Self) -> Self { Self(lhs) + rhs }
    static func - (lhs: Double, rhs: Self) -> Self { Self(lhs) - rhs }
    static func * (lhs: Double, rhs: Self) -> Self { Self(lhs) * rhs }
}

extension MyFloatingPoint {
    
    typealias TicToc = timeval
    
    static var flag_verbose:Bool { true }   // for detailed messages
    
    static func tic () -> TicToc {
        var time: TicToc = timeval()
        gettimeofday(&time, nil)
        return time
    }
    
    static func toc (_ tv: TicToc) -> Double {
        var tv2: TicToc = timeval()
        gettimeofday(&tv2, nil)
        let sec = Double(tv2.tv_sec - tv.tv_sec)
        let usec = Double(tv2.tv_usec - tv.tv_usec)
        return sec + 1.0e-6 * usec
    }
    
    static func print_timing(_ nops: Double, t: Double) {
        let mops = 1.0e-6 * nops / t
        print(String(format: "\t%10.6f us \t\t%10.4f mop/s", 1.0/mops, mops))
    }
    
    static func print_timing<T:MyFloatingPoint>(_ nops: Double, t: Double, dummy: T) {
        let mops = 1.0e-6 * nops / t
        print(String(format: "%10.6f μs %10.4f mop/s", 1.0/mops, mops), terminator: "")
        let x = T.string2(dummy)
        print(x)
    }
    
    static func addition<T:MyFloatingPoint>(_ dummy:T = 0) {
        let n = 100_000
        
        let a1 = 1.0 / T(7.0)
        let a2 = 1.0 / T(11.0)
        let a3 = 1.0 / T(13.0)
        let a4 = 1.0 / T(17.0)
        var b1 = T(0); var b2 = T(0); var b3 = T(0); var b4 = T(0)
        
        let tv = tic()
        for _ in 0..<n {
            b1 += a1
            b2 += a2
            b3 += a3
            b4 += a4
        }
        let t = toc(tv)
        print("   add: ", terminator: ""); print_timing(4.0*Double(n), t: t, dummy: b4)  // prevent optimizer from removing timing code
    }
    
    static func multiplication<T:MyFloatingPoint>(_ dummy:T = 0) {
        let n = 100_000
        
        let a1 = 1.0 + 1.0 / T(n)
        let a2 = 1.0 + 2.0 / T(n)
        let a3 = 1.0 + 3.0 / T(n)
        let a4 = 1.0 + 4.0 / T(n)
        var b1 = T(1.0); var b2 = T(1.0); var b3 = T(1.0); var b4 = T(1.0)
        
        let tv = tic()
        for _ in 0..<n {
            b1 *= a1
            b2 *= a2
            b3 *= a3
            b4 *= a4
        }
        let t = toc(tv)
        print("   mul: ", terminator: ""); print_timing(4.0*Double(n), t: t, dummy: b4)
    }
    
    static func division<T:MyFloatingPoint>(_ dummy:T = 0) {
        let n = 100_000
        
        let a1 = 1.0 + 1.0 / T(n)
        let a2 = 1.0 + 2.0 / T(n)
        let a3 = 1.0 + 3.0 / T(n)
        let a4 = 1.0 + 4.0 / T(n)
        var b1 = T(1.0); var b2 = T(1.0); var b3 = T(1.0); var b4 = T(1.0)
        
        let tv = tic()
        for _ in 0..<n {
            b1 /= a1
            b2 /= a2
            b3 /= a3
            b4 /= a4
        }
        let t = toc(tv)
        print("   div: ", terminator: ""); print_timing(4.0*Double(n), t: t, dummy: b4)
    }
    
    static func root<T:MyFloatingPoint>(_ dummy:T = 0) {
        let n = 10_000
        
        let a1 = 1.0 + T.pi
        let a2 = 2.0 + T.pi
        let a3 = 3.0 + T.pi
        let a4 = 4.0 + T.pi
        var b1 = T(0.0); var b2 = T(0.0); var b3 = T(0.0); var b4 = T(0.0)
        
        let tv = tic()
        for _ in 0..<n {
            b1 = T.sqrt(a1 + b1)
            b2 = T.sqrt(a2 + b2)
            b3 = T.sqrt(a3 + b3)
            b4 = T.sqrt(a4 + b4)
        }
        let t = toc(tv)
        print("  sqrt: ", terminator: ""); print_timing(4.0*Double(n), t: t, dummy: b4)
    }
    
    static func sine<T:MyFloatingPoint>(_ dummy:T = 0) {
        let n = 4_000
        
        var a = T(0)
        let b = 3.0 * T.pi / Double(n)
        var c = T(0)
        
        let tv = tic()
        for _ in 0..<n {
            a += b
            c += T.sin(a)
        }
        let t = toc(tv)
        print("   sin: ", terminator: ""); print_timing(Double(n), t: t, dummy: c)
    }
    
    static func cosine<T:MyFloatingPoint>(_ dummy:T = 0) {
        let n = 4_000
        
        var a = T(0)
        let b = 3.0 * T.pi / Double(n)
        var c = T(0)
        
        let tv = tic()
        for _ in 0..<n {
            a += b
            c += T.cos(a)
        }
        let t = toc(tv)
        print("   cos: ", terminator: ""); print_timing(Double(n), t: t, dummy: c)
    }
    
    static func flog<T:MyFloatingPoint>(_ dummy:T = 0) {
        let n = 1_000
        
        var a = T(0)
        let d = T.exp(T(100.2 / Double(n)))
        var c = T.exp(T(-50.1))
        
        let tv = tic()
        for _ in 0..<n {
            a += T.log(c)
            c *= d
        }
        let t = toc(tv)
        print("   log: ", terminator: ""); print_timing(Double(n), t: t, dummy: c)
    }
    
    static func dot<T:MyFloatingPoint>(_ dummy:T = 0) {
        let n = 100_000
        
        let a1 = 1.0 / T(7.0);
        let a2 = 1.0 / T(11.0);
        let a3 = 1.0 / T(13.0);
        let a4 = 1.0 / T(17.0);
        let b1 = 1.0 - T(1.0) / Double(n)
        let b2 = 1.0 - T(2.0) / Double(n)
        let b3 = 1.0 - T(3.0) / Double(n)
        let b4 = 1.0 - T(4.0) / Double(n)
        var x1 = T(0.0); var x2 = T(0.0); var x3 = T(0.0); var x4 = T(0.0)
        
        let tv = tic()
        for _ in 0..<n {
            x1 = a1 + b1 * x1
            x2 = a2 + b2 * x2
            x3 = a3 + b3 * x3
            x4 = a4 + b4 * x4
        }
        let t = toc(tv)
        print("   dot: ", terminator: ""); print_timing(8.0*Double(n), t: t, dummy: x4)
    }
    
    static func fexp<T:MyFloatingPoint>(_ dummy:T = 0) {
        let n = 1_000
        
        var a = T(0)
        let d = T(10.0 / Double(n))
        var c = T(-5)
        
        let tv = tic()
        for _ in 0..<n {
            a += T.exp(c)
            c += d
        }
        let t = toc(tv)
        print("   exp: ", terminator: ""); print_timing(Double(n), t: t, dummy: c)
    }
    
    static func testPerformance<T:MyFloatingPoint>(_ name: String, _ dummy:T = 0) {
        let title = "Timing \(name)"
        print(title); print("".padding(toLength: title.count, withPad: "-", startingAt: 0))
        addition(dummy)
        multiplication(dummy)
        division(dummy)
        root(dummy)
        sine(dummy)
        flog(dummy)
        dot(dummy)
        fexp(dummy)
        cosine(dummy)
        print()
    }
    
    static func test1<T:MyFloatingPoint>(_ dummy:T, max_iter:Int) {
        print()
        print("Test 1.  (Polynomial).")
        
        let n = 8
        var c = [T](repeating: 0, count: n)
        var x, y : T
        
        for i in 0..<n {
            c[i] = T(Double(i+1))
        }
        
        x = T.polyroot(c, n-1, T(0.0), max_iter, 0.0)
        y = T.polyeval(c, n-1, x)
        
        if flag_verbose {
            print("Root Found:  x  = \(x)")
            print("           p(x) = \(y)")
        }
        XCTAssert(y.double < 4.0 * T.eps, "Failed test 1")
    }
    
    /* Test 2.  Machin's Formula for Pi. */
    static func test2<T:MyFloatingPoint>(_ dummy:T) {
        print()
        print("Test 2.  (Machin's Formula for Pi).")
        
        /* Use the Machin's arctangent formula:
         
         pi / 4  =  4 arctan(1/5) - arctan(1/239)
         
         The arctangent is computed based on the Taylor series expansion
         
         arctan(x) = x - x^3 / 3 + x^5 / 5 - x^7 / 7 + ...
         */
        var s1, s2, t, r:T
        
        /* Compute arctan(1/5) */
        var d = 1.0;
        t = T(1.0) / 5.0;
        r = T.sqr(t)
        s1 = 0.0
        var k = 0
        
        var sign = 1;
        while (t > T.eps) {
            k+=1
            if (sign < 0) {
                s1 -= (t / d);
            } else {
                s1 += (t / d);
            }
            
            d += 2.0
            t *= r
            sign = -sign
        }
        
        if flag_verbose {
            print("\(k) Iterations")
        }
        
        /* Compute arctan(1/239) */
        d = 1.0
        t = T(1.0) / 239.0
        r = T.sqr(t)
        s2 = 0.0
        k = 0
        
        sign = 1
        while t > T.eps {
            k+=1
            if (sign < 0) {
                s2 -= (t / d)
            } else {
                s2 += (t / d)
            }
            
            d += 2.0
            t *= r
            sign = -sign
        }
        
        if flag_verbose {
            print("\(k) Iterations")
        }
        
        var p = 4.0 * s1 - s2
        
        p *= 4.0;
        let err = Swift.abs((p - T.pi).double)
        
        if flag_verbose {
            print("   pi = \(p)")
            print("  _pi = \(T.pi)")

            print("error = \(err) = \(err / T.eps) eps")
        }
        
        XCTAssert(err < 8.0 * T.eps, "Failed test 2")
    }
    
    /* Test 3.  Salamin-Brent Quadratic Formula for Pi. */
    static func test3<T:MyFloatingPoint>(_ dummy:T) {
        print()
        print("Test 3.  (Salamin-Brent Quadratic Formula for Pi).")
        
        var a, b, s, p:T
        var a_new, b_new, p_old:T
        let max_iter = 20
        
        a = 1.0
        b = T.sqrt(T(0.5))
        s = 0.5
        var m = 1.0
        
        p = 2.0 * T.sqr(a) / s;
        if flag_verbose {
            print("Iteration  0: \(p)")
        }
        for i in 1...max_iter {
            m *= 2.0
            a_new = 0.5 * (a + b)
            b_new = a * b
            s -= m * (T.sqr(a_new) - b_new)
            a = a_new
            b = T.sqrt(b_new)
            p_old = p
            p = 2.0 * T.sqr(a) / s
            if (flag_verbose) {
                print("Iteration \(i) : \(p)")
            }
            if (Swift.abs((p - p_old).double) < 64 * T.eps) {
                break
            }
        }
        
        let err = Swift.abs((p - T.pi).double)
        
        if (flag_verbose) {
            print("         _pi: \(T.pi)")
            print("       error: \(err) = \(err / T.eps) eps")
        }
        
        // for some reason, this test gives relatively large error compared
        // to other tests.  May need to be looked at more closely.
        XCTAssert(err < 1024.0 * T.eps, "Failed test 3")
    }
    
    static func test4<T:MyFloatingPoint>(_ dummy:T) {
        print()
        print("Test 4.  (Borwein Quartic Formula for Pi).")
        
        var a, y, p, r, p_old: T
        var m: Double
        let max_iter = 20
        
        a = 6.0 - 4.0 * T.sqrt(T(2))
        y = T.sqrt(T(2)) - 1.0
        m = 2.0
        
        p = 1.0 / a
        print("Iteration 0 : \(p)")
        
        for i in 1...max_iter {
            m *= 4.0
            r = T.nroot(1.0 - T.sqr(T.sqr(y)), 4)
            y = (1.0 - r) / (1.0 + r);
            a = a * T.sqr(T.sqr(1.0 + y)) - m * y * (1.0 + y + T.sqr(y))
            
            p_old = p
            p = 1.0 / a
            print("Iteration \(i) : \(p)")
            if Swift.abs((p - p_old).double) < 16 * T.eps { break }
        }
        
        let err = Swift.abs((p - T.pi).double)
        
        if (flag_verbose) {
            print("         _pi: \(T.pi)")
            print("       error: \(err) = \(err / T.eps) eps")
        }
        
        XCTAssert(err < 256.0 * T.eps, "Failed test 4")
    }
    
    static func test5 <T:MyFloatingPoint>(_ dummy:T) {
        print()
        print("Test 5.  (Taylor Series Formula for E).")
        
        /* Use Taylor series
         
         e = 1 + 1 + 1/2! + 1/3! + 1/4! + ...
         
         To compute e.
         */
        
        var s = T(2.0), t = T(1.0)
        var n = 1.0
        var delta: Double
        var i = 0
        
        while t > T.eps {
            i += 1
            n += 1.0
            t /= n
            s += t
        }
        
        delta = Swift.abs((s - T.e).double)
        
        print("    e = \(s)")
        print("   _e = \(T.e)")
        print("error = \(delta) = \(delta / T.eps) eps \(i) iterations.")
        
        XCTAssert(delta < 64.0 * T.eps, "Failed test 5")
    }
    
    static func test6<T:MyFloatingPoint>(_ dummy:T)  {
        print()
        print("Test 6.  (Taylor Series Formula for Log 2).")
        
        /* Use the Taylor series
         
         -log(1-x) = x + x^2/2 + x^3/3 + x^4/4 + ...
         
         with x = 1/2 to get  log(1/2) = -log 2.
         */
        
        var s = T(0.5), t = T(0.5)
        var n = 1.0
        var i = 0
        
        while T.abs(t) > T.eps {
            i += 1
            n += 1.0
            t *= 0.5
            s += t/n
        }
        
        let delta = Swift.abs((s - T.Log2).double)
        
        print("    log2 = \(s)")
        print("   _log2 = \(T.Log2)")
        print("error = \(delta) = \(delta / T.eps) eps \(i) iterations.")
        
        XCTAssert(delta < 4.0 * T.eps, "Failed test 6")
    }
    
    static func test7<T:MyFloatingPoint>(_ dummy:T) {
        print()
        print("Test 7.  (Sanity check for exp).")
        
        /* Do simple sanity check
         *
         *   e^2 = exp(2)
         *       = exp(-13/4) * exp(-9/4) * exp(-5/4) * exp(-1/4) *
         *         exp(3/4) * exp(7/4) * exp(11/4) * exp(15/4)
         */
        
        var t = T(-3.25)
        var p = T(1.0)
        
        for _ in 0..<8 {
            /* For some reason gcc-4.1.x on x86_64 miscompiles p *= exp(t) here. */
            p = p * T.exp(t)
            t += 1.0
        }
        
        let t1 = T.exp(T(2))
        let t2 = T.sqr(T.e)
        let delta = Swift.max(Swift.abs((t1 - p).double), Swift.abs((t2 - p).double))
        
        print("result = \(p)")
        print("exp(2) = \(t1)")
        print("   e^2 = \(t2)")
        print(" error = \(delta) = \(delta / T.eps) eps")
        
        XCTAssert(delta < 16.0 * T.eps, "Failed test 7")
    }
    
    static func test8<T:MyFloatingPoint>(_ dummy:T) {
        print()
        print("Test 8.  (Sanity check for sin / cos).")
        
        /* Do simple sanity check
         *
         *  sin(x) = sin(5x/7)cos(2x/7) + cos(5x/7)sin(2x/7)
         *
         *  cos(x) = cos(5x/7)cos(2x/7) - sin(5x/7)sin(2x/7);
         */
        
        let x = T.pi / 3.0
        let x1 = 5.0 * x / 7.0
        let x2 = 2.0 * x / 7.0
        
        let r1 = T.sin(x1)*T.cos(x2) + T.cos(x1)*T.sin(x2)
        let r2 = T.cos(x1)*T.cos(x2) - T.sin(x1)*T.sin(x2)
        let t1 = T.sqrt(T(3)) / 2.0
        let t2 = T(0.5)
        
        let delta = Swift.max(Swift.abs((t1 - r1).double), Swift.abs((t2 - r2).double))
        
        print("  r1 = \(r1)")
        print("  t1 = \(t1)")
        print("  r2 = \(r2)")
        print("  t2 = \(t2)")
        print(" error = \(delta) = \(delta / T.eps) eps")
        
        XCTAssert(delta < 4.0 * T.eps, "Failed test 8")
    }
    
    static func testHuge<T:MyFloatingPoint>(_ dummy:T, true_str: String) {
        
        func check(_ str: String, _ true_str: String) -> Bool {
            let pass = (str == true_str);
            if !pass {
                print("     fail: \(str)")
                print("should be: \(true_str)")
            }
            return !pass
        }
        
        print()
        print("Test 9 output of huge numbers...")
        
        let digits = T.digits-1
        var fail = false
        var x = T.pi * T("1.0e290")!
        
        var pi_str = T.pi.string(digits, width: 0, fmt: [.fixed])
        for i in 0..<18 {
            let pi_str2 = pi_str + "e+\(290 + i)"
            fail = check(x.string(digits), pi_str2) || fail
            x *= 10.0
        }
        
        x = -T.pi * T("1.0e290")!
        pi_str = "-" + pi_str
        for i in 0..<18 {
            let pi_str2 = pi_str + "e+\(290 + i)"
            fail = check(x.string(digits), pi_str2) || fail
            x *= 10.0
        }
        XCTAssert(!fail, "Failed Huge Number test 9 - Seems to fail on Mac (please fix me)") // Ignore this error
        
        print()
        print("Test 10 output of huge numbers...")
        fail = check(T.max.string(digits), true_str)
        fail = check((-T.max).string(digits), "-" + true_str) || fail
        XCTAssert(!fail, "Failed Huge Number test 10")
    }
     
    
    static func testAll<T:MyFloatingPoint>(_ dummy:T, max_iter: Int) {
        test1(dummy, max_iter: max_iter)
        test2(dummy)
        test3(dummy)
        test4(dummy)
        test5(dummy)
        test6(dummy)
        test7(dummy)
        test8(dummy)
    }
}

extension Double : MyFloatingPoint {
    func string(_ precision: Int, width: Int, fmt: Format, showpos: Bool, uppercase: Bool, fill: String) -> String { "\(self)" } // not used
    
    static var digits: Int { 16 }
    static var max: Double { Double.greatestFiniteMagnitude }
    
    static var Log2: Double { Double.log(2.0) }
    static var e: Double { Foundation.exp(1.0) }
    static func nroot(_ a: Double, _ n: Int) -> Double { Foundation.pow(a, 1.0/Double(n)) }
    static func sqr(_ a: Double) -> Double { a*a }
    static func polyroot(_ c: [Double], _ n: Int, _ x0: Double, _ max_iter: Int, _ thresh: Double) -> Double { x0 } // Not used
    static func polyeval(_ c: [Double], _ n: Int, _ x: Double) -> Double  { x }  // Not used
    
    var double: Double { self }
    static func abs(_ a: Double) -> Double { Foundation.fabs(a) }
    static func ** (_ a: Double, _ b: Int) -> Double { Foundation.pow(a, Double(b)) }
    static var eps: Double { Double.ulpOfOne }
    
    static func exp(_ a: Double) -> Double { Foundation.exp(a) }
    static func sqrt(_ a: Double) -> Double { Foundation.sqrt(a) }
    static func sin(_ a: Double) -> Double { Foundation.sin(a) }
    static func cos(_ a: Double) -> Double { Foundation.cos(a) }
    static func log(_ a: Double) -> Double { Foundation.log(a) }
}

extension DDouble : MyFloatingPoint { }
extension QDouble : MyFloatingPoint { }


class Test: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testHuge() {
        print("Testing DDouble...")
        DDouble.testHuge(DDouble(0), true_str: "1.797693134862315807937289714053e+308")
        print()
        
        print("Testing QDouble...")
        QDouble.testHuge(QDouble(0), true_str: "1.7976931348623158079372897140530286112296785259868571699620069e+308")
        print()
    }
    
    func testDoubles() {
        print("Testing DDouble...")
        DDouble.testAll(DDouble(0), max_iter: 32)
        print()
        
        print("Testing QDouble...")
        QDouble.testAll(QDouble(0), max_iter: 64)
        print()
    }
    
    func testPerformance() {
        Double.testPerformance("Double", Double(0))
        DDouble.testPerformance("DDouble", DDouble(0))
        QDouble.testPerformance("QDouble", QDouble(0))
    }
    
}

