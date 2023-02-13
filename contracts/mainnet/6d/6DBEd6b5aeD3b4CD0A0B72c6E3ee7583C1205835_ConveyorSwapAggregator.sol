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

    constructor(address _weth) {
        WETH = _weth;
        CONVEYOR_SWAP_EXECUTOR = address(new ConveyorSwapExecutor());
    }

    struct SwapAggregatorMulticall {
        address tokenInDestination;
        Call[] calls;
    }

    struct Call {
        address target;
        bytes callData;
    }

    function swap(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOutMin,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external {
        IERC20(tokenIn).transferFrom(
            msg.sender,
            swapAggregatorMulticall.tokenInDestination,
            amountIn
        );

        uint256 tokenOutBalance = IERC20(tokenOut).balanceOf(msg.sender);
        uint256 tokenOutAmountRequired = tokenOutBalance + amountOutMin;

        IConveyorSwapExecutor(CONVEYOR_SWAP_EXECUTOR).executeMulticall(
            swapAggregatorMulticall.calls
        );

        if (IERC20(tokenOut).balanceOf(msg.sender) < tokenOutAmountRequired) {
            revert InsufficientOutputAmount(
                tokenOutAmountRequired - IERC20(tokenOut).balanceOf(msg.sender),
                amountOutMin
            );
        }
    }

    function swapExactEthForToken(
        address tokenOut,
        uint256 amountOutMin,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external payable {
        address _weth = WETH;
        assembly {
            mstore(0x0, shl(224, 0xd0e30db0))
            if iszero(
                call(
                    gas(),
                    _weth,
                    callvalue(),
                    0,
                    0,
                    0,
                    0
                )
            ) {
                revert("Native token deposit failed", 0)
            }
            
        }
      
        IERC20(WETH).transfer(
            swapAggregatorMulticall.tokenInDestination,
            msg.value
        );

        uint256 tokenOutBalance = IERC20(tokenOut).balanceOf(msg.sender);
        uint256 tokenOutAmountRequired = tokenOutBalance + amountOutMin;

        IConveyorSwapExecutor(CONVEYOR_SWAP_EXECUTOR).executeMulticall(
            swapAggregatorMulticall.calls
        );

        bool sufficient;
        uint256 balanceOut = IERC20(tokenOut).balanceOf(msg.sender);

        assembly {
            sufficient := iszero(lt(tokenOutAmountRequired, balanceOut))
        }
        
        if (!sufficient) {
            revert InsufficientOutputAmount(
                tokenOutAmountRequired - balanceOut,
                amountOutMin
            );
        }
    }

    function swapExactTokenForEth(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external {
        IERC20(tokenIn).transferFrom(
            msg.sender,
            swapAggregatorMulticall.tokenInDestination,
            amountIn
        );

        uint256 amountOutRequired;
        assembly {
            amountOutRequired := add(selfbalance(), amountOutMin)
        }

        IConveyorSwapExecutor(CONVEYOR_SWAP_EXECUTOR).executeMulticall(
            swapAggregatorMulticall.calls
        );

        bool sufficient;
        bool transferSuccess;
        uint256 balanceWeth = IERC20(WETH).balanceOf(address(this));

        address _weth = WETH;
        assembly {
            mstore(0x0, shl(224, 0x2e1a7d4d))
            mstore(4, balanceWeth)
            if iszero(
                call(
                    gas(),
                    _weth,
                    0, /* wei */
                    0, /* in pos */
                    68, /* in len */
                    0, /* out pos */
                    0 /* out size */
                )
            ) {
                revert("Native Token Withdraw failed", balanceWeth)
            }

            sufficient := iszero(lt(amountOutRequired, selfbalance()))

            if sufficient {
                mstore(
                    0x00,
                    0xa9059cbb00000000000000000000000000000000000000000000000000000000
                )

                mstore(4, caller())
                mstore(36, selfbalance())

                pop(
                    call(
                        gas(),
                        0, /* to */
                        0, /* wei */
                        0, /* in pos */
                        68, /* in len */
                        0, /* out pos */
                        0 /* out size */
                    )
                )
                transferSuccess := iszero(returndatasize())
            }
        }

        if (!sufficient) {
            revert InsufficientOutputAmount(
                amountOutRequired - address(this).balance,
                amountOutMin
            );
        }

        require(transferSuccess, "Native transfer failed");
    }

    receive() external payable {}
}

contract ConveyorSwapExecutor {
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