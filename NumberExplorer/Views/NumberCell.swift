import SwiftUI

struct NumberCell: View {
    let data: NumberData
    
    var body: some View {
        Text(data.number.description)
            .font(.title2)
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(8)
    }
    
    private var backgroundColor: Color {
        if data.isActive { return .yellow }
        if data.isCompleted { return .gray }
        return .blue.opacity(0.1)
    }
    
    private var textColor: Color {
        if data.isCompleted { return .white }
        return .primary
    }
}
