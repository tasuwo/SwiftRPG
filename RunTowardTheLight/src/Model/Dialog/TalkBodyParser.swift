//
//  TalkBodyParser.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2016/02/26.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON

class TalkBodyParser {
    private var body: String!
    
    
    ///  <#Description#>
    ///
    ///  - parameter talkFileName: <#talkFileName description#>
    ///
    ///  - returns: <#return value description#>
    init?(talkFileName: String) {
        if
            let path: String = NSBundle.mainBundle().pathForResource(talkFileName, ofType: nil),
            let fileHandle: NSFileHandle = NSFileHandle(forReadingAtPath: path),
            let data: NSData = fileHandle.readDataToEndOfFile()
        {
            self.body = NSString(data:data, encoding:NSUTF8StringEncoding) as! String
            
            
        } else {
            self.body = nil
            return nil
        }
        print(self.body)
    }
    
    private enum PARSING {
        case BEGIN
        case CONFIG
        case BODY
    }
    
    func parse() {
        //var index: Int = 0
        var state: PARSING = .BEGIN
        var tmpBody: String = ""
        var hasReadBodyFlg = false
        self.body.enumerateLines { (line, stop) -> () in
            if line == "!" {
                state = .CONFIG
                hasReadBodyFlg = false
                return
            }
            
            switch state {
            case .CONFIG:
                var config = line.characters.split(":").map{ String($0) }
                print("player:" + config[0])
                print("side:" + config[1])
                state = .BODY
                break
            case .BODY:
                if hasReadBodyFlg {
                    tmpBody.appendContentsOf(line)
                    
                    return
                }
                tmpBody.append(Dialog.NEWLINE_CHAR)
                tmpBody.appendContentsOf(line)
                print(tmpBody)
                break
            default:
                return
            }
        }
        self.body.append(Dialog.NEWLINE_CHAR)
    }
}