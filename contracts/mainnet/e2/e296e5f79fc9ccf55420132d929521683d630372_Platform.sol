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

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
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

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;
/*
▄▄▄█████▓ ██░ ██ ▓█████     ██░ ██ ▓█████  ██▀███  ▓█████▄ 
▓  ██▒ ▓▒▓██░ ██▒▓█   ▀    ▓██░ ██▒▓█   ▀ ▓██ ▒ ██▒▒██▀ ██▌
▒ ▓██░ ▒░▒██▀▀██░▒███      ▒██▀▀██░▒███   ▓██ ░▄█ ▒░██   █▌
░ ▓██▓ ░ ░▓█ ░██ ▒▓█  ▄    ░▓█ ░██ ▒▓█  ▄ ▒██▀▀█▄  ░▓█▄   ▌
  ▒██▒ ░ ░▓█▒░██▓░▒████▒   ░▓█▒░██▓░▒████▒░██▓ ▒██▒░▒████▓ 
  ▒ ░░    ▒ ░░▒░▒░░ ▒░ ░    ▒ ░░▒░▒░░ ▒░ ░░ ▒▓ ░▒▓░ ▒▒▓  ▒ 
    ░     ▒ ░▒░ ░ ░ ░  ░    ▒ ░▒░ ░ ░ ░  ░  ░▒ ░ ▒░ ░ ▒  ▒ 
  ░       ░  ░░ ░   ░       ░  ░░ ░   ░     ░░   ░  ░ ░  ░ 
          ░  ░  ░   ░  ░    ░  ░  ░   ░  ░   ░        ░    
                                                    ░      
              .,;>>%%%%%>>;,.
           .>%%%%%%%%%%%%%%%%%%%%>,.
         .>%%%%%%%%%%%%%%%%%%>>,%%%%%%;,.
       .>>>>%%%%%%%%%%%%%>>,%%%%%%%%%%%%,>>%%,.
     .>>%>>>>%%%%%%%%%>>,%%%%%%%%%%%%%%%%%,>>%%%%%,.
   .>>%%%%%>>%%%%>>,%%>>%%%%%%%%%%%%%%%%%%%%,>>%%%%%%%,
  .>>%%%%%%%%%%>>,%%%%%%>>%%%%%%%%%%%%%%%%%%,>>%%%%%%%%%%.
  .>>%%%%%%%%%%>>,>>>>%%%%%%%%%%'..`%%%%%%%%,;>>%%%%%%%%%>%%.
.>>%%%>>>%%%%%>,%%%%%%%%%%%%%%.%%%,`%%%%%%,;>>%%%%%%%%>>>%%%%.
>>%%>%>>>%>%%%>,%%%%%>>%%%%%%%%%%%%%`%%%%%%,>%%%%%%%>>>>%%%%%%%.
>>%>>>%%>>>%%%%>,%>>>%%%%%%%%%%%%%%%%`%%%%%%%%%%%%%%%%%%%%%%%%%%.
>>%%%%%%%%%%%%%%,>%%%%%%%%%%%%%%%%%%%'%%%,>>%%%%%%%%%%%%%%%%%%%%%.
>>%%%%%%%%%%%%%%%,>%%%>>>%%%%%%%%%%%%%%%,>>%%%%%%%%>>>>%%%%%%%%%%%.
>>%%%%%%%%;%;%;%%;,%>>>>%%%%%%%%%%%%%%%,>>>%%%%%%>>;";>>%%%%%%%%%%%%.
`>%%%%%%%%%;%;;;%;%,>%%%%%%%%%>>%%%%%%%%,>>>%%%%%%%%%%%%%%%%%%%%%%%%%%.
 >>%%%%%%%%%,;;;;;%%>,%%%%%%%%>>>>%%%%%%%%,>>%%%%%%%%%%%%%%%%%%%%%%%%%%%.
 `>>%%%%%%%%%,%;;;;%%%>,%%%%%%%%>>>>%%%%%%%%,>%%%%%%'%%%%%%%%%%%%%%%%%%%>>.
  `>>%%%%%%%%%%>,;;%%%%%>>,%%%%%%%%>>%%%%%%';;;>%%%%%,`%%%%%%%%%%%%%%%>>%%>.
   >>>%%%%%%%%%%>> %%%%%%%%>>,%%%%>>>%%%%%';;;;;;>>,%%%,`%     `;>%%%%%%>>%%
   `>>%%%%%%%%%%>> %%%%%%%%%>>>>>>>>;;;;'.;;;;;>>%%'  `%%'          ;>%%%%%>
    >>%%%%%%%%%>>; %%%%%%%%>>;;;;;;''    ;;;;;>>%%%                   ;>%%%%
    `>>%%%%%%%>>>, %%%%%%%%%>>;;'        ;;;;>>%%%'                    ;>%%%
     >>%%%%%%>>>':.%%%%%%%%%%>>;        .;;;>>%%%%                    ;>%%%'
     `>>%%%%%>>> ::`%%%%%%%%%%>>;.      ;;;>>%%%%'                   ;>%%%'
      `>>%%%%>>> `:::`%%%%%%%%%%>;.     ;;>>%%%%%                   ;>%%'
       `>>%%%%>>, `::::`%%%%%%%%%%>,   .;>>%%%%%'                   ;>%'
        `>>%%%%>>, `:::::`%%%%%%%%%>>. ;;>%%%%%%                    ;>%,
         `>>%%%%>>, :::::::`>>>%%%%>>> ;;>%%%%%'                     ;>%,
          `>>%%%%>>,::::::,>>>>>>>>>>' ;;>%%%%%                       ;%%,
            >>%%%%>>,:::,%%>>>>>>>>'   ;>%%%%%.                        ;%%
             >>%%%%>>``%%%%%>>>>>'     `>%%%%%%.
             >>%%%%>> `@@a%%%%%%'     .%%%%%%%%%.
             `[email protected]@a%@'    `%[email protected]@'       `[email protected]@a%[email protected]@a
 */

