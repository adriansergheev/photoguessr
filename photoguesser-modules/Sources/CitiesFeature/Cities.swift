import SwiftUI
import Styleguide
import CoreLocation

struct Location {
	let lat: Double
	let long: Double
}

struct City: Identifiable {
	let id: UUID = .init()
	let location: Location
	let name: String
}

let cities = [
	City(location: .init(lat: 0, long: 0), name: "San-Francisco"),
	City(location: .init(lat: 0, long: 0), name: "Stockholm"),
	City(location: .init(lat: 0, long: 0), name: "Chisinau")
]

let sfLady = UIImage(named: "sf-lady", in: Bundle.module, with: nil)!

struct ListView: View {
	@Environment(\.colorScheme) var colorScheme
	var body: some View {
		GeometryReader { proxy in
			ScrollView {
				ForEach(cities) { _ in
					ZStack {
						VStack {
							Image(uiImage: sfLady)
								.resizable()
								.aspectRatio(contentMode: .fill)
						}
						.frame(height: proxy.size.height / 4)
						.cornerRadius(8)
						.padding([.leading, .trailing], .grid(4))
						.padding([.top, .bottom], .grid(2))

						VStack {
							Spacer()
							HStack {
								Spacer()
								Text("San Francisco")
									.bold()
									.padding(.grid(2))
									.padding([.leading, .trailing], .grid(2))
									.foregroundColor(self.colorScheme == .dark ? .black : .photoGuesserCream)
									.background(self.colorScheme == .dark ? Color.photoGuesserCream : .black)
									.clipShape(
										RoundedRectangle(cornerRadius: 13, style: .continuous)
												.inset(by: 2)
									)
							}
						}
						.padding([.trailing], .grid(8))
						.padding([.bottom], .grid(4))
					}
				}
			}
		}
	}
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		Preview {
			ListView()
		}
	}
}
#endif
