// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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

import {ERC20} from "./ERC20.sol";

import {SafeTransferLib} from "../utils/SafeTransferLib.sol";

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/WETH.sol)
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

// File: contracts/ISSVNetwork.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.2;

import "./ISSVRegistry.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISSVNetwork {
    /**
     * @dev Emitted when the account has been enabled.
     * @param ownerAddress Operator's owner.
     */
    event AccountEnable(address indexed ownerAddress);

    /**
     * @dev Emitted when the account has been liquidated.
     * @param ownerAddress Operator's owner.
     */
    event AccountLiquidation(address indexed ownerAddress);

    /**
     * @dev Emitted when the operator has been added.
     * @param id operator's ID.
     * @param name Operator's display name.
     * @param ownerAddress Operator's ethereum address that can collect fees.
     * @param publicKey Operator's public key. Will be used to encrypt secret shares of validators keys.
     * @param fee Operator's initial fee.
     */
    event OperatorRegistration(
        uint32 indexed id,
        string name,
        address indexed ownerAddress,
        bytes publicKey,
        uint256 fee
    );

    /**
     * @dev Emitted when the operator has been removed.
     * @param operatorId operator's ID.
     * @param ownerAddress Operator's owner.
     */
    event OperatorRemoval(uint32 operatorId, address indexed ownerAddress);

    event OperatorFeeDeclaration(
        address indexed ownerAddress,
        uint32 operatorId,
        uint256 blockNumber,
        uint256 fee
    );

    event DeclaredOperatorFeeCancelation(address indexed ownerAddress, uint32 operatorId);

    /**
     * @dev Emitted when an operator's fee is updated.
     * @param ownerAddress Operator's owner.
     * @param blockNumber from which block number.
     * @param fee updated fee value.
     */
    event OperatorFeeExecution(
        address indexed ownerAddress,
        uint32 operatorId,
        uint256 blockNumber,
        uint256 fee
    );

    /**
     * @dev Emitted when an operator's score is updated.
     * @param operatorId operator's ID.
     * @param ownerAddress Operator's owner.
     * @param blockNumber from which block number.
     * @param score updated score value.
     */
    event OperatorScoreUpdate(
        uint32 operatorId,
        address indexed ownerAddress,
        uint256 blockNumber,
        uint256 score
    );

    /**
     * @dev Emitted when the validator has been added.
     * @param ownerAddress The user's ethereum address that is the owner of the validator.
     * @param publicKey The public key of a validator.
     * @param operatorIds The operators public keys list for this validator.
     * @param sharesPublicKeys The shared publick keys list for this validator.
     * @param encryptedKeys The encrypted keys list for this validator.
     */
    event ValidatorRegistration(
        address indexed ownerAddress,
        bytes publicKey,
        uint32[] operatorIds,
        bytes[] sharesPublicKeys,
        bytes[] encryptedKeys
    );

    /**
     * @dev Emitted when the validator is removed.
     * @param ownerAddress Validator's owner.
     * @param publicKey The public key of a validator.
     */
    event ValidatorRemoval(address indexed ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when an owner deposits funds.
     * @param value Amount of tokens.
     * @param ownerAddress Owner's address.
     * @param senderAddress Sender's address.
     */
    event FundsDeposit(uint256 value, address indexed ownerAddress, address indexed senderAddress);

    /**
     * @dev Emitted when an owner withdraws funds.
     * @param value Amount of tokens.
     * @param ownerAddress Owner's address.
     */
    event FundsWithdrawal(uint256 value, address indexed ownerAddress);

    /**
     * @dev Emitted when the network fee is updated.
     * @param oldFee The old fee
     * @param newFee The new fee
     */
    event NetworkFeeUpdate(uint256 oldFee, uint256 newFee);

    /**
     * @dev Emitted when transfer fees are withdrawn.
     * @param value The amount of tokens withdrawn.
     * @param recipient The recipient address.
     */
    event NetworkFeesWithdrawal(uint256 value, address recipient);

    event DeclareOperatorFeePeriodUpdate(uint256 value);

    event ExecuteOperatorFeePeriodUpdate(uint256 value);

    event LiquidationThresholdPeriodUpdate(uint256 value);

    event OperatorFeeIncreaseLimitUpdate(uint256 value);

    event ValidatorsPerOperatorLimitUpdate(uint256 value);

    event RegisteredOperatorsPerAccountLimitUpdate(uint256 value);

    event MinimumBlocksBeforeLiquidationUpdate(uint256 value);

    event OperatorMaxFeeIncreaseUpdate(uint256 value);

    /** errors */
    error ValidatorWithPublicKeyNotExist();
    error CallerNotValidatorOwner();
    error OperatorWithPublicKeyNotExist();
    error CallerNotOperatorOwner();
    error FeeTooLow();
    error FeeExceedsIncreaseLimit();
    error NoPendingFeeChangeRequest();
    error ApprovalNotWithinTimeframe();
    error NotEnoughBalance();
    error BurnRatePositive();
    error AccountAlreadyEnabled();
    error NegativeBalance();
    error BelowMinimumBlockPeriod();
    error ExceedManagingOperatorsPerAccountLimit();

    /**
     * @dev Initializes the contract.
     * @param registryAddress_ The registry address.
     * @param token_ The network token.
     * @param minimumBlocksBeforeLiquidation_ The minimum blocks before liquidation.
     * @param declareOperatorFeePeriod_ The period an operator needs to wait before they can approve their fee.
     * @param executeOperatorFeePeriod_ The length of the period in which an operator can approve their fee.
     */
    function initialize(
        ISSVRegistry registryAddress_,
        IERC20 token_,
        uint64 minimumBlocksBeforeLiquidation_,
        uint64 operatorMaxFeeIncrease_,
        uint64 declareOperatorFeePeriod_,
        uint64 executeOperatorFeePeriod_
    ) external;

    /**
     * @dev Registers a new operator.
     * @param name Operator's display name.
     * @param publicKey Operator's public key. Used to encrypt secret shares of validators keys.
     */
    function registerOperator(
        string calldata name,
        bytes calldata publicKey,
        uint256 fee
    ) external returns (uint32);

    /**
     * @dev Removes an operator.
     * @param operatorId Operator's id.
     */
    function removeOperator(uint32 operatorId) external;

    /**
     * @dev Set operator's fee change request by public key.
     * @param operatorId Operator's id.
     * @param operatorFee The operator's updated fee.
     */
    function declareOperatorFee(uint32 operatorId, uint256 operatorFee) external;

    function cancelDeclaredOperatorFee(uint32 operatorId) external;

    function executeOperatorFee(uint32 operatorId) external;

    /**
     * @dev Updates operator's score by public key.
     * @param operatorId Operator's id.
     * @param score The operators's updated score.
     */
    function updateOperatorScore(uint32 operatorId, uint32 score) external;

    /**
     * @dev Registers a new validator.
     * @param publicKey Validator public key.
     * @param operatorIds Operator public keys.
     * @param sharesPublicKeys Shares public keys.
     * @param sharesEncrypted Encrypted private keys.
     * @param amount Amount of tokens to deposit.
     */
    function registerValidator(
        bytes calldata publicKey,
        uint32[] calldata operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata sharesEncrypted,
        uint256 amount
    ) external;

    /**
     * @dev Updates a validator.
     * @param publicKey Validator public key.
     * @param operatorIds Operator public keys.
     * @param sharesPublicKeys Shares public keys.
     * @param sharesEncrypted Encrypted private keys.
     * @param amount Amount of tokens to deposit.
     */
    function updateValidator(
        bytes calldata publicKey,
        uint32[] calldata operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata sharesEncrypted,
        uint256 amount
    ) external;

    /**
     * @dev Removes a validator.
     * @param publicKey Validator's public key.
     */
    function removeValidator(bytes calldata publicKey) external;

    /**
     * @dev Deposits tokens for the sender.
     * @param ownerAddress Owners' addresses.
     * @param tokenAmount Tokens amount.
     */
    function deposit(address ownerAddress, uint256 tokenAmount) external;

    /**
     * @dev Withdraw tokens for the sender.
     * @param tokenAmount Tokens amount.
     */
    function withdraw(uint256 tokenAmount) external;

    /**
     * @dev Withdraw total balance to the sender, deactivating their validators if necessary.
     */
    function withdrawAll() external;

    /**
     * @dev Liquidates multiple owners.
     * @param ownerAddresses Owners' addresses.
     */
    function liquidate(address[] calldata ownerAddresses) external;

    /**
     * @dev Enables msg.sender account.
     * @param amount Tokens amount.
     */
    function reactivateAccount(uint256 amount) external;

    /**
     * @dev Updates the number of blocks left for an owner before they can be liquidated.
     * @param blocks The new value.
     */
    function updateLiquidationThresholdPeriod(uint64 blocks) external;

    /**
     * @dev Updates the maximum fee increase in pecentage.
     * @param newOperatorMaxFeeIncrease The new value.
     */
    function updateOperatorFeeIncreaseLimit(uint64 newOperatorMaxFeeIncrease) external;

    function updateDeclareOperatorFeePeriod(uint64 newDeclareOperatorFeePeriod) external;

    function updateExecuteOperatorFeePeriod(uint64 newExecuteOperatorFeePeriod) external;

    /**
     * @dev Updates the network fee.
     * @param fee the new fee
     */
    function updateNetworkFee(uint256 fee) external;

    /**
     * @dev Withdraws network fees.
     * @param amount Amount to withdraw
     */
    function withdrawNetworkEarnings(uint256 amount) external;

    /**
     * @dev Gets total balance for an owner.
     * @param ownerAddress Owner's address.
     */
    function getAddressBalance(address ownerAddress) external view returns (uint256);

    function isLiquidated(address ownerAddress) external view returns (bool);

    /**
     * @dev Gets an operator by operator id.
     * @param operatorId Operator's id.
     */
    function getOperatorById(uint32 operatorId)
        external view
        returns (
            string memory,
            address,
            bytes memory,
            uint256,
            uint256,
            uint256,
            bool
        );

    /**
     * @dev Gets a validator public keys by owner's address.
     * @param ownerAddress Owner's Address.
     */
    function getValidatorsByOwnerAddress(address ownerAddress)
        external view
        returns (bytes[] memory);

    /**
     * @dev Gets operators list which are in use by validator.
     * @param validatorPublicKey Validator's public key.
     */
    function getOperatorsByValidator(bytes calldata validatorPublicKey)
        external view
        returns (uint32[] memory);

    function getOperatorDeclaredFee(uint32 operatorId) external view returns (uint256, uint256, uint256);

    /**
     * @dev Gets operator current fee.
     * @param operatorId Operator's id.
     */
    function getOperatorFee(uint32 operatorId) external view returns (uint256);

    /**
     * @dev Gets the network fee for an address.
     * @param ownerAddress Owner's address.
     */
    function addressNetworkFee(address ownerAddress) external view returns (uint256);

    /**
     * @dev Returns the burn rate of an owner, returns 0 if negative.
     * @param ownerAddress Owner's address.
     */
    function getAddressBurnRate(address ownerAddress) external view returns (uint256);

    /**
     * @dev Check if an owner is liquidatable.
     * @param ownerAddress Owner's address.
     */
    function isLiquidatable(address ownerAddress) external view returns (bool);

    /**
     * @dev Returns the network fee.
     */
    function getNetworkFee() external view returns (uint256);

    /**
     * @dev Gets the available network earnings
     */
    function getNetworkEarnings() external view returns (uint256);

    /**
     * @dev Returns the number of blocks left for an owner before they can be liquidated.
     */
    function getLiquidationThresholdPeriod() external view returns (uint256);

    /**
     * @dev Returns the maximum fee increase in pecentage
     */
     function getOperatorFeeIncreaseLimit() external view returns (uint256);

     function getExecuteOperatorFeePeriod() external view returns (uint256);

     function getDeclaredOperatorFeePeriod() external view returns (uint256);

     function validatorsPerOperatorCount(uint32 operatorId) external view returns (uint32);
}

