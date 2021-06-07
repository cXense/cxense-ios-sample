import SwiftUI
import CxenseSDK

public struct CloseButton: View {
    let close: () -> Void
    
    public var body: some View {
        HStack(alignment: .top) {
            Spacer()
            
            Button(action: {
                close()
            }, label: {
                Image(systemName: "multiply")
            })
        }.padding(EdgeInsets(top: 15, leading: 0, bottom: 10, trailing: 15))
    }
}

public struct SportKind {
    
    let name: String
}

public struct RecomendationView: View {
    
    @Environment(\.openURL) var openURL
    
    @StateObject var viewModel = RecomendationViewModel()
    
    let widget: ContentWidget
    let recomendation: ContentRecommendation
    let close: () -> Void
    
    public var body: some View {
        VStack {
            if viewModel.thumbnail != nil {
                CloseButton {
                    close()
                }
                
                Text(recomendation.title)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(uiImage: UIImage(data: viewModel.thumbnail!)!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                
                Spacer()
                
                Button(action: {
                    openURL(URL(string: recomendation.url)!)
                }) {
                    Image(systemName: "safari")
                        .resizable()
                        .frame(width: 48, height: 48, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                }.padding(.bottom, 10)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            /// Track click
            widget.trackClick(for: recomendation)

            guard let url = URL(string: recomendation.dominantthumbnail!) else { return }

            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let d = data, error == nil else { return }
                DispatchQueue.main.async {
                    viewModel.thumbnail = d
                }
            }.resume()
        }
    }
}

extension RecomendationView {
    
    class RecomendationViewModel: ObservableObject {
        
        @Published var thumbnail: Data? = nil
    }
}

public struct SportKindView: View {
        
    @Environment(\.presentationMode) var presentation
    
    @ObservedObject var viewModel = ViewModel()
    
    @State private var showingSheet = false
    
    let sportKind: SportKind
        
    public var body: some View {
        VStack {
            if self.viewModel.recomendations.count > 0 {
                List(self.viewModel.recomendations, id: \.url) { recomendation in
                    HStack {
                        Image(systemName: "bolt.circle")
                            .padding(.horizontal, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                        Button(recomendation.title) {
                            viewModel.current = recomendation
                            showingSheet.toggle()
                        }
                    }
                }
            } else {
                ProgressView()
            }
        
        }
        .navigationBarTitle(sportKind.name)
        .sheet(isPresented: $showingSheet) {
            RecomendationView(widget: viewModel.widget!, recomendation: viewModel.current!) {
                viewModel.current = nil
                showingSheet.toggle()
            }
        }
        .onAppear {
            /// Create content context
            let context = ContentContext()
            context.url = "https://cxense.com"
            
            /// Make content widget
            let widget = Cxense.makeWidget(id: "ffb1d2523b582f5f649df351d37928d2c108e715", context: context)
            viewModel.widget = widget
            
            /// Fetch recomendations
            widget.fetchItems { recomendations, error in
                guard let r = recomendations, error == nil else { return }
                
                DispatchQueue.main.async {
                    self.viewModel.recomendations = r
                }
            }
            
            do {
                /// Make page view event
                let pageViewEvent = try PageViewEventBuilder.makeBuilder(
                    withName: sportKind.name,
                    siteId: AppDelegate.SiteID
                )
                .setContentId(cid: sportKind.name)
                .addCustomParameter(forKey: "cxd-item", withValue: sportKind.name)
                .build()
                /// Send page view event
                Cxense.reportEvent(pageViewEvent)
                
                /// Make performance event
                let performanceEvent = try PerformanceEventBuilder.makeBuilder(
                    withName: sportKind.name,
                    type: "view",
                    origin: "cxd-app",
                    siteId: AppDelegate.SiteID,
                    andUserIds: [DMPUserIdentifier(identifier: "value", type: "cxd")]
                )
                .setPrnd(pageViewEvent.rnd!)
                .addCustomParameter(DMPCustomParameter(group: "kind", item: sportKind.name))
                .build()
                /// Send performance event
                Cxense.reportEvent(performanceEvent)
                
                /// Make conversion event
                let conversionEvent = try ConversionEventBuilder.makeBuilder(
                    withName: sportKind.name,
                    type: "view",
                    origin: "cxd-app",
                    siteId: AppDelegate.SiteID,
                    andUserIds: [DMPUserIdentifier(identifier: "123456", type: "cxd")]
                )
                .setPrnd(pageViewEvent.rnd!)
                .build()
                
                /// Send performance event
                Cxense.reportEvent(conversionEvent)
            } catch {
                print(error.localizedDescription)
            }
        }
        .onDisappear {
        }
    }
}

extension SportKindView {
    class ViewModel: ObservableObject {
        @Published public var recomendations: [ContentRecommendation] = []
        
        public var widget: ContentWidget? = nil
        
        public var current: ContentRecommendation? = nil
    }
}

struct ContentView: View {
    
    @ObservedObject var viewModel: ViewModel = ViewModel()
    
    @State private var showingSheet = false
    
    var body: some View {
        NavigationView {
            List(viewModel.sportKinds, id: \.name) { sportKind in
                NavigationLink(
                    destination: SportKindView(sportKind: sportKind)) {
                    Text(sportKind.name)
                }
                
            }
            .navigationBarTitle("Cxense Sample")
            .navigationBarItems(
                trailing:
                    Button(action: {
                        
                    }) {
                        Menu {
                            Button(action: {
                                /// Queue status
                                viewModel.status = Cxense.queueStatus()
                                showingSheet.toggle()
                            }) {
                                Label("Queue status", systemImage: "info.circle")
                            }
                            
                            Button(action: {
                                /// Flush events
                                Cxense.flushEventQueue()
                            }) {
                                Label("Flush event queue", systemImage: "arrow.up.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    }
            )
            .sheet(isPresented: $showingSheet) {
                VStack {
                    CloseButton {
                        showingSheet.toggle()
                    }
                    Text("Sent: \(viewModel.status?.sentEvents.count ?? -1)")
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Not sent: \(viewModel.status?.notSentEvents.count ?? -1)")
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                }
            }
        }
    }
}

extension ContentView {
    
    class ViewModel: ObservableObject {
        
        var status: QueueStatus? = nil
        
        @Published var pushed = false
       
        let sportKinds: [SportKind] = [
            SportKind(name: "Football"),
            SportKind(name: "Basketball"),
            SportKind(name: "Hockey"),
            SportKind(name: "Baseball"),
            SportKind(name: "Tennis"),
            SportKind(name: "Athletics"),
            SportKind(name: "Weightlifting")
        ]
    }
}

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        ContentView()
    }
}
