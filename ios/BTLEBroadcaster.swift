//
//  BTLEBroadcaster.swift
//  Rakning
//
//  Created by Pivotal on 11/03/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit

protocol BTLEBroadcasterDelegate {
    func btleBroadcaster(_ broadcaster: BTLEBroadcaster, didUpdateState state: CBManagerState)
}

class BTLEBroadcaster: NSObject, CBPeripheralManagerDelegate {
    
    static let coLocateServiceUUID = CBUUID(nsuuid: UUID(uuidString: "c1f5983c-fa94-4ac8-8e2e-bb86d6de9b21")!)
    
    var delegate: BTLEBroadcasterDelegate?
    
    // This is safe to force-unwrap, according to the docs this will only be nil if we're running before the device
    // has been unlocked
    var deviceIdentifier = CBUUID(nsuuid: UIDevice.current.identifierForVendor!)
    
    static let deviceIdentifierCharacteristicUUID = CBUUID(nsuuid: UUID(uuidString: "85BF337C-5B64-48EB-A5F7-A9FED135C972")!)

    var primaryService: CBService?
    
    let restoreIdentifier: String = "CoLocatePeripheralRestoreIdentifier"
    
    var peripheralManager: CBPeripheralManager?
    
    var peripheral: CBPeripheral?
    
    func start(delegate: BTLEBroadcasterDelegate?) {
        self.delegate = delegate
        
        peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: nil,
            options: [CBPeripheralManagerOptionRestoreIdentifierKey: restoreIdentifier])
    }
    
    // MARK: CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        delegate?.btleBroadcaster(self, didUpdateState: peripheral.state)
        
        switch (peripheral.state) {
            
        case .unknown:
            print("\(#file).\(#function) .unknown")
            
        case .resetting:
            print("\(#file).\(#function) .resetting")
            
        case .unsupported:
            print("\(#file).\(#function) .unsupported")
            
        case .unauthorized:
            print("\(#file).\(#function) .unauthorized")
            
        case .poweredOff:
            print("\(#file).\(#function) .poweredOff")
            
        case .poweredOn:
            print("\(#file).\(#function) .poweredOn")
         
            let service = CBMutableService(type: BTLEBroadcaster.coLocateServiceUUID, primary: true)
            
            let identityCharacteristic = CBMutableCharacteristic(type: BTLEBroadcaster.deviceIdentifierCharacteristicUUID, properties: CBCharacteristicProperties([.read]), value: deviceIdentifier.data, permissions: .readable)
            
            service.characteristics = [identityCharacteristic]
            peripheralManager?.add(service)
        @unknown default:
            fatalError()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        guard error == nil else {
            print("\(#file).\(#function) error: \(String(describing: error))")
            return
        }
        
        print("\(#file).\(#function) service: \(service)")
        self.primaryService = service
        
        print("\(#file).\(#function) advertising device identifier \(deviceIdentifier.uuidString)")
        peripheralManager?.startAdvertising([
            CBAdvertisementDataLocalNameKey: "CoLocate",
            CBAdvertisementDataServiceUUIDsKey: [service.uuid]
        ])
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        print("\(#file).\(#function)")

        self.peripheralManager = peripheral
        if let services = dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService] {
            self.primaryService = services.first
        } else {
            print("\(#file).\(#function) No services to restore!")
        }
    }
    
}