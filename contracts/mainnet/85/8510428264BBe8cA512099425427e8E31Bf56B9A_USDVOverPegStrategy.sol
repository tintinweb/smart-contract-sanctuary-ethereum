// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

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

    /*///////////////////////////////////////////////////////////////
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
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                            COMMON BASE UNITS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant YAD = 1e8;
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RAD = 1e45;

    /*///////////////////////////////////////////////////////////////
                         FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // If baseUnit is zero this will return zero instead of reverting.
            z := div(z, baseUnit)
        }
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * baseUnit in z for now.
            z := mul(x, baseUnit)

            // Equivalent to require(y != 0 && (x == 0 || (x * baseUnit) / x == baseUnit))
            if iszero(and(iszero(iszero(y)), or(iszero(x), eq(div(z, x), baseUnit)))) {
                revert(0, 0)
            }

            // We ensure y is not zero above, so there is never division by zero here.
            z := div(z, y)
        }
    }

    function fpow(
        uint256 x,
        uint256 n,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := baseUnit
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store baseUnit in z for now.
                    z := baseUnit
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, baseUnit)

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
                    x := div(xxRound, baseUnit)

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
                        z := div(zxRound, baseUnit)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z)
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z)
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z)
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z)
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z)
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z)
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x <= type(uint248).max);

        y = uint248(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x <= type(uint128).max);

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x <= type(uint96).max);

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x <= type(uint64).max);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x <= type(uint32).max);

        y = uint32(x);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /* ///////////////////////////////////////////////////////////////
    SIMPLIFIED FIXED POINT OPERATIONS
    ////////////////////////////////////////////////////////////// */

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD);
        // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD);
        // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y);
        // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y);
        // Equivalent to (x * WAD) / y rounded up.
    }

    /* ///////////////////////////////////////////////////////////////
    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/
    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
        // Store x * y in z for now.
            z := mul(x, y)

        // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

        // If baseUnit is zero this will return zero instead of reverting.
            z := div(z, baseUnit)
        }
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
        // Store x * baseUnit in z for now.
            z := mul(x, baseUnit)

        // Equivalent to require(y != 0 && (x == 0 || (x * baseUnit) / x == baseUnit))
            if iszero(and(iszero(iszero(y)), or(iszero(x), eq(div(z, x), baseUnit)))) {
                revert(0, 0)
            }

        // We ensure y is not zero above, so there is never division by zero here.
            z := div(z, y)
        }
    }

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
        // Store x * y in z for now.
            z := mul(x, y)

        // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

        // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
        // Store x * y in z for now.
            z := mul(x, y)

        // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

        // First, divide z - 1 by the denominator and add 1.
        // Then multiply it by 0 if z is zero, or 1 otherwise.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                // 0 ** 0 = 1
                    z := denominator
                }
                default {
                // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                // If n is even, store denominator in z for now.
                    z := denominator
                }
                default {
                // If n is odd, store x in z for now.
                    z := x
                }

            // Shifting right by 1 is like dividing by 2.
                let half := shr(1, denominator)

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
                    x := div(xxRound, denominator)

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
                        z := div(zxRound, denominator)
                    }
                }
            }
        }
    }

    /* ///////////////////////////////////////////////////////////////
    GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
        // Start off with z at 1.
            z := 1

        // Used below to help find a nearby power of 2.
            let y := x

        // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z)
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z)
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z)
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z)
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z)
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z)
            }
            if iszero(lt(y, 0x8)) {
            // Equivalent to 2 ** z.
                z := shl(1, z)
            }

        // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

        // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

        // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {Auth, Authority} from "@rari-capital/solmate/src/auth/Auth.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {SafeCastLib} from "@rari-capital/solmate/src/utils/SafeCastLib.sol";
import {FixedPointMathLib} from "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";
import {IVaderMinter} from "./interfaces/vader/IVaderMinter.sol";

contract VaderGateway is Auth, IVaderMinter {

    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;
    using SafeCastLib for uint256;

    IVaderMinter public immutable VADERMINTER;

    ERC20 public immutable VADER;
    ERC20 public immutable USDV;

    constructor(
        address VADERMINTER_,
        address GOVERNANCE_,
        Authority AUTHORITY_,
        address VADER_,
        address USDV_
    ) Auth(GOVERNANCE_, Authority(AUTHORITY_))
    {
        VADERMINTER = IVaderMinter(VADERMINTER_);
        VADER = ERC20(VADER_);
        USDV = ERC20(USDV_);

        //set approvals
        VADER.safeApprove(VADERMINTER_, type(uint256).max);
        VADER.safeApprove(address(USDV), type(uint256).max);
        USDV.safeApprove(VADERMINTER_, type(uint256).max);
    }


    function lbt() external view returns (address) {
        return VADERMINTER.lbt();
    }

    // The 24 hour limits on USDV mints that are available for public minting and burning as well as the fee.
    function dailyLimits() external view returns (Limits memory) {
        return VADERMINTER.dailyLimits();
    }

    // The current cycle end timestamp
    function cycleTimestamp() external view returns (uint) {
        return VADERMINTER.cycleTimestamp();
    }

    // The current cycle cumulative mints
    function cycleMints() external view returns (uint) {
        return VADERMINTER.cycleMints();
    }

    // The current cycle cumulative burns
    function cycleBurns() external view returns (uint){
        return VADERMINTER.cycleBurns();
    }

    function partnerLimits(address partner) external view returns (Limits memory){
        return VADERMINTER.partnerLimits(partner);
    }

    // USDV Contract for Mint / Burn Operations
    function usdv() external view returns (address) {
        return VADERMINTER.usdv();
    }

    /*
     * @dev Partner mint function that receives Vader and mints USDV.
     * @param vAmount Vader amount to burn.
     * @returns uAmount in USDV, represents the USDV amount received from the mint.
     *
     * Requirements:
     * - Can only be called by whitelisted partners.
     **/
    function partnerMint(uint256 vAmount, uint256 uMinOut) external requiresAuth returns (uint256 uAmount) {
        VADER.transferFrom(msg.sender, address(this), vAmount);

        uAmount = VADERMINTER.partnerMint(vAmount, uMinOut);

        USDV.safeTransfer(msg.sender, uAmount);
    }
    /*
     * @dev Partner burn function that receives USDV and mints Vader.
     * @param uAmount USDV amount to burn.
     * @returns vAmount in Vader, represents the Vader amount received from the mint.
     *
     * Requirements:
     * - Can only be called by whitelisted partners.
     **/
    function partnerBurn(uint256 uAmount, uint256 vMinOut) external requiresAuth returns (uint256 vAmount) {
        USDV.transferFrom(msg.sender, address(this), uAmount);
        vAmount = VADERMINTER.partnerBurn(uAmount, vMinOut);
        VADER.safeTransfer(msg.sender, vAmount);
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.11;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";

/// @notice Minimal interface for Vault compatible strategies.
/// @dev Designed for out of the box compatibility with Fuse cTokens.
/// @dev Like cTokens, strategies must be transferrable ERC20s.
abstract contract Strategy is ERC20 {
    /// @notice Returns whether the strategy accepts ETH or an ERC20.
    /// @return True if the strategy accepts ETH, false otherwise.
    /// @dev Only present in Fuse cTokens, not Compound cTokens.
    function isCEther() external view virtual returns (bool);

    /// @notice Withdraws a specific amount of underlying tokens from the strategy.
    /// @param amount The amount of underlying tokens to withdraw.
    /// @return An error code, or 0 if the withdrawal was successful.
    function redeemUnderlying(uint256 amount) external virtual returns (uint256);

    /// @notice Returns a user's strategy balance in underlying tokens.
    /// @param user The user to get the underlying balance of.
    /// @return The user's strategy balance in underlying tokens.
    /// @dev May mutate the state of the strategy by accruing interest.
    function balanceOfUnderlying(address user) external virtual returns (uint256);
}

/// @notice Minimal interface for Vault strategies that accept ERC20s.
/// @dev Designed for out of the box compatibility with Fuse cERC20s.
abstract contract ERC20Strategy is Strategy {
    /// @notice Returns the underlying ERC20 token the strategy accepts.
    /// @return The underlying ERC20 token the strategy accepts.
    function underlying() external view virtual returns (ERC20);

    /// @notice Deposit a specific amount of underlying tokens into the strategy.
    /// @param amount The amount of underlying tokens to deposit.
    /// @return An error code, or 0 if the deposit was successful.
    function mint(uint256 amount) external virtual returns (uint256);
}

/// @notice Minimal interface for Vault strategies that accept ETH.
/// @dev Designed for out of the box compatibility with Fuse cEther.
abstract contract ETHStrategy is Strategy {
    /// @notice Deposit a specific amount of ETH into the strategy.
    /// @dev The amount of ETH is specified via msg.value. Reverts on error.
    function mint() external payable virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}
interface IUniswap {
    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    )
    external
    payable
    returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] memory path
    ) external view returns (uint[] memory amounts);

    function getAmountsOut(
        uint amountIn,
        address[] memory path
    ) external view returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