// File: contracts/ISSVRegistry.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.2;

interface ISSVRegistry {
    struct Oess {
        uint32 operatorId;
        bytes sharedPublicKey;
        bytes encryptedKey;
    }

    /** errors */
    error ExceedRegisteredOperatorsByAccountLimit();
    error OperatorDeleted();
    error ValidatorAlreadyExists();
    error ExceedValidatorLimit();
    error OperatorNotFound();
    error InvalidPublicKeyLength();
    error OessDataStructureInvalid();

    /**
     * @dev Initializes the contract
     */
    function initialize() external;

    /**
     * @dev Registers a new operator.
     * @param name Operator's display name.
     * @param ownerAddress Operator's ethereum address that can collect fees.
     * @param publicKey Operator's public key. Will be used to encrypt secret shares of validators keys.
     * @param fee The fee which the operator charges for each block.
     */
    function registerOperator(string calldata name, address ownerAddress, bytes calldata publicKey, uint64 fee) external returns (uint32);

    /**
     * @dev removes an operator.
     * @param operatorId Operator id.
     */
    function removeOperator(uint32 operatorId) external;

    /**
     * @dev Updates an operator fee.
     * @param operatorId Operator id.
     * @param fee New operator fee.
     */
    function updateOperatorFee(
        uint32 operatorId,
        uint64 fee
    ) external;

