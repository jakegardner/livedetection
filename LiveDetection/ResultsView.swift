//
//  ResultsView.swift
//  LiveDetection
//
//  Created by Jake on 3/10/20.
//  Copyright © 2020 Jake. All rights reserved.
//

import SwiftUI

struct Result: Identifiable {
    var id = UUID()
    var description: String
}

struct ResultRow: View {
    var result: Result

    var body: some View {
        Text("\(result.description)")
            .foregroundColor(.white)
    }
}

struct ResultsView: View {
    @Binding var predictions: Set<String>
    
    var body: some View {
        VStack {
            List(predictions.map { Result(description: $0) }) { prediction in
                ResultRow(result: prediction)
            }
        }
    }
}

struct ResultsView_Previews: PreviewProvider {
    static var previews: some View {
        ResultsView(predictions: .constant([]))
    }
}
