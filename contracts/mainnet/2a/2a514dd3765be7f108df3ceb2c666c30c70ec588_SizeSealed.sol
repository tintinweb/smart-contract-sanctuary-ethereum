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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Gas optimized merkle proof verification library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
library MerkleProofLib {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            if proof.length {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(proof.offset, shl(5, proof.length))

                // Initialize offset to the offset of the proof in calldata.
                let offset := proof.offset

                // Iterate over proof elements to compute root hash.
                // prettier-ignore
                for {} 1 {} {
                    // Slot where the leaf should be put in scratch space. If
                    // leaf > calldataload(offset): slot 32, otherwise: slot 0.
                    let leafSlot := shl(5, gt(leaf, calldataload(offset)))

                    // Store elements to hash contiguously in scratch space.
                    // The xor puts calldataload(offset) in whichever slot leaf
                    // is not occupying, so 0 if leafSlot is 32, and 32 otherwise.
                    mstore(leafSlot, leaf)
                    mstore(xor(leafSlot, 32), calldataload(offset))

                    // Reuse leaf to store the hash to reduce stack operations.
                    leaf := keccak256(0, 64) // Hash both slots of scratch space.

                    offset := add(offset, 32) // Shift 1 word per cycle.

                    // prettier-ignore
                    if iszero(lt(offset, end)) { break }
                }
            }

            isValid := eq(leaf, root) // The proof is valid if the roots match.
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {MerkleProofLib} from "solmate/utils/MerkleProofLib.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {ECCMath} from "./util/ECCMath.sol";
import {ISizeSealed} from "./interfaces/ISizeSealed.sol";
import {CommonTokenMath} from "./util/CommonTokenMath.sol";

/// @title Size Sealed Auction
/// @author Size Market
contract SizeSealed is ISizeSealed {
    ///////////////////////////////
    ///          STATE          ///
    ///////////////////////////////

    uint256 public currentAuctionId;

    mapping(uint256 => Auction) public idToAuction;

    ///////////////////////////////////////////////////
    ///                  MODIFIERS                  ///
    ///////////////////////////////////////////////////

    modifier atState(Auction storage a, States _state) {
        if (block.timestamp < a.timings.startTimestamp) {
            if (_state != States.Created) revert InvalidState();
        } else if (block.timestamp < a.timings.endTimestamp) {
            if (_state != States.AcceptingBids) revert InvalidState();
        } else if (a.data.finalized) {
            if (_state != States.Finalized) revert InvalidState();
        } else if (block.timestamp <= a.timings.endTimestamp + 24 hours) {
            if (_state != States.RevealPeriod) revert InvalidState();
        } else if (block.timestamp > a.timings.endTimestamp + 24 hours) {
            if (_state != States.Voided) revert InvalidState();
        } else {
            revert();
        }
        _;
    }

    ///////////////////////////////////////////////////////////////////////
    ///                          AUCTION LOGIC                          ///
    ///////////////////////////////////////////////////////////////////////

    /// @notice Creates a new sealed auction
    /// @dev Transfers the `baseToken` from `msg.sender` to the contract
    /// @return `auctionId` unique to that auction
    /// @param auctionParams Parameters used during the auction
    /// @param timings The timestamps at which the auction starts/ends
    /// @param encryptedSellerPrivKey Encrypted seller's ephemeral private key
    function createAuction(
        AuctionParameters calldata auctionParams,
        Timings calldata timings,
        bytes calldata encryptedSellerPrivKey
    ) external returns (uint256) {
        if (timings.endTimestamp <= block.timestamp) {
            revert InvalidTimestamp();
        }
        if (timings.startTimestamp >= timings.endTimestamp) {
            revert InvalidTimestamp();
        }
        if (timings.endTimestamp > timings.vestingStartTimestamp) {
            revert InvalidTimestamp();
        }
        if (timings.vestingStartTimestamp > timings.vestingEndTimestamp) {
            revert InvalidTimestamp();
        }
        if (timings.cliffPercent > 1e18) {
            revert InvalidCliffPercent();
        }
        // Revert if the min bid is more than the total reserve of the auction
        if (
            FixedPointMathLib.mulDivDown(
                auctionParams.minimumBidQuote, type(uint128).max, auctionParams.totalBaseAmount
            ) > auctionParams.reserveQuotePerBase
        ) {
            revert InvalidReserve();
        }
        // Passes https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol#L9
        if (auctionParams.quoteToken.code.length == 0 || auctionParams.baseToken.code.length == 0) {
            revert TokenDoesNotExist();
        }

        uint256 auctionId = ++currentAuctionId;

        Auction storage a = idToAuction[auctionId];
        a.timings = timings;

        a.data.seller = msg.sender;

        a.params = auctionParams;

        // Transfer base tokens from the seller
        transferWithTaxCheck(auctionParams.baseToken, msg.sender, auctionParams.totalBaseAmount);

        emit AuctionCreated(auctionId, msg.sender, auctionParams, timings, encryptedSellerPrivKey);

        return auctionId;
    }

    /// @dev Transfers `amount` from msg.sender, and checks that the amount transferred matches the expected
    function transferWithTaxCheck(address token, address from, uint256 amount) internal {
        uint256 balanceBeforeTransfer = ERC20(token).balanceOf(address(this));

        SafeTransferLib.safeTransferFrom(
            ERC20(token), from, address(this), amount
        );

        uint256 balanceAfterTransfer = ERC20(token).balanceOf(address(this));
        if (balanceAfterTransfer - balanceBeforeTransfer != amount) {
            revert UnexpectedBalanceChange();
        }
    }

    /// @notice Bid on a runnning auction
    /// @dev Transfers `quoteAmount` of `quoteToken` from bidder to contract
    /// @return Index of the bid
    /// @param auctionId Id of the auction to bid on
    /// @param quoteAmount Amount of `quoteTokens` bidding on a committed amount of `baseTokens`
    /// @param commitment Hash commitment of the `baseAmount`
    /// @param pubKey Public key used to encrypt `baseAmount`
    /// @param encryptedMessage `baseAmount` encrypted to the seller's public key
    /// @param encryptedPrivateKey Encrypted private key for on-chain storage
    /// @param proof Merkle proof that checks seller against `merkleRoot` if there is a whitelist
    function bid(
        uint256 auctionId,
        uint128 quoteAmount,
        bytes32 commitment,
        ECCMath.Point calldata pubKey,
        bytes32 encryptedMessage,
        bytes calldata encryptedPrivateKey,
        bytes32[] calldata proof
    ) external atState(idToAuction[auctionId], States.AcceptingBids) returns (uint256) {
        Auction storage a = idToAuction[auctionId];
        if (a.params.merkleRoot != bytes32(0)) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            if (!MerkleProofLib.verify(proof, a.params.merkleRoot, leaf)) {
                revert InvalidProof();
            }
        }

        // Seller cannot bid on their own auction
        if (msg.sender == a.data.seller) {
            revert UnauthorizedCaller();
        }

        if (quoteAmount == 0 || quoteAmount < a.params.minimumBidQuote) {
            revert InvalidBidAmount();
        }

        EncryptedBid memory ebid;
        ebid.sender = msg.sender;
        ebid.quoteAmount = quoteAmount;
        ebid.commitment = commitment;
        ebid.pubKey = pubKey;
        ebid.encryptedMessage = encryptedMessage;

        uint256 bidIndex = a.bids.length;
        // Max of 1000 bids on an auction to prevent DOS
        if (bidIndex >= 1000) {
            revert InvalidState();
        }

        a.bids.push(ebid);

        // Transfer the quote tokens from the bidder
        transferWithTaxCheck(a.params.quoteToken, msg.sender, quoteAmount);

        emit Bid(
            msg.sender, auctionId, bidIndex, quoteAmount, commitment, pubKey, encryptedMessage, encryptedPrivateKey
            );

        return bidIndex;
    }

    /// @notice Reveals the private key of the seller
    /// @dev All valid bids are decrypted after this
    ///      finalizeData should be empty if seller does not wish to finalize in this tx
    /// @param privateKey Private key corresponding to the auctions public key
    /// @param finalizeData Calldata that will be sent to finalize()
    function reveal(uint256 auctionId, uint256 privateKey, bytes calldata finalizeData)
        external
        atState(idToAuction[auctionId], States.RevealPeriod)
    {
        Auction storage a = idToAuction[auctionId];
        if (a.data.seller != msg.sender) {
            revert UnauthorizedCaller();
        }

        ECCMath.Point memory pubKey = ECCMath.publicKey(privateKey);
        if (pubKey.x != a.params.pubKey.x || pubKey.y != a.params.pubKey.y || (pubKey.x == 1 && pubKey.y == 1)) {
            revert InvalidPrivateKey();
        }

        a.data.privKey = privateKey;

        emit RevealedKey(auctionId, privateKey);

        if (finalizeData.length != 0) {
            (uint256[] memory bidIndices) = abi.decode(finalizeData, (uint256[]));
            finalize(auctionId, bidIndices);
        }
    }

    // Used to get around stack too deep errors -- even with viaIr
    struct FinalizeData {
        uint256 reserveQuotePerBase;
        uint256 totalBaseAmount;
        uint256 filledBase;

        uint256 previousQuote;
        uint256 previousBase;
        uint256 previousIndex;
    }

    /// @notice Finalises an auction by revealing all bids
    /// @dev Calculates the minimum `quotePerBase` and marks successful bids
    /// @param auctionId `auctionId` of the auction to bid on
    /// @param bidIndices Bids sorted by price descending
    function finalize(uint256 auctionId, uint256[] memory bidIndices)
        public
        atState(idToAuction[auctionId], States.RevealPeriod)
    {
        Auction storage a = idToAuction[auctionId];
        uint256 sellerPriv = a.data.privKey;
        if (sellerPriv == 0) {
            revert InvalidPrivateKey();
        }

        if (bidIndices.length != a.bids.length) {
            revert InvalidCalldata();
        }

        FinalizeData memory data;
        data.reserveQuotePerBase = a.params.reserveQuotePerBase;
        data.totalBaseAmount = a.params.totalBaseAmount;
        data.previousQuote = type(uint128).max;
        data.previousBase = 1;

        // Bitmap of all the bid indices that have been processed
        uint256[] memory seenBidMap = new uint256[]((bidIndices.length/256)+1);

        // Fill orders from highest price to lowest price
        for (uint256 i; i < bidIndices.length; i++) {
            uint256 bidIndex = bidIndices[i];
            EncryptedBid storage b = a.bids[bidIndex];

            // Verify this bid index hasn't been seen before
            uint256 bitmapIndex = bidIndex / 256;
            uint256 bitMap = seenBidMap[bitmapIndex];
            uint256 indexBit = 1 << (bidIndex % 256);
            if (bitMap & indexBit == indexBit) revert InvalidState();
            seenBidMap[bitmapIndex] = bitMap | indexBit;

            // G^k1^k2 == G^k2^k1
            ECCMath.Point memory sharedPoint = ECCMath.ecMul(b.pubKey, sellerPriv);
            // If the bidder public key isn't on the bn128 curve
            if (sharedPoint.x == 1 && sharedPoint.y == 1) continue;

            bytes32 decryptedMessage = ECCMath.decryptMessage(sharedPoint, b.encryptedMessage);
            // If the bidder didn't faithfully submit commitment or pubkey
            // Or the bid was canceled
            if (computeCommitment(decryptedMessage) != b.commitment) continue;

            // First 128 bits are the base amount, last are random salt
            uint256 baseAmount = uint256(decryptedMessage >> 128);
            uint256 quoteAmount = b.quoteAmount;

            if (baseAmount == 0) continue;

            // Require that bids are passed in descending price
            uint256 quotePerBase = FixedPointMathLib.mulDivDown(quoteAmount, type(uint128).max, baseAmount);
            uint256 currentMult = quoteAmount * data.previousBase;
            uint256 previousMult = data.previousQuote * baseAmount;
            
            if (currentMult >= previousMult) {
                // If last bid was the same price, make sure we filled the earliest bid first
                if (currentMult == previousMult) {
                    if (data.previousIndex > bidIndex) revert InvalidSorting();
                } else {
                    revert InvalidSorting();
                }
            }

            // Only fill if above reserve price
            if (quotePerBase < data.reserveQuotePerBase) continue;

            // Auction has been fully filled
            if (data.filledBase == data.totalBaseAmount) continue;

            data.previousBase = baseAmount;
            data.previousQuote = quoteAmount;
            data.previousIndex = bidIndex;

            // Fill the remaining unfilled base amount
            if (data.filledBase + baseAmount > data.totalBaseAmount) {
                baseAmount = data.totalBaseAmount - data.filledBase;
            }

            b.filledBaseAmount = uint128(baseAmount);
            data.filledBase += baseAmount;
        }

        a.data.clearingQuote = uint128(data.previousQuote);
        a.data.clearingBase = uint128(data.previousBase);
        a.data.finalized = true;

        // seenBidMap[0:len-1] should be full
        for (uint256 i; i < seenBidMap.length - 1; i++) {
            if (seenBidMap[i] != type(uint256).max) {
                revert InvalidState();
            }
        }

        // seenBidMap[-1] should only have the last N bits set
        if (seenBidMap[seenBidMap.length - 1] != (1 << (bidIndices.length % 256)) - 1) {
            revert InvalidState();
        }

        // Sanity check that we didn't overfill the auction
        if (data.filledBase > data.totalBaseAmount) {
            revert InvalidState();
        }

        // Transfer the unsold baseToken
        if (data.totalBaseAmount > data.filledBase) {
            uint256 unsoldBase = data.totalBaseAmount - data.filledBase;
            a.params.totalBaseAmount = uint128(data.filledBase);
            safeTransferOut(a.params.baseToken, a.data.seller, unsoldBase);
        }

        // Calculate quote amount based on clearing price
        uint256 filledQuote = FixedPointMathLib.mulDivDown(data.previousQuote, data.filledBase, data.previousBase);

        safeTransferOut(a.params.quoteToken, a.data.seller, filledQuote);

        emit AuctionFinalized(auctionId, bidIndices, data.filledBase, filledQuote);
    }

    /// @notice Called after finalize for unsuccessful bidders to return funds
    /// @dev Returns all `quoteToken` to the original bidder
    /// @param auctionId `auctionId` of the auction to bid on
    /// @param bidIndex Index of the failed bid to be refunded
    function refund(uint256 auctionId, uint256 bidIndex) external atState(idToAuction[auctionId], States.Finalized) {
        Auction storage a = idToAuction[auctionId];
        EncryptedBid storage b = a.bids[bidIndex];
        if (msg.sender != b.sender) {
            revert UnauthorizedCaller();
        }

        if (b.filledBaseAmount != 0) {
            revert InvalidState();
        }

        b.sender = address(0);

        emit BidRefund(auctionId, bidIndex);

        SafeTransferLib.safeTransfer(ERC20(a.params.quoteToken), msg.sender, b.quoteAmount);
    }

    /// @notice Called after finalize for successful bidders
    /// @dev Returns won `baseToken` & any unfilled `quoteToken` to the bidder
    /// @param auctionId `auctionId` of the auction bid on
    /// @param bidIndex Index of the successful bid
    function withdraw(uint256 auctionId, uint256 bidIndex) external atState(idToAuction[auctionId], States.Finalized) {
        Auction storage a = idToAuction[auctionId];
        EncryptedBid storage b = a.bids[bidIndex];
        if (msg.sender != b.sender) {
            revert UnauthorizedCaller();
        }

        uint128 baseAmount = b.filledBaseAmount;
        if (baseAmount == 0) {
            revert InvalidState();
        }

        uint128 baseTokensAvailable = tokensAvailableForWithdrawal(auctionId, baseAmount);
        baseTokensAvailable = baseTokensAvailable - b.baseWithdrawn;

        b.baseWithdrawn += baseTokensAvailable;

        // Refund unfilled quoteAmount on first withdraw
        if (b.quoteAmount != 0) {
            uint256 quoteBought = FixedPointMathLib.mulDivUp(baseAmount, a.data.clearingQuote, a.data.clearingBase);
            // refund = min(quoteAmount, quoteBought)
            uint256 refundedQuote = b.quoteAmount;
            if (refundedQuote >= quoteBought) refundedQuote -= quoteBought;
            else refundedQuote = 0;
            b.quoteAmount = 0;
            
            safeTransferOut(a.params.quoteToken, msg.sender, refundedQuote);
        }

        safeTransferOut(a.params.baseToken, msg.sender, baseTokensAvailable);

        emit Withdrawal(auctionId, bidIndex, baseTokensAvailable, baseAmount - b.baseWithdrawn);
    }

    /// @dev Transfer amount of token, but cap the amount at the current balance to prevent reverts
    function safeTransferOut(address token, address to, uint256 amount) internal {
        uint256 balance = ERC20(token).balanceOf(address(this));
        if (balance < amount) amount = balance;
        if (amount == 0) return;
        
        SafeTransferLib.safeTransfer(ERC20(token), to, amount);
    }

    /// @dev Transfers `baseToken` back to seller and will enable withdraws for bidders
    /// @param auctionId `auctionId` of the auction to be canceled
    function cancelAuction(uint256 auctionId) external {
        Auction storage a = idToAuction[auctionId];
        if (msg.sender != a.data.seller) {
            revert UnauthorizedCaller();
        }
        // Only allow cancellations before finalization
        // Equivalent to atState(idToAuction[auctionId], ~STATE_FINALIZED)
        if (a.data.finalized) {
            revert InvalidState();
        }

        // Allowing bidders to cancel bids (withdraw quote)
        // Auction considered forever States.AcceptingBids but nobody can finalize
        a.data.seller = address(0);
        a.timings.endTimestamp = type(uint32).max;

        emit AuctionCanceled(auctionId);

        SafeTransferLib.safeTransfer(ERC20(a.params.baseToken), msg.sender, a.params.totalBaseAmount);
    }

    /// @dev Transfers `quoteToken` back to bidder and prevents bid from being finalised
    /// @param auctionId `auctionId` of the auction to be canceled
    /// @param bidIndex Index of the bid to be canceled
    function cancelBid(uint256 auctionId, uint256 bidIndex) external {
        Auction storage a = idToAuction[auctionId];
        EncryptedBid storage b = a.bids[bidIndex];
        if (msg.sender != b.sender) {
            revert UnauthorizedCaller();
        }

        // Only allow bid cancellations while not finalized or in the reveal period
        if (block.timestamp >= a.timings.endTimestamp) {
            if (a.data.finalized || block.timestamp <= a.timings.endTimestamp + 24 hours) {
                revert InvalidState();
            }
        }
        uint256 refundAmount = b.quoteAmount;

        // Delete the canceled bid, and replace it with the most recent bid
        a.bids[bidIndex] = a.bids[a.bids.length - 1];
        a.bids.pop();

        emit BidCanceled(auctionId, bidIndex);

        SafeTransferLib.safeTransfer(ERC20(a.params.quoteToken), msg.sender, refundAmount);
    }

    ////////////////////////////////////////////////////////////////////////////
    ///                            UTIL FUNCTIONS                            ///
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Calculates available unlocked tokens for an auction
    /// @dev Uses vesting parameters to account for cliff & linearity
    /// @return tokensAvailable Amount of unlocked `baseToken` at the current time
    /// @param auctionId `auctionId` of the auction bid on
    /// @param baseAmount Amount of total vested `baseToken`
    function tokensAvailableForWithdrawal(uint256 auctionId, uint128 baseAmount)
        public
        view
        returns (uint128 tokensAvailable)
    {
        Auction storage a = idToAuction[auctionId];
        return CommonTokenMath.tokensAvailableAtTime(
            a.timings.vestingStartTimestamp,
            a.timings.vestingEndTimestamp,
            uint32(block.timestamp),
            a.timings.cliffPercent,
            baseAmount
        );
    }

    function computeCommitment(bytes32 message) public pure returns (bytes32) {
        return keccak256(abi.encode(message));
    }

    function computeMessage(uint128 baseAmount, bytes16 salt) external pure returns (bytes32) {
        return bytes32(abi.encodePacked(baseAmount, salt));
    }

    function getTimings(uint256 auctionId) external view returns (Timings memory) {
        return idToAuction[auctionId].timings;
    }

    function getAuctionData(uint256 auctionId) external view returns (AuctionData memory) {
        return idToAuction[auctionId].data;
    }

    function getBid(uint256 auctionId, uint256 bidIndex) external view returns (EncryptedBid memory) {
        return idToAuction[auctionId].bids[bidIndex];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {ECCMath} from "../util/ECCMath.sol";

interface ISizeSealed {
    ////////////////////////////////////
    ///            ERRORS            ///
    ////////////////////////////////////

    error InvalidTimestamp();
    error InvalidCliffPercent();
    error InvalidBidAmount();
    error InvalidState();
    error InvalidReserve();
    error InvalidCalldata();
    error UnauthorizedCaller();
    error CommitmentMismatch();
    error InvalidProof();
    error InvalidPrivateKey();
    error UnexpectedBalanceChange();
    error InvalidSorting();
    error TokenDoesNotExist();

    /////////////////////////////////////////
    ///              ENUMS                ///
    /////////////////////////////////////////

    enum States {
        Created,
        AcceptingBids,
        RevealPeriod,
        Voided,
        Finalized
    }

    /////////////////////////////////////////
    ///              STRUCTS              ///
    /////////////////////////////////////////

    struct EncryptedBid {
        address sender;
        uint128 quoteAmount;
        uint128 filledBaseAmount;
        uint128 baseWithdrawn;
        bytes32 commitment;
        ECCMath.Point pubKey;
        bytes32 encryptedMessage;
    }

    /// @param startTimestamp When the auction opens for bidding
    /// @param endTimestamp When the auction closes for bidding
    /// @param vestingStartTimestamp When linear vesting starts
    /// @param vestingEndTimestamp When linear vesting is complete
    /// @param cliffPercent Normalized percentage of base tokens to unlock at vesting start
    struct Timings {
        uint32 startTimestamp;
        uint32 endTimestamp;
        uint32 vestingStartTimestamp;
        uint32 vestingEndTimestamp;
        uint128 cliffPercent;
    }

    struct AuctionData {
        address seller;
        bool finalized;
        uint128 clearingBase;
        uint128 clearingQuote;
        uint256 privKey;
    }

    /// @param baseToken The ERC20 to be sold by the seller
    /// @param quoteToken The ERC20 to be bid by the bidders
    /// @param reserveQuotePerBase Minimum price that bids will be filled at
    /// @param totalBaseAmount Max amount of `baseToken` to be auctioned
    /// @param minimumBidQuote Minimum quote amount a bid can buy
    /// @param pubKey On-chain storage of seller's ephemeral public key
    struct AuctionParameters {
        address baseToken;
        address quoteToken;
        uint256 reserveQuotePerBase;
        uint128 totalBaseAmount;
        uint128 minimumBidQuote;
        bytes32 merkleRoot;
        ECCMath.Point pubKey;
    }

    struct Auction {
        Timings timings;
        AuctionData data;
        AuctionParameters params;
        EncryptedBid[] bids;
    }

    ////////////////////////////////////
    ///            EVENTS            ///
    ////////////////////////////////////

    event AuctionCreated(
        uint256 auctionId, address seller, AuctionParameters params, Timings timings, bytes encryptedPrivKey
    );

    event AuctionCanceled(uint256 auctionId);

    event Bid(
        address sender,
        uint256 auctionId,
        uint256 bidIndex,
        uint128 quoteAmount,
        bytes32 commitment,
        ECCMath.Point pubKey,
        bytes32 encryptedMessage,
        bytes encryptedPrivateKey
    );

    event BidCanceled(uint256 auctionId, uint256 bidIndex);

    event RevealedKey(uint256 auctionId, uint256 privateKey);

    event AuctionFinalized(uint256 auctionId, uint256[] bidIndices, uint256 filledBase, uint256 filledQuote);

    event BidRefund(uint256 auctionId, uint256 bidIndex);

    event Withdrawal(uint256 auctionId, uint256 bidIndex, uint256 withdrawAmount, uint256 remainingAmount);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

library CommonTokenMath {
    /*//////////////////////////////////////////////////////////////
                                VESTING
    //////////////////////////////////////////////////////////////*/

    //                endTimestamp      vestingStart            vestingEnd
    //        ┌─────────────┬─────────────────┬──────────────────────────────┐
    //        │                                                     │        │
    //        │             │                 │                              │
    //        │                                                     │        │
    //        │             │                 │                     ▽        │
    //        │                                                   ┌── ◁─ ─ ─ ┤totalBaseAmount
    //        │             │                 │                 ┌─┘          │
    //        │                                               ┌─┘            │
    //        │             │                 │             ┌─┘              │
    //        │                                           ┌─┘                │
    //                      │                 │         ┌─┘                  │
    //    Unlocked                                    ┌─┘                    │
    //     Tokens           │                 │     ┌─┘                      │
    //                                            ┌─┘                        │
    //        │             │                 ▽ ┌─┘                          │
    //        │                               ┌─┘◁─ ─ ─ ─ ─ ┐                │
    //        │             │                 │             │                │
    //        │                               │             │                │
    //        │             │                 │        cliffPercent          │
    //        │                               │             │                │
    //        │             │                 │             │                │
    //        │             ▽                 │             │                │
    //        │             ──────────────────┘  ◁─ ─ ─ ─ ─ ┘                │
    //        │                                                              │
    //        └────────────────────────────  Time  ──────────────────────────┘
    //

    /// @dev Helper function to determine tokens at a specific `block.timestamp`
    /// @return tokensAvailable Amount of unlocked `baseToken` at the current `block.timestamp`
    /// @param vestingStart Start of linear vesting
    /// @param vestingEnd Completion of linear vesting
    /// @param currentTime Timestamp to evaluate at
    /// @param cliffPercent Normalized percent to unlock at vesting start
    /// @param baseAmount Total amount of vested `baseToken`
    function tokensAvailableAtTime(
        uint32 vestingStart,
        uint32 vestingEnd,
        uint32 currentTime,
        uint128 cliffPercent,
        uint128 baseAmount
    ) internal pure returns (uint128) {
        if (currentTime > vestingEnd) {
            return baseAmount; // If vesting is over, bidder is owed all tokens
        } else if (currentTime <= vestingStart) {
            return 0; // If cliff hasn't been triggered yet, bidder receives no tokens
        } else {
            // Vesting is active and cliff has triggered
            uint256 cliffAmount = FixedPointMathLib.mulDivDown(baseAmount, cliffPercent, 1e18);

            return uint128(
                cliffAmount
                    + FixedPointMathLib.mulDivDown(
                        baseAmount - cliffAmount, currentTime - vestingStart, vestingEnd - vestingStart
                    )
            );
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

library ECCMath {
    error InvalidPoint();

    // https://eips.ethereum.org/EIPS/eip-197#definition-of-the-groups
    uint256 internal constant GX = 1;
    uint256 internal constant GY = 2;

    struct Point {
        uint256 x;
        uint256 y;
    }

    /// @notice returns the corresponding public key of the private key
    /// @dev calculates G^k, aka G^privateKey = publicKey
    function publicKey(uint256 privateKey) internal view returns (Point memory) {
        return ecMul(Point(GX, GY), privateKey);
    }

    /// @notice calculates point^scalar
    /// @dev returns (1,1) if the ecMul failed or invalid parameters
    /// @return corresponding point
    function ecMul(Point memory point, uint256 scalar) internal view returns (Point memory) {
        bytes memory data = abi.encode(point, scalar);
        if (scalar == 0 || (point.x == 0 && point.y == 0)) return Point(1, 1);
        (bool res, bytes memory ret) = address(0x07).staticcall{gas: 6000}(data);
        if (!res) return Point(1, 1);
        return abi.decode(ret, (Point));
    }

    /// @dev after encryption, both the seller and buyer private keys can decrypt
    /// @param encryptToPub public key to which the message gets encrypted
    /// @param encryptWithPriv private key to use for encryption
    /// @param message arbitrary 32 bytes
    function encryptMessage(Point memory encryptToPub, uint256 encryptWithPriv, bytes32 message)
        internal
        view
        returns (Point memory buyerPub, bytes32 encryptedMessage)
    {
        Point memory sharedPoint = ecMul(encryptToPub, encryptWithPriv);
        bytes32 sharedKey = hashPoint(sharedPoint);
        encryptedMessage = message ^ sharedKey;
        buyerPub = publicKey(encryptWithPriv);
    }

    /// @notice decrypts a message that was encrypted using `encryptMessage()`
    /// @param sharedPoint G^k1^k2 where k1 and k2 are the
    ///      private keys of the two parties that can decrypt
    function decryptMessage(Point memory sharedPoint, bytes32 encryptedMessage)
        internal
        pure
        returns (bytes32 decryptedMessage)
    {
        return encryptedMessage ^ hashPoint(sharedPoint);
    }

    /// @dev we hash the point because unsure if x,y is normal distribution (source needed)
    function hashPoint(Point memory point) internal pure returns (bytes32) {
        return keccak256(abi.encode(point));
    }
}