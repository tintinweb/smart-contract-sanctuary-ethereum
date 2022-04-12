// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface Shop {
    function buy() external;
}

contract MyBuyer {
    uint256 public myprice;
    address payable owner;
    Shop public shop;

    constructor(address _address) public {
        owner = msg.sender;
        myprice = 101;
        shop = Shop(_address);
    }

    function attack() public {
        shop.buy();
    }

    function kill() public {
        selfdestruct(owner);
    }

    /*
    function price() public returns (uint256) {
        myprice = myprice - 1;
        return myprice;
    }
    */
    function price() public view returns (uint256) {
        return myprice;
    }
}