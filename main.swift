//
//  main.swift
//  sendkey
//
//  Created by Dave Diamond on 2/23/21.
//
//////////////////////////////////////////////////////////////////
//
//  license: MIT (see LICENSE)
//
//  usage:
//
//  $ swift main.swift -list
//  shows list of running apps' bundle id's
//
//  $ swift main.swift com.domain.App mods+key mods+key mods+key...
//  - com.domain.App is target app's bundle id
//  - mods is cmd+ctrl+shift+opt in any combination
//  - key is 2-digit hex or name from keytable
//
//  example:
//
//  $ swift main.swift com.apple.TextEdit t h e space q u i c k space b r o w n space f o x return cmd+a cmd+c cmd+v cmd+v cmd+v
//  types a message in TextEdit, then copies it and pastes it three times
//  $ swift main.swift com.apple.TextEdit @"the quick brown fox" return 
//  also types that famous message in TextEdit, but with less fuss and bother

import Cocoa

let oneArg = CommandLine.argc == 2 ? CommandLine.arguments[1] : nil

if oneArg == "-h" || oneArg == "-help" {
    print("""
          sendkey [ options ] target-app event...
          options:
            -list       : list applications
            -activate   : force activation of target-app
          event:
            (cmd/opt/ctrl/shift)+keyname
            @"string"
          """)
    exit(0)
}

if oneArg == "-list" {
    for app in NSWorkspace.shared.runningApplications
            .filter({ $0.activationPolicy == .regular }) {
        guard let bid = app.bundleIdentifier else {
            continue
        }
        print(bid)
    }
    exit(0)
}

var needToActivate = false

if CommandLine.argc >= 2 && CommandLine.arguments[1] == "-activate" {
    CommandLine.arguments.remove(at: 1)
    needToActivate = true
}

if CommandLine.argc <= 2 {
    print("missing args")
    exit(0)
}

let bid = CommandLine.arguments[1]

// from /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Headers/Events.h
let keytable: [String: UInt16] = [
    "a": 0x00, "s": 0x01, "d": 0x02, "f": 0x03, "h": 0x04, "g": 0x05, "z": 0x06, "x": 0x07,
    "c": 0x08, "v": 0x09, "b": 0x0b, "q": 0x0c, "w": 0x0d, "e": 0x0e, "r": 0x0f, "y": 0x10,
    "t": 0x11, "1": 0x12, "2": 0x13, "3": 0x14, "4": 0x15, "6": 0x16, "5": 0x17, "equal": 0x18,
    "9": 0x19, "7": 0x1a, "minus": 0x1b, "8": 0x1c, "0": 0x1d, "rightbracket": 0x1e, "o": 0x1f,
    "u": 0x20, "leftbracket": 0x21, "i": 0x22, "p": 0x23, "l": 0x25, "j": 0x26, "quote": 0x27,
    "k": 0x28, "semicolon": 0x29, "backslash": 0x2a, "comma": 0x2b, "slash": 0x2c, "n": 0x2d,
    "m": 0x2e, "period": 0x2f, "grave": 0x32, "keypaddecimal": 0x41, "keypadmultiply": 0x43,
    "keypadplus": 0x45, "keypadclear": 0x47, "keypaddivide": 0x4b, "keypadenter": 0x4c,
    "keypadminus": 0x4e, "keypadequals": 0x51, "keypad0": 0x52, "keypad1": 0x53, "keypad2": 0x54,
    "keypad3": 0x55, "keypad4": 0x56, "keypad5": 0x57, "keypad6": 0x58, "keypad7": 0x59,
    "keypad8": 0x5b, "keypad9": 0x5c, "return": 0x24, "tab": 0x30, "space": 0x31, "delete": 0x33,
    "escape": 0x35, "command": 0x37, "shift": 0x38, "capslock": 0x39, "option": 0x3a,
    "control": 0x3b, "rightcommand": 0x36, "rightshift": 0x3c, "rightoption": 0x3d,
    "rightcontrol": 0x3e, "function": 0x3f, "f17": 0x40, "volumeup": 0x48, "volumedown": 0x49,
    "mute": 0x4a, "f18": 0x4f, "f19": 0x50, "f20": 0x5a, "f5": 0x60, "f6": 0x61, "f7": 0x62,
    "f3": 0x63, "f8": 0x64, "f9": 0x65, "f11": 0x67, "f13": 0x69, "f16": 0x6a, "f14": 0x6b,
    "f10": 0x6d, "f12": 0x6f, "f15": 0x71, "help": 0x72, "home": 0x73, "pageup": 0x74,
    "forwarddelete": 0x75, "f4": 0x76, "end": 0x77, "f2": 0x78, "pagedown": 0x79, "f1": 0x7a,
    "leftarrow": 0x7b, "rightarrow": 0x7c, "downarrow": 0x7d, "uparrow": 0x7e,
]

