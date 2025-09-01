//
//  File.swift
//  
//
//  Created by Ben Schultz on 11/13/21.
//

import Foundation
import Vapor

enum LineParseError: Error {
    case expectedChildNotPresent
}


class LineParser {
    
    struct OnlineSpread: Codable, Content {
        var date: Date
        var awayTeamString: String
        var homeTeamString: String
        var spreadValue: Double
    }
    
    private let appConfig: AppConfig
    
    init(_ appConfig: AppConfig) async throws {
        self.appConfig = appConfig
    }
    
    private func dataFromSource(_ req: Request) async throws -> [APISpread.Entry] {
        let uri = URI(string: appConfig.linesUrl)
        var headers = HTTPHeaders([])
        headers.contentType = .json
        let response = try await req.client.get(uri, headers: headers).get()
        var logger = req.application.logger
        logger.logLevel = appConfig.loggerLogLevel
        logger.info("API requests used: \(response.headers["x-requests-used"])")
        let result = try response.content.decode([APISpread.Entry].self)
        return result
    }
    
    
    func parse(_ req: Request) async throws -> [LineParser.OnlineSpread] {
        var logger = req.application.logger
        logger.logLevel = appConfig.loggerLogLevel
        let sourceData = try await dataFromSource(req)
        
        logger.trace("\(sourceData)")
        
        var lines = [OnlineSpread]()
        
        for entry in sourceData {
            let home = entry.homeTeam
            let away = entry.awayTeam
            let kickoff = entry.commenceTime
            let details = entry.bookmakers.filter { $0.title == "DraftKings" }
                        
            if let detail = details.first,
               let market = detail.markets.first,
               let outcome1 = market.outcomes.first
            {
                var spreadValue = 0.0
                if outcome1.name == home {
                    spreadValue = -1 * outcome1.point
                }
                else {
                    spreadValue = outcome1.point
                }
                
                logger.trace("\(kickoff) \(away)  \(home)  \(spreadValue)")
                lines.append(OnlineSpread(date: kickoff, awayTeamString: away, homeTeamString: home, spreadValue: spreadValue))
            }
        }
        logger.debug("\(lines.count) succesfully parsed.")
        return lines
    }
    
}
