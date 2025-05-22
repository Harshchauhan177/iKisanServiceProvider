import SwiftUI
import Charts

struct MonthlyIncomeView: View {
    enum ChartType: String, CaseIterable {
        case line = "Line"
        case bar = "Bar"
        case pie = "Pie"
    }
    @EnvironmentObject var dataController: DataController
    @State private var selectedTimeframe: Timeframe = .month
    @State private var selectedMonth = Date()
    @State private var selectedChartType: ChartType = .line
    
    var totalIncome: Double {
        dataController.monthlyIncome.reduce(0) { $0 + $1.totalAmount }
    }
    
    var totalRequests: Int {
        dataController.monthlyIncome.reduce(0) { $0 + $1.completedRequests }
    }
    
    var averageDaily: Double {
        guard !dataController.monthlyIncome.isEmpty else { return 0 }
        return totalIncome / Double(dataController.monthlyIncome.count * 30)  // Approximate days per month
    }
    
    var successRate: Double {
        guard totalRequests > 0 else { return 0 }
        let completedRequests = dataController.monthlyIncome.reduce(0) { $0 + $1.completedRequests }
        return Double(completedRequests) / Double(totalRequests) * 100
    }
    
    var monthlyGrowth: Double {
        guard dataController.monthlyIncome.count >= 2 else { return 0 }
        let sortedIncome = dataController.monthlyIncome.sorted { $0.monthYear < $1.monthYear }
        let currentMonth = sortedIncome.last?.totalAmount ?? 0
        let previousMonth = sortedIncome.dropLast().last?.totalAmount ?? 0
        guard previousMonth > 0 else { return 0 }
        return ((currentMonth - previousMonth) / previousMonth) * 100
    }
    
    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    struct DailyIncome: Identifiable {
        let id = UUID()
        let date: Date
        let amount: Double
        let requestCount: Int
    }
    
