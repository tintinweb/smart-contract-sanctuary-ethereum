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

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

abstract contract AddressRegistry {
    address payable immutable WETH_9;
    address public immutable KP3R_V1;
    address public immutable KP3R_LP;
    address public immutable SWAP_ROUTER;
    address public immutable KEEP3R;
    address public immutable SUDOSWAP_FACTORY;
    address public immutable SUDOSWAP_CURVE;

    constructor() {
        address _weth;
        address _kp3rV1;
        address _kp3rLP;
        address _keep3r;
        address _uniswapRouter;
        address _sudoswapFactory;
        address _sudoswapCurve;

        uint256 _chainId = block.chainid;
        if (_chainId == 1 || _chainId == 31337) {
            _weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            _kp3rV1 = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44;
            _kp3rLP = 0x3f6740b5898c5D3650ec6eAce9a649Ac791e44D7;
            _keep3r = 0xeb02addCfD8B773A5FFA6B9d1FE99c566f8c44CC;
            _uniswapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
            _sudoswapFactory = 0xb16c1342E617A5B6E4b631EB114483FDB289c0A4;
            _sudoswapCurve = 0x7942E264e21C5e6CbBA45fe50785a15D3BEb1DA0;
        } else if (_chainId == 5) {
            _weth = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
            _kp3rV1 = 0x16F63C5036d3F48A239358656a8f123eCE85789C;
            _kp3rLP = 0xb4A7137B024d4C0531b0164fCb6E8fc20e6777Ae;
            _keep3r = 0x229d018065019c3164B899F4B9c2d4ffEae9B92b;
            _uniswapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
            _sudoswapFactory = 0xF0202E9267930aE942F0667dC6d805057328F6dC;
            _sudoswapCurve = 0x02363a2F1B2c2C5815cb6893Aa27861BE0c4F760;
        }

        WETH_9 = payable(_weth);
        KP3R_V1 = _kp3rV1;
        KP3R_LP = _kp3rLP;
        KEEP3R = _keep3r;
        SWAP_ROUTER = _uniswapRouter;
        SUDOSWAP_FACTORY = _sudoswapFactory;
        SUDOSWAP_CURVE = _sudoswapCurve;
    }
}

// SPDX-License-Identifier: MIT

/*

  by             .__________                 ___ ___
  __  _  __ ____ |__\_____  \  ___________  /   |   \_____    ______ ____
  \ \/ \/ // __ \|  | _(__  <_/ __ \_  __ \/    ~    \__  \  /  ___// __ \
   \     /\  ___/|  |/       \  ___/|  | \/\    Y    // __ \_\___ \\  ___/
    \/\_/  \___  >__/______  /\___  >__|    \___|_  /(____  /____  >\___  >
               \/          \/     \/              \/      \/     \/     \/*/

pragma solidity >=0.8.4 <0.9.0;

import {GameSchema} from './GameSchema.sol';
import {AddressRegistry} from './AddressRegistry.sol';

import {IButtPlug, IChess} from 'interfaces/IGame.sol';
import {IKeep3r, IKeep3rHelper, IPairManager} from 'interfaces/IKeep3r.sol';
import {LSSVMPair, LSSVMPairETH, ILSSVMPairFactory, ICurve, IERC721} from 'interfaces/ISudoswap.sol';
import {ISwapRouter} from 'interfaces/IUniswap.sol';

import {WETH} from 'solmate/tokens/WETH.sol';
import {ERC20} from 'solmate/tokens/ERC20.sol';
import {ERC721} from 'solmate/tokens/ERC721.sol';
import {SafeTransferLib} from 'solmate/utils/SafeTransferLib.sol';
import {FixedPointMathLib} from 'solmate/utils/FixedPointMathLib.sol';

