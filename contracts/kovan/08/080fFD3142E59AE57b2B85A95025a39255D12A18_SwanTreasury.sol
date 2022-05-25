//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ISwapRouter.sol";

/**
 * @notice Swan Treasury contract that partners deposit their tokens for pair and let the trade wallet do the trading
 * @dev Uniswap trading interface
 * @author rock888
 */
contract SwanTreasury is ReentrancyGuard {
    // only to distinguish the cloned one
    bool public isBase;
    // prevents the already cloned one from re-initialize
    bool public isInitialized;

    address public partner; // the partner who deposits the funds
    address private swanTrader; // the trader who really do the trading
    address public tokenA; // token0 first token of pair
    address public tokenB; // token1 second token of pair
    uint24 public poolFee; // the pool fee just to get the swap params

    uint256 public epochDuration; // the swan trading epoch period
    uint256 public epochStart; // the start time for calculating the epoch time

    uint256 public reserveA; // the tokenA amount of the contract
    uint256 public reserveB; // the tokenB amount of the contract
    uint256 public currentPreInformedAmountA; // current pre informed amount of tokenA
    uint256 public currentPreInformedAmountB; // current pre informed amount of tokenB

    uint256 private lastFeeWithdrawedTime;

    // address public uniSwapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    event Deposite(address token, uint256 amount);
    event PreInform(address token, uint256 amount);
    event WithDraw(address token, uint256 amount);
    event UniswapV3Swap(ISwapRouter.ExactInputSingleParams params);
    event Update();

    /// @notice only for the target contract
    constructor() {
        // this ensures that the base contract cannot be initialized
        isBase = true;
    }

    modifier onlyPartner() {
        require(partner == msg.sender, "you're not the allowed partner");
        _;
    }

    modifier onlyTrader() {
        require(swanTrader == msg.sender, "you're not the allowed trader");
        _;
    }

    modifier isInformable() {
        uint256 periodToNextEpoch = ((block.timestamp - epochStart) /
            epochDuration +
            1) *
            epochDuration +
            epochStart -
            block.timestamp;
        require(
            periodToNextEpoch >= 86400 * 3,
            "ERROR: it'a not informable after 3 days before the next epoch, do it the next epoch again"
        );
        _;
    }

    /// @notice initialize the cloned contract
    function initialize(
        address _partner,
        address _swanTrader,
        address _tokenA,
        address _tokenB,
        uint24 _poolFee,
        uint256 _epochDuration,
        uint256 _epochStart
    ) external {
        // For the base contract, itBase == true. Impossible to use.
        // if it's initialized once then it's not possible to use again
        require(
            isBase == false,
            "ERROR: This is base contract, cannot be initialized"
        );
        require(
            isInitialized == false,
            "ERROR: This is already isInitialized. redo is not allowed"
        );
        tokenA = _tokenA;
        partner = _partner;
        tokenB = _tokenB;
        poolFee = _poolFee;
        swanTrader = _swanTrader;
        epochDuration = _epochDuration;
        epochStart = _epochStart;
        isInitialized = true;
    }

    /// @notice deposite the token pair
    function deposite(uint256 _amountA, uint256 _amountB) external onlyPartner {
        IERC20(tokenA).transferFrom(msg.sender, address(this), _amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), _amountB);
        if (_amountA > 0) {
            reserveA = reserveA + _amountA;
        }
        if (_amountB > 0) {
            reserveB = reserveB + _amountB;
        }
        emit Deposite(tokenA, _amountA);
        emit Deposite(tokenB, _amountB);
    }

    /// @notice preinform for the withdraw, need to be done before 3 days from the end of the current epoch
    function preInform(uint256 _amountA, uint256 _amountB)
        external
        onlyPartner
        isInformable
    {
        if (_amountA > 0) {
            currentPreInformedAmountA = currentPreInformedAmountA + _amountA;
        }
        if (_amountB > 0) {
            currentPreInformedAmountB = currentPreInformedAmountB + _amountB;
        }
        emit PreInform(tokenA, _amountA);
        emit PreInform(tokenB, _amountB);
    }

    /// @notice withdraw the token pair
    function withdraw(uint256 amountA, uint256 amountB)
        external
        onlyPartner
        nonReentrant
    {
        if (amountA > 0) {
            require(amountA <= currentPreInformedAmountA, "ERR: amount exceed");
            IERC20(tokenA).transferFrom(address(this), partner, amountA);
            reserveA = reserveA - amountA;
            currentPreInformedAmountA = currentPreInformedAmountA - amountA;
        }
        if (amountB > 0) {
            require(amountB <= currentPreInformedAmountB, "ERR: amount exceed");
            IERC20(tokenB).transferFrom(address(this), partner, amountB);
            currentPreInformedAmountB = currentPreInformedAmountB - amountB;
        }
        emit WithDraw(tokenA, amountA);
        emit WithDraw(tokenB, amountB);
    }

    /// @notice withdraw the fee per epoch
    function withdrawFee(address to) external onlyTrader nonReentrant {
        (uint256 feeAmountA, uint256 feeAmountB) = calculateFee();
        IERC20(tokenA).transfer(to, feeAmountA);
        IERC20(tokenB).transfer(to, feeAmountB);
        update();
    }

    /// @notice calculate the fee from last withdrawed epoch
    function calculateFee()
        internal
        view
        returns (uint256 amountA, uint256 amountB)
    {
        uint256 currentTime = block.timestamp;
        uint256 currentEpochStartTime = ((currentTime - epochStart) /
            epochDuration) *
            epochDuration +
            epochStart;
        require(
            currentEpochStartTime > lastFeeWithdrawedTime,
            "ERR: already withdrawed for the current epoch"
        );
        // currently 20 percent fee
        amountA = (reserveA * 20) / 100;
        amountB = (reserveB * 20) / 100;
    }

    /// @notice update the reserve amounts
    function update() public {
        reserveA = IERC20(tokenA).balanceOf(address(this));
        reserveB = IERC20(tokenB).balanceOf(address(this));
        emit Update();
    }

    /// @notice just for general purposes, not use really
    function trade(
        address targetContract,
        uint256 amount,
        bytes calldata data
    ) external onlyTrader {
        (bool success, bytes memory data) = targetContract.call(data);
        require(success, "trade failed");
    }

    /// @notice uniswap v3 swap trigger
    function uniswapv3(
        address uniSwapRouter,
        address tokenIn,
        uint256 amountIn
    ) external onlyTrader {
        IERC20(tokenIn).approve(uniSwapRouter, amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenIn == tokenA ? tokenB : tokenA,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        ISwapRouter(uniSwapRouter).exactInputSingle(params);
        update();
        emit UniswapV3Swap(params);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}