import {Factory} from "src/interfaces/Factory.sol";
import {GaugeController} from "src/interfaces/GaugeController.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC20, SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

/// version 1.0.2
/// @title  Platform
/// @author Stake DAO
contract Platform is ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    ////////////////////////////////////////////////////////////////
    /// --- EMERGENCY SHUTDOWN
    ///////////////////////////////////////////////////////////////

    /// @notice Emergency shutdown flag
    bool public isKilled;

    ////////////////////////////////////////////////////////////////
    /// --- STRUCTS
    ///////////////////////////////////////////////////////////////

    /// @notice Bribe struct requirements.
    struct Bribe {
        // Address of the target gauge.
        address gauge;
        // Manager.
        address manager;
        // Address of the ERC20 used for rewards.
        address rewardToken;
        // Number of periods.
        uint8 numberOfPeriods;
        // Timestamp where the bribe become unclaimable.
        uint256 endTimestamp;
        // Max Price per vote.
        uint256 maxRewardPerVote;
        // Total Reward Added.
        uint256 totalRewardAmount;
        // Blacklisted addresses.
        address[] blacklist;
    }

    /// @notice Period struct.
    struct Period {
        // Period id.
        // Eg: 0 is the first period, 1 is the second period, etc.
        uint8 id;
        // Timestamp of the period start.
        uint256 timestamp;
        // Reward amount distributed during the period.
        uint256 rewardPerPeriod;
    }

    struct Upgrade {
        // Number of periods after increase.
        uint8 numberOfPeriods;
        // Total reward amount after increase.
        uint256 totalRewardAmount;
        // New max reward per vote after increase.
        uint256 maxRewardPerVote;
        // New end timestamp after increase.
        uint256 endTimestamp;
    }

    ////////////////////////////////////////////////////////////////
    /// --- CONSTANTS & IMMUTABLES
    ///////////////////////////////////////////////////////////////

    /// @notice Week in seconds.
    uint256 private constant _WEEK = 1 weeks;

    /// @notice Base unit for fixed point compute.
    uint256 private constant _BASE_UNIT = 1e18;

    /// @notice Minimum duration a Bribe.
    uint8 public constant MINIMUM_PERIOD = 2;

    /// @notice Factory contract.
    Factory public immutable factory;

    /// @notice Gauge Controller.
    GaugeController public immutable gaugeController;

    ////////////////////////////////////////////////////////////////
    /// --- STORAGE VARS
    ///////////////////////////////////////////////////////////////

    /// @notice Bribe ID Counter.
    uint256 public nextID;

    /// @notice ID => Bribe.
    mapping(uint256 => Bribe) public bribes;

    /// @notice ID => Bribe In Queue to be upgraded.
    mapping(uint256 => Upgrade) public upgradeBribeQueue;

    /// @notice ID => Period running.
    mapping(uint256 => Period) public activePeriod;

    /// @notice BribeId => isUpgradeable. If true, the bribe can be upgraded.
    mapping(uint256 => bool) public isUpgradeable;

    /// @notice ID => Amount Claimed per Bribe.
    mapping(uint256 => uint256) public amountClaimed;

    /// @notice ID => Amount of reward per token distributed.
    mapping(uint256 => uint256) public rewardPerToken;

    /// @notice Blacklisted addresses per bribe that aren't counted for rewards arithmetics.
    mapping(uint256 => mapping(address => bool)) public isBlacklisted;

    /// @notice Last time a user claimed
    mapping(address => mapping(uint256 => uint256)) public lastUserClaim;

    ////////////////////////////////////////////////////////////////
    /// --- MODIFIERS
    ///////////////////////////////////////////////////////////////

    modifier onlyManager(uint256 _id) {
        if (msg.sender != bribes[_id].manager) revert AUTH_MANAGER_ONLY();
        _;
    }

    modifier notKilled() {
        if (isKilled) revert KILLED();
        _;
    }

    ////////////////////////////////////////////////////////////////
    /// --- EVENTS
    ///////////////////////////////////////////////////////////////

    /// @notice Emitted when a new bribe is created.
    event BribeCreated(
        uint256 indexed id,
        address indexed gauge,
        address manager,
        address indexed rewardToken,
        uint8 numberOfPeriods,
        uint256 maxRewardPerVote,
        uint256 rewardPerPeriod,
        uint256 totalRewardAmount,
        bool isUpgradeable
    );

    /// @notice Emitted when a bribe is closed.
    event BribeClosed(uint256 id, uint256 remainingReward);

    /// @notice Emitted when a bribe period is rolled over.
    event PeriodRolledOver(uint256 id, uint256 periodId, uint256 timestamp, uint256 rewardPerPeriod);

    /// @notice Emitted on claim.
    event Claimed(
        address indexed user, address indexed rewardToken, uint256 indexed bribeId, uint256 amount, uint256 period
    );

    /// @notice Emitted when a bribe is queued to upgrade.
    event BribeDurationIncreaseQueued(
        uint256 id, uint8 numberOfPeriods, uint256 totalRewardAmount, uint256 maxRewardPerVote
    );

    /// @notice Emitted when a bribe is upgraded.
    event BribeDurationIncreased(
        uint256 id, uint8 numberOfPeriods, uint256 totalRewardAmount, uint256 maxRewardPerVote
    );

    /// @notice Emitted when a bribe manager is updated.
    event ManagerUpdated(uint256 id, address indexed manager);

    ////////////////////////////////////////////////////////////////
    /// --- ERRORS
    ///////////////////////////////////////////////////////////////

    error KILLED();
    error WRONG_INPUT();
    error ZERO_ADDRESS();
    error INVALID_GAUGE();
    error NO_PERIODS_LEFT();
    error NOT_UPGRADEABLE();
    error AUTH_MANAGER_ONLY();
    error ALREADY_INCREASED();
    error NOT_ALLOWED_OPERATION();
    error INVALID_NUMBER_OF_PERIODS();

    ////////////////////////////////////////////////////////////////
    /// --- CONSTRUCTOR
    ///////////////////////////////////////////////////////////////

    /// @notice Create Bribe platform.
    /// @param _gaugeController Address of the gauge controller.
    constructor(address _gaugeController, address _factory) {
        gaugeController = GaugeController(_gaugeController);
        factory = Factory(_factory);
    }

    ////////////////////////////////////////////////////////////////
    /// --- BRIBE CREATION LOGIC
    ///////////////////////////////////////////////////////////////

    /// @notice Create a new bribe.
    /// @param gauge Address of the target gauge.
    /// @param rewardToken Address of the ERC20 used or rewards.
    /// @param numberOfPeriods Number of periods.
    /// @param maxRewardPerVote Target Bias for the Gauge.
    /// @param totalRewardAmount Total Reward Added.
    /// @param blacklist Array of addresses to blacklist.
    /// @return newBribeID of the bribe created.
    function createBribe(
        address gauge,
        address manager,
        address rewardToken,
        uint8 numberOfPeriods,
        uint256 maxRewardPerVote,
        uint256 totalRewardAmount,
        address[] calldata blacklist,
        bool upgradeable
    ) external nonReentrant notKilled returns (uint256 newBribeID) {
        if (rewardToken == address(0)) revert ZERO_ADDRESS();
        if (gaugeController.gauge_types(gauge) < 0) return newBribeID;
        if (numberOfPeriods < MINIMUM_PERIOD) revert INVALID_NUMBER_OF_PERIODS();
        if (totalRewardAmount == 0 || maxRewardPerVote == 0) revert WRONG_INPUT();

        // Transfer the rewards to the contracts.
        ERC20(rewardToken).safeTransferFrom(msg.sender, address(this), totalRewardAmount);

        unchecked {
            // Get the ID for that new Bribe and increment the nextID counter.
            newBribeID = nextID;

            ++nextID;
        }

        uint256 rewardPerPeriod = totalRewardAmount.mulDivDown(1, numberOfPeriods);

        bribes[newBribeID] = Bribe({
            gauge: gauge,
            manager: manager,
            rewardToken: rewardToken,
            numberOfPeriods: numberOfPeriods,
            endTimestamp: getCurrentPeriod() + ((numberOfPeriods + 1) * _WEEK),
            maxRewardPerVote: maxRewardPerVote,
            totalRewardAmount: totalRewardAmount,
            blacklist: blacklist
        });

        emit BribeCreated(
            newBribeID,
            gauge,
            manager,
            rewardToken,
            numberOfPeriods,
            maxRewardPerVote,
            rewardPerPeriod,
            totalRewardAmount,
            upgradeable
            );

        // Set Upgradeable status.
        isUpgradeable[newBribeID] = upgradeable;
        // Starting from next period.
        activePeriod[newBribeID] = Period(0, getCurrentPeriod() + _WEEK, rewardPerPeriod);

        // Add the addresses to the blacklist.
        uint256 length = blacklist.length;
        for (uint256 i = 0; i < length;) {
            isBlacklisted[newBribeID][blacklist[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Claim rewards for a given bribe.
    /// @param bribeId ID of the bribe.
    /// @return Amount of rewards claimed.
    function claim(uint256 bribeId) external returns (uint256) {
        return _claim(msg.sender, bribeId);
    }

    /// @notice Update Bribe for a given id.
    /// @param bribeId ID of the bribe.
    function updateBribePeriod(uint256 bribeId) external nonReentrant {
        _updateBribePeriod(bribeId);
    }

    /// @notice Update multiple bribes for given ids.
    /// @param ids Array of Bribe IDs.
    function updateBribePeriods(uint256[] calldata ids) external nonReentrant {
        uint256 length = ids.length;
        for (uint256 i = 0; i < length;) {
            _updateBribePeriod(ids[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Claim all rewards for multiple bribes.
    /// @param ids Array of bribe IDs to claim.
    function claimAll(uint256[] calldata ids) external {
        uint256 length = ids.length;

        for (uint256 i = 0; i < length;) {
            uint256 id = ids[i];
            _claim(msg.sender, id);

            unchecked {
                ++i;
            }
        }
    }

    ////////////////////////////////////////////////////////////////
    /// --- INTERNAL LOGIC
    ///////////////////////////////////////////////////////////////

    /// @notice Claim rewards for a given bribe.
    /// @param user Address of the user.
    /// @param bribeId ID of the bribe.
    /// @return amount of rewards claimed.
    function _claim(address user, uint256 bribeId) internal nonReentrant notKilled returns (uint256 amount) {
        if (isBlacklisted[bribeId][user]) return 0;
        // Update if needed the current period.
        uint256 currentPeriod = _updateBribePeriod(bribeId);

        Bribe storage bribe = bribes[bribeId];

        // Address of the target gauge.
        address gauge = bribe.gauge;
        // End timestamp of the bribe.
        uint256 endTimestamp = bribe.endTimestamp;
        // Get the last_vote timestamp.
        uint256 lastVote = gaugeController.last_user_vote(user, gauge);
        // Get the end lock date to compute dt.
        uint256 end = gaugeController.vote_user_slopes(user, gauge).end;
        // Get the voting power user slope.
        uint256 userSlope = gaugeController.vote_user_slopes(user, gauge).slope;

        if (
            userSlope == 0 || lastUserClaim[user][bribeId] >= currentPeriod || currentPeriod >= end
                || currentPeriod <= lastVote || currentPeriod >= endTimestamp || currentPeriod != getCurrentPeriod()
                || amountClaimed[bribeId] == bribe.totalRewardAmount
        ) return 0;

        // Update User last claim period.
        lastUserClaim[user][bribeId] = currentPeriod;

        // Voting Power = userSlope * dt
        // with dt = lock_end - period.
        uint256 _bias = _getAddrBias(userSlope, end, currentPeriod);
        // Compute the reward amount based on
        // Reward / Total Votes.
        amount = _bias.mulWadDown(rewardPerToken[bribeId]);
        // Compute the reward amount based on
        // the max price to pay.
        uint256 _amountWithMaxPrice = _bias.mulWadDown(bribe.maxRewardPerVote);
        // Distribute the _min between the amount based on votes, and price.
        amount = _min(amount, _amountWithMaxPrice);

        // Update the amount claimed.
        uint256 _amountClaimed = amountClaimed[bribeId];
        if (amount + _amountClaimed > bribe.totalRewardAmount) {
            amount = bribe.totalRewardAmount - _amountClaimed;
        }

        amountClaimed[bribeId] += amount;

        uint256 platformFee = factory.platformFee(address(gaugeController));
        if (platformFee != 0) {
            uint256 feeAmount = amount.mulWadDown(platformFee);
            amount -= feeAmount;

            // Transfer fees.
            ERC20(bribe.rewardToken).safeTransfer(factory.feeCollector(), feeAmount);
        }
        // Transfer to user.
        ERC20(bribe.rewardToken).safeTransfer(user, amount);

        emit Claimed(user, bribe.rewardToken, bribeId, amount, currentPeriod);
    }

    /// @notice Update the current period for a given bribe.
    /// @param bribeId Bribe ID.
    /// @return current/updated period.
    function _updateBribePeriod(uint256 bribeId) internal returns (uint256) {
        Period storage _activePeriod = activePeriod[bribeId];

        uint256 currentPeriod = getCurrentPeriod();

        if (_activePeriod.id == 0 && currentPeriod == _activePeriod.timestamp) {
            // Initialize reward per token.
            // Only for the first period, and if not already initialized.
            _updateRewardPerToken(bribeId, currentPeriod);
        }

        // Increase Period
        if (block.timestamp >= _activePeriod.timestamp + _WEEK) {
            // Checkpoint gauge to have up to date gauge weight.
            gaugeController.checkpoint_gauge(bribes[bribeId].gauge);
            // Roll to next period.
            _rollOverToNextPeriod(bribeId, currentPeriod);

            return currentPeriod;
        }

        return _activePeriod.timestamp;
    }

    /// @notice Roll over to next period.
    /// @param bribeId Bribe ID.
    /// @param currentPeriod Next period timestamp.
    function _rollOverToNextPeriod(uint256 bribeId, uint256 currentPeriod) internal {
        uint8 index = getActivePeriodPerBribe(bribeId);

        Upgrade storage upgradedBribe = upgradeBribeQueue[bribeId];

        // Check if there is an upgrade in queue.
        if (upgradedBribe.totalRewardAmount != 0) {
            // Save new values.
            bribes[bribeId].numberOfPeriods = upgradedBribe.numberOfPeriods;
            bribes[bribeId].totalRewardAmount = upgradedBribe.totalRewardAmount;
            bribes[bribeId].maxRewardPerVote = upgradedBribe.maxRewardPerVote;
            bribes[bribeId].endTimestamp = upgradedBribe.endTimestamp;

            emit BribeDurationIncreased(
                bribeId, upgradedBribe.numberOfPeriods, upgradedBribe.totalRewardAmount, upgradedBribe.maxRewardPerVote
                );

            // Reset the next values.
            delete upgradeBribeQueue[bribeId];
        }

        Bribe storage bribe = bribes[bribeId];

        uint256 periodsLeft = getPeriodsLeft(bribeId);
        uint256 rewardPerPeriod;
        rewardPerPeriod = bribe.totalRewardAmount - amountClaimed[bribeId];

        if (bribe.endTimestamp > currentPeriod + _WEEK && periodsLeft > 1) {
            rewardPerPeriod = rewardPerPeriod.mulDivDown(1, periodsLeft);
        }

        // Get adjusted slope without blacklisted addresses.
        uint256 gaugeBias = _getAdjustedBias(bribe.gauge, bribe.blacklist, currentPeriod);

        rewardPerToken[bribeId] = rewardPerPeriod.mulDivDown(_BASE_UNIT, gaugeBias);
        activePeriod[bribeId] = Period(index, currentPeriod, rewardPerPeriod);

        emit PeriodRolledOver(bribeId, index, currentPeriod, rewardPerPeriod);
    }

    /// @notice Update the amount of reward per token for a given bribe.
    /// @dev This function is only called once per Bribe.
    function _updateRewardPerToken(uint256 bribeId, uint256 currentPeriod) internal {
        if (rewardPerToken[bribeId] == 0) {
            uint256 gaugeBias = _getAdjustedBias(bribes[bribeId].gauge, bribes[bribeId].blacklist, currentPeriod);
            if (gaugeBias != 0) {
                rewardPerToken[bribeId] = activePeriod[bribeId].rewardPerPeriod.mulDivDown(_BASE_UNIT, gaugeBias);
            }
        }
    }

    ////////////////////////////////////////////////////////////////
    /// ---  VIEWS
    ///////////////////////////////////////////////////////////////

    /// @notice Get an estimate of the reward amount for a given user.
    /// @param user Address of the user.
    /// @param bribeId ID of the bribe.
    /// @return amount of rewards.
    /// Mainly used for UI.
    function claimable(address user, uint256 bribeId) external view returns (uint256 amount) {
        if (isBlacklisted[bribeId][user]) return 0;

        Bribe memory bribe = bribes[bribeId];

        // Update if needed the current period.
        uint256 currentPeriod = getCurrentPeriod();
        // End timestamp of the bribe.
        uint256 endTimestamp = bribe.endTimestamp;
        // Get the last_vote timestamp.
        uint256 lastVote = gaugeController.last_user_vote(user, bribe.gauge);
        // Get the end lock date to compute dt.
        uint256 end = gaugeController.vote_user_slopes(user, bribe.gauge).end;
        // Get the voting power user slope.
        uint256 userSlope = gaugeController.vote_user_slopes(user, bribe.gauge).slope;

        if (
            userSlope == 0 || lastUserClaim[user][bribeId] >= currentPeriod || currentPeriod >= end
                || currentPeriod <= lastVote || currentPeriod >= endTimestamp
                || currentPeriod < getActivePeriod(bribeId).timestamp || amountClaimed[bribeId] >= bribe.totalRewardAmount
        ) return 0;

        uint256 _rewardPerToken = rewardPerToken[bribeId];
        // If period updated.
        if (_rewardPerToken == 0 || (_rewardPerToken > 0 && getActivePeriod(bribeId).timestamp != currentPeriod)) {
            uint256 _rewardPerPeriod;
            // If there is an upgrade in progress but period hasn't been rolled over yet.
            Upgrade memory upgradedBribe = upgradeBribeQueue[bribeId];

            if (upgradedBribe.numberOfPeriods != 0) {
                // Update max reward per vote.
                bribe.maxRewardPerVote = upgradedBribe.maxRewardPerVote;
                bribe.totalRewardAmount = upgradedBribe.totalRewardAmount;
                // Update end timestamp.
                endTimestamp = upgradedBribe.endTimestamp;
            }

            uint256 periodsLeft = endTimestamp > currentPeriod ? (endTimestamp - currentPeriod) / _WEEK : 0;
            _rewardPerPeriod = bribe.totalRewardAmount - amountClaimed[bribeId];

            if (endTimestamp > currentPeriod + _WEEK && periodsLeft > 1) {
                _rewardPerPeriod = _rewardPerPeriod.mulDivDown(1, periodsLeft);
            }

            // Get Adjusted Slope without blacklisted addresses weight.
            uint256 gaugeBias = _getAdjustedBias(bribe.gauge, bribe.blacklist, currentPeriod);
            _rewardPerToken = _rewardPerPeriod.mulDivDown(_BASE_UNIT, gaugeBias);
        }
        // Get user voting power.
        uint256 _bias = _getAddrBias(userSlope, end, currentPeriod);
        // Estimation of the amount of rewards.
        amount = _bias.mulWadDown(_rewardPerToken);
        // Compute the reward amount based on
        // the max price to pay.
        uint256 _amountWithMaxPrice = _bias.mulWadDown(bribe.maxRewardPerVote);
        // Distribute the _min between the amount based on votes, and price.
        amount = _min(amount, _amountWithMaxPrice);

        uint256 _amountClaimed = amountClaimed[bribeId];
        // Update the amount claimed.
        if (amount + _amountClaimed > bribe.totalRewardAmount) {
            amount = bribe.totalRewardAmount - _amountClaimed;
        }
        // Substract fees.
        uint256 platformFee = factory.platformFee(address(gaugeController));
        if (platformFee != 0) {
            amount = amount.mulWadDown(_BASE_UNIT - platformFee);
        }
    }

    ////////////////////////////////////////////////////////////////
    /// --- INTERNAL VIEWS
    ///////////////////////////////////////////////////////////////

    /// @notice Get adjusted slope from Gauge Controller for a given gauge address.
    /// Remove the weight of blacklisted addresses.
    /// @param gauge Address of the gauge.
    /// @param _addressesBlacklisted Array of blacklisted addresses.
    /// @param period   Timestamp to check vote weight.
    function _getAdjustedBias(address gauge, address[] memory _addressesBlacklisted, uint256 period)
        internal
        view
        returns (uint256 gaugeBias)
    {
        // Cache the user slope.
        GaugeController.VotedSlope memory userSlope;
        // Bias
        uint256 _bias;
        // Last Vote
        uint256 _lastVote;
        // Cache the length of the array.
        uint256 length = _addressesBlacklisted.length;
        // Cache blacklist.
        // Get the gauge slope.
        gaugeBias = gaugeController.points_weight(gauge, period).bias;

        for (uint256 i = 0; i < length;) {
            // Get the user slope.
            userSlope = gaugeController.vote_user_slopes(_addressesBlacklisted[i], gauge);
            _lastVote = gaugeController.last_user_vote(_addressesBlacklisted[i], gauge);
            if (period > _lastVote) {
                _bias = _getAddrBias(userSlope.slope, userSlope.end, period);
                gaugeBias -= _bias;
            }
            // Increment i.
            unchecked {
                ++i;
            }
        }
    }

    ////////////////////////////////////////////////////////////////
    /// --- MANAGEMENT LOGIC
    ///////////////////////////////////////////////////////////////

    /// @notice Increase Bribe duration.
    /// @param _bribeId ID of the bribe.
    /// @param _additionnalPeriods Number of periods to add.
    /// @param _increasedAmount Total reward amount to add.
    /// @param _newMaxPricePerVote Total reward amount to add.
    function increaseBribeDuration(
        uint256 _bribeId,
        uint8 _additionnalPeriods,
        uint256 _increasedAmount,
        uint256 _newMaxPricePerVote
    ) external nonReentrant notKilled onlyManager(_bribeId) {
        if (!isUpgradeable[_bribeId]) revert NOT_UPGRADEABLE();
        if (getPeriodsLeft(_bribeId) < 1) revert NO_PERIODS_LEFT();
        if (_increasedAmount == 0 || _newMaxPricePerVote == 0) revert WRONG_INPUT();

        Bribe storage bribe = bribes[_bribeId];
        Upgrade memory upgradedBribe = upgradeBribeQueue[_bribeId];

        ERC20(bribe.rewardToken).safeTransferFrom(msg.sender, address(this), _increasedAmount);

        if (upgradedBribe.totalRewardAmount != 0) {
            upgradedBribe = Upgrade({
                numberOfPeriods: upgradedBribe.numberOfPeriods + _additionnalPeriods,
                totalRewardAmount: upgradedBribe.totalRewardAmount + _increasedAmount,
                maxRewardPerVote: _newMaxPricePerVote,
                endTimestamp: upgradedBribe.endTimestamp + (_additionnalPeriods * _WEEK)
            });
        } else {
            upgradedBribe = Upgrade({
                numberOfPeriods: bribe.numberOfPeriods + _additionnalPeriods,
                totalRewardAmount: bribe.totalRewardAmount + _increasedAmount,
                maxRewardPerVote: _newMaxPricePerVote,
                endTimestamp: bribe.endTimestamp + (_additionnalPeriods * _WEEK)
            });
        }

        upgradeBribeQueue[_bribeId] = upgradedBribe;

        emit BribeDurationIncreaseQueued(
            _bribeId, upgradedBribe.numberOfPeriods, upgradedBribe.totalRewardAmount, _newMaxPricePerVote
            );
    }

    /// @notice Close Bribe if there is remaining.
    /// @param bribeId ID of the bribe to close.
    function closeBribe(uint256 bribeId) external nonReentrant onlyManager(bribeId) {
        // Check if the currentPeriod is the last one.
        // If not, we can increase the duration.
        Bribe storage bribe = bribes[bribeId];

        if (getCurrentPeriod() >= bribe.endTimestamp || isKilled) {
            uint256 leftOver;
            Upgrade memory upgradedBribe = upgradeBribeQueue[bribeId];
            if (upgradedBribe.totalRewardAmount != 0) {
                leftOver = upgradedBribe.totalRewardAmount - amountClaimed[bribeId];
                delete upgradeBribeQueue[bribeId];
            } else {
                leftOver = bribes[bribeId].totalRewardAmount - amountClaimed[bribeId];
            }
            // Transfer the left over to the owner.
            ERC20(bribe.rewardToken).safeTransfer(bribe.manager, leftOver);
            delete bribes[bribeId].manager;

            emit BribeClosed(bribeId, leftOver);
        }
    }

    /// @notice Update Bribe Manager.
    /// @param bribeId ID of the bribe.
    /// @param newManager Address of the new manager.
    function updateManager(uint256 bribeId, address newManager) external nonReentrant onlyManager(bribeId) {
        emit ManagerUpdated(bribeId, bribes[bribeId].manager = newManager);
    }

    function kill() external {
        if (msg.sender != address(factory)) revert NOT_ALLOWED_OPERATION();
        isKilled = true;
    }

    function unKill() external {
        if (msg.sender != address(factory)) revert NOT_ALLOWED_OPERATION();
        isKilled = false;
    }

    ////////////////////////////////////////////////////////////////
    /// --- UTILS FUNCTIONS
    ///////////////////////////////////////////////////////////////

    /// @notice Returns the number of periods left for a given bribe.
    /// @param bribeId ID of the bribe.
    function getPeriodsLeft(uint256 bribeId) public view returns (uint256 periodsLeft) {
        Bribe memory bribe = bribes[bribeId];
        uint256 endTimestamp = bribe.endTimestamp;

        periodsLeft = endTimestamp > getCurrentPeriod() ? (endTimestamp - getCurrentPeriod()) / _WEEK : 0;
    }

    /// @notice Return the bribe object for a given ID.
    /// @param bribeId ID of the bribe.
    function getBribe(uint256 bribeId) external view returns (Bribe memory) {
        return bribes[bribeId];
    }

    /// @notice Return the bribe in queue for a given ID.
    /// @dev Can return an empty bribe if there is no upgrade.
    /// @param bribeId ID of the bribe.
    function getUpgradedBribeQueued(uint256 bribeId) external view returns (Upgrade memory) {
        return upgradeBribeQueue[bribeId];
    }

    /// @notice Return the blacklisted addresses of a bribe for a given ID.
    /// @param bribeId ID of the bribe.
    function getBlacklistedAddressesForBribe(uint256 bribeId) external view returns (address[] memory) {
        return bribes[bribeId].blacklist;
    }

    /// @notice Return the active period running of bribe given an ID.
    /// @param bribeId ID of the bribe.
    function getActivePeriod(uint256 bribeId) public view returns (Period memory) {
        return activePeriod[bribeId];
    }

    /// @notice Return the expected current period id.
    /// @param bribeId ID of the bribe.
    function getActivePeriodPerBribe(uint256 bribeId) public view returns (uint8) {
        Bribe memory bribe = bribes[bribeId];

        uint256 endTimestamp = bribe.endTimestamp;
        uint256 numberOfPeriods = bribe.numberOfPeriods;
        uint256 periodsLeft = endTimestamp > getCurrentPeriod() ? (endTimestamp - getCurrentPeriod()) / _WEEK : 0;

        // If periodsLeft is superior, then the bribe didn't start yet.
        return uint8(periodsLeft > numberOfPeriods ? 0 : numberOfPeriods - periodsLeft);
    }

    /// @notice Return the current period based on Gauge Controller rounding.
    function getCurrentPeriod() public view returns (uint256) {
        return block.timestamp / _WEEK * _WEEK;
    }

    /// @notice Return the minimum between two numbers.
    /// @param a First number.
    /// @param b Second number.
    function _min(uint256 a, uint256 b) private pure returns (uint256 min) {
        min = a < b ? a : b;
    }

    /// @notice Return the bias of a given address based on its lock end date and the current period.
    /// @param userSlope User slope.
    /// @param endLockTime Lock end date of the address.
    /// @param currentPeriod Current period.
    function _getAddrBias(uint256 userSlope, uint256 endLockTime, uint256 currentPeriod)
        internal
        pure
        returns (uint256)
    {
        if (currentPeriod + _WEEK >= endLockTime) return 0;
        return userSlope * (endLockTime - currentPeriod);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface Factory {
    function feeCollector() external view returns (address);

    function platformFee(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface GaugeController {
    struct VotedSlope {
        uint256 slope;
        uint256 power;
        uint256 end;
    }

    struct Point {
        uint256 bias;
        uint256 slope;
    }

    function vote_user_slopes(address, address) external view returns (VotedSlope memory);

    function add_gauge(address, int128) external;

    function WEIGHT_VOTE_DELAY() external view returns (uint256);

    function last_user_vote(address, address) external view returns (uint256);

    function points_weight(address, uint256) external view returns (Point memory);

    function checkpoint_gauge(address) external;

    //solhint-disable-next-line
    function gauge_types(address addr) external view returns (int128);

    //solhint-disable-next-line
    function gauge_relative_weight_write(address addr, uint256 timestamp) external returns (uint256);

    //solhint-disable-next-line
    function gauge_relative_weight(address addr) external view returns (uint256);

    //solhint-disable-next-line
    function gauge_relative_weight(address addr, uint256 timestamp) external view returns (uint256);

    //solhint-disable-next-line
    function get_total_weight() external view returns (uint256);

    //solhint-disable-next-line
    function get_gauge_weight(address addr) external view returns (uint256);

    function vote_for_gauge_weights(address, uint256) external;

    function add_type(string memory, uint256) external;

    function admin() external view returns (address);
}