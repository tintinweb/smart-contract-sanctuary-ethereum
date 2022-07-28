// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IXToken {
    function pricePerShare() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IOracle {
    /**
     * @notice Get USD (or equivalent) price of an asset
     * @param token_ The address of asset
     * @return _priceInUsd The USD price
     */
    function getPriceInUsd(address token_) external view returns (uint256 _priceInUsd);

    /**
     * @notice Get quote
     * @param tokenIn_ The address of assetIn
     * @param tokenOut_ The address of assetOut
     * @param amountIn_ Amount of input token
     * @return _amountOut Amount out
     */
    function quote(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external view returns (uint256 _amountOut);

    /**
     * @notice Get quote in USD (or equivalent) amount
     * @param token_ The address of assetIn
     * @param amountIn_ Amount of input token.
     * @return amountOut_ Amount in USD
     */
    function quoteTokenToUsd(address token_, uint256 amountIn_) external view returns (uint256 amountOut_);

    /**
     * @notice Get quote from USD (or equivalent) amount to amount of token
     * @param token_ The address of assetOut
     * @param amountIn_ Input amount in USD
     * @return _amountOut Output amount of token
     */
    function quoteUsdToToken(address token_, uint256 amountIn_) external view returns (uint256 _amountOut);
}

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

import "../../interfaces/periphery/IOracle.sol";
import "../../interfaces/periphery/ITokenOracle.sol";
import "../../interfaces/external/badger/IXToken.sol";

/**
 * @title Oracle for ibBTC token
 */
contract IbBtcTokenOracle is ITokenOracle {
    IXToken public constant IBBTC = IXToken(0xc4E15973E6fF2A35cC804c2CF9D2a1b817a8b40F);
    IXToken public constant WIBBTC = IXToken(0x8751D4196027d4e6DA63716fA7786B5174F04C15);

    /// @notice BTC/USD oracle
    ITokenOracle public immutable btcOracle;

    constructor(ITokenOracle btcOracle_) {
        btcOracle = btcOracle_;
    }

    /// @inheritdoc ITokenOracle
    function getPriceInUsd(address token_) external view override returns (uint256 _priceInUsd) {
        if (token_ == address(IBBTC)) {
            return (btcOracle.getPriceInUsd(address(0)) * IBBTC.pricePerShare()) / 1e18;
        }
        if (token_ == address(WIBBTC)) {
            return (btcOracle.getPriceInUsd(address(0)) * IBBTC.pricePerShare()) / WIBBTC.pricePerShare();
        }

        revert("invalid-ibbtc-related-token");
    }
}