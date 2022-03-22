/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

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
/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}
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

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
                // returned exactly 1 (not just any non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the addition in the
                // order of operations or else returndatasize() will be zero during the computation.
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
                // returned exactly 1 (not just any non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the addition in the
                // order of operations or else returndatasize() will be zero during the computation.
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
                // returned exactly 1 (not just any non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the addition in the
                // order of operations or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

/// @title Fei
/// @author Fei Protocol
/// @notice Minimal interface for the Fei token.
abstract contract Fei is ERC20 {
    function mint(address to, uint256 amount) external virtual;
}
/// @title CERC20
/// @author Compound Labs and Rari Capital
/// @notice Minimal Compound/Fuse Comptroller interface.
abstract contract CERC20 is ERC20 {
    /// @notice Deposit an amount of underlying tokens to the CERC20.
    /// @param underlyingAmount Amount of underlying tokens to deposit.
    /// @return An error code or zero if there was no error in the deposit.
    function mint(uint256 underlyingAmount) external virtual returns (uint256);

    /// @notice Borrow an amount of underlying tokens from the CERC20.
    /// @param underlyingAmount Amount of underlying tokens to borrow.
    /// @return An error code or zero if there was no error in the borrow.
    function borrow(uint256 underlyingAmount) external virtual returns (uint256);

    /// @notice Repay an amount of underlying tokens to the CERC20.
    /// @param underlyingAmount Amount of underlying tokens to repay.
    /// @return An error code or zero if there was no error in the repay.
    function repayBorrow(uint256 underlyingAmount) external virtual returns (uint256);

    /// @notice Returns the underlying balance of a specific user.
    /// @param user The user who's balance the CERC20 will retrieve.
    /// @return The amount of underlying tokens the user is entitled to.
    function balanceOfUnderlying(address user) external view virtual returns (uint256);

    /// @notice Returns the amount of underlying tokens a cToken redeemable for.
    /// @return The amount of underlying tokens a cToken is redeemable for.
    function exchangeRateStored() external view virtual returns (uint256);

    /// @notice Withdraw a specific amount of underlying tokens from the CERC20.
    /// @param underlyingAmount Amount of underlying tokens to withdraw.
    /// @return An error code or zero if there was no error in the withdraw.
    function redeemUnderlying(uint256 underlyingAmount) external virtual returns (uint256);

    /// @notice Return teh current borrow balance of a user in the CERC20.
    /// @param user The user to get the borrow balance for.
    /// @return The current borrow balance of the user.
    function borrowBalanceCurrent(address user) external virtual returns (uint256);

    /// @notice Repay a user's borrow on their behalf.
    /// @param user The user who's borrow to repay.
    /// @param underlyingAmount The amount of debt to repay.
    /// @return An error code or zero if there was no error in the repayBorrowBehalf.
    function repayBorrowBehalf(address user, uint256 underlyingAmount) external virtual returns (uint256);
}

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

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

    /*///////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

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
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
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
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
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

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
/// @dev Do not use in production! ERC-4626 is still in the last call stage and is subject to change.
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
                           ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}






/// @notice Price Feed
/// @author Compound Labs
/// @notice Minimal cToken price feed interface.
interface PriceFeed {
    /// @notice Get the underlying price of the cToken's asset.
    /// @param cToken The cToken to get the underlying price of.
    /// @return The underlying asset price scaled by 1e18.
    function getUnderlyingPrice(CERC20 cToken) external view returns (uint256);

    function add(address[] calldata underlyings, address[] calldata _oracles) external;

    function changeAdmin(address newAdmin) external;
}

/// @title Comptroller
/// @author Compound Labs and Rari Capital
/// @notice Minimal Compound/Fuse Comptroller interface.
interface Comptroller {
    /// @notice Retrieves the admin of the Comptroller.
    /// @return The current administrator of the Comptroller.
    function admin() external view returns (address);

    /// @notice Retrieves the price feed of the Comptroller.
    /// @return The current price feed of the Comptroller.
    function oracle() external view returns (PriceFeed);

    /// @notice Maps underlying tokens to their equivalent cTokens in a pool.
    /// @param token The underlying token to find the equivalent cToken for.
    /// @return The equivalent cToken for the given underlying token.
    function cTokensByUnderlying(ERC20 token) external view returns (CERC20);

    /// @notice Get's data about a cToken.
    /// @param cToken The cToken to get data about.
    /// @return isListed Whether the cToken is listed in the Comptroller.
    /// @return collateralFactor The collateral factor of the cToken.

    function markets(CERC20 cToken) external view returns (bool isListed, uint256 collateralFactor);

    /// @notice Enters into a list of cToken markets, enabling them as collateral.
    /// @param cTokens The list of cTokens to enter into, enabling them as collateral.
    /// @return A list of error codes, or 0 if there were no failures in entering the cTokens.
    function enterMarkets(CERC20[] calldata cTokens) external returns (uint256[] memory);

    function _setPendingAdmin(address newPendingAdmin)
        external
        returns (uint256);

    function _setBorrowCapGuardian(address newBorrowCapGuardian) external;

    function _setMarketSupplyCaps(
        CERC20[] calldata cTokens,
        uint256[] calldata newSupplyCaps
    ) external;

    function _setMarketBorrowCaps(
        CERC20[] calldata cTokens,
        uint256[] calldata newBorrowCaps
    ) external;

    function _setPauseGuardian(address newPauseGuardian)
        external
        returns (uint256);

    function _setMintPaused(CERC20 cToken, bool state)
        external
        returns (bool);

    function _setBorrowPaused(CERC20 cToken, bool borrowPaused)
        external
        returns (bool);

    function _setTransferPaused(bool state) external returns (bool);

    function _setSeizePaused(bool state) external returns (bool);

    function _setPriceOracle(address newOracle)
        external
        returns (uint256);

    function _setCloseFactor(uint256 newCloseFactorMantissa)
        external
        returns (uint256);

    function _setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa)
        external
        returns (uint256);

    function _setCollateralFactor(
        CERC20 cToken,
        uint256 newCollateralFactorMantissa
    ) external returns (uint256);

    function _acceptAdmin() external virtual returns (uint256);

    function _deployMarket(
        bool isCEther,
        bytes calldata constructionData,
        uint256 collateralFactorMantissa
    ) external returns (uint256);

    function borrowGuardianPaused(address cToken)
        external
        view
        returns (bool);

    function comptrollerImplementation()
        external
        view
        returns (address);

    function rewardsDistributors(uint256 index)
        external
        view
        returns (address);

    function _addRewardsDistributor(address distributor)
        external
        returns (uint256);

    function _setWhitelistEnforcement(bool enforce)
        external
        returns (uint256);

    function _setWhitelistStatuses(
        address[] calldata suppliers,
        bool[] calldata statuses
    ) external returns (uint256);

    function _unsupportMarket(CERC20 cToken) external returns (uint256);

    function _toggleAutoImplementations(bool enabled)
        external
        returns (uint256);
}

/// @title Fuse Admin
/// @author Fei Protocol
/// @notice Minimal Fuse Admin interface.
interface FuseAdmin {
    /// @notice Whitelists or blacklists a user from accessing the cTokens in the pool.
    /// @param users The users to whitelist or blacklist.
    /// @param enabled Whether to whitelist or blacklist each user.
    function _setWhitelistStatuses(address[] calldata users, bool[] calldata enabled) external;

    function _deployMarket(
        address underlying,
        address irm,
        string calldata name,
        string calldata symbol,
        address impl,
        bytes calldata data,
        uint256 reserveFactor,
        uint256 adminFee,
        uint256 collateralFactorMantissa
    ) external;
}


interface IReverseRegistrar {
    /**
     @notice sets reverse ENS Record
     @param name the ENS record to set
     After calling this, a user has a fully configured reverse record claiming the provided name as that account's canonical name.
     */
    function setName(string memory name) external returns (bytes32);
}

