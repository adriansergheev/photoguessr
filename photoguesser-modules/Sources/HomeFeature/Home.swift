import SwiftUI
import Styleguide

public struct HomeView: View {
	
	public var body: some View {
		VStack {
			GeometryReader { proxy in
				Spacer()
					.padding(.grid(2))
				EmptyView()
					.frame(width: proxy.size.width)
					.border(.red)
			}
		}
	}
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
	static var previews: some View {
		HomeView()
	}
}
#endif
