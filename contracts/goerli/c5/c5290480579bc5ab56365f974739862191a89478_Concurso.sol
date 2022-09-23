/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Concurso {
  address public owner;

  // mapa que relaciona direccion con cantidad depositada
  mapping (address => uint) public balanceOf;
  
  // cantidad que ha sido depositada
  uint public deposited;

  // el creador del contrato se establece como duenio
  constructor() {
    owner = msg.sender;
  }

  // cuando usemos 'onlyOwner' se verificara que la operacion este siendo realizada por el creador del contrato
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  // 'payable' permite que el contrato pueda recibir transferencias
  function deposit() public payable {
    // mas adelante agregaremos verificaciones aqui

    balanceOf[msg.sender] += msg.value;
    deposited += msg.value;
  }

  function getBalanceOf(address _user) public view returns (uint balance) {
    return balanceOf[_user];
  }

  function transfer(address _to, uint _value) public {
    // mas adelante agregaremos verificaciones aqui

    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
  }

  function withdraw(uint _ammount) public onlyOwner {
    require(_ammount <= deposited);
    deposited -= _ammount;
    payable(msg.sender).transfer(_ammount);
  }
}