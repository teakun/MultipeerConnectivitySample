//
//  ViewController.swift
//  MultipeerConnectivitySample
//
//  Created by Yuki Takeda on 2018/10/24.
//  Copyright © 2018 TAKEDA Yuki. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController {

    let textView = UITextView()
    var messageTextField: UITextField?

    let manager = MultipeerConnectivityManager.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "chat"
        manager.delegate = self

        addSubviews()
        addConfigures()
        addConstraints()

        manager.startManager()
    }

    func addSubviews() {
        self.view.addSubview(textView)
    }

    func addConfigures() {
        extendedLayoutIncludesOpaqueBars = true
        let sendItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapMessageButton))
        self.navigationItem.setRightBarButton(sendItem, animated: false)
    }

    func addConstraints() {
        textView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.leftAnchor.constraint(equalTo: view.leftAnchor),
            textView.rightAnchor.constraint(equalTo: view.rightAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
    }

    @objc func didTapMessageButton() {
        showSendMessageAlert()
    }

    func showSendMessageAlert() {
        let alert = UIAlertController(title: "メッセージをおくる", message: "送りたい文章を入力してください", preferredStyle: .alert)
        let cancelButton = UIAlertAction(title: "cancel", style: .cancel, handler: nil)

        let sendButton = UIAlertAction(title: "send", style: .default, handler: { _ in
            if let message = alert.textFields?.first?.text {
                self.send(message: message)
            }
        })

        alert.addAction(cancelButton)
        alert.addAction(sendButton)
        alert.addTextField(configurationHandler: nil)
        present(alert, animated: true, completion: nil)
    }

    func send(message: String) {
        if let data = message.data(using: .utf8) {
            self.textView.text += UIDevice.current.name + ":" + message + "\n"
            manager.send(data: data)
        }
    }
}

extension ViewController: MultipeerConnectivityManagerDelegate {
    func mcManager(manager: MultipeerConnectivityManager, session: MCSession, didReceive data: Data, from peer: MCPeerID) {
        if let message = String(data: data, encoding: .utf8) {
            self.textView.text += peer.displayName + ":" + message + "\n"
        }
    }

    func mcManager(manager: MultipeerConnectivityManager, session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {

    }
}
