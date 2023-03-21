// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "./libraries/LiquidatorLib.sol";
import "./libraries/FixedMathLib.sol";
import "./interfaces/ILiquidationSource.sol";

contract LiquidationPair {
    /* ============ Variables ============ */
    ILiquidationSource public immutable source; // Where to get tokenIn from
    address public immutable tokenIn; // Token being sent into the Liquidator Pair by the user(ex. POOL)
    address public immutable tokenOut; // Token being sent out of the Liquidation Pair to the user(ex. USDC, WETH, etc.)
    UFixed32x9 public immutable swapMultiplier; // 9 decimals
    UFixed32x9 public immutable liquidityFraction; // 9 decimals

    uint128 public virtualReserveIn;
    uint128 public virtualReserveOut;

    /* ============ Events ============ */
    event Swapped(address indexed account, uint256 amountIn, uint256 amountOut);

    /* ============ Constructor ============ */

    constructor(
        ILiquidationSource _source,
        address _tokenIn,
        address _tokenOut,
        UFixed32x9 _swapMultiplier,
        UFixed32x9 _liquidityFraction,
        uint128 _virtualReserveIn,
        uint128 _virtualReserveOut
    ) {
        require(UFixed32x9.unwrap(_liquidityFraction) > 0, "LiquidationPair/liquidity-fraction-greater-than-zero");
        require(UFixed32x9.unwrap(_swapMultiplier) <= 1e9, "LiquidationPair/swap-multiplier-less-than-one");
        require(UFixed32x9.unwrap(_liquidityFraction) <= 1e9, "LiquidationPair/liquidity-fraction-less-than-one");
        source = _source;
        tokenIn = _tokenIn;
        tokenOut = _tokenOut;
        swapMultiplier = _swapMultiplier;
        liquidityFraction = _liquidityFraction;
        virtualReserveIn = _virtualReserveIn;
        virtualReserveOut = _virtualReserveOut;
    }

    /* ============ External Function ============ */

    function maxAmountOut() external returns (uint256) {
        return _availableReserveOut();
    }

    function _availableReserveOut() internal returns (uint256) {
        return source.availableBalanceOf(tokenOut);
    }

    function nextLiquidationState() external returns (uint128, uint128) {
        return LiquidatorLib.virtualBuyback(virtualReserveIn, virtualReserveOut, _availableReserveOut());
    }

    function computeExactAmountIn(uint256 _amountOut) external returns (uint256) {
        return
            LiquidatorLib.computeExactAmountIn(virtualReserveIn, virtualReserveOut, _availableReserveOut(), _amountOut);
    }

    function computeExactAmountOut(uint256 _amountIn) external returns (uint256) {
        return
            LiquidatorLib.computeExactAmountOut(virtualReserveIn, virtualReserveOut, _availableReserveOut(), _amountIn);
    }

    function swapExactAmountIn(address _account, uint256 _amountIn, uint256 _amountOutMin) external returns (uint256) {
        uint256 availableBalance = _availableReserveOut();
        (uint128 _virtualReserveIn, uint128 _virtualReserveOut, uint256 amountOut) = LiquidatorLib.swapExactAmountIn(
            virtualReserveIn, virtualReserveOut, availableBalance, _amountIn, swapMultiplier, liquidityFraction
        );

        virtualReserveIn = _virtualReserveIn;
        virtualReserveOut = _virtualReserveOut;

        require(amountOut >= _amountOutMin, "LiquidationPair/min-not-guaranteed");
        _swap(_account, amountOut, _amountIn);

        emit Swapped(_account, _amountIn, amountOut);

        return amountOut;
    }

    function swapExactAmountOut(address _account, uint256 _amountOut, uint256 _amountInMax) external returns (uint256) {
        uint256 availableBalance = _availableReserveOut();
        (uint128 _virtualReserveIn, uint128 _virtualReserveOut, uint256 amountIn) = LiquidatorLib.swapExactAmountOut(
            virtualReserveIn, virtualReserveOut, availableBalance, _amountOut, swapMultiplier, liquidityFraction
        );
        virtualReserveIn = _virtualReserveIn;
        virtualReserveOut = _virtualReserveOut;
        require(amountIn <= _amountInMax, "LiquidationPair/max-not-guaranteed");
        _swap(_account, _amountOut, amountIn);

        emit Swapped(_account, amountIn, _amountOut);

        return amountIn;
    }

    /**
     * @notice Get the address that will receive `tokenIn`.
     * @return address Address of the target
     */
    function target() external returns(address) {
        return source.targetOf(tokenIn);
    }

    /* ============ Internal Functions ============ */

    // Note: Uniswap has restrictions on _account, but we don't
    // Note: Uniswap requires _amountOut to be > 0, but we don't
    function _swap(address _account, uint256 _amountOut, uint256 _amountIn) internal {
        source.liquidate(_account, tokenIn, _amountIn, tokenOut, _amountOut);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

interface ILiquidationSource {
    /**
     * @notice Get the available amount of tokens that can be swapped.
     * @param tokenOut Address of the token to get available balance for
     * @return uint256 Available amount of `token`
     */
    function availableBalanceOf(address tokenOut) external returns (uint256);

    /**
     * @notice Liquidate `amountIn` of `tokenIn` for `amountOut` of `tokenOut` and transfer to `account`.
     * @param account Address of the account that will receive `tokenOut`
     * @param tokenIn Address of the token being sold
     * @param amountIn Amount of token being sold
     * @param tokenOut Address of the token being bought
     * @param amountOut Amount of token being bought
     * @return bool Return true once the liquidation has been completed
     */
    function liquidate(
        address account,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut
    ) external returns (bool);

    /**
     * @notice Get the address that will receive `tokenIn`.
     * @param tokenIn Address of the token to get the target address for
     * @return address Address of the target
     */
    function targetOf(address tokenIn) external returns(address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

type UFixed32x9 is uint32;

/// A minimal library to do fixed point operations on UFixed32x9.
library FixedMathLib {
    uint256 constant multiplier = 1e9;

    function mul(uint256 a, UFixed32x9 b) internal pure returns (uint256) {
        require(a <= type(uint224).max, "FixedMathLib/a-less-than-224-bits");
        return a * UFixed32x9.unwrap(b) / multiplier;
    }

    function div(uint256 a, UFixed32x9 b) internal pure returns (uint256) {
        require(UFixed32x9.unwrap(b) > 0, "FixedMathLib/b-greater-than-zero");
        require(a <= type(uint224).max, "FixedMathLib/a-less-than-224-bits");
        return a * multiplier / UFixed32x9.unwrap(b);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "openzeppelin/token/ERC20/IERC20.sol";

import "./FixedMathLib.sol";

/**
 * @title PoolTogether Liquidator Library
 * @author PoolTogether Inc. Team
 * @notice
 */
library LiquidatorLib {
    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint256 amountIn1, uint128 reserve1, uint128 reserve0)
        internal
        pure
        returns (uint256 amountOut0)
    {
        require(reserve0 > 0 && reserve1 > 0, "LiquidatorLib/insufficient-reserve-liquidity");
        uint256 numerator = amountIn1 * reserve0;
        uint256 denominator = amountIn1 + reserve1;
        amountOut0 = numerator / denominator;
        require(amountOut0 < reserve0, "LiquidatorLib/insufficient-reserve-liquidity");
        // require(amountOut0 > 0, "LiquidatorLib/insufficient-amount-out");
        return amountOut0;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint256 amountOut0, uint128 reserve1, uint128 reserve0)
        internal
        pure
        returns (uint256 amountIn1)
    {
        // require(amountOut0 > 0, "LiquidatorLib/insufficient-amount-out");
        require(amountOut0 < reserve0, "LiquidatorLib/insufficient-reserve-liquidity");
        require(reserve0 > 0 && reserve1 > 0, "LiquidatorLib/insufficient-reserve-liquidity");
        uint256 numerator = amountOut0 * reserve1;
        uint256 denominator = uint256(reserve0) - amountOut0;
        amountIn1 = (numerator / denominator);
    }

    function virtualBuyback(uint128 _reserve0, uint128 _reserve1, uint256 _amountIn1)
        internal
        pure
        returns (uint128 reserve0, uint128 reserve1)
    {
        // swap back yield
        uint256 amountOut0 = getAmountOut(_amountIn1, _reserve1, _reserve0);
        reserve0 = _reserve0 - uint128(amountOut0); // Note: Safe: amountOut0 < reserve0
        reserve1 = _reserve1 + uint128(_amountIn1); // Note: Potential overflow
    }

    function computeExactAmountIn(uint128 _reserve0, uint128 _reserve1, uint256 _amountIn1, uint256 _amountOut1)
        internal
        pure
        returns (uint256)
    {
        require(_amountOut1 <= _amountIn1, "LiquidatorLib/insufficient-balance-liquidity");
        (uint128 reserve0, uint128 reserve1) = virtualBuyback(_reserve0, _reserve1, _amountIn1);
        return getAmountIn(_amountOut1, reserve0, reserve1);
    }

    function computeExactAmountOut(uint128 _reserve0, uint128 _reserve1, uint256 _amountIn1, uint256 _amountIn0)
        internal
        pure
        returns (uint256)
    {
        (uint128 reserve0, uint128 reserve1) = virtualBuyback(_reserve0, _reserve1, _amountIn1);

        uint256 amountOut1 = getAmountOut(_amountIn0, reserve0, reserve1);
        require(amountOut1 <= _amountIn1, "LiquidatorLib/insufficient-balance-liquidity");
        return amountOut1;
    }

    function swapExactAmountIn(
        uint128 _reserve0,
        uint128 _reserve1,
        uint256 _amountIn1,
        uint256 _amountIn0,
        UFixed32x9 _swapMultiplier,
        UFixed32x9 _liquidityFraction
    ) internal pure returns (uint128 reserve0, uint128 reserve1, uint256 amountOut1) {
        (reserve0, reserve1) = virtualBuyback(_reserve0, _reserve1, _amountIn1);

        // do swap
        amountOut1 = getAmountOut(_amountIn0, reserve0, reserve1);
        require(amountOut1 <= _amountIn1, "LiquidatorLib/insufficient-balance-liquidity");
        reserve0 = reserve0 + uint128(_amountIn0); // Note: Potential overflow
        reserve1 = reserve1 - uint128(amountOut1); // Note: Safe: amountOut1 < reserve1

        (reserve0, reserve1) =
            _virtualSwap(reserve0, reserve1, _amountIn1, amountOut1, _swapMultiplier, _liquidityFraction);
    }

    function swapExactAmountOut(
        uint128 _reserve0,
        uint128 _reserve1,
        uint256 _amountIn1,
        uint256 _amountOut1,
        UFixed32x9 _swapMultiplier,
        UFixed32x9 _liquidityFraction
    ) internal pure returns (uint128 reserve0, uint128 reserve1, uint256 amountIn0) {

        require(_amountOut1 <= _amountIn1, "LiquidatorLib/insufficient-balance-liquidity");
        (reserve0, reserve1) = virtualBuyback(_reserve0, _reserve1, _amountIn1);


        // do swap
        amountIn0 = getAmountIn(_amountOut1, reserve0, reserve1);
        reserve0 = reserve0 + uint128(amountIn0); // Note: Potential overflow
        reserve1 = reserve1 - uint128(_amountOut1); // Note: Safe: _amountOut1 < reserve1

        (reserve0, reserve1) =
            _virtualSwap(reserve0, reserve1, _amountIn1, _amountOut1, _swapMultiplier, _liquidityFraction);
    }

    function _virtualSwap(
        uint128 _reserve0,
        uint128 _reserve1,
        uint256 _amountIn1,
        uint256 _amountOut1,
        UFixed32x9 _swapMultiplier,
        UFixed32x9 _liquidityFraction
    ) internal pure returns (uint128 reserve0, uint128 reserve1) {
        uint256 virtualAmountOut1 = FixedMathLib.mul(_amountOut1, _swapMultiplier);
        // NEED THIS TO BE GREATER THAN 0 for getAmountIn!
        // Effectively a minimum of 1e9 going out to the user?

        uint256 virtualAmountIn0 = getAmountIn(virtualAmountOut1, _reserve0, _reserve1);

        reserve0 = _reserve0 + uint128(virtualAmountIn0); // Note: Potential overflow
        reserve1 = _reserve1 - uint128(virtualAmountOut1); // Note: Potential underflow after sub


        // now, we want to ensure that the accrued yield is always a small fraction of virtual LP position.\
        uint256 reserveFraction = (_amountIn1 * 1e9) / reserve1;
        uint256 multiplier = FixedMathLib.div(reserveFraction, _liquidityFraction);
        reserve0 = uint128((uint256(reserve0) * multiplier) / 1e9); // Note: Safe cast
        reserve1 = uint128((uint256(reserve1) * multiplier) / 1e9); // Note: Safe cast
    }
}

// reserve1 of 2381976568565668072671905656
// rf of 2857142857
// multiplier of 142857142850