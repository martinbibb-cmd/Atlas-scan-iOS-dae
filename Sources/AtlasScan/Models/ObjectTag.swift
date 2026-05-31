import Foundation

// MARK: - ObjectTag

/// The complete set of taggable objects in Atlas Scan V0.1.
public enum ObjectTag: String, Codable, CaseIterable, Sendable {
    case boiler
    case cylinder
    case thermalStore
    case radiator
    case ufhManifold
    case pump
    case filter
    case tank
    case programmer
    case thermostat
    case trv
    case consumerUnit
    case gasMeter
    case electricMeter
    case stopcock
    case flue
    case condensate
    case shower
    case bath
    case sink
    case risk
    case customerGoal

    // MARK: Default TwinArea

    /// The default `TwinArea` for this tag.
    ///
    /// Mapping rationale:
    /// - **system** – physical heating / hot water / electrical infrastructure
    /// - **house**  – building fabric (wet rooms)
    /// - **home**   – people-centric items (risks, goals)
    public var defaultTwinArea: TwinArea {
        switch self {
        case .boiler, .cylinder, .thermalStore, .radiator, .ufhManifold,
             .pump, .filter, .tank, .programmer, .thermostat, .trv,
             .consumerUnit, .gasMeter, .electricMeter, .stopcock,
             .flue, .condensate:
            return .system
        case .shower, .bath, .sink:
            return .house
        case .risk, .customerGoal:
            return .home
        }
    }

    // MARK: Display name

    public var displayName: String {
        switch self {
        case .boiler:        return "Boiler"
        case .cylinder:      return "Cylinder"
        case .thermalStore:  return "Thermal Store"
        case .radiator:      return "Radiator"
        case .ufhManifold:   return "UFH Manifold"
        case .pump:          return "Pump"
        case .filter:        return "Filter"
        case .tank:          return "Tank"
        case .programmer:    return "Programmer"
        case .thermostat:    return "Thermostat"
        case .trv:           return "TRV"
        case .consumerUnit:  return "Consumer Unit"
        case .gasMeter:      return "Gas Meter"
        case .electricMeter: return "Electric Meter"
        case .stopcock:      return "Stopcock"
        case .flue:          return "Flue"
        case .condensate:    return "Condensate"
        case .shower:        return "Shower"
        case .bath:          return "Bath"
        case .sink:          return "Sink"
        case .risk:          return "Risk"
        case .customerGoal:  return "Customer Goal"
        }
    }
}

public extension TwinArea {
    var displayName: String {
        switch self {
        case .system:
            return "System"
        case .house:
            return "House"
        case .home:
            return "Home"
        }
    }

    var defaultObjectTag: ObjectTag {
        switch self {
        case .system:
            return .boiler
        case .house:
            return .sink
        case .home:
            return .customerGoal
        }
    }
}
