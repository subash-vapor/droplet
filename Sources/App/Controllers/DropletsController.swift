import Foundation
import Vapor
import Authentication

struct DropletsController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let dropletRoute = router.grouped("api","droplets")
        
        let tokenAuthMiddleWare = User.tokenAuthMiddleware()
        let guardAuthMiddleWare = User.guardAuthMiddleware()
        let tokenProtectedRoute = dropletRoute.grouped(tokenAuthMiddleWare,guardAuthMiddleWare)
        
        dropletRoute.get(use: getAllHandler)
        dropletRoute.get(Droplet.parameter, use: getHandler)
        tokenProtectedRoute.post(DropletCreateData.self,use: createHandler)
        tokenProtectedRoute.put(Droplet.parameter, use: updateHandler)
        tokenProtectedRoute.delete(Droplet.parameter, use: deleteHandler)
        dropletRoute.get("sorted", use: sortHandler)
        
        dropletRoute.get(Droplet.parameter,"user",use: getUserHandler)
        tokenProtectedRoute.post(Droplet.parameter,"categories",Category.parameter, use: addCategoriesHandler)
        dropletRoute.get(Droplet.parameter,"categories",use: getCategoriesHandler)
        tokenProtectedRoute.delete(Droplet.parameter,"categories",Category.parameter, use: removeCategoriesHandler)
        
    }
    
    //Get: all
    func getAllHandler(_ request: Request) throws -> Future<[Droplet]> {
        return Droplet.query(on: request).all()
    }
    
    //Get: specific droplet
    func getHandler(_ request: Request) throws -> Future<Droplet> {
        try request.parameters.next(Droplet.self)
    }
    
    //Post: droplet
    func createHandler(_ request: Request, data: DropletCreateData) throws -> Future<Droplet> {
        let user = try request.requireAuthenticated(User.self)
        let droplet = try Droplet(name: data.name, userId: user.requireID())
        return droplet.save(on: request)
    }
    
    //Put: Update a droplet
    func updateHandler(_ request: Request) throws -> Future<Droplet> {
        try flatMap(to: Droplet.self,
                    request.parameters.next(Droplet.self),
                    request.content.decode(DropletCreateData.self)) { (droplet, updatedDroplet)  in
                        droplet.name = updatedDroplet.name
                        let user = try request.requireAuthenticated(User.self)
                        droplet.userId = try user.requireID()
                        return droplet.save(on: request)
        }
    }
    
    ///Delete: specific droplet
    func deleteHandler(_ request: Request) throws -> Future<HTTPStatus> {
        try request.parameters.next(Droplet.self).delete(on: request).transform(to: .noContent)
    }
    
    //Sort
    func sortHandler(_ request: Request) throws -> Future<[Droplet]> {
        return Droplet.query(on: request)
                   .sort(\.name, ._ascending)
                   .all()
    }
    
    //Get associated User
    func getUserHandler(_ request: Request) throws -> Future<User.Public> {
        try request.parameters.next(Droplet.self)
            .flatMap(to: User.Public.self) { droplet in
                droplet.user.get(on: request).Public
        }
    }
    
    func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self,
                           req.parameters.next(Droplet.self),
                           req.parameters.next(Category.self), { (droplet, category) in
                            return droplet.categories.attach(category, on: req)
                                .transform(to: .created)
        })
    }

    func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
        return try req.parameters.next(Droplet.self)
            .flatMap(to: [Category].self){ droplet in
                try droplet.categories.query(on: req).all()
            }
    }
    
    func removeCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self,
                                req.parameters.next(Droplet.self),
                                req.parameters.next(Category.self), { (droplet, category) in
                                 return droplet.categories.detach(category, on: req)
                                     .transform(to: .created)
             })
    }
    
}

struct DropletCreateData: Content {
    let name: String
}
