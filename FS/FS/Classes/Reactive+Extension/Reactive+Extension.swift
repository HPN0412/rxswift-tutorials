//
//  Reactive+Extension.swift
//  FS
//
//  Created by at-thinhuv on 11/28/17.
//  Copyright © 2017 thinhxavi. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SVProgressHUD

public extension ObservableType {
    public func withHUD() -> Observable<Self.E> {
        return self.do(onNext: nil, onError: { (error) in
            DispatchQueue.main.async {
                SVProgressHUD.showInfo(withStatus: error.localizedDescription)
            }
        }, onCompleted: {
            dismissHUD()
        }, onSubscribe: nil, onSubscribed: {
            showHUD()
        }, onDispose: {
            dismissHUD()
        })
    }
}

extension Observable {
//    func onRealm() -> Observable<Self.E> {
//        return Observable.empty()
//    }
}
