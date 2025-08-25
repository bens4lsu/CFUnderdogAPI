import Fluent
import Vapor

func routes(_ app: Application, _ appConfig: AppConfig, teamList: [Team]) throws {
    app.get { req in
        return "It works!"
    }

    

    app.get("getLines") { req async throws-> Response in
        var response: GameMatcher.GameMatcherResponseAll
        do {
            struct PoolUserEntryContent: Content {
                var poolUserEntryId: String?
            }
            
            // try several times to get succesful lines
            var retryCount = 0
            var lines = try? await LineParser(appConfig).parse(req)
            while retryCount < appConfig.retryCount && lines == nil {
                retryCount += 1
                if retryCount < appConfig.retryCount {
                    lines = try? await LineParser(appConfig).parse(req)
                }
                else {      // last chance, let the error throw
                    lines = try await LineParser(appConfig).parse(req)
                }
            }

            let week = try await currentWeek(req)

            var gameMatcherResponse = try await GameMatcher(teamList: teamList).load(req, appConfig: appConfig, lines: lines!, week: week)
            if let poolUserParamContent = try? req.query.decode(PoolUserEntryContent.self),
               let poolUserParamStr = poolUserParamContent.poolUserEntryId,
               let poolUserParam = Int(poolUserParamStr)
            {
                gameMatcherResponse = try await gameMatcherResponse.exceptPickFor(req, user: poolUserParam, week: week)
            }
            response = gameMatcherResponse
        }
        catch(let e) {
            let message = Logger.Message(stringLiteral: e.localizedDescription)
            app.logger.error(message)
            response = GameMatcher.GameMatcherResponseAll(games: [], teamNameMatchErrors: [], error: e.localizedDescription)
        }
        return try await response.encodeResponse(for: req)
    }
    
    app.get("testLines") { req async throws -> Response in
        try await LineParser(appConfig).parse(req).encodeResponse(for: req)
    }
    
    app.post("newMessage") { req async throws -> Response in
        struct NewMessagePost: Codable {
            var user: Int
            var message: String
            var messageParent: Int
            var poolId: Int
        }
        
        let newMessage = try req.content.decode(NewMessagePost.self)
        let poolMessage = PoolMessage(poolId: newMessage.poolId, parentPoolMessageId: newMessage.messageParent, message: newMessage.message, enteredBy: newMessage.user)
        try await poolMessage.save(on: req.db)
        return try await "ok".encodeResponse(for: req)
    }
    
    
    
    @Sendable func currentWeek(_ req: Request) async throws -> Week {
        guard let week = try await Week.query(on: req.db)
                                        .filter(\.$weekDateStart < Date())
                                        .filter(\.$weekDateEnd >= Date())
                                        .sort(\.$weekDateEnd)
                                        .first()
        else {
            throw Abort(.internalServerError, reason: "No weeks configured that correspond to the current date.")
        }
        return week
    }

}
