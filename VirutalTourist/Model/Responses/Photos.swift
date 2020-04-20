//
//  Photos.swift
//  VirutalTourist
//
//  Created by JASJEEV on 4/18/20.
//  Copyright © 2020 Lorgarithmic Science. All rights reserved.
//

import Foundation

struct Photos: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
}
