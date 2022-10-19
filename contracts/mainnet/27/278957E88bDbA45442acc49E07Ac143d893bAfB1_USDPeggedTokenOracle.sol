// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ITokenOracle {
    /**
     * @notice Get USD (or equivalent) price of an asset
     * @param token_ The address of asset
     * @return _priceInUsd The USD price
     */
    function getPriceInUsd(address token_) external view returns (uint256 _priceInUsd);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../interfaces/periphery/ITokenOracle.sol";

/**
 * @title Oracle for USD hard pegged token
 * @dev This oracle shouldn't be used for stable coins! Its purpose is for a specific use case that's the Synth USD token.
 */
contract USDPeggedTokenOracle is ITokenOracle {
    /// @inheritdoc ITokenOracle
    function getPriceInUsd(address) external pure override returns (uint256 _priceInUsd) {
        return 1e18;
    }
}