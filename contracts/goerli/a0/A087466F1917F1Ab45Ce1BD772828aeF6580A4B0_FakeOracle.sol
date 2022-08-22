// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

import "../Interfaces/IOracle.sol";

contract FakeOracle is IOracle {
    int256 public currentPrice;
    constructor(int256 _currentPrice) {
        currentPrice = _currentPrice;
    }

    function getCurrentPrice() external view returns(int256) {
        return currentPrice;
    }

    function setCurrentPrice(int256 newPrice) external {
        currentPrice = newPrice;
    }

    function decimals() external pure returns(uint256) {
        return 8;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

/**
 * @dev we will decide later on the format of the oracle
 *  for now it is as simple as it can get
 */
interface IOracle {
    function getCurrentPrice() external view returns (int256);

}