## CloudPayments SDK for iOS 

CloudPayments SDK позволяет интегрировать прием платежей в мобильные приложения для платформы iOS.

### Требования
Для работы CloudPayments SDK необходим iOS версии 15.0 и выше.

### Подключение
Для подключения SDK вы можете использовать Swift Package Manager или CocoaPods.

* Для подключения через Swift Package Manager используйте меню File -> Add Package Dependencies, найдите SDK используя Package URL - https://gitpub.cloudpayments.ru/integrations/sdk/cloudpayments-ios и добавьте зависимость в проект.
* Для подключения через CocoaPods добавьте в файл Podfile зависимости:

```
pod 'Cloudpayments', :git =>  "https://gitpub.cloudpayments.ru/integrations/sdk/cloudpayments-ios", :branch => "master"
pod 'CloudpaymentsNetworking', :git =>  "https://gitpub.cloudpayments.ru/integrations/sdk/cloudpayments-ios", :branch => "master"
```

### Структура проекта:

* **demo** - Пример реализации приложения с использованием SDK
* **sdk** - Исходный код SDK

### Возможности CloudPayments SDK:

Вы можете использовать SDK одним из трех способов: 
* использовать стандартную платежную форму Cloudpayments
* реализовать свою платежную форму с использованием функций CloudpaymentsApi без вашего сервера
* реализовать свою платежную форму, сформировать криптограмму и отправить ее на свой сервер

### Использование стандартной платёжной формы от CloudPayments:

1. Cоздайте объект PaymentDataPayer и проинициализируйте его, затем создайте объект PaymentData передайте в него объект PaymentDataPayer, сумму платежа, валюту и дополнительные данные. Если хотите иметь возможность оплаты с помощью Apple Pay, передайте также Apple pay merchant id.

```
//содержимое позиций чека
let item = Receipt.Item(
            label: descript,
            price: 300.0,
            quantity: 3.0,
            amount: 900.0,
            vat: 20,
            method: 0,
            object: 0)
            
//создание объекта чека
let receipt = Receipt(
            items: [item],
            taxationSystem: 0,
            email: email,
            phone: payerPhone,
            isBso: false,
            amounts: Receipt.Amounts(
                electronic: 900.0,
                advancePayment: 0.0,
                credit: 0.0,
                provision: 0.0))
                
//создание объекта подписки
let recurrent = Recurrent(
            interval: "Month",
            period: 1,
            customerReceipt: receipt, 
            amount: 99.99)
            
// Доп. поле, куда передается информация о плательщике. Используйте следующие параметры: FirstName, LastName, MiddleName, Birth, Street, Address, City, Country, Phone, Postcode
let payer = PaymentDataPayer(firstName: "Test", lastName: "Testov", middleName: "Testovich", birth: "1955-02-22", address: "home 6", street: "Testovaya", city: "Moscow", country: "RU", phone: "89991234567", postcode: "12345")
    
// Указывайте дополнительные данные если это необходимо
let jsonData: [String: Any] = ["age":27, "name":"Ivan", "phone":"+79998881122"] // Любые другие данные, которые будут связаны с транзакцией {name: Ivan}

let paymentData = PaymentData() 
    .setAmount(String(totalAmount)) // Cумма платежа в валюте, максимальное количество не нулевых знаков после запятой: 2
    .setCurrency(.ruble) // Валюта
    .setApplePayMerchantId("") // Apple pay merchant id (Необходимо получить у Apple)
    .setDescription("Корзина цветов") // Описание оплаты в свободной форме
    .setAccountId("111") // Обязательный идентификатор пользователя для создания подписки и получения токена
    .setInvoiceId("123") // Номер счета или заказа
    .setEmail("test@cp.ru") // E-mail плательщика, на который будет отправлена квитанция об оплате
    .setPayer(payer) // Информация о плательщике
    .setJsonData(jsonData) // Любые другие данные, которые будут связаны с транзакцией
    .setReceipt(receipt) // Данные для чека
    .setRecurrent(recurrent) // Данные для подписки           
```

