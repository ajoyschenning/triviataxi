//
//  QuestionOverlay.swift
//  triviataxi
//

import SwiftUI

struct QuestionOverlayView: View {
    @State private var selectedAnswer: String? = nil
    @State private var showQuestion = true
    @State private var timeRemaining = 15
    @State private var isAnswered = false
    @State private var betweenQuestionTimer = 0
    @State private var displayTimer: Timer? = nil
    @State private var answerTimer: Timer? = nil
    @State private var currentShuffledAnswers: [String] = []
    @State private var showBuffer = false
    @State private var isLoading = false
    @State private var loadingError: String? = nil
    @State private var isFetchingNextBatch = false
    
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var userManager: UserManager
    
    let sessionId: String
    let destinationId: String
    let difficulty: String?
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                if isLoading {
                    VStack {
                        ProgressView()
//                            .scaleEffect(1.5)
                        Text("Loading question...")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemGray6))
                } else if let error = loadingError {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        Text("Error Loading Question")
                            .font(.system(size: 16, weight: .bold))
                        Text(error)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        Button(action: { loadQuestion() }) {
                            Text("Retry")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemGray6))
                } else if let question = currentQuestion, showQuestion && !isAnswered && !showBuffer {
                    QuestionBoxView(
                        questionNumber: questionCount,
                        totalQuestions: 0, // Infinite game, so don't show total
                        question: question,
                        allAnswers: currentShuffledAnswers,
                        timeRemaining: timeRemaining,
                        selectedAnswer: selectedAnswer,
                        difficultyColor: difficultyColor,
                        timerColor: timerColor,
                        onAnswerSelected: selectAnswer
                    )
                }
                
                if showBuffer {
                    // Empty during buffer period
                }
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .onAppear {
            loadQuestionBatch()
        }
        .onChange(of: gameManager.isGameOver) { newValue in
            if newValue {
                // Game is over, stop loading new questions
                displayTimer?.invalidate()
                displayTimer = nil
                answerTimer?.invalidate()
                answerTimer = nil
            }
        }
        .onChange(of: gameManager.currentIndex) { newIndex in
            // Fetch next batch when approaching the end of current batch
            if !isFetchingNextBatch && newIndex > gameManager.questions.count - 10 {
                fetchNextBatch()
            }
        }
    }
    
    private var difficultyColor: Color {
        guard let question = gameManager.currentQuestion else { return Color.blue }
        switch question.difficulty.lowercased() {
        case "easy":
            return Color.green
        case "medium":
            return Color.orange
        case "hard":
            return Color.red
        default:
            return Color.blue
        }
    }
    
    private var timerColor: Color {
        if timeRemaining > 7 {
            return Color.green
        } else if timeRemaining > 3 {
            return Color.orange
        } else {
            return Color.red
        }
    }
    
    private func loadQuestionBatch() {
        isLoading = true
        loadingError = nil
        
        Task {
            do {
                // Fetch 50 questions at a time
                let questions = try await NetworkService.shared.fetchQuestionBatch(
                    sessionId: sessionId,
                    difficulty: difficulty,
                    batchSize: 50
                )
                
                await MainActor.run {
                    isLoading = false
                    gameManager.startSession(routeId: destinationId, fetchedQuestions: questions)
                    showNextQuestion()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    loadingError = "Failed to load questions: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func fetchNextBatch() {
        isFetchingNextBatch = true
        
        Task {
            do {
                let questions = try await NetworkService.shared.fetchQuestionBatch(
                    sessionId: sessionId,
                    difficulty: difficulty,
                    batchSize: 50
                )
                
                await MainActor.run {
                    gameManager.appendMoreQuestions(questions)
                    isFetchingNextBatch = false
                }
            } catch {
                await MainActor.run {
                    isFetchingNextBatch = false
                    print("Failed to fetch next question batch: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showNextQuestion() {
        selectedAnswer = nil
        isAnswered = false
        showQuestion = true
        showBuffer = false
        shuffleAnswers()
        startQuestionTimer()
    }
    
    private func startQuestionTimer() {
        timeRemaining = 15
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            timeRemaining -= 1
            
            if timeRemaining <= 0 {
                displayTimer?.invalidate()
                displayTimer = nil
                // Question expires, show buffer
                showQuestion = false
                showBuffer = true
                startBetweenQuestionTimer()
            }
        }
    }
    
    private func selectAnswer(_ answer: String) {
        selectedAnswer = answer
        isAnswered = true
        displayTimer?.invalidate()
        displayTimer = nil
        showQuestion = false
        showBuffer = true
        
        // Submit answer to GameManager for scoring
        gameManager.submitAnswer(answer, userManager: userManager)
        
        // Wait 5 seconds before showing next question
        startBetweenQuestionTimer()
    }
    
    private func startBetweenQuestionTimer() {
        betweenQuestionTimer = 5
        answerTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            betweenQuestionTimer -= 1
            
            if betweenQuestionTimer <= 0 {
                answerTimer?.invalidate()
                answerTimer = nil
                // Check if game is still active
                if !gameManager.isGameOver {
                    showNextQuestion()
                }
            }
        }
    }
    
    private func shuffleAnswers() {
        guard let question = gameManager.currentQuestion else { return }
        var all = [question.correctAnswer] + question.incorrectAnswers
        all.shuffle()
        currentShuffledAnswers = all
    }
}

struct AnswerButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(buttonTextColor)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(buttonBackgroundColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(buttonBorderColor, lineWidth: isSelected ? 2 : 0)
                )
        }
    }
    
    private var buttonBackgroundColor: Color {
        if isSelected {
            return isCorrect ? Color.green.opacity(0.2) : Color.red.opacity(0.2)
        }
        return Color.gray.opacity(0.1)
    }
    
    private var buttonTextColor: Color {
        if isSelected {
            return isCorrect ? Color.green : Color.red
        }
        return Color.black
    }
    
    private var buttonBorderColor: Color {
        if isSelected {
            return isCorrect ? Color.green : Color.red
        }
        return Color.clear
    }
}

struct QuestionBoxView: View {
    let questionNumber: Int
    let totalQuestions: Int
    let question: Question
    let allAnswers: [String]
    let timeRemaining: Int
    let selectedAnswer: String?
    let difficultyColor: Color
    let timerColor: Color
    let onAnswerSelected: (String) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            QuestionHeaderView(
                questionNumber: questionNumber,
                totalQuestions: totalQuestions,
                difficulty: question.difficulty,
                difficultyColor: difficultyColor
            )
            
            QuestionTextView(text: question.text)
            
            AnswersGridView(
                answers: allAnswers,
                correctAnswer: question.correctAnswer,
                selectedAnswer: selectedAnswer,
                onAnswerSelected: onAnswerSelected
            )
            
            TimerCircleView(timeRemaining: timeRemaining, timerColor: timerColor)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 8)
        .padding(16)
        .transition(.scale.combined(with: .opacity))
    }
}

