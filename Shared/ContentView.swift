//
//  ContentView.swift
//  Shared
//
//  Created by Leif on 2/28/21.
//

import SwiftUI

struct CodableColor: Codable, Hashable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat?
    
    var cgColor: CGColor {
        CGColor(red: red, green: green, blue: blue, alpha: alpha ?? 1)
    }
    
    var color: Color {
        Color(cgColor)
    }
    
    init(color: Color) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

struct TodayItem: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var epoch: Date = Date()
    var completionEpoch: Date?
    
    var todo: String
    var foregroundColor: CodableColor
    var backgroundColor: CodableColor
}

extension TodayItem {
    static func item(
        title: String,
        epochOffset: TimeInterval,
        completionEpochOffset: TimeInterval?
    ) -> TodayItem {
        TodayItem(
            id: UUID(),
            epoch: Date().addingTimeInterval(epochOffset),
            completionEpoch: completionEpochOffset.map { Date().addingTimeInterval($0) },
            todo: title,
            foregroundColor: .init(color: .black),
            backgroundColor: .init(color: .white)
        )
    }
}

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isShowingRollup = false
    @State private var isAdding = false
    @State private var newItemTodo: String = ""
    @State private var newItemForegroundColor: Color = .clear
    @State private var newItemBackgroundColor: Color = .clear
    
    @State private var items: [TodayItem] = {
        let uncompleted: [TodayItem] = stride(from: 1, to: 10, by: 1).map { day in
            .item(title: "New", epochOffset: 60 * 60 * 24 * day, completionEpochOffset: nil)
        }
        let completed: [TodayItem] = stride(from: 1, to: 10, by: 1).map { day in
            .item(title: "Completed", epochOffset: 60 * 60 * 24 * day, completionEpochOffset: 60 * 60 * 30 * -1)
        }
        let completedOld: [TodayItem] = stride(from: 1, to: 100, by: 1).map { day in
            .item(title: "Old", epochOffset: 60 * 60 * 24 * day, completionEpochOffset: 60 * 60 * 30 * -10)
        }
        
        return completed + uncompleted + completedOld
    }()
    
    private let oneDay: TimeInterval = 60 * 60 * 24
    private var itemsByDays: [Int: [TodayItem]] {
        items.sorted(by: { $0.epoch > $1.epoch })
            .reduce([Int: [TodayItem]]()) { (itemsByDays, item) in
                var items = itemsByDays
                let numberOfDaysAgo = Int(abs(Date().timeIntervalSince1970 - item.epoch.timeIntervalSince1970) / oneDay)
                guard var itemsForDay = items[numberOfDaysAgo] else {
                    items[numberOfDaysAgo] = [item]
                    return items
                }
                itemsForDay.append(item)
                items[numberOfDaysAgo] = itemsForDay
                return items
            }
    }
    private func itemsCompleted(from: Date, to: Date) -> [TodayItem] {
        itemsByDays.flatMap { _, items in
            items.filter { item in
                guard let completionEpoch = item.completionEpoch else {
                    return false
                }
                
                return from.timeIntervalSince1970 < completionEpoch.timeIntervalSince1970 && completionEpoch.timeIntervalSince1970 < to.timeIntervalSince1970
            }
        }
    }
    
    private var addButton: some View {
        Button(
            action: {
                newItemForegroundColor = colorScheme == .dark ? .white : .black
                newItemBackgroundColor = colorScheme == .dark ? .black : .white
                isAdding = true
            },
            label: {
                Label("Add Item", systemImage: "plus")
                    .font(.title3)
                    .frame(maxWidth: .infinity,
                           minHeight: 44, maxHeight: 44,
                           alignment: .center)
                    .foregroundColor(colorScheme == .dark ? .blue : .white)
                    .background(colorScheme == .dark ? Color.white : Color.blue)
                    .cornerRadius(8)
                    .padding(4)
            }
        )
    }
    
    private func all(items: [Int : [TodayItem]]) -> some View {
        return ForEach(items.keys.sorted(by: <), id: \.self) { daysAgo in
            if let dayItems = items[daysAgo] {
                if daysAgo == 0 {
                    ForEach(dayItems, id: \.self) { item in
                        itemView(item: item)
                    }
                } else {
                    Section(header: Text("\(daysAgo) \(daysAgo == 1 ? "Day" : "Days") ago: \(dayItems.count)")) {
                        ForEach(dayItems, id: \.self) { item in
                            itemView(item: item)
                        }
                    }
                }
            }
        }
    }
    
    private func itemView(item: TodayItem) -> some View {
        Button(
            action: {
                guard let index = items.firstIndex(where: { $0.id == item.id }) else {
                    return
                }
                if item.completionEpoch != nil {
                    items[index].completionEpoch = nil
                } else {
                    items[index].completionEpoch = Date()
                }
            },
            label: {
                Text(item.todo)
                    .padding()
                    .frame(maxWidth: .infinity,
                           minHeight: 44, maxHeight: 120,
                           alignment: .center)
                    .foregroundColor((item.completionEpoch != nil) ? Color.red : item.foregroundColor.color)
                    .background((item.completionEpoch != nil) ? Color.clear : item.backgroundColor.color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                style: StrokeStyle(
                                    lineWidth: 2,
                                    dash: [6]
                                )
                            )
                            .foregroundColor((item.completionEpoch != nil) ? Color.primary : Color.clear)
                    )
                    .cornerRadius(8)
                    .padding(4)
            }
        )
    }
    
    var body: some View {
        let itemsByDays = self.itemsByDays
        
        return List {
            addButton
            all(items: itemsByDays)
        }
        .listStyle(PlainListStyle())
        .navigationBarTitle("Today: \(itemsByDays[0]?.count ?? 0)")
        .toolbar {
            Button(
                action: {
                    isShowingRollup = true
                },
                label: {
                    Image(systemName: "scroll")
                }
            )
            .sheet(isPresented: $isShowingRollup) {
                List {
                    Text("Today: \(itemsCompleted(from: Date().addingTimeInterval(-oneDay), to: Date()).count)").font(.largeTitle)
                    all(items: [
                        0: itemsCompleted(from: Date().addingTimeInterval(-oneDay), to: Date()),
                        1: itemsCompleted(from: Date().addingTimeInterval(-oneDay * 2), to: Date().addingTimeInterval(-oneDay))
                    ])
                    .disabled(true)
                }
            }
        }
        //        .onAppear {
        //            load()
        //        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            print("Application willResignActiveNotification")
            items.removeAll { (item) -> Bool in
                guard let completionEpoch = item.completionEpoch else {
                    return false
                }
                
                return completionEpoch.timeIntervalSince1970 < Date().addingTimeInterval(60 * 60 * 24 * -2).timeIntervalSince1970
            }
            save()
        }
        .sheet(isPresented: $isAdding) {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Button("Cancel") {
                            isAdding = false
                            newItemTodo = ""
                            newItemForegroundColor = colorScheme == .dark ? .white : .black
                            newItemBackgroundColor = colorScheme == .dark ? .black : .white
                        }
                        Spacer()
                        Button("Add") {
                            guard !newItemTodo.isEmpty else {
                                return
                            }
                            
                            items.append(
                                TodayItem(
                                    todo: newItemTodo,
                                    foregroundColor: CodableColor(color: newItemForegroundColor),
                                    backgroundColor: CodableColor(color: newItemBackgroundColor)
                                )
                            )
                            isAdding = false
                            
                            newItemTodo = ""
                            newItemForegroundColor = colorScheme == .dark ? .white : .black
                            newItemBackgroundColor = colorScheme == .dark ? .black : .white
                        }
                        .padding()
                    }
                    TextEditor(text: $newItemTodo)
                        .padding()
                        .frame(height: 120, alignment: .center)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    style: StrokeStyle(
                                        lineWidth: 2,
                                        dash: [6]
                                    )
                                )
                                .foregroundColor(Color.blue)
                        )
                        .cornerRadius(8)
                    ColorPicker("Foreground Color", selection: $newItemForegroundColor)
                    ColorPicker("Background Color", selection: $newItemBackgroundColor)
                    Spacer()
                }
                .padding()
            }
        }
    }
    
    private func save() {
        DispatchQueue.main.async {
            if let data = try? JSONEncoder().encode(items) {
                UserDefaults.standard.set(data, forKey: "TodayItems")
            }
        }
    }
    
    private func load() {
        DispatchQueue.main.async {
            if let data = UserDefaults.standard.data(forKey: "TodayItems"),
               let items = try? JSONDecoder().decode([TodayItem].self, from: data) {
                self.items = items
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
