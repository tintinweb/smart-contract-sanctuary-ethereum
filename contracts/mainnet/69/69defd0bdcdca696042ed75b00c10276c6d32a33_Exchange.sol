// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

// https://github.com/makerdao/dss/blob/master/src/dai.sol
interface DaiAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function version() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function nonces(address) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function approve(address, uint256) external returns (bool);
    function push(address, uint256) external;
    function pull(address, uint256) external;
    function move(address, address, uint256) external;
    function permit(address, address, uint256, uint256, bool, uint8, bytes32, bytes32) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

// https://github.com/makerdao/dss/blob/master/src/join.sol
interface GemJoinAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function gem() external view returns (address);
    function dec() external view returns (uint256);
    function live() external view returns (uint256);
    function cage() external;
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

// https://github.com/makerdao/dss-psm/blob/master/src/psm.sol
interface PsmAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function gemJoin() external view returns (address);
    function dai() external view returns (address);
    function daiJoin() external view returns (address);
    function ilk() external view returns (bytes32);
    function vow() external view returns (address);
    function tin() external view returns (uint256);
    function tout() external view returns (uint256);
    function file(bytes32 what, uint256 data) external;
    function hope(address) external;
    function nope(address) external;
    function sellGem(address usr, uint256 gemAmt) external;
    function buyGem(address usr, uint256 gemAmt) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
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

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

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

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
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

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
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

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
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

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeTransferLib.sol";

import "makerdao/dss/DaiAbstract.sol";
import "makerdao/dss/PsmAbstract.sol";
import "makerdao/dss/GemJoinAbstract.sol";

import "univ3/interfaces/IUniswapV3Pool.sol";
import "univ3/interfaces/callback/IUniswapV3SwapCallback.sol";

import {I3PoolCurve} from "./interfaces/I3PoolCurve.sol";
import {IBondingCurve} from "./interfaces/IBondingCurve.sol";
import {IForeignBridge} from "./interfaces/IForeignBridge.sol";

enum Stablecoin {
    DAI,
    USDC,
    USDT
}

enum LiquidityProvider {
    NONE,
    DAI_PSM,
    CURVE_FI_3POOL,
    UNISWAP_V3
}

struct BuyParams {
    // the amount of bzz to buy
    uint256 bzzAmount;
    // the maximum amount of stablecoin (in native stablecoin decimals) to pay for `bzzAmount`
    uint256 maxStablecoinAmount;
    // the stablecoin to use for payment
    Stablecoin inputCoin;
    // the liquidity provider to use for payment
    LiquidityProvider lp;
    // options as a byte
    // bit 0: whether to use permit
    // bit 1: whether to use the bridge
    // therefore options = 1 means use permit, options = 2 means use bridge, options = 3 means use both
    uint256 options;
    // the data for the permit and/or bridge
    bytes data;
}

struct SellParams {
    // the amount of bzz to sell
    uint256 bzzAmount;
    // the minimum amount of stablecoin to receive for `bzzAmount`
    uint256 minStablecoinAmount;
    // which stablecoin to sell to
    Stablecoin outputCoin;
    // the liquidity provider to use for payment
    LiquidityProvider lp;
}