interface ICurve {
    function get_virtual_price() external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function balances(uint256) external view returns (uint256);
}

interface IXVader is IERC20 {
    function enter(uint256 amount) external;
    function leave(uint256 share) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IVaderMinter {
    struct Limits {
        uint256 fee;
        uint256 mintLimit;
        uint256 burnLimit;
    }

    event PublicMintCapChanged(
        uint256 previousPublicMintCap,
        uint256 publicMintCap
    );

    event PublicMintFeeChanged(
        uint256 previousPublicMintFee,
        uint256 publicMintFee
    );

    event PartnerMintCapChanged(
        uint256 previousPartnerMintCap,
        uint256 partnerMintCap
    );

    event PartnerMintFeeChanged(
        uint256 previousPartnercMintFee,
        uint256 partnerMintFee
    );

    event DailyLimitsChanged(Limits previousLimits, Limits nextLimits);
    event WhitelistPartner(
        address partner,
        uint256 mintLimit,
        uint256 burnLimit,
        uint256 fee
    );

    function lbt() external view returns (address);

    // The 24 hour limits on USDV mints that are available for public minting and burning as well as the fee.
    function dailyLimits() external view returns (Limits memory);

    // The current cycle end timestamp
    function cycleTimestamp() external view returns (uint);

    // The current cycle cumulative mints
    function cycleMints() external view returns (uint);

    // The current cycle cumulative burns
    function cycleBurns() external view returns (uint);

    function partnerLimits(address) external view returns (Limits memory);

    // USDV Contract for Mint / Burn Operations
    function usdv() external view returns (address);

    function partnerMint(uint256 vAmount, uint256 uAmountMinOut) external returns (uint256 uAmount);

    function partnerBurn(uint256 uAmount, uint256 vAmountMinOut) external returns (uint256 vAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {Auth, Authority} from "@rari-capital/solmate/src/auth/Auth.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {SafeCastLib} from "@rari-capital/solmate/src/utils/SafeCastLib.sol";
import {FixedPointMathLib} from "../FixedPointMathLib.sol";
import {ERC20Strategy} from "../interfaces/Strategy.sol";
import {VaderGateway, IVaderMinter} from "../VaderGateway.sol";
import {IERC20, IUniswap, IXVader, ICurve} from "../interfaces/StrategyInterfaces.sol";

contract USDVOverPegStrategy is Auth, ERC20("USDVOverPegStrategy", "aUSDVOverPegStrategy", 18), ERC20Strategy {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    ERC20 public constant DAI = ERC20(address(0x6B175474E89094C44Da98b954EedeAC495271d0F));  //our flip
    ERC20 public constant USDC = ERC20(address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)); //our flap
    ERC20 public constant USDT = ERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7)); //our flop
    ERC20 public constant USDV = ERC20(address(0xea3Fb6f331735252E7Bfb0b24b3B761301293DBe));

