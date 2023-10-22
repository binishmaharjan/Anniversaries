//
//  Created by Maharjan Binish on 2023/03/05.
//

import AddAndEdit
import AppUI
import ComposableArchitecture
import CoreKit
import Foundation
import SwiftDataClient
import UserDefaultsClient

public struct Home: Reducer {
    public struct State: Equatable {
        public init() {}

        @PresentationState var destination: Destination.State?
        var anniversaries: [Anniversary] = []
        var currentSort: Sort.Kind = .defaultDate
        var currentSortOrder: Sort.Order = .newest
    }

    public enum Action: Equatable {
        public enum Delegate: Equatable {
        }

        case destination(PresentationAction<Destination.Action>)
        case onAppear
        case fetchAnniversaries
        case anniversariesResponse(TaskResult<[Anniversary]>)
        case editButtonTapped
        case sortByButtonTapped(Sort.Kind)
        case sortOrderButtonTapped(Sort.Order)
        case addButtonTapped
        case delegate(Delegate)
    }

    public init() {}

    @Dependency(\.userDefaultsClient) private var userDefaultClient
    @Dependency(\.anniversaryDataClient) private var anniversaryDataClient

    public var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                state.currentSort = userDefaultClient.currentAnniversariesSort()
                state.currentSortOrder = userDefaultClient.currentAnniversariesSortOrder()

                return .send(.fetchAnniversaries)

            case .fetchAnniversaries:
                return .run { send in
                    await send(
                        .anniversariesResponse(
                            TaskResult {
                                try anniversaryDataClient.fetch()
                            }
                        )
                    )
                }

            case .anniversariesResponse(.success(let anniversaries)):
                state.anniversaries = anniversaries

            case .anniversariesResponse(.failure(let error)):
                assertionFailure(error.localizedDescription)
                state.destination = .alert(
                    AlertState(title: TextState(#localized("Failed to load data")))
                )

            case .editButtonTapped:
                break

            case .sortByButtonTapped(let sort):
                // TODO: Perform Sort Logic
                state.currentSort = sort
                userDefaultClient.setCurrentAnniversariesSort(sort)

            case .sortOrderButtonTapped(let sortOrder):
                // TODO: Perform Sort Logic
                state.currentSortOrder = sortOrder
                userDefaultClient.setCurrentAnniversariesSortOrder(sortOrder)

            case .addButtonTapped:
                state.destination = .anniversary(.init(mode: .new))

            case .destination(.presented(.anniversary(.saveAnniversaries(.success)))):
                return .send(.fetchAnniversaries)

            case .destination:
                break
            }
            return .none
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
    }
}

// MARK: Destination
extension Home {
    public struct Destination: Reducer {
        public enum State: Equatable {
            case anniversary(AddAndEdit.State)
            case alert(AlertState<Action.Alert>)
        }

        public enum Action: Equatable {
            public enum Alert: Equatable {
            }
            case anniversary(AddAndEdit.Action)
            case alert(Alert)
        }

        public var body: some ReducerOf<Self> {
            Scope(state: /State.anniversary, action: /Action.anniversary, child: AddAndEdit.init)
        }
    }
}
