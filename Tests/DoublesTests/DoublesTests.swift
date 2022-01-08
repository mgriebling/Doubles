    import XCTest
    @testable import Doubles

    //
    //  Test.swift
    //  QuadReal
    //
    //  Created by Mike Griebling on 10 Jul 2015.
    //  Copyright © 2015 Computer Inspirations. All rights reserved.
    //
    class Test: XCTestCase {
        
        override func setUp() {
            super.setUp()
            // Put setup code here. This method is called before the invocation of each test method in the class.
//            print("QDouble.pi = ", QDouble.pi.debugDescription)
//            print("DDouble.pi = ", DDouble.pi.debugDescription)
        }
        
        override func tearDown() {
            // Put teardown code here. This method is called after the invocation of each test method in the class.
            super.tearDown()
        }
        
        func testPi() {
            // This is an example of a functional test case.
            var a, b, s, p, t, t2: QDouble
            var a_new, b_new, p_old: QDouble
            var m: Double
            let max_iter = 20;
            
            print("Test 1.  (Salamin-Brent quadratically convergent formula for pi)")
            
            a = 1.0                /* a = 1.0 */
            t = 0.5                /* t = 0.5 */
            b = QDouble.sqrt(t)    /* b = sqrt(t) */
            s = 0.5                /* s = 0.5 */
            m = 1.0
            t2 = 0
            
            p = (2 * a**2) / s
            
            print("  iteration 0: \(p)")
            for i in 1...max_iter {
                m *= 2.0
                
                a_new = 0.5 * (a + b)
                b_new = a * b
                
                /* Compute s = s - m * (a_new^2 - b) */
                s -= m * (a_new**2 - b_new)
                
                a = a_new
                b = QDouble.sqrt(b_new)
                p_old = p
                
                /* Compute  p = 2.0 * a^2 / s */
                p = (2.0 * a**2) / s
                
                /* Test for convergence by looking at |p - p_old|. */
                t = p - p_old
                t2 = QDouble.abs(t)
                if t2 < 64.0 * QDouble.eps { break }
                
                print("  iteration \(i): \(p)")
            }
            
            p = QDouble.pi   /* p = pi */
            print("          _pi: \(p)")
            print("        error: \(t2) = \((t2 / QDouble.eps).double)) eps")
            XCTAssert(t2 < 64.0 * QDouble.eps, "Pass")
        }
        
        func testBorweinPi () {
            print("Test 4.  (Borwein Quartic Formula for Pi).")
            
            var a, y, p, r, p_old: QDouble
            var m: Double
            let max_iter = 20
            
            a = 6.0 - 4.0 * QDouble.sqrt(QDouble(2))
            y = QDouble.sqrt(QDouble(2)) - 1.0
            m = 2.0
            
            p = 1.0 / a
            print("Iteration 0 : \(p)")
            
            for i in 1...max_iter {
                m *= 4.0
                r = QDouble.nroot(1.0 - QDouble.sqr(QDouble.sqr(y)), n: 4)
                y = (1.0 - r) / (1.0 + r);
                a = a * QDouble.sqr(QDouble.sqr(1.0 + y)) - m * y * (1.0 + y + QDouble.sqr(y))
                
                p_old = p
                p = 1.0 / a
                print("Iteration \(i) : \(p)")
                if (abs((p - p_old).double) < 16 * QDouble.eps) { break }
            }
            
            let err = abs((p - QDouble.pi).double)
            XCTAssert(err < 64.0 * QDouble.eps, "Pass")
        }
        
        func testHuge() {
            
            func check(_ str: String, _ true_str: String) -> Bool {
                let pass = (str == true_str);
                if !pass {
                    print("     fail: \(str)")
                    print("should be: \(true_str)")
                }
                return pass
            }
            
            var pass = true
            let digits = QDouble.digits - 1
            var x = QDouble.pi * "1.0e290"
            
            var pi_str = QDouble.pi.string(digits, width: 0, fmt: [.fixed])
            for i in 0..<18 {
                let pi_str2 = pi_str + "e+\(290 + i)"
                pass = pass && check(x.string(digits), pi_str2)
                x *= 10.0
            }
            
            x = -QDouble.pi * "1.0e290"
            pi_str = "-" + pi_str
            for i in 0..<18 {
                let pi_str2 = pi_str + "e+\(290 + i)"
                pass = pass && check(x.string(digits), pi_str2)
                x *= 10.0
            }
            
            let true_str = "1.7976931348623158079372897140530286112296785259868571699620069e+308"   // fails on Mac
            pass = pass && check(QDouble.max.string(digits), true_str)
            pass = pass && check((-QDouble.max).string(digits), "-" + true_str)
            
            XCTAssert(pass, "Pass")
        }
        
        func testPolynomical() {
            let n = 8
            var c = [QDouble](repeating: 0, count: n)
            var x, y: QDouble
            
            for i in 0..<n { c[i] = QDouble(i+1) }
            x = QDouble.polyroot(c, n: n-1, x: 0)
            y = QDouble.polyeval(c, n: n-1, x: x)
            
            print("Root Found:  x  = \(x)")
            print("           p(x) = \(y)")
            
            XCTAssert(y.double < 4.0 * QDouble.eps, "Pass")
        }
        
        func testTaylorPi() {
            /* Use the Machin's arctangent formula:
            
            pi / 4  =  4 arctan(1/5) - arctan(1/239)
            
            The arctangent is computed based on the Taylor series expansion
            
            arctan(x) = x - x^3 / 3 + x^5 / 5 - x^7 / 7 + ...   */
            var s1, s2, t, r: QDouble
            var k: Int
            var sign: Int
            var d, err: Double
            
            /* Compute arctan(1/5) */
            d = 1.0;
            t = QDouble(1.0) / 5.0
            r = QDouble.sqr(t)
            s1 = 0.0
            k = 0
            
            sign = 1;
            while t > QDouble(QDouble.eps) {
                k += 1;
                if (sign < 0) {
                    s1 -= (t / d);
                } else {
                    s1 += (t / d);
                }
                
                d += 2.0;
                t *= r;
                sign = -sign;
            }
            
            /* Compute arctan(1/239) */
            d = 1.0;
            t = QDouble(1.0) / 239.0;
            r = QDouble.sqr(t)
            s2 = 0.0
            k = 0
            
            sign = 1;
            while t > QDouble(QDouble.eps) {
                k += 1;
                if (sign < 0) {
                    s2 -= (t / d)
                } else {
                    s2 += (t / d)
                }
                
                d += 2.0
                t *= r
                sign = -sign
            }
            
            var p = 4.0 * s1 - s2;
            
            p *= 4.0;
            err = abs((p - QDouble.pi).double)
            XCTAssert(err < 8.0 * QDouble.eps, "Pass")
        }
        
        func testTaylorE () {
            print("Test 5.  (Taylor Series Formula for E).")
            
            /* Use Taylor series
            
            e = 1 + 1 + 1/2! + 1/3! + 1/4! + ...
            
            To compute e.
            */
            
            var s = QDouble(2.0); var t = QDouble(1.0)
            var n = 1.0
            var delta: Double
            var i = 0
            
            while t > QDouble(QDouble.eps) {
                i += 1
                n += 1.0
                t /= n
                s += t
            }
            
            delta = abs((s - QDouble.e).double)
            
            print("    e = \(s)")
            print("   _e = \(QDouble.e)")
            print("error = \(delta) = \(delta / QDouble.eps) eps \(i) iterations.")
            
            XCTAssert(delta < 64.0 * QDouble.eps, "Pass")
        }
        
        func testTaylorLog2() {
            print("Test 5.  (Taylor Series Formula for Log 2).")
            
            /* Use the Taylor series
            
            -log(1-x) = x + x^2/2 + x^3/3 + x^4/4 + ...
            
            with x = 1/2 to get  log(1/2) = -log 2.
            */
            
            var s = QDouble(0.5); var t = QDouble(0.5)
            var n = 1.0
            var delta: Double
            var i = 0
            
            while t.abs > QDouble(QDouble.eps) {
                i += 1
                n += 1.0
                t *= 0.5
                s += t/n
            }
            
            delta = abs((s - QDouble.log2).double)
            
            print("    log2 = \(s)")
            print("   _log2 = \(QDouble.log2)")
            print("error = \(delta) = \(delta / QDouble.eps) eps \(i) iterations.")
            
            XCTAssert(delta < 4.0 * QDouble.eps, "Pass")
        }
        
        func testExp() {
            print("Test 7.  (Sanity check for exp).")
            
            /* Do simple sanity check
            *
            *   e^2 = exp(2)
            *       = exp(-13/4) * exp(-9/4) * exp(-5/4) * exp(-1/4) *
            *         exp(3/4) * exp(7/4) * exp(11/4) * exp(15/4)
            */
            
            var t = QDouble(-3.25)
            var p = QDouble(1.0)
            
            for _ in 0..<8 {
                /* For some reason gcc-4.1.x on x86_64 miscompiles p *= exp(t) here. */
                p = p * QDouble.exp(t)
                t += 1.0
            }
            
            let t1 = QDouble.exp(QDouble(2))
            let t2 = QDouble.sqr(QDouble.e)
            let delta = max(abs((t1 - p).double), abs((t2 - p).double))
            
            print("result = \(p)")
            print("exp(2) = \(t1)")
            print("   e^2 = \(t2)")
            print(" error = \(delta) = \(delta / QDouble.eps) eps")
            
            XCTAssert(delta < 16.0 * QDouble.eps, "Pass")
        }
        
        func testSinCos() {
            print("Test 8.  (Sanity check for sin / cos).")
            
            /* Do simple sanity check
            *
            *  sin(x) = sin(5x/7)cos(2x/7) + cos(5x/7)sin(2x/7)
            *
            *  cos(x) = cos(5x/7)cos(2x/7) - sin(5x/7)sin(2x/7);
            */
            
            let x = QDouble.pi / 3.0
            let x1 = 5.0 * x / 7.0
            let x2 = 2.0 * x / 7.0
            
            let r1 = QDouble.sin(x1)*QDouble.cos(x2) + QDouble.cos(x1)*QDouble.sin(x2)
            let r2 = QDouble.cos(x1)*QDouble.cos(x2) - QDouble.sin(x1)*QDouble.sin(x2)
            let t1 = QDouble.sqrt(QDouble(3)) / 2.0
            let t2 = QDouble(0.5)
            
            let delta = max(abs((t1 - r1).double), abs((t2 - r2).double));
            
            print("  r1 = \(r1)")
            print("  t1 = \(t1)")
            print("  r2 = \(r2)")
            print("  t2 = \(t2)")
            print(" error = \(delta) = \(delta / QDouble.eps) eps")
            
            XCTAssert(delta < 4.0 * QDouble.eps, "Pass")
        }
        
        typealias TicToc = timeval
        
        func tic () -> TicToc {
            var time: TicToc = timeval()
            gettimeofday(&time, nil)
            return time
        }
        
        func toc (_ tv: TicToc) -> Double {
            var tv2: TicToc = timeval()
            gettimeofday(&tv2, nil)
            let sec = Double(tv2.tv_sec - tv.tv_sec)
            let usec = Double(tv2.tv_usec - tv.tv_usec)
            return sec + 1.0e-6 * usec
        }
        
        func print_timing(_ nops: Double, t: Double) {
            let mops = 1.0e-6 * nops / t
            print(String(format: "\t%10.6f us \t\t%10.4f mop/s", 1.0/mops, mops))
        }
        
        func addition() {
            let n = 100_000
            
            let a1 = 1.0 / QDouble(7.0)
            let a2 = 1.0 / QDouble(11.0)
            let a3 = 1.0 / QDouble(13.0)
            let a4 = 1.0 / QDouble(17.0)
            var b1 = QDouble(0.0); var b2 = QDouble(0.0); var b3 = QDouble(0.0); var b4 = QDouble(0.0)
            
            let tv = tic()
            for _ in 0..<n {
                b1 += a1
                b2 += a2
                b3 += a3
                b4 += a4
            }
            let t = toc(tv)
            print("   add: ", terminator: ""); print_timing(4.0*Double(n), t: t)
        }
        
        func multiplication() {
            let n = 100_000
            
            let a1 = 1.0 + 1.0 / QDouble(n)
            let a2 = 1.0 + 2.0 / QDouble(n)
            let a3 = 1.0 + 3.0 / QDouble(n)
            let a4 = 1.0 + 4.0 / QDouble(n)
            var b1 = QDouble(1.0); var b2 = QDouble(1.0); var b3 = QDouble(1.0); var b4 = QDouble(1.0)
            
            let tv = tic()
            for _ in 0..<n {
                b1 *= a1
                b2 *= a2
                b3 *= a3
                b4 *= a4
            }
            let t = toc(tv)
            print("   mul: ", terminator: ""); print_timing(4.0*Double(n), t: t)
        }
        
        func division() {
            let n = 100_000
            
            let a1 = 1.0 + 1.0 / QDouble(n)
            let a2 = 1.0 + 2.0 / QDouble(n)
            let a3 = 1.0 + 3.0 / QDouble(n)
            let a4 = 1.0 + 4.0 / QDouble(n)
            var b1 = QDouble(1.0); var b2 = QDouble(1.0); var b3 = QDouble(1.0); var b4 = QDouble(1.0)
            
            let tv = tic()
            for _ in 0..<n {
                b1 *= a1
                b2 *= a2
                b3 *= a3
                b4 *= a4
            }
            let t = toc(tv)
            print("   div: ", terminator: ""); print_timing(4.0*Double(n), t: t)
        }
        
        func root() {
            let n = 10_000
            
            let a1 = 1.0 + QDouble.pi
            let a2 = 2.0 + QDouble.pi
            let a3 = 3.0 + QDouble.pi
            let a4 = 4.0 + QDouble.pi
            var b1 = QDouble(0.0); var b2 = QDouble(0.0); var b3 = QDouble(0.0); var b4 = QDouble(0.0)
            
            let tv = tic()
            for _ in 0..<n {
                b1 = QDouble.sqrt(a1 + b1)
                b2 = QDouble.sqrt(a2 + b2)
                b3 = QDouble.sqrt(a3 + b3)
                b4 = QDouble.sqrt(a4 + b4)
            }
            let t = toc(tv)
            print("  sqrt: ", terminator: ""); print_timing(4.0*Double(n), t: t)
        }
        
        func sine() {
            let n = 4_000
            
            var a = QDouble(0)
            let b = 3.0 * QDouble.pi / Double(n)
            var c = QDouble(0)
            
            let tv = tic()
            for _ in 0..<n {
                a += b
                c += QDouble.sin(a)
            }
            let t = toc(tv)
            print("   sin: ", terminator: ""); print_timing(Double(n), t: t)
        }
        
        func cosine() {
            let n = 4_000
            
            var a = QDouble(0)
            let b = 3.0 * QDouble.pi / Double(n)
            var c = QDouble(0)
            
            let tv = tic()
            for _ in 0..<n {
                a += b
                c += QDouble.cos(a)
            }
            let t = toc(tv)
            print("   cos: ", terminator: ""); print_timing(Double(n), t: t)
        }
        
        func log() {
            let n = 1_000
            
            var a = QDouble(0)
            let d = QDouble.exp(100.2 / Double(n))
            var c = QDouble.exp(-50.1)
            
            let tv = tic()
            for _ in 0..<n {
                a += QDouble.log(c)
                c *= d
            }
            let t = toc(tv)
            print("   log: ", terminator: ""); print_timing(Double(n), t: t)
        }
        
        func dot() {
            let n = 100_000
            
            let a1 = 1.0 / QDouble(7.0);
            let a2 = 1.0 / QDouble(11.0);
            let a3 = 1.0 / QDouble(13.0);
            let a4 = 1.0 / QDouble(17.0);
            let b1 = 1.0 - QDouble(1.0) / Double(n)
            let b2 = 1.0 - QDouble(2.0) / Double(n)
            let b3 = 1.0 - QDouble(3.0) / Double(n)
            let b4 = 1.0 - QDouble(4.0) / Double(n)
            var x1 = QDouble(0.0); var x2 = QDouble(0.0); var x3 = QDouble(0.0); var x4 = QDouble(0.0)
            
            let tv = tic()
            for _ in 0..<n {
                x1 = a1 + b1 * x1
                x2 = a2 + b2 * x2
                x3 = a3 + b3 * x3
                x4 = a4 + b4 * x4
            }
            let t = toc(tv)
            print("   dot: ", terminator: ""); print_timing(8.0*Double(n), t: t)
        }
        
        func exp() {
            let n = 1_000
            
            var a = QDouble(0)
            let d = QDouble(10.0 / Double(n))
            var c = QDouble(-5)
            
            let tv = tic()
            for _ in 0..<n {
                a += QDouble.exp(c)
                c += d
            }
            let t = toc(tv)
            print("   exp: ", terminator: ""); print_timing(Double(n), t: t)
        }
        
        func testPerformance() {
            addition()
            multiplication()
            division()
            root()
            sine()
            log()
            dot()
            exp()
            cosine()
        }
        
    }

