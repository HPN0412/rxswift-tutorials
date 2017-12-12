//
//  HomeViewController.swift
//  FS
//
//  Created by at-thinhuv on 11/28/17.
//  Copyright © 2017 thinhxavi. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import SVProgressHUD

final class HomeViewController: ViewController {
    // MARK: - IBOutlets
    @IBOutlet private weak var tableView: UITableView!

    // MARK: - Propertie
    private var refreshControl = UIRefreshControl()
    var viewModel = HomeViewModel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Home"
        setupUI()
        setupData()
    }

    // MARK: - Private funtions
    private func setupUI() {
        let nib = UINib(nibName: "VenueCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "VenueCell")
        tableView.rowHeight = 143.0
        tableView.addSubview(refreshControl)

        tableView.rx.itemSelected
            .map { indexPath in
                self.viewModel.venue(at: indexPath)
            }
            .subscribeOn(MainScheduler.instance)
            .subscribe { [weak self] (event) in
                guard let this = self else { return }
                switch event {
                case .next(let venue):
                    if let selectRowIndexPath = this.tableView.indexPathForSelectedRow {
                        this.tableView.deselectRow(at: selectRowIndexPath, animated: true)
                    }
                    let viewModel = VenueDetailViewModel(venueId: venue.id)
                    let detailController = VenueDetailViewController()
                    detailController.viewModel = viewModel
                    this.navigationController?.pushViewController(detailController, animated: true)
                case .error(let error):
                    print("dkm", error.localizedDescription)
                default:
                    break
                }
            }
            .disposed(by: disposeBag)
    }

    private func setupData() {
        viewModel.venues.asObservable()
            .bind(to: tableView.rx.items(cellIdentifier: "VenueCell", cellType: VenueCell.self)) { (index, venue, cell) in
                cell.viewModel = VenueCellViewModel(venue: venue)
            }
            .disposed(by: disposeBag)

        viewModel.isRefreshing.asDriver().drive(refreshControl.rx.isRefreshing)
            .addDisposableTo(disposeBag)

        refreshControl.rx.controlEvent(.valueChanged)
            .subscribe(onNext: { (_) in
                self.viewModel.refresh()
            })
            .disposed(by: disposeBag)
    }
}

