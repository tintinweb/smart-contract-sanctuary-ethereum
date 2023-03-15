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

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
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
pragma solidity ^0.8.9;

import 'solmate/tokens/ERC20.sol';
import 'solmate/utils/SafeTransferLib.sol';
import 'solmate/utils/FixedPointMathLib.sol';
import 'src/libraries/Ownership.sol';

contract Staking is Ownership {
	using SafeTransferLib for ERC20;
	using FixedPointMathLib for uint256;

	/// @notice staked tokens used as 'shares'
	ERC20 public immutable asset;
	/// @notice reward token
	ERC20 public immutable reward;

	/// @notice record of total distributed rewards per share, used to calculate rewards as users join/leave the pool
	/// @dev gradually increments. users will be updated to the current figure whenever they interact with the contract
	uint256 public totalRewardsPerShare;

	/// @notice period over which staked assets are gradually vested
	uint256 public lockDuration = 7 days;
	uint256 internal constant MAX_LOCK_DURATION = 28 days;

	/// @notice total shares staked in contract
	/// @dev used instead of asset.balanceOf(address(this)) to prevent direct transfers from diluting everyone's rewards
	uint256 public totalShares;

	/// @notice current balance of rewards in contract, used for reward calculations
	uint256 public currentRewardBalance;

	/// @dev multiple mappings cost slightly less gas than a single mapping to a struct with multiple variables

	/// @notice amount of shares (staked assets) per user
	mapping(address => uint256) public shares;
	/// @notice timestamp of the user's last deposit, used for vesting unlock calculations
	mapping(address => uint256) public lastDepositTimestamp;

	/// @dev record of user's last total rewards per share checkpoint
	mapping(address => uint256) private _indexOf;
	mapping(address => uint256) private _unclaimedRewards;
	mapping(address => uint256) private _lockedAssets;

	uint256 internal constant MULTIPLIER = 1e18;

	constructor(
		ERC20 _asset,
		ERC20 _reward,
		address _nominatedOwner,
		address _admin,
		address[] memory _authorized
	) Ownership(_nominatedOwner, _admin, _authorized) {
		asset = _asset;
		reward = _reward;
	}

	/*//////////////////////////
	/      View Functions      /
	//////////////////////////*/

	/// @notice amount of staked assets locked at the current timestamp
	function lockedAssets(address _account) public view returns (uint256) {
		uint256 locked = _lockedAssets[_account];
		if (locked == 0) return 0;

		uint256 duration = lockDuration;
		uint256 timestamp = lastDepositTimestamp[_account];

		if (block.timestamp >= timestamp + duration) return 0;
		return locked - locked.mulDivUp(block.timestamp - timestamp, duration);
	}

	/// @notice amount of staked assets user can withdraw at the current timestamp
	function freeAssets(address _account) public view returns (uint256) {
		return shares[_account] - lockedAssets(_account);
	}

	function unclaimedRewards(address _account) public view returns (uint256) {
		return _unclaimedRewards[_account] + _calculateRewards(_account);
	}

	/*//////////////////////////
	/      User Functions      /
	//////////////////////////*/

	event Deposit(address indexed account, uint256 assets);

	function deposit(uint256 _assets) external updateUser(msg.sender) {
		asset.safeTransferFrom(msg.sender, address(this), _assets);
		shares[msg.sender] += _assets;
		totalShares += _assets;

		uint256 locked = lockedAssets(msg.sender);

		// update user lock
		lastDepositTimestamp[msg.sender] = block.timestamp;
		_lockedAssets[msg.sender] = locked + _assets;

		emit Deposit(msg.sender, _assets);
	}

	error AssetsLocked();
	event Withdraw(address indexed account, uint256 assets);

	function withdraw(uint256 _assets) external updateUser(msg.sender) {
		if (_assets > freeAssets(msg.sender)) revert AssetsLocked();

		shares[msg.sender] -= _assets;
		totalShares -= _assets;
		asset.safeTransfer(msg.sender, _assets);

		emit Withdraw(msg.sender, _assets);
	}

	event ClaimedRewards(address indexed account, uint256 rewards);
	error NoRewardsToClaim();

	function claimRewards() external updateUser(msg.sender) returns (uint256 rewards) {
		rewards = _unclaimedRewards[msg.sender];
		if (rewards == 0) revert NoRewardsToClaim();

		_unclaimedRewards[msg.sender] = 0;
		reward.safeTransfer(msg.sender, rewards);
		currentRewardBalance -= rewards;

		emit ClaimedRewards(msg.sender, rewards);
	}

	/*////////////////////////////////
	/      Authorized Functions      /
	////////////////////////////////*/

	event RewardsAdded(uint256 rewards, uint256 rewardsPerShare, uint256 newTotalRewardsPerShare);

	error NoRewardsToUpdate();
	error NoShares();

	/// @dev authorize treasury contract to automatically call this during harvest
	function updateTotalRewards() external onlyAuthorized {
		if (totalShares == 0) revert NoShares();

		uint256 rewards = reward.balanceOf(address(this)) - currentRewardBalance;
		if (rewards == 0) revert NoRewardsToUpdate();

		uint256 rewardsPerShare = rewards.mulDivDown(MULTIPLIER, totalShares);

		currentRewardBalance += rewards;
		totalRewardsPerShare += rewardsPerShare;

		emit RewardsAdded(rewards, rewardsPerShare, totalRewardsPerShare);
	}

	/*///////////////////////////
	/      Admin Functions      /
	///////////////////////////*/

	event LockDurationSet(uint256 duration);
	error AboveMaximumLockDuration();

	function setLockDuration(uint256 _duration) external onlyAdmins {
		if (_duration > MAX_LOCK_DURATION) revert AboveMaximumLockDuration();
		lockDuration = _duration;

		emit LockDurationSet(_duration);
	}

	error NothingToSkim();

	/*///////////////////////////
	/      Owner Functions      /
	///////////////////////////*/

	/// @notice used to withdraw assets accidentally transferred into contract (users should use deposit function)
	function skim() external onlyOwner {
		uint256 amount = asset.balanceOf(address(this)) - totalShares;
		if (amount == 0) revert NothingToSkim();
		asset.safeTransfer(msg.sender, amount);
	}

	error InvalidToken();
	error NothingToSweep();

	/// @notice used to withdraw tokens accidentally transferred to this contract
	function sweep(ERC20 _token) external onlyOwner {
		if (_token == asset || _token == reward) revert InvalidToken();
		uint256 amount = _token.balanceOf(address(this));
		if (amount == 0) revert NothingToSweep();
		_token.safeTransfer(msg.sender, amount);
	}

	/*///////////////////////////
	/      Internal Logic       /
	///////////////////////////*/

	modifier updateUser(address _account) {
		uint256 rewards = _calculateRewards(_account);
		_indexOf[_account] = totalRewardsPerShare;
		_unclaimedRewards[_account] += rewards;
		_;
	}

	function _calculateRewards(address _account) private view returns (uint256 rewards) {
		uint256 userShares = shares[_account];
		if (userShares == 0) return 0;

		return (totalRewardsPerShare - _indexOf[_account]).mulDivDown(userShares, MULTIPLIER);
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import 'solmate/tokens/ERC20.sol';
import 'solmate/utils/SafeTransferLib.sol';
import './external/uniswap/ISwapRouter02.sol';
import './external/sushiswap/ISushiRouter.sol';
import {IAsset, IVault} from './external/balancer/IVault.sol';
import './libraries/Ownable.sol';
import './libraries/Path.sol';

/**
 * @notice
 * Swap contract used by strategies to:
 * 1. swap strategy rewards to 'asset'
 * 2. zap similar tokens to asset (e.g. USDT to USDC)
 */
contract Swap is Ownable {
	using SafeTransferLib for ERC20;
	using Path for bytes;

	enum Route {
		Unsupported,
		UniswapV2,
		UniswapV3Direct,
		UniswapV3Path,
		SushiSwap,
		BalancerBatch
	}

	/**
		@dev info depends on route:
		UniswapV2: address[] path
		UniswapV3Direct: uint24 fee
		UniswapV3Path: bytes path (address, uint24 fee, address, uint24 fee, address)
	 */
	struct RouteInfo {
		Route route;
		bytes info;
	}

	ISushiRouter internal constant sushiswap = ISushiRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
	/// @dev single address which supports both uniswap v2 and v3 routes
	ISwapRouter02 internal constant uniswap = ISwapRouter02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

	IVault internal constant balancer = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

	/// @dev tokenIn => tokenOut => routeInfo
	mapping(address => mapping(address => RouteInfo)) public routes;

	/*//////////////////
	/      Events      /
	//////////////////*/

	event RouteSet(address indexed tokenIn, address indexed tokenOut, RouteInfo routeInfo);
	event RouteRemoved(address indexed tokenIn, address indexed tokenOut);

	/*//////////////////
	/      Errors      /
	//////////////////*/

	error UnsupportedRoute(address tokenIn, address tokenOut);
	error InvalidRouteInfo();

	constructor() Ownable() {
		address CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
		address CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
		address LDO = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;

		address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

		address STG = 0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6;
		address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
		address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

		_setRoute(CRV, WETH, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(3_000))}));
		_setRoute(CVX, WETH, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(10_000))}));
		_setRoute(LDO, WETH, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(3_000))}));

		_setRoute(CRV, USDC, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(10_000))}));
		_setRoute(
			CVX,
			USDC,
			RouteInfo({
				route: Route.UniswapV3Path,
				info: abi.encodePacked(CVX, uint24(10_000), WETH, uint24(500), USDC)
			})
		);

		_setRoute(USDC, USDT, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(100))}));

		IAsset[] memory assets = new IAsset[](4);
		assets[0] = IAsset(STG);
		assets[1] = IAsset(0xA13a9247ea42D743238089903570127DdA72fE44); // bb-a-USD
		assets[2] = IAsset(0x82698aeCc9E28e9Bb27608Bd52cF57f704BD1B83); // bb-a-USDC
		assets[3] = IAsset(USDC);

		IVault.BatchSwapStep[] memory steps = new IVault.BatchSwapStep[](3);

		// STG -> bb-a-USD
		steps[0] = IVault.BatchSwapStep({
			poolId: 0x4ce0bd7debf13434d3ae127430e9bd4291bfb61f00020000000000000000038b,
			assetInIndex: 0,
			assetOutIndex: 1,
			amount: 0,
			userData: ''
		});

		// bb-a-USD -> bb-a-USDC
		steps[1] = IVault.BatchSwapStep({
			poolId: 0xa13a9247ea42d743238089903570127dda72fe4400000000000000000000035d,
			assetInIndex: 1,
			assetOutIndex: 2,
			amount: 0,
			userData: ''
		});

		// bb-a-USDC -> USDC
		steps[2] = IVault.BatchSwapStep({
			poolId: 0x82698aecc9e28e9bb27608bd52cf57f704bd1b83000000000000000000000336,
			assetInIndex: 2,
			assetOutIndex: 3,
			amount: 0,
			userData: ''
		});

		_setRoute(STG, USDC, RouteInfo({route: Route.BalancerBatch, info: abi.encode(steps, assets)}));
	}

	/*///////////////////////
	/      Public View      /
	///////////////////////*/

	function getRoute(address _tokenIn, address _tokenOut) external view returns (RouteInfo memory routeInfo) {
		return routes[_tokenIn][_tokenOut];
	}

	/*////////////////////////////
	/      Public Functions      /
	////////////////////////////*/

	function swapTokens(
		address _tokenIn,
		address _tokenOut,
		uint256 _amount,
		uint256 _minReceived
	) external returns (uint256 received) {
		RouteInfo memory routeInfo = routes[_tokenIn][_tokenOut];

		ERC20 tokenIn = ERC20(_tokenIn);
		tokenIn.safeTransferFrom(msg.sender, address(this), _amount);

		Route route = routeInfo.route;
		bytes memory info = routeInfo.info;

		if (route == Route.UniswapV2) {
			received = _uniswapV2(_amount, _minReceived, info);
		} else if (route == Route.UniswapV3Direct) {
			received = _uniswapV3Direct(_tokenIn, _tokenOut, _amount, _minReceived, info);
		} else if (route == Route.UniswapV3Path) {
			received = _uniswapV3Path(_amount, _minReceived, info);
		} else if (route == Route.SushiSwap) {
			received = _sushiswap(_amount, _minReceived, info);
		} else if (route == Route.BalancerBatch) {
			received = _balancerBatch(_amount, _minReceived, info);
		} else revert UnsupportedRoute(_tokenIn, _tokenOut);

		// return unswapped amount to sender
		uint256 balance = tokenIn.balanceOf(address(this));
		if (balance > 0) tokenIn.safeTransfer(msg.sender, balance);
	}

	/*///////////////////////////////////////////
	/      Restricted Functions: onlyOwner      /
	///////////////////////////////////////////*/

	function setRoute(
		address _tokenIn,
		address _tokenOut,
		RouteInfo memory _routeInfo
	) external onlyOwner {
		_setRoute(_tokenIn, _tokenOut, _routeInfo);
	}

	function unsetRoute(address _tokenIn, address _tokenOut) external onlyOwner {
		delete routes[_tokenIn][_tokenOut];
		emit RouteRemoved(_tokenIn, _tokenOut);
	}

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/

	function _setRoute(
		address _tokenIn,
		address _tokenOut,
		RouteInfo memory _routeInfo
	) internal {
		Route route = _routeInfo.route;
		bytes memory info = _routeInfo.info;

		if (route == Route.UniswapV2 || route == Route.SushiSwap) {
			address[] memory path = abi.decode(info, (address[]));

			if (path[0] != _tokenIn) revert InvalidRouteInfo();
			if (path[path.length - 1] != _tokenOut) revert InvalidRouteInfo();
		}

		// just check that this doesn't throw an error
		if (route == Route.UniswapV3Direct) abi.decode(info, (uint24));

		if (route == Route.UniswapV3Path) {
			bytes memory path = info;

			// check first tokenIn
			(address tokenIn, , ) = path.decodeFirstPool();
			if (tokenIn != _tokenIn) revert InvalidRouteInfo();

			// check last tokenOut
			while (path.hasMultiplePools()) path = path.skipToken();
			(, address tokenOut, ) = path.decodeFirstPool();
			if (tokenOut != _tokenOut) revert InvalidRouteInfo();
		}

		address router = route == Route.SushiSwap ? address(sushiswap) : route == Route.BalancerBatch
			? address(balancer)
			: address(uniswap);

		ERC20(_tokenIn).safeApprove(router, 0);
		ERC20(_tokenIn).safeApprove(router, type(uint256).max);

		routes[_tokenIn][_tokenOut] = _routeInfo;
		emit RouteSet(_tokenIn, _tokenOut, _routeInfo);
	}

	function _uniswapV2(
		uint256 _amount,
		uint256 _minReceived,
		bytes memory _path
	) internal returns (uint256) {
		address[] memory path = abi.decode(_path, (address[]));

		return uniswap.swapExactTokensForTokens(_amount, _minReceived, path, msg.sender);
	}

	function _sushiswap(
		uint256 _amount,
		uint256 _minReceived,
		bytes memory _path
	) internal returns (uint256) {
		address[] memory path = abi.decode(_path, (address[]));

		uint256[] memory received = sushiswap.swapExactTokensForTokens(
			_amount,
			_minReceived,
			path,
			msg.sender,
			block.timestamp + 30 minutes
		);

		return received[received.length - 1];
	}

	function _uniswapV3Direct(
		address _tokenIn,
		address _tokenOut,
		uint256 _amount,
		uint256 _minReceived,
		bytes memory _info
	) internal returns (uint256) {
		uint24 fee = abi.decode(_info, (uint24));

		return
			uniswap.exactInputSingle(
				ISwapRouter02.ExactInputSingleParams({
					tokenIn: _tokenIn,
					tokenOut: _tokenOut,
					fee: fee,
					recipient: msg.sender,
					amountIn: _amount,
					amountOutMinimum: _minReceived,
					sqrtPriceLimitX96: 0
				})
			);
	}

	function _uniswapV3Path(
		uint256 _amount,
		uint256 _minReceived,
		bytes memory _path
	) internal returns (uint256) {
		return
			uniswap.exactInput(
				ISwapRouter02.ExactInputParams({
					path: _path,
					recipient: msg.sender,
					amountIn: _amount,
					amountOutMinimum: _minReceived
				})
			);
	}

	function _balancerBatch(
		uint256 _amount,
		uint256 _minReceived,
		bytes memory _info
	) internal returns (uint256) {
		(IVault.BatchSwapStep[] memory steps, IAsset[] memory assets) = abi.decode(
			_info,
			(IVault.BatchSwapStep[], IAsset[])
		);

		steps[0].amount = _amount;

		int256[] memory limits = new int256[](assets.length);

		limits[0] = int256(_amount);
		limits[limits.length - 1] = int256(_minReceived);

		int256[] memory received = balancer.batchSwap(
			IVault.SwapKind.GIVEN_IN,
			steps,
			assets,
			IVault.FundManagement({
				sender: address(this),
				fromInternalBalance: false,
				recipient: payable(address(msg.sender)),
				toInternalBalance: false
			}),
			limits,
			block.timestamp + 30 minutes
		);

		return uint256(received[received.length - 1]);
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.9;

import 'solmate/tokens/ERC20.sol';
import 'solmate/utils/SafeTransferLib.sol';
import 'src/Staking.sol';
import 'src/libraries/Ownership.sol';

abstract contract Treasury is Ownership {
	using SafeTransferLib for ERC20;

	/// @notice asset of the underlying vault
	ERC20 public immutable asset;
	/// @notice staking contract where where rewards are sent to
	Staking public immutable staking;

	constructor(
		Staking _staking,
		address _nominatedOwner,
		address _admin,
		address[] memory _authorized
	) Ownership(_nominatedOwner, _admin, _authorized) {
		staking = _staking;
		// the assumption here is that the asset of the underlying vault is the reward for the staking contract
		asset = staking.reward();
	}

	/*///////////////////////////
	/      Owner Functions      /
	///////////////////////////*/

	function withdraw(
		ERC20 _token,
		address _receiver,
		uint256 _amount
	) external onlyOwner {
		_withdraw(_token, _receiver, _amount);
	}

	/*////////////////////////////////
	/      Authorized Functions      /
	////////////////////////////////*/

	function harvest() external onlyAuthorized {
		_harvest();
		staking.updateTotalRewards();
	}

	function invest(uint256 _min) external onlyAuthorized {
		_invest(_min);
	}

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/

	function _withdraw(
		ERC20 _token,
		address _receiver,
		uint256 _amount
	) internal {
		_token.safeTransfer(_receiver, _amount);
	}

	/*////////////////////////////
	/      Internal Virtual      /
	////////////////////////////*/

	/// @dev this must 1. collect yield, 2. convert into reward token and 3. send reward to staking contract
	function _harvest() internal virtual;

	function _invest(uint256 _min) internal virtual;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

/// https://etherscan.io/address/0xBA12222222228d8Ba445958a75a0704d566BF2C8#code

interface IAsset {

}

interface IVault {
	enum SwapKind {
		GIVEN_IN,
		GIVEN_OUT
	}

	/**
	 * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
	 * `assets` array passed to that function, and ETH assets are converted to WETH.
	 *
	 * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
	 * from the previous swap, depending on the swap kind.
	 *
	 * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
	 * used to extend swap behavior.
	 */
	struct BatchSwapStep {
		bytes32 poolId;
		uint256 assetInIndex;
		uint256 assetOutIndex;
		uint256 amount;
		bytes userData;
	}

	/**
	 * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
	 * `recipient` account.
	 *
	 * If the caller is not `sender`, it must be an authorized relayer for them.
	 *
	 * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
	 * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
	 * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
	 * `joinPool`.
	 *
	 * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
	 * transferred. This matches the behavior of `exitPool`.
	 *
	 * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
	 * revert.
	 */
	struct FundManagement {
		address sender;
		bool fromInternalBalance;
		address payable recipient;
		bool toInternalBalance;
	}

	/**
	 * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
	 * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
	 *
	 * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
	 * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
	 * the same index in the `assets` array.
	 *
	 * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
	 * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
	 * `amountOut` depending on the swap kind.
	 *
	 * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
	 * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
	 * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
	 *
	 * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
	 * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
	 * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
	 * or unwrapped from WETH by the Vault.
	 *
	 * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
	 * the minimum or maximum amount of each token the vault is allowed to transfer.
	 *
	 * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
	 * equivalent `swap` call.
	 *
	 * Emits `Swap` events.
	 */
	function batchSwap(
		SwapKind kind,
		BatchSwapStep[] memory swaps,
		IAsset[] memory assets,
		FundManagement memory funds,
		int256[] memory limits,
		uint256 deadline
	) external payable returns (int256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// https://docs.convexfinance.com/convexfinanceintegration/baserewardpool
// https://github.com/convex-eth/platform/blob/main/contracts/contracts/BaseRewardPool.sol

interface IBaseRewardPool {
	function balanceOf(address _account) external view returns (uint256);

	function getReward(address _account, bool _claimExtras) external returns (bool);

	function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IBooster {
	function poolInfo(uint256 _pid)
		external
		view
		returns (
			address lpToken,
			address token,
			address gauge,
			address crvRewards,
			address stash,
			bool shutdown
		);

	function deposit(
		uint256 _pid,
		uint256 _amount,
		bool _stake
	) external returns (bool);

	function withdraw(uint256 _pid, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// https://etherscan.io/address/0xd51a44d3fae010294c616388b506acda1bfaae46

interface ITricryptoPool {
	function add_liquidity(uint256[3] memory _amounts, uint256 min_mint_amount) external;

	function remove_liquidity_one_coin(
		uint256 _token_amount,
		uint256 _i,
		uint256 _min_amount
	) external;

	function coins(uint256 _i) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// https://etherscan.io/address/0xd9e1ce17f2641f24ae83637ab66a2cca9c378b9f
// it's actually a UniswapV2Router02 but renamed for clarity vs actual uniswap

interface ISushiRouter {
	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// https://github.com/Uniswap/swap-router-contracts/blob/main/contracts/interfaces/ISwapRouter02.sol

interface ISwapRouter02 {
	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to
	) external payable returns (uint256 amountOut);

	struct ExactInputSingleParams {
		address tokenIn;
		address tokenOut;
		uint24 fee;
		address recipient;
		uint256 amountIn;
		uint256 amountOutMinimum;
		uint160 sqrtPriceLimitX96;
	}

	/// @notice Swaps `amountIn` of one token for as much as possible of another token
	/// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
	/// and swap the entire amount, enabling contracts to send tokens before calling this function.
	/// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
	/// @return amountOut The amount of the received token
	function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

	struct ExactInputParams {
		bytes path;
		address recipient;
		uint256 amountIn;
		uint256 amountOutMinimum;
	}

	/// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
	/// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
	/// and swap the entire amount, enabling contracts to send tokens before calling this function.
	/// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
	/// @return amountOut The amount of the received token
	function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: Unlicense

//https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol

pragma solidity >=0.8.0 <0.9.0;

library BytesLib {
	function slice(
		bytes memory _bytes,
		uint256 _start,
		uint256 _length
	) internal pure returns (bytes memory) {
		require(_length + 31 >= _length, 'slice_overflow');
		require(_bytes.length >= _start + _length, 'slice_outOfBounds');

		bytes memory tempBytes;

		assembly {
			switch iszero(_length)
			case 0 {
				// Get a location of some free memory and store it in tempBytes as
				// Solidity does for memory variables.
				tempBytes := mload(0x40)

				// The first word of the slice result is potentially a partial
				// word read from the original array. To read it, we calculate
				// the length of that partial word and start copying that many
				// bytes into the array. The first word we copy will start with
				// data we don't care about, but the last `lengthmod` bytes will
				// land at the beginning of the contents of the new array. When
				// we're done copying, we overwrite the full first word with
				// the actual length of the slice.
				let lengthmod := and(_length, 31)

				// The multiplication in the next line is necessary
				// because when slicing multiples of 32 bytes (lengthmod == 0)
				// the following copy loop was copying the origin's length
				// and then ending prematurely not copying everything it should.
				let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
				let end := add(mc, _length)

				for {
					// The multiplication in the next line has the same exact purpose
					// as the one above.
					let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
				} lt(mc, end) {
					mc := add(mc, 0x20)
					cc := add(cc, 0x20)
				} {
					mstore(mc, mload(cc))
				}

				mstore(tempBytes, _length)

				//update free-memory pointer
				//allocating the array padded to 32 bytes like the compiler does now
				mstore(0x40, and(add(mc, 31), not(31)))
			}
			//if we want a zero-length slice let's just return a zero-length array
			default {
				tempBytes := mload(0x40)
				//zero out the 32 bytes slice we are about to return
				//we need to do it because Solidity does not garbage collect
				mstore(tempBytes, 0)

				mstore(0x40, add(tempBytes, 0x20))
			}
		}

		return tempBytes;
	}

	function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
		require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
		address tempAddress;

		assembly {
			tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
		}

		return tempAddress;
	}

	function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
		require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
		uint24 tempUint;

		assembly {
			tempUint := mload(add(add(_bytes, 0x3), _start))
		}

		return tempUint;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

abstract contract Ownable {
	address public owner;
	address public nominatedOwner;

	error Unauthorized();

	event OwnerChanged(address indexed previousOwner, address indexed newOwner);

	constructor() {
		owner = msg.sender;
	}

	// Public Functions

	function acceptOwnership() external {
		if (msg.sender != nominatedOwner) revert Unauthorized();
		emit OwnerChanged(owner, msg.sender);
		owner = msg.sender;
		nominatedOwner = address(0);
	}

	// Restricted Functions: onlyOwner

	/// @dev nominating zero address revokes a pending nomination
	function nominateOwnership(address _newOwner) external onlyOwner {
		nominatedOwner = _newOwner;
	}

	// Modifiers

	modifier onlyOwner() {
		if (msg.sender != owner) revert Unauthorized();
		_;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

abstract contract Ownership {
	address public owner;
	address public nominatedOwner;

	address public admin;

	mapping(address => bool) public authorized;

	event OwnerChanged(address indexed previousOwner, address indexed newOwner);
	event AuthAdded(address indexed newAuth);
	event AuthRemoved(address indexed oldAuth);

	error Unauthorized();
	error AlreadyRole();
	error NotRole();

	/// @param _authorized maximum of 256 addresses in constructor
	constructor(
		address _nominatedOwner,
		address _admin,
		address[] memory _authorized
	) {
		owner = msg.sender;
		nominatedOwner = _nominatedOwner;
		admin = _admin;
		for (uint8 i = 0; i < _authorized.length; ++i) {
			authorized[_authorized[i]] = true;
			emit AuthAdded(_authorized[i]);
		}
	}

	// Public Functions

	function acceptOwnership() external {
		if (msg.sender != nominatedOwner) revert Unauthorized();
		emit OwnerChanged(owner, msg.sender);
		owner = msg.sender;
		nominatedOwner = address(0);
	}

	// Restricted Functions: onlyOwner

	/// @dev nominating zero address revokes a pending nomination
	function nominateOwnership(address _newOwner) external onlyOwner {
		nominatedOwner = _newOwner;
	}

	function setAdmin(address _newAdmin) external onlyOwner {
		if (admin == _newAdmin) revert AlreadyRole();
		admin = _newAdmin;
	}

	// Restricted Functions: onlyAdmins

	function addAuthorized(address _authorized) external onlyAdmins {
		if (authorized[_authorized]) revert AlreadyRole();
		authorized[_authorized] = true;
		emit AuthAdded(_authorized);
	}

	function removeAuthorized(address _authorized) external onlyAdmins {
		if (!authorized[_authorized]) revert NotRole();
		authorized[_authorized] = false;
		emit AuthRemoved(_authorized);
	}

	// Modifiers

	modifier onlyOwner() {
		if (msg.sender != owner) revert Unauthorized();
		_;
	}

	modifier onlyAdmins() {
		if (msg.sender != owner && msg.sender != admin) revert Unauthorized();
		_;
	}

	modifier onlyAuthorized() {
		if (msg.sender != owner && msg.sender != admin && !authorized[msg.sender]) revert Unauthorized();
		_;
	}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

// https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/Path.sol

import './BytesLib.sol';

/// @title Functions for manipulating path data for multihop swaps
library Path {
	using BytesLib for bytes;

	/// @dev The length of the bytes encoded address
	uint256 private constant ADDR_SIZE = 20;
	/// @dev The length of the bytes encoded fee
	uint256 private constant FEE_SIZE = 3;

	/// @dev The offset of a single token address and pool fee
	uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
	/// @dev The offset of an encoded pool key
	uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
	/// @dev The minimum length of an encoding that contains 2 or more pools
	uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

	/// @notice Returns true iff the path contains two or more pools
	/// @param path The encoded swap path
	/// @return True if path contains two or more pools, otherwise false
	function hasMultiplePools(bytes memory path) internal pure returns (bool) {
		return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
	}

	/// @notice Returns the number of pools in the path
	/// @param path The encoded swap path
	/// @return The number of pools in the path
	function numPools(bytes memory path) internal pure returns (uint256) {
		// Ignore the first token address. From then on every fee and token offset indicates a pool.
		return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
	}

	/// @notice Decodes the first pool in path
	/// @param path The bytes encoded swap path
	/// @return tokenA The first token of the given pool
	/// @return tokenB The second token of the given pool
	/// @return fee The fee level of the pool
	function decodeFirstPool(bytes memory path)
		internal
		pure
		returns (
			address tokenA,
			address tokenB,
			uint24 fee
		)
	{
		tokenA = path.toAddress(0);
		fee = path.toUint24(ADDR_SIZE);
		tokenB = path.toAddress(NEXT_OFFSET);
	}

	/// @notice Gets the segment corresponding to the first pool in the path
	/// @param path The bytes encoded swap path
	/// @return The segment containing all data necessary to target the first pool in the path
	function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
		return path.slice(0, POP_OFFSET);
	}

	/// @notice Skips a token + fee element from the buffer and returns the remainder
	/// @param path The swap path
	/// @return The remaining token + fee elements in the path
	function skipToken(bytes memory path) internal pure returns (bytes memory) {
		return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.9;

import 'solmate/utils/SafeTransferLib.sol';
import 'src/Treasury.sol';
import 'src/external/curve/ITricryptoPool.sol';
import 'src/external/convex/IBaseRewardPool.sol';
import 'src/external/convex/IBooster.sol';
import 'src/Swap.sol';

contract TreasuryConvexTricrypto is Treasury {
	using SafeTransferLib for ERC20;

	/// @notice contract used to swap CRV/CVX to treasury asset
	Swap public swap;

	/// @notice index of token in tricrypto pool
	uint8 public immutable index;
	ERC20 public immutable poolToken;

	ITricryptoPool internal constant pool = ITricryptoPool(0xD51a44d3FaE010294C616388b506AcdA1bfAAE46);
	/// @dev crvTricrypto LP token
	ERC20 internal constant lpToken = ERC20(0xc4AD29ba4B3c580e6D59105FFf484999997675Ff);

	IBaseRewardPool private constant rewardPool = IBaseRewardPool(0x9D5C5E364D81DaB193b72db9E9BE9D8ee669B652);
	IBooster private constant booster = IBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

	ERC20 internal constant CRV = ERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
	ERC20 internal constant CVX = ERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

	ERC20[2] public rewards = [CRV, CVX];
	bool public shouldClaimExtras = true;

	error InvalidIndex();
	error WithdrawAndUnwrapFailed();

	/// @dev pid of tricrypto2 in Convex
	uint8 internal constant pid = 38;

	constructor(
		Staking _staking,
		address _nominatedOwner,
		address _admin,
		address[] memory _authorized,
		Swap _swap,
		uint8 _index
	) Treasury(_staking, _nominatedOwner, _admin, _authorized) {
		poolToken = ERC20(pool.coins(_index));

		swap = _swap;
		index = _index;

		_approve();
	}

	/*//////////////////////////
	/      View Functions      /
	//////////////////////////*/

	function totalAssets() external view returns (uint256) {
		return rewardPool.balanceOf(address(this));
	}

	/*///////////////////////////
	/      Owner Functions      /
	///////////////////////////*/

	function unstakeAndWithdraw(
		uint256 _lpAmount,
		uint256 _i,
		uint256 _min,
		address _receiver
	) external onlyOwner {
		if (!rewardPool.withdrawAndUnwrap(_lpAmount, true)) revert WithdrawAndUnwrapFailed();

		pool.remove_liquidity_one_coin(_lpAmount, _i, _min);

		ERC20 token = ERC20(pool.coins(_i));
		uint256 balance = token.balanceOf(address(this));
		_withdraw(token, _receiver, balance);
	}

	function changeSwap(Swap _swap) external onlyOwner {
		_unapproveSwap();
		swap = _swap;
		_approveSwap();
	}

	/*////////////////////////////////
	/      Authorized Functions      /
	////////////////////////////////*/

	function reapprove() external onlyAuthorized {
		_unapprove();
		_approve();
	}

	function setShouldClaimExtras(bool _shouldClaimExtras) external onlyAuthorized {
		shouldClaimExtras = _shouldClaimExtras;
	}

	/*/////////////////////////////
	/      Internal Override      /
	/////////////////////////////*/

	error ClaimRewardsFailed();

	function _harvest() internal override {
		if (!rewardPool.getReward(address(this), shouldClaimExtras)) revert ClaimRewardsFailed();

		uint256 balance = asset.balanceOf(address(this));

		uint8 length = uint8(rewards.length);
		for (uint8 i = 0; i < length; ++i) {
			ERC20 rewardToken = rewards[i];
			uint256 rewardBalance = rewardToken.balanceOf(address(this));

			if (rewardBalance == 0) continue;

			swap.swapTokens(address(rewardToken), address(asset), rewardBalance, 1);
		}

		uint256 received = asset.balanceOf(address(this)) - balance;

		asset.safeTransfer(address(staking), received);
	}

	error NothingToInvest();
	error DepositFailed();

	function _invest(uint256 _min) internal override {
		uint256 assetBalance = asset.balanceOf(address(this));

		if (assetBalance == 0) revert NothingToInvest();

		// convert from USDC to USDT
		if (asset != poolToken) {
			swap.swapTokens(address(asset), address(poolToken), assetBalance, 1);
			assetBalance = poolToken.balanceOf(address(this));
		}

		uint256[] memory balances = new uint256[](3);
		balances[index] = assetBalance;

		pool.add_liquidity([balances[0], balances[1], balances[2]], _min);

		uint256 lpBalance = lpToken.balanceOf(address(this));
		if (!booster.deposit(pid, lpBalance, true)) revert DepositFailed();
	}

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/

	function _approve() internal {
		// approve deposit USDT/WBTC/WETH in pool
		poolToken.safeApprove(address(pool), type(uint256).max);
		// approve deposit lpTokens into booster
		lpToken.safeApprove(address(booster), type(uint256).max);
		// approve withdraw lpTokens
		lpToken.safeApprove(address(pool), type(uint256).max);

		_approveSwap();
	}

	function _unapprove() internal {
		poolToken.safeApprove(address(pool), 0);
		lpToken.safeApprove(address(booster), 0);
		lpToken.safeApprove(address(pool), 0);

		_unapproveSwap();
	}

	function _approveSwap() internal {
		uint8 length = uint8(rewards.length);
		for (uint8 i = 0; i < length; ++i) {
			rewards[i].safeApprove(address(swap), type(uint256).max);
		}

		if (asset != poolToken) asset.safeApprove(address(swap), type(uint256).max);
	}

	function _unapproveSwap() internal {
		uint8 length = uint8(rewards.length);
		for (uint8 i = 0; i < length; ++i) {
			rewards[i].safeApprove(address(swap), 0);
		}

		if (asset != poolToken) asset.safeApprove(address(swap), type(uint256).max);
	}
}