    /**
     * @dev Updates an operator fee.
     * @param operatorId Operator id.
     * @param score New score.
     */
    function updateOperatorScore(
        uint32 operatorId,
        uint32 score
    ) external;

    /**
     * @dev Registers a new validator.
     * @param ownerAddress The user's ethereum address that is the owner of the validator.
     * @param publicKey Validator public key.
     * @param operatorIds Operator ids.
     * @param sharesPublicKeys Shares public keys.
     * @param sharesEncrypted Encrypted private keys.
     */
    function registerValidator(
        address ownerAddress,
        bytes calldata publicKey,
        uint32[] calldata operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata sharesEncrypted
    ) external;

    /**
     * @dev removes a validator.
     * @param publicKey Validator's public key.
     */
    function removeValidator(bytes calldata publicKey) external;

    function enableOwnerValidators(address ownerAddress) external;

    function disableOwnerValidators(address ownerAddress) external;

    function isLiquidated(address ownerAddress) external view returns (bool);

    /**
     * @dev Gets an operator by operator id.
     * @param operatorId Operator id.
     */
    function getOperatorById(uint32 operatorId)
        external view
        returns (
            string memory,
            address,
            bytes memory,
            uint256,
            uint256,
            uint256,
            bool
        );

    /**
     * @dev Returns operators for owner.
     * @param ownerAddress Owner's address.
     */
    function getOperatorsByOwnerAddress(address ownerAddress)
        external view
        returns (uint32[] memory);

