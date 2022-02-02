// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../TridentBatchable.sol";
import "../TridentPermit.sol";
import "../interfaces/IBentoBoxMinimal.sol";
import "../interfaces/ITridentRouter.sol";
import "../interfaces/IMasterDeployer.sol";
import "../interfaces/IPoolFactory.sol";
import "../interfaces/IUniswapV2Minimal.sol";
import "../interfaces/IPool.sol";

/// @notice Liquidity migrator from UniV2 style pool to Trident Constant product pool.
contract TridentSushiRollCP is TridentBatchable, TridentPermit {
    error MinimumOutput();

    IBentoBoxMinimal internal immutable bentoBox;
    IPoolFactory internal immutable poolFactory;
    IMasterDeployer internal immutable masterDeployer;

    constructor(
        IBentoBoxMinimal _bentoBox,
        IPoolFactory _poolFactory,
        IMasterDeployer _masterDeployer
    ) {
        bentoBox = _bentoBox;
        poolFactory = _poolFactory;
        masterDeployer = _masterDeployer;
    }

    /** @notice Function to migrate existing Sushiswap or other Uniswap V2 style pools to Trident.
        @param pair Uniswap V2 style liquidity pool address.
        @param amount Liquidity amount (Lp token balance) to be migrated.
        @param swapFee Swap fee of the Trident CP pool we are migrating into.
        @param twapSupport Whether the Trident CP pool we are migrating into supports twap oracles.
        @param minToken0Received Slippage protection for removing liquidity from a UniV2 style pool.
        @param minToken1Received Slippage protection for removing liquidity from a UniV2 style pool.
        @param minLpReceived Slippage protection for minting liquidity on the Trident CP pool.
        @dev If the pool with the current conditions doesn't exist it will be deployed. */
    function migrate(
        IUniswapV2Minimal pair,
        uint256 amount,
        uint256 swapFee,
        bool twapSupport,
        uint256 minToken0Received,
        uint256 minToken1Received,
        uint256 minLpReceived
    ) external returns (uint256 liquidity) {
        address token0 = pair.token0();
        address token1 = pair.token1();

        bytes memory poolData = abi.encode(token0, token1, swapFee, twapSupport);
        address tridentPool = poolFactory.configAddress(keccak256(poolData));

        if (tridentPool == address(0)) {
            tridentPool = masterDeployer.deployPool(address(poolFactory), poolData);
        }

        pair.transferFrom(msg.sender, address(pair), amount);
        (uint256 amount0, uint256 amount1) = pair.burn(address(bentoBox));

        if (amount0 < minToken0Received || amount1 < minToken1Received) revert MinimumOutput();

        bentoBox.deposit(token0, address(bentoBox), tridentPool, amount0, 0);
        bentoBox.deposit(token1, address(bentoBox), tridentPool, amount1, 0);

        liquidity = IPool(tridentPool).mint(abi.encode(msg.sender));

        if (liquidity < minLpReceived) revert MinimumOutput();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Generic contract exposing the batch call functionality.
abstract contract TridentBatchable {
    /// @notice Provides batch function calls for this contract and returns the data from all of them if they all succeed.
    /// Adapted from https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/base/Multicall.sol, License-Identifier: GPL-2.0-or-later.
    /// @dev The `msg.value` should not be trusted for any method callable from this function.
    /// @param data ABI-encoded params for each of the calls to make to this contract.
    /// @return results The results from each of the calls passed in via `data`.
    function batch(bytes[] calldata data) external payable returns (bytes[] memory results) {
        results = new bytes[](data.length);

        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Generic contract exposing the permit functionality.
abstract contract TridentPermit {
    error PermitFailed();

    /// @notice Provides EIP-2612 signed approval for this contract to spend user tokens.
    /// @param token Address of ERC-20 token.
    /// @param amount Token amount to grant spending right over.
    /// @param deadline Termination for signed approval (UTC timestamp in seconds).
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function permitThis(
        address token,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        (bool success, ) = token.call(abi.encodeWithSelector(0xd505accf, msg.sender, address(this), amount, deadline, v, r, s)); // permit(address,address,uint256,uint256,uint8,bytes32,bytes32).
        if (!success) revert PermitFailed();
    }

    /// @notice Provides DAI-derived signed approval for this contract to spend user tokens.
    /// @param token Address of ERC-20 token.
    /// @param nonce Token owner's nonce - increases at each call to {permit}.
    /// @param expiry Termination for signed approval - UTC timestamp in seconds.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function permitThisAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        (bool success, ) = token.call(abi.encodeWithSelector(0x8fcbaf0c, msg.sender, address(this), nonce, expiry, true, v, r, s)); // permit(address,address,uint256,uint256,bool,uint8,bytes32,bytes32).
        if (!success) revert PermitFailed();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../libraries/RebaseLibrary.sol";

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
    /// @param token The ERC-20 token to deposit.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount represented in shares.
    function deposit(
        address token,
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

    /// @dev Reads the Rebase `totals`from storage for a given token
    function totals(address token) external view returns (Rebase memory total);

    /// @dev Approves users' BentoBox assets to a "master" contract.
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

pragma solidity >=0.8.0;

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

pragma solidity >=0.8.0;

/// @notice Trident pool deployer interface.
interface IMasterDeployer {
    function barFee() external view returns (uint256);

    function barFeeTo() external view returns (address);

    function bento() external view returns (address);

    function migrator() external view returns (address);

    function pools(address pool) external view returns (bool);

    function deployPool(address factory, bytes calldata deployData) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Trident pool deployment interface.
interface IPoolFactory {
    function deployPool(bytes calldata _deployData) external returns (address pool);

    function configAddress(bytes32 data) external returns (address pool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./IERC20.sol";

/// @notice Minimal Uniswap V2 LP interface.
interface IUniswapV2Minimal is IERC20 {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

/// @notice Trident pool interface.
interface IPool {
    /// @notice Executes a swap from one token to another.
    /// @dev The input tokens must've already been sent to the pool.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that were sent to the user.
    function swap(bytes calldata data) external returns (uint256 finalAmountOut);

    /// @notice Executes a swap from one token to another with a callback.
    /// @dev This function allows borrowing the output tokens and sending the input tokens in the callback.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that were sent to the user.
    function flashSwap(bytes calldata data) external returns (uint256 finalAmountOut);

    /// @notice Mints liquidity tokens.
    /// @param data ABI-encoded params that the pool requires.
    /// @return liquidity The amount of liquidity tokens that were minted for the user.
    function mint(bytes calldata data) external returns (uint256 liquidity);

    /// @notice Burns liquidity tokens.
    /// @dev The input LP tokens must've already been sent to the pool.
    /// @param data ABI-encoded params that the pool requires.
    /// @return withdrawnAmounts The amount of various output tokens that were sent to the user.
    function burn(bytes calldata data) external returns (TokenAmount[] memory withdrawnAmounts);

    /// @notice Burns liquidity tokens for a single output token.
    /// @dev The input LP tokens must've already been sent to the pool.
    /// @param data ABI-encoded params that the pool requires.
    /// @return amountOut The amount of output tokens that were sent to the user.
    function burnSingle(bytes calldata data) external returns (uint256 amountOut);

    /// @return A unique identifier for the pool type.
    function poolIdentifier() external pure returns (bytes32);

    /// @return An array of tokens supported by the pool.
    function getAssets() external view returns (address[] memory);

    /// @notice Simulates a trade and returns the expected output.
    /// @dev The pool does not need to include a trade simulator directly in itself - it can use a library.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that will be sent to the user if the trade is executed.
    function getAmountOut(bytes calldata data) external view returns (uint256 finalAmountOut);

    /// @notice Simulates a trade and returns the expected output.
    /// @dev The pool does not need to include a trade simulator directly in itself - it can use a library.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountIn The amount of input tokens that are required from the user if the trade is executed.
    function getAmountIn(bytes calldata data) external view returns (uint256 finalAmountIn);

    /// @dev This event must be emitted on all swaps.
    event Swap(address indexed recipient, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    /// @dev This struct frames output tokens for burns.
    struct TokenAmount {
        address token;
        uint256 amount;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8;

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library
library RebaseLibrary {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(Rebase memory total, uint256 elastic) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(Rebase memory total, uint256 base) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @dev Use a library or custom safeTransfer{From} functions when dealing with unknown tokens!
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}