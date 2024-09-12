//
//  GarminServiceTableViewController.swift
//  GarminServiceKitUI
//
//  Created by Jan Wrede on 06/21/2024.
//  Copyright © 2024 Jan Wrede. All rights reserved.
//

import UIKit
import LoopKit
import LoopKitUI
import GarminServiceKit
import ConnectIQ
import os

extension Notification.Name {
    static let didReceiveURL = Notification.Name("didReceiveURL")
}


final class GarminServiceTableViewController: UITableViewController, UITextFieldDelegate, IQDeviceEventDelegate, IQUIOverrideDelegate, DeviceManagerDelegate {
   
    public enum Operation {
        case create
        case update
    }
    
    private let service: GarminService
    
    private let deviceManager = DeviceManager.sharedInstance
    //private var garmin: IQDevice?
    private let operation: Operation
    private let logger : Logger
    init(service: GarminService, for operation: Operation) {
        self.service = service
        self.operation = operation
        self.logger = Logger(subsystem: "Garmin", category: "GarminServiceTableViewController")
        super.init(style: .grouped)
        
        
        //The app delegate will handle the open URL event and post a notification with the URL and options. We need to observe this notification and handle the URL in the GarminServiceTableViewController.
        NotificationCenter.default.addObserver(forName: .didReceiveURL, object: nil, queue: nil) { Notification in
            self.handleOpenURL(Notification)
        }

        //The url scheme is what garmin connect will use to open this application
        ConnectIQ.sharedInstance().initialize(withUrlScheme: ReturnURLScheme, uiOverrideDelegate: self)
        logger.debug("ConnectIQ initialized")
        
    }
    
    // MARK: -
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //load old devices, this will cause devicesChanged() to be called
        self.deviceManager.delegate = self
        deviceManager.restoreDevicesFromFileSystem()
        
        
        //register reusable garmin device cells
        let bundle = Bundle(identifier: "com.loopkit.GarminServiceKitUI")
        let garminDeviceCellNib = UINib(nibName: "DeviceTableViewCell", bundle: bundle)
        tableView.register(garminDeviceCellNib, forCellReuseIdentifier: "iqdevicecell")
        
        //register reusable garmin service setting cells
        tableView.register(AuthenticationTableViewCell.nib(), forCellReuseIdentifier: AuthenticationTableViewCell.className)
        tableView.register(TextButtonTableViewCell.self, forCellReuseIdentifier: TextButtonTableViewCell.className)
        
        title = service.localizedTitle
        
        if operation == .create {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        
        updateButtonStates()
    }
    
    func handleOpenURL(_ notification: Notification) {
        //Handles the notification that was send from the app delegate after Loop was opened by garmin connect application in response to a openURL. The notification carries the Gamrin connect app response with information about the available garmin devices. We parse the device list using the DeviceManager and then set the current device
        
        //        guard let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String else {
        //            print("handleOpenURL: Source application value was nil, expecting \(IQGCMBundle); disregarind open request, likely not for us.")
        //            return false
        //        }
        
        self.logger.debug("Handling Open URL Notification: \(notification)")
        guard let url = notification.userInfo?["url"] as? URL else {
            logger.warning("No URL found, ignoring open request.")
            return
        }
        
        //verify open url origin comes from garmin connect
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let ciqBundle = urlComponents?.queryItems?.first(where: { $0.name == "ciqBundle" })?.value
        guard ciqBundle == IQGCMBundle else {
            logger.warning("handleOpenURL source != \(IQGCMBundle), disregarind open request, likely not for us.")
            return
        }
        
        //pass device list to Device Manager
        let devices = ConnectIQ.sharedInstance().parseDeviceSelectionResponse(from: url)
        deviceManager.handleDeviceSelectionList(devices: devices ?? [])
    }
    
    
    private func updateButtonStates() {
        //navigationItem.rightBarButtonItem?.isEnabled = service.hasConfiguration
    }
    
    @objc private func cancel() {
        view.endEditing(true)
        
        notifyComplete()
    }
    