    /**
     * @dev Gets operators list which are in use by validator.
     * @param validatorPublicKey Validator's public key.
     */
    function getOperatorsByValidator(bytes calldata validatorPublicKey)
        external view
        returns (uint32[] memory);

    /**
     * @dev Gets operator's owner.
     * @param operatorId Operator id.
     */
    function getOperatorOwner(uint32 operatorId) external view returns (address);

    /**
     * @dev Gets operator current fee.
     * @param operatorId Operator id.
     */
    function getOperatorFee(uint32 operatorId)
        external view
        returns (uint64);

    /**
     * @dev Gets active validator count.
     */
    function activeValidatorCount() external view returns (uint32);

    /**
     * @dev Gets an validator by public key.
     * @param publicKey Validator's public key.
     */
    function validators(bytes calldata publicKey)
        external view
        returns (
            address,
            bytes memory,
            bool
        );

    /**
     * @dev Gets a validator public keys by owner's address.
     * @param ownerAddress Owner's Address.
     */
    function getValidatorsByAddress(address ownerAddress)
        external view
        returns (bytes[] memory);

    /**
     * @dev Get validator's owner.
     * @param publicKey Validator's public key.
     */
    function getValidatorOwner(bytes calldata publicKey) external view returns (address);

    /**
     * @dev Get validators amount per operator.
     * @param operatorId Operator public key
     */
    function validatorsPerOperatorCount(uint32 operatorId) external view returns (uint32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {WETH} from "solmate/tokens/WETH.sol";

import {ISSVNetwork} from "ssv-network/ISSVNetwork.sol";
import {ISSVRegistry} from "ssv-network/ISSVRegistry.sol";

import {IDepositContract} from "./interfaces/IDepositContract.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

enum IsActive {
    NONE,
    FALSE,
    TRUE
}

struct Validator {
    bytes pubkey;
    uint32[] operatorIds;
    bytes[] sharesPublicKeys;
    bytes[] sharesEncrypted;
    uint256 amount;
    IsActive active;
}

contract StakingPool is Owned, ERC4626 {
    uint256 private constant VALIDATOR_STAKE_AMOUNT = 32 ether;

    mapping(bytes32 => Validator) public validators;
    mapping(address => uint256) public userClaims;
    uint256 public totalValidators;
    uint256 public totalEarned;
    uint256 public totalEarnedHistoric;

    IDepositContract public immutable depositContract;
    ISSVNetwork public immutable SSVNetwork;
    ISSVRegistry public immutable SSVRegistry;
    ERC20 public immutable SSVToken;
    AggregatorV3Interface internal immutable priceFeed;

    /* EVENTS */
    event ValidatorRegistered(bytes32 pubKeyHash, uint256 timestamp);
    event ValidatorRemoved(bytes32 pubKeyHash, uint256 timestamp);
    event ValidatorStakeDeposited(bytes32 pubKeyHash, uint256 timestamp);
    event StakeReached(uint256 stakeCount);

    event RewardIndexUpdated(
        address indexed from,
        uint256 reward,
        uint256 timestamp
    );
    event Staked(address indexed from, uint256 amount, uint256 timestamp);
    event Unstaked(address indexed from, uint256 amount, uint256 timestamp);
    event Claimed(address indexed from, uint256 amount, uint256 timestamp);

    /* ERRORS */
    error InvalidAmount();
    error ValidatorAlreadyExists(bytes32 pubKeyHash, uint256 timestamp);

    constructor(
        IDepositContract _depositContract,
        ERC20 _SSVToken,
        ISSVNetwork _SSVNetwork,
        ISSVRegistry _SSVRegistry,
        ERC20 _weth,
        AggregatorV3Interface _priceFeedAddress
    ) Owned(msg.sender) ERC4626(_weth, "pool SSV token", "PSSV") {
        depositContract = _depositContract;
        SSVToken = _SSVToken;
        SSVRegistry = _SSVRegistry;
        SSVNetwork = _SSVNetwork;
        priceFeed = _priceFeedAddress;
    }

    receive() external payable {
        if (address(asset) != msg.sender) {
            totalEarned += msg.value;
            totalEarnedHistoric += msg.value;
        }
    }

    function stake() public payable {
        if (msg.value == 0) {
            revert InvalidAmount();
        }

        WETH(payable(address(asset))).deposit{value: msg.value}();

        _calculateAssets(msg.value);
    }

    function stake(uint256 amount) public {
        if (amount == 0) {
            revert InvalidAmount();
        }

        asset.transferFrom(msg.sender, address(this), amount);

        _calculateAssets(amount);
    }

    function _calculateAssets(uint256 _amount) internal {
        uint256 cBalance = asset.balanceOf(address(this));
        uint256 stakes = (cBalance - _amount) / VALIDATOR_STAKE_AMOUNT;
        uint256 remainder = cBalance - stakes * VALIDATOR_STAKE_AMOUNT;

        if (remainder >= VALIDATOR_STAKE_AMOUNT) {
            emit StakeReached(remainder / VALIDATOR_STAKE_AMOUNT);
        }

        _mint(msg.sender, _amount);

        emit Staked(msg.sender, _amount, block.timestamp);
    }

    function unstake(uint256 _amount) external {
        _claim();
        _burn(msg.sender, _amount);

        asset.transferFrom(address(this), msg.sender, _amount);

        emit Unstaked(msg.sender, _amount, block.timestamp);
    }

    function claim() external {
        _claim();
    }

    function _claim() internal {
        uint256 amount = calcRewards(msg.sender);

        if (amount == 0) {
            return;
        }

        totalEarned -= amount;
        userClaims[msg.sender] += amount;
        payable(msg.sender).transfer(amount);

        emit Claimed(msg.sender, amount, block.timestamp);
    }

    function registerValidatorAndDeposit(
        bytes memory pubKey,
        uint32[] memory operatorIds,
        bytes[] memory sharesPublicKeys,
        bytes[] memory sharesEncrypted,
        uint256 amount,
        bytes memory withdrawal_credentials,
        bytes memory signature,
        bytes32 deposit_data_root
    ) external onlyOwner {
        registerValidator(
            pubKey,
            operatorIds,
            sharesPublicKeys,
            sharesEncrypted,
            amount
        );

        depositValidatorStaking(
            pubKey,
            withdrawal_credentials,
            signature,
            deposit_data_root
        );
    }

    function registerValidator(
        bytes memory pubKey,
        uint32[] memory operatorIds,
        bytes[] memory sharesPublicKeys,
        bytes[] memory sharesEncrypted,
        uint256 amount
    ) public onlyOwner {
        bytes32 pubKeyHash = keccak256(pubKey);

        if (validators[pubKeyHash].active == IsActive.TRUE) {
            revert ValidatorAlreadyExists(pubKeyHash, block.timestamp);
        }

        SSVToken.approve(address(SSVNetwork), amount);

        // Register the validator and deposit the shares
        SSVNetwork.registerValidator(
            pubKey,
            operatorIds,
            sharesPublicKeys,
            sharesEncrypted,
            amount
        );

        validators[pubKeyHash] = Validator(
            pubKey,
            operatorIds,
            sharesPublicKeys,
            sharesEncrypted,
            amount,
            IsActive.TRUE
        );

        unchecked {
            totalValidators = totalValidators + 1;
        }

        // Emit an event to log the deposit of shares
        emit ValidatorRegistered(pubKeyHash, block.timestamp);
    }

    function removeValidator(bytes calldata pubKey) external onlyOwner {
        bytes32 pubKeyHash = keccak256(pubKey);

        if (validators[pubKeyHash].active == IsActive.FALSE) {
            revert ValidatorAlreadyExists(pubKeyHash, block.timestamp);
        }

        SSVNetwork.removeValidator(pubKey);

        delete validators[pubKeyHash];

        emit ValidatorRemoved(pubKeyHash, block.timestamp);
    }

    function depositValidatorStaking(
        bytes memory pubKey,
        bytes memory withdrawal_credentials,
        bytes memory signature,
        bytes32 deposit_data_root
    ) public onlyOwner {
        WETH(payable(address(asset))).withdraw(VALIDATOR_STAKE_AMOUNT);
        // Deposit the validator to the deposit contract
        depositContract.deposit{value: VALIDATOR_STAKE_AMOUNT}(
            pubKey,
            withdrawal_credentials,
            signature,
            deposit_data_root
        );
        // Emit an event to log the deposit of the public key
        emit ValidatorStakeDeposited(keccak256(pubKey), block.timestamp);
    }

    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function totalAssetsInUSD() public view returns (uint256) {
        (uint256 price, uint256 priceDecimals) = getLatestPrice();
        return (totalSupply * price) / priceDecimals;
    }

    function stakeOf(address who) external view returns (uint256 amount) {
        return balanceOf[who];
    }

    function stakeOfInUSD(address who) external view returns (uint256 amount) {
        (uint256 price, uint256 priceDecimals) = getLatestPrice();
        return (balanceOf[who] * price) / priceDecimals;
    }

    function totalEarnedInUSD() external view returns (uint256 amount) {
        (uint256 price, uint256 priceDecimals) = getLatestPrice();
        return (totalEarned * price) / priceDecimals;
    }

    function totalEarnedHistoricInUSD() external view returns (uint256 amount) {
        (uint256 price, uint256 priceDecimals) = getLatestPrice();
        return (totalEarnedHistoric * price) / priceDecimals;
    }

    function calcRewards(address who) public view returns (uint256 amount) {
        uint256 percSender = (balanceOf[who] * 1000) / totalSupply;

        amount = (percSender * totalEarned) / 1000;
        uint256 userClaim = userClaims[msg.sender];

        if (amount > userClaim) {
            amount -= userClaim;
        } else {
            return 0;
        }
    }

    function calcRewardsInUSD(address who)
        external
        view
        returns (uint256 amount)
    {
        (uint256 price, uint256 priceDecimals) = getLatestPrice();
        return (calcRewards(who) * price) / priceDecimals;
    }

    function getLatestPrice()
        public
        view
        returns (uint256 price, uint256 priceDecimals)
    {
        (, int256 inputPrice, , , ) = priceFeed.latestRoundData();
        require(inputPrice > 0, "Bad price");

        price = uint256(inputPrice);

        priceDecimals = 1 * 10**priceFeed.decimals();
    }

    // Removed functions

    function deposit(uint256, address) public pure override returns (uint256) {
        revert("Can't deposit");
    }

    function mint(uint256, address) public pure override returns (uint256) {
        revert("Can't mint");
    }

    function withdraw(
        uint256,
        address,
        address
    ) public pure override returns (uint256) {
        revert("Can't withdraw");
    }

    function redeem(
        uint256,
        address,
        address
    ) public pure override returns (uint256) {
        revert("Can't redeem");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// This interface is designed to be compatible with the Vyper version.
/// @notice This is the Ethereum 2.0 deposit contract interface.
/// For more information see the Phase 0 specification under https://github.com/ethereum/eth2.0-specs
interface IDepositContract {
    /// @notice A processed deposit event.
    event DepositEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        bytes amount,
        bytes signature,
        bytes index
    );

    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

    /// @notice Query the current deposit root hash.
    /// @return The deposit root hash.
    function get_deposit_root() external view returns (bytes32);

    /// @notice Query the current deposit count.
    /// @return The deposit count encoded as a little endian 64-bit number.
    function get_deposit_count() external view returns (bytes memory);
}