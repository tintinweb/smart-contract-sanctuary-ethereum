// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

error InsufficientWalletBalance(
    address account,
    uint256 balance,
    uint256 balanceNeeded
);
error OrderDoesNotExist(bytes32 orderId);
error OrderQuantityIsZero();
error InsufficientOrderInputValue();
error IncongruentInputTokenInOrderGroup(address token, address expectedToken);
error TokenInIsTokenOut();
error IncongruentOutputTokenInOrderGroup(address token, address expectedToken);
error InsufficientOutputAmount(uint256 amountOut, uint256 expectedAmountOut);
error InsufficientInputAmount(uint256 amountIn, uint256 expectedAmountIn);
error InsufficientLiquidity();
error InsufficientAllowanceForOrderPlacement(
    address token,
    uint256 approvedQuantity,
    uint256 approvedQuantityNeeded
);
error InsufficientAllowanceForOrderUpdate(
    address token,
    uint256 approvedQuantity,
    uint256 approvedQuantityNeeded
);
error InvalidOrderGroupSequence();
error IncongruentFeeInInOrderGroup();
error IncongruentFeeOutInOrderGroup();
error IncongruentTaxedTokenInOrderGroup();
error IncongruentStoplossStatusInOrderGroup();
error IncongruentBuySellStatusInOrderGroup();
error NonEOAStoplossExecution();
error MsgSenderIsNotTxOrigin();
error MsgSenderIsNotLimitOrderRouter();
error MsgSenderIsNotLimitOrderExecutor();
error MsgSenderIsNotSandboxRouter();
error MsgSenderIsNotOwner();
error MsgSenderIsNotOrderOwner();
error MsgSenderIsNotOrderBook();
error MsgSenderIsNotLimitOrderBook();
error MsgSenderIsNotTempOwner();
error Reentrancy();
error ETHTransferFailed();
error InvalidAddress();
error UnauthorizedUniswapV3CallbackCaller();
error DuplicateOrderIdsInOrderGroup();
error InvalidCalldata();
error InsufficientMsgValue();
error UnauthorizedCaller();
error AmountInIsZero();
///@notice Returns the index of the call that failed within the SandboxRouter.Call[] array
error SandboxCallFailed(uint256 callIndex);
error InvalidTransferAddressArray();
error AddressIsZero();
error IdenticalTokenAddresses();
error InvalidInputTokenForOrderPlacement();
error SandboxFillAmountNotSatisfied(
    bytes32 orderId,
    uint256 amountFilled,
    uint256 fillAmountRequired
);
error OrderNotEligibleForRefresh(bytes32 orderId);

error SandboxAmountOutRequiredNotSatisfied(
    bytes32 orderId,
    uint256 amountOut,
    uint256 amountOutRequired
);

error AmountOutRequiredIsZero(bytes32 orderId);

error FillAmountSpecifiedGreaterThanAmountRemaining(
    uint256 fillAmountSpecified,
    uint256 amountInRemaining,
    bytes32 orderId
);
error ConveyorFeesNotPaid(
    uint256 expectedFees,
    uint256 feesPaid,
    uint256 unpaidFeesRemaining
);
error InsufficientFillAmountSpecified(
    uint128 fillAmountSpecified,
    uint128 amountInRemaining
);
error InsufficientExecutionCredit(uint256 msgValue, uint256 minExecutionCredit);
error WithdrawAmountExceedsExecutionCredit(
    uint256 amount,
    uint256 executionCredit
);
error MsgValueIsNotCumulativeExecutionCredit(
    uint256 msgValue,
    uint256 cumulativeExecutionCredit
);

error ExecutorNotCheckedIn();

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../lib/interfaces/token/IERC20.sol";
import "./ConveyorErrors.sol";

interface IConveyorSwapExecutor {
    function executeMulticall(ConveyorSwapAggregator.Call[] memory calls)
        external;
}

