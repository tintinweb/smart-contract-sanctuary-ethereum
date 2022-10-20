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
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
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

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.16;
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

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {Factory} from "src/interfaces/Factory.sol";
import {GaugeController} from "src/interfaces/GaugeController.sol";

/// version 0.2.0
/// @title  Platform
/// @author Stake DAO
contract Platform is ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    ////////////////////////////////////////////////////////////////
    /// --- STRUCTS
    ///////////////////////////////////////////////////////////////

    /// @notice Bribe struct requirements.
    struct Bribe {
        // Address of the target gauge.
        address gauge;
        // Manager.
        address manager;
        // Address of the ERC20 used or rewards.
        address rewardToken;
        // Number of periods.
        uint8 numberOfPeriods;
        // Bribe duration.
        uint256 endTimestamp;
        // Max Price per vote.
        uint256 maxRewardPerVote;
        // Total Reward Added.
        uint256 totalRewardAmount;
        // Total Reward Added.
        uint256 totalRewardPerPeriod;
        // Blacklisted addresses.
        address[] blacklist;
    }

    /// @notice Period struct.
    struct Period {
        // Period id.
        uint8 id;
        // Period Start Time.
        uint256 timestamp;
        // Total Reward Added.
        uint256 totalPeriodRewardAmount;
    }

    ////////////////////////////////////////////////////////////////
    /// --- CONSTANTS & IMMUTABLES
    ///////////////////////////////////////////////////////////////

    /// @notice Week in seconds.
    uint256 public constant WEEK = 604_800;
    /// @notice Base unit for fixed point compute.
    uint256 public constant BASE_UNIT = 1e18;
    /// @notice Minimum duration a Bribe.
    uint8 public constant MINIMUM_PERIOD = 2;

    /// @notice Gauge Controller.
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

    /// @notice BribeId => IsMutable ?
    mapping(uint256 => bool) public isUpgradeable;

    /// @notice ID => Amount Claimed per Bribe.
    mapping(uint256 => uint256) public claimPerBribe;

    /// @notice ID => Reward Token per Bribe.
    mapping(uint256 => uint256) public rewardPerToken;

    /// @notice ID => Periods.
    mapping(uint256 => Period) public activePeriodPerBribe;

    /// @notice Bribe Id => address to blacklist => isBlacklisted.
    mapping(uint256 => mapping(address => bool)) public isBlacklisted;

    /// @notice User address => Bribe Id => Period claimed.
    mapping(address => mapping(uint256 => uint256)) public lastUserClaim;

    ////////////////////////////////////////////////////////////////
    /// --- MODIFIERS
    ///////////////////////////////////////////////////////////////

    modifier onlyManager(uint256 _id) {
        if (msg.sender != bribes[_id].manager) revert AUTH_MANAGER_ONLY();
        _;
    }

    ////////////////////////////////////////////////////////////////
    /// --- EVENTS
    ///////////////////////////////////////////////////////////////

    event BribeCreated(
        uint256 id,
        address indexed gauge,
        address indexed manager,
        address rewardToken,
        uint8 numberOfPeriods,
        uint256 maxRewardPerVote,
        uint256 totalRewardAmount,
        uint256 totalRewardPerPeriod,
        bool isUpgradeable
    );

    event BribeClosed(uint256 id, uint256 remainingReward);

    event PeriodRolledOver(uint256 id, uint256 periodId, uint256 timestamp, uint256 totalPeriodRewardAmount);

    event Claimed(
        address indexed user, address indexed rewardToken, uint256 indexed bribeId, uint256 amount, uint256 period
    );

    event BribeDurationIncreaseQueued(
        uint256 id, uint8 numberOfPeriods, uint256 totalRewardAmount, uint256 maxRewardPerVote
    );

    event BribeDurationIncreased(
        uint256 id,
        uint8 numberOfPeriods,
        uint256 totalRewardAmount,
        uint256 totalRewardPerPeriod,
        uint256 maxRewardPerVote
    );

    event ManagerUpdated(uint256 id, address indexed manager);

    ////////////////////////////////////////////////////////////////
    /// --- ERRORS
    ///////////////////////////////////////////////////////////////

    error WRONG_INPUT();
    error NOT_MUTABLE();
    error ZERO_ADDRESS();
    error INVALID_GAUGE();
    error AUTH_MANAGER_ONLY();
    error ALREADY_INCREASED();
    error INCORRECT_FEE_AMOUNT();
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
    /// @param blacklist Arrat of addresses to blacklist.
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
    ) external nonReentrant returns (uint256 newBribeID) {
        if (gauge == address(0) || rewardToken == address(0)) revert ZERO_ADDRESS();
        if (gaugeController.gauge_types(gauge) < 0) revert INVALID_GAUGE();
        if (numberOfPeriods < MINIMUM_PERIOD) revert INVALID_NUMBER_OF_PERIODS();
        // Transfer the rewards to the contracts.
        ERC20(rewardToken).safeTransferFrom(msg.sender, address(this), totalRewardAmount);
        unchecked {
            // Get the ID for that new Bribe and increment the nextID counter.
            newBribeID = nextID;

            ++nextID;
        }

        uint256 totalRewardPerPeriod = totalRewardAmount.mulDivDown(1, numberOfPeriods);
        uint256 endTimestamp = getCurrentPeriod() + ((numberOfPeriods + 1) * WEEK);

        // Create the new Bribe.
        bribes[newBribeID] = Bribe({
            gauge: gauge,
            manager: manager,
            rewardToken: rewardToken,
            numberOfPeriods: numberOfPeriods,
            endTimestamp: endTimestamp,
            maxRewardPerVote: maxRewardPerVote,
            totalRewardAmount: totalRewardAmount,
            totalRewardPerPeriod: totalRewardPerPeriod,
            blacklist: blacklist
        });

        // Set Upgradeable status.
        isUpgradeable[newBribeID] = upgradeable;
        // Starting from next period.
        activePeriodPerBribe[newBribeID] = Period(0, getCurrentPeriod() + WEEK, totalRewardPerPeriod);

        // Add the addresses to the blacklist.
        uint256 length = blacklist.length;
        if (length != 0) {
            for (uint256 i = 0; i < length;) {
                isBlacklisted[newBribeID][blacklist[i]] = true;
                unchecked {
                    ++i;
                }
            }
        }

        emit BribeCreated(
            newBribeID,
            gauge,
            manager,
            rewardToken,
            numberOfPeriods,
            maxRewardPerVote,
            totalRewardAmount,
            totalRewardPerPeriod,
            upgradeable
            );
    }

    /// @notice Claim rewards for a given bribe.
    /// @param bribeId ID of the bribe.
    /// @return Amount of rewards claimed.
    function claim(uint256 bribeId) external returns (uint256) {
        return _claim(msg.sender, bribeId);
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
    function _claim(address user, uint256 bribeId) internal nonReentrant returns (uint256 amount) {
        Bribe memory bribe = bribes[bribeId];
        if (isBlacklisted[bribeId][user]) return 0;
        // Update if needed the current period.
        uint256 currentPeriod = _updateBribePeriod(bribeId);

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

        if (userSlope == 0) return 0;

        if (currentPeriod >= end) return 0;
        if (currentPeriod <= lastVote) return 0;
        if (currentPeriod >= endTimestamp) return 0;
        if (currentPeriod != getCurrentPeriod()) return 0;

        if (lastUserClaim[user][bribeId] >= currentPeriod) return 0;

        // Update User last claim period.
        lastUserClaim[user][bribeId] = currentPeriod;
        // Voting Power = userSlope * dt
        // with dt = lock_end - period.
        uint256 _bias = userSlope * (end - currentPeriod);
        // Compute the reward amount based on
        // Reward / Total Votes.
        amount = userSlope.mulWadDown(rewardPerToken[bribeId]);
        // Compute the reward amount based on
        // the max price to pay.
        uint256 _amountWithMaxPrice = _bias.mulWadDown(bribe.maxRewardPerVote);
        // Distribute the min between the amount based on votes, and price.
        amount = min(amount, _amountWithMaxPrice);
        // Reward Token.
        address rewardToken = bribe.rewardToken;
        // Transfer the amount claimed.
        claimPerBribe[bribeId] += amount;

        uint256 feeAmount = amount.mulWadDown(factory.platformFee());

        amount -= feeAmount;
        // Transfer to user.
        ERC20(rewardToken).safeTransfer(user, amount);
        // Transfer fees.
        ERC20(rewardToken).safeTransfer(factory.feeCollector(), feeAmount);

        emit Claimed(user, rewardToken, bribeId, amount, currentPeriod);
    }

    /// @notice Update the current period for a given bribe.
    /// @param bribeId Bribe ID.
    /// @return current/updated period.
    function _updateBribePeriod(uint256 bribeId) internal returns (uint256) {
        Period memory activePeriod = activePeriodPerBribe[bribeId];
        uint256 currentPeriod = getCurrentPeriod();

        if (currentPeriod == activePeriod.timestamp) {
            // Initialize reward per token.
            // Only for the first period.
            _updateRewardPerToken(bribeId);
        }

        // Increase Period
        if (block.timestamp >= activePeriod.timestamp + WEEK) {
            Bribe memory bribe = bribes[bribeId];

            // Checkpoint gauge just in case.
            gaugeController.checkpoint_gauge(bribe.gauge);

            // Get Adjusted Slope without blacklisted addresses weight.
            uint256 gaugeSlope = getAdjustedSlope(bribe.gauge, bribe.blacklist, currentPeriod);

            uint256 index = getActivePeriodPerBribe(bribeId);

            uint256 amountNextPeriod;
            uint256 leftOver;

            if (bribe.endTimestamp == currentPeriod + WEEK) {
                amountNextPeriod = bribe.totalRewardAmount - claimPerBribe[bribeId];
            } else {
                // Update the current amount to distribute.
                leftOver = (++index * bribe.totalRewardPerPeriod) - claimPerBribe[bribeId];
                amountNextPeriod = bribe.totalRewardPerPeriod + leftOver;
            }

            if (gaugeSlope > 0) {
                rewardPerToken[bribeId] = amountNextPeriod * BASE_UNIT / gaugeSlope;
            }
            // Roll to next period.
            _rollOverToNextPeriod(bribeId, leftOver, currentPeriod);

            return currentPeriod;
        }

        return activePeriod.timestamp;
    }

    /// @notice Roll over to next period.
    /// @param bribeId Bribe ID.
    /// @param leftOver Amount to distribute next period.
    /// @param nextPeriodTimestamp Next period timestamp.
    function _rollOverToNextPeriod(uint256 bribeId, uint256 leftOver, uint256 nextPeriodTimestamp) internal {
        uint8 index = getActivePeriodPerBribe(bribeId);

        uint8 newNumberOfPeriods = nextNumberOfPeriods[bribeId];

        Bribe memory bribe = bribes[bribeId];

        if (newNumberOfPeriods > 0) {
            uint256 newMaxRewardPerVote = nextMaxRewardPerVote[bribeId];

            bribe.endTimestamp = bribe.endTimestamp + ((newNumberOfPeriods - bribe.numberOfPeriods) * WEEK);
            bribe.totalRewardAmount = nextTotalRewardAmount[bribeId];

            uint256 _leftOver = bribe.totalRewardAmount - claimPerBribe[bribeId];

            bribe.totalRewardPerPeriod = _leftOver.mulDivDown(1, newNumberOfPeriods - getPeriodsLeft(bribeId));
            bribe.numberOfPeriods = newNumberOfPeriods;
            bribe.maxRewardPerVote = newMaxRewardPerVote;

            // Save new values.
            bribes[bribeId] = bribe;

            // Reset the next values.
            delete changeEffectPeriod[bribeId];
            delete nextNumberOfPeriods[bribeId];
            delete nextMaxRewardPerVote[bribeId];
            delete nextTotalRewardAmount[bribeId];

            emit BribeDurationIncreased(
                bribeId, newNumberOfPeriods, bribe.totalRewardAmount, bribe.totalRewardPerPeriod, newMaxRewardPerVote
                );
        }

        unchecked {
            uint256 totalPeriodRewardAmount;
            if (bribe.endTimestamp == nextPeriodTimestamp + WEEK) {
                totalPeriodRewardAmount = bribes[bribeId].totalRewardAmount - claimPerBribe[bribeId];
            } else {
                totalPeriodRewardAmount = bribes[bribeId].totalRewardPerPeriod + leftOver;
            }

            activePeriodPerBribe[bribeId] = Period(index, nextPeriodTimestamp, totalPeriodRewardAmount);
            emit PeriodRolledOver(bribeId, index, nextPeriodTimestamp, totalPeriodRewardAmount);
        }
    }

    function _updateRewardPerToken(uint256 bribeId) internal {
        if (rewardPerToken[bribeId] == 0) {
            uint256 currentPeriod = getCurrentPeriod();
            uint256 gaugeSlope = getAdjustedSlope(bribes[bribeId].gauge, bribes[bribeId].blacklist, currentPeriod);

            if (gaugeSlope > 0) {
                rewardPerToken[bribeId] = bribes[bribeId].totalRewardPerPeriod.mulDivDown(BASE_UNIT, gaugeSlope);
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

        // Address of the target gauge.
        address gauge = bribe.gauge;
        // Update if needed the current period.
        uint256 currentPeriod = getCurrentPeriod();
        // End timestamp of the bribe.
        uint256 endTimestamp = bribe.endTimestamp;
        // Get the last_vote timestamp.
        uint256 lastVote = gaugeController.last_user_vote(user, gauge);
        // Get the end lock date to compute dt.
        uint256 end = gaugeController.vote_user_slopes(user, gauge).end;
        // Get the voting power user slope.
        uint256 userSlope = gaugeController.vote_user_slopes(user, gauge).slope;

        if (userSlope == 0) return 0;

        if (currentPeriod >= end) return 0;
        if (currentPeriod <= lastVote) return 0;
        if (currentPeriod >= endTimestamp) return 0;

        if (lastUserClaim[user][bribeId] >= currentPeriod) return 0;

        uint8 newNumberOfPeriods = nextNumberOfPeriods[bribeId];

        if (newNumberOfPeriods > 0 && changeEffectPeriod[bribeId] == currentPeriod) {
            uint256 newMaxRewardPerVote = nextMaxRewardPerVote[bribeId];

            endTimestamp = bribe.endTimestamp + ((newNumberOfPeriods - bribe.numberOfPeriods) * WEEK);
            bribe.totalRewardAmount = nextTotalRewardAmount[bribeId];
            uint256 leftOver = bribe.totalRewardAmount - claimPerBribe[bribeId];

            bribe.totalRewardPerPeriod = leftOver.mulDivDown(1, newNumberOfPeriods - getPeriodsLeft(bribeId));
            bribe.maxRewardPerVote = newMaxRewardPerVote;
        }

        // Voting Power = userSlope * dt
        // with dt = lock_end - period.
        uint256 _bias = userSlope * (end - currentPeriod);

        // Get Adjusted Slope without blacklisted addresses weight.
        uint256 gaugeSlope = getAdjustedSlope(gauge, bribe.blacklist, currentPeriod);

        if (gaugeSlope == 0) return 0;

        // Compute the reward estimated to be distributed per per period minus claimed.
        uint256 rewards;
        if (endTimestamp == currentPeriod + WEEK) {
            rewards = bribe.totalRewardAmount - claimPerBribe[bribeId];
        } else {
            uint256 index = getActivePeriodPerBribe(bribeId) + 1;
            rewards = index * bribe.totalRewardPerPeriod - claimPerBribe[bribeId];
        }

        // Estimation of the amount of rewards.
        uint256 estimatedRewardPerToken = rewards.mulDivDown(BASE_UNIT, gaugeSlope);

        amount = userSlope.mulWadDown(estimatedRewardPerToken);
        // Compute the reward amount based on
        // the max price to pay.
        uint256 _amountWithMaxPrice = _bias.mulWadDown(bribe.maxRewardPerVote);
        // Distribute the min between the amount based on votes, and price.
        amount = min(amount, _amountWithMaxPrice);
        amount = amount.mulWadDown(BASE_UNIT - factory.platformFee());
    }
    ////////////////////////////////////////////////////////////////
    /// --- INTERNAL VIEWS
    ///////////////////////////////////////////////////////////////

    /// @notice Get adjusted slope from Gauge Controller for a given gauge address.
    /// Remove the weight of blacklisted addresses.
    /// @param gauge Address of the gauge.
    /// @param _addressesBlacklisted Array of blacklisted addresses.
    /// @param period   Timestamp to check vote weight.
    function getAdjustedSlope(address gauge, address[] memory _addressesBlacklisted, uint256 period)
        internal
        view
        returns (uint256 gaugeSlope)
    {
        uint256 userSlope;
        address addressBlacklisted;
        // Cache the length of the array.
        uint256 length = _addressesBlacklisted.length;

        // Get the gauge slope.
        gaugeSlope = gaugeController.points_weight(gauge, period).slope;

        unchecked {
            for (uint256 i = 0; i < length;) {
                // Cache address.
                addressBlacklisted = _addressesBlacklisted[i];
                // Get the user slope.
                userSlope = gaugeController.vote_user_slopes(addressBlacklisted, gauge).slope;
                // Remove the user slope from the gauge slope.
                gaugeSlope -= userSlope;
                // Increment i.
                ++i;
            }
        }
    }

    function getPeriodsLeft(uint256 bribeId) public view returns (uint256 periodsLeft) {
        Bribe memory bribe = bribes[bribeId];
        uint256 endTimestamp = bribe.endTimestamp;
        periodsLeft = endTimestamp > getCurrentPeriod() ? (endTimestamp - getCurrentPeriod()) / WEEK : 0;
    }

    function getBribe(uint256 bribeId) external view returns (Bribe memory) {
        return bribes[bribeId];
    }

    function getBlacklistedAddressesForBribe(uint256 bribeId) external view returns (address[] memory) {
        return bribes[bribeId].blacklist;
    }

    function getActivePeriod(uint256 bribeId) external view returns (Period memory) {
        return activePeriodPerBribe[bribeId];
    }

    function getActivePeriodPerBribe(uint256 bribeId) public view returns (uint8) {
        Bribe memory bribe = bribes[bribeId];

        uint256 endTimestamp = bribe.endTimestamp;
        uint256 numberOfPeriods = bribe.numberOfPeriods;
        uint256 periodsLeft = endTimestamp > getCurrentPeriod() ? (endTimestamp - getCurrentPeriod()) / WEEK : 0;

        // If periodsLeft is superior, then the bribe didn't start yet.
        return uint8(periodsLeft > numberOfPeriods ? numberOfPeriods : numberOfPeriods - periodsLeft);
    }

    ////////////////////////////////////////////////////////////////
    /// --- MANAGEMENT LOGIC
    ///////////////////////////////////////////////////////////////

    /// @notice Next total reward per period amount next period.
    mapping(uint256 => uint8) public nextNumberOfPeriods;

    /// @notice Next max price to pay for a vote to next period.
    mapping(uint256 => uint256) public nextMaxRewardPerVote;

    /// @notice Next total reward amount next period.
    mapping(uint256 => uint256) public nextTotalRewardAmount;

    /// @notice Next total reward amount next period.
    mapping(uint256 => uint256) public changeEffectPeriod;

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
    ) external nonReentrant onlyManager(_bribeId) {
        if (!isUpgradeable[_bribeId]) revert NOT_MUTABLE();
        if (nextNumberOfPeriods[_bribeId] != 0) revert ALREADY_INCREASED();
        if (_additionnalPeriods == 0 || _increasedAmount == 0) revert WRONG_INPUT();

        Bribe memory bribe = bribes[_bribeId];

        uint256 periodsLeft =
            bribe.endTimestamp > getCurrentPeriod() ? (bribe.endTimestamp - getCurrentPeriod()) / WEEK : 0;

        if (periodsLeft < 1) revert NOT_ALLOWED_OPERATION();

        ERC20(bribe.rewardToken).safeTransferFrom(msg.sender, address(this), _increasedAmount);

        uint8 newNumberOfPeriods = bribe.numberOfPeriods + _additionnalPeriods;

        nextNumberOfPeriods[_bribeId] = newNumberOfPeriods;
        nextMaxRewardPerVote[_bribeId] = _newMaxPricePerVote;
        changeEffectPeriod[_bribeId] = getCurrentPeriod() + WEEK;

        emit BribeDurationIncreaseQueued(
            _bribeId,
            newNumberOfPeriods,
            nextTotalRewardAmount[_bribeId] = bribe.totalRewardAmount + _increasedAmount,
            _newMaxPricePerVote
            );
    }

    /// @notice Close Bribe if there is remaining.
    /// @param bribeId ID of the bribe to close.
    function closeBribe(uint256 bribeId) external nonReentrant onlyManager(bribeId) {
        // Check if the currentPeriod is the last one.
        // If not, we can increase the duration.
        Bribe memory bribe = bribes[bribeId];

        if (getCurrentPeriod() >= bribe.endTimestamp) {
            uint256 leftOver = bribes[bribeId].totalRewardAmount - claimPerBribe[bribeId];
            // Transfer the left over to the owner.
            ERC20(bribe.rewardToken).safeTransfer(bribe.manager, leftOver);
            delete bribes[bribeId].manager;

            emit BribeClosed(bribeId, leftOver);
        }
    }

    function updateManager(uint256 bribeId, address newManager) external nonReentrant onlyManager(bribeId) {
        emit ManagerUpdated(bribeId, bribes[bribeId].manager = newManager);
    }

    ////////////////////////////////////////////////////////////////
    /// --- UTILS FUNCTIONS
    ///////////////////////////////////////////////////////////////

    /// @notice Create a new bribe.
    /// @param gauge Address of the target gauge.
    /// @param rewardToken Address of the ERC20 used or rewards.
    /// @param numberOfPeriods Number of periods.
    /// @param maxRewardPerVote Target Bias for the Gauge.
    /// @param totalRewardAmount Total Reward Added.
    /// @param blacklist Arrat of addresses to blacklist.
    /// @return newBribeID of the bribe created.
    function createBribeTesnet(
        address gauge,
        address manager,
        address rewardToken,
        uint8 numberOfPeriods,
        uint256 maxRewardPerVote,
        uint256 totalRewardAmount,
        address[] calldata blacklist,
        bool upgradeable
    ) external nonReentrant returns (uint256 newBribeID) {
        if (gauge == address(0) || rewardToken == address(0)) revert ZERO_ADDRESS();
        if (gaugeController.gauge_types(gauge) < 0) revert INVALID_GAUGE();
        if (numberOfPeriods < MINIMUM_PERIOD) revert INVALID_NUMBER_OF_PERIODS();
        // Transfer the rewards to the contracts.
        ERC20(rewardToken).safeTransferFrom(msg.sender, address(this), totalRewardAmount);
        unchecked {
            // Get the ID for that new Bribe and increment the nextID counter.
            newBribeID = nextID;

            ++nextID;
        }

        uint256 totalRewardPerPeriod = totalRewardAmount.mulDivDown(1, numberOfPeriods);
        uint256 endTimestamp = getCurrentPeriod() + ((numberOfPeriods + 1) * WEEK);

        // Create the new Bribe.
        bribes[newBribeID] = Bribe({
            gauge: gauge,
            manager: manager,
            rewardToken: rewardToken,
            numberOfPeriods: numberOfPeriods,
            endTimestamp: endTimestamp,
            maxRewardPerVote: maxRewardPerVote,
            totalRewardAmount: totalRewardAmount,
            totalRewardPerPeriod: totalRewardPerPeriod,
            blacklist: blacklist
        });

        // Set Upgradeable status.
        isUpgradeable[newBribeID] = upgradeable;
        // Starting from next period.
        activePeriodPerBribe[newBribeID] = Period(0, getCurrentPeriod() + WEEK, totalRewardPerPeriod);

        // Add the addresses to the blacklist.
        uint256 length = blacklist.length;
        if (length != 0) {
            for (uint256 i = 0; i < length;) {
                isBlacklisted[newBribeID][blacklist[i]] = true;
                unchecked {
                    ++i;
                }
            }
        }

        emit BribeCreated(
            newBribeID,
            gauge,
            manager,
            rewardToken,
            numberOfPeriods,
            maxRewardPerVote,
            totalRewardAmount,
            totalRewardPerPeriod,
            upgradeable
            );
    }
    ////////////////////////////////////////////////////////////////
    /// --- UTILS FUNCTIONS
    ///////////////////////////////////////////////////////////////

    function getPlatformFee() public view returns (uint256) {
        return factory.platformFee();
    }

    function getCurrentPeriod() public view returns (uint256) {
        return block.timestamp / WEEK * WEEK;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface Factory {
    function feeCollector() external view returns (address);

    function platformFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

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