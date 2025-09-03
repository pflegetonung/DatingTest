import Foundation

/*
 ADAPTY CONFIGURATION GUIDE
 
 Для полной интеграции Adapty в продакшн приложении выполните следующие шаги:
 
 1. РЕГИСТРАЦИЯ В ADAPTY:
    - Зарегистрируйтесь на https://adapty.io
    - Создайте новое приложение в дашборде
    - Получите API ключ (Public SDK key)
 
 2. НАСТРОЙКА ПРОДУКТОВ:
    - В дашборде Adapty создайте продукты с ID:
      * dating_premium_weekly ($0.99 weekly)
      * dating_premium_monthly ($9.99 monthly)  
      * dating_premium_yearly ($99.99 yearly)
    - Настройте access level "premium"
 
 3. PAYWALL КОНФИГУРАЦИЯ:
    - Создайте Paywall с placement_id: "dating_premium"
    - Добавьте созданные продукты в этот paywall
    - Настройте локализацию для языков (en, ru)
 
 4. ЗАМЕНА API КЛЮЧА:
    - В DatingApp.swift замените тестовый ключ на ваш:
      Adapty.activate("your_real_api_key_here")
 
 5. APP STORE CONNECT:
    - Создайте In-App Purchase продукты с теми же ID в App Store Connect
    - Настройте подписки и цены
    - Пройдите процесс ревью
 
 6. ТЕСТИРОВАНИЕ:
    - Используйте Sandbox аккаунты для тестирования
    - Протестируйте все сценарии покупок
    - Проверьте восстановление покупок
 
 ВАЖНО: 
 В текущей реализации используются mock методы для тестирования.
 Для продакшн замените mockPurchase() и mockRestore() на реальные методы:
 - adaptyService.purchaseProduct(product)
 - adaptyService.restorePurchases()
*/

struct AdaptyConfiguration {
    
    // MARK: - API Keys
    
    static let testAPIKey = "public_live_xT9R9Bu8.Yz9grtnKJQNazQcEzQUR" // Текущий тестовый ключ
    static let productionAPIKey = "your_production_api_key_here" // Замените на ваш ключ
    
    // MARK: - Product IDs
    
    enum ProductID: String {
        case weekly = "dating_premium_weekly"
        case monthly = "dating_premium_monthly"
        case yearly = "dating_premium_yearly"
    }
    
    // MARK: - Placement IDs
    
    enum PlacementID: String {
        case premium = "dating_premium"
    }
    
    // MARK: - Access Levels
    
    enum AccessLevel: String {
        case premium = "premium"
    }
    
    // MARK: - Testing Mode
    
    static let isTestingMode = true // Установите false для продакшн
    
    static func getAPIKey() -> String {
        return isTestingMode ? testAPIKey : productionAPIKey
    }
}
