// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import './Ownable.sol';

contract CopanionsExchangeEth is Ownable {
  
  constructor() {}

  function withdraw() onlyOwner external {
    payable(_msgSender()).transfer(address(this).balance);
  }
}