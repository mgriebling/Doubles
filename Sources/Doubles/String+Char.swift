//
//  String+Char.swift
//  QuadReal
//
//  Created by Mike Griebling on 1 Jul 2015.
//  Copyright (c) 2015 Computer Inspirations. All rights reserved.
//

import Foundation

public extension String {
	
	// Extensions to make it easier to work with C-style strings	
    subscript (n: Int) -> Character {
        get {
            if !self.isEmpty, let s = self.index(startIndex, offsetBy: n, limitedBy: self.index(endIndex, offsetBy: -1)) {
                return self[s]
            }
            return "\0"
        }
        set {
            // Strings are immutable so this gets messy and is probably not very efficient
            if let s = self.index(startIndex, offsetBy: n, limitedBy: self.index(endIndex, offsetBy: -1)) {
                self = self.replacingCharacters(in: s...s, with: String(newValue))
            }
        }
    }
	
}

public extension Character {

    var unicodeValue : Int { Int(unicodeScalar.value) }
    var unicodeScalar : UnicodeScalar { String(self).unicodeScalars.first ?? "\0" }

    init(_ int: Int) { self = String(describing: UnicodeScalar(int)!).first! }
	func add (_ n: Int) -> Character { Character(self.unicodeValue + n) }
	
}

public func + (c: Character, inc: Int) -> Character { c.add(inc) }
public func - (c: Character, inc: Int) -> Character { c.add(-inc) }
public func += (c: inout Character, inc: Int) { c = c + inc }
public func -= (c: inout Character, inc: Int) { c = c - inc }

