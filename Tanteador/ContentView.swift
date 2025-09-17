//
//  ContentView.swift
//  Tanteador
//
//  Created by Marco Carmona on 9/5/25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedRate: Double = 0.0
    @State private var isLoading = true
    @State private var shouldShowError = false
    @State private var showCopiedPriceAlert = false
    @State private var rawArticlePrice = ""
    
    var convertedPrice: String {
        let articlePrice = Double(rawArticlePrice) ?? 0.0
        let converted = calculateUSDAmount(articleCost: articlePrice, exchangeRate: selectedRate)
        
        return String(converted)
    }
    
    enum RateLoadingError: Error {
        case dollarUnavailableInResponse
        case rateNotFound
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView()
            } else if shouldShowError {
                ErrorView()
            } else {
                HStack {
                    Text("₡")
                        .bold()
                    
                    TextField("Enter your amount...", text: $rawArticlePrice)
                        .keyboardType(.decimalPad)
                }
                
                if convertedPrice != "0.0" {
                    Text("$\(convertedPrice)")
                        .bold()
                
                    Button("Copy") {
                        UIPasteboard.general.string = convertedPrice
                        showCopiedPriceAlert = true
                    }
                    .alert(isPresented: $showCopiedPriceAlert) {
                        .init(title: Text("Copied!"))
                    }
                }
            }
        }
        .task {
            defer { isLoading = false }
            
            if !shouldReloadRate() {
                selectedRate = UserDefaults.standard.double(forKey: "lastSelectedRate")
                return
            }
            
            do {
                let countryCode = try await loadCountryFromCurrentIP()

                selectedRate = try await loadRates(countryCode: countryCode)
                upsertLastFetching()
            } catch {
                print("could not fetch required data: \(error.localizedDescription)")
            }
        }
        .padding(100)
    }
    
    private func shouldReloadRate() -> Bool {
        let formatter = DateFormatter()

        guard let rawDate = UserDefaults.standard.string(forKey: "lastFetchedDate") else {
            // No date stored, should reload
            return true
        }
        
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        
        guard let lastFetchedDate = formatter.date(from: rawDate) else {
            // Could not parse date, should reload
            return true
        }
        
        print("Should use the cached rate from: \(lastFetchedDate)")
        
        return !Calendar.current.isDate(lastFetchedDate, inSameDayAs: Date.now)
    }
    
    private func upsertLastFetching() {
        let formattedDate = Date.now.formatted(date: .numeric, time: .omitted)
        
        UserDefaults.standard.set(selectedRate, forKey: "lastSelectedRate")
        UserDefaults.standard.set(formattedDate, forKey: "lastFetchedDate")
    }
    
    private func loadCountryFromCurrentIP() async throws -> String {
        let location = try await NetworkManager.shared.fetchUserLocation()
        
        return location.countryCode
    }
    
    private func loadRates(countryCode: String) async throws -> Double {
        let loadedRates = try await NetworkManager.shared.fetchExchangeRate()
        var selectedRate: CurrencyRate?
        
        guard let dollarRates = loadedRates["USD"] else {
            throw RateLoadingError.dollarUnavailableInResponse
        }
        
        selectedRate = dollarRates.first { $0.countryCode == countryCode }
        
        guard let selectedRate else {
            throw RateLoadingError.rateNotFound
        }
        
        return selectedRate.buy
    }
    
    private func calculateUSDAmount(articleCost: Double, exchangeRate: Double) -> Double {
        let rawUSD = articleCost / exchangeRate
        var usdAmount = ceil(rawUSD * 100) / 100
        let reversedAmount = usdAmount * exchangeRate
        
        // If due to floating point precision we're still under, add one cent
        if reversedAmount < articleCost {
            usdAmount += 0.01
        }
        
        return usdAmount
    }
}
