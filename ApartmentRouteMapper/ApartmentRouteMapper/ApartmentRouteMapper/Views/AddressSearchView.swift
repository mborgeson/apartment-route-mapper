import SwiftUI
import MapKit

struct AddressSearchView: View {
    @Binding var searchText: String
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var searchCompleter = MKLocalSearchCompleter()
    @State private var completions: [MKLocalSearchCompletion] = []
    
    let onSelection: (MKMapItem) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search for address...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _, newValue in
                        searchCompleter.queryFragment = newValue
                    }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()
            
            if !completions.isEmpty {
                List(completions, id: \.self) { completion in
                    Button(action: {
                        selectCompletion(completion)
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(completion.title)
                                .font(.body)
                                .foregroundColor(.primary)
                            if !completion.subtitle.isEmpty {
                                Text(completion.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
                .frame(maxHeight: 300)
            }
            
            if isSearching {
                ProgressView("Searching...")
                    .padding()
            }
        }
        .onAppear {
            setupSearchCompleter()
        }
    }
    
    private func setupSearchCompleter() {
        searchCompleter.delegate = SearchCompleterDelegate { completions in
            self.completions = completions
        }
        searchCompleter.resultTypes = .address
    }
    
    private func selectCompletion(_ completion: MKLocalSearchCompletion) {
        isSearching = true
        
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            isSearching = false
            
            if let mapItem = response?.mapItems.first {
                onSelection(mapItem)
                searchText = ""
                completions = []
            }
        }
    }
}

// MARK: - Search Completer Delegate
class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    private let onUpdate: ([MKLocalSearchCompletion]) -> Void
    
    init(onUpdate: @escaping ([MKLocalSearchCompletion]) -> Void) {
        self.onUpdate = onUpdate
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onUpdate(completer.results)
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error)")
    }
}