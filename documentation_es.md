##### Instalación (CocoaPods)
Agrega el pod a tu Podfile
```ruby
pod 'ZeroBounceSDK'
```
y ejecuta
```bash
pod install
```

#### USO
Importa el SDK en tu archivo:
```swift
import ZeroBounceSDK
```

Inicializa el SDK con tu clave de API:
```swift
ZeroBounceSDK.shared.initialize(apiKey: "<TU_CLAVE_DE_API>")
```

#### Ejemplos
Luego puedes utilizar cualquiera de los métodos del SDK, por ejemplo:

* ####### Validar una dirección de correo electrónico
```swift
let email = "<DIRECCIÓN_DE_CORREO>"   // La dirección de correo electrónico que deseas validar
let ipAddress = "127.0.0.1"     // La dirección IP desde la cual se registró el correo electrónico (opcional)

ZeroBounceSDK.shared.validate(email, ipAddress) { result in
    switch result {
    case .success(let response):
        NSLog("validate success response=\(response)")
    case .failure(let error):
        NSLog("validate failure error=\(String(describing: error))")
        switch error as? ZBError {
        case .notInitialized:
            break
        case .decodeError(let messages):
            /// decodeError se utiliza para extraer y decodificar errores y mensajes
            /// cuando no forman parte del objeto de respuesta
            break
        default:
            break
        }
    }
}
```

* ####### Validar hasta 100 direcciones de correo electrónico utilizando Batch Email Validator
```swift
// Las direcciones de correo electrónico que deseas validar
let emails = [
    ["email_address": "<DIRECCIÓN_DE_CORREO_1>"],
    ["email_address": "<DIRECCIÓN_DE_CORREO_2>", "ip_address": "127.0.0.1"]
]

ZeroBounceSDK.shared.validateBatch(emails: emails) { result in
    switch result {
    case .success(let response):
        NSLog("validate success response=\(response)")
    case .failure(let error):
        NSLog("validate failure error=\(String(describing: error))")
    }
}
```

* ####### Verificar cuántos créditos te quedan en tu cuenta
```swift
ZeroBounceSDK.shared.getCredits() { result in
    switch result {
    case .success(let response):
        NSLog("getCredits success response=\(response)")
        let credits = response.credits
    case .failure(let error):
        NSLog("getCredits failure error=\(String(describing: error))")
    }
}
```

* ####### Verificar si tu bandeja de entrada de correo electrónico ha estado activa en los últimos 30, 60, 90, 180, 365, 730 o 1095 días
```swift
ZeroBounceSDK.shared.getActivityData(email: email) { result in
    switch result {
    case .success(let response):
        NSLog("getActivityData success response=\(response)")
    case .failure(let error):
        NSLog("getActivityData failure error=\(String(describing: error))")
    }
}
```

* ####### Verificar el uso de tu API durante un período de tiempo determinado
```swift
let startDate = Date();    // La fecha de inicio desde la cual deseas ver el uso de la API
let endDate = Date();      // La

 fecha de finalización hasta la cual deseas ver el uso de la API

ZeroBounceSDK.shared.getApiUsage(startDate, endDate) { result in
    switch result {
    case .success(let response):
        NSLog("getApiUsage success response=\(response)")
    case .failure(let error):
        NSLog("getApiUsage failure error=\(String(describing: error))")
    }
}
```

* ####### La API sendfile permite enviar un archivo para la validación masiva de correos electrónicos
```swift
let filePath = File("<RUTA_DEL_ARCHIVO>") // El archivo csv o txt
let emailAddressColumn = 3;         // El índice de la columna "email" en el archivo. El índice comienza en 1
let firstNameColumn = 3;            // El índice de la columna "nombre" en el archivo
let lastNameColumn = 3;             // El índice de la columna "apellido" en el archivo
let genderColumn = 3;               // El índice de la columna "género" en el archivo
let ipAddressColumn = 3;            // El índice de la columna "dirección IP" en el archivo
let hasHeaderRow = true;            // Si es `true`, se considera que la primera fila contiene los encabezados de la tabla
let returnUrl = "https://dominio.com/llamada/despues/de/procesar/solicitud";

ZeroBounceSDK.shared.sendFile(
    filePath,
    emailAddressColumn,
    returnUrl,
    firstNameColumn,
    lastNameColumn,
    genderColumn,
    ipAddressColumn,
    hasHeaderRow) { result in
        switch result {
        case .success(let response):
            NSLog("sendFile success response=\(response)")
        case .failure(let error):
            NSLog("sendFile failure error=\(String(describing: error))")
        }
}
```

* ####### La API getfile permite a los usuarios obtener el archivo de resultados de validación del archivo enviado mediante la API sendfile
```swift
let fileId = "<ID_DEL_ARCHIVO>";    // El ID de archivo devuelto al llamar a la API sendfile

ZeroBounceSDK.shared.getfile(fileId) { result in
    switch result {
    case .success(let response):
        NSLog("getfile success response=\(response)")
    case .failure(let error):
        NSLog("getfile failure error=\(String(describing: error))")
    }
}
```

* ####### Verificar el estado de un archivo cargado mediante el método "sendFile"
```swift
let fileId = "<ID_DEL_ARCHIVO>";    // El ID de archivo devuelto al llamar a la API sendfile

ZeroBounceSDK.shared.fileStatus(fileId) { result in
    switch result {
    case .success(let response):
        NSLog("fileStatus success response=\(response)")
    case .failure(let error):
        NSLog("fileStatus failure error=\(String(describing: error))")
    }
}
```