    var dailyIncomeData: [DailyIncome] {
        let calendar = Calendar.current
        let now = Date()
        
        // Get the start date based on selected timeframe
        let startDate: Date
        switch selectedTimeframe {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        // Group requests by date and calculate daily totals
        var dailyData: [Date: (amount: Double, count: Int)] = [:]
        
        for income in dataController.monthlyIncome {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM"
            if let date = dateFormatter.date(from: income.monthYear) {
                dailyData[date] = (income.totalAmount, income.completedRequests)
            }
        }
        
        return dailyData.map { date, value in
            DailyIncome(date: date, amount: value.amount, requestCount: value.count)
        }.sorted { $0.date < $1.date }
    }
    
   
    
    var averageIncome: Double {
        guard !dailyIncomeData.isEmpty else { return 0 }
        return totalIncome / Double(dailyIncomeData.count)
    }
    
   
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        SummaryCard(title: "Total Income", value: String(format: "₹%.2f", totalIncome), color: .blue)
                        SummaryCard(title: "Average Daily", value: String(format: "₹%.2f", averageDaily), color: .green)
                        SummaryCard(title: "Total Requests", value: "\(totalRequests)", color: .orange)
                        SummaryCard(title: "Success Rate", value: String(format: "%.0f%%", successRate), color: .purple)
                        SummaryCard(title: "Growth", value: String(format: "%+.0f%%", monthlyGrowth), color: .green)
                        if let topEquipment = dataController.equipmentDetails.values.max(by: { $0.pricePerAcre < $1.pricePerAcre }) {
                            SummaryCard(title: "Top Equipment", value: topEquipment.name, color: .blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Time Range Selector
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(Timeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    if selectedTimeframe == .month {
                        DatePicker("Select Month",
                                 selection: $selectedMonth,
                                 displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                            .frame(maxHeight: 400)
                            .padding()
                    }
                    
                    // Chart Type Selector
                    Picker("Chart Type", selection: $selectedChartType) {
                        ForEach(ChartType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    // Income Charts
                    VStack(alignment: .leading) {
                        Text("Income Analysis")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        switch selectedChartType {
                        case .line:
                            Chart {
                                ForEach(dailyIncomeData) { data in
                                    LineMark(
                                        x: .value("Date", data.date),
                                        y: .value("Income", data.amount)
                                    )
                                    .foregroundStyle(.blue)
                                    
                                    AreaMark(
                                        x: .value("Date", data.date),
                                        y: .value("Income", data.amount)
                                    )
                                    .foregroundStyle(.blue.opacity(0.1))
                                }
                            }
                            .frame(height: 200)
                            .padding()
                            
                        case .bar:
                            Chart {
                                ForEach(dailyIncomeData) { data in
                                    BarMark(
                                        x: .value("Date", data.date),
                                        y: .value("Income", data.amount)
                                    )
                                    .foregroundStyle(.blue)
                                }
                            }
                            .frame(height: 200)
                            .padding()
                            
                        case .pie:
                            VStack(spacing: 20) {
                                // Equipment-wise Income Chart
                                Chart {
                                    ForEach(Array(dataController.equipmentDetails), id: \.key) { id, equipment in
                                        let amount = dataController.monthlyIncome
                                            .filter { income in
                                                let equipmentRequests = dataController.serviceRequests
                                                    .filter { $0.equipmentname == id }
                                                return !equipmentRequests.isEmpty
                                            }
                                            .reduce(0.0) { $0 + $1.totalAmount }
                                        
                                        if amount > 0 {
                                            SectorMark(
                                                angle: .value("Income", amount),
                                                innerRadius: .ratio(0.5),
                                                angularInset: 1.0
                                            )
                                            .foregroundStyle(by: .value("Equipment", equipment.name))
                                        }
                                    }
                                }
                                .frame(height: 200)
                                .padding()
                                
                                // Monthly Income Trend
                                VStack(alignment: .leading) {
                                    Text("Monthly Income Trend")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    Chart {
                                        ForEach(dataController.monthlyIncome.sorted(by: { $0.monthYear < $1.monthYear }), id: \.monthYear) { income in
                                            LineMark(
                                                x: .value("Month", income.monthYear),
                                                y: .value("Income", income.totalAmount)
                                            )
                                            .foregroundStyle(.green)
                                            .symbol(.circle)
                                        }
                                        ForEach(dataController.monthlyIncome.sorted(by: { $0.monthYear < $1.monthYear }), id: \.monthYear) { income in
                                            AreaMark(
                                                x: .value("Month", income.monthYear),
                                                y: .value("Income", income.totalAmount)
                                            )
                                            .foregroundStyle(.green.opacity(0.1))
                                        }
                                    }
                                    .frame(height: 150)
                                    .padding()
                                }
                            }
                        }
                        
                        // Equipment-wise Income
                        if selectedChartType == .pie {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Equipment-wise Income")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(Array(dataController.equipmentDetails), id: \.key) { id, equipment in
                                    let amount = dataController.monthlyIncome
                                        .filter { income in
                                            let equipmentRequests = dataController.serviceRequests
                                                .filter { $0.equipmentname == id }
                                            return !equipmentRequests.isEmpty
                                        }
                                        .reduce(0.0) { $0 + $1.totalAmount }
                                    
                                    let bookings = dataController.serviceRequests
                                        .filter { $0.equipmentname == id }
                                        .count
                                    
                                    if amount > 0 {
                                        HStack {
                                            Text(equipment.name)
                                                .font(.subheadline)
                                            Spacer()
                                            VStack(alignment: .trailing) {
                                                Text("₹\(String(format: "%.2f", amount))")
                                                    .font(.headline)
                                                Text("\(bookings) bookings")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding()
                                        .background(Color(.systemBackground))
                                        .cornerRadius(10)
                                        .shadow(radius: 1)
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Daily Breakdown
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Monthly Breakdown")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(dataController.monthlyIncome.sorted(by: { $0.monthYear > $1.monthYear }), id: \.monthYear) { income in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(income.monthYear)
                                        .font(.subheadline)
                                    Text("\(income.completedRequests) requests")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("₹\(String(format: "%.2f", income.totalAmount))")
                                    .font(.headline)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 1)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Income Analysis")
            .task {
                do {
                    try await dataController.fetchMonthlyIncome()
                } catch {
                    print("Error fetching monthly income: \(error)")
                }
            }
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .bold()
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

#Preview {
    MonthlyIncomeView()
        .environmentObject(DataController())
}
