// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.11;

import "./interfaces/ISushiXSwap.sol";

/// @title SushiXSwap
/// @notice Enables cross chain swap for sushiswap.
/// @dev Supports both BentoBox and Wallet. Supports both Trident and Legacy AMM. Uses Stargate as bridge.
contract SushiXSwap is
    ISushiXSwap,
    BentoAdapter,
    TokenAdapter,
    SushiLegacyAdapter,
    TridentSwapAdapter,
    StargateAdapter
{
    constructor(
        IBentoBoxMinimal _bentoBox,
        IStargateRouter _stargateRouter,
        address _factory,
        bytes32 _pairCodeHash,
        IStargateWidget _stargateWidget
    ) ImmutableState(_bentoBox, _stargateRouter, _factory, _pairCodeHash, _stargateWidget) {
        // Register to BentoBox
        _bentoBox.registerProtocol();
    }

    /// @notice List of ACTIONS supported by the `cook()`.

    // Bento and Token Operations
    uint8 internal constant ACTION_MASTER_CONTRACT_APPROVAL = 0;
    uint8 internal constant ACTION_SRC_DEPOSIT_TO_BENTOBOX = 1;
    uint8 internal constant ACTION_SRC_TRANSFER_FROM_BENTOBOX = 2;
    uint8 internal constant ACTION_DST_DEPOSIT_TO_BENTOBOX = 3;
    uint8 internal constant ACTION_DST_WITHDRAW_TOKEN = 4;
    uint8 internal constant ACTION_DST_WITHDRAW_OR_TRANSFER_FROM_BENTOBOX = 5;
    uint8 internal constant ACTION_UNWRAP_AND_TRANSFER = 6;

    // Swap Operations
    uint8 internal constant ACTION_LEGACY_SWAP = 7;
    uint8 internal constant ACTION_TRIDENT_SWAP = 8;
    uint8 internal constant ACTION_TRIDENT_COMPLEX_PATH_SWAP = 9;

    // Bridge Operations
    uint8 internal constant ACTION_STARGATE_TELEPORT = 10;

    uint8 internal constant ACTION_SRC_TOKEN_TRANSFER = 11;

    /// @notice Executes a set of actions and allows composability (contract calls) to other contracts.
    /// @param actions An array with a sequence of actions to execute (see ACTION_ declarations).
    /// @param values A one-to-one mapped array to `actions`. Native token amount to send along action.
    /// @param datas A one-to-one mapped array to `actions`. Contains abi encoded data of function arguments.
    /// @dev The function gets invoked both at the src and dst chain.
    function cook(
        uint8[] memory actions,
        uint256[] memory values,
        bytes[] memory datas
    ) public payable override {
        uint256 actionLength = actions.length;
        for (uint256 i; i < actionLength; i = _increment(i)) {
            uint8 action = actions[i];
            // update for total amounts in contract?
            if (action == ACTION_MASTER_CONTRACT_APPROVAL) {
                (
                    address user,
                    bool approved,
                    uint8 v,
                    bytes32 r,
                    bytes32 s
                ) = abi.decode(
                        datas[i],
                        (address, bool, uint8, bytes32, bytes32)
                    );

                bentoBox.setMasterContractApproval(
                    user,
                    address(this),
                    approved,
                    v,
                    r,
                    s
                );
            } else if (action == ACTION_SRC_DEPOSIT_TO_BENTOBOX) {
                (address token, address to, uint256 amount, uint256 share) = abi
                    .decode(datas[i], (address, address, uint256, uint256));
                _depositToBentoBox(
                    token,
                    msg.sender,
                    to,
                    amount,
                    share,
                    values[i]
                );
            } else if (action == ACTION_SRC_TRANSFER_FROM_BENTOBOX) {
                (
                    address token,
                    address to,
                    uint256 amount,
                    uint256 share,
                    bool unwrapBento
                ) = abi.decode(
                        datas[i],
                        (address, address, uint256, uint256, bool)
                    );
                _transferFromBentoBox(
                    token,
                    msg.sender,
                    to,
                    amount,
                    share,
                    unwrapBento
                );
            } else if (action == ACTION_SRC_TOKEN_TRANSFER) {
                (address token, address to, uint256 amount) = abi.decode(
                    datas[i],
                    (address, address, uint256)
                );

                _transferFromToken(IERC20(token), to, amount);
            } else if (action == ACTION_DST_DEPOSIT_TO_BENTOBOX) {
                (address token, address to, uint256 amount, uint256 share) = abi
                    .decode(datas[i], (address, address, uint256, uint256));

                if (amount == 0) {
                    amount = IERC20(token).balanceOf(address(this));
                    // Stargate Router doesn't support value? Should we update it anyway?
                    // values[i] = address(this).balance;
                }

                _transferTokens(IERC20(token), address(bentoBox), amount);

                _depositToBentoBox(
                    token,
                    address(bentoBox),
                    to,
                    amount,
                    share,
                    values[i]
                );
            } else if (action == ACTION_DST_WITHDRAW_TOKEN) {
                (address token, address to, uint256 amount) = abi.decode(
                    datas[i],
                    (address, address, uint256)
                );
                if (amount == 0) {
                    if (token != address(0)) {
                        amount = IERC20(token).balanceOf(address(this));
                    } else {
                        amount = address(this).balance;
                    }
                }
                _transferTokens(IERC20(token), to, amount);
            } else if (
                action == ACTION_DST_WITHDRAW_OR_TRANSFER_FROM_BENTOBOX
            ) {
                (
                    address token,
                    address to,
                    uint256 amount,
                    uint256 share,
                    bool unwrapBento
                ) = abi.decode(
                        datas[i],
                        (address, address, uint256, uint256, bool)
                    );
                if (amount == 0 && share == 0) {
                    share = bentoBox.balanceOf(token, address(this));
                }
                _transferFromBentoBox(
                    token,
                    address(this),
                    to,
                    amount,
                    share,
                    unwrapBento
                );
            } else if (action == ACTION_UNWRAP_AND_TRANSFER) {
                (address token, address to) = abi.decode(
                    datas[i],
                    (address, address)
                );

                _unwrapTransfer(token, to);
            } else if (action == ACTION_LEGACY_SWAP) {
                (
                    uint256 amountIn,
                    uint256 amountOutMin,
                    address[] memory path,
                    address to
                ) = abi.decode(
                        datas[i],
                        (uint256, uint256, address[], address)
                    );
                bool sendTokens;
                if (amountIn == 0) {
                    amountIn = IERC20(path[0]).balanceOf(address(this));
                    sendTokens = true;
                }
                _swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    path,
                    to,
                    sendTokens
                );
            } else if (action == ACTION_TRIDENT_SWAP) {
                ExactInputParams memory params = abi.decode(
                    datas[i],
                    (ExactInputParams)
                );

                _exactInput(params);
            } else if (action == ACTION_TRIDENT_COMPLEX_PATH_SWAP) {
                ComplexPathParams memory params = abi.decode(
                    datas[i],
                    (ComplexPathParams)
                );

                _complexPath(params);
            } else if (action == ACTION_STARGATE_TELEPORT) {
                (
                    StargateTeleportParams memory params,
                    uint8[] memory actionsDST,
                    uint256[] memory valuesDST,
                    bytes[] memory datasDST
                ) = abi.decode(
                        datas[i],
                        (StargateTeleportParams, uint8[], uint256[], bytes[])
                    );

                _stargateTeleport(params, actionsDST, valuesDST, datasDST);
            }
        }
    }

    /// @notice Allows the contract to receive Native tokens
    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.11;

