import SwiftUI

// Persistent Manager for Water Records
class WaterRecordsManager: ObservableObject {
    private let defaults = UserDefaults.standard
    private let key = "waterRecords"

    func getRecords() -> [String: Int] {
        if let data = defaults.data(forKey: key),
           let records = try? JSONDecoder().decode([String: Int].self, from: data) {
            return records
        }
        return [:]
    }

    func saveRecords(_ records: [String: Int]) {
        if let data = try? JSONEncoder().encode(records) {
            defaults.set(data, forKey: key)
        }
    }
}

struct ContentView: View {
    @AppStorage("dailyGoalOz") private var dailyGoal: Int = 64 // Default daily goal in ounces
    @StateObject private var recordsManager = WaterRecordsManager()
    @State private var waterRecords: [String: Int] = [:] // Records by date
    @State private var waterIntake: Int = 0 // Water intake in ounces
    @State private var addAmount: Int = 8 // Default add amount in ounces
    @State private var showCongratulations: Bool = false // State for showing the alert
    @State private var selectedDate: Date = Date() // Selected date in calendar view

    var progress: Double {
        min(Double(waterIntake) / Double(dailyGoal), 1.0)
    }

    var body: some View {
        TabView {
            NavigationStack {
                ScrollView { // Added ScrollView to allow scrolling
                    VStack(spacing: 20) {
                        Text("Thirsty?")
                            .font(.largeTitle)
                            .bold()
                            .padding(.top, 0)
                        
                        Text("\(formattedDate(selectedDate))")
                            .font(.headline)
                            .padding(.top, 0)

                        ZStack {
                            // Background Teardrop Shape Outline
                            TeardropShape()
                                .stroke(Color.blue.opacity(0.3), lineWidth: 8)
                                .frame(width: 200, height: 300)

                            // Progress Fill
                            TeardropShape()
                                .fill(Color.blue.opacity(0.6))
                                .frame(width: 200, height: 300)
                                .mask(
                                    Rectangle()
                                        .frame(height: 300 * progress) // Scale height based on progress
                                        .offset(y: (1 - progress) * 150) // Offset to maintain bottom-up fill
                                )
                                .animation(.linear(duration: 0.4), value: progress)

                            // Text for Progress
                            VStack {
                                Text("\(waterIntake) / \(dailyGoal) oz")
                                    .font(.title)
                                Text("\(Int(progress * 100))%")
                                    .font(.headline)
                                    .foregroundColor(.black)
                            }
                        }
                        .padding(.top, 20)
                        
                        HStack {
                            Stepper("Add: \(addAmount) oz", value: $addAmount, in: 1...32, step: 1)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)
                        }

                        // Log Water Button
                        Button(action: logWaterIntake) {
                            Text("Log Water (\(addAmount) oz)")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.vertical, 5)

                        // Reset Button
                        Button(action: resetDailyIntake) {
                            Text("Reset for New Day")
                                .foregroundColor(.red)
                        }
                        .padding(.vertical, 5)

                        // Set Goal
                        VStack {
                            Text("Set Daily Goal")
                                .font(.headline)
                            Stepper("Goal: \(dailyGoal) oz", value: $dailyGoal, in: 8...200, step: 1)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)
                        }
                        .padding(.vertical, 10)

                        Spacer() // This spacer ensures content remains at the bottom of the screen
                    }
                    .padding()
                    .onAppear {
                        waterRecords = recordsManager.getRecords()
                        loadWaterIntake()
                    }
                    .alert("Congratulations!", isPresented: $showCongratulations) {
                        Button("OK", role: .cancel) {
                            showCongratulations = false // Reset the alert state
                        }
                    } message: {
                        Text("You've reached your daily water intake goal!")
                    }
                }
                .navigationBarTitle("Water Log", displayMode: .inline) // Optional title
            }
            .tabItem {
                Label("Log", systemImage: "book.fill")
            }

            // Calendar View
            CalendarTab(selectedDate: $selectedDate, waterRecords: waterRecords)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
        }
    }

    // MARK: Helper Functions
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func loadWaterIntake() {
        let dateKey = formattedDate(selectedDate)
        waterIntake = waterRecords[dateKey] ?? 0
    }

    private func logWaterIntake() {
        waterIntake += addAmount
        if waterIntake >= dailyGoal {
            showCongratulations = true
            waterIntake = dailyGoal
        }
        saveWaterIntake()
    }

    private func saveWaterIntake() {
        let dateKey = formattedDate(selectedDate)
        waterRecords[dateKey] = waterIntake
        recordsManager.saveRecords(waterRecords)
    }

    private func resetDailyIntake() {
        saveWaterIntake() // Save current progress
        waterIntake = 0
    }
}

private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

struct TeardropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let center = CGPoint(x: rect.midX, y: rect.midY)
        // Start at the top of the drop
        path.move(to: CGPoint(x: center.x, y: rect.minY))
        // Draw the left curve with adjusted control points for flatter bottom
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + width * 0.25, y: rect.maxY - height * 0.1), // Flatter
            control: CGPoint(x: rect.minX - width * 0.3, y: rect.maxY * 0.4)
        )
        // Create a flatter bottom
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - width * 0.25, y: rect.maxY - height * 0.1), // Flatter
            control: CGPoint(x: center.x, y: rect.maxY + height * 0.05) // Lower apex for flatter curve
        )
        // Draw the right curve back to the top
        path.addQuadCurve(
            to: CGPoint(x: center.x, y: rect.minY),
            control: CGPoint(x: rect.maxX + width * 0.3, y: rect.maxY * 0.4)
        )
        return path
    }
}

// Preview for Xcode Canvas
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewDevice("iPhone SE (3rd generation)")
                .previewDisplayName("iPhone SE Portrait")
                .preferredColorScheme(.light)

            ContentView()
                .previewDevice("iPhone 14")
                .previewDisplayName("iPhone 14 Landscape")
                .previewInterfaceOrientation(.landscapeLeft)
           
            ContentView()
                .previewDevice("iPhone 14")
                .previewDisplayName("iPhone 14 Portrait")
                .previewInterfaceOrientation(.portrait)

            ContentView()
                .previewDevice("iPad Pro (12.9-inch) (6th generation)")
                .previewDisplayName("iPad Pro Portrait")
            ContentView()
                .previewDevice("iPad Pro (12.9-inch) (6th generation)")
                .previewDisplayName("iPad Pro Landscape")
                .previewInterfaceOrientation(.landscapeLeft)
        }
    }
}

@main
struct WaterTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
