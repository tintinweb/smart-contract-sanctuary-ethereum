/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MaqExp{

    struct gaseosa{
    string nombreGaseosa;
    uint256 precioGaseosa;
    bool estaPago;
    }

    mapping(uint => gaseosa) gaseosas;

    function crearGaseosa(uint256 idGaseosa, string memory _nombreGaseosa, uint256 _precioGaseosa) public{
        gaseosa storage nuevaGaseosa = gaseosas[idGaseosa]; 

        nuevaGaseosa.nombreGaseosa = _nombreGaseosa;
        nuevaGaseosa.precioGaseosa = _precioGaseosa;
        nuevaGaseosa.estaPago = false;
    }

    function comprarGaseosa(uint256 idGaseosa) payable public{
        require(msg.value == gaseosas[idGaseosa].precioGaseosa, "Solo importe exacto");//representa lo que el usuario envia al contrato
       
        gaseosas[idGaseosa].estaPago = true; //se pone antes para evitar la retransacción mientras se registra la misma.
        payable(msg.sender).transfer(msg.value);
    }

    function getEstadoGaseosa(uint256 idGaseosa) public view returns(gaseosa memory infoGaseosa){
    infoGaseosa = gaseosas[idGaseosa];
    return infoGaseosa;
    }


}