1.1. За более подробной информацией по формированию чека, можно обратиться в [документацию CloudKassir](https://developers.cloudkassir.ru/)

2. Создайте объект PaymentConfiguration, передайте в него объект PaymentData и ваш **Public_id** из [личного кабинета Cloudpayments](https://merchant.cloudpayments.ru/). Реализуйте протокол PaymentDelegate, чтобы узнать о завершении платежа

```
let configuration = PaymentConfiguration.init(
    publicId: "", // Ваш Public_id из личного кабинета
    paymentData: paymentData, // Информация о платеже
    delegate: self, // Вывод информации о завершении платежа
    uiDelegate: self, // Вывод информации о UI 
    scanner: nil, // Сканер банковских карт
    emailBehavior: .optional, // Опции отображения поля Email (Optional - пользователь может включить/отключить поле, Required - поле обязательно для заполнения, Hidden - поле не отображается)
    paymentMethodSequence: [.tpay, .card], // Порядок отображения платежных методов, если указать не все методы, тогда первыми буду отображены переданные методы, а остальные будут отображены в порядке по умолчанию
    useDualMessagePayment: true, // Использовать двухстадийную схему проведения платежа, (по умолчанию используется одностадийная схема)
    disableApplePay: true, // Выключить Apple Pay, (по умолчанию Apple Pay включен)
    successRedirectUrl: "", // Ваш deeplink для редиректа из приложения банка после успешной оплаты, (если ничего не передано, по умолчанию используется URL адрес вашего сайта)
    failRedirectUrl: "" //  Ваш deeplink для редиректа из приложения банка после неуспешной оплаты, (если ничего не передано, по умолчанию используется URL адрес вашего сайта)
```
2.1. Для передачи deeplink при использовании CБП,TPay,SberPay,Долями нужно использовать Universal Links:

2.2. Документация от Apple: [Universal Links](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)

2.3. В вашем приложении реализуйте метод application(_:continue:restorationHandler:) в классе вашего AppDelegate для обработки Universal Links

3. Вызовите форму оплаты внутри своего контроллера

```
PaymentOptionsViewController.present(with: configuration, from: self)
```
### Использование T-Pay, SberPay, СБП, Долями в стандартной платежной форме:

1. Включить необходимые опции в [личном кабинете Cloudpayments](https://merchant.cloudpayments.ru/).
2. Если эти опции недоступны, обратитесь к курирующему вас менеджеру.

### Использование вашей платежной формы с использованием функций CloudPaymentsApi:

* **Для использования нового формата криптограммы:**

1. Получите **publicKey** и **keyVersion** с данного [API](https://api.cloudpayments.ru/payments/publickey)
2. Полученные **publicKey** и **keyVersion** передайте в метод создания криптограммы.

3. Cоздайте криптограмму карточных данных

```
// Обязательно проверяйте входящие данные карты (номер, срок действия и cvc код) на корректность, иначе метод создания криптограммы вернет nil.
let cardCryptogramPacket = Card.makeCardCryptogramPacket(cardNumber: cardNumber, expDate: expDate, cvv: cvv, merchantPublicID: "Ваш Public_id", publicKey: "Полученный публичный ключ", keyVersion: "Полученная версия ключа")
```

4. Выполните запрос на проведения платежа (см. [документацию по API](https://developers.cloudpayments.ru/#oplata-po-kriptogramme)).

5. Если необходимо, покажите 3DS форму для подтверждения платежа

```
let data = ThreeDsData.init(transactionId: transactionId, paReq: paReq, acsUrl: acsUrl)
let threeDsProcessor = ThreeDsProcessor()
threeDsProcessor.make3DSPayment(with: data, delegate: self)
```

6. Для получения формы 3DS и получения результатов прохождения 3DS аутентификации реализуйте протокол ThreeDsDelegate.

```
extension CheckoutViewController: ThreeDsDelegate {
    // Вы получаете объект WKWebView, который сами показываете нужным вам способом и в нужном вам месте
    func willPresentWebView(_ webView: WKWebView) {
        self.showThreeDsForm(webView)
    }

    // Для завершения оплаты в выполните метод post3ds CloudpaymentsApi. 
    // threeDsCallbackId - идентификатор, полученный в ответ на запрос на проведение платежа
    func onAuthotizationCompleted(with md: String, paRes: String) {
        hideThreeDs()
        post3ds(transactionId: md, paRes: paRes, threeDsCallbackId: threeDsCallbackId)
    }

    func onAuthorizationFailed(with html: String) {
        hideThreeDs()
        print("error: \(html)")
    }
}
```

### История обновлений:

#### 2.0.0 

* Новый дизайн, новые возможности, добавлены новые способы оплаты, добавлена возможность изменять порядок отображения способов оплаты

#### 1.6.0
* Выполнен переход на новое API (только для стандартной формы)

#### 1.5.18
* Обновлены схемы для SberPay, исправлена передача параметров startDate и vat

#### 1.5.17
* Исправлены делегаты paymentFormWillHide и paymentFormDidHide

#### 1.5.16
* Добавлена возможность интеграции через Swift Package Manager

#### 1.5.15
* Добавлены объекты для создания чека и подписки

#### 1.5.14
* Исправлена проблема с логотипом TPay

#### 1.5.13
* Выполнена доработка для SberPay

#### 1.5.12
* Повышена надежность

#### 1.5.11
* Удален параметр ipAddress

#### 1.5.10
* Исправлена проблема при оплате по Tpay и открытие приложения Т-банк

#### 1.5.9
* Исправлена проблема при оплате по СБП

#### 1.5.8
* Исправлена проблема при оплате по Tpay и SberPay

#### 1.5.7
* Обновлен дизайн TPay
* Добавлен параметр showResultScreen

#### 1.5.6
* Добавлен режим запуска SDK SberPay
* Добавлен Privacy Manifest

#### 1.5.5
* Добавлен режим запуска SDK СБП

#### 1.5.4
* Добавлен поиск по списку банков при оплате по СБП

* Добавлена расшифрока некоторых причин отказа в проведении платежа

* Повышена надежность

#### 1.5.2
* Улучшена валидация

* Повышена надежность

#### 1.5.1
* Добавлен режим запуска SDK TPay

* Добавлена возможность педедать deeplink для перехода из приложения T-банк после оплаты

* Отключен YandexPay

#### 1.5.0
* Повышена надежность

#### 1.4.2
* Обновлен YandexPay SDK

* Исправлена передача email при оплате через YandexPay 

#### 1.4.1
* Исправлена передача accountId при оплате через СБП
 
* Отключена переадресация на сайт эквайера из приложения банка после оплаты через СБП

#### 1.4.0
* Добавлен новый способ оплаты: оплата через СБП (см. документацию для получения более подробной информации: https://gitpub.cloudpayments.ru/integrations/sdk/cloudpayments-ios/-/blob/master/README.md)

* Оптимизировано получение параметров шлюза и проверка доступности способов оплаты: теперь экран способов оплаты появляется сразу со всеми подключенными и доступными способами оплаты

* Оптимизирован интерфейс окна Выбор способов оплаты, теперь он работает плавнее

* Добавлена проверка интерент соединения во время запука SDK, теперь пользователь не пройдет дальше по сценарию оплаты если сервер не доступен

* Внесено значительное количество небольших исправлений и улучшений


### Поддержка

По возникающим вопросам технического характера обращайтесь на support@cp.ru
