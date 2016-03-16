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
    }
    
    ///  パース状態
    ///
    ///  - CONFIG: プレイヤー情報読み込み
    ///  - BODY:   会話内容読み込み
    private enum PARSING {
        case CONFIG
        case BODY
    }
    
    func parse() -> JSON {
        var index: Int = 0
        var state: PARSING = .CONFIG
        var didReadBody = false
        var talksInfo = [[String: String]]()
        var talkInfo = [String: String]()
        var tmpTalkBody: String = ""
        
        self.body.enumerateLines { (line, stop) -> () in
            if line == "!" {
                talkInfo["talk_body"] = tmpTalkBody
                talksInfo.append(talkInfo)
                tmpTalkBody = ""
                index += 1
                state = .CONFIG
                didReadBody = false
                return
            }
            
            switch state {
            case .CONFIG:
                var config = line.characters.split(":").map{ String($0) }
                talkInfo["talker"] = config[0]
                talkInfo["talk_side"] = config[1]
                state = .BODY
                break
            case .BODY:
                if didReadBody {
                    tmpTalkBody.appendContentsOf(line)
                    return
                }
                tmpTalkBody.append(Dialog.NEWLINE_CHAR)
                tmpTalkBody.appendContentsOf(line)
                break
            }
        }

        return JSON(talksInfo)
    }
}