import "../adapters/BentoAdapter.sol";
import "../adapters/TokenAdapter.sol";
import "../adapters/SushiLegacyAdapter.sol";
import "../adapters/TridentSwapAdapter.sol";
import "../adapters/StargateAdapter.sol";

interface ISushiXSwap {
    function cook(
        uint8[] memory actions,
        uint256[] memory values,
        bytes[] memory datas
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.11;

import "../interfaces/IBentoBoxMinimal.sol";
import "../base/ImmutableState.sol";

/// @title BentoAdapter
/// @notice Adapter which provides all functions of BentoBox require by this contract.
/// @dev These are generic functions, make sure, only msg.sender, address(this) and address(bentoBox)
/// are passed in the from param, or else the attacker can sifu user's funds in bentobox.
abstract contract BentoAdapter is ImmutableState {
    /// @notice Deposits the token from users wallet into the BentoBox.
    /// @dev Make sure, only msg.sender, address(this) and address(bentoBox)
    /// are passed in the from param, or else the attacker can sifu user's funds in bentobox.
    /// Pass either amount or share.
    /// @param token token to deposit. Use token as address(0) when depositing native token
    /// @param from sender
    /// @param to receiver
    /// @param amount amount to be deposited
    /// @param share share to be deposited
    /// @param value native token value to be deposited. Only use when token address is address(0)
    function _depositToBentoBox(
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 share,
        uint256 value
    ) internal {
        bentoBox.deposit{value: value}(token, from, to, amount, share);
    }

    /// @notice Transfers the token from bentobox user to another or withdraw it to another address.
    /// @dev Make sure, only msg.sender, address(this) and address(bentoBox)
    /// are passed in the from param, or else the attacker can sifu user's funds in bentobox.
    /// Pass either amount or share.
    /// @param token token to transfer. For native tokens, use wnative token address
    /// @param from sender
    /// @param to receiver
    /// @param amount amount to transfer
    /// @param share share to transfer
    /// @param unwrapBento use true for withdraw and false for transfer
    function _transferFromBentoBox(
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 share,
        bool unwrapBento
    ) internal {
        if (unwrapBento) {
            bentoBox.withdraw(token, from, to, amount, share);
        } else {
            if (amount > 0) {
                share = bentoBox.toShare(token, amount, false);
            }
            bentoBox.transfer(token, from, to, share);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWETH.sol";

/// @title TokenAdapter
/// @notice Adapter for all token operations
abstract contract TokenAdapter {
    using SafeERC20 for IERC20;

    /// @notice Function to transfer tokens from address(this)
    /// @param token token to transfer
    /// @param to receiver
    /// @param amount amount to transfer
    function _transferTokens(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (address(token) != address(0)) {
            token.safeTransfer(to, amount);
        } else {
            payable(to).transfer(amount);
        }
    }

    /// @notice Function to transfer tokens from user to the to address
    /// @param token token to transfer
    /// @param to receiver
    /// @param amount amount to transfer
    function _transferFromToken(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        token.safeTransferFrom(msg.sender, to, amount);
    }

    /// @notice Unwraps the wrapper native into native and sends it to the receiver.
    /// @param token token to transfer
    /// @param to receiver
    function _unwrapTransfer(address token, address to) internal {
        IWETH(token).withdraw(IERC20(token).balanceOf(address(this)));
        _transferTokens(IERC20(address(0)), to, address(this).balance);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../libraries/UniswapV2Library.sol";
import "../base/ImmutableState.sol";

/// @title SushiLegacyAdapter
/// @notice Adapter for functions used to swap using Sushiswap Legacy AMM.
abstract contract SushiLegacyAdapter is ImmutableState {
    using SafeERC20 for IERC20;

    function _swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        bool sendTokens
    ) internal returns (uint256 amountOut) {
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(
            factory,
            amountIn,
            path,
            pairCodeHash
        );
        amountOut = amounts[amounts.length - 1];

        require(amountOut >= amountOutMin, "insufficient-amount-out");

        /// @dev force sends token to the first pair if not already sent
        if (sendTokens) {
            IERC20(path[0]).safeTransfer(
                UniswapV2Library.pairFor(
                    factory,
                    path[0],
                    path[1],
                    pairCodeHash
                ),
                IERC20(path[0]).balanceOf(address(this))
            );
        }
        _swap(amounts, path, to);
    }

    /// @dev requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2
                ? UniswapV2Library.pairFor(
                    factory,
                    output,
                    path[i + 2],
                    pairCodeHash
                )
                : _to;
            IUniswapV2Pair(
                UniswapV2Library.pairFor(factory, input, output, pairCodeHash)
            ).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.11;

import "../interfaces/trident/ITridentSwapAdapter.sol";

/// @title TridentSwapAdapter
/// @notice Adapter for all Trident based Swaps

abstract contract TridentSwapAdapter is
    ITridentRouter,
    ImmutableState,
    BentoAdapter,
    TokenAdapter
{
    // Custom Error
    error TooLittleReceived();

    /// @notice Swaps token A to token B directly. Swaps are done on `bento` tokens.
    /// @param params This includes the address of token A, pool, amount of token A to swap,
    /// minimum amount of token B after the swap and data required by the pool for the swap.
    /// @dev Ensure that the pool is trusted before calling this function. The pool can steal users' tokens.
    function _exactInput(ExactInputParams memory params)
        internal
        returns (uint256 amountOut)
    {
        if (params.amountIn == 0) {
          uint256 tokenBalance = IERC20(params.tokenIn).balanceOf(
                address(this)
            );
            _transferTokens(
                IERC20(params.tokenIn),
                address(bentoBox),
                tokenBalance
            );
            // Pay the first pool directly.
            (, params.amountIn) = bentoBox.deposit(
                params.tokenIn,
                address(bentoBox),
                params.path[0].pool,
                tokenBalance,
                0
            );
        }

        // Call every pool in the path.
        // Pool `N` should transfer its output tokens to pool `N+1` directly.
        // The last pool should transfer its output tokens to the user.
        // If the user wants to unwrap `wETH`, the final destination should be this contract and
        // a batch call should be made to `unwrapWETH`.
        uint256 n = params.path.length;
        for (uint256 i = 0; i < n; i = _increment(i)) {
            amountOut = IPool(params.path[i].pool).swap(params.path[i].data);
        }
        // Ensure that the slippage wasn't too much. This assumes that the pool is honest.
        if (amountOut < params.amountOutMinimum) revert TooLittleReceived();
    }

    /// @notice Swaps multiple input tokens to multiple output tokens using multiple paths, in different percentages.
    /// For example, you can swap 50 DAI + 100 USDC into 60% ETH and 40% BTC.
    /// @param params This includes everything needed for the swap.
    /// Look at the `ComplexPathParams` struct for more details.
    /// @dev This function is not optimized for single swaps and should only be used in complex cases where
    /// the amounts are large enough that minimizing slippage by using multiple paths is worth the extra gas.
    function _complexPath(ComplexPathParams memory params) internal {
        // Deposit all initial tokens to respective pools and initiate the swaps.
        // Input tokens come from the user - output goes to following pools.
        uint256 n = params.initialPath.length;
        for (uint256 i = 0; i < n; i = _increment(i)) {
            bentoBox.transfer(
                params.initialPath[i].tokenIn,
                address(this),
                params.initialPath[i].pool,
                params.initialPath[i].amount
            );
            IPool(params.initialPath[i].pool).swap(params.initialPath[i].data);
        }
        // Do all the middle swaps. Input comes from previous pools.
        n = params.percentagePath.length;
        for (uint256 i = 0; i < n; i = _increment(i)) {
            uint256 balanceShares = bentoBox.balanceOf(
                params.percentagePath[i].tokenIn,
                address(this)
            );
            uint256 transferShares = (balanceShares *
                params.percentagePath[i].balancePercentage) / uint256(10)**8;
            bentoBox.transfer(
                params.percentagePath[i].tokenIn,
                address(this),
                params.percentagePath[i].pool,
                transferShares
            );
            IPool(params.percentagePath[i].pool).swap(
                params.percentagePath[i].data
            );
        }
        // Ensure enough was received and transfer the ouput to the recipient.
        n = params.output.length;
        for (uint256 i = 0; i < n; i = _increment(i)) {
            uint256 balanceShares = bentoBox.balanceOf(
                params.output[i].token,
                address(this)
            );
            if (balanceShares < params.output[i].minAmount)
                revert TooLittleReceived();
            if (params.output[i].unwrapBento) {
                bentoBox.withdraw(
                    params.output[i].token,
                    address(this),
                    params.output[i].to,
                    0,
                    balanceShares
                );
            } else {
                bentoBox.transfer(
                    params.output[i].token,
                    address(this),
                    params.output[i].to,
                    balanceShares
                );
            }
        }
    }

    function _increment(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.11;

import "../interfaces/stargate/IStargateAdapter.sol";

/// @title StargateAdapter
/// @notice Adapter for function used by Stargate Bridge
abstract contract StargateAdapter is ImmutableState, IStargateReceiver {
    using SafeERC20 for IERC20;

    // Custom Error
    error NotStargateRouter();

    // events
    event StargateSushiXSwapSrc(bytes32 indexed srcContext);
    event StargateSushiXSwapDst(bytes32 indexed srcContext, bool failed);

    struct StargateTeleportParams {
        uint16 dstChainId; // stargate dst chain id
        address token; // token getting bridged
        uint256 srcPoolId; // stargate src pool id
        uint256 dstPoolId; // stargate dst pool id
        uint256 amount; // amount to bridge
        uint256 amountMin; // amount to bridge minimum
        uint256 dustAmount; // native token to be received on dst chain
        address receiver; // sushiXswap on dst chain
        address to; // receiver bridge token incase of transaction reverts on dst chain
        uint256 gas; // extra gas to be sent for dst chain operations
        bytes32 srcContext; // random bytes32 as source context
    }

    /// @notice Approves token to the Stargate Router
    /// @param token token to approve
    function approveToStargateRouter(IERC20 token) external {
        token.safeApprove(address(stargateRouter), type(uint256).max);
    }

    /// @notice Bridges the token to dst chain using Stargate Router
    /// @dev It is hardcoded to use all the contract balance. Only call this as the last step.
    /// The refund address for extra fees sent it msg.sender.
    /// @param params required by the Stargate, can be found at StargateTeleportParams struct.
    /// @param actions An array with a sequence of actions to execute (see ACTION_ declarations).
    /// @param values A one-to-one mapped array to `actions`. Native token amount to send along action.
    /// @param datas A one-to-one mapped array to `actions`. Contains abi encoded data of function arguments.
    function _stargateTeleport(
        StargateTeleportParams memory params,
        uint8[] memory actions,
        uint256[] memory values,
        bytes[] memory datas
    ) internal {
        bytes memory payload = abi.encode(params.to, actions, values, datas, params.srcContext);

        stargateRouter.swap{value: address(this).balance}(
            params.dstChainId,
            params.srcPoolId,
            params.dstPoolId,
            payable(msg.sender), // refund address
            params.amount != 0
                ? params.amount
                : IERC20(params.token).balanceOf(address(this)),
            params.amountMin,
            IStargateRouter.lzTxObj(
                params.gas, // extra gas to be sent for dst execution
                params.dustAmount,
                abi.encodePacked(params.receiver)
            ),
            abi.encodePacked(params.receiver), // sushiXswap on the dst chain
            payload
        );

        stargateWidget.partnerSwap(0x0001);

        emit StargateSushiXSwapSrc(params.srcContext);
    }

    /// @notice Get the fees to be paid in native token for the swap
    /// @param _dstChainId stargate dst chainId
    /// @param _functionType stargate Function type 1 for swap.
    /// See more at https://stargateprotocol.gitbook.io/stargate/developers/function-types
    /// @param _receiver sushiXswap on the dst chain
    /// @param _gas extra gas being sent
    /// @param _dustAmount dust amount to be received at the dst chain
    /// @param _payload payload being sent at the dst chain
    function getFee(
        uint16 _dstChainId,
        uint8 _functionType,
        address _receiver,
        uint256 _gas,
        uint256 _dustAmount,
        bytes memory _payload
    ) external view returns (uint256 a, uint256 b) {
        (a, b) = stargateRouter.quoteLayerZeroFee(
            _dstChainId,
            _functionType,
            abi.encodePacked(_receiver),
            abi.encode(_payload),
            IStargateRouter.lzTxObj(
                _gas,
                _dustAmount,
                abi.encodePacked(_receiver)
            )
        );
    }

    /// @notice Receiver function on dst chain
    /// @param _token bridge token received
    /// @param amountLD amount received
    /// @param payload ABI-Encoded data received from src chain
    function sgReceive(
        uint16,
        bytes memory,
        uint256,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external override {
        if (msg.sender != address(stargateRouter)) revert NotStargateRouter();

        (
            address to,
            uint8[] memory actions,
            uint256[] memory values,
            bytes[] memory datas,
            bytes32 srcContext
        ) = abi.decode(payload, (address, uint8[], uint256[], bytes[], bytes32));

        // 100000 -> exit gas
        uint256 limit = gasleft() - 200000;
        bool failed;
        /// @dev incase the actions fail, transfer bridge token to the to address
        try
            ISushiXSwap(payable(address(this))).cook{gas: limit}(
                actions,
                values,
                datas
            )
        {} catch (bytes memory) {
            IERC20(_token).safeTransfer(to, amountLD);
            failed = true;
        }

        /// @dev transfer any native token received as dust to the to address
        if (address(this).balance > 0)
            to.call{value: (address(this).balance)}("");

        emit StargateSushiXSwapDst(srcContext, failed);

    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.11;

/// @notice Minimal BentoBox vault interface.
/// @dev `token` is aliased as `address` from `IERC20` for simplicity.
interface IBentoBoxMinimal {
    /// @notice Balance per ERC-20 token per account in shares.
    function balanceOf(address, address) external view returns (uint256);

    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param token The ERC-20 token.
    /// @param amount The `token` amount.
    /// @param roundUp If the result `share` should be rounded up.
    /// @return share The token amount represented in shares.
    function toShare(
        address token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    /// @dev Helper function to represent shares back into the `token` amount.
    /// @param token The ERC-20 token.
    /// @param share The amount of shares.
    /// @param roundUp If the result should be rounded up.
    /// @return amount The share amount back into native representation.
    function toAmount(
        address token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    /// @notice Registers this contract so that users can approve it for BentoBox.
    function registerProtocol() external;

    /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
    /// @param token_ The ERC-20 token to deposit.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount represented in shares.
    function deposit(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    /// @notice Withdraws an amount of `token` from a user account.
    /// @param token_ The ERC-20 token to withdraw.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
    /// @param share Like above, but `share` takes precedence over `amount`.
    function withdraw(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    /// @notice Transfer shares from a user account to another one.
    /// @param token The ERC-20 token to transfer.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param share The amount of `token` in shares.
    function transfer(
        address token,
        address from,
        address to,
        uint256 share
    ) external;

    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.11;

import "../interfaces/IImmutableState.sol";

/// @title ImmutableState
/// @notice Stores the immutable state
abstract contract ImmutableState is IImmutableState {
    /// @notice BentoBox token vault
    IBentoBoxMinimal public immutable override bentoBox;

    /// @notice Stargate Router for cross chain interaction
    IStargateRouter public immutable override stargateRouter;

    /// @notice Stargate Widget for stargate partner fee
    IStargateWidget public immutable override stargateWidget;

    /// @notice Sushiswap Legacy AMM Factory
    address public immutable override factory;

    /// @notice Sushiswap Legacy AMM PairCodeHash
    bytes32 public immutable override pairCodeHash;

    constructor(
        IBentoBoxMinimal _bentoBox,
        IStargateRouter _stargateRouter,
        address _factory,
        bytes32 _pairCodeHash,
        IStargateWidget _stargateWidget
    ) {
        bentoBox = _bentoBox;
        stargateRouter = _stargateRouter;
        stargateWidget = _stargateWidget;
        factory = _factory;
        pairCodeHash = _pairCodeHash;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.11;

import "./IBentoBoxMinimal.sol";
import "./stargate/IStargateRouter.sol";
import "./stargate/IStargateWidget.sol";

interface IImmutableState {
    function bentoBox() external view returns (IBentoBoxMinimal);

    function stargateRouter() external view returns (IStargateRouter);

    function stargateWidget() external view returns (IStargateWidget);

    function factory() external view returns (address);

    function pairCodeHash() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

interface IStargateRouter {

    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

interface IStargateWidget {
    function partnerSwap(bytes2 _partnerId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.11;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMathUniswap for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 pairCodeHash
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            pairCodeHash // init code hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 pairCodeHash
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            pairFor(factory, tokenA, tokenB, pairCodeHash)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path,
        bytes32 pairCodeHash
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1],
                pairCodeHash
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path,
        bytes32 pairCodeHash
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i],
                pairCodeHash
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.11;

import "./ITridentRouter.sol";
import "../../adapters/BentoAdapter.sol";
import "../../adapters/TokenAdapter.sol";
import "../../base/ImmutableState.sol";

interface ITridentSwapAdapter {}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.11;

import "./IPool.sol";
import "../IBentoBoxMinimal.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

/// @notice Trident pool router interface.
interface ITridentRouter {
    struct Path {
        address pool;
        bytes data;
    }

    struct ExactInputSingleParams {
        uint256 amountIn;
        uint256 amountOutMinimum;
        address pool;
        address tokenIn;
        bytes data;
    }

    struct ExactInputParams {
        address tokenIn;
        uint256 amountIn;
        uint256 amountOutMinimum;
        Path[] path;
    }

    struct TokenInput {
        address token;
        bool native;
        uint256 amount;
    }

    struct InitialPath {
        address tokenIn;
        address pool;
        bool native;
        uint256 amount;
        bytes data;
    }

    struct PercentagePath {
        address tokenIn;
        address pool;
        uint64 balancePercentage; // Multiplied by 10^6. 100% = 100_000_000
        bytes data;
    }

    struct Output {
        address token;
        address to;
        bool unwrapBento;
        uint256 minAmount;
    }

    struct ComplexPathParams {
        InitialPath[] initialPath;
        PercentagePath[] percentagePath;
        Output[] output;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.11;

/// @notice Trident pool interface.
interface IPool {
    /// @notice Executes a swap from one token to another.
    /// @dev The input tokens must've already been sent to the pool.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that were sent to the user.
    function swap(bytes calldata data)
        external
        returns (uint256 finalAmountOut);

    /// @notice Executes a swap from one token to another with a callback.
    /// @dev This function allows borrowing the output tokens and sending the input tokens in the callback.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that were sent to the user.
    function flashSwap(bytes calldata data)
        external
        returns (uint256 finalAmountOut);

    /// @notice Mints liquidity tokens.
    /// @param data ABI-encoded params that the pool requires.
    /// @return liquidity The amount of liquidity tokens that were minted for the user.
    function mint(bytes calldata data) external returns (uint256 liquidity);

    /// @notice Burns liquidity tokens.
    /// @dev The input LP tokens must've already been sent to the pool.
    /// @param data ABI-encoded params that the pool requires.
    /// @return withdrawnAmounts The amount of various output tokens that were sent to the user.
    function burn(bytes calldata data)
        external
        returns (TokenAmount[] memory withdrawnAmounts);

    /// @notice Burns liquidity tokens for a single output token.
    /// @dev The input LP tokens must've already been sent to the pool.
    /// @param data ABI-encoded params that the pool requires.
    /// @return amountOut The amount of output tokens that were sent to the user.
    function burnSingle(bytes calldata data)
        external
        returns (uint256 amountOut);

    /// @return A unique identifier for the pool type.
    function poolIdentifier() external pure returns (bytes32);

    /// @return An array of tokens supported by the pool.
    function getAssets() external view returns (address[] memory);

    /// @notice Simulates a trade and returns the expected output.
    /// @dev The pool does not need to include a trade simulator directly in itself - it can use a library.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that will be sent to the user if the trade is executed.
    function getAmountOut(bytes calldata data)
        external
        view
        returns (uint256 finalAmountOut);

    /// @notice Simulates a trade and returns the expected output.
    /// @dev The pool does not need to include a trade simulator directly in itself - it can use a library.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountIn The amount of input tokens that are required from the user if the trade is executed.
    function getAmountIn(bytes calldata data)
        external
        view
        returns (uint256 finalAmountIn);

    /// @dev This event must be emitted on all swaps.
    event Swap(
        address indexed recipient,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @dev This struct frames output tokens for burns.
    struct TokenAmount {
        address token;
        uint256 amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../base/ImmutableState.sol";
import "../ISushiXSwap.sol";
import "./IStargateReceiver.sol";
import "./IStargateWidget.sol";

interface IStargateAdapter {}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

interface IStargateReceiver {
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external;
}