/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

//SPDX-License-Identifier: ISC
pragma solidity >0.6.0;

contract Storage {
  address payable private owner;
  uint public number;

  constructor() public {
    owner = msg.sender;
  }

  function store(uint num) public {
    number = num;
  }

  function retrieve() public view returns (uint) {
    return number;
  }

  function close() public {
    selfdestruct(owner);
  }
}