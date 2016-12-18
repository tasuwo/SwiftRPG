//
//  String+subscript.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/08/04.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation

extension String {

  subscript (i: Int) -> Character {
    return self[self.characters.index(self.startIndex, offsetBy: i)]
  }

  subscript (i: Int) -> String {
    return String(self[i] as Character)
  }

  subscript (r: Range<Int>) -> String {
    let start = characters.index(startIndex, offsetBy: r.lowerBound)
    let end = characters.index(start, offsetBy: r.upperBound - r.lowerBound)
    //let start = startIndex.advancedBy(r.startIndex)
    //let end = start.advancedBy(r.endIndex - r.startIndex)
    return self[Range(start ..< end)]
  }
}
