/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract Ejercicio1 {
    string greeting;
    address owner;

    constructor(){
        //1. Inicializar una variable greeting  de tipo string con la frase: “Hello Ethereum”
        greeting = "Hello Ethereum";
        owner = msg.sender;
    }

    //5. Crear dos eventos.
    event GreetingChange(string oldGreeting, string newGreeting);
    event OwnerChange(address oldOwner, address newOwner);

    //2. Solo puede ser modificada por el owner (utilizar un modifier)
    modifier validarOwner { 
        require(owner != msg.sender, "No eres el owner del contrato");
        _;
    }
    //3. Utilizar otro modifier para confirmar que la address sea válida o distinta de cero.
    modifier validarAddress() {
         require(owner == address(0), "El owner no es valido . Tiene un valor de 0 ");
        _;
    }

    //2. Solo puede ser modificada por el owner (utilizar un modifier)
    function modificarVariable(string memory _newGreeting)  external validarOwner validarAddress{
       //5.1 Cuando se cambia el greeting indicando el address, el saludo original y el nuevo saludo
       emit GreetingChange(greeting, _newGreeting);
        greeting = _newGreeting;
          
    }
     
    //4. Debe existir una función que permita cambiar de owner pero sólo debe ser ejecutable por el owner.
    function modificarOwner(address _newOwner) external  validarOwner{
        //5.2 Cuando se cambia el owner, indican el owner original y el nuevo owner.
         emit OwnerChange(owner, _newOwner);
         owner = _newOwner;
    }

}