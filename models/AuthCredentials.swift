import Foundation

struct AuthCredentials {

    let username: String

    let password: String

    init(username: String, password: String) {
        self.username = username.trimmingCharacters(in: .whitespacesAndNewlines)
        self.password = password
    }

    var isValid: Bool {
        !username.isEmpty && !password.isEmpty && password.count >= 6
    }

    var isEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: username)
    }
}

struct RegistrationCredentials {

    let username: String

    let email: String

    let password: String

    let confirmPassword: String

    let fullName: String?

    init(
        username: String,
        email: String,
        password: String,
        confirmPassword: String,
        fullName: String? = nil
    ) {
        self.username = username.trimmingCharacters(in: .whitespacesAndNewlines)
        self.email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.password = password
        self.confirmPassword = confirmPassword
        self.fullName = fullName?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    enum ValidationError: LocalizedError {
        case emptyUsername
        case usernameTooShort
        case emptyEmail
        case invalidEmail
        case emptyPassword
        case passwordTooShort
        case passwordsDoNotMatch
        case usernameContainsInvalidCharacters

        var errorDescription: String? {
            switch self {
            case .emptyUsername:
                return "Имя пользователя не может быть пустым"
            case .usernameTooShort:
                return "Имя пользователя должно содержать минимум 3 символа"
            case .emptyEmail:
                return "Email не может быть пустым"
            case .invalidEmail:
                return "Введите корректный email адрес"
            case .emptyPassword:
                return "Пароль не может быть пустым"
            case .passwordTooShort:
                return "Пароль должен содержать минимум 6 символов"
            case .passwordsDoNotMatch:
                return "Пароли не совпадают"
            case .usernameContainsInvalidCharacters:
                return "Имя пользователя может содержать только буквы, цифры и подчеркивания"
            }
        }
    }

    func validate() -> [ValidationError] {
        var errors: [ValidationError] = []

        if username.isEmpty {
            errors.append(.emptyUsername)
        } else if username.count < 3 {
            errors.append(.usernameTooShort)
        } else if !isValidUsername(username) {
            errors.append(.usernameContainsInvalidCharacters)
        }

        if email.isEmpty {
            errors.append(.emptyEmail)
        } else if !isValidEmail(email) {
            errors.append(.invalidEmail)
        }

        if password.isEmpty {
            errors.append(.emptyPassword)
        } else if password.count < 6 {
            errors.append(.passwordTooShort)
        }

        if password != confirmPassword {
            errors.append(.passwordsDoNotMatch)
        }

        return errors
    }

    var isValid: Bool {
        validate().isEmpty
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func isValidUsername(_ username: String) -> Bool {
        let usernameRegex = "^[a-zA-Z0-9_]+$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: username)
    }
}
