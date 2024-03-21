//
//  ViewController.swift
//  Auth0-Integration
//
//  Created by Ahmed Sadiq on 21/03/2024.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    private func login() {
        AuthService.shared.login { credentials in
            // Handle credentials here
        }
    }
}

