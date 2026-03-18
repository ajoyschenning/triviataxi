//
//  QuestionOverlay.swift
//  triviataxi
//

import SwiftUI

//struct Question {
//    let id: String
//    let text: String
//    let difficulty: String
//    let answers: [String]
//    let correctAnswerIndex: Int
//}

struct QuestionOverlayView: View {
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: String? = nil
    @State private var showQuestion = true
    @State private var timeRemaining = 15
    @State private var isAnswered = false
    @State private var betweenQuestionTimer = 0
    @State private var displayTimer: Timer? = nil
    @State private var answerTimer: Timer? = nil
    @State private var currentShuffledAnswers: [String] = []
    @State private var showBuffer = false
    
    let questions: [Question]
    let sessionId: String
    
    var currentQuestion: Question {
        questions[currentQuestionIndex]
    }
    
    var hasMoreQuestions: Bool {
        currentQuestionIndex < questions.count - 1
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                if showQuestion && !isAnswered && !showBuffer {
                    QuestionBoxView(
                        questionNumber: currentQuestionIndex + 1,
                        totalQuestions: questions.count,
                        question: currentQuestion,
                        allAnswers: currentShuffledAnswers,
                        timeRemaining: timeRemaining,
                        selectedAnswer: selectedAnswer,
                        difficultyColor: difficultyColor,
                        timerColor: timerColor,
                        onAnswerSelected: selectAnswer
                    )
                }
                
                if showBuffer && hasMoreQuestions {
                    // Empty during buffer period
                }
                
                if !hasMoreQuestions && isAnswered && !showQuestion {
                    // QuizCompleteView()
                }
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .onAppear {
            shuffleAnswers()
            startQuestionTimer()
        }
    }
    
    private var difficultyColor: Color {
        switch currentQuestion.difficulty.lowercased() {
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
                moveToNextQuestion()
            }
        }
    }
    
    private func moveToNextQuestion() {
        if hasMoreQuestions {
            currentQuestionIndex += 1
            selectedAnswer = nil
            isAnswered = false
            showQuestion = true
            showBuffer = false
            shuffleAnswers()
            startQuestionTimer()
        } else {
            // Quiz is complete
            showQuestion = false
        }
    }
    
    private func shuffleAnswers() {
        var all = [currentQuestion.correctAnswer] + currentQuestion.incorrectAnswers
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
        incorrectAnswers: ["Nashville", "Knoxville", "Chattanooga"],
    ),
    Question(
        questionId: "2",
        text: "What year was Vanderbilt University founded?",
        category: "History",
        difficulty: "Medium",
        earningValue: 10,
        correctAnswer: "1875",
        incorrectAnswers: ["1873", "1879", "1881"],
    )
]

#Preview {
    
    
    QuestionOverlayView(questions: sampleQuestions, sessionId: "test-session")
}