    ERC20 public immutable WETH;
    ICurve public immutable POOL;
    IUniswap public immutable UNISWAP;
    IXVader public immutable XVADER;
    IVaderMinter public immutable VADERGATEWAY;

    constructor(
        ERC20 UNDERLYING_,
        address GOVERNANCE_,
        Authority AUTHORITY_,
        address POOL_,
        address XVADER_,
        address VADERGATEWAY_,
        address UNIROUTER_,
        address WETH_
    ) Auth(GOVERNANCE_, AUTHORITY_) { //set authority to something that enables operators for aphra
        UNDERLYING = UNDERLYING_; //vader
        BASE_UNIT = 10e18;

        POOL = ICurve(POOL_);
        XVADER = IXVader(XVADER_);

        VADERGATEWAY = IVaderMinter(VADERGATEWAY_); // our partner minter
        UNISWAP = IUniswap(UNIROUTER_);
        WETH = ERC20(WETH_);

        USDV.safeApprove(POOL_, type(uint256).max); //set unlimited approval to the pool for usdv
        DAI.safeApprove(UNIROUTER_, type(uint256).max);
        USDC.safeApprove(UNIROUTER_, type(uint256).max);
        USDT.safeApprove(UNIROUTER_, type(uint256).max);
        WETH.safeApprove(UNIROUTER_, type(uint256).max); //prob not needed
        UNDERLYING.safeApprove(XVADER_, type(uint256).max);
        UNDERLYING.safeApprove(VADERGATEWAY_, type(uint256).max);
    }

    /* //////////////////////////////////////////////////////////////
                             STRATEGY LOGIC
    ///////////////////////////////////////////////////////////// */


