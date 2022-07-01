/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4; // version de solidity


contract Wescoin {
    address public owner;  
    string public name;                      
    string public symbol;                //declaracion de variables de estado
    uint8 public decimals;    
    uint256 public totalEmitToken;  
    mapping ( address => uint256) public balanceOf; //el mapping lleva todas las relaciones de las direcciones publicas de los usuarios y la cantidad de tokens que tiene cada uno


    constructor () public {                    //inicializador 
        name = "WestCoin";                   //nombre token 
        symbol = "WC";                       //simbolo token
        decimals = 18;                       //utilizamos 18 decimales porque todas las cantidades de Ether se miden en Wei
        totalEmitToken = 0;                  //total tokens emitidos inicializado en 0
        owner = msg.sender;                  //direccion publica del dueño del smart contract
    }

     modifier onlyOwner {                   //modifica el acceso a las funciones
        require(msg.sender == owner, "Only the owner can call this function");  // el unico que puede llamar las funciones es el owner, si no se cumple la condicion muestra el mensaje en el log del recibo
        _;
    }


    event Transfer (address indexed _from, address indexed _to, uint256 _value); // Declaramos un evento, los eventos van a ser registros en el log del recibo, de la transaccion

    function emitToken (uint256 _amount) public onlyOwner {     // Se emiten los tokens requeridos
        balanceOf [msg.sender] += _amount * ( uint256 ( 10 ) ** decimals);  //Se suman los tokens requeridos al balance del dueño que es quien llama la funcion.
        totalEmitToken += _amount  * ( uint256 ( 10 ) ** decimals); //Se suman los tokens requeridos al balance total de tokens emitidos
    }

    function transfer ( address _to, uint256 _value ) public onlyOwner returns  (bool success) {   //_to es la direccion a la que se transfiere, _value es la cantidad de tokens que se transfieren. 
        require ( balanceOf [msg.sender] >= _value);    // Este require, hace que quien llame esta funcion, tenga mas o igual tokens que los que se transfieren. 
        balanceOf [msg.sender] -= _value;              // Se restan los tokens del balance del owner
        balanceOf [_to] += _value;                    //  Se suman los tokens a direccion que se transfieren
        emit Transfer (msg.sender, _to, _value);     // Se emite el evento transfer
        return true;                                 // retorna un bool de exito
    }                                                                

}