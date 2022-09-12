// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MintFearless {
  address perpetual;
  uint price;
  bool minted;

  constructor(address _perpetual, uint _price) {
    perpetual = _perpetual;
    price = _price;
  }

  function mint() external {
    require(msg.sender.balance >= price, "Insufficient balance");
    require(minted == false, "Already minted");
    minted = true;
    IPerpetual(perpetual).mint(msg.sender, 2);
  }
}

interface IPerpetual {
  function mint(address to, uint editionNo) external;
}