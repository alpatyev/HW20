import Foundation

// MARK: - Models

struct CardsList: Decodable {
    let cards: [Card]
}

struct Card: Decodable {
    let name: String
    let manaCost: String
    let type: String
    let rarity: String
    let setName: String
    let flavor: String?
    let text: String
    let artist: String
    let number: String
    let id: String
}

// MARK: - Network service

final class CardsDataService {
    
    private enum RequestType {
        case specificName(String)
    }
    
    private lazy var urlBuilder: URLComponents = {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.magicthegathering.io"
        components.path = "/v1/cards"
        return components
    }()
        
    private let schedule = DispatchGroup()
    
    public func fetchCards(named name: String) {
        schedule.wait()
        schedule.enter()
        
        print("\n▼ REQUEST FOR NAME \"\(name)\"")
        guard let url = createURL(.specificName(name)) else {
            print("  ► URL ERROR FOR NAME \"\(name)\"")
            schedule.leave()
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            defer { self?.schedule.leave() }
            
            if let response = response as? HTTPURLResponse{
                print("  ► RESPONSE CODE: \(response.statusCode)")
            } else {
                print("  ► NO RESPONSE")
            }
            
            if let data = data {
                if let cards = self?.serializeData(data) {
                    self?.presentCards(cards)
                }
            } else {
                print("  ► NO DATA")
            }
            
            if let error = error {
                print("  ► REQUEST ERROR: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    private func createURL(_ requestType: RequestType) -> URL? {
        switch requestType {
            case .specificName(let name):
                urlBuilder.queryItems = [URLQueryItem(name: "name", value: "\"\(name)\"")]
                return urlBuilder.url
        }
    }
    
    private func calculateDataSize(_ data: Data) -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useAll]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: Int64(data.count))
    }
    
    private func serializeData(_ data: Data) -> [Card]? {
        print("  ► RECIVED DATA: " + calculateDataSize(data))
        do {
            let decoded = try JSONDecoder().decode(CardsList.self, from: data)
            return decoded.cards
        } catch let error {
            print("  ► DECODING ERROR: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func presentCards(_ cards: [Card]) {
        guard cards.count > 0 else { print("  ► CARDS NOT FOUNDED"); return }
        print("\n    ▼ FOUNDED \(cards.count) CARDS WITH EXACT NAME")

        let spacing = "\n    - "
        var description = String()
        let spaced: (String) -> Void = { base in description += (spacing + base) }
        
        for (index, card) in cards.enumerated() {
            spaced("[\(index + 1)] \"\(card.name)\"")
            spaced("ID        : \(card.id)")
            spaced("Type      : \(card.type)")
            spaced("Artist    : \(card.artist)")
            spaced("Set name  : \(card.setName)")
            spaced("RARITY    : \(card.rarity)")
            spaced("MANA COST : \(card.manaCost)")
            
            if let flavor = card.flavor {
                spaced("FLAVOR    : \(flavor.replacingOccurrences(of: "\n", with: " "))")
            }
            
            print(description)
            description.removeAll()
        }
    }
}

let gameDataService = CardsDataService()
gameDataService.fetchCards(named: "Opt")
gameDataService.fetchCards(named: "Black Lotus")
gameDataService.fetchCards(named: "abcdefghj")
