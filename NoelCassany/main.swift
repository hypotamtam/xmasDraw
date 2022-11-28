import Foundation

//Data structure

struct Entry: Codable {
    let year: Int
    let draw: [String: String]
}

struct Log: Codable {
    let history: [Entry]
    let exclusion: [String: [String]]
}


// Script

guard CommandLine.arguments.count > 1 else {
    exit(-1)
}

let jsonPath = CommandLine.arguments[1]
print(jsonPath)

guard let data = FileManager.default.contents(atPath: jsonPath) else {
    exit(-1)
}

var candidatesPerName = try getCandidatesPerName(data)
//candidatesPerName.forEach {
//    print("\($0.key): \($0.value)")
//}

var isFinished = false
var round = 0
while(!isFinished) {
    do {
        let pair = try drawPair(candidatesPerName: candidatesPerName)
        print("-------------------------------")
        pair.forEach {
            print("\($0.from) ==> \($0.to)")
        }
        print("-------------------------------")
        isFinished = true
    } catch {
        round = round + 1
        if round > 1000 {
            print("DOMMAGE ELIANE!")
            exit(-1)
        }
    }
}


func drawPair(candidatesPerName: [String: [String]]) throws -> [(from: String, to: String)] {
    var pair = [(from: String, to: String)]()
    var nameDrawn = [String]()

    try candidatesPerName.forEach {
        var candidates = $0.value.filter { name in !nameDrawn.contains(name) }
        guard !candidates.isEmpty else {
            throw DrawnError.noCandidateAvailable
        }
        if let to = candidates.randomElement() {
            pair.append((from: $0.key, to: to))
            nameDrawn.append(to)
        } else {
            throw DrawnError.noCandidateDrawn
        }
    }

    return pair
}

func getCandidatesPerName(_ data: Data) throws -> [String: [String]] {
    let log = try JSONDecoder().decode(Log.self, from: data)
    let names = log.history.first
        .map { $0.draw }
        .map { $0.compactMap{ entry in entry.key } }

    guard let names = names else {
        exit(-1)
    }

    var candidatesPerName = [String: [String]]()

    names.forEach { participant in
        var notPossibleCandidates = log.history.compactMap { $0.draw[participant]}
        notPossibleCandidates.append(contentsOf: log.exclusion[participant] ?? [])
        notPossibleCandidates.append(participant)
        let candidates =  names.filter {  !notPossibleCandidates.contains($0)}
        candidatesPerName[participant] = candidates
    }

    candidatesPerName.forEach {
        print("\($0.key): \($0.value)")
    }

    return candidatesPerName
}

enum DrawnError: Error {
    case noCandidateAvailable
    case noCandidateDrawn
}

//print(history?.map { [Int($0.key): $0.value] })


