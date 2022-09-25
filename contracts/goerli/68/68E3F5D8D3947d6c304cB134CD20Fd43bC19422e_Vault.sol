/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

contract Vault {
  address private owner;

  mapping (address => bool) public operators;

  constructor() public {
    owner = msg.sender;
  }

  // Модификатор владельца
  modifier OnlyOwner() {
    require(owner == msg.sender, 'Permission denied');
    _;
  }

  // Модификатор оператора
  modifier OnlyOperator() {
    require(!operators[msg.sender], 'Permission denied');
    _;
  }

  // Сменить владельца
  function changeOwner(address newOwner) public OnlyOwner {
    require(!operators[msg.sender], 'New owner must be operator first');
    owner = newOwner;
  }

  // Добавить оператора
  function addOperator(address operator) public OnlyOwner {
    operators[operator] = true;
  }

  // Удалить оператора
  function removeOperator(address operator) public OnlyOwner {
    delete operators[operator];
  }
/* 
  function callSwap(address router, bytes memory data) public OnlyOperator {
    return router.call(data);
  } */
}