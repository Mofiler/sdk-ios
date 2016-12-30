# Mofiler sdk-ios

En este repositorio encontrará tanto el código del SDK como el de 2 aplicaciones de ejemplo, una escrita en ObjectiveC (`MofilerAppObjC`) y otra escrita en Swift (`MofilerAppSwift`)

## Cómo integrar
El SDK de Mofiler se distribuye a través de Carthage, que es inicialmente la forma recomendada de utilizar el framework.


## Instalación via Carthage
Luego de  instalar Carthage, para integrar Mofiler en su proyecto Xcode, especifique la siguiente línea en su Cartfile:

`github "Mofiler/sdk-ios" "develop"`

Ejecutar carthage update va a construir el framework y arrastre el construido `Mofiler.framework` en el proyecto Xcode.

## Instalación manual
Si prefiere no utilizar Carthage, puede integrar Mofiler en su proyecto de forma manual.
Para compilar el SDK de forma manual empezar por clonar el repositorio:

`git clone https://github.com/Mofiler/sdk-ios.git`

Después de haber inicializado el repositorio, añadir Mofiler.xcodeproj como un sub-proyecto para el proyecto de su aplicación, y luego añadir el Mofiler.framework.

## Location

Para acceder a location la aplicación debe agregar al `Info.plist` una key `NSLocationAlwaysUsageDescription` con un value que explique al usuario cómo la aplicación utiliza estos datos.


## Usando el SDK

### SWIFT

1) Agregar el siguiente import
```
import Mofiler
```

2) Agregar a la class que usa MofilerDelegate
```
class AppDelegate: UIResponder, UIApplicationDelegate, MofilerDelegate {
}
```

3) Funcionalidades

```
//Singleton de mofiler
let mof = Mofiler.sharedInstance

//Inicializa mofiler con los campos obligatorios        
mof.initializeWith(appKey: "MY-­APPKEY-­HERE-IOS", appName: "MyIosTestApplication", identity: ["username" : "johndoe"])

//Le asigna el delegate
mof.delegate = self

//Inicializa las demas propiedades que no son obligatorias
mof.url = "mofiler.com"
mof.addIdentity(identity: ["name":"john doe"])
mof.addIdentity(identity: ["email":"john@doe.com"])
mof.useLocation = false
mof.useVerboseContext = true
        
//Inyecta valores por clave-valor o clave-valor y fecha de caducidad
mof.injectValue(newValue: ["mykey1":"myvalue1"])
mof.injectValue(newValue: ["mykey2":"myvalue2"], expirationDateInMilliseconds: 100000000.0)
mof.injectValue(newValue: ["mykey3":"myvalue3"])
mof.injectValue(newValue: ["mykey4":"myvalue4"], expirationDateInMilliseconds: 100000000.0)
mof.injectValue(newValue: ["mykey5":"myvalue5"])
mof.injectValue(newValue: ["mykey6":"myvalue6"])
mof.injectValue(newValue: ["mykey7":"myvalue7"], expirationDateInMilliseconds: 100000000.0)
mof.injectValue(newValue: ["mykey8":"myvalue8"])
mof.injectValue(newValue: ["mykey9":"myvalue9"])
mof.injectValue(newValue: ["mykey10":"myvalue10"])
mof.injectValue(newValue: ["mykey11":"myvalue11"])
mof.injectValue(newValue: ["mykey12":"myvalue12"])
mof.injectValue(newValue: ["mykey13":"myvalue13"])
        
//Fuerza el envio de datos alojados        
mof.flushDataToMofiler()


//1. Obtiene un valor particular. (Responde en la func del delegate)
mof.getValue(key: "mykey1", identityKey: "username", identityValue: "johndoe")
        
//2. Obtiene un valor particular. (Responde en el closure)
mof.getValue(key: "mykey1", identityKey: "username", identityValue: "johndoe") { (result, error) in
            print(result)
}
    
//# MARK: - MofilerDelegate
//Funciones del delegate

//Recibe la respuesta del getValue
public func responseValue(key: String, identityKey: String, identityValue: String, value: [String : Any]) {
        print(value)
}
    
//Recibe si ocurrio un error
func errorOcurred(error: String, userInfo: [String : String]) {
print(error)
}
```

#### Manejo de sesiones e identidad

