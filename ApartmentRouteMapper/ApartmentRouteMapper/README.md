# Apartment Route Mapper

An iOS app for managing apartment viewing routes with optimized navigation using the Traveling Salesman Problem (TSP) algorithm.

## Features

- 🗺️ **Interactive Map View**: View all apartments on a map with route visualization
- 📍 **Current Location Support**: Automatic location tracking and distance calculations
- 🏢 **Apartment Management**: Add, edit, and delete apartment listings
- 🔍 **Address Autocomplete**: Quick address entry with MapKit search integration
- 🚗 **Route Optimization**: TSP algorithm implementation for shortest route calculation
- 💾 **Core Data Persistence**: Save apartments and routes locally
- 📱 **SwiftUI Interface**: Modern, responsive UI design
- 🎯 **MVVM Architecture**: Clean separation of concerns

## Technical Stack

- **Language**: Swift 5.0
- **UI Framework**: SwiftUI
- **Minimum iOS**: 17.0
- **Architecture**: MVVM
- **Persistence**: Core Data
- **Maps**: MapKit
- **Location**: CoreLocation

## Key Components

### Models
- `Apartment`: Represents an apartment location with coordinates and metadata
- `Route`: Manages waypoints and route optimization state
- `Waypoint`: Individual stops on a route with timing information

### Services
- `LocationService`: Handles location permissions and real-time updates
- `RouteOptimizationService`: Implements TSP algorithm with 2-opt improvement
- `CoreDataService`: Manages local data persistence

### Views
- `MapView`: Interactive map with apartment pins and route display
- `ApartmentListView`: Searchable list of apartments with distance sorting
- `RouteDetailView`: Detailed route information with reordering capability

## Route Optimization

The app uses a Nearest Neighbor heuristic with 2-opt improvement for route optimization:

1. **Nearest Neighbor**: Starts from current location and visits the nearest unvisited apartment
2. **2-Opt Improvement**: Iteratively improves the route by eliminating crossing paths
3. **MapKit Integration**: Calculates actual driving distances and times

## Setup

1. Open `ApartmentRouteMapper.xcodeproj` in Xcode
2. Build and run on iOS 17.0+ device or simulator
3. Allow location permissions when prompted

## Usage

1. **Add Apartments**: Tap + in the Apartments tab to add new locations
2. **Select Apartments**: On the map, tap apartment pins to add them to your route
3. **Optimize Route**: Tap "Optimize Route" to calculate the shortest path
4. **View Details**: Access detailed route information and driving directions
5. **Save Routes**: Save optimized routes for future reference

## Testing

The project includes comprehensive unit tests for the route optimization algorithm. Run tests with ⌘+U in Xcode.