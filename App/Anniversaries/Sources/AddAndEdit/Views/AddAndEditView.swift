//
//  Created by クォン ジュンヒョク on 2023/05/27.
//

import AppUI
import ComposableArchitecture
import SwiftUI
import RemindScheduler
import CoreKit

private extension AddAndEdit.State.Mode {
    var title: String {
        switch self {
        case .new:
            return #localized("New")
        case .edit:
            return #localized("Edit")
        }
    }

    var completeTitle: String {
        switch self {
        case .new:
            return #localized("Add")
        case .edit:
            return #localized("Done")
        }
    }
}

private extension AnniversaryKind {
    var title: String {
        switch self {
        case .birth:
            return #localized("Birthday")
        case .marriage:
            return #localized("Marriage Anniversary")
        case .death:
            return #localized("Death Anniversary")
        case .others:
            return #localized("Others")
        }
    }
}

public struct AddAndEditView: View {
/*
 TODO
 Swift Data(separate branch)
 Make Name Compulsary
 */

    public init(store: StoreOf<AddAndEdit>) {
        self.store = store
    }

    private var store: StoreOf<AddAndEdit>

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
                Form {
                    Section {
                        Picker(#localized("Kind"), selection: viewStore.$selectedKind) {
                            ForEach(AnniversaryKind.allCases, id: \.self) { kind in
                                Text(kind.title).tag(kind)
                            }
                        }
                        if case .others = viewStore.selectedKind {
                            TextField(#localized("Title"), text: viewStore.$othersTitle)
                        }
                    }
                    Section {
                        TextField(#localized("Name"), text: viewStore.$name)
                        DatePicker(
                            #localized("Date"),
                            selection: viewStore.$date,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                    }
                    Section {
                        LabeledContent(#localized("Remind")) {
                            Button {
                                viewStore.send(.addRemindButtonTapped)
                                // +タップしたらモーダルでDateとTimeとRepeatを決める画面を表示する
                                // 全てToggleでOn/OffできるようにしてDefaultはDateはOn、TimeはOff
                                // RepeatはDefaultはOnで下に毎年リマインドすることを案内し
                                // 次リマインドする年月日を表示する
                                // 全体的にRemindアプリを参考する
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                        
                        ForEach(viewStore.reminds, id: \.self) { remind in
                            Text(remind.date.formatted())
                                .padding(.leading, 8)
                        }
                        .onDelete { indexSet in
                            viewStore.send(.deleteRemind(indexSet))
                        }
                    }
                    Section {
                        TextField(#localized("Memo"), text: viewStore.$memo)
                            .frame(height: 100, alignment: .top)
                    }
                }
                .navigationTitle(viewStore.mode.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(#localized("Cancel")) {
                            viewStore.send(.cancelButtonTapped)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(viewStore.mode.completeTitle) {
                            viewStore.send(.completeButtonTapped)
                        }
                    }
                }
                .sheet(
                    store: store.scope(state: \.$destination, action: AddAndEdit.Action.destination),
                    state: /Destination.State.remind,
                    action: Destination.Action.remind,
                    content: RemindSchedulerView.init(store:)
                )
                .alert(
                    store: store.scope(state: \.$destination, action: AddAndEdit.Action.destination),
                    state: /Destination.State.alert,
                    action: Destination.Action.alert
                )
            }
        }
    }
}

struct AnniversaryView_Previews: PreviewProvider {
    static var previews: some View {
        AddAndEditView(store: .init(initialState: .init(mode: .new), reducer: AddAndEdit.init))
            .previewDisplayName("New")
        AddAndEditView(store: .init(initialState: .init(mode: .edit), reducer: AddAndEdit.init))
            .previewDisplayName("Edit")
    }
}
