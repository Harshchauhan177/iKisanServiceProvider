let sortedRequests = dataController.serviceRequests
    .filter { request in
        // Filter for today's requests
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let requestDate = formatter.date(from: String(request.date.prefix(10))) ?? Date()
        return Calendar.current.isDateInToday(requestDate)
    }