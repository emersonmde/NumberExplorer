import SwiftUI

enum LearningMode: String, CaseIterable, Identifiable {
    case englishSpeaking = "English"
    case chineseSpeaking = "Chinese"
    
    var id: Self { self }
}

struct ContentView: View {
    @StateObject private var viewModel = NumberLearningViewModel()
    
    var body: some View {
        VStack {
            modePicker
            numberGrid
            startButton
        }
        .padding()
        .navigationTitle("Learn Numbers")
    }
    
    private var modePicker: some View {
        Picker("Mode", selection: $viewModel.currentMode) {
            ForEach(LearningMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
    
    private var numberGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                ForEach(viewModel.numbers.indices, id: \.self) { index in
                    NumberCell(data: viewModel.numbers[index])
                }
            }
        }
    }
    
    private var startButton: some View {
        Button(action: {
            viewModel.startListening()
        }) {
            Text(viewModel.isListening ? "Stop Listening" : "Start Listening")
                .font(.title2)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding()
    }
}


#Preview {
    ContentView()
}
