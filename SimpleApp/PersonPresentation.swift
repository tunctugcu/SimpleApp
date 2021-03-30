//
//  PersonPresentation.swift
//  SimpleApp
//
//  Created by Tunc Tugcu on 27.03.2021.
//

import Foundation

struct PersonPresentation: Hashable {
    static func == (lhs: PersonPresentation, rhs: PersonPresentation) -> Bool {
        lhs.person.id == rhs.person.id
            && lhs.person.fullName == rhs.person.fullName
    }
    
    let person: Person
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(person.id)
        hasher.combine(person.fullName)
    }
    
    var text: String { person.fullName + " (" + String(person.id) + ")" }
}