/// @title ConveyorSwapAggregator
/// @author 0xKitsune, 0xOsiris, Conveyor Labs
/// @notice Multicall contract for token Swaps.
contract ConveyorSwapAggregator {
    address public immutable CONVEYOR_SWAP_EXECUTOR;
    address public immutable WETH;

    constructor(address _weth, address _conveyorSwapExecutor) {
        WETH = _weth;
        CONVEYOR_SWAP_EXECUTOR = _conveyorSwapExecutor;
    }

    /// @notice Multicall struct for token Swaps.
    /// @param tokenInDestination Address to send tokenIn to.
    /// @param calls Array of calls to be executed.
    struct SwapAggregatorMulticall {
        address tokenInDestination;
        Call[] calls;
    }
    /// @notice Call struct for token Swaps.
    /// @param target Address to call.
    /// @param callData Data to call.
    struct Call {
        address target;
        bytes callData;
    }

    /// @notice Swap tokens for tokens.
    /// @param tokenIn Address of token to swap.
    /// @param amountIn Amount of tokenIn to swap.
    /// @param tokenOut Address of token to receive.
    /// @param amountOutMin Minimum amount of tokenOut to receive.
    /// @param swapAggregatorMulticall Multicall to be executed.
    function swap(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOutMin,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external {
        ///@notice Transfer tokenIn from msg.sender to tokenInDestination address.
        IERC20(tokenIn).transferFrom(
            msg.sender,
            swapAggregatorMulticall.tokenInDestination,
            amountIn
        );

        ///@notice Get tokenOut balance of msg.sender.
        uint256 tokenOutBalance = IERC20(tokenOut).balanceOf(msg.sender);
        ///@notice Calculate tokenOut amount required.
        uint256 tokenOutAmountRequired = tokenOutBalance + amountOutMin;

        ///@notice Execute Multicall.
        IConveyorSwapExecutor(CONVEYOR_SWAP_EXECUTOR).executeMulticall(
            swapAggregatorMulticall.calls
        );
        ///@notice Check if tokenOut balance of msg.sender is sufficient.
        if (IERC20(tokenOut).balanceOf(msg.sender) < tokenOutAmountRequired) {
            revert InsufficientOutputAmount(
                tokenOutAmountRequired - IERC20(tokenOut).balanceOf(msg.sender),
                amountOutMin
            );
        }
    }

    /// @notice Swap ETH for tokens.
    /// @param tokenOut Address of token to receive.
    /// @param amountOutMin Minimum amount of tokenOut to receive.
    /// @param swapAggregatorMulticall Multicall to be executed.
    function swapExactEthForToken(
        address tokenOut,
        uint256 amountOutMin,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external payable {
        ///@notice Deposit the msg.value into WETH.
        _depositEth(msg.value, WETH);

        ///@notice Transfer WETH from WETH to tokenInDestination address.
        IERC20(WETH).transfer(
            swapAggregatorMulticall.tokenInDestination,
            msg.value
        );

        ///@notice Calculate tokenOut amount required.
        uint256 tokenOutAmountRequired = IERC20(tokenOut).balanceOf(
            msg.sender
        ) + amountOutMin;

        ///@notice Execute Multicall.
        IConveyorSwapExecutor(CONVEYOR_SWAP_EXECUTOR).executeMulticall(
            swapAggregatorMulticall.calls
        );

        ///@notice Get tokenOut balance of msg.sender after multicall execution.
        uint256 balanceOut = IERC20(tokenOut).balanceOf(msg.sender);

        ///@notice Revert if tokenOut balance of msg.sender is insufficient.
        if (balanceOut < tokenOutAmountRequired) {
            revert InsufficientOutputAmount(
                tokenOutAmountRequired - balanceOut,
                amountOutMin
            );
        }
    }

    /// @notice Swap tokens for ETH.
    /// @param tokenIn Address of token to swap.
    /// @param amountIn Amount of tokenIn to swap.
    /// @param amountOutMin Minimum amount of ETH to receive.
    /// @param swapAggregatorMulticall Multicall to be executed.
    function swapExactTokenForEth(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external {
        ///@notice Transfer tokenIn from msg.sender to tokenInDestination address.
        IERC20(tokenIn).transferFrom(
            msg.sender,
            swapAggregatorMulticall.tokenInDestination,
            amountIn
        );
        ///@notice Calculate amountOutRequired.
        uint256 amountOutRequired = msg.sender.balance + amountOutMin;

        ///@notice Execute Multicall.
        IConveyorSwapExecutor(CONVEYOR_SWAP_EXECUTOR).executeMulticall(
            swapAggregatorMulticall.calls
        );

        ///@notice Get WETH balance of this contract.
        uint256 balanceWeth = IERC20(WETH).balanceOf(address(this));

        ///@notice Withdraw WETH from this contract.
        _withdrawEth(balanceWeth, WETH);

        ///@notice Transfer ETH to msg.sender.
        _safeTransferETH(msg.sender, address(this).balance);

        ///@notice Revert if Eth balance of the caller is insufficient.
        if (msg.sender.balance < amountOutRequired) {
            revert InsufficientOutputAmount(
                amountOutRequired - msg.sender.balance,
                amountOutMin
            );
        }
    }

    ///@notice Helper function to transfer ETH.
    function _safeTransferETH(address to, uint256 amount) internal {
        bool success;
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        if (!success) {
            revert ETHTransferFailed();
        }
    }

    /// @notice Helper function to Withdraw ETH from WETH.
    function _withdrawEth(uint256 amount, address weth) internal {
        assembly {
            mstore(0x0, shl(224, 0x2e1a7d4d)) /* keccak256("withdraw(uint256)") */
            mstore(4, amount)
            if iszero(
                call(
                    gas(), /* gas */
                    weth, /* to */
                    0, /* value */
                    0, /* in */
                    68, /* in size */
                    0, /* out */
                    0 /* out size */
                )
            ) {
                revert("Native Token Withdraw failed", amount)
            }
        }
    }

    /// @notice Helper function to Deposit ETH into WETH.
    function _depositEth(uint256 amount, address weth) internal {
        assembly {
            mstore(0x0, shl(224, 0xd0e30db0)) /* keccak256("deposit()") */
            if iszero(
                call(
                    gas(), /* gas */
                    weth, /* to */
                    amount, /* value */
                    0, /* in */
                    0, /* in size */
                    0, /* out */
                    0 /* out size */
                )
            ) {
                revert("Native token deposit failed", 0)
            }
        }
    }

    receive() external payable {}
}

contract ConveyorSwapExecutor {
    ///@notice Executes a multicall.
    function executeMulticall(ConveyorSwapAggregator.Call[] calldata calls)
        public
    {
        uint256 callsLength = calls.length;
        for (uint256 i = 0; i < callsLength; ) {
            ConveyorSwapAggregator.Call memory call = calls[i];

            (bool success, ) = call.target.call(call.callData);

            require(success, "call failed");

            unchecked {
                ++i;
            }
        }
    }

    ///@notice Uniswap V3 callback function called during a swap on a v3 liqudity pool.
    ///@param amount0Delta - The change in token0 reserves from the swap.
    ///@param amount1Delta - The change in token1 reserves from the swap.
    ///@param data - The data packed into the swap.
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        ///@notice Decode all of the swap data.
        (bool _zeroForOne, address tokenIn, address _sender) = abi.decode(
            data,
            (bool, address, address)
        );

        ///@notice Set amountIn to the amountInDelta depending on boolean zeroForOne.
        uint256 amountIn = _zeroForOne
            ? uint256(amount0Delta)
            : uint256(amount1Delta);

        if (!(_sender == address(this))) {
            ///@notice Transfer the amountIn of tokenIn to the liquidity pool from the sender.
            IERC20(tokenIn).transferFrom(_sender, msg.sender, amountIn);
        } else {
            IERC20(tokenIn).transfer(msg.sender, amountIn);
        }
    }
}