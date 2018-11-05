//
//  MultipeerConnectivityManager.swift
//  MultipeerConnectivitySample
//
//  Created by Yuki Takeda on 2018/10/26.
//  Copyright © 2018 TAKEDA Yuki. All rights reserved.
//

import Foundation
import UIKit
import MultipeerConnectivity

protocol MultipeerConnectivityManagerDelegate {
    // データをうけとったとき
    func mcManager(manager: MultipeerConnectivityManager, session: MCSession, didReceive data: Data, from peer: MCPeerID)

    // 接続中の端末の状態に変化があったとき
    func mcManager(manager: MultipeerConnectivityManager, session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState)
}

class MultipeerConnectivityManager: NSObject {
    static let sharedInstance = MultipeerConnectivityManager()

    private let serviceType = "mcsample"
    private let timeoutInterval = 10.0
    private var browser: MCNearbyServiceBrowser?
    private var advertiser: MCNearbyServiceAdvertiser?

    private lazy var session: MCSession = {
        let session = MCSession(peer: self.ownID, securityIdentity: nil, encryptionPreference: .optional)
        session.delegate = self
        return session
    }()

    private lazy var ownID: MCPeerID = {
        return MCPeerID(displayName: UIDevice.current.name)
    }()

    var delegate: MultipeerConnectivityManagerDelegate?

    // 接続中の端末一覧
    var connectedPeers: [MCPeerID] {
        return session.connectedPeers
    }

    deinit {
        self.session.disconnect()
        self.stopManager()
    }

    override init() {
        super.init()
    }

    // 接続処理開始
    func startManager() {
        self.browser = MCNearbyServiceBrowser(peer: self.ownID, serviceType: self.serviceType)
        self.advertiser = MCNearbyServiceAdvertiser(peer: self.ownID, discoveryInfo: nil, serviceType: self.serviceType)

        self.browser?.delegate = self
        self.advertiser?.delegate = self

        self.browser?.startBrowsingForPeers()
        self.advertiser?.startAdvertisingPeer()

    }

    // 接続処理の終了
    func stopManager() {
        browser?.stopBrowsingForPeers()
        advertiser?.stopAdvertisingPeer()
        browser?.delegate = nil
        advertiser?.delegate = nil
        browser = nil
        advertiser = nil
    }

    // 全体へのデータの送信
    func send(data: Data) {
        send(data: data, peers: connectedPeers)
    }

    // 一つに対してのデータの送信
    func send(data: Data, peer: MCPeerID) {
        let peers = [peer]
        send(data: data, peers: peers)
    }

    // 一部へのデータの送信
    func send(data: Data, peers: [MCPeerID]) {
        if peers.count > 0 {
            do {
                try session.send(data, toPeers: peers, with: .reliable)
            } catch let error {
                print(error)
            }
        }
    }

}

extension MultipeerConnectivityManager: MCNearbyServiceBrowserDelegate {
    // 他端末を発見したとき
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // 自分自身を発見したときはスルー
        if peerID == ownID {
            return
        }

        // それ以外はすべて招待
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: timeoutInterval)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {}
}

extension MultipeerConnectivityManager: MCNearbyServiceAdvertiserDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {}

    // 招待を受けたとき
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // 自身でなければ参加，自身の場合は参加しない
        if peerID != ownID {
            invitationHandler(true, self.session)
        } else {
            invitationHandler(false, nil)
        }
    }
}

extension MultipeerConnectivityManager: MCSessionDelegate {
    // データを受信したとき
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.delegate?.mcManager(manager: self, session: session, didReceive: data, from: peerID)
        }
    }

    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.delegate?.mcManager(manager: self, session: session, peer: peerID, didChange: state)
        }
    }

    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
}
