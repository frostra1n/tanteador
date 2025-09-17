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
        guard let url = URL(string: AppConfig.API.exchangeRateURL) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data()

        let (data, response) = try await URLSession.shared.data(for: request)
        return try parseResponse(data: data, response: response)
    }

    func fetchUserLocation() async throws -> IPLocation {
        guard let url = URL(string: AppConfig.API.ipLocationURL) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        return try parseResponse(data: data, response: response)
    }

    private func parseResponse<T: Decodable>(data: Data, response: URLResponse) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
}
