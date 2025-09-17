//
//  NetworkManager.swift
//  Tanteador
//
//  Created on 9/10/25.
//

import Foundation

struct CurrencyRate: Codable {
    let countryCode: String
    let currencyCode: String
    let buy: Double
    let sell: Double
}

typealias ExchangeRateResponse = [String: [CurrencyRate]]

struct IPLocation: Codable {
    let country: String
    let countryCode: String
    let city: String?
    let region: String?
    let ip: String
}

class NetworkManager {
    static let shared = NetworkManager()
    
    private init() {}
    
    func fetchExchangeRate() async throws -> ExchangeRateResponse {
        let url = URL(string: "https://www.sucursalelectronica.com/ebac/common/GetExchangeRateInfo.go")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set headers
        request.setValue("application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue("empty", forHTTPHeaderField: "Sec-Fetch-Dest")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("same-origin", forHTTPHeaderField: "Sec-Fetch-Site")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("cors", forHTTPHeaderField: "Sec-Fetch-Mode")
        request.setValue("https://www.sucursalelectronica.com", forHTTPHeaderField: "Origin")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("https://www.sucursalelectronica.com/redir/showLogin.go", forHTTPHeaderField: "Referer")
        request.setValue("0", forHTTPHeaderField: "Content-Length")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue("u=3, i", forHTTPHeaderField: "Priority")
        
        // Empty body for POST request
        request.httpBody = Data()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ExchangeRateResponse.self, from: data)
    }
    
    func fetchUserLocation() async throws -> IPLocation {
        let url = URL(string: "https://ipapi.co/json/")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(IPLocation.self, from: data)
    }
}
