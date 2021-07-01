    import XCTest
    @testable import QuadReals

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
        }
        
        override func tearDown() {
            // Put teardown code here. This method is called after the invocation of each test method in the class.
            super.tearDown()
        }
        
        func println(_ s: String) { print(s) }
        
        func testPi() {
            // This is an example of a functional test case.
            var a, b, s, p, t, t2: Quad
            var a_new, b_new, p_old: Quad
            var m: Double
            let max_iter = 20;
            
            print("Test 1.  (Salamin-Brent quadratically convergent formula for pi)")
            
            a = 1.0                /* a = 1.0 */
            t = 0.5                /* t = 0.5 */
            b = Quad.sqrt(t)    /* b = sqrt(t) */
            s = 0.5                /* s = 0.5 */
            m = 1.0
            t2 = 0
            
            p = (2 * a**2) / s
            
            println("  iteration 0: \(p)")
            for i in 1...max_iter {
                m *= 2.0
                
                a_new = 0.5 * (a + b)
                b_new = a * b
                
                /* Compute s = s - m * (a_new^2 - b) */
                s -= m * (a_new**2 - b_new)
                
                a = a_new
                b = Quad.sqrt(b_new)
                p_old = p
                
                /* Compute  p = 2.0 * a^2 / s */
                p = (2.0 * a**2) / s
                
                
                /* Test for convergence by looking at |p - p_old|. */
                t = p - p_old
                t2 = Quad.abs(t)
                if t2 < 64.0 * Quad.eps { break }
                
                
                println("  iteration \(i): \(p)")
            }
            
            p = Quad.pi   /* p = pi */
            println("          _pi: \(p)")
            println("        error: \(t2) = \(Quad.double(t2 / Quad.eps))) eps")
            XCTAssert(t2 < 64.0 * Quad.eps, "Pass")
        }
        
        func testBorweinPi () {
            println("Test 4.  (Borwein Quartic Formula for Pi).")
            
            var a, y, p, r, p_old: Quad
            var m: Double
            let max_iter = 20
            
            a = 6.0 - 4.0 * Quad.sqrt(Quad(2))
            y = Quad.sqrt(Quad(2)) - 1.0
            m = 2.0
            
            p = 1.0 / a
            println("Iteration 0: \(p)")
            
            for i in 1...max_iter {
                m *= 4.0
                r = Quad.nroot(1.0 - Quad.sqr(Quad.sqr(y)), n: 4)
                y = (1.0 - r) / (1.0 + r);
                a = a * Quad.sqr(Quad.sqr(1.0 + y)) - m * y * (1.0 + y + Quad.sqr(y))
                
                p_old = p
                p = 1.0 / a
                println("Iteration \(i) : \(p)")
                if (abs(Quad.double(p - p_old)) < 16 * Quad.eps) { break }
            }
            
            let err = abs(Quad.double(p - Quad.pi))
            XCTAssert(err < 64.0 * Quad.eps, "Pass")
        }
        
        func testHuge() {
            
            func check(_ str: String, _ true_str: String) -> Bool {
                let pass = (str == true_str);
                if !pass {
                    println("     fail: \(str)")
                    println("should be: \(true_str)")
                }
                return pass
            }
            
            var pass = true
            let digits = Quad.ndigits - 1
            var x = Quad.pi * "1.0e290"
            
            var pi_str = Quad.pi.string(digits, width: 0, fmt: [.fixed])
            for i in 0..<18 {
                let pi_str2 = pi_str + "e+\(290 + i)"
                pass = pass && check(x.string(digits), pi_str2)
                x *= 10.0
            }
            
            x = -Quad.pi * "1.0e290"
            pi_str = "-" + pi_str
            for i in 0..<18 {
                let pi_str2 = pi_str + "e+\(290 + i)"
                pass = pass && check(x.string(digits), pi_str2)
                x *= 10.0
            }
            
            let true_str = "1.7976931348623158079372897140530286112296785259868571699620069e+308"   // fails on Mac
            pass = pass && check(Quad.max.string(digits), true_str)
            pass = pass && check((-Quad.max).string(digits), "-" + true_str)
            
            XCTAssert(pass, "Pass")
        }
        
        func testPolynomical() {
            let n = 8
            var c = [Quad](repeating: 0, count: n)
            var x, y: Quad
            
            for i in 0..<n { c[i] = Quad(i+1) }
            x = Quad.polyroot(c, n: n-1, x: 0)
            y = Quad.polyeval(c, n: n-1, x: x)
            
            println("Root Found:  x  = \(x)")
            println("           p(x) = \(y)")
            
            XCTAssert(Quad.double(y) < 4.0 * Quad.eps, "Pass")
        }
        
        func testTaylorPi() {
            /* Use the Machin's arctangent formula:
            
            pi / 4  =  4 arctan(1/5) - arctan(1/239)
            
            The arctangent is computed based on the Taylor series expansion
            
            arctan(x) = x - x^3 / 3 + x^5 / 5 - x^7 / 7 + ...   */
            var s1, s2, t, r: Quad
            var k: Int
            var sign: Int
            var d, err: Double
            
            /* Compute arctan(1/5) */
            d = 1.0;
            t = Quad(1.0) / 5.0
            r = Quad.sqr(t)
            s1 = 0.0
            k = 0
            
            sign = 1;
            while t > Quad(Quad.eps) {
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
            t = Quad(1.0) / 239.0;
            r = Quad.sqr(t)
            s2 = 0.0
            k = 0
            
            sign = 1;
            while t > Quad(Quad.eps) {
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
            err = abs(Quad.double(p - Quad.pi));
            XCTAssert(err < 8.0 * Quad.eps, "Pass")
        }
        
        func testTaylorE () {
            println("Test 5.  (Taylor Series Formula for E).")
            
            /* Use Taylor series
            
            e = 1 + 1 + 1/2! + 1/3! + 1/4! + ...
            
            To compute e.
            */
            
            var s = Quad(2.0); var t = Quad(1.0)
            var n = 1.0
            var delta: Double
            var i = 0
            
            while t > Quad(Quad.eps) {
                i += 1
                n += 1.0
                t /= n
                s += t
            }
            
            delta = abs(Quad.double(s - Quad.e))
            
            println("    e = \(s)")
            println("   _e = \(Quad.e)")
            println("error = \(delta) = \(delta / Quad.eps) eps \(i) iterations.")
            
            XCTAssert(delta < 64.0 * Quad.eps, "Pass")
        }
        
        func testTaylorLog2() {
            println("Test 5.  (Taylor Series Formula for Log 2).")
            
            /* Use the Taylor series
            
            -log(1-x) = x + x^2/2 + x^3/3 + x^4/4 + ...
            
            with x = 1/2 to get  log(1/2) = -log 2.
            */
            
            var s = Quad(0.5); var t = Quad(0.5)
            var n = 1.0
            var delta: Double
            var i = 0
            
            while Quad.abs(t)() > Quad(Quad.eps) {
                i += 1
                n += 1.0
                t *= 0.5
                s += t/n
            }
            
            delta = abs(Quad.double(s - Quad.log2))
            
            println("    log2 = \(s)")
            println("   _log2 = \(Quad.log2)")
            println("error = \(delta) = \(delta / Quad.eps) eps \(i) iterations.")
            
            XCTAssert(delta < 4.0 * Quad.eps, "Pass")
        }
        
        func testExp() {
            println("Test 7.  (Sanity check for exp).")
            
            /* Do simple sanity check
            *
            *   e^2 = exp(2)
            *       = exp(-13/4) * exp(-9/4) * exp(-5/4) * exp(-1/4) *
            *         exp(3/4) * exp(7/4) * exp(11/4) * exp(15/4)
            */
            
            var t = Quad(-3.25)
            var p = Quad(1.0)
            
            for _ in 0..<8 {
                /* For some reason gcc-4.1.x on x86_64 miscompiles p *= exp(t) here. */
                p = p * Quad.exp(t)
                t += 1.0
            }
            
            let t1 = Quad.exp(Quad(2))
            let t2 = Quad.sqr(Quad.e)
            let delta = max(abs(Quad.double(t1 - p)), abs(Quad.double(t2 - p)));
            
            println("result = \(p)")
            println("exp(2) = \(t1)")
            println("   e^2 = \(t2)")
            println(" error = \(delta) = \(delta / Quad.eps) eps")
            
            XCTAssert(delta < 16.0 * Quad.eps, "Pass")
        }
        
        func testSinCos() {
            println("Test 8.  (Sanity check for sin / cos).")
            
            /* Do simple sanity check
            *
            *  sin(x) = sin(5x/7)cos(2x/7) + cos(5x/7)sin(2x/7)
            *
            *  cos(x) = cos(5x/7)cos(2x/7) - sin(5x/7)sin(2x/7);
            */
            
            let x = Quad.pi / 3.0
            let x1 = 5.0 * x / 7.0
            let x2 = 2.0 * x / 7.0
            
            let r1 = Quad.sin(x1)*Quad.cos(x2) + Quad.cos(x1)*Quad.sin(x2)
            let r2 = Quad.cos(x1)*Quad.cos(x2) - Quad.sin(x1)*Quad.sin(x2)
            let t1 = Quad.sqrt(Quad(3)) / 2.0
            let t2 = Quad(0.5)
            
            let delta = max(abs(Quad.double(t1 - r1)), abs(Quad.double(t2 - r2)));
            
            println("  r1 = \(r1)")
            println("  t1 = \(t1)")
            println("  r2 = \(r2)")
            println("  t2 = \(t2)")
            println(" error = \(delta) = \(delta / Quad.eps) eps")
            
            XCTAssert(delta < 4.0 * Quad.eps, "Pass")
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
            println("\t\(1.0 / mops) us \t\t\(mops) mop/s")
        }
        
        func addition() {
            let n = 10000
            
            let a1 = 1.0 / Quad(7.0)
            let a2 = 1.0 / Quad(11.0)
            let a3 = 1.0 / Quad(13.0)
            let a4 = 1.0 / Quad(17.0)
            var b1 = Quad(0.0); var b2 = Quad(0.0); var b3 = Quad(0.0); var b4 = Quad(0.0)
            
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
            let n = 10000
            
            let a1 = 1.0 + 1.0 / Quad(n)
            let a2 = 1.0 + 2.0 / Quad(n)
            let a3 = 1.0 + 3.0 / Quad(n)
            let a4 = 1.0 + 4.0 / Quad(n)
            var b1 = Quad(1.0); var b2 = Quad(1.0); var b3 = Quad(1.0); var b4 = Quad(1.0)
            
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
            let n = 10000
            
            let a1 = 1.0 + 1.0 / Quad(n)
            let a2 = 1.0 + 2.0 / Quad(n)
            let a3 = 1.0 + 3.0 / Quad(n)
            let a4 = 1.0 + 4.0 / Quad(n)
            var b1 = Quad(1.0); var b2 = Quad(1.0); var b3 = Quad(1.0); var b4 = Quad(1.0)
            
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
            let n = 1000
            
            let a1 = 1.0 + Quad.pi
            let a2 = 2.0 + Quad.pi
            let a3 = 3.0 + Quad.pi
            let a4 = 4.0 + Quad.pi
            var b1 = Quad(0.0); var b2 = Quad(0.0); var b3 = Quad(0.0); var b4 = Quad(0.0)
            
            let tv = tic()
            for _ in 0..<n {
                b1 = Quad.sqrt(a1 + b1)
                b2 = Quad.sqrt(a2 + b2)
                b3 = Quad.sqrt(a3 + b3)
                b4 = Quad.sqrt(a4 + b4)
            }
            let t = toc(tv)
            print("  sqrt: ", terminator: ""); print_timing(4.0*Double(n), t: t)
        }
        
        func sine() {
            let n = 400
            
            var a = Quad(0)
            let b = 3.0 * Quad.pi / Double(n)
            var c = Quad(0)
            
            let tv = tic()
            for _ in 0..<n {
                a += b
                c += Quad.sin(a)
            }
            let t = toc(tv)
            print("   sin: ", terminator: ""); print_timing(Double(n), t: t)
        }
        
        func cosine() {
            let n = 400
            
            var a = Quad(0)
            let b = 3.0 * Quad.pi / Double(n)
            var c = Quad(0)
            
            let tv = tic()
            for _ in 0..<n {
                a += b
                c += Quad.cos(a)
            }
            let t = toc(tv)
            print("   cos: ", terminator: ""); print_timing(Double(n), t: t)
        }
        
        func log() {
            let n = 100
            
            var a = Quad(0)
            let d = Quad.exp(100.2 / Double(n))
            var c = Quad.exp(-50.1)
            
            let tv = tic()
            for _ in 0..<n {
                a += Quad.log(c)
                c *= d
            }
            let t = toc(tv)
            print("   log: ", terminator: ""); print_timing(Double(n), t: t)
        }
        
        func dot() {
            let n = 10000
            
            let a1 = 1.0 / Quad(7.0);
            let a2 = 1.0 / Quad(11.0);
            let a3 = 1.0 / Quad(13.0);
            let a4 = 1.0 / Quad(17.0);
            let b1 = 1.0 - Quad(1.0) / Double(n)
            let b2 = 1.0 - Quad(2.0) / Double(n)
            let b3 = 1.0 - Quad(3.0) / Double(n)
            let b4 = 1.0 - Quad(4.0) / Double(n)
            var x1 = Quad(0.0); var x2 = Quad(0.0); var x3 = Quad(0.0); var x4 = Quad(0.0)
            
            let tv = tic()
            for _ in 0..<n {
                x1 = a1 + b1 * x1
                x2 = a2 + b2 * x2
                x3 = a3 + b3 * x3
                x4 = a4 + b4 * x4
            }
            let t = toc(tv)
            print("   dot: ", terminator: ""); print_timing(4.0*Double(n), t: t)
        }
        
        func exp() {
            let n = 100
            
            var a = Quad(0)
            let d = Quad(10.0 / Double(n))
            var c = Quad(-5)
            
            let tv = tic()
            for _ in 0..<n {
                a += Quad.exp(c)
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

