// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/router/IUniswapV2Router.sol";
import "../interfaces/router/IUniswapV3Router.sol";
import "../interfaces/router/IBalancerRouter.sol";
import "../interfaces/router/ICurveTC1Router.sol";
import "./Permitable.sol";
import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "@rari-capital/solmate/src/tokens/ERC20.sol";
import "@rari-capital/solmate/src/tokens/WETH.sol";

/// @title Router contract that swaps tokens with different DEXs using multihops.
contract MainnetMultiHopRouter is Permitable {
    IUniswapV3Router private immutable UniV3Router;
    ICurveTC1Router private immutable curveTC1Router;
    IBalancerRouter private immutable balancer;
    WETH private immutable WETHContract;
    address private constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint32 public immutable _fee;

    struct BalancerMultiInputs {
        uint256 deadline;
        address payable to;
        address srcToken;
    }

    constructor(
        IUniswapV3Router _uniswapV3Router,
        IBalancerRouter _balancer,
        ICurveTC1Router _curveTC1Router,
        address payable _WETHAddress,
        uint32 fee
    ) {
        UniV3Router = _uniswapV3Router;
        balancer = _balancer;
        curveTC1Router = _curveTC1Router;
        WETHContract = WETH(_WETHAddress);
        _fee = fee;
    }

    /////////////////////////////////// MULTIHOP SWAPS ////////////////////////////////////
    /// @notice Swaps tokens using multiple pools on UniV2 forks
    /// @param amountIn The amount of source token to be swapped
    /// @param amountOutMin The minimum amount of destination token to be received
    /// @param path The addresses of tokens to be swapped - source token and destination token
    /// @param deadline The deadline for the swap
    /// @param to The receiver address
    function uniswapV2MultiSwap(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        uint256 deadline,
        address to,
        IUniswapV2Router router
    ) public payable {
        if (msg.value != 0) {
            path[0] = address(WETHContract);
            unchecked {
                router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                    value: (msg.value * _fee) / 10000
                }(amountOutMin, path, to, deadline);
            }
        } else {
            bool ToETH = path[path.length - 1] == address(0);
            SafeTransferLib.safeTransferFrom(
                ERC20(path[0]),
                msg.sender,
                address(this),
                amountIn
            );
            unchecked {
                amountIn = (amountIn * _fee) / 10000;
            }
            SafeTransferLib.safeApprove(
                ERC20(path[0]),
                address(router),
                amountIn
            );
            if (ToETH) {
                path[path.length - 1] = address(WETHContract);
                router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    amountIn,
                    amountOutMin,
                    path,
                    to,
                    deadline
                );
            } else {
                router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    amountIn,
                    amountOutMin,
                    path,
                    to,
                    deadline
                );
            }
        }
    }

    /// @notice Swaps tokens using multiple pools of UniV3
    /// @param amountIn The amount of source token to be swapped
    /// @param amountOutMin The minimum amount of destination token to be received
    /// @param deadline The deadline for the swap
    /// @param to The receiver address
    /// @param srcToken The source token address
    /// @param bytePath The encoded path with token address, fee, token adress, fee ... n times
    /// @return amountOut The amount of destination token received
    function uniswapV3MultiSwap(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        address payable to,
        address srcToken,
        bytes calldata bytePath
    ) public payable returns (uint256 amountOut) {
        SafeTransferLib.safeTransferFrom(
            ERC20(srcToken),
            msg.sender,
            address(this),
            amountIn
        );
        unchecked {
            amountIn = (amountIn * _fee) / 10000;
        }
        SafeTransferLib.safeApprove(
            ERC20(srcToken),
            address(UniV3Router),
            amountIn
        );
        amountOut = UniV3Router.exactInput(
            IUniswapV3Router.ExactInputParams({
                path: bytePath,
                recipient: to,
                deadline: deadline,
                amountIn: amountIn,
                amountOutMin: amountOutMin
            })
        );
    }

    /// @notice Swaps tokens using multiple pools on Balancer
    /// @param swaps The BatchSwapStep struct for Balancer batchSwaps
    /// @param assets The sorted token addresses for the swap
    /// @param limits The limit values for each token in sort order
    /// @param inputs The deadline for the swap, the receiver address and the source token address
    /// @return amountOut The amount of destination token received 
    function balancerMultiSwap(
        IBalancerRouter.BatchSwapStep[] memory swaps,
        address[] calldata assets,
        int256[] calldata limits,
        BalancerMultiInputs calldata inputs
    ) public payable returns (int256[] memory amountOut) {
        SafeTransferLib.safeTransferFrom(
            ERC20(inputs.srcToken),
            msg.sender,
            address(this),
            swaps[0].amount
        );
        unchecked {
            swaps[0].amount = (swaps[0].amount * _fee) / 10000;
        }
        SafeTransferLib.safeApprove(
            ERC20(inputs.srcToken),
            address(balancer),
            swaps[0].amount
        );
        amountOut = balancer.batchSwap(
            IBalancerRouter.SwapKind.GIVEN_IN,
            swaps,
            assets,
            IBalancerRouter.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: inputs.to,
                toInternalBalance: false
            }),
            limits,
            inputs.deadline
        );
    }

    /// @notice Batch swap function using multiple pools on Cruve
    /// @param amountIn The amount of source token to be swapped
    /// @param amountOutMin The minimum amount of destination token to be received
    /// @param path The addresses of tokens to be swapped and unused slots with zero address
    /// @param to The receiver address
    /// @param swapParams Multidimensional array of [i, j, swapType] where i and j are indexes of tokens in each swap
    /// @param pools The pool addresses for the tokens to be swapped
    /// @return amountOut The amount of destination token received
    function CurveMultiSwap(
        uint256 amountIn,
        uint256 amountOutMin,
        address[9] memory path,
        address to,
        uint256[3][4] calldata swapParams,
        address[4] calldata pools
    ) public payable returns (uint256 amountOut) {
        if (msg.value != 0) {
            WETHContract.deposit{value: msg.value}();
            path[0] = ETH_ADDRESS;
            unchecked {
                amountIn = (msg.value * _fee) / 10000;
            }
        } else {
            SafeTransferLib.safeTransferFrom(
                ERC20(path[0]),
                msg.sender,
                address(this),
                amountIn
            );
            unchecked {
                amountIn = (amountIn * _fee) / 10000;
            }
        }
        SafeTransferLib.safeApprove(
            ERC20(path[0]),
            address(curveTC1Router),
            amountIn
        );
        if (msg.value != 0) {
            amountOut = curveTC1Router.exchange_multiple{value: amountIn}(
                path,
                swapParams,
                amountIn,
                amountOutMin,
                pools,
                to
            );
        } else {
            amountOut = curveTC1Router.exchange_multiple(
                path,
                swapParams,
                amountIn,
                amountOutMin,
                pools,
                to
            );
        }
    }

    //////////////////////////////////// PERMIT SWAPS ////////////////////////////////////
    function swapUniV2Permit(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        uint256 deadline,
        address to,
        IUniswapV2Router router,
        bytes calldata permitData
    ) external payable {
        _permit(path[0], permitData);
        uniswapV2MultiSwap(amountIn, amountOutMin, path, deadline, to, router);
    }

    function swapUniV3Permit(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        address payable to,
        address srcToken,
        bytes calldata bytePath,
        bytes calldata permitData
    ) external payable returns (uint256 amountOut) {
        _permit(srcToken, permitData);
        return
            uniswapV3MultiSwap(
                amountIn,
                amountOutMin,
                deadline,
                to,
                srcToken,
                bytePath
            );
    }

    function swapBalancerPermit(
        IBalancerRouter.BatchSwapStep[] memory swaps,
        address[] calldata assets,
        int256[] calldata limits,
        BalancerMultiInputs calldata inputs,
        bytes calldata permitData
    ) external payable returns (int256[] memory amountOut) {
        _permit(inputs.srcToken, permitData);
        return balancerMultiSwap(swaps, assets, limits, inputs);
    }

    function swapCurvePermit(
        uint256 amountIn,
        uint256 amountOutMin,
        address[9] memory path,
        address to,
        uint256[3][4] calldata swapParams,
        address[4] calldata pools,
        bytes calldata permitData
    ) external payable returns (uint256 amountOut) {
        _permit(path[0], permitData);
        return
            CurveMultiSwap(amountIn, amountOutMin, path, to, swapParams, pools);
    }

    ////////////////////////////////////////// ADMIN FUNCTIONS //////////////////////////////////////////
    /// @notice Flushes the balance of the contract for a token to an address
    /// @param _token The address of the token to be flushed
    /// @param _to The address to which the balance will be flushed
    function flush(ERC20 _token, address _to) external {
        uint256 amount = _token.balanceOf(address(this));
        assembly {
            if iszero(
                eq(caller(), 0x123CB0304c7f65B0D48276b9857F4DF4733d1dd8) // Required address to flush
            ) {
                revert(0, 0)
            }
            // We'll write our calldata to this slot.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with function selector
            mstore(0x00, 0xa9059cbb)
            mstore(0x20, _to) // append the 'to' argument
            mstore(0x40, amount) // append the 'amount' argument

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x64 because that's the total length of our call data (0x04 + 0x20 * 3)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), _token, 0, 0x1c, 0x60, 0x00, 0x20)
                    // Adjusted above by changing 0x64 to 0x60
                )
            ) {
                // Store the function selector of TransferFromFailed()
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size)
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero
            mstore(0x40, memPointer) // Restore the mempointer
        }
    }

    /// @notice Flushes the ETH balance of the contract to an address
    /// @param to The address to which the balance will be flushed
    function flushETH(address to) external {
        uint256 amount = address(this).balance;
        assembly {
            if iszero(
                eq(caller(), 0x123CB0304c7f65B0D48276b9857F4DF4733d1dd8) // Required address to flush
            ) {
                revert(0, 0)
            }
            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x64 because that's the total length of our call data (0x04 + 0x20 * 3)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), to, amount, 0, 0, 0, 0)
                    // Adjusted above by changing 0x64 to 0x60
                )
            ) {
                // Store the function selector of TransferFromFailed()
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size)
                revert(0x1c, 0x04)
            }
        }
    }

    /// @notice receive fallback function for empty call data
    receive() external payable {}

    /// @notice fallback function when no other function matches
    fallback() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IUniswapV2Router {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IUniswapV3Router {
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
        uint256 amountOutMin;
    }

    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IBalancerRouter {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct Asset {
        string symbol;
        uint8 decimals;
        uint256 limit;
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    function swap(
        SingleSwap memory swap,
        FundManagement memory fund,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] calldata swaps,
        address[] calldata assets,
        FundManagement memory fund,
        int256[] calldata limits,
        uint256 deadline
    ) external payable returns (int256[] calldata assetDeltas);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ICurveTC1Router {
    function exchange_with_best_rate(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) external returns (uint256);

    function exchange(
        address pool,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) payable external returns (uint256);

    function exchange_multiple(
        address[9] calldata _route,
        uint256[3][4] calldata _swap_params,
        uint256 _amount,
        uint256 _expected,
        address[4] calldata _pools,
        address _receiver
    ) external payable returns (uint256);

    function is_killed() external view returns (bool);

    function registry() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

interface IDaiLikePermit {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract Permitable {
    function _permit(address token, bytes calldata permit) internal {
        if (permit.length > 0) {
            bool success;
            bytes memory result;
            if (permit.length == 32 * 7) {
                // solhint-disable-next-line avoid-low-level-calls
                (success, result) = token.call(
                    abi.encodePacked(IERC20Permit.permit.selector, permit)
                );
            } else if (permit.length == 32 * 8) {
                // solhint-disable-next-line avoid-low-level-calls
                (success, result) = token.call(
                    abi.encodePacked(IDaiLikePermit.permit.selector, permit)
                );
            } else {
                revert("Wrong permit length");
            }
            if (!success) {
                revert("Permit failed: ");
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "./ERC20.sol";

import {SafeTransferLib} from "../utils/SafeTransferLib.sol";

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/WETH.sol)
/// @author Inspired by WETH9 (https://github.com/dapphub/ds-weth/blob/master/src/weth9.sol)
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}