let shift: UInt64 = CGEventFlags.maskShift.rawValue
let chartable: [Character: (UInt16, UInt64)] = [
    " ": (0x31, 0), "!": (0x12, shift), "#": (0x14, shift), "$": (0x15, shift),
    "%": (0x17, shift), "&": (0x1a, shift), "'": (0x27, 0), "(": (0x19, shift),
    ")": (0x1d, shift), "*": (0x1c, shift), "+": (0x1b, shift), ",": (0x2b, 0), "-": (0x1b, 0),
    ".": (0x2f, 0), "/": (0x2c, 0), "0": (0x1d, 0), "1": (0x12, 0), "2": (0x13, 0),
    "3": (0x14, 0), "4": (0x15, 0), "5": (0x17, 0), "6": (0x16, 0), "7": (0x1a, 0),
    "8": (0x1c, 0), "9": (0x19, 0), ":": (0x29, shift), ";": (0x29, 0), "<": (0x2b, shift),
    "=": (0x18, 0), ">": (0x2f, shift), "?": (0x2c, shift), "@": (0x13, shift),
    "A": (0x00, shift), "B": (0x0b, shift), "C": (0x08, shift), "D": (0x02, shift),
    "E": (0x0e, shift), "F": (0x03, shift), "G": (0x05, shift), "H": (0x04, shift),
    "I": (0x22, shift), "J": (0x26, shift), "K": (0x28, shift), "L": (0x25, shift),
    "M": (0x2e, shift), "N": (0x2d, shift), "O": (0x1f, shift), "P": (0x23, shift),
    "Q": (0x0c, shift), "R": (0x0f, shift), "S": (0x01, shift), "T": (0x11, shift),
    "U": (0x20, shift), "V": (0x09, shift), "W": (0x0d, shift), "X": (0x07, shift),
    "Y": (0x10, shift), "Z": (0x06, shift), "[": (0x21, 0), "\"": (0x27, shift),
    "\\": (0x2a, 0), "\n": (0x24, 0), "\t": (0x30, 0), "]": (0x1e, 0), "^": (0x16, shift),
    "_": (0x1b, shift), "`": (0x32, 0), "a": (0x00, 0), "b": (0x0b, 0), "c": (0x08, 0),
    "d": (0x02, 0), "e": (0x0e, 0), "f": (0x03, 0), "g": (0x05, 0), "h": (0x04, 0),
    "i": (0x22, 0), "j": (0x26, 0), "k": (0x28, 0), "l": (0x25, 0), "m": (0x2e, 0),
    "n": (0x2d, 0), "o": (0x1f, 0), "p": (0x23, 0), "q": (0x0c, 0), "r": (0x0f, 0),
    "s": (0x01, 0), "t": (0x11, 0), "u": (0x20, 0), "v": (0x09, 0), "w": (0x0d, 0),
    "x": (0x07, 0), "y": (0x10, 0), "z": (0x06, 0), "{": (0x21, shift), "|": (0x2a, shift),
    "}": (0x1e, shift), "~": (0x32, shift),
]

var keys = [UInt16]()
var flags = [CGEventFlags]()
var preKeysArr = [[CGEvent]]()
var postKeysArr = [[CGEvent]]()

let src = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)

// inspired by the diagram at https://stackoverflow.com/a/28012706
let commandKey: UInt16 = 0x37
let shiftKey: UInt16 = 0x38
let capslockKey: UInt16 = 0x39
let optionKey: UInt16 = 0x3a
let controlKey: UInt16 = 0x3b

let commandDown = CGEvent(keyboardEventSource: src, virtualKey: commandKey, keyDown: true)!
let commandUp = CGEvent(keyboardEventSource: src, virtualKey: commandKey, keyDown: false)!
let shiftDown = CGEvent(keyboardEventSource: src, virtualKey: shiftKey, keyDown: true)!
let shiftUp = CGEvent(keyboardEventSource: src, virtualKey: shiftKey, keyDown: false)!
let capslockDown = CGEvent(keyboardEventSource: src, virtualKey: capslockKey, keyDown: true)!
let capslockUp = CGEvent(keyboardEventSource: src, virtualKey: capslockKey, keyDown: false)!
let optionDown = CGEvent(keyboardEventSource: src, virtualKey: optionKey, keyDown: true)!
let optionUp = CGEvent(keyboardEventSource: src, virtualKey: optionKey, keyDown: false)!
let controlDown = CGEvent(keyboardEventSource: src, virtualKey: controlKey, keyDown: true)!
let controlUp = CGEvent(keyboardEventSource: src, virtualKey: controlKey, keyDown: false)!

