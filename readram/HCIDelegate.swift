//
//  HCIDelegate.swift
//  IOBluetoothExtended
//
//  Created by Davide Toldo on 03.09.19.
//  Copyright © 2019 Davide Toldo. All rights reserved.
//

import Foundation

class HCIDelegate: NSObject {
    @objc var waitingForOpcode = 0
}

extension HCIDelegate: IOBluetoothHostControllerDelegate {
    public func bluetoothHCIEventNotificationMessage(_ controller: IOBluetoothHostController,
        in message: UnsafeMutablePointer<IOBluetoothHCIEventNotificationMessage>) {
        
        let opcode = message.pointee.dataInfo.opcode
        let data = IOBluetoothHCIEventParameterData(message)
        if opcode != waitingForOpcode { return }
        
        let result = String(data.hexEncodedString().dropFirst(2))
        NotificationCenter.default.post(name: NSNotification.Name("result"), object: nil, userInfo: ["result": result])

//        let str = result.separate()
//        var str2 = ""
//        for (i, sub) in str.components(separatedBy: " ").enumerated() {
//            if i % 8 == 7 {
//                let rowIndex = i/8
//                let start = result.index(result.startIndex, offsetBy: rowIndex * 32)
//                let end = rowIndex * 32 + 32 < result.count ?
//                    result.index(result.startIndex, offsetBy: rowIndex * 32 + 32) :
//                    result.endIndex
//                let range = start..<end
//                let row = String(result[range])
//                str2.append(sub + " \(hexStringtoAscii(row))\n")
//            }
//            else {
//                str2.append(sub + " ")
//            }
//        }
//
//        print(str2)
    }
    
    func hexStringtoAscii(_ hexString : String) -> String {
        
        let pattern = "(0x)?([0-9a-f]{2})"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let nsString = hexString as NSString
        let matches = regex.matches(in: hexString, options: [], range: NSMakeRange(0, nsString.length))
        var characters = matches.map {
            Character(UnicodeScalar(UInt32(nsString.substring(with: $0.range(at: 2)), radix: 16)!)!)
        }
        characters = characters.map {
            if !$0.isASCII { return "." }
            if $0.asciiValue! < 32 { return "." }
            if $0.asciiValue! > 130 { return "." }
            if $0.isNewline { return "." }
            if $0 == "\0" { return "." }
            return $0
        }
        return String(characters)
    }
}
