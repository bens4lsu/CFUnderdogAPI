//
//  File.swift
//  CFUnderdogAPI
//
//  Created by Ben Schultz on 8/31/25.
//

import Foundation

actor CachedGameMatcherResponse: Sendable {
    let date: Date
    let responseAll: GameMatcher.GameMatcherResponseAll
    
    init(date: Date, gameMatcherResponse: GameMatcher.GameMatcherResponseAll) async {
        self.date = date
        self.responseAll = gameMatcherResponse
    }
}
