/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV3Factory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

interface IUniswapV3Pool {
    // IUniswapV3PoolImmutables
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    function tickSpacing() external view returns (int24);
    function maxLiquidityPerTick() external view returns (uint128);

    // IUniswapV3PoolState
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    function feeGrowthGlobal0X128() external view returns (uint256);
    function feeGrowthGlobal1X128() external view returns (uint256);
    function protocolFees() external view returns (uint128 token0, uint128 token1);
    function liquidity() external view returns (uint128);
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );
    function tickBitmap(int16 wordPosition) external view returns (uint256);
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );

    // IUniswapV3PoolActions
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;

    // IUniswapV3PoolDerivedState
    // IUniswapV3PoolOwnerActions
    // IUniswapV3PoolEvents
}


contract ToolBox {
    address public constant wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    IUniswapV3Factory public constant swapFactory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    function convertToTargetValueFromPool(IUniswapV3Pool pool, uint256 sourceTokenAmount, address targetAddress) public view returns (uint256) {
        address token0 = pool.token0();
        address token1 = pool.token1();
        uint256 decimal0 = IERC20(token0).decimals();
        uint256 decimal1 = IERC20(token1).decimals();
        (uint256 sqrtPriceX96,,,,,,) = pool.slot0();

        require(token0 == targetAddress || token1 == targetAddress, "one of the pairs must be the targetAddress");
        if (sourceTokenAmount == 0)
            return 0;

        uint256 POWER;
        if (2 ** 192 > sqrtPriceX96 ** 2)
            POWER = 10 ** (log10(sqrtPriceX96 ** 2) - 8);
        else
            POWER = 10 ** (log10(2 ** 192) - 8);

        if (targetAddress == token1)
            if (decimal0 >= decimal1) {
                return sourceTokenAmount
                    * (10 ** decimal0) / (10 ** decimal1)
                    * ((sqrtPriceX96 ** 2) / POWER)
                    / ((2 ** 192) / POWER);
            }
            else
                return sourceTokenAmount
                    * (10 ** decimal0)
                    * ((sqrtPriceX96 ** 2) / POWER)
                    / ((2 ** 192) / POWER)
                    / (10 ** decimal1);
        else 
            if (decimal0 >= decimal1)
                return sourceTokenAmount
                    * ((2 ** 192) / POWER)
                    / ((sqrtPriceX96 ** 2) / POWER)
                    * (10 ** decimal1)
                    / (10 ** decimal0);
            else
                return sourceTokenAmount
                    * ((10 ** decimal1) / (10 ** decimal0))
                    * ((2 ** 192) / POWER)
                    / ((sqrtPriceX96 ** 2) / POWER);
    }

    function getTokenValueInEth(address token, uint256 amount, uint24 fee) external view returns (uint256) {
        IUniswapV3Pool uniEthPool = IUniswapV3Pool(swapFactory.getPool(token, wethAddress, fee));
        return convertToTargetValueFromPool(uniEthPool, amount, wethAddress);
    }

    function getTokenValueInUsdc(address token, uint256 amount, uint24 fee) external view returns (uint256) {
        IUniswapV3Pool uniEthPool = IUniswapV3Pool(swapFactory.getPool(token, wethAddress, fee));
        uint256 ethAmount = convertToTargetValueFromPool(uniEthPool, amount, wethAddress);
        return getEthValueInUsdc(ethAmount, fee);
    }

    function getEthValueInUsdc(uint256 amount, uint24 fee) public view returns (uint256) {
        IUniswapV3Pool ethUsdcPool = IUniswapV3Pool(swapFactory.getPool(usdcAddress, wethAddress, fee));
        if (address(ethUsdcPool) == address(0)){
            return 0;
        }
        return convertToTargetValueFromPool(ethUsdcPool, amount, usdcAddress);
    }

    function log10(uint256 x) private pure returns(uint256) {
        uint8 r=0;
        do {
            x/=10;
            if(0==x)break;
            r++;
        } while (true);
        return r;
    }
}