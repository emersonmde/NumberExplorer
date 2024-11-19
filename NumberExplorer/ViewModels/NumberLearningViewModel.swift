import SwiftUI
import Speech
import AVFoundation

class NumberLearningViewModel: NSObject, ObservableObject {
    @Published var numbers: [NumberData] = []
    @Published var currentMode: LearningMode = .englishSpeaking
    @Published var currentIndex: Int = 0
    @Published var isListening: Bool = false
    @Published private(set) var currentSpeechBuffer: String = ""
    
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var errorCount = 0
    private let maxErrors = 3
    private var isRecognitionActive = false
    
    override init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        super.init()
        speechRecognizer?.delegate = self
        setupNumbers()
        requestPermissions()
    }
    
    private func setupNumbers() {
        numbers = (0...100).map { num in
            NumberData(
                number: num,
                english: String(num),
                chinese: convertToChineseNumeral(num),
                isCompleted: false,
                isActive: false
            )
        }
        numbers[0].isActive = true
    }
    
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status == .authorized {
                    print("Speech recognition authorized")
                } else {
                    print("Speech recognition not authorized")
                    self?.isListening = false
                }
            }
        }
        
        AVAudioApplication.requestRecordPermission { [weak self] allowed in
            DispatchQueue.main.async {
                if allowed {
                    print("Microphone access granted")
                } else {
                    print("Microphone access denied")
                    self?.isListening = false
                }
            }
        }
    }
    
    func startListening() {
        if isListening {
            stopListening()
            return
        }
        
        errorCount = 0
        do {
            try setupAudioSession()
            try startRecording()
            isListening = true
            print("Listening started successfully")
        } catch {
            print("Error starting recording: \(error)")
            isListening = false
            cleanup()
        }
    }
    
    func stopListening() {
        cleanup()
        isListening = false
    }
    
    private func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    private func startRecording() throws {
        guard let speechRecognizer = speechRecognizer else {
            throw NSError(domain: "SpeechRecognizerError", code: -1)
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "RecognitionRequestError", code: -1)
        }
        
        let inputNode = audioEngine.inputNode
        
        // Configure recognition request
        recognitionRequest.shouldReportPartialResults = true
        
        // Install tap on input node
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Create recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.handleRecognitionError(error)
                return
            }
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                print("Transcription: \(transcription)")
                
                DispatchQueue.main.async {
                    self.currentSpeechBuffer = transcription
                    if !transcription.isEmpty {
                        self.checkNumber(transcription)
                    }
                }
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        isRecognitionActive = true
    }
    
    private func handleRecognitionError(_ error: Error) {
        let nsError = error as NSError
        
        if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110 {
            return
        }
        
        errorCount += 1
        print("Recognition error (\(errorCount)/\(maxErrors)): \(error)")
        
        if errorCount >= maxErrors {
            DispatchQueue.main.async {
                self.stopListening()
            }
            return
        }
        
        if isListening && isRecognitionActive {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                do {
                    try self.startRecording()
                } catch {
                    self.stopListening()
                }
            }
        }
    }
    
    private func cleanup() {
        audioEngine.stop()
        if audioEngine.inputNode.numberOfInputs > 0 {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecognitionActive = false
        
        // Don't deactivate the audio session here as it can cause issues
    }
    
    private func checkNumber(_ spokenText: String) {
        let currentNumber = numbers[currentIndex]
        let targetNumber = currentNumber.number
        
        let cleaned = spokenText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if let spoken = Int(cleaned), spoken == targetNumber {
            handleMatch()
            return
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = Locale(identifier: "en-US")
        
        if let spokenNumber = formatter.number(from: cleaned),
           spokenNumber.intValue == targetNumber {
            handleMatch()
        }
    }
    
    private func handleMatch() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.numbers[self.currentIndex].isCompleted = true
            self.numbers[self.currentIndex].isActive = false
            
            if self.currentIndex < self.numbers.count - 1 {
                self.currentIndex += 1
                self.numbers[self.currentIndex].isActive = true
            }
        }
    }
    
    private func convertToChineseNumeral(_ num: Int) -> String {
        let chineseNumerals = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
        
        if num == 0 { return chineseNumerals[0] }
        if num <= 10 { return chineseNumerals[num] }
        if num < 20 { return "\(chineseNumerals[10])\(chineseNumerals[num - 10])" }
        
        let tens = num / 10
        let ones = num % 10
        
        if ones == 0 {
            return "\(chineseNumerals[tens])\(chineseNumerals[10])"
        }
        return "\(chineseNumerals[tens])\(chineseNumerals[10])\(chineseNumerals[ones])"
    }
}

extension NumberLearningViewModel: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            stopListening()
        }
    }
}
