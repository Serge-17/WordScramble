//
//  ContentView.swift
//  WordScramble
//
//  Created by Serge Eliseev on 9/19/24.
//

import SwiftUI

// Основное представление приложения Word Scramble
struct ContentView: View {
    // Переменные состояния для хранения использованных слов, корневого слова и нового слова
    @State private var usedWords = [String]()
    @State private var rootWord = ""
    @State private var newWord = ""
    
    // Переменные состояния для обработки ошибок
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    
    @State private var letterWordsCount = 0
    
    var body: some View {
        NavigationStack {
            List {
                // Секция для ввода пользователя
                Section {
                    TextField("Введите ваше слово", text: $newWord)
                        .textInputAutocapitalization(.never) // Отключает автоматическую капитализацию ввода
                }
                
                // Секция для отображения использованных слов
                Section {
                    ForEach(usedWords, id: \.self) { word in
                        HStack {
                            Image(systemName: "\(word.count).circle") // Отображает круг с количеством букв в слове
                            Text(word) // Отображает использованное слово
                        }
                    }
                }
               
                Section ("Общая статистика по игре:") {
                    VStack{
                        Text("Угадано слов: \(usedWords.count)")
                        Text("Угадано букв: \(letterWordsCount)")
                    }
                }
                
            }
            .navigationTitle(rootWord) // Устанавливает заголовок навигации на корневое слово
            .onSubmit(addNewWord) // Вызывает функцию addNewWord при отправке ввода пользователем
            .onAppear(perform: startGame) // Начинает новую игру при появлении представления
            .alert(errorTitle, isPresented: $showingError) { // Отображает предупреждение об ошибках
                Button("OK") { } // Кнопка для закрытия предупреждения
            } message: {
                Text(errorMessage) // Отображает сообщение об ошибке
            }
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Restart game") {
                        startGame()
                    }
                }
            }
        }
        
    }
    
    // Функция для добавления нового слова, введенного пользователем
    func addNewWord() {
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) // Нормализует ввод
        
        guard isMoreThreeLetters(word: answer) else { // Проверяет, является слово более 3 букв
            wordError(title: "Слово короткое", message: "Слово не может быть короче 3 букв!")
            return
        }
        
        guard isNotNewWord(word: answer) else { // Проверяет, является ли слово действительным английским словом
            wordError(title: "Слова совподают", message: "Слово не может  являются просто нашим начальным словом!")
            return
        }
        
        guard answer.count > 0 else { return } // Проверяет, что ввод не пустой
        
        guard isOriginal(word: answer) else { // Проверяет, было ли слово уже использовано
            wordError(title: "Слово уже использовано", message: "Будьте более оригинальны!")
            return
        }
        
        guard isPossible(word: answer) else { // Проверяет, можно ли составить слово из корневого слова
            wordError(title: "Слово невозможно", message: "Вы не можете составить это слово из '\(rootWord)'!")
            return
        }

        guard isReal(word: answer) else { // Проверяет, является ли слово действительным английским словом
            wordError(title: "Слово не распознано", message: "Вы не можете просто их придумать!")
            return
        }

        withAnimation {
            usedWords.insert(answer, at: 0) // Добавляет новое действительное слово в список использованных слов с анимацией
        }
        
        letterWordsCount += answer.count
        
        newWord = ""
        // Очищает поле ввода после отправки
        

    }
    
    // Функция для начала новой игры путем загрузки случайного корневого слова из текстового файла
    func startGame() {
        if let startWorld = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWord = try? String(contentsOf: startWorld) {
                let allWords = startWord.components(separatedBy: "\n") // Разделяет слова по переносам строк
                rootWord = allWords.randomElement() ?? "silkworm" // Выбирает случайное корневое слово или по умолчанию "silkworm"
                return
            }
        }
        
        fatalError("Не удалось загрузить start.txt из пакета.") // Ошибка при загрузке файла приводит к аварийному завершению программы
    }
    
    // Функция для проверки, что введенное слово еще не использовалось ранее
    func isOriginal(word: String) -> Bool {
        !usedWords.contains(word)
    }
    
    
    // Функция для проверки, что введенное слово можно составить из букв корневого слова
    func isPossible(word: String) -> Bool {
        var tempWord = rootWord
        
        for letter in word {
            if let pos = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: pos) // Удаляет букву из tempWord, если она найдена
            } else {
                return false // Возвращает false, если буква не найдена в tempWord
            }
        }
        return true // Возвращает true, если все буквы учтены
    }
    
    // Функция для проверки, что введенное слово является действительным английским словом с использованием UITextChecker для проверки правописания
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")

        return misspelledRange.location == NSNotFound // Возвращает true, если нет ошибок правописания
    }
    
    // Функция для обработки ошибок путем установки заголовка и сообщения об ошибке и отображения предупреждения
    func wordError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showingError = true // Активирует отображение предупреждения установкой showingError в true
    }

    // Функция для проверки, что введенное слово не короче трех букв
    func isMoreThreeLetters(word: String) -> Bool {
        if word.count > 2 {
             return true // Возвращает true, если буква в слове более 3
            } else {
                return false // Возвращает false, если буква в слове менее 3
            }

    }
    
    // Функция для проверки, что введенное слово еще не использовалось ранее
    func isNotNewWord(word: String) -> Bool {
        if word == rootWord {
            return false //Возвращает false, является начальным словом.
            } else {
                return true //Возвращает true,не является начальным словом.
            }
    }
    


}

// Провайдер предварительного просмотра для SwiftUI
#Preview {
    ContentView()
}




//Разместите где-нибудь текстовое представление, чтобы вы могли отслеживать и показывать оценку игрока за данное корневое слово. Способ подсчета очков зависит от вас, но что-то, связанное с количеством слов и их количеством букв, было бы разумно.
