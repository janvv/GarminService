//
//  LogglyServiceTableViewController.swift
//  LogglyServiceKitUI
//
//  Created by Darin Krauss on 6/20/19.
//  Copyright © 2019 LoopKit Authors. All rights reserved.
//

import UIKit
import LoopKit
import LoopKitUI
import GarminServiceKit

final class GarminServiceTableViewController: UITableViewController, UITextFieldDelegate {
    
    public enum Operation {
        case create
        case update
    }
    
    private let service: GarminService
    
    private let operation: Operation
    
    init(service: GarminService, for operation: Operation) {
        self.service = service
        self.operation = operation
        
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(AuthenticationTableViewCell.nib(), forCellReuseIdentifier: AuthenticationTableViewCell.className)
        tableView.register(TextButtonTableViewCell.self, forCellReuseIdentifier: TextButtonTableViewCell.className)
        
        title = service.localizedTitle
        
        if operation == .create {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        
        updateButtonStates()
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
        case credentials
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
        case .credentials:
            return 1
        case .deleteService:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .credentials:
            return nil
        case .deleteService:
            return " " // Use an empty string for more dramatic spacing
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .credentials:
            let cell = tableView.dequeueReusableCell(withIdentifier: AuthenticationTableViewCell.className, for: indexPath) as! AuthenticationTableViewCell
            cell.titleLabel.text = LocalizedString("Customer Token", comment: "The title of the Loggly customer token")
            cell.textField.text = service.customerToken
            cell.textField.enablesReturnKeyAutomatically = true
            cell.textField.keyboardType = .asciiCapable
            cell.textField.placeholder = LocalizedString("Required", comment: "The default placeholder for required text")
            cell.textField.returnKeyType = .done
            cell.textField.delegate = self
            return cell
        case .deleteService:
            let cell = tableView.dequeueReusableCell(withIdentifier: TextButtonTableViewCell.className, for: indexPath) as! TextButtonTableViewCell
            cell.textLabel?.text = LocalizedString("Delete Service", comment: "Button title to delete a service")
            cell.textLabel?.textAlignment = .center
            cell.tintColor = .delete
            return cell
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section)! {
        case .credentials:
            break
        case .deleteService:
            confirmDeletion {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let indexPath = tableView.indexPathForRow(at: tableView.convert(textField.frame.origin, from: textField.superview)) else {
            return true
        }
        
        let text = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        switch Section(rawValue: indexPath.section)! {
        case .credentials:
            service.customerToken = text
        case .deleteService:
            break
        }
        
        updateButtonStates()
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField.returnKeyType {
        case .done:
            textField.resignFirstResponder()
            done()
            return true
        default:
            return false
        }
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
