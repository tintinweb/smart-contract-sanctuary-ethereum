/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
// ERC support


interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


interface IUniswapV3 {

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
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
}

contract ZZZStablilizer {

    IERC20 public zzzToken;
    IERC20 public USDC;
    IUniswapV3 public pool;
    address private owner;

    constructor() {
        owner = msg.sender;
        zzzToken = IERC20(0x89fc72B92cb1E90e6f0D4dFf8460B0d9012efD8e);
        USDC = IERC20(0xE21Dbb332f17B91103e837e2331eB3416A6C006f);
        pool = IUniswapV3(0xbdf29bca874f24ddF499B39762e96A7a82Fa5fbd);
    }

    function pullFunds() external {
        require( msg.sender == owner);
        uint bal0 = zzzToken.balanceOf(address(this));
        uint bal1 = USDC.balanceOf(address(this));
        zzzToken.transfer(msg.sender, bal0);
        USDC.transfer(msg.sender, bal1);
    }

    function stabilize() external returns (int, int) {

        uint bal0 = zzzToken.balanceOf(address(this));
        uint bal1 = USDC.balanceOf(address(this));

        // Here we want to see how many ticks off from the peg we are
        (, int24 currentTick, , , , , ) = pool.slot0();

        // Since we are trying to maintain a 1:1 exchange, we factor in the decimal precisions to find our desired peg tick
        // ZZZtoken is decimals 18 and USDC is 6 : our desired peg is -726324
        int24 difference = currentTick + 726324;
        if (difference == 0) return (0, 0);

        // Which way are we swapping
        bool zeroForOne = difference > 0;

        // Check state
        // If we have no tokens to help stabilize simply return
        if (zeroForOne) {
            if (bal0 == 0) return (0, 0);
        } 
        else {
            if (bal1 == 0) return (0, 0);
        }

        // use 5% of available funds
        int amountToSwap = zeroForOne ? int((bal0 * 5 / 100)) : int((bal1 * 5 / 100));

        // Each tick difference we use that * 5% of our tokens to pull back
        (int t0, int t1) = pool.swap(address(this), zeroForOne, amountToSwap, 0, "");
        return (t0, t1);
    }
}