/// @notice Contract will not be audited, proceed at your own risk
/// @dev THE_RABBIT will not be responsible for any loss of funds
contract ButtPlugWars is GameSchema, AddressRegistry, ERC721 {
    using SafeTransferLib for address payable;
    using FixedPointMathLib for uint256;

    /*///////////////////////////////////////////////////////////////
                            ADDRESS REGISTRY
    //////////////////////////////////////////////////////////////*/

    address public THE_RABBIT;
    address public nftDescriptor;
    address public immutable SUDOSWAP_POOL;

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /* IERC721 */
    address public immutable owner;

    /* NFT whitelisting mechanics */
    uint256 public immutable genesis;
    mapping(uint256 => bool) whitelistedToken;

    /*///////////////////////////////////////////////////////////////
                                  SETUP
    //////////////////////////////////////////////////////////////*/

    bool bunnySaysSo;

    uint32 immutable PERIOD;
    uint32 immutable COOLDOWN;

    constructor(
        string memory _name,
        address _masterOfCeremony,
        address _fiveOutOfNine,
        uint32 _period,
        uint32 _cooldown
    ) GameSchema(_fiveOutOfNine) ERC721(_name, unicode'{♙}') {
        THE_RABBIT = _masterOfCeremony;

        PERIOD = _period;
        COOLDOWN = _cooldown;

        // emit token aprovals
        ERC20(WETH_9).approve(SWAP_ROUTER, MAX_UINT);
        ERC20(KP3R_V1).approve(KP3R_LP, MAX_UINT);
        ERC20(WETH_9).approve(KP3R_LP, MAX_UINT);
        ERC20(KP3R_LP).approve(KEEP3R, MAX_UINT);

        // create Keep3r job
        IKeep3r(KEEP3R).addJob(address(this));

        // create Sudoswap pool
        SUDOSWAP_POOL = address(
            ILSSVMPairFactory(SUDOSWAP_FACTORY).createPairETH({
                _nft: IERC721(FIVE_OUT_OF_NINE),
                _bondingCurve: ICurve(SUDOSWAP_CURVE),
                _assetRecipient: payable(address(this)),
                _poolType: LSSVMPair.PoolType.NFT,
                _spotPrice: 59000000000000000, // 0.059 ETH
                _delta: 1,
                _fee: 0,
                _initialNFTIDs: new uint256[](0)
            })
        );

        // set the owner of the ERC721 for royalties
        owner = THE_RABBIT;
        canStartSales = block.timestamp + 2 * PERIOD;

        // mint scoreboard token to itself
        _mint(address(this), 0);
        // records supply of fiveOutOfNine to whitelist pre-genesis tokens
        genesis = ERC20(FIVE_OUT_OF_NINE).totalSupply();
    }

    /// @notice Permissioned method, allows rabbit to cancel or early-finish the event
    function saySo() external onlyRabbit {
        if (state == STATE.ANNOUNCEMENT) state = STATE.CANCELLED;
        else bunnySaysSo = true;
    }

    /// @notice Permissioned method, allows rabbit to revoke all permissions
    function suicideRabbit() external onlyRabbit {
        delete THE_RABBIT;
    }

    /// @notice Handles rabbit authorized methods
    modifier onlyRabbit() {
        if (msg.sender != THE_RABBIT) revert WrongMethod();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            BADGE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows the signer to mint a Player NFT, bonding a 5/9 and paying ETH price
    /// @param _tokenId Token ID of the FiveOutOfNine to bond
    /// @return _badgeId Token ID of the minted player badge
    function mintPlayerBadge(uint256 _tokenId) external payable returns (uint256 _badgeId) {
        if (state < STATE.TICKET_SALE || state >= STATE.GAME_OVER) revert WrongTiming();

        if (!isWhitelistedToken(_tokenId)) revert WrongNFT(); // token must be pre-genesis or whitelisted

        uint256 _value = msg.value;
        if (_value < 0.05 ether || _value > 1 ether) revert WrongValue();
        uint256 _weight = _value.sqrt(); // weight is defined by sqrt(msg.value)

        // players can only mint badges from the non-playing team
        TEAM _team = TEAM(((_roundT(block.timestamp, PERIOD) / PERIOD) + 1) % 2);
        // a player cannot be minted for a soon-to-win team
        if (matchesWon[_team] == 4) revert WrongTeam();

        _badgeId = _calcPlayerBadge(_tokenId, _team, _weight);

        // msg.sender must approve the FiveOutOfNine transfer
        ERC721(FIVE_OUT_OF_NINE).safeTransferFrom(msg.sender, address(this), _tokenId);
        _mint(msg.sender, _badgeId); // msg.sender supports ERC721, as it had a 5/9
    }

    /// @notice Allows the signer to register a ButtPlug NFT
    /// @param _buttPlug Address of the buttPlug to register
    /// @return _badgeId Token ID of the minted buttPlug badge
    function mintButtPlugBadge(address _buttPlug) external returns (uint256 _badgeId) {
        if ((state < STATE.TICKET_SALE) || (state >= STATE.GAME_OVER)) revert WrongTiming();

        // buttPlug contract must have an owner view method
        address _owner = IButtPlug(_buttPlug).owner();

        _badgeId = _calcButtPlugBadge(_buttPlug, TEAM.BUTTPLUG);
        _safeMint(_owner, _badgeId);
    }

    /// @notice Allows player to melt badges weight and score into a Medal NFT
    /// @param _badgeIds Array of token IDs of badges to submit
    /// @return _badgeId Token ID of the minted medal badge
    function mintMedal(uint256[] memory _badgeIds) external returns (uint256 _badgeId) {
        if (state != STATE.PREPARATIONS) revert WrongTiming();
        uint256 _totalWeight;
        uint256 _totalScore;

        uint256 _weight;
        uint256 _score;
        bytes32 _salt;
        for (uint256 _i; _i < _badgeIds.length; _i++) {
            _badgeId = _badgeIds[_i];
            (_weight, _score) = _processBadge(_badgeId);
            _totalWeight += _weight;
            _totalScore += _score;
            _salt = keccak256(abi.encodePacked(_salt, _badgeId));
        }

        // adds weight and score to state vars
        totalScore += _totalScore;
        totalWeight += _totalWeight;

        _badgeId = _calcMedalBadge(_totalWeight, _totalScore, _salt);

        emit MedalMinted(_badgeId, _salt, _badgeIds, _totalScore);
        _mint(msg.sender, _badgeId); // msg.sender supports ERC721, as it had a badge
    }

    function _processBadge(uint256 _badgeId) internal returns (uint256 _weight, uint256 _score) {
        TEAM _team = _getBadgeType(_badgeId);
        if (_team > TEAM.BUTTPLUG) revert WrongTeam();

        // if bunny says so, all badges are winners
        if (matchesWon[_team] >= 5 || bunnySaysSo) _weight = _getBadgeWeight(_badgeId);

        // only positive score is accounted
        int256 _badgeScore = _calcScore(_badgeId);
        _score = _badgeScore >= 0 ? uint256(_badgeScore) : 1;

        // msg.sender should be the owner
        transferFrom(msg.sender, address(this), _badgeId);
        _returnNftIfStaked(_badgeId);
    }

    /// @notice Allow players who claimed prize to withdraw their rewards
    /// @param _badgeId Token ID of the medal badge to claim rewards from
    function withdrawRewards(uint256 _badgeId) external onlyBadgeAllowed(_badgeId) {
        if (state != STATE.PRIZE_CEREMONY) revert WrongTiming();
        if (_getBadgeType(_badgeId) != TEAM.MEDAL) revert WrongTeam();

        uint256 _claimableSales = totalSales.mulDivDown(_getMedalScore(_badgeId), totalScore);
        uint256 _claimed = claimedSales[_badgeId];
        uint256 _claimable = _claimableSales - _claimed;

        // liquidity prize should be withdrawn only once per medal
        if (_claimed == 0) {
            ERC20(KP3R_LP).transfer(msg.sender, totalPrize.mulDivDown(_getBadgeWeight(_badgeId), totalWeight));
            claimedSales[_badgeId]++;
        }

        // sales prize can be re-claimed as pool sales increase
        claimedSales[_badgeId] += _claimable;
        payable(msg.sender).safeTransferETH(_claimable);
    }

    /// @notice Allows players who didn't mint a medal to withdraw their staked NFTs
    /// @param _badgeId Token ID of the player badge to withdraw the staked NFT from
    function withdrawStakedNft(uint256 _badgeId) external onlyBadgeAllowed(_badgeId) {
        if (state != STATE.PRIZE_CEREMONY) revert WrongTiming();
        _returnNftIfStaked(_badgeId);
    }

    function _returnNftIfStaked(uint256 _badgeId) internal {
        if (_getBadgeType(_badgeId) < TEAM.BUTTPLUG) {
            uint256 _tokenId = _getStakedToken(_badgeId);
            ERC721(FIVE_OUT_OF_NINE).safeTransferFrom(address(this), msg.sender, _tokenId);
        }
    }

    /// @notice Handles badge authorized methods
    modifier onlyBadgeAllowed(uint256 _badgeId) {
        address _sender = msg.sender;
        address _owner = _ownerOf[_badgeId];
        if (_owner != _sender && !isApprovedForAll[_owner][_sender] && _sender != getApproved[_badgeId]) {
            revert WrongBadge();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            ROADMAP MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Open method, allows signer to start ticket sale
    function startEvent() external {
        uint256 _timestamp = block.timestamp;
        if ((state != STATE.ANNOUNCEMENT) || (_timestamp < canStartSales)) revert WrongTiming();

        canPushLiquidity = _timestamp + 2 * PERIOD;
        state = STATE.TICKET_SALE;
    }

    /// @notice Open method, allows signer to swap ETH => KP3R, mints kLP and adds to job
    function pushLiquidity() external {
        uint256 _timestamp = block.timestamp;
        if (state >= STATE.GAME_OVER || _timestamp < canPushLiquidity) revert WrongTiming();
        if (state == STATE.TICKET_SALE) {
            state = STATE.GAME_RUNNING;
            canPlayNext = _timestamp + COOLDOWN;
            ++matchNumber;
        }

        uint256 _eth = address(this).balance - totalSales;
        if (_eth < 0.05 ether) revert WrongTiming();
        WETH(WETH_9).deposit{value: _eth}();

        address _keep3rHelper = IKeep3r(KEEP3R).keep3rHelper();
        uint256 _quote = IKeep3rHelper(_keep3rHelper).quote(_eth / 2);

        ISwapRouter.ExactInputSingleParams memory _params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH_9,
            tokenOut: KP3R_V1,
            fee: 10_000,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _eth / 2,
            amountOutMinimum: _quote.mulDivDown(95, 100),
            sqrtPriceLimitX96: 0
        });
        ISwapRouter(SWAP_ROUTER).exactInputSingle(_params);

        uint256 wethBalance = ERC20(WETH_9).balanceOf(address(this));
        uint256 kp3rBalance = ERC20(KP3R_V1).balanceOf(address(this));

        uint256 kLPBalance = IPairManager(KP3R_LP).mint(kp3rBalance, wethBalance, 0, 0, address(this));
        IKeep3r(KEEP3R).addLiquidityToJob(address(this), KP3R_LP, kLPBalance);

        totalPrize += kLPBalance;
        canPushLiquidity = _timestamp + PERIOD;
    }

    /// @notice Open method, allows signer (after game ended) to start unbond period
    function unbondLiquidity() external {
        if (state != STATE.GAME_OVER) revert WrongTiming();
        totalPrize = IKeep3r(KEEP3R).liquidityAmount(address(this), KP3R_LP);
        IKeep3r(KEEP3R).unbondLiquidityFromJob(address(this), KP3R_LP, totalPrize);
        state = STATE.PREPARATIONS;
    }

    /// @notice Open method, allows signer (after unbonding) to withdraw all staked kLPs
    function withdrawLiquidity() external {
        if (state != STATE.PREPARATIONS) revert WrongTiming();
        // Method reverts unless 2w cooldown since unbond tx
        IKeep3r(KEEP3R).withdrawLiquidityFromJob(address(this), KP3R_LP, address(this));
        state = STATE.PRIZE_CEREMONY;
    }

    /// @notice Open method, allows signer (after game is over) to reduce pool spotPrice
    function updateSpotPrice() external {
        uint256 _timestamp = block.timestamp;
        if (state <= STATE.GAME_OVER || _timestamp < canUpdateSpotPriceNext) revert WrongTiming();

        canUpdateSpotPriceNext = _timestamp + PERIOD;
        _increaseSudoswapDelta();
    }

    /// @notice Handles Keep3r mechanism and payment
    modifier upkeep(address _keeper) {
        if (!IKeep3r(KEEP3R).isKeeper(_keeper) || ERC20(FIVE_OUT_OF_NINE).balanceOf(_keeper) < matchNumber) {
            revert WrongKeeper();
        }
        _;
        IKeep3r(KEEP3R).worked(_keeper);
    }

    /*///////////////////////////////////////////////////////////////
                            GAME MECHANICS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether the executeMove method could be called
    /// @dev The view function can return true, but still not be workable because of credits
    function workable() external view returns (bool) {
        uint256 _timestamp = block.timestamp;
        if ((state != STATE.GAME_RUNNING) || (_timestamp < canPlayNext)) return false;
        return true;
    }

    /// @notice Called by keepers to execute the next move
    function executeMove() external upkeep(msg.sender) {
        uint256 _timestamp = block.timestamp;
        uint256 _periodStart = _roundT(_timestamp, PERIOD);
        if ((state != STATE.GAME_RUNNING) || (_timestamp < canPlayNext)) revert WrongTiming();

        TEAM _team = TEAM((_periodStart / PERIOD) % 2);
        address _buttPlug = buttPlug[_team];

        if (_buttPlug == address(0)) {
            // if team does not have a buttplug, skip turn
            canPlayNext = _periodStart + PERIOD;
            return;
        }

        uint256 _votes = votes[_team][_buttPlug];
        uint256 _buttPlugBadgeId = _calcButtPlugBadge(_buttPlug, _team);

        int8 _score;
        bool _isCheckmate;

        uint256 _board = IChess(FIVE_OUT_OF_NINE).board();
        // gameplay is wrapped in a try/catch block to punish reverts
        try ButtPlugWars(this).playMove(_board, _buttPlug) {
            uint256 _newBoard = IChess(FIVE_OUT_OF_NINE).board();
            _isCheckmate = _newBoard == CHECKMATE;
            if (_isCheckmate) {
                _score = 3;
                canPlayNext = _periodStart + PERIOD;
            } else {
                _score = _calcMoveScore(_board, _newBoard);
                canPlayNext = _timestamp + COOLDOWN;
            }
        } catch {
            // if buttplug or move reverts
            _score = -2;
            canPlayNext = _periodStart + PERIOD;
        }

        matchScore[_team] += _score;
        score[_buttPlugBadgeId] += _score * int256(_votes);

        // each match is limited to 69 moves
        emit MoveExecuted(_team, _buttPlug, _score, uint64(_votes));
        if (_isCheckmate || ++matchMoves >= 69 || bunnySaysSo) _checkMateRoutine();
    }

    /// @notice Externally called to try catch
    function playMove(uint256 _board, address _buttPlug) external {
        if (msg.sender != address(this)) revert WrongMethod();

        uint256 _move = IButtPlug(_buttPlug).readMove{gas: _getGas()}(_board);
        uint256 _depth = _getDepth(_board, msg.sender);
        IChess(FIVE_OUT_OF_NINE).mintMove(_move, _depth);
    }

    function _checkMateRoutine() internal {
        if (matchScore[TEAM.ZERO] >= matchScore[TEAM.ONE]) matchesWon[TEAM.ZERO]++;
        if (matchScore[TEAM.ONE] >= matchScore[TEAM.ZERO]) matchesWon[TEAM.ONE]++;

        delete matchMoves;
        delete matchScore[TEAM.ZERO];
        delete matchScore[TEAM.ONE];

        // verifies if game has ended
        if (_isGameOver()) {
            state = STATE.GAME_OVER;
            // all remaining ETH will be considered to distribute as sales
            totalSales = address(this).balance;
            canPlayNext = MAX_UINT;
            return;
        }
    }

    function _isGameOver() internal view returns (bool) {
        // if bunny says so, current match was the last one
        return matchesWon[TEAM.ZERO] == 5 || matchesWon[TEAM.ONE] == 5 || bunnySaysSo;
    }

    function _roundT(uint256 _timestamp, uint256 _period) internal pure returns (uint256 _roundTimestamp) {
        _roundTimestamp = _timestamp - (_timestamp % _period);
    }

    /// @notice Adds +2 when eating a black piece, and substracts 1 when a white piece is eaten
    /// @dev Supports having more pieces than before, situation that should not be possible in production
    function _calcMoveScore(uint256 _previousBoard, uint256 _newBoard) internal pure returns (int8 _score) {
        (int8 _whitePiecesBefore, int8 _blackPiecesBefore) = _countPieces(_previousBoard);
        (int8 _whitePiecesAfter, int8 _blackPiecesAfter) = _countPieces(_newBoard);

        _score += 2 * (_blackPiecesBefore - _blackPiecesAfter);
        _score -= _whitePiecesBefore - _whitePiecesAfter;
    }

    /// @dev Efficiently loops through the board uint256 to search for pieces and count each color
    function _countPieces(uint256 _board) internal pure returns (int8 _whitePieces, int8 _blackPieces) {
        uint256 _space;
        for (uint256 i = MAGIC_NUMBER; i != 0; i >>= 6) {
            _space = (_board >> ((i & 0x3F) << 2)) & 0xF;
            if (_space == 0) continue;
            _space >> 3 == 1 ? _whitePieces++ : _blackPieces++;
        }
    }

    function _getGas() internal view returns (uint256 _gas) {
        return BUTT_PLUG_GAS_LIMIT - matchNumber * BUTT_PLUG_GAS_DELTA;
    }

    function _getDepth(uint256 _salt, address _keeper) internal view virtual returns (uint256 _depth) {
        uint256 _timeVariable = _roundT(block.timestamp, COOLDOWN);
        _depth = 3 + uint256(keccak256(abi.encode(_salt, _keeper, _timeVariable))) % 8;
    }

    /*///////////////////////////////////////////////////////////////
                            VOTE MECHANICS
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows players to vote for their preferred ButtPlug
    /// @param _buttPlug Address of the buttPlug to vote for
    /// @param _badgeId Token ID of the player badge to vote with
    function voteButtPlug(address _buttPlug, uint256 _badgeId) external {
        if (_buttPlug == address(0)) revert WrongValue();
        _voteButtPlug(_buttPlug, _badgeId);
    }

    /// @notice Allows players to batch vote for their preferred ButtPlug
    /// @param _buttPlug Address of the buttPlug to vote for
    /// @param _badgeIds Array of token IDs of the player badges to vote with
    function voteButtPlug(address _buttPlug, uint256[] memory _badgeIds) external {
        if (_buttPlug == address(0)) revert WrongValue();
        for (uint256 _i; _i < _badgeIds.length; _i++) {
            _voteButtPlug(_buttPlug, _badgeIds[_i]);
        }
    }

    function _voteButtPlug(address _buttPlug, uint256 _badgeId) internal onlyBadgeAllowed(_badgeId) {
        TEAM _team = _getBadgeType(_badgeId);
        if (_team >= TEAM.BUTTPLUG) revert WrongTeam();

        uint256 _weight = _getBadgeWeight(_badgeId);
        uint256 _previousVote = voteData[_badgeId];
        if (_previousVote != 0) {
            votes[_team][_getVoteAddress(_previousVote)] -= _weight;
            score[_badgeId] = _calcScore(_badgeId);
        }

        votes[_team][_buttPlug] += _weight;
        uint256 _voteParticipation = _weight.sqrt().mulDivDown(BASE, votes[_team][_buttPlug].sqrt());
        voteData[_badgeId] = _calcVoteData(_buttPlug, _voteParticipation);

        uint256 _buttPlugBadgeId = _calcButtPlugBadge(_buttPlug, _team);
        lastUpdatedScore[_badgeId][_buttPlugBadgeId] = score[_buttPlugBadgeId];

        emit VoteSubmitted(_team, _badgeId, _buttPlug);
        if (votes[_team][_buttPlug] > votes[_team][buttPlug[_team]]) buttPlug[_team] = _buttPlug;
    }

    /*///////////////////////////////////////////////////////////////
                                ERC721
    //////////////////////////////////////////////////////////////*/

    function onERC721Received(address, address _from, uint256 _id, bytes calldata) external returns (bytes4) {
        // only FiveOutOfNine tokens should be safeTransferred to contract
        if (msg.sender != FIVE_OUT_OF_NINE) revert WrongNFT();
        // if token is newly minted transfer to sudoswap pool
        if (_from == address(0)) {
            whitelistedToken[_id] = true;
            ERC721(FIVE_OUT_OF_NINE).safeTransferFrom(address(this), SUDOSWAP_POOL, _id);
            _increaseSudoswapDelta();
        }

        return 0x150b7a02;
    }

    /// @notice Calculates if the FiveOutOfNine token is whitelisted to play
    /// @param _id Token ID of the enquired FiveOutOfNine
    /// @return _isWhitelisted Whether the token is whitelisted or not
    function isWhitelistedToken(uint256 _id) public view returns (bool _isWhitelisted) {
        return _id < genesis || whitelistedToken[_id];
    }

    function _increaseSudoswapDelta() internal {
        uint128 _currentDelta = LSSVMPair(SUDOSWAP_POOL).delta();
        LSSVMPair(SUDOSWAP_POOL).changeDelta(++_currentDelta);
    }

    /*///////////////////////////////////////////////////////////////
                          DELEGATE TOKEN URI
    //////////////////////////////////////////////////////////////*/

    /// @notice Routes tokenURI calculation through a static-delegatecall
    function tokenURI(uint256 _badgeId) public view virtual override returns (string memory) {
        if (_ownerOf[_badgeId] == address(0)) revert WrongNFT();
        (bool _success, bytes memory _data) =
            address(this).staticcall(abi.encodeWithSignature('_tokenURI(uint256)', _badgeId));

        assembly {
            switch _success
            // delegatecall returns 0 on error.
            case 0 { revert(add(_data, 32), returndatasize()) }
            default { return(add(_data, 32), returndatasize()) }
        }
    }

    function _tokenURI(uint256) external {
        if (msg.sender != address(this)) revert WrongMethod();

        (bool _success, bytes memory _data) = address(nftDescriptor).delegatecall(msg.data);
        assembly {
            switch _success
            // delegatecall returns 0 on error.
            case 0 { revert(add(_data, 32), returndatasize()) }
            default { return(add(_data, 32), returndatasize()) }
        }
    }

    /// @notice Permissioned method, allows rabbit to change the nftDescriptor address
    function setNftDescriptor(address _nftDescriptor) external onlyRabbit {
        nftDescriptor = _nftDescriptor;
    }

    /*///////////////////////////////////////////////////////////////
                                RECEIVE
    //////////////////////////////////////////////////////////////*/

    /// @notice Method called by sudoswap pool on each sale
    receive() external payable {
        if (msg.sender == SUDOSWAP_POOL) totalSales += msg.value;
        return;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import {ButtPlugWars} from './ButtPlugWars.sol';

contract ChessOlympiads is ButtPlugWars {
    address constant _FIVE_OUT_OF_NINE = 0xB543F9043b387cE5B3d1F0d916E42D8eA2eBA2E0;

    constructor(address _masterOfCeremony)
        ButtPlugWars('ChessOlympiads', _masterOfCeremony, _FIVE_OUT_OF_NINE, 5 days, 4 hours)
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

abstract contract GameSchema {
    error WrongMethod(); // method should not be externally called
    error WrongTiming(); // method called at wrong roadmap state or cooldown
    error WrongKeeper(); // keeper doesn't fulfill the required params
    error WrongValue(); // badge minting value should be between 0.05 and 1
    error WrongBadge(); // only the badge owner or allowed can access
    error WrongTeam(); // only specific badges can access
    error WrongNFT(); // an unknown NFT was sent to the contract

    event VoteSubmitted(TEAM _team, uint256 _badgeId, address _buttPlug);
    event MoveExecuted(TEAM _team, address _buttPlug, int8 _moveScore, uint64 _weight);
    event MedalMinted(uint256 _badgeId, bytes32 _seed, uint256[] _badges, uint256 _totalScore);

    address public immutable FIVE_OUT_OF_NINE;

    constructor(address _fiveOutOfNine) {
        FIVE_OUT_OF_NINE = _fiveOutOfNine;
    }

    uint256 constant BASE = 10_000;
    uint256 constant MAX_UINT = type(uint256).max;
    uint256 constant CHECKMATE = 0x3256230011111100000000000000000099999900BCDECB000000001; // new board
    uint256 constant MAGIC_NUMBER = 0xDB5D33CB1BADB2BAA99A59238A179D71B69959551349138D30B289; // by @fiveOutOfNine
    uint256 constant BUTT_PLUG_GAS_LIMIT = 10_000_000; // amount of gas used to read buttPlug moves
    uint256 constant BUTT_PLUG_GAS_DELTA = 1_000_000; // gas reduction per match to read buttPlug moves

    enum STATE {
        ANNOUNCEMENT, // rabbit can cancel event
        TICKET_SALE, // can mint badges
        GAME_RUNNING, // game runs, can mint badges
        GAME_OVER, // game stops, can unbondLiquidity
        PREPARATIONS, // can mint medals, waits until kLPs are unbonded
        PRIZE_CEREMONY, // can withdraw prizes
        CANCELLED // a critical bug was found
    }

    STATE public state = STATE.ANNOUNCEMENT;

    uint256 canStartSales; // can startEvent()
    uint256 canPlayNext; // can executeMove()
    uint256 canPushLiquidity; // can pushLiquidity()
    uint256 canUpdateSpotPriceNext; // can updateSpotPrice()

    enum TEAM {
        ZERO,
        ONE,
        BUTTPLUG,
        MEDAL,
        SCOREBOARD
    }

    /*///////////////////////////////////////////////////////////////
                            GAME VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(TEAM => uint256) matchesWon; // amount of matches won by each team
    mapping(TEAM => int256) matchScore; // current match score for each team
    uint256 matchNumber; // amount of matches started
    uint256 matchMoves; // amount of moves made on current match

    /* Badge mechanics */
    uint256 totalPlayers; // amount of player badges minted

    /* Vote mechanics */
    mapping(uint256 => uint256) voteData; // player -> vote data
    mapping(TEAM => address) buttPlug; // team -> most-voted buttPlug
    mapping(TEAM => mapping(address => uint256)) votes; // team -> buttPlug -> votes

    /* Prize mechanics */
    uint256 totalPrize; // total amount of kLPs minted as liquidity
    uint256 totalSales; // total amount of ETH from sudoswap sales
    uint256 totalWeight; // total weigth of minted medals
    uint256 totalScore; // total score of minted medals
    mapping(uint256 => uint256) claimedSales; // medal -> amount of ETH already claimed

    mapping(uint256 => int256) score; // badge -> score record (see _calcScore)
    mapping(uint256 => mapping(uint256 => int256)) lastUpdatedScore; // badge -> buttPlug -> lastUpdated score

    /* Badge mechanics */

    function _getBadgeType(uint256 _badgeId) internal pure returns (TEAM) {
        return TEAM(uint8(_badgeId));
    }

    /* Players */

    /// @dev Non-view method, increases totalPlayers
    function _calcPlayerBadge(uint256 _tokenId, TEAM _team, uint256 _weight) internal returns (uint256 _badgeId) {
        return (++totalPlayers << 96) + (_weight << 32) + (_tokenId << 8) + uint256(_team);
    }

    function _getStakedToken(uint256 _badgeId) internal pure returns (uint256 _tokenId) {
        return uint16(_badgeId >> 8);
    }

    function _getBadgeWeight(uint256 _badgeId) internal pure returns (uint256 _weight) {
        return uint64(_badgeId >> 32);
    }

    function _getPlayerNumber(uint256 _badgeId) internal pure returns (uint256 _playerNumber) {
        return uint16(_badgeId >> 96);
    }

    /* ButtPlugs */

    function _calcButtPlugBadge(address _buttPlug, TEAM _team) internal pure returns (uint256 _badgeId) {
        return (uint256(uint160(_buttPlug)) << 96) + uint256(_team);
    }

    function _getButtPlugAddress(uint256 _badgeId) internal pure returns (address _buttPlug) {
        return address(uint160(_badgeId >> 96));
    }

    /* Medals */

    function _calcMedalBadge(uint256 _totalWeight, uint256 _totalScore, bytes32 _salt)
        internal
        pure
        returns (uint256 _badgeId)
    {
        return (_totalScore << 96) + (_totalWeight << 32) + uint32(uint256(_salt) << 8) + uint256(TEAM.MEDAL);
    }

    function _getMedalScore(uint256 _badgeId) internal pure returns (uint256 _score) {
        return uint64(_badgeId >> 96);
    }

    function _getMedalSalt(uint256 _badgeId) internal pure returns (uint256 _salt) {
        return uint24(_badgeId >> 8);
    }

    /* Vote mechanism */

    function _calcVoteData(address _buttPlug, uint256 _voteParticipation) internal pure returns (uint256 _voteData) {
        return (_voteParticipation << 160) + uint160(_buttPlug);
    }

    function _getVoteAddress(uint256 _vote) internal pure returns (address _voteAddress) {
        return address(uint160(_vote));
    }

    function _getVoteParticipation(uint256 _vote) internal pure returns (uint256 _voteParticipation) {
        return uint256(_vote >> 160);
    }

    /* Score mechanism */

    function _calcScore(uint256 _badgeId) internal view returns (int256 _score) {
        TEAM _team = _getBadgeType(_badgeId);
        if (_team < TEAM.BUTTPLUG) {
            // player badge
            uint256 _previousVote = voteData[_badgeId];
            address _votedButtPlug = _getVoteAddress(_previousVote);
            uint256 _voteParticipation = _getVoteParticipation(_previousVote);
            uint256 _votedButtPlugBadge = _calcButtPlugBadge(_votedButtPlug, _team);

            int256 _lastVoteScore = score[_votedButtPlugBadge] - lastUpdatedScore[_badgeId][_votedButtPlugBadge];
            if (_lastVoteScore >= 0) {
                return score[_badgeId] + int256((uint256(_lastVoteScore) * _voteParticipation) / BASE);
            } else {
                return score[_badgeId] - int256((uint256(-_lastVoteScore) * _voteParticipation) / BASE);
            }
        } else if (_team == TEAM.BUTTPLUG) {
            // buttplug badge
            address _buttPlug = _getButtPlugAddress(_badgeId);
            uint256 _buttPlugZERO = _calcButtPlugBadge(_buttPlug, TEAM.ZERO);
            uint256 _buttPlugONE = _calcButtPlugBadge(_buttPlug, TEAM.ONE);
            return score[_buttPlugZERO] + score[_buttPlugONE];
        } else {
            // medal badge
            return int256(_getMedalScore(_badgeId));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IButtPlug {
    function readMove(uint256 _board) external view returns (uint256 _move);

    function owner() external view returns (address _owner);
}

interface IChess {
    function mintMove(uint256 _move, uint256 _depth) external payable;

    function board() external view returns (uint256 _board);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

// import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';

interface IPairManager {
    function mint(uint256, uint256, uint256, uint256, address) external returns (uint128);
}

interface IKeep3rHelper {
    function quote(uint256) external view returns (uint256);
}

interface IKeep3r {
    function keep3rV1() external view returns (address);

    function keep3rHelper() external view returns (address);

    function addJob(address) external;

    function isKeeper(address) external returns (bool);

    function worked(address) external;

    function bond(address, uint256) external;

    function activate(address) external;

    function liquidityAmount(address, address) external view returns (uint256);

    function jobPeriodCredits(address) external view returns (uint256);

    function addLiquidityToJob(address, address, uint256) external;

    function unbondLiquidityFromJob(address, address, uint256) external;

    function withdrawLiquidityFromJob(address, address, address) external;

    function canWithdrawAfter(address, address) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IERC721 {}

interface ICurve {}

interface LSSVMPair {
    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

    function changeSpotPrice(uint128 newSpotPrice) external;
    function spotPrice() external view returns (uint128 spotPrice);
    function changeDelta(uint128 newDelta) external;
    function delta() external view returns (uint128 delta);
}

interface LSSVMPairETH is LSSVMPair {
    function withdrawAllETH() external;
}

interface ILSSVMPairFactory {
    function createPairETH(
        IERC721 _nft,
        ICurve _bondingCurve,
        address payable _assetRecipient,
        LSSVMPair.PoolType _poolType,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] calldata _initialNFTIDs
    ) external payable returns (LSSVMPairETH pair);
}

interface ILSSVMRouter {
    struct PairSwapAny {
        LSSVMPair pair;
        uint256 numItems;
    }

    function swapETHForAnyNFTs(
        PairSwapAny[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable returns (uint256 remainingValue);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4 <0.9.0;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}