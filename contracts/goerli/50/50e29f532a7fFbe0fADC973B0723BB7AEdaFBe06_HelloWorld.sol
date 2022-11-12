// Especifica la versión de Solidity, utilizando la versión semántica.
// Más información: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragmma
pragma solidity ^0.5.10;

// Define un contrato llamado `HelloWorld`.
// Un contrato es una colección de funciones y datos (su estado). Una vez desplegado, un contrato reside en una dirección específica en la blockchain de Ethereum. Más información: https://solidity.readthedocs.io/en/v0.5.10/structure-of-a-contract.html
contract HelloWorld {

    // Declara una variable de estado `message` del tipo `string`.
   // Las variables de estado son variables cuyos valores se almacenan permanentemente en el almacenamiento del contrato. La palabra clave `public` hace que las variables sean accesibles desde fuera de un contrato y crea una función que otros contratos o clientes pueden llamar para acceder al valor.
   string public message;

    // Similar a muchos idiomas orientados a objetos basados en clases, un constructor es una función especial que sólo se ejecuta cuando se crea un contrato.
   // Los constructores se utilizan para inicializar los datos del contrato. Más información: https://solidity.readthedocs.io/es/v0.5.10/contracts.html#constructors
    constructor(string memory initMessage) public {

        // Acepta un argumento de cadena `initMessage` y establece el valor en la variable de almacenamiento `message` del contrato).
      message = initMessage;
    }

    // Una función pública que acepta un argumento de cadena y actualiza la variable de almacenamiento `message`.
   function update(string memory newMessage) public {
      message = newMessage;
   }
}