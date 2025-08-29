//
//  File.swift
//  CFUnderdogAPI
//
//  Created by Ben Schultz on 8/28/25.
//

import Foundation

struct APISpread: Decodable {
    
    struct Entry: Decodable {
        let id: String
        let sportKey: String
        let sportTitle: String
        let commenceTime: Date
        let homeTeam: String
        let awayTeam: String
        let bookmakers: [Bookmaker]
        
        enum CodingKeys: String, CodingKey {
            case id
            case sportKey = "sport_key"
            case sportTitle = "sport_title"
            case commenceTime = "commence_time"
            case homeTeam = "home_team"
            case awayTeam = "away_team"
            case bookmakers
        }
    }
    
    struct Bookmaker: Decodable {
        let key: String
        let title: String
        let lastUpdate: Date
        let markets: [Market]
        
        enum CodingKeys: String, CodingKey {
            case key, title, markets
            case lastUpdate = "last_update"
        }
    }
    
    struct Market: Decodable {
        let key: String
        let lastUpdate: Date
        let outcomes: [Outcome]
        
        enum CodingKeys: String, CodingKey {
            case key, outcomes
            case lastUpdate = "last_update"
        }
    }
    
    struct Outcome: Decodable {
        let name: String
        let price: Double
        let point: Double
    }
    
}
