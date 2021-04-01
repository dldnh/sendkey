//  test1.swift
//  why can't I send ctrl+cmd+l to vnc?

import Cocoa

let src = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)

let commandKey: UInt16 = 0x37
let controlKey: UInt16 = 0x3b
let ellKey: UInt16 = 0x25
let aitchKey: UInt16 = 0x04
let ceeKey: UInt16 = 0x08

let commandDown = CGEvent(keyboardEventSource: src, virtualKey: commandKey, keyDown: true)!
let commandUp = CGEvent(keyboardEventSource: src, virtualKey: commandKey, keyDown: false)!
let controlDown = CGEvent(keyboardEventSource: src, virtualKey: controlKey, keyDown: true)!
let controlUp = CGEvent(keyboardEventSource: src, virtualKey: controlKey, keyDown: false)!
let ellDown = CGEvent(keyboardEventSource: src, virtualKey: ellKey, keyDown: true)!
let ellUp = CGEvent(keyboardEventSource: src, virtualKey: ellKey, keyDown: false)!
let aitchDown = CGEvent(keyboardEventSource: src, virtualKey: aitchKey, keyDown: true)!
let aitchUp = CGEvent(keyboardEventSource: src, virtualKey: aitchKey, keyDown: false)!
let ceeDown = CGEvent(keyboardEventSource: src, virtualKey: ceeKey, keyDown: true)!
let ceeUp = CGEvent(keyboardEventSource: src, virtualKey: ceeKey, keyDown: false)!

let bid = "com.realvnc.vncviewer"
//let bid = "org.gnu.Emacs"
var pid = pid_t(-1)
for x in NSWorkspace.shared.runningApplications {
    if x.bundleIdentifier == bid {
        pid = x.processIdentifier
        break
    }
}

NSRunningApplication(processIdentifier: pid)!.activate(options: .activateIgnoringOtherApps)

let controlMask = CGEventFlags.maskControl.rawValue
let cmdControlMask = CGEventFlags.maskControl.rawValue | CGEventFlags.maskCommand.rawValue

let keysAndMasks = [
  (controlDown, controlMask),
  (aitchDown, controlMask),
  (aitchUp, controlMask),
  (controlUp, controlMask),
  (ceeDown, 0),
  (ceeUp, 0),
  (commandDown, cmdControlMask),
  (controlDown, cmdControlMask),
  (ellDown, cmdControlMask),
  (ellUp, cmdControlMask),
  (commandUp, cmdControlMask),
  (controlUp, cmdControlMask),
]

for (i, (key, mask)) in keysAndMasks.enumerated() {
    if i > 0 {
        usleep(100_000)
    }
    key.flags = CGEventFlags(rawValue: mask)
    key.postToPid(pid)
}