/**
 @title helper contract to set reverse ens record with solmate Auth
 @author joeysantoro
 @notice sets reverse ENS record against canonical ReverseRegistrar https://docs.ens.domains/contract-api-reference/reverseregistrar.
*/
abstract contract ENSReverseRecordAuth is Auth {

    /// @notice the ENS Reverse Registrar
    IReverseRegistrar public constant REVERSE_REGISTRAR = IReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148);

    function setENSName(string memory name) external requiresAuth {
        REVERSE_REGISTRAR.setName(name);
    }
}

/// @title Turbo Clerk
/// @author Transmissions11
/// @notice Fee determination module for Turbo Safes.
contract TurboClerk is Auth, ENSReverseRecordAuth {
    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Turbo Clerk contract.
    /// @param _owner The owner of the Clerk.
    /// @param _authority The Authority of the Clerk.
    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*///////////////////////////////////////////////////////////////
                        DEFAULT FEE CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice The default fee on Safe interest taken by the protocol.
    /// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
    uint256 public defaultFeePercentage;

    /// @notice Emitted when the default fee percentage is updated.
    /// @param newDefaultFeePercentage The new default fee percentage.
    event DefaultFeePercentageUpdated(address indexed user, uint256 newDefaultFeePercentage);

    /// @notice Sets the default fee percentage.
    /// @param newDefaultFeePercentage The new default fee percentage.
    function setDefaultFeePercentage(uint256 newDefaultFeePercentage) external requiresAuth {
        // A fee percentage over 100% makes no sense.
        require(newDefaultFeePercentage <= 1e18, "FEE_TOO_HIGH");

        // Update the default fee percentage.
        defaultFeePercentage = newDefaultFeePercentage;

        emit DefaultFeePercentageUpdated(msg.sender, newDefaultFeePercentage);
    }

    /*///////////////////////////////////////////////////////////////
                        CUSTOM FEE CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps collaterals to their custom fees on interest taken by the protocol.
    /// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
    mapping(ERC20 => uint256) public getCustomFeePercentageForCollateral;

    /// @notice Maps Safes to their custom fees on interest taken by the protocol.
    /// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
    mapping(TurboSafe => uint256) public getCustomFeePercentageForSafe;

    /// @notice Emitted when a collateral's custom fee percentage is updated.
    /// @param collateral The collateral who's custom fee percentage was updated.
    /// @param newFeePercentage The new custom fee percentage.
    event CustomFeePercentageUpdatedForCollateral(
        address indexed user,
        ERC20 indexed collateral,
        uint256 newFeePercentage
    );

    /// @notice Sets a collateral's custom fee percentage.
    /// @param collateral The collateral to set the custom fee percentage for.
    /// @param newFeePercentage The new custom fee percentage for the collateral.
    function setCustomFeePercentageForCollateral(ERC20 collateral, uint256 newFeePercentage) external requiresAuth {
        // A fee percentage over 100% makes no sense.
        require(newFeePercentage <= 1e18, "FEE_TOO_HIGH");

        // Update the custom fee percentage for the Safe.
        getCustomFeePercentageForCollateral[collateral] = newFeePercentage;

        emit CustomFeePercentageUpdatedForCollateral(msg.sender, collateral, newFeePercentage);
    }

    /// @notice Emitted when a Safe's custom fee percentage is updated.
    /// @param safe The Safe who's custom fee percentage was updated.
    /// @param newFeePercentage The new custom fee percentage.
    event CustomFeePercentageUpdatedForSafe(address indexed user, TurboSafe indexed safe, uint256 newFeePercentage);

    /// @notice Sets a Safe's custom fee percentage.
    /// @param safe The Safe to set the custom fee percentage for.
    /// @param newFeePercentage The new custom fee percentage for the Safe.
    function setCustomFeePercentageForSafe(TurboSafe safe, uint256 newFeePercentage) external requiresAuth {
        // A fee percentage over 100% makes no sense.
        require(newFeePercentage <= 1e18, "FEE_TOO_HIGH");

        // Update the custom fee percentage for the Safe.
        getCustomFeePercentageForSafe[safe] = newFeePercentage;

        emit CustomFeePercentageUpdatedForSafe(msg.sender, safe, newFeePercentage);
    }

    /*///////////////////////////////////////////////////////////////
                          ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the fee on interest taken by the protocol for a Safe.
    /// @param safe The Safe to get the fee percentage for.
    /// @param collateral The collateral/asset of the Safe.
    /// @return The fee percentage for the Safe.
    function getFeePercentageForSafe(TurboSafe safe, ERC20 collateral) external view returns (uint256) {
        // Get the custom fee percentage for the Safe.
        uint256 customFeePercentageForSafe = getCustomFeePercentageForSafe[safe];

        // If a custom fee percentage is set for the Safe, return it.
        if (customFeePercentageForSafe != 0) return customFeePercentageForSafe;

        // Get the custom fee percentage for the collateral type.
        uint256 customFeePercentageForCollateral = getCustomFeePercentageForCollateral[collateral];

        // If a custom fee percentage is set for the collateral, return it.
        if (customFeePercentageForCollateral != 0) return customFeePercentageForCollateral;

        // Otherwise, return the default fee percentage.
        return defaultFeePercentage;
    }
}
/// @title Turbo Booster
/// @author Transmissions11
/// @notice Boost authorization module.
contract TurboBooster is Auth, ENSReverseRecordAuth {
    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Turbo Booster contract.
    /// @param _owner The owner of the Booster.
    /// @param _authority The Authority of the Booster.
    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*///////////////////////////////////////////////////////////////
                      GLOBAL FREEZE CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Whether boosting is currently frozen.
    bool public frozen;

    /// @notice Emitted when boosting is frozen or unfrozen.
    /// @param user The user who froze or unfroze boosting.
    /// @param frozen Whether boosting is now frozen.
    event FreezeStatusUpdated(address indexed user, bool frozen);

    /// @notice Sets whether boosting is frozen.
    /// @param freeze Whether boosting will be frozen.
    function setFreezeStatus(bool freeze) external requiresAuth {
        // Update freeze status.
        frozen = freeze;

        emit FreezeStatusUpdated(msg.sender, freeze);
    }

    /*///////////////////////////////////////////////////////////////
                     VAULT BOOST CAP CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    ERC4626[] public boostableVaults;

    /// @notice exposes an array of boostable vaults. Only used for visibility.
    function getBoostableVaults() external view returns(ERC4626[] memory) {
        return boostableVaults;
    }

    /// @notice Maps Vaults to the cap on the amount of Fei used to boost them.
    mapping(ERC4626 => uint256) public getBoostCapForVault;

    /// @notice Emitted when a Vault's boost cap is updated.
    /// @param vault The Vault who's boost cap was updated.
    /// @param newBoostCap The new boost cap for the Vault.
    event BoostCapUpdatedForVault(address indexed user, ERC4626 indexed vault, uint256 newBoostCap);

    /// @notice Sets a Vault's boost cap.
    /// @param vault The Vault to set the boost cap for.
    /// @param newBoostCap The new boost cap for the Vault.
    function setBoostCapForVault(ERC4626 vault, uint256 newBoostCap) external requiresAuth {
        require(newBoostCap != 0, "cap is zero");

        // Add to boostable vaults array
        if (getBoostCapForVault[vault] == 0) {
            boostableVaults.push(vault);
        }
        
        // Update the boost cap for the Vault.
        getBoostCapForVault[vault] = newBoostCap;

        emit BoostCapUpdatedForVault(msg.sender, vault, newBoostCap);
    }

    /*///////////////////////////////////////////////////////////////
                     COLLATERAL BOOST CAP CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps collateral types to the cap on the amount of Fei boosted against them.
    mapping(ERC20 => uint256) public getBoostCapForCollateral;

    /// @notice Emitted when a collateral type's boost cap is updated.
    /// @param collateral The collateral type who's boost cap was updated.
    /// @param newBoostCap The new boost cap for the collateral type.
    event BoostCapUpdatedForCollateral(address indexed user, ERC20 indexed collateral, uint256 newBoostCap);

    /// @notice Sets a collateral type's boost cap.
    /// @param collateral The collateral type to set the boost cap for.
    /// @param newBoostCap The new boost cap for the collateral type.
    function setBoostCapForCollateral(ERC20 collateral, uint256 newBoostCap) external requiresAuth {
        // Update the boost cap for the collateral type.
        getBoostCapForCollateral[collateral] = newBoostCap;

        emit BoostCapUpdatedForCollateral(msg.sender, collateral, newBoostCap);
    }

    /*///////////////////////////////////////////////////////////////
                          AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether a Safe is authorized to boost a Vault.
    /// @param safe The Safe to check is authorized to boost the Vault.
    /// @param collateral The collateral/asset of the Safe.
    /// @param vault The Vault to check the Safe is authorized to boost.
    /// @param feiAmount The amount of Fei asset to check the Safe is authorized boost the Vault with.
    /// @param newTotalBoostedForVault The total amount of Fei that will boosted to the Vault after boost (if it is not rejected).
    /// @param newTotalBoostedAgainstCollateral The total amount of Fei that will be boosted against the Safe's collateral type after this boost.
    /// @return Whether the Safe is authorized to boost the Vault with the given amount of Fei asset.
    function canSafeBoostVault(
        TurboSafe safe,
        ERC20 collateral,
        ERC4626 vault,
        uint256 feiAmount,
        uint256 newTotalBoostedForVault,
        uint256 newTotalBoostedAgainstCollateral
    ) external view returns (bool) {
        return
            !frozen &&
            getBoostCapForVault[vault] >= newTotalBoostedForVault &&
            getBoostCapForCollateral[collateral] >= newTotalBoostedAgainstCollateral;
    }
}





/// @title Turbo Master
/// @author Transmissions11
/// @notice Factory for creating and managing Turbo Safes.
/// @dev Must be authorized to call the Turbo Fuse Pool's FuseAdmin.
contract TurboMaster is Auth, ENSReverseRecordAuth {
    using SafeTransferLib for ERC20;

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The Turbo Fuse Pool the Safes will interact with.
    Comptroller public immutable pool;

    /// @notice The Fei token on the network.
    ERC20 public immutable fei;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Turbo Master contract.
    /// @param _pool The Turbo Fuse Pool the Master will use.
    /// @param _fei The Fei token on the network.
    /// @param _owner The owner of the Master.
    /// @param _authority The Authority of the Master.
    constructor(
        Comptroller _pool,
        ERC20 _fei,
        address _owner,
        Authority _authority
    ) Auth(_owner, _authority) {
        pool = _pool;

        fei = _fei;

        // Prevent the first safe from getting id 0.
        safes.push(TurboSafe(address(0)));
    }

    /*///////////////////////////////////////////////////////////////
                            BOOSTER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The Booster module used by the Master and its Safes.
    TurboBooster public booster;

    /// @notice Emitted when the Booster is updated.
    /// @param user The user who triggered the update of the Booster.
    /// @param newBooster The new Booster contract used by the Master.
    event BoosterUpdated(address indexed user, TurboBooster newBooster);

    /// @notice Update the Booster used by the Master.
    /// @param newBooster The new Booster contract to be used by the Master.
    function setBooster(TurboBooster newBooster) external requiresAuth {
        booster = newBooster;

        emit BoosterUpdated(msg.sender, newBooster);
    }

    /*///////////////////////////////////////////////////////////////
                             CLERK STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The Clerk module used by the Master and its Safes.
    TurboClerk public clerk;

    /// @notice Emitted when the Clerk is updated.
    /// @param user The user who triggered the update of the Clerk.
    /// @param newClerk The new Clerk contract used by the Master.
    event ClerkUpdated(address indexed user, TurboClerk newClerk);

    /// @notice Update the Clerk used by the Master.
    /// @param newClerk The new Clerk contract to be used by the Master.
    function setClerk(TurboClerk newClerk) external requiresAuth {
        clerk = newClerk;

        emit ClerkUpdated(msg.sender, newClerk);
    }

    /*///////////////////////////////////////////////////////////////
                  DEFAULT SAFE AUTHORITY CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice The default authority to be used by created Safes.
    Authority public defaultSafeAuthority;

    /// @notice Emitted when the default safe authority is updated.
    /// @param user The user who triggered the update of the default safe authority.
    /// @param newDefaultSafeAuthority The new default authority to be used by created Safes.
    event DefaultSafeAuthorityUpdated(address indexed user, Authority newDefaultSafeAuthority);

    /// @notice Set the default authority to be used by created Safes.
    /// @param newDefaultSafeAuthority The new default safe authority.
    function setDefaultSafeAuthority(Authority newDefaultSafeAuthority) external requiresAuth {
        // Update the default safe authority.
        defaultSafeAuthority = newDefaultSafeAuthority;

        emit DefaultSafeAuthorityUpdated(msg.sender, newDefaultSafeAuthority);
    }

    /*///////////////////////////////////////////////////////////////
                             SAFE STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The total Fei currently boosting Vaults.
    uint256 public totalBoosted;

    /// @notice Maps Safe addresses to the id they are stored under in the Safes array.
    mapping(TurboSafe => uint256) public getSafeId;

    /// @notice Maps Vault addresses to the total amount of Fei they've being boosted with.
    mapping(ERC4626 => uint256) public getTotalBoostedForVault;

    /// @notice Maps collateral types to the total amount of Fei boosted by Safes using it as collateral.
    mapping(ERC20 => uint256) public getTotalBoostedAgainstCollateral;

    /// @notice An array of all Safes created by the Master.
    /// @dev The first Safe is purposely invalid to prevent any Safes from having an id of 0.
    TurboSafe[] public safes;

    /// @notice Returns all Safes created by the Master.
    /// @return An array of all Safes created by the Master.
    /// @dev This is provided because Solidity converts public arrays into index getters,
    /// but we need a way to allow external contracts and users to access the whole array.
    function getAllSafes() external view returns (TurboSafe[] memory) {
        return safes;
    }

    /*///////////////////////////////////////////////////////////////
                          SAFE CREATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new Safe is created.
    /// @param user The user who created the Safe.
    /// @param asset The asset of the Safe.
    /// @param safe The newly deployed Safe contract.
    /// @param id The index of the Safe in the safes array.
    event TurboSafeCreated(address indexed user, ERC20 indexed asset, TurboSafe safe, uint256 id);

    /// @notice Creates a new Turbo Safe which supports a specific asset.
    /// @param asset The ERC20 token that the Safe should accept.
    /// @return safe The newly deployed Turbo Safe which accepts the provided asset.
    function createSafe(ERC20 asset) external requiresAuth returns (TurboSafe safe, uint256 id) {
        // Create a new Safe using the default authority and provided asset.
        safe = new TurboSafe(msg.sender, defaultSafeAuthority, asset);

        // Add the safe to the list of Safes.
        safes.push(safe);

        unchecked {
            // Get the index/id of the new Safe.
            // Cannot underflow, we just pushed to it.
            id = safes.length - 1;
        }

        // Store the id/index of the new Safe.
        getSafeId[safe] = id;

        emit TurboSafeCreated(msg.sender, asset, safe, id);

        // Prepare a users array to whitelist the Safe.
        address[] memory users = new address[](1);
        users[0] = address(safe);

        // Prepare an enabled array to whitelist the Safe.
        bool[] memory enabled = new bool[](1);
        enabled[0] = true;

        // Whitelist the Safe to access the Turbo Fuse Pool.
        FuseAdmin(pool.admin())._setWhitelistStatuses(users, enabled);
    }

    /*///////////////////////////////////////////////////////////////
                          SAFE CALLBACK LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Callback triggered whenever a Safe boosts a Vault.
    /// @param asset The asset of the Safe.
    /// @param vault The Vault that was boosted.
    /// @param feiAmount The amount of Fei used to boost the Vault.
    function onSafeBoost(
        ERC20 asset,
        ERC4626 vault,
        uint256 feiAmount
    ) external {
        // Get the caller as a Safe instance.
        TurboSafe safe = TurboSafe(msg.sender);

        // Ensure the Safe was created by this Master.
        require(getSafeId[safe] != 0, "INVALID_SAFE");

        // Update the total amount of Fei being using to boost Vaults.
        totalBoosted += feiAmount;

        // Cache the new total boosted for the Vault.
        uint256 newTotalBoostedForVault;

        // Cache the new total boosted against the Vault's collateral.
        uint256 newTotalBoostedAgainstCollateral;

        // Update the total amount of Fei being using to boost the Vault.
        getTotalBoostedForVault[vault] = (newTotalBoostedForVault = getTotalBoostedForVault[vault] + feiAmount);

        // Update the total amount of Fei boosted against the collateral type.
        getTotalBoostedAgainstCollateral[asset] = (newTotalBoostedAgainstCollateral =
            getTotalBoostedAgainstCollateral[asset] +
            feiAmount);

        // Check with the booster that the Safe is allowed to boost the Vault using this amount of Fei.
        require(
            booster.canSafeBoostVault(
                safe,
                asset,
                vault,
                feiAmount,
                newTotalBoostedForVault,
                newTotalBoostedAgainstCollateral
            ),
            "BOOSTER_REJECTED"
        );
    }

    /// @notice Callback triggered whenever a Safe withdraws from a Vault.
    /// @param asset The asset of the Safe.
    /// @param vault The Vault that was withdrawn from.
    /// @param feiAmount The amount of Fei withdrawn from the Vault.
    function onSafeLess(
        ERC20 asset,
        ERC4626 vault,
        uint256 feiAmount
    ) external {
        // Get the caller as a Safe instance.
        TurboSafe safe = TurboSafe(msg.sender);

        // Ensure the Safe was created by this Master.
        require(getSafeId[safe] != 0, "INVALID_SAFE");

        // Update the total amount of Fei being using to boost the Vault.
        getTotalBoostedForVault[vault] -= feiAmount;

        // Update the total amount of Fei being using to boost Vaults.
        totalBoosted -= feiAmount;

        // Update the total amount of Fei boosted against the collateral type.
        getTotalBoostedAgainstCollateral[asset] -= feiAmount;
    }

    /*///////////////////////////////////////////////////////////////
                              SWEEP LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted a token is sweeped from the Master.
    /// @param user The user who sweeped the token from the Master.
    /// @param to The recipient of the sweeped tokens.
    /// @param amount The amount of the token that was sweeped.
    event TokenSweeped(address indexed user, address indexed to, ERC20 indexed token, uint256 amount);

    /// @notice Claim tokens sitting idly in the Master.
    /// @param to The recipient of the sweeped tokens.
    /// @param token The token to sweep and send.
    /// @param amount The amount of the token to sweep.
    function sweep(
        address to,
        ERC20 token,
        uint256 amount
    ) external requiresAuth {
        emit TokenSweeped(msg.sender, to, token, amount);

        // Transfer the sweeped tokens to the recipient.
        token.safeTransfer(to, amount);
    }
}

