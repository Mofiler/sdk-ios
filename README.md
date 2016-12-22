# Mofiler sdk-ios

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