    @objc private func done() {
        view.endEditing(true)
        
        switch operation {
        case .create:
            service.completeCreate()
            
            if let serviceNavigationController = navigationController as? ServiceNavigationController {
                serviceNavigationController.notifyServiceCreatedAndOnboarded(service)
            }
        case .update:
            service.completeUpdate()
        }
        
        notifyComplete()
    }
    
    private func confirmDeletion(completion: (() -> Void)? = nil) {
        view.endEditing(true)
        
        let alert = UIAlertController(serviceDeletionHandler: {
            self.service.completeDelete()
            self.notifyComplete()
        })
        
        present(alert, animated: true, completion: completion)
    }
    
    private func notifyComplete() {
        if let serviceNavigationController = navigationController as? ServiceNavigationController {
            serviceNavigationController.notifyComplete()
        }
    }
    
    // MARK: - Data Source
    
    private enum Section: Int, CaseIterable {
        case garminconnect
        case garmindevices
        case sendtestdata
        case deleteService
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        switch operation {
        case .create:
            return Section.allCases.count - 1   // No deleteService
        case .update:
            return Section.allCases.count
        }
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .garminconnect:
            return 1
        case .garmindevices:
            return self.deviceManager.devices.count
        case .deleteService:
            return 1
        case .sendtestdata:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .garminconnect:
            return "Connect Garmin Device"
        case .garmindevices:
            return "Available Garmin Devices"
        case .deleteService:
            return "Delete Service Section" // Use an empty string for more dramatic spacing
        case .sendtestdata:
            return "Send Test Data"
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .garminconnect:
            let cell = tableView.dequeueReusableCell(withIdentifier: "StandardCellIdentifier") ?? UITableViewCell(style: .default, reuseIdentifier: "StandardCellIdentifier")
            cell.textLabel?.text = "Connect Garmin Devices"
            self.logger.debug("GarminServiceTableViewController: Button added")
            return cell
        case .garmindevices:
            let device = self.deviceManager.devices[indexPath.row]
            let status = ConnectIQ.sharedInstance().getDeviceStatus(device)
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "iqdevicecell", for: indexPath) as! DeviceTableViewCell
            cell.nameLabel.text! = device.friendlyName
            cell.modelLabel.text! = device.modelName
            switch status {
                case .invalidDevice:
                    cell.statusLabel.text! = "Invalid Device"
                    cell.enabled = false
                case .bluetoothNotReady:
                    cell.statusLabel.text! = "Bluetooth Off"
                    cell.enabled = false
                case .notFound:
                    cell.statusLabel.text! = "Not Found"
                    cell.enabled = false
                case .notConnected:
                    cell.statusLabel.text! = "Not Connected"
                    cell.enabled = false
                case .connected:
                    cell.statusLabel.text! = "Connected"
                    cell.enabled = true
            }
            //if current active device has same UUID, then mark this row as selected
            if let activeDevice = self.service.app?.device {
                cell.accessoryType = device.uuid == activeDevice.uuid ? .checkmark : .none
            } else {
                cell.accessoryType = .none
            }
            return cell
        case .sendtestdata:
            let cell = tableView.dequeueReusableCell(withIdentifier: "StandardCellIdentifier") ?? UITableViewCell(style: .default, reuseIdentifier: "StandardCellIdentifier")
            cell.textLabel?.text = "Send Test Data"
            self.logger.debug("GarminServiceTableViewController: Button added")
            return cell
        case .deleteService:
            let cell = tableView.dequeueReusableCell(withIdentifier: TextButtonTableViewCell.className, for: indexPath) as! TextButtonTableViewCell
            cell.textLabel?.text = LocalizedString("Delete Service", comment: "Button title to delete a service")
            cell.textLabel?.textAlignment = .center
            cell.tintColor = .delete
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section)! {
        case .garminconnect:
            //Launches Garmin Connect Mobile for the purpose of retrieving a list of ConnectIQ-compatible devices.
            ConnectIQ.sharedInstance().showDeviceSelection()
            ConnectIQ.sharedInstance().showAppStoreForConnectMobile()
        case .garmindevices:
            let device = self.deviceManager.devices[indexPath.row]
            //if the selected row corresponds to device that is already active, deactivate it
            if let activeDevice = self.service.app?.device, activeDevice.uuid == device.uuid {
                self.service.setActiveGarminDevice(nil)
                self.logger.debug("Deselected device: \(device)")
            } else {
                self.service.setActiveGarminDevice(device)
                self.logger.debug("Selected device: \(device)")
            }
            tableView.reloadRows(at: [indexPath], with: .automatic)
        case .sendtestdata:
            
            if let app = self.service.app {
                self.logger.debug("Sending messages: Selected \(app.device)")
                let timestamp = Date().timeIntervalSince1970
                let data = ["glucose": 111, "trend": 111, "timestamp": Int(timestamp)] as [String : Any]
                sendMessage(data, app: app)
            } else {
                self.logger.debug("Tried sending test data but service has no active device")
            }
        case .deleteService:
            confirmDeletion {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    //MARK: - IQUIOverrideDelegate
    func needsToInstallConnectMobile() {
        logger.debug("Needs to install Connect Mobile")
        ConnectIQ.sharedInstance().showAppStoreForConnectMobile()
    }
    
    // MARK: - DeviceManager Event Delegate

    func devicesChanged() {
        logger.info("Devices changed: \(self.deviceManager.devices)")
        
        //register to new devices
        ConnectIQ.sharedInstance().unregister(forAllDeviceEvents: self);
        for device: IQDevice in self.deviceManager.devices {
            ConnectIQ.sharedInstance().register(forDeviceEvents: device, delegate: self)
        }
        
        //reload data if if table view is available
        if self.tableView != nil {
            self.tableView.reloadSections(IndexSet(integer: Section.garmindevices.rawValue), with: .automatic)
        }
    }
    
    //QDeviceEventDelegate
    func deviceStatusChanged(_ device: IQDevice, status: IQDeviceStatus) {
        // It appears that not having this method, will cause device unavailable errors when sending messages.
        if status != .connected {
            self.logger.debug("Status changed to \(status.rawValue)")
        }
        self.tableView.reloadSections(IndexSet(integer: Section.garmindevices.rawValue), with: .automatic)
    }
    
    //MARK: - Garmin Specific -
    
    func sendMessage(_ message: [String: Any], app: IQApp) {
        //We need to send a message to the garmin device using the ConnectIQ framework. We create a message object with the message data and the app object. We then send the message using the ConnectIQ send message method. We also register for the message progress and completion events
        
        self.logger.debug("Sending message: \(message)")
        
        ConnectIQ.sharedInstance().sendMessage(message, to: app, progress: {(sentBytes: UInt32, totalBytes: UInt32) -> Void in
            let percent: Double = 100.0 * Double(sentBytes / totalBytes)
            self.logger.debug("Progress: \(percent)% sent \(sentBytes) bytes of \(totalBytes)")
            }, completion: {(result: IQSendMessageResult) -> Void in
                self.logger.debug("Send message finished with result: \(NSStringFromSendMessageResult(result))")
        })
    }
    
    
}

extension AuthenticationTableViewCell: IdentifiableClass {}

extension AuthenticationTableViewCell: NibLoadable {}

extension TextButtonTableViewCell: IdentifiableClass {}

fileprivate extension UIAlertController {
    
    convenience init(serviceDeletionHandler handler: @escaping () -> Void) {
        self.init(
            title: nil,
            message: LocalizedString("Are you sure you want to delete this service?", comment: "Confirmation message for deleting a service"),
            preferredStyle: .actionSheet
        )
        
        addAction(UIAlertAction(
            title: LocalizedString("Delete Service", comment: "Button title to delete a service"),
            style: .destructive,
            handler: { _ in
                handler()
        }
        ))
        
        let cancel = LocalizedString("Cancel", comment: "The title of the cancel action in an action sheet")
        addAction(UIAlertAction(title: cancel, style: .cancel, handler: nil))
    }
    
}



