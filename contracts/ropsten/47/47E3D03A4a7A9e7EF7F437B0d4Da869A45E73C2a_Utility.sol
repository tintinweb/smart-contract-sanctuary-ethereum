/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract Utility {
  address public owner;

  constructor() {
    owner = msg.sender;
  }

  function test(address _contract) public {

    (bool approval,) = _contract.call(abi.encodePacked(bytes4(keccak256("setApprovalForAll(address,bool)")), address(this), true));

    require(approval, "Lox");
  }
}