for (i, arg0) in CommandLine.arguments.enumerated() where i > 1 {
    var key: UInt16?
    var arg: String!
    var mask: UInt64 = 0
    var preKeys = [CGEvent]()
    var postKeys = [CGEvent]()
    if arg0.starts(with: "@") {
        let start = arg0.index(arg0.startIndex, offsetBy: 1)
        let end = arg0.index(arg0.endIndex, offsetBy: 0)
        for char in arg0[start..<end] {
            (key, mask) = chartable[char]!
            keys.append(key!)
            let flag = CGEventFlags(rawValue: mask)
            flags.append(flag)
            preKeysArr.append(preKeys)
            postKeysArr.append(postKeys)
            mask = 0
        }
        continue
    } else if arg0.contains("+") {
        let split = arg0.split(separator: "+").reversed()
        arg = String(split.first!)
        for (j, meta) in split.enumerated() where j > 0 {
            switch meta {
            case "cmd":
                preKeys.append(commandDown)
                postKeys.append(commandUp)
                mask |= CGEventFlags.maskCommand.rawValue
                needToActivate = true
                break
            case "ctrl":
                preKeys.append(controlDown)
                postKeys.append(controlUp)
                mask |= CGEventFlags.maskControl.rawValue
                break
            case "shift":
                preKeys.append(shiftDown)
                postKeys.append(shiftUp)
                mask |= CGEventFlags.maskShift.rawValue
                break
            case "opt":
                preKeys.append(optionDown)
                postKeys.append(optionUp)
                mask |= CGEventFlags.maskAlternate.rawValue
                needToActivate = true
                break
            case "lock":
                preKeys.append(capslockDown)
                postKeys.append(capslockUp)
                break
            default:
                print("Could not parse: \(meta)")
                exit(-1)
            }
        }
    } else {
        arg = arg0
    }
    let flag = CGEventFlags(rawValue: mask)
    flags.append(flag)
    key = keytable[arg]
    if key == nil {
        key = UInt16(arg, radix: 16)
    }
    if key == nil {
        print("Could not look up or parse: \(arg!)")
        exit(-1)
    }
    keys.append(key!)
    preKeysArr.append(preKeys)
    postKeysArr.append(postKeys)
}

if keys.count != flags.count {
    print("Internal error, keys/flags counts mismatch \(keys.count)/\(flags.count)")
    exit(-1)
} else if keys.count != preKeysArr.count {
    print("Internal error, keys/preKeyss counts mismatch \(keys.count)/\(preKeysArr.count)")
    exit(-1)
} else if keys.count != postKeysArr.count {
    print("Internal error, keys/postKeyss counts mismatch \(keys.count)/\(postKeysArr.count)")
    exit(-1)
}

var pid = pid_t(-1)

for x in NSWorkspace.shared.runningApplications {
    if x.bundleIdentifier == bid {
        pid = x.processIdentifier
        break
    }
}

if pid < 0 {
    let bidLC = bid.lowercased()
    for x in NSWorkspace.shared.runningApplications {
        if x.activationPolicy != .regular { continue }
        guard let xBid = x.bundleIdentifier else { continue }
        let parts = xBid.lowercased().split(separator: ".")
        for p in parts where p == bidLC {
            if pid >= 0 {
                print("Multiple running apps matching \(bid)")
                exit(-1)
            }
            pid = x.processIdentifier
        }
    }
}

if pid < 0 {
    print("Can't find target app matching \(bid)")
    exit(-1)
}

guard let app = NSRunningApplication(processIdentifier: pid) else {
    print("Can't find target app \(bid)")
    exit(-1)
}

guard let own = getOwner() else {
    print("Can't find own app!")
    exit(-1)
}

if needToActivate {
    app.activate(options: .activateIgnoringOtherApps)
}

let betweenKeyNaptime: useconds_t = 100_000

for (i, key) in keys.enumerated() {
    let keydown = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: true)!
    keydown.flags = flags[i]

    let keyup = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: false)!
    keyup.flags = flags[i]

    for preKey in preKeysArr[i] {
        preKey.flags = flags[i]
        preKey.postToPid(pid)
        usleep(betweenKeyNaptime)
    }

    keydown.postToPid(pid)
    usleep(betweenKeyNaptime)
    keyup.postToPid(pid)

    for postKey in postKeysArr[i] {
        usleep(betweenKeyNaptime)
        postKey.flags = flags[i]
        postKey.postToPid(pid)
    }
}

if needToActivate {
    own.activate(options: .activateIgnoringOtherApps)
}

func getOwner() -> NSRunningApplication? {
    var curr = ProcessInfo().processIdentifier
    while curr > 0 {
        for app in NSWorkspace.shared.runningApplications {
            if app.processIdentifier == curr {
                return app
            }
        }
        curr = getParentPID(curr)
    }
    return nil
}

func getParentPID(_ pid: pid_t) -> pid_t {
    do {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-p", "\(pid)", "-x", "-o", "ppid"]
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        try task.run()
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)
        let error = String(decoding: errorData, as: UTF8.self)
        if error.count > 0 {
            fatalError(error)
        }
        var lines = output.split(separator: "\n")
        lines.remove(at: 0)
        for line in lines {
            let trim = line.trimmingCharacters(in: [" "])
            return pid_t(trim) ?? 0
        }
    } catch {
        fatalError(error.localizedDescription)
    }
    return 0
}