contract Exchange is Owned, IUniswapV3SwapCallback {
    using SafeTransferLib for ERC20;

    // --- constants

    // maximum fee is hardcoded at 100 basis points (1%)
    uint256 public constant MAX_FEE = 100;

    /// @dev the conversion rate from 6 decimals to 18 decimals (USDC/USDT to DAI)
    uint256 internal constant TO_DAI = 1000000000000;

    /// @notice Uniswap V3 pool constants from TickMath
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    // --- immutables

    // tokens that are processed in this exchange
    ERC20 private immutable dai;
    ERC20 private immutable bzz;
    ERC20 private immutable usdc;
    ERC20 private immutable usdt;

    // the bonding curve we use for exchanging dai <--> bzz
    IBondingCurve public immutable bc;

    // the curve.fi 3pool we use for exchanging dai <--> usdc/usdt
    I3PoolCurve public immutable curveFi3Pool;

    // the uniswap v3 pool we use for exchanging usdc <--> dai
    IUniswapV3Pool public immutable usdcV3Pool;
    IUniswapV3Pool public immutable usdtV3Pool;

    // the foreign bridge we use for relaying tokens
    IForeignBridge public immutable bridge;

    // the dai psm contract (this comes in handy when moving large amounts of usdc)
    PsmAbstract public immutable psm;

    // --- state
    uint256 public fee;

    constructor(
        address owner,
        address _bc,
        address _curveFi3Pool,
        address _usdcUniswapV3Pool,
        address _usdtUniswapV3Pool,
        address _psm,
        address _bridge,
        uint256 _fee
    ) Owned(owner) {
        require(_fee <= MAX_FEE, "fee/too-high");

        // the bonding curve that we are going to use
        bc = IBondingCurve(_bc);
        // the curve.fi 3pool that we are going to use
        curveFi3Pool = I3PoolCurve(_curveFi3Pool);
        // the amb (arbitrary message bridge) for relaying tokens
        bridge = IForeignBridge(_bridge);
        // the dai psm contract
        psm = PsmAbstract(_psm);

        // the uniswap v3 pool that we are going to use
        usdcV3Pool = IUniswapV3Pool(_usdcUniswapV3Pool);
        usdtV3Pool = IUniswapV3Pool(_usdtUniswapV3Pool);

        // these are the tokens that we are exchanging on the bonding curve
        bzz = ERC20(bc.bondedToken());
        dai = ERC20(bc.collateralToken());

        // other tokens that we can exchange on the curve.fi curve
        usdc = ERC20(curveFi3Pool.coins(1));
        require(usdcV3Pool.token0() == address(dai) && usdcV3Pool.token1() == address(usdc), "exchange/v3-pool/invalid");
        usdt = ERC20(curveFi3Pool.coins(2));
        require(usdtV3Pool.token0() == address(dai) && usdtV3Pool.token1() == address(usdt), "exchange/v3-pool/invalid");

        /// @notice pre-approve the bonding curve for unlimited approval of the exchange's bzz and dai
        dai.approve(address(bc), type(uint256).max);
        bzz.approve(address(bc), type(uint256).max);

        /// @notice pre-approve the curve.fi 3pool for unlimited approval of the exchange's dai, usdc and usdt
        dai.approve(address(curveFi3Pool), type(uint256).max);
        usdc.approve(address(curveFi3Pool), type(uint256).max);
        // have to use the safeApprove function because the usdt token has a non-standard approve function 🤮
        usdt.safeApprove(address(curveFi3Pool), type(uint256).max);

        /// @notice there is no need to pre-approve uniswap v3 pools as these transactions
        //          are done using callbacks

        /// @notice pre-approve the bridge for unlimited spending approval of the exchange's bzz tokens
        /// @dev this may be a security risk if the bridge is hacked, and could subsequently drain
        ///      any fees that this contract may have accumulated, though this motivates the owners
        ///      to regularly sweep tokens from the exchange that have accumulated as fees
        bzz.approve(address(bridge), type(uint256).max);

        /// @notice pre-approve the dai psm gemjoiner for unlimited spending approval of the exchange's usdc tokens
        /// @dev this may be a security risk if the psm is hacked, and could subsequently drain
        ///      any fees that this contract may have accumulated, though this motivates the owners
        ///      to regularly sweep tokens from the exchange that have accumulated as fees
        require(address(usdc) == GemJoinAbstract(psm.gemJoin()).gem(), "psm/gem-mismatch");
        dai.approve(address(psm), type(uint256).max);
        usdc.approve(address(psm.gemJoin()), type(uint256).max);

        // what fee we should collect (maximum hardcoded at 100bps, ie. 1%)
        fee = _fee;
    }

    // --- ADMINISTRATION ---

    /// @dev All functions in this section MUST have the onlyOwner modifier

    /// Allow configuration of uint256 variables after contract deployment, respecting maximums.
    /// @param _fee the fee to set for the exchange
    function setFee(uint256 _fee) external onlyOwner {
        require(_fee <= MAX_FEE, "fee/too-high");
        fee = _fee;
    }

    /// Sweeper function for any ERC20 tokens accidentally sent to the contract
    /// @notice this function will send the ERC20 tokens to the owner of the contract
    /// @param token the address of the token to sweep
    /// @param wad amount of ERC20 tokens to send to owner
    function sweep(ERC20 token, uint256 wad) external onlyOwner {
        token.safeTransfer(owner, wad);
    }

    // --- EXCHANGE ---

    /// The exchange allows for buying / selling BZZ from/to stablecoins
    ///
    /// BZZ market: Bonding Curve (BZZ <--> DAI)
    /// Stablecoin markets:
    /// a. Curve.fi 3pool (DAI <--> USDC/USDT)
    /// b. Uniswap V3 (DAI <--> USDC/USDT)
    /// c. DAI PSM (DAI <--> USDC)

    /// Buy BZZ with a stablecoin
    /// @param _buyParams the parameters for the buy transaction
    /// @return totalCost in stablecoin of the transaction
    function buy(BuyParams calldata _buyParams) external returns (uint256 totalCost) {
        // 1. calculate the price to buy wad amount of bzz, then calculate fee
        uint256 collateralCost = bc.buyPrice(_buyParams.bzzAmount); // dai cost
        unchecked {
            uint256 feeCost = collateralCost * fee / 10000; // dai fee
            totalCost = collateralCost + feeCost; // dai total
        }

        // 2. enforce slippage constraints
        /// @dev Allow for 2bps slippage for Uniswap V3 and Curve.fi
        require(
            _buyParams.maxStablecoinAmount * (_buyParams.inputCoin == Stablecoin.DAI ? 1 : TO_DAI)
                > (
                    uint8(_buyParams.lp) <= 1 // logic shortcut to check if lp is 0 or 1, ie. NONE or DAI_PSM
                        ? totalCost
                        : totalCost * 10002 / 10000
                ), // allow 2bps of slippage for Uniswap V3 and Curve.fi
            "exchange/slippage"
        );

        bytes memory permitData;
        bytes memory bridgeData;

        // 3. extract any optional data
        if (_buyParams.options != 0) {
            if (_buyParams.options == 1) {
                // the user has given us a permit signature for the stablecoin token only
                permitData = _buyParams.data;
                _permit(_buyParams.inputCoin, permitData);
            } else if (_buyParams.options == 2) {
                // the user has specified some data for dealing with the bridge
                bridgeData = _buyParams.data;
            } else {
                // if we get here, we will assume that this is a permit signature and bridge data
                (permitData, bridgeData) = abi.decode(_buyParams.data, (bytes, bytes));
                _permit(_buyParams.inputCoin, permitData);
            }
        }

        // 4. if input coin is not dai, then swap to dai (moves to this contract)
        //    else if input coin is dai, then transfer dai to this contract
        if (uint8(Stablecoin.DAI) < uint8(_buyParams.inputCoin)) {
            _daiRouter(
                _buyParams.lp,
                (
                    _buyParams.lp != LiquidityProvider.DAI_PSM // if not using dai psm, we need 2bps slippage
                        ? totalCost * 10002 / 10000 / TO_DAI // 2bps slippage
                        : totalCost / TO_DAI
                ), // otherwise 0bps slippage
                true,
                _buyParams.inputCoin == Stablecoin.USDC ? address(usdc) : address(usdt)
            );
        } else {
            _move(dai, msg.sender, address(this), totalCost);
        }

        // 5. buy bzz from the bonding curve and send to the user
        if (_buyParams.options < 2) {
            // no bridging data, therefore we are to just send to the user here on ethereum mainnet
            // use mintTo to save on a transfer
            bc.mintTo(_buyParams.bzzAmount, collateralCost, msg.sender);
            return totalCost;
        }

        // 6. if we are here, then we are to bridge the bzz to the other chain
        bc.mint(_buyParams.bzzAmount, collateralCost);
        // there are two options here, depending on the calldata length
        // a. if calldata is just an abi encoded address, then we send to an address on gnosis chain.
        //    this is handy if wanting to send direct to a bee node's wallet
        // b. if calldata is longer than just an abi encoded address, we will relay tokens and provide
        //    callback data (allows for flexibility when sending to contracts on gnosis chain)
        if (bridgeData.length == 32) {
            // relay direct to a wallet
            bridge.relayTokens(address(bzz), abi.decode(bridgeData, (address)), _buyParams.bzzAmount);
        } else {
            (address dest, bytes memory cd) = abi.decode(bridgeData, (address, bytes));
            bridge.relayTokensAndCall(address(bzz), dest, _buyParams.bzzAmount, cd);
        }
    }

    /// Sell BZZ for a stablecoin
    /// @param _sellParams the parameters for the sell transaction
    /// @return amount in stablecoin of the transaction
    function sell(SellParams calldata _sellParams) external returns (uint256 amount) {
        // 1. calculate the reward for selling wad bzz and enforce slippage constraint
        uint256 collateralReward = bc.sellReward(_sellParams.bzzAmount); // dai reward
        uint256 feeReward = collateralReward * fee / 10000; // dai fee
        amount = collateralReward - feeReward; // dai amount

        // 2. enforce slippage constraints
        /// @dev Allow for 2bps slippage for Uniswap V3 and Curve.fi
        require(
            _sellParams.minStablecoinAmount * (_sellParams.outputCoin == Stablecoin.DAI ? 1 : TO_DAI)
                < (
                    uint8(_sellParams.lp) <= 1 // logic shortcut to check if lp is 0 or 1, ie. NONE or DAI_PSM
                        ? amount
                        : amount * 9998 / 10000
                ), // allow 2bps of slippage for Uniswap V3 and Curve.fi
            "exchange/slippage"
        );

        // 3. transfer bzz from the user to this contract
        _move(bzz, msg.sender, address(this), _sellParams.bzzAmount);

        // 4. redeem bzz from the bonding curve
        bc.redeem(_sellParams.bzzAmount, collateralReward);

        // 5. if output coin is not dai, then swap to output coin (moves to user)
        //    else if output coin is dai, then transfer dai to user
        if (uint8(Stablecoin.DAI) < uint8(_sellParams.outputCoin)) {
            uint256 afterLp = _daiRouter(
                _sellParams.lp,
                (
                    _sellParams.lp != LiquidityProvider.DAI_PSM // if not using dai psm, we need 2bps slippage
                        ? amount * 9998 / 10000 // 2bps slippage
                        : amount
                ), // otherwise 0bps slippage
                false,
                _sellParams.outputCoin == Stablecoin.USDC ? address(usdc) : address(usdt)
            );
            // if the LP is DAI_PSM or CURVE_FI, then we need to transfer the output coin to the user
            if (uint8(_sellParams.lp) < 3) {
                _move(_sellParams.outputCoin == Stablecoin.USDC ? usdc : usdt, msg.sender, afterLp);
            }
        } else {
            _move(dai, address(this), msg.sender, amount);
        }
    }

    // --- helpers

    /// Route from dai <--> usdc/usdt using various liquidity pools
    /// @param lp the liquidity pool to use
    /// @param wad the amount of the stablecoin to exchange (in the stablecoin decimals)
    /// @param toDai if true, we are converting from stablecoin to dai, otherwise we are converting from dai to stablecoin
    /// @param gem the non-dai stablecoin address
    /// @return output the amount of stablecoin received (in the stablecoin decimals)
    function _daiRouter(LiquidityProvider lp, uint256 wad, bool toDai, address gem) internal returns (uint256 output) {
        /// 1. route the stablecoin to / from dai using the appropriate router
        if (lp == LiquidityProvider.CURVE_FI_3POOL) {
            // if we are going to dai, move the stablecoin to this contract
            if (toDai) {
                // we are going to dai, so we need to transfer the stablecoin to this contract
                _move(ERC20(gem), msg.sender, address(this), wad);
            }
            output = _curveFi3PoolRouter(wad, toDai, gem);
        } else if (lp == LiquidityProvider.UNISWAP_V3) {
            /// @dev we make use of callbacks here to avoid having to transfer the stablecoin to this contract
            output = _uniswapV3Router(wad, toDai, gem);
        } else if (lp == LiquidityProvider.DAI_PSM) {
            require(gem == address(usdc), "exchange/psm-usdc-only");
            // if we are going to dai, move the stablecoin to this contract
            if (toDai) {
                // we are going to dai, so we need to transfer the stablecoin to this contract
                _move(ERC20(gem), msg.sender, address(this), wad);
            }
            output = _daiPsmRouter(wad, toDai);
        } else {
            revert("exchange/invalid-lp");
        }
    }

    /// Curve fi 3pool routing
    /// @param wad the amount of the stablecoin to swap
    /// @param toDai whether we are going to dai or from dai
    /// @param gem the address of the stablecoin we are swapping to / from dai
    /// @return uint256 the amount of the destination coin received
    function _curveFi3PoolRouter(uint256 wad, bool toDai, address gem) internal returns (uint256) {
        // a. determine the non-dai coin index in the curve fi 3pool (1 = USDC, 2 = USDT)
        int128 nonDaiCoinIndex = gem == address(usdc) ? int128(1) : int128(2);
        // b. determine the i and j coin indices based on swap direction
        (int128 i, int128 j) = toDai ? (nonDaiCoinIndex, int128(0)) : (int128(0), nonDaiCoinIndex);

        // c. record the toCoin balance before the swap (and locally cache the addr)
        address toCoinAddr = toDai ? address(dai) : gem;
        uint256 toCoinBalanceBefore = _balance(toCoinAddr, address(this));

        // d. do the swap via the curve fi router
        /// @dev this is safe to set the minimum out to 0 as the bonding curve will revert if the
        ///      slippage is too high
        curveFi3Pool.exchange(i, j, wad, 0);

        // e. return the difference in balance
        return _balance(toCoinAddr, address(this)) - toCoinBalanceBefore;
    }

    /// Uniswap V3 routing for dai/usdc and dai/usdt pools
    /// @param wad the amount of the stablecoin to swap
    /// @param toDai true if we are going to dai, false if we are going from dai
    /// @param gem the address of the stablecoin we are swapping to / from dai
    /// @return uint256 the amount of the destination coin received
    function _uniswapV3Router(uint256 wad, bool toDai, address gem) internal returns (uint256) {
        // a. determine which pool we are using
        IUniswapV3Pool pool = gem == address(usdc) ? usdcV3Pool : usdtV3Pool;

        /// @dev we can use the knowledge that the dai is always the token0 in the
        ///      dai/usdc and dai/usdt pools to simplify the logic here

        // b. do the swap via the uniswap v3 router
        /// @dev if we are going to dai, we should be the recipient of the swap
        (int256 daiAmount, int256 usdcOrUsdtAmount) = pool.swap(
            toDai ? address(this) : msg.sender,
            !toDai,
            int256(wad), // amount of input token (dai, usdc/usdt)
            toDai ? MAX_SQRT_RATIO - 1 : MIN_SQRT_RATIO + 1,
            toDai ? abi.encode(msg.sender) : bytes("")
        );

        // c. return the amount of the destination coin received
        return uint256(-(toDai ? daiAmount : usdcOrUsdtAmount));
    }

    /// DAI PSM router
    /// @notice the DAI PSM router only supports dai <--> usdc so no need for the gem param
    /// @dev this function will handle the routing of dai <--> usdc via the dai psm
    /// @param wad the amount of dai or usdc to exchange
    /// @param toDai true if we are going to dai, false if we are going from dai
    /// @return uint256 the amount of the destination coin received
    function _daiPsmRouter(uint256 wad, bool toDai) internal returns (uint256) {
        if (toDai) {
            // usdc --> dai
            psm.sellGem(address(this), wad);
            return wad;
        } else {
            // dai --> usdc
            psm.buyGem(address(this), wad / TO_DAI);
            return wad / TO_DAI;
        }
    }

    /// Move tokens from an address to another
    /// @param token the token to move
    /// @param from the address to move from
    /// @param to the address to move to
    /// @param amount the amount to move
    function _move(ERC20 token, address from, address to, uint256 amount) internal {
        token.safeTransferFrom(from, to, amount);
    }

    /// Move tokens to an address
    /// @param token the token to move
    /// @param to the address to move to
    /// @param amount the amount to move
    function _move(ERC20 token, address to, uint256 amount) internal {
        token.safeTransfer(to, amount);
    }

    /// Get the balance of a token for an address
    /// @param token the token to get the balance of
    /// @param addr the address to get the balance of
    /// @return uint256 the balance of the token for the address
    function _balance(address token, address addr) internal view returns (uint256) {
        return ERC20(token).balanceOf(addr);
    }

    /// Permit handler for dai and usdc
    /// @param _sc the stablecoin whose permit we are handling
    /// @param _pp the permit parameters
    /// @dev this function is used to handle the permit signatures for dai and usdc
    function _permit(Stablecoin _sc, bytes memory _pp) internal {
        /// @dev we can use the same permit params layout for dai and usdc
        (uint256 nonceOrValue, uint256 expiryOrDeadline, uint8 v, bytes32 r, bytes32 s) =
            abi.decode(_pp, (uint256, uint256, uint8, bytes32, bytes32));

        if (_sc == Stablecoin.DAI) {
            /// @dev dai permit is not eip-2612.
            DaiAbstract(address(dai)).permit(msg.sender, address(this), nonceOrValue, expiryOrDeadline, true, v, r, s);
        } else {
            /// @dev usdc permit is eip-2612.
            usdc.permit(msg.sender, address(this), nonceOrValue, expiryOrDeadline, v, r, s);
        }
    }

    /// --- callbacks

    /// Uniswap V3 swap callback to transfer tokens.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received
    ///                     (positive) by the pool by the end of the swap. If positive, the
    ///                     callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received
    ///                     (positive) by the pool by the end of the swap. If positive, the
    ///                     callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call.
    ///             In this implementation, assumes that the pool key and a minimum receive amount
    ///             are passed via `data` to save on external calls.
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        /// @dev make sure we are actually being called by a canonical pool. This is safe as the pools are immutable.
        require(msg.sender == address(usdcV3Pool) || msg.sender == address(usdtV3Pool), "exchange/u3-invalid-pool");

        /// @dev token transfers below don't need SignedMath as the values are always positive
        if (amount0Delta > 0) {
            // we need to send token0 to the pool (which is dai, and held by this contract)
            dai.safeTransfer(msg.sender, uint256(amount0Delta));
        } else {
            // we need to send token1 to the pool (which is usdc/usdt, and held by the caller, _who_)
            (address who) = abi.decode(data, (address));
            ERC20 token = ERC20(msg.sender == address(usdcV3Pool) ? address(usdc) : address(usdt));
            token.safeTransferFrom(who, msg.sender, uint256(amount1Delta));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

/// @title Abbreviated Curve.fi interface for 3pool to allow use of USDC / USDT
/// @author mfw78 <[email protected]>
/// @dev Refer https://github.com/curvefi/curve-contract/tree/master/contracts/pools/3pool
interface I3PoolCurve {
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
    function coins(uint256 arg0) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

/// @title abbreviated curve interface for BZZ bonding curve
/// @dev refer https://github.com/ethersphere/bzzaar-contracts/blob/main/packages/chain/contracts/Curve.sol
interface IBondingCurve {
    function buyPrice(uint256 _amount) external view returns (uint256);
    function sellReward(uint256 _amount) external view returns (uint256);
    function collateralToken() external view returns (address);
    function bondedToken() external view returns (address);
    function mint(uint256 _amount, uint256 _maxCollateralSpend) external returns (bool success);
    function mintTo(uint256 _amount, uint256 _maxCollateralSpend, address _to) external returns (bool);
    function redeem(uint256 _amount, uint256 _minCollateralReward) external returns (bool success);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IForeignBridge {
    function relayTokens(address token, address _receiver, uint256 _value) external;
    function relayTokensAndCall(address token, address _receiver, uint256 _value, bytes memory _data) external;
}