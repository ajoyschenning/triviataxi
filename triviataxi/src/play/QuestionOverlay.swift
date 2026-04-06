//
//  QuestionOverlay.swift
//  triviataxi
//

import SwiftUI


struct QuestionOverlayView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) var dismiss
    
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
    @State private var lastAnswerCorrect: Bool? = nil
    @State private var showEndSummary = false
    @State private var lastEarningValue: Int = 0
    @State private var lastCorrectAnswer: String = ""
    @State private var hintsUsed: Int = 0
    @State private var sessionEarningsSpent: Int = 0
    @State private var crossedOutAnswers: Set<String> = []
    @State private var hintUsedThisQuestion: Bool = false
    // @State private var questionsAnswered = 0

    
    
    
    let questions: [Question]
    let destinationId: String
    let cityName: String
    let routeLength: String

    
    var currentQuestion: Question {
        questions[currentQuestionIndex]
    }
    
    var hasMoreQuestions: Bool {
        currentQuestionIndex < questions.count - 1
    }
    
    var body: some View {
        if showEndSummary {
            let miles = gameManager.milesTravelled
            let seconds = gameManager.timeElapsed
            EndSummary(cityName: cityName,
                    routeLength: routeLength, 
                    milesTravelled: miles, 
                    timeElapsed: seconds,
                    questionsAnswered: currentQuestionIndex + 1,
                    // questionsAnswered: questionsAnswered,

                    earnings: gameManager.currentEarnings,
                    strikes: gameManager.strikes
                    )
                    .transition(.opacity)
        } else {
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    if showQuestion && !isAnswered && !showBuffer {
//                        questionCount += 1
                        QuestionBoxView(
                            questionNumber: currentQuestionIndex + 1,
                            totalQuestions: questions.count,
                            question: currentQuestion,
                            allAnswers: currentShuffledAnswers,
                            timeRemaining: timeRemaining,
                            selectedAnswer: selectedAnswer,
                            difficultyColor: difficultyColor,
                            timerColor: timerColor,
                            onAnswerSelected: selectAnswer,
                            hintsUsed: $hintsUsed,
                            sessionEarningsSpent: $sessionEarningsSpent,
                            crossedOutAnswers: $crossedOutAnswers,
                            hintUsedThisQuestion: $hintUsedThisQuestion,
                            gameManager: gameManager
                        )
                        
                    }
                    
                    if showBuffer && hasMoreQuestions {
                        BetweenQuestionsView(timeRemaining: betweenQuestionTimer, isCorrect: lastAnswerCorrect, earningValue: lastEarningValue, correctAnswer: lastCorrectAnswer)
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
                gameManager.incrementStrikes()
                showQuestion = false
                showBuffer = true
                
                if gameManager.strikes >= gameManager.maxStrikes {
                    gameManager.endGameLocally(userManager: userManager)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showEndSummary = true
                    }
                } else {
                    startBetweenQuestionTimer()
                }
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
        // questionsAnswered += 1
        
        let isCorrect = answer == currentQuestion.correctAnswer
        lastAnswerCorrect = isCorrect
        lastEarningValue = currentQuestion.earningValue
        lastCorrectAnswer = currentQuestion.correctAnswer
        
        if isCorrect {
            gameManager.addEarnings(earningValue: currentQuestion.earningValue)
        } else {
            gameManager.incrementStrikes()
        }
        
        if gameManager.strikes >= gameManager.maxStrikes {
            gameManager.endGameLocally(userManager: userManager)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showEndSummary = true
            }
        } else if !hasMoreQuestions {
            gameManager.endGameLocally(userManager: userManager)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showEndSummary = true
            }
        } else {
            // Wait 5 seconds before showing next question
            startBetweenQuestionTimer()
        }
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
            lastAnswerCorrect = nil
            crossedOutAnswers = []
            hintUsedThisQuestion = false
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
    let isCrossedOut: Bool
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
                .overlay(
                    isCrossedOut ?
                    VStack {
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(.red)
                    } : nil
                )
        }
        .disabled(isCrossedOut)
    }
    
    private var buttonBackgroundColor: Color {
        if isCrossedOut {
            return Color.gray.opacity(0.2)
        }
        if isSelected {
            return isCorrect ? Color.green.opacity(0.2) : Color.red.opacity(0.2)
        }
        return Color.gray.opacity(0.1)
    }
    
    private var buttonTextColor: Color {
        if isCrossedOut {
            return Color.gray
        }
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
    @Binding var hintsUsed: Int
    @Binding var sessionEarningsSpent: Int
    @Binding var crossedOutAnswers: Set<String>
    @Binding var hintUsedThisQuestion: Bool
    let gameManager: GameManager
    
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
                crossedOutAnswers: crossedOutAnswers,
                onAnswerSelected: onAnswerSelected
            )
            
            HStack(spacing: 20) {
                HintButton(
                    hintsUsed: $hintsUsed,
                    sessionEarningsSpent: $sessionEarningsSpent,
                    question: question,
                    crossedOutAnswers: $crossedOutAnswers,
                    allAnswers: allAnswers,
                    hintUsedThisQuestion: $hintUsedThisQuestion,
                    gameManager: gameManager
                )
                
                Spacer()
                
                TimerCircleView(timeRemaining: timeRemaining, timerColor: timerColor)
            }
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
    let crossedOutAnswers: Set<String>
    let onAnswerSelected: (String) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(answers, id: \.self) { answer in
                AnswerButton(
                    text: answer,
                    isSelected: selectedAnswer == answer,
                    isCorrect: answer == correctAnswer && selectedAnswer != nil,
                    isCrossedOut: crossedOutAnswers.contains(answer),
                    action: {
                        onAnswerSelected(answer)
                    }
                )
            }
        }
    }
}



