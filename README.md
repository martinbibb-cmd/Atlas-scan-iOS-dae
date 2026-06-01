# Atlas Scan

## Open and Run in Xcode

Use the app project, not Swift Package mode.

Open:

- `AtlasScan.xcodeproj`

Do NOT open:

- `Package.swift`
- the repository folder as a Swift Package

In Xcode:

1. Select the `AtlasScanApp` scheme.
2. Select an iPhone simulator or a physical iPhone.
3. Press Run to install and launch `AtlasScanApp.app`.
4. The app should launch to the visit list (`VisitListView`).

## Repository Description

Atlas Scan is a spatial-first survey capture application for heating, hot water, and home energy systems.
The application is designed around evidence capture rather than form completion.
Surveyors follow the system through the property while Atlas captures photos, voice notes, spatial relationships, and structured survey data.
Atlas Scan does not generate recommendations.
Its responsibility is to capture reality accurately and efficiently, producing a canonical survey package for Atlas Mind.

Core philosophy:

- Follow the system.
- Capture reality.
- Build the twins later.

## Overview

Atlas Scan is the field capture component of the Atlas platform.

Traditional survey software focuses on forms.

Atlas Scan focuses on reality.

Surveyors walk the property naturally while Atlas captures:

- System Twin
- House Twin
- Home Twin

These are later interpreted by Atlas Mind to generate recommendations, customer journeys, and future planning.

## Design Principles

### Spatial First

Reality exists once.

Presentation adapts later.

Capture should preserve physical relationships wherever possible.

### Follow The System

Surveys begin with the heating system.

Typical path:

Boiler  
↓  
Flue  
↓  
Controls  
↓  
Cylinder  
↓  
Feed & Expansion  
↓  
Meters  
↓  
Emitters

The surveyor follows the system.

Atlas builds the model.

## Survey Navigation

Atlas Scan does not require room-by-room capture.
The preferred workflow is to follow the physical system:

Boiler  
→ Flue  
→ Controls  
→ Cylinder  
→ Feed & Expansion  
→ Meters  
→ Emitters

The house model emerges from evidence capture rather than being completed as a separate form.

## Home / House / System

Atlas captures three overlapping twins.

### System Twin

What exists.

Physical heating and hot water infrastructure.

Examples:

- Boiler
- Cylinder
- Pump
- Radiators
- Controls
- Meters

### House Twin

Where it exists.

Physical building.

Examples:

- Rooms
- Loft
- Garage
- Extensions
- Insulation
- Access routes

### Home Twin

Why it matters.

People and objectives.

Examples:

- Future plans
- Reliability concerns
- Budget limits
- Accessibility needs
- Household changes

## V0.1 Scope

### Included

#### Visit Management

- Create Visit
- Resume Visit
- Export Visit

#### Capture

- Photo
- Voice Note
- Object Tagging
- Evidence Records

#### Survey Progress

- System Progress
- House Progress
- Home Progress

#### Object Library

Initial V0.1 object set:

- Boiler
- Cylinder
- Thermal Store
- Radiator
- UFH Manifold
- Pump
- Filter
- Tank
- Programmer
- Thermostat
- TRV
- Consumer Unit
- Gas Meter
- Electric Meter
- Stopcock
- Flue
- Condensate
- Shower
- Bath
- Sink
- Risk
- Customer Goal

#### Export

- Atlas Contracts Payload
- Media Package
- Survey Metadata

### Explicitly Out Of Scope

- Automatic object recognition
- Computer vision
- Recommendation engine
- Pricing engine
- Quote generation
- Atlas Mind logic
- Customer presentation
- PDF generation
- RoomPlan automation
- AI-assisted surveying
- Cloud sync

### Deferred To Future Versions

- ARKit geometry capture
- Object measurement
- RoomPlan integration
- Spatial mesh generation
- Automatic object recognition
- Digital twin generation
- Atlas Mind integration

## Non-Goal

Atlas Scan is not a quote tool.

## Capture Model

Tap

- Photo
- Anchor

Hold

- Video

Hold + Pull Down

- Voice Note

Swipe Up

- Object Library

Swipe Down

- Progress Drawer

Volume Buttons

- Volume Up: Capture
- Hold Volume Up: Video
- Volume Down: Voice Note

Field usability takes priority over novelty.

Native iOS interaction patterns should be preferred whenever possible.

## Assistance Levels

Atlas Scan supports progressive guidance.

### Level 1

Expert

Minimal prompts.

### Level 2

Guided

Suggested next objects.

### Level 3

Training

Step-by-step survey assistance.

Example:

Open vented boiler detected.  
Check:
- F&E tank
- Cold feed
- Open vent
- Pump position

## Success Criteria

Atlas Scan V0.1 is successful if:

- A real survey can be completed faster than Depot.
- A surveyor can leave site with confidence.
- Atlas Mind receives enough information to construct meaningful twins.

### Success Test

Can a real surveyor complete a real survey faster than Depot while capturing richer evidence?  
If not, Atlas Scan has failed regardless of technical sophistication.

## Initial Build Backlog (Sprint 1)

### Core Architecture

- Visit
- Space
- Object
- Evidence

### Capture Screen

- Camera View
- Capture Button
- Object Tagging
- Voice Notes

### Object Registry

- Static Object Library

### Progress Engine

- Deterministic survey graph

### Export

- JSON Package
- Media References

## PR Status

| PR | Title | Status |
|----|-------|--------|
| PR 1 | Repository foundation & README | ✅ Merged |
| PR 2 | Core local survey data model | ✅ Data-model only — no UI, no camera, no voice, no ARKit, no recommendations, no pricing, no Mind logic. Models: `Visit`, `CaptureItem`, `EvidenceRecord`, `ObjectTag`, `TwinDrafts`. Codable + Identifiable. 30 unit tests passing. |
| PR 3 | Create / Resume Visit | ✅ Local visit management — `VisitStore` (JSON file persistence), `VisitListView`, `VisitDetailView`, `CreateVisitSheet`, `AtlasScanApp` entry point. 44 unit tests passing (14 new persistence round-trip tests). No camera, voice, ARKit, recommendations, pricing, or Mind logic. |

---

## Codex-Ready Copy Box

`feat(scan): create Atlas Scan V0.1 foundation`

Build a new iOS application named `atlas-scan-ios`.
Primary objective:
Allow real-world heating surveys to be captured faster than Depot.
Implement:
- Visit creation
- Visit persistence
- Camera capture
- Object tagging
- Voice note attachment
- Evidence record model
- Progress tracking
- Export package generation
Do NOT implement:
- AI
- Recommendations
- Pricing
- Atlas Mind logic
- Computer vision
- Automatic recognition

Architecture:

Visit
├─ System Twin
├─ House Twin
└─ Home Twin

Capture Philosophy:
Follow the system.
Capture reality.
Build the twins later.

Use native iOS patterns wherever possible.
Prioritise speed, one-handed use, gloves, poor weather conditions, and minimal typing.
The application must be usable for a live customer survey before any advanced spatial features are introduced.