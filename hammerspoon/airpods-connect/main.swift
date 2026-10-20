import Foundation
import IOBluetooth

let device = IOBluetoothDevice(addressString: "34-0e-22-23-9f-ba")
exit(device?.openConnection() == kIOReturnSuccess ? 0 : 1)
