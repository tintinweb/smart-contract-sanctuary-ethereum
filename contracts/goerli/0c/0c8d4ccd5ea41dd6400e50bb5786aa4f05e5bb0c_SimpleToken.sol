/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

pragma solidity ^0.8.17;
// SPDX-License-Identifier: MIT
contract SimpleToken {
  // The address of the contract owner
  address public owner;

  // The total supply of tokens
  uint256 public totalSupply;

  // The mapping of addresses to their token balances
  mapping (address => uint256) public balances;

  // The constructor sets the contract owner and initializes the total supply
  constructor() public {
    owner = msg.sender;
    totalSupply = 100;
    balances[owner] = totalSupply;
  }

  // The mint() function allows the contract owner to mint new tokens
  // and add them to their balance
  function mint() public {
    require(msg.sender == owner, "Only the owner can mint tokens");
    totalSupply += 1;
    balances[owner] += 1;
  }
}