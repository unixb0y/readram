//
//  main.swift
//  readram
//
//  Created by Davide Toldo on 16.10.19.
//  Copyright © 2019 Davide Toldo. All rights reserved.
//

import Foundation

var address = ""
var length  = ""

let maxLen: UInt8 = 0xFB

if CommandLine.argc < 3 {
    print("Please pass -addr and -len parameters.")
    exit(EXIT_SUCCESS)
}
else {
    let arguments = CommandLine.arguments
    let addrIndex = arguments.firstIndex(where: { $0.prefix(5) == "-addr" })
    let lenIndex = arguments.firstIndex(where: { $0.prefix(4) == "-len" })
    address = arguments[(addrIndex ?? -1) + 1]
    length  = arguments[(lenIndex ?? -1) + 1]

    if addrIndex == nil || lenIndex == nil ||
        address.count == 0 || length.count == 0 {
        print("Please pass -addr and -len parameters.")
        exit(EXIT_SUCCESS)
    }
}

if address.prefix(2) != "0x" || length.prefix(2) != "0x" {
    print("Please pass parameters in hex.")
    exit(EXIT_SUCCESS)
}

guard
    let intAddr = Int(String(address.dropFirst(2)), radix: 16),
    let intLen  = Int(String(length.dropFirst(2)), radix: 16) else {
    print("NaN")
    exit(EXIT_SUCCESS)
}


let controller = IOBluetoothHostController.default()
let delegate = HCIDelegate()
controller?.delegate = delegate
delegate.waitingForOpcode = 0xFC4D

let numberOfPackets = intLen / Int(maxLen) + 1
var resultPackets = [String]()

NotificationCenter.default.addObserver(forName: NSNotification.Name("result"), object: nil, queue: nil) { (notification) in
    guard let info = notification.userInfo, let result = info["result"] as? String else { return }
    resultPackets.append(result)

    if resultPackets.count < numberOfPackets { return }

    let directory = FileManager.default.currentDirectoryPath + "/output.bin"
    print("Output in: \(directory)")
    try? resultPackets.joined().hexadecimal?.write(to: URL(fileURLWithPath: directory))

    exit(EXIT_SUCCESS)
}

var i = 0
while i < numberOfPackets {
    let readFrom = intAddr + i*Int(maxLen)
    var location = String(format:"%02X", readFrom)
    location = String(repeating: "0", count: 8-location.count) + location
    for i in [6,7,4,5,2,3,0,1] { location.append(Array(location)[i]) }
    location = String(location.dropFirst(8))
    let location2 = Array(location)

    var command: [UInt8] = [0x4D, 0xFC, 0x05]
    var j = 0
    while j < 4 {
        let a = "\(location2[j*2])\(location2[j*2+1])"
        command.append(UInt8(a, radix: 16)!)
        j += 1
    }
    if i == numberOfPackets-1 {
        command.append(UInt8(intLen % Int(maxLen)))
    }
    else {
        command.append(maxLen)
    }

    usleep(100000)
    DispatchQueue.global(qos: .background).async {
        Methods.sendArbitraryCommand4(&command, len: 0xF0)
    }

    i += 1
}

RunLoop.current.run()