El SDK maneja sesiones de manera transparente, pero es importante notar que las identities utilizadas corresponden a un usuario en particular y por lo tanto deben ser re-inicializadas cada vez que un usuario hace login a la aplicacion. La práctica recomendada es la siguiente:

1. llamar a `mof.initializeWith(appKey: "MY-­APPKEY-­HERE-IOS", appName: "MyIosTestApplication", identity: ["username" : "johndoe"])` cada vez que se hace un login de un usuario
2. llamar a `mof.flushDataToMofiler()` cada vez que se hace un logout, para forzar liberar todo registro de algo que haya sido realizado por el usuario anteriormente logeado.


### OBJECTIVE C

1) Agregar el siguiente import
```
#import <Mofiler/Mofiler-Swift.h>
```

2) Agregar a la class que usa MofilerDelegate
```
@interface AppDelegate () <MofilerDelegate>
```

3) Funcionalidades
```
//Singleton de mofiler
Mofiler* mof = [Mofiler sharedInstance];
    
//Inicializa mofiler con los campos obligatorios        
[mof initializeWithAppKey:@"MY-APPKEY-HERE-IOS" appName:@"MyIosTestApplication" identity:@{@"username":@"johndoe"}];

//Le asigna el delegate    
mof.delegate = self;
    
//Inicializa las demas propiedades que no son obligatorias
mof.url = @"mofiler.com";
[mof addIdentityWithIdentity:@{@"name":@"john doe"}];
[mof addIdentityWithIdentity:@{@"email":@"john@doe.com"}];
mof.useLocation = false;
mof.useVerboseContext = true;
    
//Inyecta valores por clave-valor o clave-valor y fecha de caducidad
[mof injectValueWithNewValue:@{@"mykey1":@"myvalue1"} expirationDateInMilliseconds:nil];
    [mof injectValueWithNewValue:@{@"mykey2":@"myvalue2"} expirationDateInMilliseconds:[NSNumber numberWithFloat:100000000.0]];
    [mof injectValueWithNewValue:@{@"mykey3":@"myvalue3"} expirationDateInMilliseconds:nil];
    [mof injectValueWithNewValue:@{@"mykey4":@"myvalue4"} expirationDateInMilliseconds:[NSNumber numberWithFloat:100000000.0]];
    [mof injectValueWithNewValue:@{@"mykey5":@"myvalue5"} expirationDateInMilliseconds:nil];
    [mof injectValueWithNewValue:@{@"mykey6":@"myvalue6"} expirationDateInMilliseconds:nil];
    [mof injectValueWithNewValue:@{@"mykey7":@"myvalue7"} expirationDateInMilliseconds:[NSNumber numberWithFloat:100000000.0]];
    [mof injectValueWithNewValue:@{@"mykey8":@"myvalue8"} expirationDateInMilliseconds:nil];
    [mof injectValueWithNewValue:@{@"mykey9":@"myvalue9"} expirationDateInMilliseconds:nil];
    [mof injectValueWithNewValue:@{@"mykey10":@"myvalue10"} expirationDateInMilliseconds:nil];
    [mof injectValueWithNewValue:@{@"mykey11":@"myvalue11"} expirationDateInMilliseconds:nil];
    [mof injectValueWithNewValue:@{@"mykey12":@"myvalue12"} expirationDateInMilliseconds:nil];
    [mof injectValueWithNewValue:@{@"mykey13":@"myvalue13"} expirationDateInMilliseconds:nil];


//Fuerza el envio de datos alojados        
[mof flushDataToMofiler];

//1. Obtiene un valor particular. (Responde en la func del delegate)    
[mof getValueWithKey:@"mykey1" identityKey:@"username" identityValue:@"johndoe"];

//2. Obtiene un valor particular. (Responde en el closure)
[mof getValueWithKey:@"mykey1" identityKey:@"username" identityValue:@"johndoe" callback:^(id resutl, id error) {
        NSLog(@"%@", resutl);
}];

//# MARK: - MofilerDelegate
//Funciones del delegate

//Recibe la respuesta del getValue
- (void) responseValueWithKey:(NSString *)key identityKey:(NSString *)identityKey identityValue:(NSString *)identityValue value:(NSDictionary<NSString *,id> *)value {
    NSLog(@"%@", value);
}


//Recibe si ocurrio un error
- (void) errorOcurredWithError:(NSString *)error userInfo:(NSDictionary<NSString *,NSString *> *)userInfo {
    NSLog(@"%@", error);
}
```

