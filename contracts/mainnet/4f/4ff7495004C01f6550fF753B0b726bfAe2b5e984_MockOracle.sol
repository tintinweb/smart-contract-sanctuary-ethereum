//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IVspOracle.sol";

/**
 * @title MockOracle contract
 */
contract MockOracle is IVspOracle {
    function update() external {}

    function getPriceInUsd(address token_) external pure returns (uint256 _priceInUsd) {
        return (0.5e18);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @notice The Oracles' interface
 * @dev All `one-oracle` price providers, aggregator and oracle contracts implement this
 */
interface IOracle {
    /**
     * @notice Get USD (or equivalent) price of an asset
     * @param token_ The address of asset
     * @return _priceInUsd The USD price
     */
    function getPriceInUsd(address token_) external view returns (uint256 _priceInUsd);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IOracle.sol";

interface IVspOracle is IOracle {
    /**
     * @notice Update underlying price providers (i.e. UniswapV2-Like)
     */
    function update() external;
}