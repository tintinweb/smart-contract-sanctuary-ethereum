// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IShop {
    function buy() external;

    function isSold() external view returns (bool);

    function price() external view returns (uint256);
}

contract Buyer {
    function price() external view returns (uint256) {
        bool isSold = IShop(msg.sender).isSold();
        uint256 askedPrice = IShop(msg.sender).price();

        if (!isSold) {
            return askedPrice;
        }

        return 0;
    }

    function buyFromShop(address _shopAddr) public {
        IShop(_shopAddr).buy();
    }
}