/// @title Turbo Safe
/// @author Transmissions11
/// @notice Fuse liquidity accelerator.
contract TurboSafe is Auth, ERC4626, ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The Master contract that created the Safe.
    /// @dev Fees are paid directly to the Master, where they can be swept.
    TurboMaster public immutable master;

    /// @notice The Fei token on the network.
    ERC20 public immutable fei;

    /// @notice The Turbo Fuse Pool contract that collateral is held in and Fei is borrowed from.
    Comptroller public immutable pool;

    /// @notice The Fei cToken in the Turbo Fuse Pool that Fei is borrowed from.
    CERC20 public immutable feiTurboCToken;

    /// @notice The cToken that accepts the asset in the Turbo Fuse Pool.
    CERC20 public immutable assetTurboCToken;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Safe that accepts a specific asset.
    /// @param _owner The owner of the Safe.
    /// @param _authority The Authority of the Safe.
    /// @param _asset The ERC20 compliant token the Safe should accept.
    constructor(
        address _owner,
        Authority _authority,
        ERC20 _asset
    )
        Auth(_owner, _authority)
        ERC4626(
            _asset,
            // ex: Dai Stablecoin Turbo Safe
            string(abi.encodePacked(_asset.name(), " Turbo Safe")),
            // ex: tsDAI
            string(abi.encodePacked("ts", _asset.symbol()))
        )
    {
        master = TurboMaster(msg.sender);

        fei = master.fei();

        // An asset of Fei makes no sense.
        require(asset != fei, "INVALID_ASSET");

        pool = master.pool();

        feiTurboCToken = pool.cTokensByUnderlying(fei);

        assetTurboCToken = pool.cTokensByUnderlying(asset);

        // If the provided asset is not supported by the Turbo Fuse Pool, revert.
        require(address(assetTurboCToken) != address(0), "UNSUPPORTED_ASSET");

        // Construct an array of market(s) to enable as collateral.
        CERC20[] memory marketsToEnter = new CERC20[](1);
        marketsToEnter[0] = assetTurboCToken;

        // Enter the market(s) and ensure to properly revert if there is an error.
        require(pool.enterMarkets(marketsToEnter)[0] == 0, "ENTER_MARKETS_FAILED");

        // Preemptively approve the asset to the Turbo Fuse Pool's corresponding cToken.
        asset.safeApprove(address(assetTurboCToken), type(uint256).max);

        // Preemptively approve Fei to the Turbo Fuse Pool's Fei cToken.
        fei.safeApprove(address(feiTurboCToken), type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                               SAFE STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The current total amount of Fei the Safe is using to boost Vaults.
    uint256 public totalFeiBoosted;

    /// @notice Maps Vaults to the total amount of Fei they've being boosted with.
    /// @dev Used to determine the fees to be paid back to the Master.
    mapping(ERC4626 => uint256) public getTotalFeiBoostedForVault;

    /*///////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks the caller is authorized using either the Master's Authority or the Safe's local Authority.
    modifier requiresLocalOrMasterAuth() {
        // Check if the caller is the owner first:
        if (msg.sender != owner) {
            Authority masterAuth = master.authority(); // Avoid wasting gas calling the Master twice.

            // If the Master's Authority does not exist or does not accept upfront:
            if (address(masterAuth) == address(0) || !masterAuth.canCall(msg.sender, address(this), msg.sig)) {
                Authority auth = authority; // Memoizing saves us a warm SLOAD, around 100 gas.

                // The only authorization option left is via the local Authority, otherwise revert.
                require(
                    address(auth) != address(0) && auth.canCall(msg.sender, address(this), msg.sig),
                    "UNAUTHORIZED"
                );
            }
        }

        _;
    }

    /// @dev Checks the caller is authorized using the Master's Authority.
    modifier requiresMasterAuth() {
        Authority masterAuth = master.authority(); // Avoid wasting gas calling the Master twice.

        // Revert if the Master's Authority does not approve of the call and the caller is not the Master's owner.
        require(
            (address(masterAuth) != address(0) && masterAuth.canCall(msg.sender, address(this), msg.sig)) ||
                msg.sender == master.owner(),
            "UNAUTHORIZED"
        );

        _;
    }

    /*///////////////////////////////////////////////////////////////
                             ERC4626 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Called after any type of deposit occurs.
    /// @param assetAmount The amount of assets being deposited.
    /// @dev Using requiresAuth here prevents unauthorized users from depositing.
    function afterDeposit(uint256 assetAmount, uint256) internal override nonReentrant requiresAuth {
        // Collateralize the assets in the Turbo Fuse Pool.
        require(assetTurboCToken.mint(assetAmount) == 0, "MINT_FAILED");
    }

    /// @notice Called before any type of withdrawal occurs.
    /// @param assetAmount The amount of assets being withdrawn.
    /// @dev Using requiresAuth here prevents unauthorized users from withdrawing.
    function beforeWithdraw(uint256 assetAmount, uint256) internal override nonReentrant requiresAuth {
        // Withdraw the assets from the Turbo Fuse Pool.
        require(assetTurboCToken.redeemUnderlying(assetAmount) == 0, "REDEEM_FAILED");
    }

    /// @notice Returns the total amount of assets held in the Safe.
    /// @return The total amount of assets held in the Safe.
    function totalAssets() public view override returns (uint256) {
        return assetTurboCToken.balanceOf(address(this)).mulWadDown(assetTurboCToken.exchangeRateStored());
    }

    /*///////////////////////////////////////////////////////////////
                           BOOST/LESS LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a Vault is boosted by the Safe.
    /// @param user The user who boosted the Vault.
    /// @param vault The Vault that was boosted.
    /// @param feiAmount The amount of Fei that was boosted to the Vault.
    event VaultBoosted(address indexed user, ERC4626 indexed vault, uint256 feiAmount);

    /// @notice Borrow Fei from the Turbo Fuse Pool and deposit it into an authorized Vault.
    /// @param vault The Vault to deposit the borrowed Fei into.
    /// @param feiAmount The amount of Fei to borrow and supply into the Vault.
    function boost(ERC4626 vault, uint256 feiAmount) external nonReentrant requiresAuth {
        // Ensure the Vault accepts Fei asset.
        require(vault.asset() == fei, "NOT_FEI");

        // Call the Master where it will do extra validation
        // and update it's total count of funds used for boosting.
        master.onSafeBoost(asset, vault, feiAmount);

        // Increase the boost total proportionately.
        totalFeiBoosted += feiAmount;

        // Update the total Fei deposited into the Vault proportionately.
        getTotalFeiBoostedForVault[vault] += feiAmount;

        emit VaultBoosted(msg.sender, vault, feiAmount);

        // Borrow the Fei amount from the Fei cToken in the Turbo Fuse Pool.
        require(feiTurboCToken.borrow(feiAmount) == 0, "BORROW_FAILED");

        // Approve the borrowed Fei to the specified Vault.
        fei.safeApprove(address(vault), feiAmount);

        // Deposit the Fei into the specified Vault.
        vault.deposit(feiAmount, address(this));
    }

    /// @notice Emitted when a Vault is withdrawn from by the Safe.
    /// @param user The user who lessed the Vault.
    /// @param vault The Vault that was withdrawn from.
    /// @param feiAmount The amount of Fei that was withdrawn from the Vault.
    event VaultLessened(address indexed user, ERC4626 indexed vault, uint256 feiAmount);

    /// @notice Withdraw Fei from a deposited Vault and use it to repay debt in the Turbo Fuse Pool.
    /// @param vault The Vault to withdraw the Fei from.
    /// @param feiAmount The amount of Fei to withdraw from the Vault and repay in the Turbo Fuse Pool.
    function less(ERC4626 vault, uint256 feiAmount) external nonReentrant requiresLocalOrMasterAuth {
        // Update the total Fei deposited into the Vault proportionately.
        getTotalFeiBoostedForVault[vault] -= feiAmount;

        // Decrease the boost total proportionately.
        totalFeiBoosted -= feiAmount;

        emit VaultLessened(msg.sender, vault, feiAmount);

        // Withdraw the specified amount of Fei from the Vault.
        vault.withdraw(feiAmount, address(this), address(this));

        // Get out current amount of Fei debt in the Turbo Fuse Pool.
        uint256 feiDebt = feiTurboCToken.borrowBalanceCurrent(address(this));

        // Call the Master to allow it to update its accounting.
        master.onSafeLess(asset, vault, feiAmount);

        // If our debt balance decreased, repay the minimum.
        // The surplus Fei will accrue as fees and can be sweeped.
        if (feiAmount > feiDebt) feiAmount = feiDebt;

        // Repay Fei debt in the Turbo Fuse Pool, unless we would repay nothing.
        if (feiAmount != 0) require(feiTurboCToken.repayBorrow(feiAmount) == 0, "REPAY_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                              SLURP LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a Vault is slurped from by the Safe.
    /// @param user The user who slurped the Vault.
    /// @param vault The Vault that was slurped.
    /// @param protocolFeeAmount The amount of Fei accrued as fees to the Master.
    /// @param safeInterestAmount The amount of Fei accrued as interest to the Safe.
    event VaultSlurped(
        address indexed user,
        ERC4626 indexed vault,
        uint256 protocolFeeAmount,
        uint256 safeInterestAmount
    );

    /// @notice Accrue any interest earned by the Safe in the Vault.
    /// @param vault The Vault to accrue interest from, if any.
    /// @dev Sends a portion of the interest to the Master, as determined by the Clerk.
    function slurp(ERC4626 vault) external nonReentrant requiresLocalOrMasterAuth returns(uint256 safeInterestAmount) {
        // Cache the total Fei currently boosting the Vault.
        uint256 totalFeiBoostedForVault = getTotalFeiBoostedForVault[vault];

        // Ensure the Safe has Fei currently boosting the Vault.
        require(totalFeiBoostedForVault != 0, "NO_FEI_BOOSTED");

        // Compute the amount of Fei interest the Safe generated by boosting the Vault.
        uint256 interestEarned = vault.previewRedeem(vault.balanceOf(address(this))) - totalFeiBoostedForVault;

        // Compute what percentage of the interest earned will go back to the Safe.
        uint256 protocolFeePercent = master.clerk().getFeePercentageForSafe(this, asset);

        // Compute the amount of Fei the protocol will retain as fees.
        uint256 protocolFeeAmount = interestEarned.mulWadDown(protocolFeePercent);

        // Compute the amount of Fei the Safe will retain as interest.
        safeInterestAmount = interestEarned - protocolFeeAmount;

        emit VaultSlurped(msg.sender, vault, protocolFeeAmount, safeInterestAmount);

        vault.withdraw(interestEarned, address(this), address(this));

        // If we have unaccrued fees, withdraw them from the Vault and transfer them to the Master.
        if (protocolFeeAmount != 0) fei.transfer(address(master), protocolFeeAmount);
    }

    /*///////////////////////////////////////////////////////////////
                              SWEEP LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted a token is sweeped from the Safe.
    /// @param user The user who sweeped the token from the Safe.
    /// @param to The recipient of the sweeped tokens.
    /// @param amount The amount of the token that was sweeped.
    event TokenSweeped(address indexed user, address indexed to, ERC20 indexed token, uint256 amount);

    /// @notice Claim tokens sitting idly in the Safe.
    /// @param to The recipient of the sweeped tokens.
    /// @param token The token to sweep and send.
    /// @param amount The amount of the token to sweep.
    function sweep(
        address to,
        ERC20 token,
        uint256 amount
    ) external requiresAuth {
        // Ensure the caller is not trying to steal Vault shares or collateral cTokens.
        require(getTotalFeiBoostedForVault[ERC4626(address(token))] == 0 && token != assetTurboCToken, "INVALID_TOKEN");

        emit TokenSweeped(msg.sender, to, token, amount);

        // Transfer the sweeped tokens to the recipient.
        token.safeTransfer(to, amount);
    }

    /*///////////////////////////////////////////////////////////////
                               GIB LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a Safe is gibbed.
    /// @param user The user who gibbed the Safe.
    /// @param to The recipient of the impounded collateral.
    /// @param assetAmount The amount of underling tokens impounded.
    event SafeGibbed(address indexed user, address indexed to, uint256 assetAmount);

    /// @notice Impound a specific amount of a Safe's collateral.
    /// @param to The address to send the impounded collateral to.
    /// @param assetAmount The amount of the asset to impound.
    /// @dev Debt must be repaid in advance, or the redemption will fail.
    function gib(address to, uint256 assetAmount) external nonReentrant requiresMasterAuth {
        emit SafeGibbed(msg.sender, to, assetAmount);

        // Withdraw the specified amount of assets from the Turbo Fuse Pool.
        require(assetTurboCToken.redeemUnderlying(assetAmount) == 0, "REDEEM_FAILED");

        // Transfer the assets to the authorized caller.
        asset.safeTransfer(to, assetAmount);
    }
}




/// @title Turbo Gibber
/// @author Transmissions11
/// @notice Atomic impounder module.
contract TurboGibber is Auth, ReentrancyGuard, ENSReverseRecordAuth {
    using SafeTransferLib for Fei;

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The Master contract.
    /// @dev Used to validate Safes are legitimate.
    TurboMaster public immutable master;

    /// @notice The Fei token on the network.
    Fei public immutable fei;

    /// @notice The Fei cToken in the Turbo Fuse Pool.
    CERC20 public immutable feiTurboCToken;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Turbo Gibber contract.
    /// @param _master The Master of the Gibber.
    /// @param _owner The owner of the Gibber.
    /// @param _authority The Authority of the Gibber.
    constructor(
        TurboMaster _master,
        address _owner,
        Authority _authority
    ) Auth(_owner, _authority) {
        master = _master;

        fei = Fei(address(master.fei()));

        feiTurboCToken = master.pool().cTokensByUnderlying(fei);

        // Preemptively approve to the Fei cToken in the Turbo Fuse Pool.
        fei.safeApprove(address(feiTurboCToken), type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                          ATOMIC IMPOUND LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted an impound is executed.
    /// @param user The user who executed the impound.
    /// @param safe The Safe that was impounded.
    /// @param feiAmount The amount of Fei that was repaid.
    /// @param assetAmount The amount of assets impounded.
    event ImpoundExecuted(address indexed user, TurboSafe indexed safe, uint256 feiAmount, uint256 assetAmount);

    /// @notice Impound a safe.
    /// @param safe The Safe to be impounded.
    /// @param feiAmount The amount of Fei to repay the Safe's debt with.
    /// @param assetAmount The amount of assets to impound.
    /// @param to The recipient of the impounded collateral tokens.
    function impound(
        TurboSafe safe,
        uint256 feiAmount,
        uint256 assetAmount,
        address to
    ) external requiresAuth nonReentrant {
        // Ensure the Safe is registered with the Master.
        require(master.getSafeId(safe) != 0);

        emit ImpoundExecuted(msg.sender, safe, feiAmount, assetAmount);

        // Mint the Fei amount requested.
        fei.mint(address(this), feiAmount);

        // Repay the safe's Fei debt with the minted Fei, ensuring to catch cToken errors.
        require(feiTurboCToken.repayBorrowBehalf(address(safe), feiAmount) == 0, "REPAY_FAILED");

        // Impound some of the safe's collateral and send it to the chosen recipient.
        safe.gib(to, assetAmount);
    }

    /// @notice Impound all of a safe's collateral.
    /// @param safe The Safe to be impounded.
    /// @param to The recipient of the impounded collateral tokens.
    function impoundAll(TurboSafe safe, address to) external requiresAuth nonReentrant {
        // Ensure the Safe is registered with the Master.
        require(master.getSafeId(safe) != 0);

        // Get the asset cToken in the Turbo Fuse Pool.
        CERC20 assetTurboCToken = safe.assetTurboCToken();

        // Get the amount of assets to impound from the Safe.
        uint256 assetAmount = assetTurboCToken.balanceOfUnderlying(address(safe));

        // Get the amount of Fei debt to repay for the Safe.
        uint256 feiAmount = feiTurboCToken.borrowBalanceCurrent(address(safe));

        emit ImpoundExecuted(msg.sender, safe, feiAmount, assetAmount);

        // Mint the Fei amount requested.
        fei.mint(address(this), feiAmount);

        // Repay the safe's Fei debt with the minted Fei, ensuring to catch cToken errors.
        require(feiTurboCToken.repayBorrowBehalf(address(safe), feiAmount) == 0, "REPAY_FAILED");

        // Impound all of the safe's collateral and send it to the chosen recipient.
        safe.gib(to, assetAmount);
    }
}