//
//  GithubClient.swift
//  Freetime
//
//  Created by Ryan Nystrom on 5/16/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import Foundation
import Alamofire

struct GithubClient {

    struct Request {
        let path: String
        let method: HTTPMethod
        let parameters: Parameters?
        let headers: HTTPHeaders?
        let completion: (DataResponse<Any>) -> Void

        init(
            path: String,
            method: HTTPMethod = .get,
            parameters: Parameters? = nil,
            headers: HTTPHeaders? = nil,
            completion: @escaping (DataResponse<Any>) -> Void
            ) {
            self.path = path
            self.method = method
            self.parameters = parameters
            self.headers = headers
            self.completion = completion
        }
    }

    let session: GithubSession
    let networker: Alamofire.SessionManager
    let authorization: Authorization?

    init(
        session: GithubSession,
        networker: Alamofire.SessionManager,
        authorization: Authorization? = nil
        ) {
        self.session = session
        self.networker = networker
        self.authorization = authorization
    }

    @discardableResult
    func request(
        _ request: GithubClient.Request
        ) -> DataRequest {
        print("Requesting: " + request.path)

        let encoding: ParameterEncoding
        switch request.method {
        case .get: encoding = URLEncoding.queryString
        default: encoding = JSONEncoding.default
        }

        var parameters = request.parameters ?? [:]
        if let authorization = authorization {
            parameters["access_token"] = authorization.token
        }

        return networker.request("https://api.github.com/" + request.path,
                                 method: request.method,
                                 parameters: parameters,
                                 encoding: encoding,
                                 headers: request.headers)
            .responseJSON(completionHandler: { response in
                print(response.response ?? "")
                print(response.value ?? response.error?.localizedDescription ?? "Unknown error")

                // remove the github session if requesting with a session
                if let authorization = self.authorization,
                    let statusCode = response.response?.statusCode,
                    (statusCode == 401 || statusCode == 403) {
                    self.session.remove(authorization: authorization)
                } else {
                    request.completion(response)
                }
            })
    }
    
}