struct QuestionHeaderView: View {
    let questionNumber: Int
    let totalQuestions: Int
    let difficulty: String
    let difficultyColor: Color
    
    var body: some View {
        HStack {
            Text("QUESTION \(questionNumber)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(difficulty.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(difficultyColor)
                .cornerRadius(4)
        }
    }
}

struct QuestionTextView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
    }
}

struct AnswersGridView: View {
    let answers: [String]
    let correctAnswer: String
    let selectedAnswer: String?
    let onAnswerSelected: (String) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(answers, id: \.self) { answer in
                AnswerButton(
                    text: answer,
                    isSelected: selectedAnswer == answer,
                    isCorrect: answer == correctAnswer && selectedAnswer != nil,
                    action: {
                        onAnswerSelected(answer)
                    }
                )
            }
        }
    }
}

struct TimerCircleView: View {
    let timeRemaining: Int
    let timerColor: Color
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: Double(timeRemaining) / 15.0)
                .stroke(timerColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(timeRemaining)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
        }
        .frame(width: 50, height: 50)
    }
}

struct BetweenQuestionsView: View {
    let timeRemaining: Int
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Next question in \(timeRemaining)s...")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 6)
        .transition(.opacity)
    }
}


let sampleQuestions = [
    Question(
        questionId: "1",
        text: "What is the capital of Tennessee?",
        category: "Geography",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "Memphis",
        incorrectAnswers: ["Nashville", "Knoxville", "Chattanooga"]
    ),
    Question(
        questionId: "2",
        text: "What year was Vanderbilt University founded?",
        category: "History",
        difficulty: "Medium",
        earningValue: 10,
        correctAnswer: "1875",
        incorrectAnswers: ["1873", "1879", "1881"]
    )
]

#Preview {
    QuestionOverlayView(
        sessionId: "preview-session-123",
        destinationId: "test-destination",
        difficulty: "easy"
    )
}
