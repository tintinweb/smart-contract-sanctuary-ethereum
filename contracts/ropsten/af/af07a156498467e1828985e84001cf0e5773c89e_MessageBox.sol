/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 < 0.9.0;

/// @title A Hello World Example
/// @author Oriol Aguadé
/// @notice Puedes utilizar este contrato para dejar un mensaje públicoo
/// @dev Todas las funciones estan implementadas
contract MessageBox {
    /// @notice Variable global que almacena el mensaje
     string public message;

     /// @notice Constructor, inizializa el mensaje inicial
    /// @dev implementación con texto inicial por defecto
    constructor ()  {
        message = "HELLO WORLD!";
    }

    /// @notice Modifica el mensaje global
    /// @param newMessage  nuevo mensaje
    function setMessage(string memory newMessage) public {
        message = newMessage;
    }
    
    /// @notice Consulta el mensaje global
    /// @return devuelve el mensaje
    function getMessage() public view returns (string memory) {
        return message;
    }
}