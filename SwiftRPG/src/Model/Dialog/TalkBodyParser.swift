//
//  TalkBodyParser.swift
//  SwiftRPG
//
//  Created by 兎澤佑 on 2016/02/26.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON

class TalkBodyParser {
    fileprivate var body: String!
    
    init?(talkFileName: String) {
        if let path: String = Bundle.main.path(forResource: talkFileName, ofType: nil),
           let fileHandle: FileHandle = FileHandle(forReadingAtPath: path)
        {
            let data: Data = fileHandle.readDataToEndOfFile()
            self.body = NSString(data:data, encoding:String.Encoding.utf8.rawValue) as! String
        } else {
            self.body = nil
            return nil
        }
    }
    
    ///  パース状態
    ///
    ///  - CONFIG: プレイヤー情報読み込み
    ///  - BODY:   会話内容読み込み
    fileprivate enum PARSING {
        case config
        case body
    }
    
    func parse() -> JSON {
        var index: Int = 0
        var state: PARSING = .config
        var didReadBody = false
        var talksInfo = [[String: String]]()
        var talkInfo = [String: String]()
        var tmpTalkBody: String = ""
        
        self.body.enumerateLines {
            (line, stop) -> () in

            if line == "!" {
                talkInfo["talk_body"] = tmpTalkBody
                talksInfo.append(talkInfo)
                tmpTalkBody = ""
                index += 1
                state = .config
                didReadBody = false
                return
            }
            
            switch state {
            case .config:
                var config = line.characters.split(separator: ":").map{ String($0) }
                talkInfo["talker"] = config[0]
                talkInfo["talk_side"] = config[1]
                state = .body
                break
            case .body:
                if didReadBody {
                    tmpTalkBody.append(line)
                    return
                }
                tmpTalkBody.append(Dialog.NEWLINE_CHAR)
                tmpTalkBody.append(line)
                break
            }
        }

        return JSON(talksInfo)
    }
}
