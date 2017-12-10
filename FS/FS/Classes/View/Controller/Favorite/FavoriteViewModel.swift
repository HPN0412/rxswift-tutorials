//
//  FavoriteViewModel.swift
//  FS
//
//  Created by Quang Phu C. M. on 12/5/17.
//  Copyright © 2017 thinhxavi. All rights reserved.
//

import Foundation
import RxSwift
import MVVM
import RealmSwift

final class FavoriteViewModel: ViewModel {
    var venues: Variable<[Venue]> = Variable([])
    let bag = DisposeBag()
    var results: Results<Venue>!

    init() {
        fetchFavoriteVenues()
    }

    func fetchFavoriteVenues() {
        let pre = NSPredicate(format: "isFavorite = true")
        results = DatabaseManager.shared.objects(Venue.self, filter: pre)

        RealmObservable
            .collection(from: results)
            .subscribe({ [weak self] (event) in
                guard let this = self else { return }
                switch event {
                case .next(let element):
                    this.venues.value = element
                default: break
                }
        }).disposed(by: bag)
    }

    func viewModelForItem(at indexPath: IndexPath) -> VenueCellViewModel {
        guard indexPath.row >= 0 && indexPath.row < venues.value.count else { return VenueCellViewModel() }
        return VenueCellViewModel(venue: venues.value[indexPath.row])
    }
}
