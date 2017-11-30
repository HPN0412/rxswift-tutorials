//
//  ViewController.swift
//  FS
//
//  Created by at-thinhuv on 11/28/17.
//  Copyright © 2017 thinhxavi. All rights reserved.
//

import UIKit
import MVVM
import RxSwift

class ViewController: UIViewController, MVVM.View {

    var disposeBag: DisposeBag! = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    deinit {
        print("Deinit \(self)")
        disposeBag = nil
    }
}
