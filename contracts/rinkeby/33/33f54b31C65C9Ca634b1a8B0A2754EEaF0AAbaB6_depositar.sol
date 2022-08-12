/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract depositar {

    address[] public addressWhite;
    address user = msg.sender;
    bool validador;
    

    function addAdress(address i) public {
        addressWhite.push(i); 
    }

    function getAdress () public view returns (address[] memory) {
        return addressWhite;
    }

    mapping(address => uint)public balances; //el mapping me permite relacionar el monto depositado con la direccion que ejecuta el contrato 
    //la funcion deposito permite insertar un valor al contrato


function search() public view returns(bool result)
{
  uint i;
    
  for(i = 0; i < addressWhite.length; i++)
  {
    if(addressWhite[i] == user)
    {
      return true;
    }
  }
    
  if(i >= addressWhite.length)
   {
      return false;
    }
}


  modifier autorizado() {
         require(search() == true, 'Not Owner');
         _;
    }


    function deposito () external payable autorizado{
        balances[msg.sender] += msg.value;
    }
    //funcion para ver saldo de la direccion 
    function saldowallet() public view returns (uint){
        uint saldo= msg.sender.balance;
        return (saldo);
    }
    //esta funcion mediante la cual retira el valor del contrato 
    function retirar() public {
        require(balances[msg.sender] > 0, "No tiene saldo");
        //actualiza el balance
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        //envia el valor de vuelta al remitente 
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Error de envio");
    }
}