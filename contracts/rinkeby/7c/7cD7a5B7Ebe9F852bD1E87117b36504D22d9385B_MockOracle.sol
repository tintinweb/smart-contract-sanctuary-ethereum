// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IOracle.sol";

contract MockOracle is IOracle {

    mapping(address => uint256) public prices;

    function setPrice(address token, uint256 price) public {
        prices[token] = price;
    }

    function getPrice(address token) public override view returns (uint256) {
        return prices[token];
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IOracle {
    // Get the price of the currency_id.
    // Returns the price.
    function getPrice(address token) external view returns (uint256);
}