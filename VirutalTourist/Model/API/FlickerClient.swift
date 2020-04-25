//
//  FlickerAPI.swift
//  VirutalTourist
//
//  Created by JASJEEV on 4/18/20.
//  Copyright © 2020 Lorgarithmic Science. All rights reserved.
//

import Foundation

class FlickrClient {

    // MARK: Define all required Endpoints
    enum Endpoints {
        static let services = "https://www.flickr.com/services/rest"
        static let apiKey = "api_key=991fcc28b87850c0cc8b6d318209209f"
        
        case searchPhotos(lat: String, long: String)
        case getPhoto(farmId: Int, serverId: String, photoId: String, photoSecret: String)
        
        var stringValue: String {
            switch self {
            case .searchPhotos(let lat, let long): return "\(Endpoints.services)/?method=flickr.photos.search&\(Endpoints.apiKey)&lat=\(lat)&lon=\(long)&format=json&nojsoncallback=1"
            case .getPhoto(let farmId, let serverId, let photoId, let photoSecret): return "https://farm\(farmId).staticflickr.com/\(serverId)/\(photoId)_\(photoSecret)_n.jpg"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }

    class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                do {
                    let errorResponse = try decoder.decode(ResponseType.self, from: data) as! Error
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }
        task.resume()
        
        return task
    }
    
    
    class func searchPhotos(lat: String, long: String, completion: @escaping ([Photos]?, Error?) -> Void) {
        let url = Endpoints.searchPhotos(lat: lat, long: long).url
        print("Search url: \(url)")
        taskForGETRequest(url: url, responseType: PhotosResponse.self) { (response, error) in
            if let
                response = response {
                completion(response.photos?.photo, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    class func downloadPhoto(urlString: String, completion: @escaping (Data?, Error?) -> Void) {
        let url = URL(string: urlString)!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
        task.resume()
    }
}
