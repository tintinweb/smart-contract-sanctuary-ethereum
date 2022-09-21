// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ICurveRegistry.sol";

interface ICurveAddressProvider {
    function get_registry() external view returns (ICurveRegistry);

    function get_address(uint256 i) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ICurveFactoryRegistry {
    function get_n_coins(address lp) external view returns (uint256);

    function get_coins(address pool) external view returns (address[4] memory);

    function get_meta_n_coins(address pool) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ICurvePool {
    function get_virtual_price() external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ICurveRegistry {
    function get_n_coins(address lp) external view returns (uint256);

    function get_coins(address pool) external view returns (address[8] memory);

    function get_underlying_coins(address pool) external view returns (address[8] memory);

    function get_pool_from_lp_token(address lp) external view returns (address);

    function is_meta(address pool) external view returns (bool);
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

import "../../interfaces/periphery/ITokenOracle.sol";
import "../../interfaces/external/curve/ICurveAddressProvider.sol";
import "../../interfaces/external/curve/ICurveFactoryRegistry.sol";
import "../../interfaces/external/curve/ICurvePool.sol";
import "../../interfaces/periphery/IOracle.sol";

/**
 * @title Oracle for Curve LP tokens (Factory Pools)
 */
contract CurveFactoryLpTokenOracle is ITokenOracle {
    /// @dev Same address for all chains
    ICurveAddressProvider public constant addressProvider =
        ICurveAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383);

    /// @notice Factory Registry contract
    ICurveFactoryRegistry public immutable registry;

    /// @notice LP token => coins mapping
    mapping(address => address[]) public underlyingTokens;

    /// @notice Emitted when a token is registered
    event LpRegistered(address indexed lpToken);

    constructor() {
        registry = ICurveFactoryRegistry(addressProvider.get_address(3));
    }

    /// @inheritdoc ITokenOracle
    function getPriceInUsd(address lpToken_) public view override returns (uint256 _priceInUsd) {
        address[] memory _tokens = underlyingTokens[lpToken_];
        require(_tokens.length > 0, "lp-is-not-registered");
        uint256 _min = type(uint256).max;
        uint256 _n = _tokens.length;

        for (uint256 i; i < _n; i++) {
            uint256 _price = IOracle(msg.sender).getPriceInUsd(_tokens[i]);
            if (_price < _min) _min = _price;
        }

        require(_min < type(uint256).max, "no-min-underlying-price-found");
        require(_min > 0, "invalid-min-price");

        return (_min * ICurvePool(lpToken_).get_virtual_price()) / 1e18;
    }

    /// @notice Register LP token data
    /// @dev For factory pools, the LP and pool addresses are the same
    function registerLp(address lpToken_) external {
        require(underlyingTokens[lpToken_].length == 0, "lp-already-registered");

        uint256 _n = registry.get_n_coins(lpToken_);
        if (_n == 0) (_n, ) = registry.get_meta_n_coins(lpToken_);
        require(_n > 0, "invalid-factory-lp-token");

        address[4] memory _tokens = registry.get_coins(lpToken_);
        for (uint256 i; i < _n; i++) {
            underlyingTokens[lpToken_].push(_tokens[i]);
        }

        emit LpRegistered(lpToken_);
    }
}