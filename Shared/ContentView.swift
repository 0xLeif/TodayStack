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
    
    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha ?? 1)
    }
    
    var color: Color {
        Color(uiColor)
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
    
    var todo: String
    var foregroundColor: CodableColor
    var backgroundColor: CodableColor
}

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isDeletingAll = false
    @State private var isAdding = false
    @State private var newItemTodo: String = ""
    @State private var newItemForegroundColor: Color = .clear
    @State private var newItemBackgroundColor: Color = .clear
    
    @State private var items: [TodayItem] = []
    
    @State private var doneItems: [TodayItem] = []
    
    private var addButton: some View {
        VStack(spacing: 8) {
            // Add Button
            Button(action: {
                newItemForegroundColor = colorScheme == .dark ? .white : .black
                newItemBackgroundColor = colorScheme == .dark ? .black : .white
                isAdding = true
            }, label: {
                Text("Add Item")
                    
                    .frame(maxWidth: .infinity,
                           minHeight: 44, maxHeight: 44,
                           alignment: .center)
                    .background(Color.primary)
                    .cornerRadius(8)
                    .padding(4)
            })
        }
    }
    
    private var todayItems: some View {
        ForEach(items.sorted(by: { $0.epoch > $1.epoch }), id: \.self) { item in
            Button(action: {
                if let index = doneItems.firstIndex(where: { $0.id == item.id }) {
                    doneItems.remove(at: index)
                } else {
                    doneItems.append(item)
                }
            }, label: {
                Text(item.todo)
                    .padding()
                    .frame(maxWidth: .infinity,
                           minHeight: 44, maxHeight: 120,
                           alignment: .center)
                    .foregroundColor(doneItems.contains(item) ? Color.red : item.foregroundColor.color)
                    .background(doneItems.contains(item) ? Color.clear : item.backgroundColor.color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                style: StrokeStyle(
                                    lineWidth: 2,
                                    dash: [6]
                                )
                            )
                            .foregroundColor(doneItems.contains(item) ? Color.primary : Color.clear)
                    )
                    .cornerRadius(8)
                    .padding(4)
            })
            
        }
    }
    
    var body: some View {
        ScrollViewReader { scrollViewReader in
            ScrollView {
                VStack(spacing: 8) {
                    // Add Button
                    addButton
                    
                    // Items
                    todayItems
                }
                .padding()
                .toolbar {
                    Button(action: {
                        if let item = items.sorted(by: { $0.epoch > $1.epoch }).last {
                            scrollViewReader.scrollTo(item, anchor: .bottom)
                        }
                    }, label: {
                        Image(systemName: "arrow.down.circle")
                    })
                }
            }
            .navigationBarTitle("Today: \(items.count)")
            .onAppear {
                load()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                print("Application willResignActiveNotification")
                items.removeAll { (item) -> Bool in
                    doneItems.contains(item)
                }
                save()
            }
            .sheet(isPresented: $isAdding) {
                VStack {
                    HStack {
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
                    TextField("Todo", text: $newItemTodo)
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
