//
//  ErrorView.swift
//  Tanteador
//
//  Created by Marco Carmona on 9/17/25.
//

import SwiftUI

struct ErrorView: View {
    var body: some View {
        VStack {
            Text("Could not load the exchange rate, please try again later.")
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    ErrorView()
}