struct HintButton: View {
    @Binding var hintsUsed: Int
    @Binding var sessionEarningsSpent: Int
    let question: Question
    @Binding var crossedOutAnswers: Set<String>
    let allAnswers: [String]
    @Binding var hintUsedThisQuestion: Bool
    let gameManager: GameManager
    
    @State private var showInsufficientCoins = false
    @State private var showNoMoreHints = false
    @State private var showHintAlreadyUsed = false
    
    private let freeHints = 3
    private let hintCost = 50
    
    private var availableHints: Int {
        let remainingEarnings = gameManager.currentEarnings - sessionEarningsSpent
        let affordablePaidHints = remainingEarnings / hintCost
        return max(0, freeHints + affordablePaidHints - hintsUsed)
    }
    
    private var freeHintsRemaining: Int {
        return max(0, freeHints - hintsUsed)
    }
    
    private var badgeDisplay: String {
        let remainingEarnings = gameManager.currentEarnings - sessionEarningsSpent
        if freeHintsRemaining > 0 {
            return String(freeHintsRemaining)
        } else if remainingEarnings >= hintCost {
            return "50¢"
        } else {
            return "0"
        }
    }
    
    private var canUseHint: Bool {
        // Check if hint already used for this question
        if hintUsedThisQuestion {
            return false
        }
        // Check if there are available answers to cross out
        let availableAnswers = allAnswers.filter { answer in
            !crossedOutAnswers.contains(answer) && answer != question.correctAnswer
        }
        if availableAnswers.isEmpty {
            return false
        }
        // Can use hint if free hints remaining
        if freeHintsRemaining > 0 {
            return true
        }
        // Otherwise, can use hint if have enough coins to buy
        let remainingEarnings = gameManager.currentEarnings - sessionEarningsSpent
        return remainingEarnings >= hintCost
    }
    
    private var costForNextHint: Int {
        if hintsUsed < freeHints {
            return 0
        } else {
            return hintCost
        }
    }
    
