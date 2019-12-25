//
//  WebsiteController.swift
//  App
//
//  Created by subash on 12/24/19.
//

import Foundation
import Vapor

struct WebsiteController: RouteCollection {

  func boot(router: Router) throws {
     router.get(use: indexHandler)
     router.get("droplets",Droplet.parameter, use: dropletHandler)
  }

  func indexHandler(_ req: Request) throws -> Future<View> {
    return Droplet.query(on: req).all()
        .flatMap(to: View.self) { droplets in
            let context = IndexContext(title: "Home Page",droplets: droplets.isEmpty ? nil : droplets)
            return try req.view().render("index",context)
    }
  }
    
   
    func dropletHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Droplet.self)
            .flatMap(to: View.self, { droplet in
                return droplet.user.get(on: req)
                    .flatMap(to: View.self) { user in
                        let context = DropletContext(title: droplet.name, droplet: droplet, user: user)
                        return try req.view().render("droplet", context)
                }
            })
    }
    
}

struct IndexContext: Encodable {
    let title: String
    let droplets: [Droplet]?
}

struct DropletContext: Encodable {
    let title: String
    let droplet: Droplet
    let user: User
}