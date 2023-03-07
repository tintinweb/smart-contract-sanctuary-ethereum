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

import {ERC20} from "../tokens/ERC20.sol";
import {SafeTransferLib} from "../utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "../utils/FixedPointMathLib.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
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

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo24(uint256 x) internal pure returns (uint24 y) {
        require(x < 1 << 24);

        y = uint24(x);
    }

    function safeCastTo16(uint256 x) internal pure returns (uint16 y) {
        require(x < 1 << 16);

        y = uint16(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
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

/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity ^0.8.13;

import { ERC20, ERC4626 } from "../lib/solmate/src/mixins/ERC4626.sol";
import { FixedPointMathLib } from "../lib/solmate/src/utils/FixedPointMathLib.sol";

/**
 * @title Debt Token.
 * @author Pragma Labs
 * @notice The Logic to do the debt accounting for a lending pool for a certain ERC20 token.
 * @dev Protocol is according the ERC4626 standard, with a certain ERC20 as underlying.
 * @dev Implementation not vulnerable to ERC4626 inflation attacks,
 * since totalAssets() cannot be manipulated by first minter when total amount of shares are low.
 * For more information, see https://github.com/OpenZeppelin/openzeppelin-contracts/issues/3706.
 */
abstract contract DebtToken is ERC4626 {
    using FixedPointMathLib for uint256;

    /* //////////////////////////////////////////////////////////////
                                STORAGE
    ////////////////////////////////////////////////////////////// */

    // Total amount of `underlying asset` that debtors have in debt, does not take into account pending interests.
    uint256 public realisedDebt;
    // Maximum amount of `underlying asset` in debt that a single debtor can take.
    uint128 public borrowCap;

    error FunctionNotImplemented();

    /* //////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice The constructor for the debt token.
     * @param asset_ The underlying ERC-20 token in which the debt is denominated.
     */
    constructor(ERC20 asset_)
        ERC4626(
            asset_,
            string(abi.encodePacked("Arcadia ", asset_.name(), " Debt")),
            string(abi.encodePacked("darc", asset_.symbol()))
        )
    { }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the total amount of outstanding debt in the underlying asset.
     * @return totalDebt The total debt in underlying assets.
     * @dev Implementation overwritten in LendingPool.sol which inherits DebtToken.sol.
     * Implementation not vulnerable to ERC4626 inflation attacks,
     * totaLAssets() does not rely on balanceOf call.
     */
    function totalAssets() public view virtual override returns (uint256) { }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Modification of the standard ERC-4626 deposit implementation.
     * @dev No public deposit allowed.
     */
    function deposit(uint256, address) public pure override returns (uint256) {
        revert FunctionNotImplemented();
    }

    /**
     * @notice Modification of the standard ERC-4626 deposit implementation.
     * @param assets The amount of assets of the underlying ERC-20 token being loaned out.
     * @param receiver The Arcadia vault with collateral covering the loan.
     * @return shares The corresponding amount of debt shares minted.
     * @dev Only the Lending Pool (which inherits this contract) can issue debt.
     */
    function _deposit(uint256 assets, address receiver) internal returns (uint256 shares) {
        shares = previewDeposit(assets); // No need to check for rounding error, previewDeposit rounds up.
        if (borrowCap > 0) require(maxWithdraw(receiver) + assets <= borrowCap, "DT_D: BORROW_CAP_EXCEEDED");

        _mint(receiver, shares);

        realisedDebt += assets;

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * @notice Modification of the standard ERC-4626 deposit implementation.
     * @dev No public mint allowed.
     */
    function mint(uint256, address) public pure override returns (uint256) {
        revert FunctionNotImplemented();
    }

    /**
     * @notice Modification of the standard ERC-4626 withdraw implementation.
     * @dev No public withdraw allowed.
     */
    function withdraw(uint256, address, address) public pure override returns (uint256) {
        revert FunctionNotImplemented();
    }

    /**
     * @notice Modification of the standard ERC-4626 withdraw implementation.
     * @param assets The amount of assets of the underlying ERC-20 token being paid back.
     * @param receiver Will always be the Lending Pool.
     * @param owner_ The Arcadia vault with collateral covering the loan.
     * @return shares The corresponding amount of debt shares redeemed.
     * @dev Only the Lending Pool (which inherits this contract) can issue debt.
     */
    function _withdraw(uint256 assets, address receiver, address owner_) internal returns (uint256 shares) {
        // Check for rounding error since we round down in previewWithdraw.
        require((shares = previewWithdraw(assets)) != 0, "DT_W: ZERO_SHARES");

        _burn(owner_, shares);

        realisedDebt -= assets;

        emit Withdraw(msg.sender, receiver, owner_, assets, shares);
    }

    /**
     * @notice Modification of the standard ERC-4626 redeem implementation.
     * @dev No public redeem allowed.
     */
    function redeem(uint256, address, address) public pure override returns (uint256) {
        revert FunctionNotImplemented();
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Modification of the standard ERC-4626 convertToShares implementation.
     * @dev Since debt is a liability instead of an asset, roundUp and roundDown are inverted compared to the standard implementation.
     */
    function convertToShares(uint256 assets) public view override returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    /**
     * @notice Modification of the standard ERC-4626 convertToShares implementation.
     * @dev Since debt is a liability instead of an asset, roundUp and roundDown are inverted compared to the standard implementation.
     */
    function convertToAssets(uint256 shares) public view override returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    /**
     * @notice Modification of the standard ERC-4626 previewMint implementation.
     * @dev Since debt is a liability instead of an asset, roundUp and roundDown are inverted compared to the standard implementation.
     */
    function previewMint(uint256 shares) public view override returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    /**
     * @notice Modification of the standard ERC-4626 previewWithdraw implementation.
     * @dev Since debt is a liability instead of an asset, roundUp and roundDown are inverted compared to the standard implementation.
     */
    function previewWithdraw(uint256 assets) public view override returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    /*//////////////////////////////////////////////////////////////
                            TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Modification of the standard ERC-4626 approve implementation.
     * @dev No public approve allowed.
     */
    function approve(address, uint256) public pure override returns (bool) {
        revert FunctionNotImplemented();
    }

    /**
     * @notice Modification of the standard ERC-4626 transfer implementation.
     * @dev No public transfer allowed.
     */
    function transfer(address, uint256) public pure override returns (bool) {
        revert FunctionNotImplemented();
    }

    /**
     * @notice Modification of the standard ERC-4626 transferFrom implementation.
     * @dev No public transferFrom allowed.
     */
    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert FunctionNotImplemented();
    }

    /**
     * @notice Modification of the standard ERC-4626 permit implementation.
     * @dev No public permit allowed.
     */
    function permit(address, address, uint256, uint256, uint8, bytes32, bytes32) public pure override {
        revert FunctionNotImplemented();
    }
}

/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity ^0.8.13;

/**
 * @title Interest Rate Module.
 * @author Pragma Labs
 * @notice The Logic to calculate and store the interest rate of the Lending Pool.
 */
contract InterestRateModule {
    /* //////////////////////////////////////////////////////////////
                                STORAGE
    ////////////////////////////////////////////////////////////// */

    // The current interest rate, 18 decimals precision.
    uint256 public interestRate;

    // A struct with the configuration of the interest rate curves,
    // which give the interest rate in function of the utilisation of the Lending Pool.
    InterestRateConfiguration public interestRateConfig;

    /**
     * A struct with the set of interest rate configuration parameters:
     * - baseRatePerYear The interest rate when utilisation is 0.
     * - lowSlopePerYear The slope of the first curve, defined as the delta in interest rate for a delta in utilisation of 100%.
     * - highSlopePerYear The slope of the second curve, defined as the delta in interest rate for a delta in utilisation of 100%.
     * - utilisationThreshold the optimal utilisation, where we go from the flat first curve to the steeper second curve.
     */
    struct InterestRateConfiguration {
        uint72 baseRatePerYear; //18 decimals precision.
        uint72 lowSlopePerYear; //18 decimals precision.
        uint72 highSlopePerYear; //18 decimals precision.
        uint40 utilisationThreshold; //5 decimal precision.
    }

    /* //////////////////////////////////////////////////////////////
                                EVENTS
    ////////////////////////////////////////////////////////////// */

    event InterestRate(uint80 interestRate);

    /* //////////////////////////////////////////////////////////////
                        INTEREST RATE LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Sets the configuration parameters of InterestRateConfiguration struct.
     * @param newConfig A struct with a new set of interest rate configuration parameters:
     * - baseRatePerYear The interest rate when utilisation is 0, 18 decimals precision.
     * - lowSlopePerYear The slope of the first curve, defined as the delta in interest rate for a delta in utilisation of 100%,
     *   18 decimals precision.
     * - highSlopePerYear The slope of the second curve, defined as the delta in interest rate for a delta in utilisation of 100%,
     *   18 decimals precision.
     * - utilisationThreshold the optimal utilisation, where we go from the flat first curve to the steeper second curve,
     *   5 decimal precision.
     */
    function _setInterestConfig(InterestRateConfiguration calldata newConfig) internal {
        interestRateConfig = newConfig;
    }

    /**
     * @notice Calculates the interest rate.
     * @param utilisation Utilisation rate, 5 decimal precision.
     * @return interestRate The current interest rate, 18 decimal precision.
     * @dev The interest rate is a function of the utilisation of the Lending Pool.
     * We use two linear curves: a flat one below the optimal utilisation and a steep one above.
     */
    function _calculateInterestRate(uint256 utilisation) internal view returns (uint256) {
        unchecked {
            if (utilisation >= interestRateConfig.utilisationThreshold) {
                // 1e23 = uT (1e5) * ls (1e18).
                uint256 lowSlopeInterest =
                    uint256(interestRateConfig.utilisationThreshold) * interestRateConfig.lowSlopePerYear;
                // 1e23 = (uT - u) (1e5) * hs (e18).
                uint256 highSlopeInterest = uint256((utilisation - interestRateConfig.utilisationThreshold))
                    * interestRateConfig.highSlopePerYear;
                // 1e18 = bs (1e18) + (lsIR (e23) + hsIR (1e23)) / 1e5.
                return uint256(interestRateConfig.baseRatePerYear) + ((lowSlopeInterest + highSlopeInterest) / 100_000);
            } else {
                // 1e18 = br (1e18) + (ls (1e18) * u (1e5)) / 1e5.
                return uint256(
                    uint256(interestRateConfig.baseRatePerYear)
                        + ((uint256(interestRateConfig.lowSlopePerYear) * utilisation) / 100_000)
                );
            }
        }
    }

    /**
     * @notice Updates the interest rate.
     * @param totalDebt Total amount of debt.
     * @param totalLiquidity Total amount of Liquidity (sum of borrowed out assets and assets still available in the Lending Pool).
     * @dev This function is only be called by the function _updateInterestRate(uint256 realisedDebt_, uint256 totalRealisedLiquidity_),
     * calculates the interest rate, if the totalRealisedLiquidity_ is zero then utilisation is zero.
     */
    function _updateInterestRate(uint256 totalDebt, uint256 totalLiquidity) internal {
        uint256 utilisation; // 5 decimals precision
        if (totalLiquidity > 0) {
            utilisation = (100_000 * totalDebt) / totalLiquidity;
        }

        //Calculates and stores interestRate as a uint256, emits interestRate as a uint80 (interestRate is maximally equal to uint72 + uint72).
        //_updateInterestRate() will be called a lot, saves a read from from storage or a write+read from memory.
        emit InterestRate(uint80(interestRate = _calculateInterestRate(utilisation)));
    }
}

/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity ^0.8.13;

import { SafeTransferLib } from "../lib/solmate/src/utils/SafeTransferLib.sol";
import { SafeCastLib } from "../lib/solmate/src/utils/SafeCastLib.sol";
import { FixedPointMathLib } from "../lib/solmate/src/utils/FixedPointMathLib.sol";
import { LogExpMath } from "./utils/LogExpMath.sol";
import { ITranche } from "./interfaces/ITranche.sol";
import { IFactory } from "./interfaces/IFactory.sol";
import { IVault } from "./interfaces/IVault.sol";
import { ILiquidator } from "./interfaces/ILiquidator.sol";
import { ILendingPool } from "./interfaces/ILendingPool.sol";
import { TrustedCreditor } from "./TrustedCreditor.sol";
import { ERC20, ERC4626, DebtToken } from "./DebtToken.sol";
import { InterestRateModule } from "./InterestRateModule.sol";
import { Guardian } from "./security/Guardian.sol";

/**
 * @title Arcadia LendingPool.
 * @author Pragma Labs
 * @notice The Lending pool contains the main logic to provide liquidity and take or repay loans for a certain asset
 * and does the accounting of the debtTokens (ERC4626).
 * @dev Implementation not vulnerable to ERC4626 inflation attacks,
 * since totalAssets() cannot be manipulated by the first minter.
 * For more information, see https://github.com/OpenZeppelin/openzeppelin-contracts/issues/3706
 */
contract LendingPool is Guardian, TrustedCreditor, DebtToken, InterestRateModule, ILendingPool {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /* //////////////////////////////////////////////////////////////
                                STORAGE
    ////////////////////////////////////////////////////////////// */

    // Seconds per year, leap years ignored.
    uint256 public constant YEARLY_SECONDS = 31_536_000;
    // Contract address of the Arcadia Vault Factory.
    address public immutable vaultFactory;
    // Contract address of the Liquidator contract.
    address public immutable liquidator;

    // Last timestamp that interests were realized.
    uint32 public lastSyncedTimestamp;
    // Origination fee, 4 decimals precision (10 equals 0.001 or 0.1%), capped at 255 (2.55%).
    uint8 public originationFee;
    // Sum of all the interest weights of the tranches + treasury.
    uint24 public totalInterestWeight;
    // Fraction (interestWeightTreasury / totalInterestWeight) of the interest fees that go to the treasury.
    uint16 public interestWeightTreasury;
    // Sum of the liquidation weights of the tranches + treasury.
    uint24 public totalLiquidationWeight;
    // Fraction (liquidationWeightTreasury / totalLiquidationWeight) of the liquidation fees that goes to the treasury.
    uint16 public liquidationWeightTreasury;

    // Total amount of `underlying asset` that is claimable by the LPs. Does not take into account pending interests.
    uint128 public totalRealisedLiquidity;
    // Maximum amount of `underlying asset` that can be supplied to the pool.
    uint128 public supplyCap;
    // Conservative estimate of the maximal gas cost to liquidate a position (fixed cost, independent of openDebt).
    uint96 public fixedLiquidationCost;
    // Maximum amount of `underlying asset` that is paid as fee to the initiator of a liquidation.
    uint80 public maxInitiatorFee;
    // Number of auctions that are currently in progress.
    uint16 public auctionsInProgress;
    // Address of the protocol treasury.
    address public treasury;

    // Array of the interest weights of each Tranche.
    // Fraction (interestWeightTranches[i] / totalInterestWeight) of the interest fees that go to Tranche i.
    uint16[] public interestWeightTranches;
    // Array of the liquidation weights of each Tranche.
    // Fraction (liquidationWeightTranches[i] / totalLiquidationWeight) of the liquidation fees that go to Tranche i.
    uint16[] public liquidationWeightTranches;
    // Array of the contract addresses of the Tranches.
    address[] public tranches;

    // Map tranche => status.
    mapping(address => bool) public isTranche;
    // Map tranche => interestWeight.
    // Fraction (interestWeightTranches[i] / totalInterestWeight) of the interest fees that go to Tranche i.
    mapping(address => uint256) public interestWeight;
    // Map tranche => realisedLiquidity.
    // Amount of `underlying asset` that is claimable by the Tranche. Does not take into account pending interests.
    mapping(address => uint256) public realisedLiquidityOf;
    // Map vault => initiator.
    // Stores the address of the initiator of an auction, used to pay out the initiation fee after auction is ended.
    mapping(address => address) public liquidationInitiator;
    // Map vault => owner => beneficiary => amount.
    // Stores the credit allowances for a beneficiary per Vault and per Owner.
    mapping(address => mapping(address => mapping(address => uint256))) public creditAllowance;

    /* //////////////////////////////////////////////////////////////
                                EVENTS
    ////////////////////////////////////////////////////////////// */

    event TrancheAdded(address indexed tranche, uint8 indexed index, uint16 interestWeight, uint16 liquidationWeight);
    event InterestWeightSet(uint256 indexed index, uint16 weight);
    event LiquidationWeightSet(uint256 indexed index, uint16 weight);
    event MaxInitiatorFeeSet(uint80 maxInitiatorFee);
    event TranchePopped(address tranche);
    event TreasuryInterestWeightSet(uint16 weight);
    event TreasuryLiquidationWeightSet(uint16 weight);
    event OriginationFeeSet(uint8 originationFee);
    event BorrowCapSet(uint128 borrowCap);
    event SupplyCapSet(uint128 supplyCap);
    event CreditApproval(address indexed vault, address indexed owner, address indexed beneficiary, uint256 amount);
    event Borrow(
        address indexed vault, address indexed by, address to, uint256 amount, uint256 fee, bytes3 indexed referrer
    );
    event Repay(address indexed vault, address indexed from, uint256 amount);
    event FixedLiquidationCostSet(uint96 fixedLiquidationCost);
    event VaultVersionSet(uint256 indexed vaultVersion, bool valid);

    error supplyCapExceeded();

    /* //////////////////////////////////////////////////////////////
                                MODIFIERS
    ////////////////////////////////////////////////////////////// */

    modifier onlyLiquidator() {
        require(liquidator == msg.sender, "LP: Only liquidator");
        _;
    }

    modifier onlyTranche() {
        require(isTranche[msg.sender], "LP: Only tranche");
        _;
    }

    modifier processInterests() {
        _syncInterests();
        _;
        //_updateInterestRate() modifies the state (effect), but can safely be called after interactions.
        //Cannot be exploited by re-entrancy attack.
        _updateInterestRate(realisedDebt, totalRealisedLiquidity);
    }

    /* //////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice The constructor for a lending pool.
     * @param asset_ The underlying ERC-20 token of the Lending Pool.
     * @param treasury_ The address of the protocol treasury.
     * @param vaultFactory_ The address of the Vault Factory.
     * @param liquidator_ The address of the Liquidator.
     * @dev The name and symbol of the DebtToken are automatically generated, based on the name and symbol of the underlying token.
     */
    constructor(ERC20 asset_, address treasury_, address vaultFactory_, address liquidator_)
        Guardian()
        TrustedCreditor()
        DebtToken(asset_)
    {
        treasury = treasury_;
        vaultFactory = vaultFactory_;
        liquidator = liquidator_;
    }

    /* //////////////////////////////////////////////////////////////
                            TRANCHES LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Adds a tranche to the Lending Pool.
     * @param tranche The address of the Tranche.
     * @param interestWeight_ The interestWeight of the specific Tranche.
     * @param liquidationWeight The liquidationWeight of the specific Tranche.
     * @dev The order of the tranches is important, the most senior tranche is added first at index 0, the most junior at the last index.
     * @dev Each Tranche is an ERC-4626 contract.
     * @dev The interestWeight of each Tranche determines the relative share of the yield (interest payments) that goes to its Liquidity providers.
     * @dev The liquidationWeight of each Tranche determines the relative share of the liquidation fee that goes to its Liquidity providers.
     */
    function addTranche(address tranche, uint16 interestWeight_, uint16 liquidationWeight) external onlyOwner {
        require(!isTranche[tranche], "TR_AD: Already exists");
        totalInterestWeight += interestWeight_;
        interestWeightTranches.push(interestWeight_);
        interestWeight[tranche] = interestWeight_;

        totalLiquidationWeight += liquidationWeight;
        liquidationWeightTranches.push(liquidationWeight);

        tranches.push(tranche);
        isTranche[tranche] = true;

        emit TrancheAdded(tranche, uint8(tranches.length - 1), interestWeight_, liquidationWeight);
    }

    /**
     * @notice Changes the interestWeight of a specific Tranche.
     * @param index The index of the Tranche for which a new interestWeight is being set.
     * @param weight The new interestWeight of the Tranche at the index.
     * @dev The interestWeight of each Tranche determines the relative share yield (interest payments) that goes to its Liquidity providers.
     */
    function setInterestWeight(uint256 index, uint16 weight) external onlyOwner {
        require(index < tranches.length, "TR_SIW: Non Existing Tranche");
        totalInterestWeight = totalInterestWeight - interestWeightTranches[index] + weight;
        interestWeightTranches[index] = weight;
        interestWeight[tranches[index]] = weight;

        emit InterestWeightSet(index, weight);
    }

    /**
     * @notice Changes the liquidationWeight of a specific tranche.
     * @param index The index of the Tranche for which a new liquidationWeight is being set.
     * @param weight The new liquidationWeight of the Tranche at the index.
     * @dev The liquidationWeight determines the relative share of the liquidation fee that goes to its Liquidity providers.
     */
    function setLiquidationWeight(uint256 index, uint16 weight) external onlyOwner {
        require(index < tranches.length, "TR_SLW: Non Existing Tranche");
        totalLiquidationWeight = totalLiquidationWeight - liquidationWeightTranches[index] + weight;
        liquidationWeightTranches[index] = weight;

        emit LiquidationWeightSet(index, weight);
    }

    /**
     * @notice Removes the Tranche at the last index (most junior).
     * @param index The index of the last Tranche.
     * @param tranche The address of the last Tranche.
     * @dev This function can only be called by the function _processDefault(uint256 assets),
     * when there is a default as big as (or bigger than) the complete principal of the most junior tranche.
     * @dev Passing the input parameters to the function saves gas compared to reading the address and index of the last tranche from memory.
     * No need to check if index and Tranche are indeed of the last tranche since function is only called by _processDefault.
     */
    function _popTranche(uint256 index, address tranche) internal {
        totalInterestWeight -= interestWeightTranches[index];
        totalLiquidationWeight -= liquidationWeightTranches[index];
        isTranche[tranche] = false;
        interestWeightTranches.pop();
        liquidationWeightTranches.pop();
        tranches.pop();

        emit TranchePopped(tranche);
    }

    /* ///////////////////////////////////////////////////////////////
                    TREASURY FEE CONFIGURATION
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Changes the fraction of the interest payments that go to the treasury.
     * @param interestWeightTreasury_ The new interestWeight of the treasury.
     * @dev The interestWeight determines the relative share of the yield (interest payments) that goes to the protocol treasury.
     * @dev Setting interestWeightTreasury to a very high value will cause the treasury to collect all interest fees from that moment on.
     * Although this will affect the future profits of liquidity providers, no funds nor realized interest are at risk for LPs.
     */
    function setTreasuryInterestWeight(uint16 interestWeightTreasury_) external onlyOwner {
        totalInterestWeight = totalInterestWeight - interestWeightTreasury + interestWeightTreasury_;
        interestWeightTreasury = interestWeightTreasury_;

        emit TreasuryInterestWeightSet(interestWeightTreasury_);
    }

    /**
     * @notice Changes the fraction of the liquidation fees that go to the treasury.
     * @param liquidationWeightTreasury_ The new liquidationWeight of the liquidation fee fee.
     * @dev The liquidationWeight determines the relative share of the liquidation fee that goes to the protocol treasury.
     * @dev Setting liquidationWeightTreasury to a very high value will cause the treasury to collect all liquidation fees from that moment on.
     * Although this will affect the future profits of liquidity providers in the Jr tranche, no funds nor realized interest are at risk for LPs.
     */
    function setTreasuryLiquidationWeight(uint16 liquidationWeightTreasury_) external onlyOwner {
        totalLiquidationWeight = totalLiquidationWeight - liquidationWeightTreasury + liquidationWeightTreasury_;
        liquidationWeightTreasury = liquidationWeightTreasury_;

        emit TreasuryLiquidationWeightSet(liquidationWeightTreasury_);
    }

    /**
     * @notice Sets new treasury address.
     * @param treasury_ The new address of the treasury.
     */
    function setTreasury(address treasury_) external onlyOwner {
        treasury = treasury_;
    }

    /**
     * @notice Sets the new origination fee.
     * @param originationFee_ The new origination fee.
     * @dev originationFee is limited by being a uint8 -> max value is 2.55%
     * 4 decimal precision (10 = 0.1%).
     */
    function setOriginationFee(uint8 originationFee_) external onlyOwner {
        originationFee = originationFee_;

        emit OriginationFeeSet(originationFee_);
    }

    /* //////////////////////////////////////////////////////////////
                         PROTOCOL CAP LOGIC
    ////////////////////////////////////////////////////////////// */
    /**
     * @notice Sets the maximum amount of assets that can be borrowed per Vault.
     * @param borrowCap_ The new maximum amount that can be borrowed.
     * @dev The borrowCap is the maximum amount of assets that can be borrowed per Vault.
     * @dev If it is set to 0, there is no borrow cap.
     */
    function setBorrowCap(uint128 borrowCap_) external onlyOwner {
        borrowCap = borrowCap_;

        emit BorrowCapSet(borrowCap_);
    }

    /**
     * @notice Sets the maximum amount of assets that can be deposited in the pool.
     * @param supplyCap_ The new maximum amount of assets that can be deposited.
     * @dev The supplyCap is the maximum amount of assets that can be deposited in the pool at any given time.
     * @dev If it is set to 0, there is no supply cap.
     */
    function setSupplyCap(uint128 supplyCap_) external onlyOwner {
        supplyCap = supplyCap_;

        emit SupplyCapSet(supplyCap_);
    }

    /* //////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Deposit assets in the Lending Pool.
     * @param assets The amount of assets of the underlying ERC-20 tokens being deposited.
     * @param from The address of the Liquidity Provider who deposits the underlying ERC-20 token via a Tranche.
     * @dev This function can only be called by Tranches.
     */

    function depositInLendingPool(uint256 assets, address from)
        external
        whenDepositNotPaused
        onlyTranche
        processInterests
    {
        if (supplyCap > 0) {
            if (totalRealisedLiquidity + assets > supplyCap) revert supplyCapExceeded();
        }
        // Need to transfer before minting or ERC777s could reenter.
        // Address(this) is trusted -> no risk on re-entrancy attack after transfer.
        asset.safeTransferFrom(from, address(this), assets);

        unchecked {
            realisedLiquidityOf[msg.sender] += assets;
            totalRealisedLiquidity += SafeCastLib.safeCastTo128(assets);
        }

        //Event emitted by Tranche.
    }

    /**
     * @notice Donate assets to the Lending Pool.
     * @param trancheIndex The index of the tranche to donate to.
     * @param assets The amount of assets of the underlying ERC-20 tokens being deposited.
     * @dev Can be used by anyone to donate assets to the Lending Pool.
     * It is supposed to serve as a way to compensate the jrTranche after an
     * auction didn't get sold and was manually Liquidated by the Protocol.
     * @dev First minter of a tranche could abuse this function by mining only 1 share,
     * frontrun next minter by calling this function and inflate the share price.
     * This is mitigated by checking that there are at least 10 ** decimals shares outstanding.
     */
    function donateToTranche(uint256 trancheIndex, uint256 assets) external whenDepositNotPaused processInterests {
        require(assets > 0, "LP_DTT: Amount is 0");

        if (supplyCap > 0) {
            if (totalRealisedLiquidity + assets > supplyCap) revert supplyCapExceeded();
        }

        address tranche = tranches[trancheIndex];
        //Mitigate share manipulation, where first Liquidity Provider mints just 1 share.
        //See https://github.com/OpenZeppelin/openzeppelin-contracts/issues/3706 for more information.
        require(ERC4626(tranche).totalSupply() >= 10 ** decimals, "LP_DTT: Insufficient shares");

        asset.safeTransferFrom(msg.sender, address(this), assets);

        unchecked {
            realisedLiquidityOf[tranche] += assets; //[̲̅$̲̅(̲̅ ͡° ͜ʖ ͡°̲̅)̲̅$̲̅]
            totalRealisedLiquidity += SafeCastLib.safeCastTo128(assets);
        }
    }

    /**
     * @notice Withdraw assets from the Lending Pool.
     * @param assets The amount of assets of the underlying ERC-20 tokens being withdrawn.
     * @param receiver The address of the receiver of the underlying ERC-20 tokens.
     * @dev This function can be called by anyone with an open balance (realisedLiquidityOf[address] bigger than 0),
     * which can be both Tranches as other address (treasury, Liquidation Initiators, Liquidated Vault Owner...).
     */
    function withdrawFromLendingPool(uint256 assets, address receiver)
        external
        whenWithdrawNotPaused
        processInterests
    {
        require(realisedLiquidityOf[msg.sender] >= assets, "LP_WFLP: Amount exceeds balance");

        unchecked {
            realisedLiquidityOf[msg.sender] -= assets;
        }
        totalRealisedLiquidity -= SafeCastLib.safeCastTo128(assets);

        asset.safeTransfer(receiver, assets);

        //Event emitted by Tranche.
    }

    /* //////////////////////////////////////////////////////////////
                            LENDING LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Approve a beneficiary to take out a loan against an Arcadia Vault.
     * @param beneficiary The address of the beneficiary who can take out a loan backed by an Arcadia Vault.
     * @param amount The amount of underlying ERC-20 tokens to be lent out.
     * @param vault The address of the Arcadia Vault backing the loan.
     */
    function approveBeneficiary(address beneficiary, uint256 amount, address vault) external {
        //If vault is not an actual address of a vault, ownerOfVault(address) will return the zero address.
        require(IFactory(vaultFactory).ownerOfVault(vault) == msg.sender, "LP_AB: UNAUTHORIZED");

        creditAllowance[vault][msg.sender][beneficiary] = amount;

        emit CreditApproval(vault, msg.sender, beneficiary, amount);
    }

    /**
     * @notice Takes out a loan backed by collateral in an Arcadia Vault.
     * @param amount The amount of underlying ERC-20 tokens to be lent out.
     * @param vault The address of the Arcadia Vault backing the loan.
     * @param to The address who receives the lent out underlying tokens.
     * @param referrer A unique identifier of the referrer, who will receive part of the fees generated by this transaction.
     * @dev The sender might be different than the owner if they have the proper allowances.
     */
    function borrow(uint256 amount, address vault, address to, bytes3 referrer)
        external
        whenBorrowNotPaused
        processInterests
    {
        //If vault is not an actual address of a vault, ownerOfVault(address) will return the zero address.
        address vaultOwner = IFactory(vaultFactory).ownerOfVault(vault);
        require(vaultOwner != address(0), "LP_B: Not a vault");

        uint256 amountWithFee = amount + (amount * originationFee) / 10_000;

        //Check allowances to take debt.
        if (vaultOwner != msg.sender) {
            uint256 allowed = creditAllowance[vault][vaultOwner][msg.sender];
            if (allowed != type(uint256).max) {
                creditAllowance[vault][vaultOwner][msg.sender] = allowed - amountWithFee;
            }
        }

        //Mint debt tokens to the vault.
        _deposit(amountWithFee, vault);

        //Add origination fee to the treasury.
        unchecked {
            totalRealisedLiquidity += SafeCastLib.safeCastTo128(amountWithFee - amount);
            realisedLiquidityOf[treasury] += amountWithFee - amount;
        }

        //Call vault to check if it is still healthy after the debt is increased with amountWithFee.
        (bool isHealthy, address trustedCreditor, uint256 vaultVersion) =
            IVault(vault).isVaultHealthy(0, maxWithdraw(vault));
        require(isHealthy && trustedCreditor == address(this) && isValidVersion[vaultVersion], "LP_B: Reverted");

        //Transfer fails if there is insufficient liquidity in the pool.
        asset.safeTransfer(to, amount);

        emit Borrow(vault, msg.sender, to, amount, amountWithFee - amount, referrer);
    }

    /**
     * @notice Repays a loan.
     * @param amount The amount of underlying ERC-20 tokens to be repaid.
     * @param vault The address of the Arcadia Vault backing the loan.
     * @dev if Vault is not an actual address of a Vault, maxWithdraw(vault) will always return 0.
     * Function will not revert, but transferAmount is always 0.
     * @dev Anyone (EOAs and contracts) can repay debt in the name of a vault.
     */
    function repay(uint256 amount, address vault) external whenRepayNotPaused processInterests {
        uint256 vaultDebt = maxWithdraw(vault);
        uint256 transferAmount = vaultDebt > amount ? amount : vaultDebt;

        // Need to transfer before burning debt or ERC777s could reenter.
        // Address(this) is trusted -> no risk on re-entrancy attack after transfer.
        asset.safeTransferFrom(msg.sender, address(this), transferAmount);

        _withdraw(transferAmount, vault, vault);

        emit Repay(vault, msg.sender, transferAmount);
    }

    /* //////////////////////////////////////////////////////////////
                        LEVERAGED ACTIONS LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Execute and interact with external logic on leverage.
     * @param amountBorrowed The amount of underlying ERC-20 tokens to be lent out.
     * @param vault The address of the Arcadia Vault backing the loan.
     * @param actionHandler the address of the action handler to call.
     * @param actionData a bytes object containing two actionAssetData structs, an address array and a bytes array.
     * @param referrer A unique identifier of the referrer, who will receive part of the fees generated by this transaction.
     * @dev The sender might be different than the owner if they have the proper allowances.
     * @dev vaultManagementAction() works similar to flash loans, this function optimistically calls external logic and checks for the vault state at the very end.
     */
    function doActionWithLeverage(
        uint256 amountBorrowed,
        address vault,
        address actionHandler,
        bytes calldata actionData,
        bytes3 referrer
    ) external whenBorrowNotPaused processInterests {
        //If vault is not an actual address of a vault, ownerOfVault(address) will return the zero address.
        address vaultOwner = IFactory(vaultFactory).ownerOfVault(vault);
        require(vaultOwner != address(0), "LP_DAWL: Not a vault");

        uint256 amountBorrowedWithFee = amountBorrowed + (amountBorrowed * originationFee) / 10_000;

        //Check allowances to take debt.
        if (vaultOwner != msg.sender) {
            //Since calling vaultManagementAction() gives the sender full control over all assets in the vault,
            //Only Beneficiaries with maximum allowance can call the doActionWithLeverage function.
            require(creditAllowance[vault][vaultOwner][msg.sender] == type(uint256).max, "LP_DAWL: UNAUTHORIZED");
        }

        //Mint debt tokens to the vault, debt must be minted Before the actions in the vault are performed.
        _deposit(amountBorrowedWithFee, vault);

        //Add origination fee to the treasury.
        unchecked {
            totalRealisedLiquidity += SafeCastLib.safeCastTo128(amountBorrowedWithFee - amountBorrowed);
            realisedLiquidityOf[treasury] += amountBorrowedWithFee - amountBorrowed;
        }

        //Send Borrowed funds to the actionHandler.
        asset.safeTransfer(actionHandler, amountBorrowed);

        //The actionHandler will use the borrowed funds (optionally with additional assets withdrawn from the Vault)
        //to execute one or more actions (swap, deposit, mint...).
        //Next the actionHandler will deposit any of the remaining funds or any of the recipient token
        //resulting from the actions back into the vault.
        //As last step, after all assets are deposited back into the vault a final health check is done:
        //The Collateral Value of all assets in the vault is bigger than the total liabilities against the vault (including the margin taken during this function).
        (address trustedCreditor, uint256 vaultVersion) = IVault(vault).vaultManagementAction(actionHandler, actionData);
        require(trustedCreditor == address(this) && isValidVersion[vaultVersion], "LP_DAWL: Reverted");

        emit Borrow(vault, msg.sender, actionHandler, amountBorrowed, amountBorrowedWithFee - amountBorrowed, referrer);
    }

    /* //////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Returns the total amount of outstanding debt in the underlying asset.
     * @return totalDebt The total debt in underlying assets.
     */
    function totalAssets() public view override returns (uint256 totalDebt) {
        // Avoid a second calculation of unrealised debt (expensive)
        // if interests are already synced this block.
        if (lastSyncedTimestamp != uint32(block.timestamp)) {
            totalDebt = realisedDebt + calcUnrealisedDebt();
        } else {
            totalDebt = realisedDebt;
        }
    }

    /**
     * @notice Returns the redeemable amount of liquidity in the underlying asset of an address.
     * @param owner_ The address of the liquidity provider.
     * @return assets The redeemable amount of liquidity in the underlying asset.
     * @dev This function syncs the interests to prevent calculating UnrealisedDebt twice when depositing/withdrawing through the Tranches.
     * @dev After calling this function, the interest rate will not be updated until the next processInterests() call.
     */
    function liquidityOfAndSync(address owner_) external returns (uint256 assets) {
        _syncInterests();
        assets = realisedLiquidityOf[owner_];
    }

    /**
     * @notice Returns the redeemable amount of liquidity in the underlying asset of an address.
     * @param owner_ The address of the liquidity provider.
     * @return assets The redeemable amount of liquidity in the underlying asset.
     */
    function liquidityOf(address owner_) external view returns (uint256 assets) {
        // Avoid a second calculation of unrealised debt (expensive).
        // if interests are already synced this block.
        if (lastSyncedTimestamp != uint32(block.timestamp)) {
            // The total liquidity of a tranche equals the sum of the realised liquidity
            // of the tranche, and its pending interests.
            uint256 interest = calcUnrealisedDebt().mulDivUp(interestWeight[owner_], totalInterestWeight);
            unchecked {
                assets = realisedLiquidityOf[owner_] + interest;
            }
        } else {
            assets = realisedLiquidityOf[owner_];
        }
    }

    /**
     * @notice Skims any surplus funds in the LendingPool to the treasury.
     * @dev In normal conditions (when there are no ongoing auctions), the total Claimable Liquidity should be equal
     * to the sum of the available funds (the balanceOf() the underlying asset) in the pool and the total open debt.
     * In practice the actual sum of available funds and total open debt will always be bigger than the total Claimable Liquidity.
     * This because of the rounding errors of the ERC4626 calculations (conversions between assets and shares),
     * or because someone accidentally sent funds directly to the pool instead of depositing via a Tranche.
     * This functions makes the surplus available to the Treasury (otherwise they would be lost forever).
     * @dev In case you accidentally sent funds to the pool, contact the current treasury manager.
     */
    function skim() external processInterests {
        //During auctions, debt tokens are burned at start of the auction, while auctions proceeds are only returned
        //at the end of the auction -> skim function must be blocked during auctions.
        require(auctionsInProgress == 0, "LP_S: Auctions Ongoing");

        //Pending interests are synced via the processInterests modifier.
        uint256 delta = asset.balanceOf(address(this)) + realisedDebt - totalRealisedLiquidity;

        //Add difference to the treasury.
        unchecked {
            totalRealisedLiquidity += SafeCastLib.safeCastTo128(delta);
            realisedLiquidityOf[treasury] += delta;
        }
    }

    /* //////////////////////////////////////////////////////////////
                            INTERESTS LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Syncs all unrealised debt (= interest for LP and treasury).
     * @dev Calculates the unrealised debt since last sync, and realises it by minting an equal amount of
     * debt tokens to all debt holders and interests to LPs and the treasury.
     */
    function _syncInterests() internal {
        // Only Sync interests once per block.
        if (lastSyncedTimestamp != uint32(block.timestamp)) {
            uint256 unrealisedDebt = calcUnrealisedDebt();
            lastSyncedTimestamp = uint32(block.timestamp);

            //Sync interests for borrowers.
            unchecked {
                realisedDebt += unrealisedDebt;
            }

            //Sync interests for LPs and Protocol Treasury.
            _syncInterestsToLiquidityProviders(unrealisedDebt);
        }
    }

    /**
     * @notice Calculates the unrealised debt (interests).
     * @return unrealisedDebt The unrealised debt.
     * @dev To Find the unrealised debt over an amount of time, you need to calculate D[(1+r)^x-1].
     * The base of the exponential: 1 + r, is a 18 decimals fixed point number
     * with r the yearly interest rate.
     * The exponent of the exponential: x, is a 18 decimals fixed point number.
     * The exponent x is calculated as: the amount of seconds passed since last sync timestamp divided by the average of
     * seconds per year. _yearlyInterestRate = 1 + r expressed as 18 decimals fixed point number.
     */
    function calcUnrealisedDebt() public view returns (uint256 unrealisedDebt) {
        uint256 base;
        uint256 exponent;

        unchecked {
            //gas: Can't overflow for reasonable interest rates.
            base = 1e18 + interestRate;

            //gas: Only overflows when (block.timestamp - lastSyncedBlockTimestamp) > 1e59
            //in practice: exponent in LogExpMath lib is limited to 130e18,
            //Corresponding to a delta of timestamps of 4099680000 (or 130 years),
            //much bigger than any realistic time difference between two syncs.
            exponent = ((block.timestamp - lastSyncedTimestamp) * 1e18) / YEARLY_SECONDS;

            //gas: Taking an imaginary worst-case scenario with max interest of 1000%
            //over a period of 5 years.
            //This won't overflow as long as openDebt < 3402823669209384912995114146594816
            //which is 3.4 million billion *10**18 decimals.
            unrealisedDebt = (realisedDebt * (LogExpMath.pow(base, exponent) - 1e18)) / 1e18;
        }

        return SafeCastLib.safeCastTo128(unrealisedDebt);
    }

    /**
     * @notice Syncs interest payments to the Lending providers and the treasury.
     * @param assets The total amount of underlying assets to be paid out as interests.
     * @dev The interestWeight of each Tranche determines the relative share yield (interest payments) that goes to its Liquidity providers.
     */
    function _syncInterestsToLiquidityProviders(uint256 assets) internal {
        uint256 remainingAssets = assets;

        uint256 trancheShare;
        for (uint256 i; i < tranches.length;) {
            trancheShare = assets.mulDivDown(interestWeightTranches[i], totalInterestWeight);
            unchecked {
                realisedLiquidityOf[tranches[i]] += trancheShare;
                remainingAssets -= trancheShare;
                ++i;
            }
        }
        unchecked {
            totalRealisedLiquidity += SafeCastLib.safeCastTo128(assets);

            // Add the remainingAssets to the treasury balance.
            realisedLiquidityOf[treasury] += remainingAssets;
        }
    }

    /* //////////////////////////////////////////////////////////////
                        INTEREST RATE LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Set's the configuration parameters of InterestRateConfiguration struct.
     * @param newConfig New set of configuration parameters.
     */
    function setInterestConfig(InterestRateConfiguration calldata newConfig) external onlyOwner {
        _setInterestConfig(newConfig);
    }

    /**
     * @notice Updates the interest rate.
     * @dev Any address can call this, it will sync unrealised interests and update the interest rate.
     */
    function updateInterestRate() external processInterests { }

    /* //////////////////////////////////////////////////////////////
                        LIQUIDATION LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Sets the maxInitiatorFee.
     * @param maxInitiatorFee_ The maximum fee that is paid to the initiator of a liquidation.
     * @dev The liquidator sets the % of the debt that is paid to the initiator of a liquidation.
     * This fee is capped by the maxInitiatorFee.
     */
    function setMaxInitiatorFee(uint80 maxInitiatorFee_) external onlyOwner {
        maxInitiatorFee = maxInitiatorFee_;

        emit MaxInitiatorFeeSet(maxInitiatorFee_);
    }

    /**
     * @notice Sets the estimated max gas cost to liquidate a position, denominated in baseCurrency.
     * @param fixedLiquidationCost_ The new fixedLiquidationCost.
     * @dev Conservative estimate of the maximal gas cost to liquidate a position (fixed cost, independent of openDebt).
     * The fixedLiquidationCost prevents dusting attacks, and ensures that upon Liquidations positions are big enough to cover.
     * gas costs of the Liquidator without resulting in badDebt.
     */
    function setFixedLiquidationCost(uint96 fixedLiquidationCost_) external onlyOwner {
        fixedLiquidationCost = fixedLiquidationCost_;

        emit FixedLiquidationCostSet(fixedLiquidationCost_);
    }

    /**
     * @notice Starts liquidation of a Vault.
     * @param vault The vault address.
     * @dev At the start of the liquidation the debt tokens are burned,
     * as such interests are not accrued during the liquidation.
     */

    function liquidateVault(address vault) external whenLiquidationNotPaused processInterests {
        //Only Vaults can have debt, and debtTokens are non-transferrable.
        //Hence by checking that the balance of the address passed as vault is not 0, we know the address
        //passed as vault is indeed a vault and has debt.
        uint256 openDebt = maxWithdraw(vault);
        require(openDebt != 0, "LP_LV: Not a Vault with debt");

        //Store liquidation initiator to pay out initiator reward when auction is finished.
        liquidationInitiator[vault] = msg.sender;

        //Start the auction of the collateralised assets to repay debt.
        ILiquidator(liquidator).startAuction(vault, openDebt, maxInitiatorFee);

        //Hook to the most junior Tranche, to inform that auctions are ongoing,
        //already done if there are other auctions in progress (auctionsInProgress > O).
        if (auctionsInProgress == 0) {
            ITranche(tranches[tranches.length - 1]).setAuctionInProgress(true);
        }
        unchecked {
            ++auctionsInProgress;
        }

        //Remove debt from Vault (burn DebtTokens).
        _withdraw(openDebt, vault, vault);

        //Event emitted by Liquidator.
    }

    /**
     * @notice Settles the liquidation after the auction is finished and pays out Creditor, Original owner and Service providers.
     * @param vault The contract address of the vault.
     * @param originalOwner The original owner of the vault before the auction.
     * @param badDebt The amount of liabilities that was not recouped by the auction.
     * @param liquidationInitiatorReward The Reward for the Liquidation Initiator.
     * @param liquidationFee The additional fee the `originalOwner` has to pay to the protocol.
     * @param remainder Any funds remaining after the auction are returned back to the `originalOwner`.
     * @dev This function is called by the Liquidator after a liquidation is finished.
     * @dev The liquidator will transfer the auction proceeds (the underlying asset)
     * back to the liquidity pool after liquidation, before calling this function.
     */

    function settleLiquidation(
        address vault,
        address originalOwner,
        uint256 badDebt,
        uint256 liquidationInitiatorReward,
        uint256 liquidationFee,
        uint256 remainder
    ) external onlyLiquidator processInterests {
        //Make Initiator rewards claimable for liquidationInitiator[vault].
        realisedLiquidityOf[liquidationInitiator[vault]] += liquidationInitiatorReward;

        if (badDebt > 0) {
            //Collateral was auctioned for less than the liabilities (openDebt + Liquidation Initiator Reward)
            //-> Default event, deduct badDebt from LPs, starting with most Junior Tranche.
            totalRealisedLiquidity =
                SafeCastLib.safeCastTo128(uint256(totalRealisedLiquidity) + liquidationInitiatorReward - badDebt);
            _processDefault(badDebt);
        } else {
            //Collateral was auctioned for more than the liabilities
            //-> Pay out the Liquidation Fee to treasury and Tranches.
            _syncLiquidationFeeToLiquidityProviders(liquidationFee);
            totalRealisedLiquidity = SafeCastLib.safeCastTo128(
                uint256(totalRealisedLiquidity) + liquidationInitiatorReward + liquidationFee + remainder
            );

            //Any remaining assets after paying off liabilities and the fee go back to the original Vault Owner.
            if (remainder > 0) {
                //Make remainder claimable by originalOwner.
                realisedLiquidityOf[originalOwner] += remainder;
            }
        }

        unchecked {
            --auctionsInProgress;
        }
        //Hook to the most junior Tranche to inform that there are no ongoing auctions.
        if (auctionsInProgress == 0 && tranches.length > 0) {
            ITranche(tranches[tranches.length - 1]).setAuctionInProgress(false);
        }

        //Event emitted by Liquidator.
    }

    /**
     * @notice Handles the bookkeeping in case of bad debt (Vault became undercollateralised).
     * @param badDebt The total amount of underlying assets that need to be written off as bad debt.
     * @dev The order of the Tranches is important, the most senior tranche is at index 0, the most junior at the last index.
     * @dev The most junior tranche will lose its underlying assets first. If all liquidity of a certain Tranche is written off,
     * the complete tranche is locked and removed. If there is still remaining bad debt, the next Tranche starts losing capital.
     */
    function _processDefault(uint256 badDebt) internal {
        address tranche;
        uint256 maxBurnable;
        for (uint256 i = tranches.length; i > 0;) {
            unchecked {
                --i;
            }
            tranche = tranches[i];
            maxBurnable = realisedLiquidityOf[tranche];
            if (badDebt < maxBurnable) {
                //Deduct badDebt from the balance of the most junior Tranche.
                unchecked {
                    realisedLiquidityOf[tranche] -= badDebt;
                }
                break;
            } else {
                //Unhappy flow, should never occur in practice!
                //badDebt is bigger than balance most junior Tranche -> tranche is completely wiped out
                //and temporarily locked (no new deposits or withdraws possible).
                //DAO or insurance might refund (Part of) the losses, and add Tranche back.
                realisedLiquidityOf[tranche] = 0;
                _popTranche(i, tranche);
                unchecked {
                    badDebt -= maxBurnable;
                }
                ITranche(tranche).lock();
                //Hook to the new most junior Tranche to inform that auctions are ongoing.
                if (i != 0) ITranche(tranches[i - 1]).setAuctionInProgress(true);
            }
        }
    }

    /**
     * @notice Syncs liquidation penalties to the Lending providers and the treasury.
     * @param assets The total amount of underlying assets to be paid out as liquidation fee.
     * @dev The liquidationWeight of each Tranche determines the relative share yield (interest payments) that goes to its Liquidity providers.
     */
    function _syncLiquidationFeeToLiquidityProviders(uint256 assets) internal {
        uint256 remainingAssets = assets;

        uint256 trancheShare;
        uint256 weightOfTranche;
        for (uint256 i; i < tranches.length;) {
            weightOfTranche = liquidationWeightTranches[i];

            if (weightOfTranche != 0) {
                //skip if weight is zero, which is the case for Sr tranche.
                trancheShare = assets.mulDivDown(weightOfTranche, totalLiquidationWeight);
                unchecked {
                    realisedLiquidityOf[tranches[i]] += trancheShare;
                    remainingAssets -= trancheShare;
                }
            }

            unchecked {
                ++i;
            }
        }

        unchecked {
            // Add the remainingAssets to the treasury balance.
            realisedLiquidityOf[treasury] += remainingAssets;
        }
    }

    /* //////////////////////////////////////////////////////////////
                            VAULT LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Enables or disables a certain Vault version to be used as margin account.
     * @param vaultVersion The Vault version to be enabled/disabled.
     * @param valid The validity of the respective vaultVersion.
     */
    function setVaultVersion(uint256 vaultVersion, bool valid) external onlyOwner {
        _setVaultVersion(vaultVersion, valid);

        emit VaultVersionSet(vaultVersion, valid);
    }

    /**
     * @inheritdoc TrustedCreditor
     */
    function openMarginAccount(uint256 vaultVersion)
        external
        view
        override
        returns (bool success, address baseCurrency, address liquidator_, uint256 fixedLiquidationCost_)
    {
        if (isValidVersion[vaultVersion]) {
            success = true;
            baseCurrency = address(asset);
            liquidator_ = liquidator;
            fixedLiquidationCost_ = fixedLiquidationCost;
        }
    }

    /**
     * @inheritdoc TrustedCreditor
     */
    function getOpenPosition(address vault) external view override returns (uint256 openPosition) {
        openPosition = maxWithdraw(vault);
    }
}

/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity ^0.8.13;

/**
 * @title Trusted Creditor implementation.
 * @author Pragma Labs
 * @notice This contract contains the minimum functionality a Trusted Creditor, interacting with Arcadia Vaults, needs to implement.
 * @dev For the implementation of Arcadia Vaults, see: https://github.com/arcadia-finance/arcadia-vaults.
 */
abstract contract TrustedCreditor {
    /* //////////////////////////////////////////////////////////////
                                STORAGE
    ////////////////////////////////////////////////////////////// */

    // Map vaultVersion => status.
    mapping(uint256 => bool) public isValidVersion;

    /* //////////////////////////////////////////////////////////////
                            VAULT LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Sets the validity of vault version to valid.
     * @param vaultVersion The version current version of the vault.
     * @param valid The validity of the respective vaultVersion.
     */
    function _setVaultVersion(uint256 vaultVersion, bool valid) internal {
        isValidVersion[vaultVersion] = valid;
    }

    /**
     * @notice Checks if vault fulfills all requirements and returns application settings.
     * @param vaultVersion The current version of the vault.
     * @return success Bool indicating if all requirements are met.
     * @return baseCurrency The base currency of the application.
     * @return liquidator The liquidator of the application.
     * @return fixedLiquidationCost Estimated fixed costs (independent of size of debt) to liquidate a position.
     */
    function openMarginAccount(uint256 vaultVersion)
        external
        virtual
        returns (bool success, address baseCurrency, address liquidator, uint256 fixedLiquidationCost);

    /**
     * @notice Returns the open position of the vault.
     * @param vault The vault address.
     * @return openPosition The open position of the vault.
     */
    function getOpenPosition(address vault) external view virtual returns (uint256 openPosition);
}

/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.13;

interface IFactory {
    /**
     * @notice View function returning if an address is a vault.
     * @param vault The address to be checked.
     * @return bool Whether the address is a vault or not.
     */
    function isVault(address vault) external view returns (bool);

    /**
     * @notice Returns the owner of a vault.
     * @param vault The Vault address.
     * @return owner The Vault owner.
     */
    function ownerOfVault(address vault) external view returns (address);
}

/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.13;

import { ERC20 } from "../../lib/solmate/src/tokens/ERC20.sol";

interface ILendingPool {
    /**
     * @notice returns the supply cap of the Lending Pool.
     * @return supplyCap The supply cap of the Lending Pool.
     */
    function supplyCap() external view returns (uint128);

    /**
     * @notice returns the total realised liquidity of the Lending Pool.
     * @return totalRealisedLiquidity The total realised liquidity of the Lending Pool.
     */
    function totalRealisedLiquidity() external view returns (uint128);

    /**
     * @notice Deposit assets in the Lending Pool.
     * @param assets The amount of assets of the underlying ERC-20 token being deposited.
     * @param from The address of the Liquidity Provider who deposits the underlying ERC-20 token via a Tranche.
     */
    function depositInLendingPool(uint256 assets, address from) external;

    /**
     * @notice Withdraw assets from the Lending Pool.
     * @param assets The amount of assets of the underlying ERC-20 tokens being withdrawn.
     * @param receiver The address of the receiver of the underlying ERC-20 tokens.
     */
    function withdrawFromLendingPool(uint256 assets, address receiver) external;

    /**
     * @notice Returns the redeemable amount of liquidity in the underlying asset of an address.
     * @param owner The address of the liquidity provider.
     * @return assets The redeemable amount of liquidity in the underlying asset.
     */
    function liquidityOf(address owner) external view returns (uint256);

    /**
     * @notice liquidityOf, but syncs the unrealised interest first.
     * @param owner The address of the liquidity provider.
     * @return assets The redeemable amount of liquidity in the underlying asset.
     */
    function liquidityOfAndSync(address owner) external returns (uint256);

    /**
     * @notice Calculates the unrealised debt (interests).
     * @return unrealisedDebt The unrealised debt.
     */
    function calcUnrealisedDebt() external view returns (uint256);
}

/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.13;

interface ILiquidator {
    /**
     * @notice Called by a Creditor to start an auction to liquidate collateral of a vault.
     * @param vault The contract address of the Vault to liquidate.
     * @param openDebt The open debt taken by `originalOwner`.
     * @param maxInitiatorFee The maximum fee that is paid to the initiator of a liquidation.
     */
    function startAuction(address vault, uint256 openDebt, uint80 maxInitiatorFee) external;
}

/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.13;

interface ITranche {
    /**
     * @notice Locks the tranche in case all liquidity of the tranche is written of due to bad debt.
     */
    function lock() external;

    /**
     * @notice Locks the tranche while an auction is in progress.
     * @param auctionInProgress Flag indicating if there are auctions in progress.
     */
    function setAuctionInProgress(bool auctionInProgress) external;
}

/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.13;

interface IVault {
    /**
     * @notice Returns the address of the owner of the Vault.
     */
    function owner() external view returns (address);

    /**
     * @notice Checks if the Vault is healthy and still has free margin.
     * @param amount The amount with which the position is increased.
     * @param totalOpenDebt The total open Debt against the Vault.
     * @return success Boolean indicating if there is sufficient margin to back a certain amount of Debt.
     * @return trustedCreditor_ The contract address of the trusted creditor.
     * @return vaultVersion_ The vault version.
     * @dev Only one of the values can be non-zero, or we check on a certain increase of debt, or we check on a total amount of debt.
     */
    function isVaultHealthy(uint256 amount, uint256 totalOpenDebt) external view returns (bool, address, uint256);

    /**
     * @notice Calls external action handler to execute and interact with external logic.
     * @param actionHandler The address of the action handler.
     * @param actionData A bytes object containing two actionAssetData structs, an address array and a bytes array.
     * @return trustedCreditor_ The contract address of the trusted creditor.
     * @return vaultVersion_ The vault version.
     */
    function vaultManagementAction(address actionHandler, bytes calldata actionData)
        external
        returns (address, uint256);
}

/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */

pragma solidity ^0.8.13;

import { Owned } from "../../lib/solmate/src/auth/Owned.sol";

/**
 * @title Guardian
 * @author Pragma Labs
 * @notice This module provides the logic that allows authorized accounts to trigger an emergency stop.
 */
abstract contract Guardian is Owned {
    /* //////////////////////////////////////////////////////////////
                                STORAGE
    ////////////////////////////////////////////////////////////// */

    // Address of the Guardian.
    address public guardian;
    // Flag indicating if the repay() function is paused.
    bool public repayPaused;
    // Flag indicating if the withdraw() function is paused.
    bool public withdrawPaused;
    // Flag indicating if the borrow() function is paused.
    bool public borrowPaused;
    // Flag indicating if the deposit() function is paused.
    bool public depositPaused;
    // Flag indicating if the liquidation() function is paused.
    bool public liquidationPaused;
    // Last timestamp an emergency stop was triggered.
    uint256 public pauseTimestamp;

    /* //////////////////////////////////////////////////////////////
                                EVENTS
    ////////////////////////////////////////////////////////////// */

    event GuardianChanged(address indexed oldGuardian, address indexed newGuardian);
    event PauseUpdate(
        bool repayPauseUpdate,
        bool withdrawPauseUpdate,
        bool borrowPauseUpdate,
        bool supplyPauseUpdate,
        bool liquidationPauseUpdate
    );

    /* //////////////////////////////////////////////////////////////
                                ERRORS
    ////////////////////////////////////////////////////////////// */

    error FunctionIsPaused();

    /* //////////////////////////////////////////////////////////////
                                MODIFIERS
    ////////////////////////////////////////////////////////////// */

    /**
     * @dev Throws if called by any account other than the guardian.
     */
    modifier onlyGuardian() {
        require(msg.sender == guardian, "Guardian: Only guardian");
        _;
    }

    /**
     * @dev This modifier is used to restrict access to certain functions when the contract is paused for repay.
     * It throws if repay is paused.
     */
    modifier whenRepayNotPaused() {
        if (repayPaused) revert FunctionIsPaused();
        _;
    }

    /**
     * @dev This modifier is used to restrict access to certain functions when the contract is paused for withdraw.
     * It throws if withdraw is paused.
     */
    modifier whenWithdrawNotPaused() {
        if (withdrawPaused) revert FunctionIsPaused();
        _;
    }

    /**
     * @dev This modifier is used to restrict access to certain functions when the contract is paused for borrow.
     * It throws if borrow is paused.
     */
    modifier whenBorrowNotPaused() {
        if (borrowPaused) revert FunctionIsPaused();
        _;
    }

    /**
     * @dev This modifier is used to restrict access to certain functions when the contract is paused for deposit.
     * It throws if deposit is paused.
     */
    modifier whenDepositNotPaused() {
        if (depositPaused) revert FunctionIsPaused();
        _;
    }

    /**
     * @dev This modifier is used to restrict access to certain functions when the contract is paused for liquidation.
     * It throws if liquidation is paused.
     */
    modifier whenLiquidationNotPaused() {
        if (liquidationPaused) revert FunctionIsPaused();
        _;
    }

    /* //////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    ////////////////////////////////////////////////////////////// */

    constructor() Owned(msg.sender) { }

    /* //////////////////////////////////////////////////////////////
                            GUARDIAN LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice This function is used to set the guardian address.
     * @param guardian_ The address of the new guardian.
     * @dev Allows onlyOwner to change the guardian address.
     */
    function changeGuardian(address guardian_) external onlyOwner {
        emit GuardianChanged(guardian, guardian_);

        guardian = guardian_;
    }

    /* //////////////////////////////////////////////////////////////
                            PAUSING LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice This function is used to pause all the flags of the contract.
     * @dev This function can be called by the guardian to pause all functionality in the event of an emergency.
     * This function pauses repay, withdraw, borrow, deposit and liquidation.
     * This function can only be called by the guardian.
     * The guardian can only pause the protocol again after 32 days have past since the last pause.
     * This is to prevent that a malicious guardian can take user-funds hostage for an indefinite time.
     * @dev After the guardian has paused the protocol, the owner has 30 days to find potential problems,
     * find a solution and unpause the protocol. If the protocol is not unpaused after 30 days,
     * an emergency procedure can be started by any user to unpause the protocol.
     * All users have now at least a two-day window to withdraw assets and close positions before
     * the protocol can again be paused (after 32 days).
     */
    function pause() external onlyGuardian {
        require(block.timestamp > pauseTimestamp + 32 days, "G_P: Cannot pause");
        repayPaused = true;
        withdrawPaused = true;
        borrowPaused = true;
        depositPaused = true;
        liquidationPaused = true;
        pauseTimestamp = block.timestamp;

        emit PauseUpdate(true, true, true, true, true);
    }

    /**
     * @notice This function is used to unpause one or more flags.
     * @param repayPaused_ false when repay functionality should be unPaused.
     * @param withdrawPaused_ false when withdraw functionality should be unPaused.
     * @param borrowPaused_ false when borrow functionality should be unPaused.
     * @param depositPaused_ false when deposit functionality should be unPaused.
     * @param liquidationPaused_ false when liquidation functionality should be unPaused.
     * @dev This function can unPause repay, withdraw, borrow, and deposit individually.
     * @dev Can only update flags from paused (true) to unPaused (false), cannot be used the other way around
     * (to set unPaused flags to paused).
     */
    function unPause(
        bool repayPaused_,
        bool withdrawPaused_,
        bool borrowPaused_,
        bool depositPaused_,
        bool liquidationPaused_
    ) external onlyOwner {
        repayPaused = repayPaused && repayPaused_;
        withdrawPaused = withdrawPaused && withdrawPaused_;
        borrowPaused = borrowPaused && borrowPaused_;
        depositPaused = depositPaused && depositPaused_;
        liquidationPaused = liquidationPaused && liquidationPaused_;

        emit PauseUpdate(repayPaused, withdrawPaused, borrowPaused, depositPaused, liquidationPaused);
    }

    /**
     * @notice This function is used to unPause all flags.
     * @dev If the protocol is not unpaused after 30 days, any user can unpause the protocol.
     * This ensures that no rogue owner or guardian can lock user funds for an indefinite amount of time.
     * All users have now at least a two-day window to withdraw assets and close positions before
     * the protocol can again be paused (after 32 days).
     */
    function unPause() external {
        require(block.timestamp > pauseTimestamp + 30 days, "G_UP: Cannot unPause");
        if (repayPaused || withdrawPaused || borrowPaused || depositPaused || liquidationPaused) {
            repayPaused = false;
            withdrawPaused = false;
            borrowPaused = false;
            depositPaused = false;
            liquidationPaused = false;

            emit PauseUpdate(false, false, false, false, false);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.13;

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) {
        _revert(errorCode);
    }
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "BAL#" part is a known constant
        // (0x42414c23): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(200, add(0x42414c23000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // Math
    uint256 internal constant ADD_OVERFLOW = 0;
    uint256 internal constant SUB_OVERFLOW = 1;
    uint256 internal constant SUB_UNDERFLOW = 2;
    uint256 internal constant MUL_OVERFLOW = 3;
    uint256 internal constant ZERO_DIVISION = 4;
    uint256 internal constant DIV_INTERNAL = 5;
    uint256 internal constant X_OUT_OF_BOUNDS = 6;
    uint256 internal constant Y_OUT_OF_BOUNDS = 7;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
    uint256 internal constant INVALID_EXPONENT = 9;

    // Input
    uint256 internal constant OUT_OF_BOUNDS = 100;
    uint256 internal constant UNSORTED_ARRAY = 101;
    uint256 internal constant UNSORTED_TOKENS = 102;
    uint256 internal constant INPUT_LENGTH_MISMATCH = 103;
    uint256 internal constant ZERO_TOKEN = 104;

    // Shared pools
    uint256 internal constant MIN_TOKENS = 200;
    uint256 internal constant MAX_TOKENS = 201;
    uint256 internal constant MAX_SWAP_FEE_PERCENTAGE = 202;
    uint256 internal constant MIN_SWAP_FEE_PERCENTAGE = 203;
    uint256 internal constant MINIMUM_BPT = 204;
    uint256 internal constant CALLER_NOT_VAULT = 205;
    uint256 internal constant UNINITIALIZED = 206;
    uint256 internal constant BPT_IN_MAX_AMOUNT = 207;
    uint256 internal constant BPT_OUT_MIN_AMOUNT = 208;
    uint256 internal constant EXPIRED_PERMIT = 209;

    // Pools
    uint256 internal constant MIN_AMP = 300;
    uint256 internal constant MAX_AMP = 301;
    uint256 internal constant MIN_WEIGHT = 302;
    uint256 internal constant MAX_STABLE_TOKENS = 303;
    uint256 internal constant MAX_IN_RATIO = 304;
    uint256 internal constant MAX_OUT_RATIO = 305;
    uint256 internal constant MIN_BPT_IN_FOR_TOKEN_OUT = 306;
    uint256 internal constant MAX_OUT_BPT_FOR_TOKEN_IN = 307;
    uint256 internal constant NORMALIZED_WEIGHT_INVARIANT = 308;
    uint256 internal constant INVALID_TOKEN = 309;
    uint256 internal constant UNHANDLED_JOIN_KIND = 310;
    uint256 internal constant ZERO_INVARIANT = 311;
    uint256 internal constant ORACLE_INVALID_SECONDS_QUERY = 312;
    uint256 internal constant ORACLE_NOT_INITIALIZED = 313;
    uint256 internal constant ORACLE_QUERY_TOO_OLD = 314;
    uint256 internal constant ORACLE_INVALID_INDEX = 315;
    uint256 internal constant ORACLE_BAD_SECS = 316;

    // Lib
    uint256 internal constant REENTRANCY = 400;
    uint256 internal constant SENDER_NOT_ALLOWED = 401;
    uint256 internal constant PAUSED = 402;
    uint256 internal constant PAUSE_WINDOW_EXPIRED = 403;
    uint256 internal constant MAX_PAUSE_WINDOW_DURATION = 404;
    uint256 internal constant MAX_BUFFER_PERIOD_DURATION = 405;
    uint256 internal constant INSUFFICIENT_BALANCE = 406;
    uint256 internal constant INSUFFICIENT_ALLOWANCE = 407;
    uint256 internal constant ERC20_TRANSFER_FROM_ZERO_ADDRESS = 408;
    uint256 internal constant ERC20_TRANSFER_TO_ZERO_ADDRESS = 409;
    uint256 internal constant ERC20_MINT_TO_ZERO_ADDRESS = 410;
    uint256 internal constant ERC20_BURN_FROM_ZERO_ADDRESS = 411;
    uint256 internal constant ERC20_APPROVE_FROM_ZERO_ADDRESS = 412;
    uint256 internal constant ERC20_APPROVE_TO_ZERO_ADDRESS = 413;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_ALLOWANCE = 414;
    uint256 internal constant ERC20_DECREASED_ALLOWANCE_BELOW_ZERO = 415;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_BALANCE = 416;
    uint256 internal constant ERC20_BURN_EXCEEDS_ALLOWANCE = 417;
    uint256 internal constant SAFE_ERC20_CALL_FAILED = 418;
    uint256 internal constant ADDRESS_INSUFFICIENT_BALANCE = 419;
    uint256 internal constant ADDRESS_CANNOT_SEND_VALUE = 420;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_INT256 = 421;
    uint256 internal constant GRANT_SENDER_NOT_ADMIN = 422;
    uint256 internal constant REVOKE_SENDER_NOT_ADMIN = 423;
    uint256 internal constant RENOUNCE_SENDER_NOT_ALLOWED = 424;
    uint256 internal constant BUFFER_PERIOD_EXPIRED = 425;

    // Vault
    uint256 internal constant INVALID_POOL_ID = 500;
    uint256 internal constant CALLER_NOT_POOL = 501;
    uint256 internal constant SENDER_NOT_ASSET_MANAGER = 502;
    uint256 internal constant USER_DOESNT_ALLOW_RELAYER = 503;
    uint256 internal constant INVALID_SIGNATURE = 504;
    uint256 internal constant EXIT_BELOW_MIN = 505;
    uint256 internal constant JOIN_ABOVE_MAX = 506;
    uint256 internal constant SWAP_LIMIT = 507;
    uint256 internal constant SWAP_DEADLINE = 508;
    uint256 internal constant CANNOT_SWAP_SAME_TOKEN = 509;
    uint256 internal constant UNKNOWN_AMOUNT_IN_FIRST_SWAP = 510;
    uint256 internal constant MALCONSTRUCTED_MULTIHOP_SWAP = 511;
    uint256 internal constant INTERNAL_BALANCE_OVERFLOW = 512;
    uint256 internal constant INSUFFICIENT_INTERNAL_BALANCE = 513;
    uint256 internal constant INVALID_ETH_INTERNAL_BALANCE = 514;
    uint256 internal constant INVALID_POST_LOAN_BALANCE = 515;
    uint256 internal constant INSUFFICIENT_ETH = 516;
    uint256 internal constant UNALLOCATED_ETH = 517;
    uint256 internal constant ETH_TRANSFER = 518;
    uint256 internal constant CANNOT_USE_ETH_SENTINEL = 519;
    uint256 internal constant TOKENS_MISMATCH = 520;
    uint256 internal constant TOKEN_NOT_REGISTERED = 521;
    uint256 internal constant TOKEN_ALREADY_REGISTERED = 522;
    uint256 internal constant TOKENS_ALREADY_SET = 523;
    uint256 internal constant TOKENS_LENGTH_MUST_BE_2 = 524;
    uint256 internal constant NONZERO_TOKEN_BALANCE = 525;
    uint256 internal constant BALANCE_TOTAL_OVERFLOW = 526;
    uint256 internal constant POOL_NO_TOKENS = 527;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_BALANCE = 528;

    // Fees
    uint256 internal constant SWAP_FEE_PERCENTAGE_TOO_HIGH = 600;
    uint256 internal constant FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH = 601;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT = 602;
}

// SPDX-License-Identifier: MIT
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the “Software”), to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity ^0.8.13;

import "./BalancerErrors.sol";

/* solhint-disable */

/**
 * @dev Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
 *
 * Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural
 * exponentiation and logarithm (where the base is Euler's number).
 *
 * @author Fernando Martinelli - @fernandomartinelli
 * @author Sergio Yuhjtman - @sergioyuhjtman
 * @author Daniel Fernandez - @dmf7z
 */
library LogExpMath {
    // All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
    // two numbers, and multiply by ONE when dividing them.

    // All arguments and return values are 18 decimal fixed point numbers.
    int256 constant ONE_18 = 1e18;

    // Internally, intermediate values are computed with higher precision as 20 decimal fixed point numbers, and in the
    // case of ln36, 36 decimals.
    int256 constant ONE_20 = 1e20;
    int256 constant ONE_36 = 1e36;

    // The domain of natural exponentiation is bound by the word size and number of decimals used.
    //
    // Because internally the result will be stored using 20 decimals, the largest possible result is
    // (2^255 - 1) / 10^20, which makes the largest exponent ln((2^255 - 1) / 10^20) = 130.700829182905140221.
    // The smallest possible result is 10^(-18), which makes largest negative argument
    // ln(10^(-18)) = -41.446531673892822312.
    // We use 130.0 and -41.0 to have some safety margin.
    int256 constant MAX_NATURAL_EXPONENT = 130e18;
    int256 constant MIN_NATURAL_EXPONENT = -41e18;

    // Bounds for ln_36's argument. Both ln(0.9) and ln(1.1) can be represented with 36 decimal places in a fixed point
    // 256 bit integer.
    int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
    int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

    uint256 constant MILD_EXPONENT_BOUND = 2 ** 254 / uint256(ONE_20);

    // 18 decimal constants
    int256 constant x0 = 128_000_000_000_000_000_000; // 2ˆ7
    int256 constant a0 = 38_877_084_059_945_950_922_200_000_000_000_000_000_000_000_000_000_000_000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64_000_000_000_000_000_000; // 2ˆ6
    int256 constant a1 = 6_235_149_080_811_616_882_910_000_000; // eˆ(x1) (no decimals)

    // 20 decimal constants
    int256 constant x2 = 3_200_000_000_000_000_000_000; // 2ˆ5
    int256 constant a2 = 7_896_296_018_268_069_516_100_000_000_000_000; // eˆ(x2)
    int256 constant x3 = 1_600_000_000_000_000_000_000; // 2ˆ4
    int256 constant a3 = 888_611_052_050_787_263_676_000_000; // eˆ(x3)
    int256 constant x4 = 800_000_000_000_000_000_000; // 2ˆ3
    int256 constant a4 = 298_095_798_704_172_827_474_000; // eˆ(x4)
    int256 constant x5 = 400_000_000_000_000_000_000; // 2ˆ2
    int256 constant a5 = 5_459_815_003_314_423_907_810; // eˆ(x5)
    int256 constant x6 = 200_000_000_000_000_000_000; // 2ˆ1
    int256 constant a6 = 738_905_609_893_065_022_723; // eˆ(x6)
    int256 constant x7 = 100_000_000_000_000_000_000; // 2ˆ0
    int256 constant a7 = 271_828_182_845_904_523_536; // eˆ(x7)
    int256 constant x8 = 50_000_000_000_000_000_000; // 2ˆ-1
    int256 constant a8 = 164_872_127_070_012_814_685; // eˆ(x8)
    int256 constant x9 = 25_000_000_000_000_000_000; // 2ˆ-2
    int256 constant a9 = 128_402_541_668_774_148_407; // eˆ(x9)
    int256 constant x10 = 12_500_000_000_000_000_000; // 2ˆ-3
    int256 constant a10 = 113_314_845_306_682_631_683; // eˆ(x10)
    int256 constant x11 = 6_250_000_000_000_000_000; // 2ˆ-4
    int256 constant a11 = 106_449_445_891_785_942_956; // eˆ(x11)

    /**
     * @dev Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
     *
     * Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) {
            // We solve the 0^0 indetermination by making it equal one.
            return uint256(ONE_18);
        }

        if (x == 0) {
            return 0;
        }

        // Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
        // arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
        // x^y = exp(y * ln(x)).

        // The ln function takes a signed value, so we need to make sure x fits in the signed 256 bit range.
        _require(x < 2 ** 255, Errors.X_OUT_OF_BOUNDS);
        int256 x_int256 = int256(x);

        // We will compute y * ln(x) in a single step. Depending on the value of x, we can either use ln or ln_36. In
        // both cases, we leave the division by ONE_18 (due to fixed point multiplication) to the end.

        // This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 256 bit range.
        _require(y < MILD_EXPONENT_BOUND, Errors.Y_OUT_OF_BOUNDS);
        int256 y_int256 = int256(y);

        int256 logx_times_y;
        if (LN_36_LOWER_BOUND < x_int256 && x_int256 < LN_36_UPPER_BOUND) {
            int256 ln_36_x = _ln_36(x_int256);

            // ln_36_x has 36 decimal places, so multiplying by y_int256 isn't as straightforward, since we can't just
            // bring y_int256 to 36 decimal places, as it might overflow. Instead, we perform two 18 decimal
            // multiplications and add the results: one with the first 18 decimals of ln_36_x, and one with the
            // (downscaled) last 18 decimals.
            logx_times_y = ((ln_36_x / ONE_18) * y_int256 + ((ln_36_x % ONE_18) * y_int256) / ONE_18);
        } else {
            logx_times_y = _ln(x_int256) * y_int256;
        }
        logx_times_y /= ONE_18;

        // Finally, we compute exp(y * ln(x)) to arrive at x^y
        _require(
            MIN_NATURAL_EXPONENT <= logx_times_y && logx_times_y <= MAX_NATURAL_EXPONENT, Errors.PRODUCT_OUT_OF_BOUNDS
        );

        return uint256(exp(logx_times_y));
    }

    /**
     * @dev Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
     *
     * Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function exp(int256 x) internal pure returns (int256) {
        _require(x >= MIN_NATURAL_EXPONENT && x <= MAX_NATURAL_EXPONENT, Errors.INVALID_EXPONENT);

        if (x < 0) {
            // We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
            // fits in the signed 256 bit range (as it is larger than MIN_NATURAL_EXPONENT).
            // Fixed point division requires multiplying by ONE_18.
            return ((ONE_18 * ONE_18) / exp(-x));
        }

        // First, we use the fact that e^(x+y) = e^x * e^y to decompose x into a sum of powers of two, which we call x_n,
        // where x_n == 2^(7 - n), and e^x_n = a_n has been precomputed. We choose the first x_n, x0, to equal 2^7
        // because all larger powers are larger than MAX_NATURAL_EXPONENT, and therefore not present in the
        // decomposition.
        // At the end of this process we will have the product of all e^x_n = a_n that apply, and the remainder of this
        // decomposition, which will be lower than the smallest x_n.
        // exp(x) = k_0 * a_0 * k_1 * a_1 * ... + k_n * a_n * exp(remainder), where each k_n equals either 0 or 1.
        // We mutate x by subtracting x_n, making it the remainder of the decomposition.

        // The first two a_n (e^(2^7) and e^(2^6)) are too large if stored as 18 decimal numbers, and could cause
        // intermediate overflows. Instead we store them as plain integers, with 0 decimals.
        // Additionally, x0 + x1 is larger than MAX_NATURAL_EXPONENT, which means they will not both be present in the
        // decomposition.

        // For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
        // it and compute the accumulated product.

        int256 firstAN;
        if (x >= x0) {
            x -= x0;
            firstAN = a0;
        } else if (x >= x1) {
            x -= x1;
            firstAN = a1;
        } else {
            firstAN = 1; // One with no decimal places
        }

        // We now transform x into a 20 decimal fixed point number, to have enhanced precision when computing the
        // smaller terms.
        x *= 100;

        // `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed point
        // one. Recall that fixed point multiplication requires dividing by ONE_20.
        int256 product = ONE_20;

        if (x >= x2) {
            x -= x2;
            product = (product * a2) / ONE_20;
        }
        if (x >= x3) {
            x -= x3;
            product = (product * a3) / ONE_20;
        }
        if (x >= x4) {
            x -= x4;
            product = (product * a4) / ONE_20;
        }
        if (x >= x5) {
            x -= x5;
            product = (product * a5) / ONE_20;
        }
        if (x >= x6) {
            x -= x6;
            product = (product * a6) / ONE_20;
        }
        if (x >= x7) {
            x -= x7;
            product = (product * a7) / ONE_20;
        }
        if (x >= x8) {
            x -= x8;
            product = (product * a8) / ONE_20;
        }
        if (x >= x9) {
            x -= x9;
            product = (product * a9) / ONE_20;
        }

        // x10 and x11 are unnecessary here since we have high enough precision already.

        // Now we need to compute e^x, where x is small (in particular, it is smaller than x9). We use the Taylor series
        // expansion for e^x: 1 + x + (x^2 / 2!) + (x^3 / 3!) + ... + (x^n / n!).

        int256 seriesSum = ONE_20; // The initial one in the sum, with 20 decimal places.
        int256 term; // Each term in the sum, where the nth term is (x^n / n!).

        // The first term is simply x.
        term = x;
        seriesSum += term;

        // Each term (x^n / n!) equals the previous one times x, divided by n. Since x is a fixed point number,
        // multiplying by it requires dividing by ONE_20, but dividing by the non-fixed point n values does not.

        term = ((term * x) / ONE_20) / 2;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 3;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 4;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 5;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 6;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 7;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 8;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 9;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 10;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 11;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 12;
        seriesSum += term;

        // 12 Taylor terms are sufficient for 18 decimal precision.

        // We now have the first a_n (with no decimals), and the product of all other a_n present, and the Taylor
        // approximation of the exponentiation of the remainder (both with 20 decimals). All that remains is to multiply
        // all three (one 20 decimal fixed point multiplication, dividing by ONE_20, and one integer multiplication),
        // and then drop two digits to return an 18 decimal value.

        return (((product * seriesSum) / ONE_20) * firstAN) / 100;
    }

    /**
     * @dev Internal natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function _ln(int256 a) private pure returns (int256) {
        if (a < ONE_18) {
            // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
            // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive call.
            // Fixed point division requires multiplying by ONE_18.
            return (-_ln((ONE_18 * ONE_18) / a));
        }

        // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two, which
        // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that is,
        // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers cannot
        // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
        // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of this
        // decomposition, which will be lower than the smallest a_n.
        // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
        // We mutate a by subtracting a_n, making it the remainder of the decomposition.

        // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed point
        // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
        // ONE_18 to convert them to fixed point.
        // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so divide
        // by it and compute the accumulated sum.

        int256 sum = 0;
        if (a >= a0 * ONE_18) {
            a /= a0; // Integer, not fixed point division
            sum += x0;
        }

        if (a >= a1 * ONE_18) {
            a /= a1; // Integer, not fixed point division
            sum += x1;
        }

        // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this format.
        sum *= 100;
        a *= 100;

        // Because further a_n are  20 digit fixed point numbers, we multiply by ONE_20 when dividing by them.

        if (a >= a2) {
            a = (a * ONE_20) / a2;
            sum += x2;
        }

        if (a >= a3) {
            a = (a * ONE_20) / a3;
            sum += x3;
        }

        if (a >= a4) {
            a = (a * ONE_20) / a4;
            sum += x4;
        }

        if (a >= a5) {
            a = (a * ONE_20) / a5;
            sum += x5;
        }

        if (a >= a6) {
            a = (a * ONE_20) / a6;
            sum += x6;
        }

        if (a >= a7) {
            a = (a * ONE_20) / a7;
            sum += x7;
        }

        if (a >= a8) {
            a = (a * ONE_20) / a8;
            sum += x8;
        }

        if (a >= a9) {
            a = (a * ONE_20) / a9;
            sum += x9;
        }

        if (a >= a10) {
            a = (a * ONE_20) / a10;
            sum += x10;
        }

        if (a >= a11) {
            a = (a * ONE_20) / a11;
            sum += x11;
        }

        // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor series
        // that converges rapidly for values of `a` close to one - the same one used in ln_36.
        // Let z = (a - 1) / (a + 1).
        // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

        // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
        // division by ONE_20.
        int256 z = ((a - ONE_20) * ONE_20) / (a + ONE_20);
        int256 z_squared = (z * z) / ONE_20;

        // num is the numerator of the series: the z^(2 * n + 1) term
        int256 num = z;

        // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
        int256 seriesSum = num;

        // In each step, the numerator is multiplied by z^2
        num = (num * z_squared) / ONE_20;
        seriesSum += num / 3;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 5;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 7;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 9;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 11;

        // 6 Taylor terms are sufficient for 36 decimal precision.

        // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)
        seriesSum *= 2;

        // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder (both
        // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
        // value.

        return (sum + seriesSum) / 100;
    }

    /**
     * @dev Intrnal high precision (36 decimal places) natural logarithm (ln(x)) with signed 18 decimal fixed point argument,
     * for x close to one.
     *
     * Should only be used if x is between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND.
     */
    function _ln_36(int256 x) private pure returns (int256) {
        // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
        // worthwhile.

        // First, we transform x to a 36 digit fixed point value.
        x *= ONE_18;

        // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
        // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

        // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
        // division by ONE_36.
        int256 z = ((x - ONE_36) * ONE_36) / (x + ONE_36);
        int256 z_squared = (z * z) / ONE_36;

        // num is the numerator of the series: the z^(2 * n + 1) term
        int256 num = z;

        // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
        int256 seriesSum = num;

        // In each step, the numerator is multiplied by z^2
        num = (num * z_squared) / ONE_36;
        seriesSum += num / 3;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 5;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 7;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 9;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 11;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 13;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 15;

        // 8 Taylor terms are sufficient for 36 decimal precision.

        // All that remains is multiplying by 2 (non fixed point).
        return seriesSum * 2;
    }
}