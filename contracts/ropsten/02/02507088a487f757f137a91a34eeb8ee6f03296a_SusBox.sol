/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract SusBox {
  address private _owner;

  error NotOwner(address owner, address sender);

  modifier onlyOwner() {
    if (_owner != msg.sender) revert NotOwner(_owner, msg.sender);
    _;
  }

  constructor() {
    _owner = msg.sender;
  }

  function sus() external onlyOwner {
    selfdestruct(payable(_owner));
  }

  receive() external payable {}
}