    function hit(uint256 vAmount_, int128 exitCoin_, address[] memory pathToVader_) external requiresAuth () {
        _unstakeUnderlying(vAmount_);
        uint uAmount = VADERGATEWAY.partnerMint(UNDERLYING.balanceOf(address(this)), uint(1));
        uint vAmount = _swapUSDVToVader(uAmount, exitCoin_, pathToVader_);
        _stakeUnderlying(vAmount);
        require(vAmount > vAmount_, "Failed to arb for profit");
    unchecked {
        require( POOL.balances(1) * 1e3 / (POOL.balances(0)) >= 1e3, "peg must be at or above 1");
    }

    }

    function isCEther() external pure override returns (bool) {
        return false;
    }

    function ethToUnderlying(uint256 ethAmount_) external view returns (uint256) {
        if (ethAmount_ == 0) {
            return 0;
        }

        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(UNDERLYING);
        uint256[] memory amounts = UNISWAP.getAmountsOut(ethAmount_, path);

        return amounts[amounts.length - 1];
    }

    function underlying() external view override returns (ERC20) {
        return UNDERLYING;
    }

    function mint(uint256 amount) external requiresAuth override returns (uint256) {
        _mint(msg.sender, amount.fdiv(_exchangeRate(), BASE_UNIT));
        UNDERLYING.safeTransferFrom(msg.sender, address(this), amount);
        _stakeUnderlying(UNDERLYING.balanceOf(address(this)));
        return 0;
    }

    function redeemUnderlying(uint256 amount) external override returns (uint256) {
        _burn(msg.sender, amount.fdiv(_exchangeRate(), BASE_UNIT));

        if (UNDERLYING.balanceOf(address(this)) < amount) {
            uint leaveAmount = amount - UNDERLYING.balanceOf(address(this));
            _unstakeUnderlying(leaveAmount);
        }
        UNDERLYING.safeTransfer(msg.sender, amount);

        return 0;
    }

    function balanceOfUnderlying(address user) external view override returns (uint256) {
        return balanceOf[user].fmul(_exchangeRate(), BASE_UNIT);
    }

    /* //////////////////////////////////////////////////////////////
                            INTERNAL LOGIC
    ///////////////////////////////////////////////////////////// */

    ERC20 internal immutable UNDERLYING;

    uint256 internal immutable BASE_UNIT;

    function _stakeUnderlying(uint vAmount) internal {
        XVADER.enter(vAmount);
    }

    function _computeStakedSharesForUnderlying(uint vAmount) internal view returns(uint256) {
        return (vAmount * XVADER.totalSupply()) / UNDERLYING.balanceOf(address(XVADER));
    }

    function _unstakeUnderlying(uint vAmount) internal {
        uint shares = _computeStakedSharesForUnderlying(vAmount);
        XVADER.leave(shares);
    }

    function _swapUSDVToVader(uint uAmount_, int128 exitCoin_, address[] memory path_) internal returns (uint vAmount) {
        //get best exit address
        //get mins for swap
        address exitCoinAddr = address(DAI);
        if (exitCoin_ == int128(2)) {
            exitCoinAddr = address(USDC);
        } else if (exitCoin_ == int128(3)) {
            exitCoinAddr = address(USDT);
        }
        POOL.exchange_underlying(0, exitCoin_, uAmount_, uint(1));

        address[] memory path;
        if(path_.length == 0) {
            path = new address[](3);
            path[0] = exitCoinAddr;
            path[1] = address(WETH);
            path[2] = address(UNDERLYING); //vader eth pool has the best depth for vader
        } else {
            path = path_;
        }

        uint256 amountIn = ERC20(exitCoinAddr).balanceOf(address(this));
        uint256[] memory amounts = UNISWAP.getAmountsOut(amountIn, path);
        vAmount = amounts[amounts.length - 1];
        UNISWAP.swapExactTokensForTokens(
            amountIn,
            vAmount,
            path,
            address(this),
            block.timestamp
        );

    }

    function _computeStakedUnderlying() internal view returns (uint256) {
        return (XVADER.balanceOf(address(this)) * UNDERLYING.balanceOf(address(XVADER))) / XVADER.totalSupply();
    }

    function _exchangeRate() internal view returns (uint256) {
        uint256 cTokenSupply = totalSupply;

        if (cTokenSupply == 0) return BASE_UNIT;
        uint underlyingBalance;
        uint stakedBalance = _computeStakedUnderlying();
        unchecked {
            underlyingBalance = UNDERLYING.balanceOf(address(this)) + stakedBalance;
        }
        return underlyingBalance.fdiv(cTokenSupply, BASE_UNIT);
    }
}