* ####### Elimina el archivo que se envió mediante la API "sendFile". El archivo solo se puede eliminar cuando su estado es _`Complete`_
```swift
let fileId = "<ID_DEL_ARCHIVO>";    // El ID de archivo devuelto al llamar a la API sendfile

ZeroBounceSDK.shared.deleteFile(fileId) { result in
    switch result {
    case .success(let response):
        NSLog("deleteFile success response=\(response)")
    case .failure(let error):
        NSLog("deleteFile failure error=\(String(describing: error))")
    }
}
```

##### API de puntuación de AI
*

####### La API scoringSendFile permite enviar un archivo para la validación masiva de correos electrónicos
```swift
let filePath = File("<RUTA_DEL_ARCHIVO>") // El archivo csv o txt
let emailAddressColumn = 3;         // El índice de la columna "email" en el archivo. El índice comienza en 1
let hasHeaderRow = true;            // Si es `true`, se considera que la primera fila contiene los encabezados de la tabla
let returnUrl = "https://dominio.com/llamada/despues/de/procesar/solicitud";

ZeroBounceSDK.shared.scoringSendFile(
    filePath,
    emailAddressColumn,
    returnUrl,
    hasHeaderRow) { result in
        switch result {
        case .success(let response):
            NSLog("sendFile success response=\(response)")
        case .failure(let error):
            NSLog("sendFile failure error=\(String(describing: error))")
        }
}
```

* ####### La API scoringGetFile permite a los usuarios obtener el archivo de resultados de validación para el archivo enviado mediante la API scoringSendFile
```swift
let fileId = "<ID_DEL_ARCHIVO>";    // El ID de archivo devuelto al llamar a la API scoringSendFile

ZeroBounceSDK.shared.scoringGetfile(fileId) { result in
    switch result {
    case .success(let response):
        NSLog("getfile success response=\(response)")
    case .failure(let error):
        NSLog("getfile failure error=\(String(describing: error))")
    }
}
```

* ####### Verificar el estado de un archivo cargado mediante el método "scoringSendFile"
```swift
let fileId = "<ID_DEL_ARCHIVO>";    // El ID de archivo devuelto al llamar a la API scoringSendFile

ZeroBounceSDK.shared.scoringFileStatus(fileId) { result in
    switch result {
    case .success(let response):
        NSLog("fileStatus success response=\(response)")
    case .failure(let error):
        NSLog("fileStatus failure error=\(String(describing: error))")
    }
}
```

* ####### Elimina el archivo que se envió mediante la API scoring scoringSendFile. El archivo solo se puede eliminar cuando su estado es _`Complete`_
```swift
let fileId = "<ID_DEL_ARCHIVO>";    // El ID de archivo devuelto al llamar a la API scoringSendFile

ZeroBounceSDK.shared.scoringDeleteFile(fileId) { result in
    switch result {
    case .success(let response):
        NSLog("deleteFile success response=\(response)")
    case .failure(let error):
        NSLog("deleteFile failure error=\(String(describing: error))")
    }
}
```

#### Aplicación de ejemplo
- También puedes clonar el repositorio y acceder a la aplicación de ejemplo dentro del proyecto para ver algunos ejemplos. Simplemente inicializa el SDK con tu propia clave de API y descomenta el punto final que deseas probar.

**Puedes utilizar cualquiera de las siguientes direcciones de correo electrónico para probar la API, no se cobran créditos por estas direcciones de correo electrónico de prueba:**
* [disposable@example.com](mailto:disposable@example.com)
* [invalid@example.com](mailto:invalid@example.com)
* [valid@example.com](mailto:valid@example.com)
* [toxic@example.com](mailto:toxic@example.com)
* [donotmail@example.com](mailto:donotmail@example.com)
* [spamtrap@example.com](mailto:spamtrap@example.com)
* [abuse@example.com](mailto:abuse@example.com)
* [unknown@example.com](mailto:unknown@example.com)
* [catch_all@example.com](mailto:catch_all@example.com)
* [antispam_system@example.com](mailto:antispam_system@example.com)
* [does_not_accept_mail@example.com](mailto:does_not_accept_mail@example.com)
* [exception_occurred@example.com](mailto:exception_occurred@example.com)
* [failed_smtp_connection@example.com](mailto:failed_smtp_connection@example.com)
* [failed_syntax_check@example.com](mailto:failed_syntax_check@example.com)
* [forcible_disconnect@example.com](mailto:forcible_disconnect@example.com)
* [global_suppression@example.com](mailto:global_suppression@example.com)
* [greylisted@example.com](mailto:greylisted@example.com)
* [leading_period_removed@example.com](mailto:leading_period_removed@example.com)
* [mail_server_did_not_respond@example.com](mailto:mail_server_did_not_respond@example.com)
* [mail_server_temporary_error@example.com](mailto:mail_server_temporary_error@example.com)
* [mailbox_quota_exceeded@example.com](mailto:mailbox_quota_exceeded@example.com)
* [mailbox_not_found@example.com](mailto:mailbox_not_found@example.com)
* [no_dns_entries@example.com](mailto:no_dns_entries@example.com)
* [possible_trap@example.com](mailto:possible_trap@example.com)
* [possible_typo@example.com](mailto:possible_typo@example.com)
* [role_based@example.com](mailto:role_based@example.com)
* [timeout_exceeded@example.com](mailto:timeout_exceeded@example.com)
* [unroutable_ip_address@example.com](mailto:unroutable_ip_address@example.com)
* [free_email@example.com](mailto:free_email@example.com)