    private var sessionEarnings: Int {
        gameManager.currentEarnings - sessionEarningsSpent
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
            
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            
            Button(action: useHint) {
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundColor(canUseHint ? .yellow : .gray)
                    
                    Text(badgeDisplay)
                        .font(.system(size: badgeDisplay == "50¢" ? 8 : 10, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(Color.yellow))
                        .offset(x: 14, y: 14)
                }
            }
            .disabled(!canUseHint)
        }
        .frame(width: 50, height: 50)
        .alert("Insufficient Coins", isPresented: $showInsufficientCoins) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This hint costs \(costForNextHint) coins. You've earned \(sessionEarnings) coins in this session.")
        }
        .alert("No More Hints Available", isPresented: $showNoMoreHints) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You have no more available hints.")
        }
        .alert("Hint Already Used", isPresented: $showHintAlreadyUsed) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You can only use one hint per question.")
        }
    }
    
    private func useHint() {
        // Check if hint already used for this question
        if hintUsedThisQuestion {
            showHintAlreadyUsed = true
            return
        }
        
        // Check if hint is free or costs coins
        let cost = costForNextHint
        
        if cost > 0 && sessionEarnings < cost {
            showInsufficientCoins = true
            return
        }
        
        // Get an incorrect answer to cross out
        let incorrectAnswers = allAnswers.filter { answer in
            !crossedOutAnswers.contains(answer) && answer != question.correctAnswer
        }
        
        guard let answerToCrossOut = incorrectAnswers.randomElement() else {
            showNoMoreHints = true
            return
        }
        
        // Apply hint
        crossedOutAnswers.insert(answerToCrossOut)
        hintsUsed += 1
        hintUsedThisQuestion = true
        
        if cost > 0 {
            sessionEarningsSpent += cost
            gameManager.spendEarningsOnHint(amount: cost)
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
    let isCorrect: Bool?
    let earningValue: Int
    let correctAnswer: String
    
    var body: some View {
        VStack(spacing: 12) {
            if let isCorrect = isCorrect {
                HStack(spacing: 8) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isCorrect ? .green : .red)
                    
                    Text(isCorrect ? "Correct!" : "Incorrect!")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isCorrect ? .green : .red)
                }
                
                if isCorrect {
                    Text("+\(earningValue) coins")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.green)
                } else {
                    Text("Answer: \(correctAnswer)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
            
            
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
        text: "What is the capital of France?",
        category: "Geography",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "Paris",
        incorrectAnswers: ["London", "Berlin", "Madrid"],
    ),
    Question(
        questionId: "2",
        text: "Which planet is known as the Red Planet?",
        category: "Science",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "Mars",
        incorrectAnswers: ["Venus", "Jupiter", "Saturn"],
    ),
    Question(
        questionId: "3",
        text: "What is the largest ocean on Earth?",
        category: "Geography",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "Pacific Ocean",
        incorrectAnswers: ["Atlantic Ocean", "Indian Ocean", "Arctic Ocean"],
    ),
    Question(
        questionId: "4",
        text: "Who wrote 'Romeo and Juliet'?",
        category: "Literature",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "William Shakespeare",
        incorrectAnswers: ["Jane Austen", "Charles Dickens", "Mark Twain"],
    ),
    Question(
        questionId: "5",
        text: "What is the chemical symbol for gold?",
        category: "Science",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "Au",
        incorrectAnswers: ["Ag", "Fe", "Cu"],
    ),
    Question(
        questionId: "6",
        text: "In what year did the Titanic sink?",
        category: "History",
        difficulty: "Medium",
        earningValue: 10,
        correctAnswer: "1912",
        incorrectAnswers: ["1905", "1920", "1898"],
    ),
    Question(
        questionId: "7",
        text: "What is the smallest prime number?",
        category: "Mathematics",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "2",
        incorrectAnswers: ["1", "3", "0"],
    ),
    Question(
        questionId: "8",
        text: "Which country is home to the Eiffel Tower?",
        category: "Geography",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "France",
        incorrectAnswers: ["Italy", "Germany", "Spain"],
    ),
    Question(
        questionId: "9",
        text: "What is the capital of Japan?",
        category: "Geography",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "Tokyo",
        incorrectAnswers: ["Osaka", "Kyoto", "Hiroshima"],
    ),
    Question(
        questionId: "10",
        text: "How many continents are there?",
        category: "Geography",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "7",
        incorrectAnswers: ["5", "6", "8"],
    ),
    Question(
        questionId: "11",
        text: "What is the largest mammal in the world?",
        category: "Biology",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "Blue Whale",
        incorrectAnswers: ["African Elephant", "Giraffe", "Hippopotamus"],
    ),
    Question(
        questionId: "12",
        text: "Who painted the Mona Lisa?",
        category: "Art",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "Leonardo da Vinci",
        incorrectAnswers: ["Michelangelo", "Raphael", "Donatello"],
    ),
    Question(
        questionId: "13",
        text: "What is the speed of light?",
        category: "Physics",
        difficulty: "Medium",
        earningValue: 10,
        correctAnswer: "299,792,458 m/s",
        incorrectAnswers: ["300,000 m/s", "150,000,000 m/s", "999,999 m/s"],
    ),
    Question(
        questionId: "14",
        text: "In what year did World War II end?",
        category: "History",
        difficulty: "Medium",
        earningValue: 10,
        correctAnswer: "1945",
        incorrectAnswers: ["1944", "1946", "1943"],
    ),
    Question(
        questionId: "15",
        text: "What is the capital of Australia?",
        category: "Geography",
        difficulty: "Medium",
        earningValue: 10,
        correctAnswer: "Canberra",
        incorrectAnswers: ["Sydney", "Melbourne", "Brisbane"],
    ),
    Question(
        questionId: "16",
        text: "Which element has the atomic number 1?",
        category: "Chemistry",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "Hydrogen",
        incorrectAnswers: ["Helium", "Lithium", "Carbon"],
    ),
    Question(
        questionId: "17",
        text: "What is the tallest mountain in the world?",
        category: "Geography",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "Mount Everest",
        incorrectAnswers: ["K2", "Kangchenjunga", "Lhotse"],
    ),
    Question(
        questionId: "18",
        text: "How many sides does a hexagon have?",
        category: "Mathematics",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "6",
        incorrectAnswers: ["5", "7", "8"],
    ),
    Question(
        questionId: "19",
        text: "What is the currency of the United Kingdom?",
        category: "Economics",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "British Pound",
        incorrectAnswers: ["Euro", "Dollar", "Franc"],
    ),
    Question(
        questionId: "20",
        text: "Who was the first President of the United States?",
        category: "History",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "George Washington",
        incorrectAnswers: ["Thomas Jefferson", "John Adams", "James Madison"],
    ),
    Question(
        questionId: "21",
        text: "What is the capital of Brazil?",
        category: "Geography",
        difficulty: "Medium",
        earningValue: 10,
        correctAnswer: "Brasília",
        incorrectAnswers: ["Rio de Janeiro", "São Paulo", "Salvador"],
    ),
    Question(
        questionId: "22",
        text: "How many strings does a violin have?",
        category: "Music",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "4",
        incorrectAnswers: ["5", "6", "3"],
    ),
    Question(
        questionId: "23",
        text: "What is the boiling point of water in Celsius?",
        category: "Physics",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "100",
        incorrectAnswers: ["0", "212", "50"],
    ),
    Question(
        questionId: "24",
        text: "Which planet has the most moons?",
        category: "Astronomy",
        difficulty: "Medium",
        earningValue: 10,
        correctAnswer: "Jupiter",
        incorrectAnswers: ["Saturn", "Uranus", "Neptune"],
    ),
    Question(
        questionId: "25",
        text: "What is the only mammal that lays eggs?",
        category: "Biology",
        difficulty: "Medium",
        earningValue: 10,
        correctAnswer: "Platypus",
        incorrectAnswers: ["Echidna", "Bat", "Dolphin"],
    ),
    Question(
        questionId: "26",
        text: "In what year did the Magna Carta get signed?",
        category: "History",
        difficulty: "Hard",
        earningValue: 15,
        correctAnswer: "1215",
        incorrectAnswers: ["1225", "1200", "1260"],
    ),
    Question(
        questionId: "27",
        text: "What is the capital of South Africa?",
        category: "Geography",
        difficulty: "Medium",
        earningValue: 10,
        correctAnswer: "Pretoria",
        incorrectAnswers: ["Johannesburg", "Cape Town", "Durban"],
    ),
    Question(
        questionId: "28",
        text: "How many bones are in the human body?",
        category: "Biology",
        difficulty: "Medium",
        earningValue: 10,
        correctAnswer: "206",
        incorrectAnswers: ["186", "226", "196"],
    ),
    Question(
        questionId: "29",
        text: "What is the smallest country in the world?",
        category: "Geography",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "Vatican City",
        incorrectAnswers: ["Monaco", "Liechtenstein", "San Marino"],
    ),
    Question(
        questionId: "30",
        text: "Who wrote 'The Great Gatsby'?",
        category: "Literature",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "F. Scott Fitzgerald",
        incorrectAnswers: ["Ernest Hemingway", "William Faulkner", "John Steinbeck"],
    ),
    Question(
        questionId: "31",
        text: "What does 'HTTP' stand for?",
        category: "Technology",
        difficulty: "Medium",
        earningValue: 10,
        correctAnswer: "HyperText Transfer Protocol",
        incorrectAnswers: ["Home Transfer Text Protocol", "High Text Transfer Protocol", "Hyper Transmit Text Protocol"],
    ),
    Question(
        questionId: "32",
        text: "In what year did the Berlin Wall fall?",
        category: "History",
        difficulty: "Medium",
        earningValue: 10,
        correctAnswer: "1989",
        incorrectAnswers: ["1987", "1991", "1988"],
    ),
    Question(
        questionId: "33",
        text: "What is the capital of Canada?",
        category: "Geography",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "Ottawa",
        incorrectAnswers: ["Toronto", "Vancouver", "Montreal"],
    ),
    Question(
        questionId: "34",
        text: "Which artist cut off part of his ear?",
        category: "Art",
        difficulty: "Medium",
        earningValue: 10,
        correctAnswer: "Vincent van Gogh",
        incorrectAnswers: ["Pablo Picasso", "Salvador Dalí", "Andy Warhol"],
    ),
    Question(
        questionId: "35",
        text: "What is the deepest ocean trench?",
        category: "Geography",
        difficulty: "Medium",
        earningValue: 10,
        correctAnswer: "Mariana Trench",
        incorrectAnswers: ["Tonga Trench", "Kuril-Kamchatka Trench", "Philippine Trench"],
    ),
    Question(
        questionId: "36",
        text: "How many strings does a guitar have?",
        category: "Music",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "6",
        incorrectAnswers: ["7", "5", "4"],
    ),
    Question(
        questionId: "37",
        text: "What is the capital of India?",
        category: "Geography",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "New Delhi",
        incorrectAnswers: ["Mumbai", "Bangalore", "Kolkata"],
    ),
    Question(
        questionId: "38",
        text: "In what year did the Challenger space shuttle disaster occur?",
        category: "History",
        difficulty: "Hard",
        earningValue: 15,
        correctAnswer: "1986",
        incorrectAnswers: ["1985", "1987", "1984"],
    ),
    Question(
        questionId: "39",
        text: "What is the largest desert in the world?",
        category: "Geography",
        difficulty: "Medium",
        earningValue: 10,
        correctAnswer: "Antarctica",
        incorrectAnswers: ["Sahara", "Arabian", "Kalahari"],
    ),
    Question(
        questionId: "40",
        text: "How many sides does a pentagon have?",
        category: "Mathematics",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "5",
        incorrectAnswers: ["6", "4", "7"],
    ),
    Question(
        questionId: "41",
        text: "What is the capital of Mexico?",
        category: "Geography",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "Mexico City",
        incorrectAnswers: ["Guadalajara", "Cancún", "Monterrey"],
    ),
    Question(
        questionId: "42",
        text: "Who invented the telephone?",
        category: "History",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "Alexander Graham Bell",
        incorrectAnswers: ["Thomas Edison", "Nikola Tesla", "Benjamin Franklin"],
    ),
    Question(
        questionId: "43",
        text: "What is the freezing point of water in Celsius?",
        category: "Physics",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "0",
        incorrectAnswers: ["32", "-40", "100"],
    ),
    Question(
        questionId: "44",
        text: "Which country hosted the 2016 Summer Olympics?",
        category: "Sports",
        difficulty: "Medium",
        earningValue: 10,
        correctAnswer: "Brazil",
        incorrectAnswers: ["China", "Russia", "Great Britain"],
    ),
    Question(
        questionId: "45",
        text: "What is the capital of Egypt?",
        category: "Geography",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "Cairo",
        incorrectAnswers: ["Giza", "Luxor", "Alexandria"],
    ),
    Question(
        questionId: "46",
        text: "How many planets are in our solar system?",
        category: "Astronomy",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "8",
        incorrectAnswers: ["9", "7", "10"],
    ),
    Question(
        questionId: "47",
        text: "What is the capital of Greece?",
        category: "Geography",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "Athens",
        incorrectAnswers: ["Sparta", "Corinth", "Delphi"],
    ),
    Question(
        questionId: "48",
        text: "Who wrote 'Pride and Prejudice'?",
        category: "Literature",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "Jane Austen",
        incorrectAnswers: ["Charlotte Brontë", "Emily Dickinson", "George Eliot"],
    ),
    Question(
        questionId: "49",
        text: "What is the largest country in the world by area?",
        category: "Geography",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "Russia",
        incorrectAnswers: ["Canada", "China", "United States"],
    ),
    Question(
        questionId: "50",
        text: "How many days are there in a leap year?",
        category: "Mathematics",
        difficulty: "Easy",
        earningValue: 5,
        correctAnswer: "366",
        incorrectAnswers: ["365", "364", "367"],
    ),
]

#Preview {
    
//    QuestionOverlayView(questions: sampleQuestions, destinationId: "test-session")
}
