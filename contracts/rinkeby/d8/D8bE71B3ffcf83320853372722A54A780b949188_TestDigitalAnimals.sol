// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IDigitalAnimals.sol";

contract TestDigitalAnimals is IDigitalAnimals {
    mapping(address => uint256) public mints;
    mapping(address => uint256) public balance;

    function setMints(address operator, uint256 mints_, uint256 balance_) public {
        mints[operator] = mints_;
        balance[operator] = balance_;
    }

    function mintedAllSales(address operator) override external view returns (uint256) {
        return mints[operator];
    }

    function balanceOf(address owner) override external view returns (uint256) {
        return balance[owner];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDigitalAnimals {
    function mintedAllSales(address operator) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
}