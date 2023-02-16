import SwiftUI

struct GameNavView: View {

	init() { }

	var body: some View {
		HStack(alignment: .center, spacing: .grid(2)) {
			Text("PhotoGuesser")
				.bold()
			Spacer()
			Button(action: {
				//
			}) {
				Image(systemName: "ellipsis")
					.foregroundColor(.black)
					.padding()
					.rotationEffect(.degrees(90))
			}
			.frame(maxHeight: .infinity)
			.background(Color.black.opacity(0.05))
			.cornerRadius(12)
		}
		.fixedSize(horizontal: false, vertical: true)
		.padding([.leading, .trailing])
		.padding([.top, .bottom], .grid(2))
	}
}

#if DEBUG
struct GameNavView_Previews: PreviewProvider {
	static var previews: some View {
		VStack {
			GameNavView()
			Spacer()
		}
	}
}
#endif
