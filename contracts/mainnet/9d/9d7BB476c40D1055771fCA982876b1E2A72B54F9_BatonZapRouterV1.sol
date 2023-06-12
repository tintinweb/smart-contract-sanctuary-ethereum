/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

// ReentrancyGuard

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

// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// Inspired by https://github.com/ZeframLou/trustus
abstract contract ReservoirOracle {
    // --- Structs ---

    struct Message {
        bytes32 id;
        bytes payload;
        // The UNIX timestamp when the message was signed by the oracle
        uint256 timestamp;
        // ECDSA signature or EIP-2098 compact signature
        bytes signature;
    }

    // --- Errors ---

    error InvalidMessage();

    // --- Fields ---

    address public RESERVOIR_ORACLE_ADDRESS;

    // --- Constructor ---

    constructor(address reservoirOracleAddress) {
        RESERVOIR_ORACLE_ADDRESS = reservoirOracleAddress;
    }

    // --- Public methods ---

    function updateReservoirOracleAddress(address newReservoirOracleAddress)
        public
        virtual;

    // --- Internal methods ---

    function _verifyMessage(
        bytes32 id,
        uint256 validFor,
        Message memory message
    ) internal view virtual returns (bool success) {
        // Ensure the message matches the requested id
        if (id != message.id) {
            return false;
        }

        // Ensure the message timestamp is valid
        if (
            message.timestamp > block.timestamp ||
            message.timestamp + validFor < block.timestamp
        ) {
            return false;
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Extract the individual signature fields from the signature
        bytes memory signature = message.signature;
        if (signature.length == 64) {
            // EIP-2098 compact signature
            bytes32 vs;
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
                s := and(
                    vs,
                    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                v := add(shr(255, vs), 27)
            }
        } else if (signature.length == 65) {
            // ECDSA signature
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else {
            return false;
        }

        address signerAddress = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    // EIP-712 structured-data hash
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Message(bytes32 id,bytes payload,uint256 timestamp)"
                            ),
                            message.id,
                            keccak256(message.payload),
                            message.timestamp
                        )
                    )
                )
            ),
            v,
            r,
            s
        );

        // Ensure the signer matches the designated oracle address
        return signerAddress == RESERVOIR_ORACLE_ADDRESS;
    }
}

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

/// @title LP token
/// @author out.eth (@outdoteth)
/// @notice LP token which is minted and burned by the Pair contract to represent liquidity in the pool.
contract LpToken is Owned, ERC20 {
    constructor(string memory pairSymbol)
        Owned(msg.sender)
        ERC20(string.concat(pairSymbol, " LP token"), string.concat("LP-", pairSymbol), 18)
    {}

    /// @notice Mints new LP tokens to the given address.
    /// @param to The address to mint to.
    /// @param amount The amount to mint.
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /// @notice Burns LP tokens from the given address.
    /// @param from The address to burn from.
    /// @param amount The amount to burn.
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// modified from https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/SafeERC20Namer.sol
// produces token descriptors from inconsistent or absent ERC20 symbol implementations that can return string or bytes32
// this library will always produce a string symbol to represent the token
library SafeERC20Namer {
    function bytes32ToString(bytes32 x) private pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint256 charCount = 0;
        for (uint256 j = 0; j < 32; j++) {
            bytes1 char = x[j];
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }

        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }

        return string(bytesStringTrimmed);
    }

    // uses a heuristic to produce a token name from the address
    // the heuristic returns the full hex of the address string
    function addressToName(address token) private pure returns (string memory) {
        return Strings.toHexString(uint160(token));
    }

    // uses a heuristic to produce a token symbol from the address
    // the heuristic returns the first 4 hex of the address string
    function addressToSymbol(address token) private pure returns (string memory) {
        return Strings.toHexString(uint160(token) >> (160 - 4 * 4));
    }

    // calls an external view token contract method that returns a symbol or name, and parses the output into a string
    function callAndParseStringReturn(address token, bytes4 selector) private view returns (string memory) {
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(selector));
        // if not implemented, or returns empty data, return empty string
        if (!success || data.length == 0) {
            return "";
        }
        // bytes32 data always has length 32
        if (data.length == 32) {
            bytes32 decoded = abi.decode(data, (bytes32));
            return bytes32ToString(decoded);
        } else if (data.length > 64) {
            return abi.decode(data, (string));
        }
        return "";
    }

    // attempts to extract the token symbol. if it does not implement symbol, returns a symbol derived from the address
    function tokenSymbol(address token) internal view returns (string memory) {
        // 0x95d89b41 = bytes4(keccak256("symbol()"))
        string memory symbol = callAndParseStringReturn(token, 0x95d89b41);
        if (bytes(symbol).length == 0) {
            // fallback to 6 uppercase hex of address
            return addressToSymbol(token);
        }
        return symbol;
    }

    // attempts to extract the token name. if it does not implement name, returns a name derived from the address
    function tokenName(address token) internal view returns (string memory) {
        // 0x06fdde03 = bytes4(keccak256("name()"))
        string memory name = callAndParseStringReturn(token, 0x06fdde03);
        if (bytes(name).length == 0) {
            // fallback to full hex of address
            return addressToName(token);
        }

        return name;
    }
}

/// @title caviar.sh
/// @author out.eth (@outdoteth)
/// @notice An AMM for creating and trading fractionalized NFTs.
contract Caviar is Owned {
    using SafeERC20Namer for address;

    /// @dev pairs[nft][baseToken][merkleRoot] -> pair
    mapping(address => mapping(address => mapping(bytes32 => address))) public pairs;

    /// @dev The stolen nft filter oracle address
    address public stolenNftFilterOracle;

    event SetStolenNftFilterOracle(address indexed stolenNftFilterOracle);
    event Create(address indexed nft, address indexed baseToken, bytes32 indexed merkleRoot);
    event Destroy(address indexed nft, address indexed baseToken, bytes32 indexed merkleRoot);

    constructor(address _stolenNftFilterOracle) Owned(msg.sender) {
        stolenNftFilterOracle = _stolenNftFilterOracle;
    }

    /// @notice Sets the stolen nft filter oracle address.
    /// @param _stolenNftFilterOracle The stolen nft filter oracle address.
    function setStolenNftFilterOracle(address _stolenNftFilterOracle) public onlyOwner {
        stolenNftFilterOracle = _stolenNftFilterOracle;
        emit SetStolenNftFilterOracle(_stolenNftFilterOracle);
    }

    /// @notice Creates a new pair.
    /// @param nft The NFT contract address.
    /// @param baseToken The base token contract address.
    /// @param merkleRoot The merkle root for the valid tokenIds.
    /// @return pair The address of the new pair.
    function create(address nft, address baseToken, bytes32 merkleRoot) public returns (Pair pair) {
        // check that the pair doesn't already exist
        require(pairs[nft][baseToken][merkleRoot] == address(0), "Pair already exists");
        require(nft.code.length > 0, "Invalid NFT contract");
        require(baseToken.code.length > 0 || baseToken == address(0), "Invalid base token contract");

        // deploy the pair
        string memory baseTokenSymbol = baseToken == address(0) ? "ETH" : baseToken.tokenSymbol();
        string memory nftSymbol = nft.tokenSymbol();
        string memory nftName = nft.tokenName();
        string memory pairSymbol = string.concat(nftSymbol, ":", baseTokenSymbol);
        pair = new Pair(nft, baseToken, merkleRoot, pairSymbol, nftName, nftSymbol);

        // save the pair
        pairs[nft][baseToken][merkleRoot] = address(pair);

        emit Create(nft, baseToken, merkleRoot);
    }

    /// @notice Deletes the pair for the given NFT, base token, and merkle root.
    /// @param nft The NFT contract address.
    /// @param baseToken The base token contract address.
    /// @param merkleRoot The merkle root for the valid tokenIds.
    function destroy(address nft, address baseToken, bytes32 merkleRoot) public {
        // check that a pair can only destroy itself
        require(msg.sender == pairs[nft][baseToken][merkleRoot], "Only pair can destroy itself");

        // delete the pair
        delete pairs[nft][baseToken][merkleRoot];

        emit Destroy(nft, baseToken, merkleRoot);
    }
}

/// @title StolenNftFilterOracle
/// @author out.eth (@outdoteth)
/// @notice A contract to check that a set of NFTs are not stolen.
contract StolenNftFilterOracle is ReservoirOracle, Owned {
    bytes32 private constant TOKEN_TYPE_HASH = keccak256("Token(address contract,uint256 tokenId)");
    uint256 public cooldownPeriod = 0;
    uint256 public validFor = 60 minutes;

    mapping(address => bool) public isDisabled;

    constructor() Owned(msg.sender) ReservoirOracle(0xAeB1D03929bF87F69888f381e73FBf75753d75AF) {}

    /// @notice Sets the cooldown period.
    /// @param _cooldownPeriod The cooldown period.
    function setCooldownPeriod(uint256 _cooldownPeriod) public onlyOwner {
        cooldownPeriod = _cooldownPeriod;
    }

    /// @notice Sets the valid for period.
    /// @param _validFor The valid for period.
    function setValidFor(uint256 _validFor) public onlyOwner {
        validFor = _validFor;
    }

    /// @notice Updates the reservoir oracle address.
    /// @param newReservoirOracleAddress The new reservoir oracle address.
    function updateReservoirOracleAddress(address newReservoirOracleAddress) public override onlyOwner {
        RESERVOIR_ORACLE_ADDRESS = newReservoirOracleAddress;
    }

    /// @notice Sets whether a token validation is disabled.
    /// @param tokenAddress The token address.
    /// @param _isDisabled Whether the token validation is disabled.
    function setIsDisabled(address tokenAddress, bool _isDisabled) public onlyOwner {
        isDisabled[tokenAddress] = _isDisabled;
    }

    /// @notice Checks that a set of NFTs are not stolen.
    /// @param tokenAddress The address of the NFT contract.
    /// @param tokenIds The ids of the NFTs.
    /// @param messages The messages signed by the reservoir oracle.
    function validateTokensAreNotStolen(address tokenAddress, uint256[] calldata tokenIds, Message[] calldata messages)
        public
        view
    {
        if (isDisabled[tokenAddress]) return;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            Message calldata message = messages[i];

            // check that the signer is correct and message id matches token id + token address
            bytes32 expectedMessageId = keccak256(abi.encode(TOKEN_TYPE_HASH, tokenAddress, tokenIds[i]));
            require(_verifyMessage(expectedMessageId, validFor, message), "Message has invalid signature");

            (bool isFlagged, uint256 lastTransferTime) = abi.decode(message.payload, (bool, uint256));

            // check that the NFT is not stolen
            require(!isFlagged, "NFT is flagged as suspicious");

            // check that the NFT was not transferred too recently
            require(lastTransferTime + cooldownPeriod < block.timestamp, "NFT was transferred too recently");
        }
    }
}

/// @title Pair
/// @author out.eth (@outdoteth)
/// @notice A pair of an NFT and a base token that can be used to create and trade fractionalized NFTs.
contract Pair is ERC20, ERC721TokenReceiver {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    uint256 public constant CLOSE_GRACE_PERIOD = 7 days;
    uint256 private constant ONE = 1e18;
    uint256 private constant MINIMUM_LIQUIDITY = 100_000;

    address public immutable nft;
    address public immutable baseToken; // address(0) for ETH
    bytes32 public immutable merkleRoot;
    LpToken public immutable lpToken;
    Caviar public immutable caviar;
    uint256 public closeTimestamp;

    event Add(uint256 indexed baseTokenAmount, uint256 indexed fractionalTokenAmount, uint256 indexed lpTokenAmount);
    event Remove(uint256 indexed baseTokenAmount, uint256 indexed fractionalTokenAmount, uint256 indexed lpTokenAmount);
    event Buy(uint256 indexed inputAmount, uint256 indexed outputAmount);
    event Sell(uint256 indexed inputAmount, uint256 indexed outputAmount);
    event Wrap(uint256[] indexed tokenIds);
    event Unwrap(uint256[] indexed tokenIds);
    event Close(uint256 indexed closeTimestamp);
    event Withdraw(uint256 indexed tokenId);

    constructor(
        address _nft,
        address _baseToken,
        bytes32 _merkleRoot,
        string memory pairSymbol,
        string memory nftName,
        string memory nftSymbol
    ) ERC20(string.concat(nftName, " fractional token"), string.concat("f", nftSymbol), 18) {
        nft = _nft;
        baseToken = _baseToken; // use address(0) for native ETH
        merkleRoot = _merkleRoot;
        lpToken = new LpToken(pairSymbol);
        caviar = Caviar(msg.sender);
    }

    // ************************ //
    //      Core AMM logic      //
    // ***********************  //

    /// @notice Adds liquidity to the pair.
    /// @param baseTokenAmount The amount of base tokens to add.
    /// @param fractionalTokenAmount The amount of fractional tokens to add.
    /// @param minLpTokenAmount The minimum amount of LP tokens to mint.
    /// @param minPrice The minimum price that the pool should currently be at.
    /// @param maxPrice The maximum price that the pool should currently be at.
    /// @param deadline The deadline before the trade expires.
    /// @return lpTokenAmount The amount of LP tokens minted.
    function add(
        uint256 baseTokenAmount,
        uint256 fractionalTokenAmount,
        uint256 minLpTokenAmount,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 deadline
    ) public payable returns (uint256 lpTokenAmount) {
        // *** Checks *** //

        // check that the trade has not expired
        require(deadline == 0 || deadline >= block.timestamp, "Expired");

        // check the token amount inputs are not zero
        require(baseTokenAmount > 0 && fractionalTokenAmount > 0, "Input token amount is zero");

        // check that correct eth input was sent - if the baseToken equals address(0) then native ETH is used
        require(baseToken == address(0) ? msg.value == baseTokenAmount : msg.value == 0, "Invalid ether input");

        uint256 lpTokenSupply = lpToken.totalSupply();

        // check that the price is within the bounds if there is liquidity in the pool
        if (lpTokenSupply != 0) {
            uint256 _price = price();
            require(_price >= minPrice && _price <= maxPrice, "Slippage: price out of bounds");
        }

        // calculate the lp token shares to mint
        lpTokenAmount = addQuote(baseTokenAmount, fractionalTokenAmount, lpTokenSupply);

        // check that the amount of lp tokens outputted is greater than the min amount
        require(lpTokenAmount >= minLpTokenAmount, "Slippage: lp token amount out");

        // *** Effects *** //

        // transfer fractional tokens in
        _transferFrom(msg.sender, address(this), fractionalTokenAmount);

        // *** Interactions *** //

        // mint lp tokens to sender
        lpToken.mint(msg.sender, lpTokenAmount);

        // transfer first MINIMUM_LIQUIDITY lp tokens to the owner
        if (lpTokenSupply == 0) {
            lpToken.mint(caviar.owner(), MINIMUM_LIQUIDITY);
        }

        // transfer base tokens in if the base token is not ETH
        if (baseToken != address(0)) {
            // transfer base tokens in
            ERC20(baseToken).safeTransferFrom(msg.sender, address(this), baseTokenAmount);
        }

        emit Add(baseTokenAmount, fractionalTokenAmount, lpTokenAmount);
    }

    /// @notice Removes liquidity from the pair.
    /// @param lpTokenAmount The amount of LP tokens to burn.
    /// @param minBaseTokenOutputAmount The minimum amount of base tokens to receive.
    /// @param minFractionalTokenOutputAmount The minimum amount of fractional tokens to receive.
    /// @param deadline The deadline before the trade expires.
    /// @return baseTokenOutputAmount The amount of base tokens received.
    /// @return fractionalTokenOutputAmount The amount of fractional tokens received.
    function remove(
        uint256 lpTokenAmount,
        uint256 minBaseTokenOutputAmount,
        uint256 minFractionalTokenOutputAmount,
        uint256 deadline
    ) public returns (uint256 baseTokenOutputAmount, uint256 fractionalTokenOutputAmount) {
        // *** Checks *** //

        // check that the trade has not expired
        require(deadline == 0 || deadline >= block.timestamp, "Expired");

        // calculate the output amounts
        (baseTokenOutputAmount, fractionalTokenOutputAmount) = removeQuote(lpTokenAmount);

        // check that the base token output amount is greater than the min amount
        require(baseTokenOutputAmount >= minBaseTokenOutputAmount, "Slippage: base token amount out");

        // check that the fractional token output amount is greater than the min amount
        require(fractionalTokenOutputAmount >= minFractionalTokenOutputAmount, "Slippage: fractional token out");

        // *** Effects *** //

        // transfer fractional tokens to sender
        _transferFrom(address(this), msg.sender, fractionalTokenOutputAmount);

        // *** Interactions *** //

        // burn lp tokens from sender
        lpToken.burn(msg.sender, lpTokenAmount);

        if (baseToken == address(0)) {
            // if base token is native ETH then send ether to sender
            msg.sender.safeTransferETH(baseTokenOutputAmount);
        } else {
            // transfer base tokens to sender
            ERC20(baseToken).safeTransfer(msg.sender, baseTokenOutputAmount);
        }

        emit Remove(baseTokenOutputAmount, fractionalTokenOutputAmount, lpTokenAmount);
    }

    /// @notice Buys fractional tokens from the pair.
    /// @param outputAmount The amount of fractional tokens to buy.
    /// @param maxInputAmount The maximum amount of base tokens to spend.
    /// @param deadline The deadline before the trade expires.
    /// @return inputAmount The amount of base tokens spent.
    function buy(uint256 outputAmount, uint256 maxInputAmount, uint256 deadline)
        public
        payable
        returns (uint256 inputAmount)
    {
        // *** Checks *** //

        // check that the trade has not expired
        require(deadline == 0 || deadline >= block.timestamp, "Expired");

        // check that correct eth input was sent - if the baseToken equals address(0) then native ETH is used
        require(baseToken == address(0) ? msg.value == maxInputAmount : msg.value == 0, "Invalid ether input");

        // calculate required input amount using xyk invariant
        inputAmount = buyQuote(outputAmount);

        // check that the required amount of base tokens is less than the max amount
        require(inputAmount <= maxInputAmount, "Slippage: amount in");

        // *** Effects *** //
        // transfer fractional tokens to sender
        _transferFrom(address(this), msg.sender, outputAmount);

        // *** Interactions *** //

        if (baseToken == address(0)) {
            // refund surplus eth
            uint256 refundAmount = maxInputAmount - inputAmount;
            if (refundAmount > 0) msg.sender.safeTransferETH(refundAmount);
        } else {
            // transfer base tokens in
            ERC20(baseToken).safeTransferFrom(msg.sender, address(this), inputAmount);
        }

        emit Buy(inputAmount, outputAmount);
    }

    /// @notice Sells fractional tokens to the pair.
    /// @param inputAmount The amount of fractional tokens to sell.
    /// @param deadline The deadline before the trade expires.
    /// @param minOutputAmount The minimum amount of base tokens to receive.
    /// @return outputAmount The amount of base tokens received.
    function sell(uint256 inputAmount, uint256 minOutputAmount, uint256 deadline)
        public
        returns (uint256 outputAmount)
    {
        // *** Checks *** //

        // check that the trade has not expired
        require(deadline == 0 || deadline >= block.timestamp, "Expired");

        // calculate output amount using xyk invariant
        outputAmount = sellQuote(inputAmount);

        // check that the outputted amount of fractional tokens is greater than the min amount
        require(outputAmount >= minOutputAmount, "Slippage: amount out");

        // *** Effects *** //

        // transfer fractional tokens from sender
        _transferFrom(msg.sender, address(this), inputAmount);

        // *** Interactions *** //

        if (baseToken == address(0)) {
            // transfer ether out
            msg.sender.safeTransferETH(outputAmount);
        } else {
            // transfer base tokens out
            ERC20(baseToken).safeTransfer(msg.sender, outputAmount);
        }

        emit Sell(inputAmount, outputAmount);
    }

    // ******************** //
    //      Wrap logic      //
    // ******************** //

    /// @notice Wraps NFTs into fractional tokens.
    /// @param tokenIds The ids of the NFTs to wrap.
    /// @param proofs The merkle proofs for the NFTs proving that they can be used in the pair.
    /// @return fractionalTokenAmount The amount of fractional tokens minted.
    function wrap(uint256[] calldata tokenIds, bytes32[][] calldata proofs, ReservoirOracle.Message[] calldata messages)
        public
        returns (uint256 fractionalTokenAmount)
    {
        // *** Checks *** //

        // check that wrapping is not closed
        require(closeTimestamp == 0, "Wrap: closed");

        // check the tokens exist in the merkle root
        _validateTokenIds(tokenIds, proofs);

        // check that the tokens are not stolen with reservoir oracle
        _validateTokensAreNotStolen(tokenIds, messages);

        // *** Effects *** //

        // mint fractional tokens to sender
        fractionalTokenAmount = tokenIds.length * ONE;
        _mint(msg.sender, fractionalTokenAmount);

        // *** Interactions *** //

        // transfer nfts from sender
        for (uint256 i = 0; i < tokenIds.length;) {
            ERC721(nft).safeTransferFrom(msg.sender, address(this), tokenIds[i]);

            unchecked {
                i++;
            }
        }

        emit Wrap(tokenIds);
    }

    /// @notice Unwraps fractional tokens into NFTs.
    /// @param tokenIds The ids of the NFTs to unwrap.
    /// @param withFee Whether to pay a fee for unwrapping or not.
    /// @return fractionalTokenAmount The amount of fractional tokens burned.
    function unwrap(uint256[] calldata tokenIds, bool withFee) public returns (uint256 fractionalTokenAmount) {
        // *** Effects *** //

        // burn fractional tokens from sender
        fractionalTokenAmount = tokenIds.length * ONE;
        _burn(msg.sender, fractionalTokenAmount);

        // Take the fee if withFee is true
        if (withFee) {
            // calculate fee
            uint256 fee = fractionalTokenAmount * 3 / 1000;

            // transfer fee from sender
            _transferFrom(msg.sender, address(this), fee);
            fractionalTokenAmount += fee;
        }

        // transfer nfts to sender
        for (uint256 i = 0; i < tokenIds.length;) {
            ERC721(nft).safeTransferFrom(address(this), msg.sender, tokenIds[i]);

            unchecked {
                i++;
            }
        }

        emit Unwrap(tokenIds);
    }

    // *********************** //
    //      NFT AMM logic      //
    // *********************** //

    /// @notice nftAdd Adds liquidity to the pair using NFTs.
    /// @param baseTokenAmount The amount of base tokens to add.
    /// @param tokenIds The ids of the NFTs to add.
    /// @param minLpTokenAmount The minimum amount of lp tokens to receive.
    /// @param minPrice The minimum price of the pair.
    /// @param maxPrice The maximum price of the pair.
    /// @param deadline The deadline for the transaction.
    /// @param proofs The merkle proofs for the NFTs.
    /// @return lpTokenAmount The amount of lp tokens minted.
    function nftAdd(
        uint256 baseTokenAmount,
        uint256[] calldata tokenIds,
        uint256 minLpTokenAmount,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 deadline,
        bytes32[][] calldata proofs,
        ReservoirOracle.Message[] calldata messages
    ) public payable returns (uint256 lpTokenAmount) {
        // wrap the incoming NFTs into fractional tokens
        uint256 fractionalTokenAmount = wrap(tokenIds, proofs, messages);

        // add liquidity using the fractional tokens and base tokens
        lpTokenAmount = add(baseTokenAmount, fractionalTokenAmount, minLpTokenAmount, minPrice, maxPrice, deadline);
    }

    /// @notice Removes liquidity from the pair using NFTs.
    /// @param lpTokenAmount The amount of lp tokens to remove.
    /// @param minBaseTokenOutputAmount The minimum amount of base tokens to receive.
    /// @param deadline The deadline before the trade expires.
    /// @param tokenIds The ids of the NFTs to remove.
    /// @param withFee Whether to pay a fee for unwrapping or not.
    /// @return baseTokenOutputAmount The amount of base tokens received.
    /// @return fractionalTokenOutputAmount The amount of fractional tokens received.
    function nftRemove(
        uint256 lpTokenAmount,
        uint256 minBaseTokenOutputAmount,
        uint256 deadline,
        uint256[] calldata tokenIds,
        bool withFee
    ) public returns (uint256 baseTokenOutputAmount, uint256 fractionalTokenOutputAmount) {
        // remove liquidity and send fractional tokens and base tokens to sender
        (baseTokenOutputAmount, fractionalTokenOutputAmount) =
            remove(lpTokenAmount, minBaseTokenOutputAmount, tokenIds.length * ONE, deadline);

        // unwrap the fractional tokens into NFTs and send to sender
        unwrap(tokenIds, withFee);
    }

    /// @notice Buys NFTs from the pair using base tokens.
    /// @param tokenIds The ids of the NFTs to buy.
    /// @param maxInputAmount The maximum amount of base tokens to spend.
    /// @param deadline The deadline before the trade expires.
    /// @return inputAmount The amount of base tokens spent.
    function nftBuy(uint256[] calldata tokenIds, uint256 maxInputAmount, uint256 deadline)
        public
        payable
        returns (uint256 inputAmount)
    {
        // buy fractional tokens using base tokens
        inputAmount = buy(tokenIds.length * ONE, maxInputAmount, deadline);

        // unwrap the fractional tokens into NFTs and send to sender
        unwrap(tokenIds, false);
    }

    /// @notice Sells NFTs to the pair for base tokens.
    /// @param tokenIds The ids of the NFTs to sell.
    /// @param minOutputAmount The minimum amount of base tokens to receive.
    /// @param deadline The deadline before the trade expires.
    /// @param proofs The merkle proofs for the NFTs.
    /// @return outputAmount The amount of base tokens received.
    function nftSell(
        uint256[] calldata tokenIds,
        uint256 minOutputAmount,
        uint256 deadline,
        bytes32[][] calldata proofs,
        ReservoirOracle.Message[] calldata messages
    ) public returns (uint256 outputAmount) {
        // wrap the incoming NFTs into fractional tokens
        uint256 inputAmount = wrap(tokenIds, proofs, messages);

        // sell fractional tokens for base tokens
        outputAmount = sell(inputAmount, minOutputAmount, deadline);
    }

    // ****************************** //
    //      Emergency exit logic      //
    // ****************************** //

    /// @notice Closes the pair to new wraps.
    /// @dev Can only be called by the caviar owner. This is used as an emergency exit in case
    ///      the caviar owner suspects that the pair has been compromised.
    function close() public {
        // check that the sender is the caviar owner
        require(caviar.owner() == msg.sender, "Close: not owner");

        // set the close timestamp with a grace period
        closeTimestamp = block.timestamp + CLOSE_GRACE_PERIOD;

        // remove the pair from the Caviar contract
        caviar.destroy(nft, baseToken, merkleRoot);

        emit Close(closeTimestamp);
    }

    /// @notice Withdraws a particular NFT from the pair.
    /// @dev Can only be called by the caviar owner after the close grace period has passed. This
    ///      is used to auction off the NFTs in the pair in case NFTs get stuck due to liquidity
    ///      imbalances. Proceeds from the auction should be distributed pro rata to fractional
    ///      token holders. See documentation for more details.
    function withdraw(uint256 tokenId) public {
        // check that the sender is the caviar owner
        require(caviar.owner() == msg.sender, "Withdraw: not owner");

        // check that the close period has been set
        require(closeTimestamp != 0, "Withdraw not initiated");

        // check that the close grace period has passed
        require(block.timestamp >= closeTimestamp, "Not withdrawable yet");

        // transfer the nft to the caviar owner
        ERC721(nft).safeTransferFrom(address(this), msg.sender, tokenId);

        emit Withdraw(tokenId);
    }

    // ***************** //
    //      Getters      //
    // ***************** //

    function baseTokenReserves() public view returns (uint256) {
        return _baseTokenReserves();
    }

    function fractionalTokenReserves() public view returns (uint256) {
        return balanceOf[address(this)];
    }

    /// @notice The current price of one fractional token in base tokens with 18 decimals of precision.
    /// @dev Calculated by dividing the base token reserves by the fractional token reserves.
    /// @return price The price of one fractional token in base tokens * 1e18.
    function price() public view returns (uint256) {
        uint256 exponent = baseToken == address(0) ? 18 : (36 - ERC20(baseToken).decimals());
        return (_baseTokenReserves() * 10 ** exponent) / fractionalTokenReserves();
    }

    /// @notice The amount of base tokens required to buy a given amount of fractional tokens.
    /// @dev Calculated using the xyk invariant and a 30bps fee.
    /// @param outputAmount The amount of fractional tokens to buy.
    /// @return inputAmount The amount of base tokens required.
    function buyQuote(uint256 outputAmount) public view returns (uint256) {
        return FixedPointMathLib.mulDivUp(
            outputAmount * 1000, baseTokenReserves(), (fractionalTokenReserves() - outputAmount) * 990
        );
    }

    /// @notice The amount of base tokens received for selling a given amount of fractional tokens.
    /// @dev Calculated using the xyk invariant and a 30bps fee.
    /// @param inputAmount The amount of fractional tokens to sell.
    /// @return outputAmount The amount of base tokens received.
    function sellQuote(uint256 inputAmount) public view returns (uint256) {
        uint256 inputAmountWithFee = inputAmount * 990;
        return (inputAmountWithFee * baseTokenReserves()) / ((fractionalTokenReserves() * 1000) + inputAmountWithFee);
    }

    /// @notice The amount of lp tokens received for adding a given amount of base tokens and fractional tokens.
    /// @dev Calculated as a share of existing deposits. If there are no existing deposits, then initializes to
    ///      sqrt(baseTokenAmount * fractionalTokenAmount).
    /// @param baseTokenAmount The amount of base tokens to add.
    /// @param fractionalTokenAmount The amount of fractional tokens to add.
    /// @return lpTokenAmount The amount of lp tokens received.
    function addQuote(uint256 baseTokenAmount, uint256 fractionalTokenAmount, uint256 lpTokenSupply)
        public
        view
        returns (uint256)
    {
        if (lpTokenSupply != 0) {
            // calculate amount of lp tokens as a fraction of existing reserves
            uint256 baseTokenShare = (baseTokenAmount * lpTokenSupply) / baseTokenReserves();
            uint256 fractionalTokenShare = (fractionalTokenAmount * lpTokenSupply) / fractionalTokenReserves();
            return Math.min(baseTokenShare, fractionalTokenShare);
        } else {
            // if there is no liquidity then init
            return Math.sqrt(baseTokenAmount * fractionalTokenAmount) - MINIMUM_LIQUIDITY;
        }
    }

    /// @notice The amount of base tokens and fractional tokens received for burning a given amount of lp tokens.
    /// @dev Calculated as a share of existing deposits.
    /// @param lpTokenAmount The amount of lp tokens to burn.
    /// @return baseTokenAmount The amount of base tokens received.
    /// @return fractionalTokenAmount The amount of fractional tokens received.
    function removeQuote(uint256 lpTokenAmount) public view returns (uint256, uint256) {
        uint256 lpTokenSupply = lpToken.totalSupply();
        uint256 baseTokenOutputAmount = (baseTokenReserves() * lpTokenAmount) / lpTokenSupply;
        uint256 fractionalTokenOutputAmount = (fractionalTokenReserves() * lpTokenAmount) / lpTokenSupply;
        uint256 upperFractionalTokenOutputAmount = (fractionalTokenReserves() * (lpTokenAmount + 1)) / lpTokenSupply;

        if (
            fractionalTokenOutputAmount % 1e18 != 0
                && upperFractionalTokenOutputAmount - fractionalTokenOutputAmount <= 1000 && lpTokenSupply > 1e15
        ) {
            fractionalTokenOutputAmount = upperFractionalTokenOutputAmount;
        }

        return (baseTokenOutputAmount, fractionalTokenOutputAmount);
    }

    // ************************ //
    //      Internal utils      //
    // ************************ //

    function _transferFrom(address from, address to, uint256 amount) internal returns (bool) {
        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    function _validateTokensAreNotStolen(uint256[] calldata tokenIds, ReservoirOracle.Message[] calldata messages)
        internal
        view
    {
        address stolenNftFilterAddress = caviar.stolenNftFilterOracle();

        // if filter address is not set then no need to check if nfts are stolen
        if (stolenNftFilterAddress == address(0)) return;

        // validate that nfts are not stolen
        StolenNftFilterOracle(stolenNftFilterAddress).validateTokensAreNotStolen(nft, tokenIds, messages);
    }

    /// @dev Validates that the given tokenIds are valid for the contract's merkle root. Reverts
    ///      if any of the tokenId proofs are invalid.
    function _validateTokenIds(uint256[] calldata tokenIds, bytes32[][] calldata proofs) internal view {
        // if merkle root is not set then all tokens are valid
        if (merkleRoot == bytes32(0)) return;

        // validate merkle proofs against merkle root
        for (uint256 i = 0; i < tokenIds.length;) {
            bool isValid = MerkleProofLib.verify(
                proofs[i],
                merkleRoot,
                // double hash to prevent second preimage attacks
                keccak256(bytes.concat(keccak256(abi.encode(tokenIds[i]))))
            );

            require(isValid, "Invalid merkle proof");

            unchecked {
                i++;
            }
        }
    }

    /// @dev Returns the current base token reserves. If the base token is ETH then it ignores
    ///      the msg.value that is being sent in the current call context - this is to ensure the
    ///      xyk math is correct in the buy() and add() functions.
    function _baseTokenReserves() internal view returns (uint256) {
        return baseToken == address(0)
            ? address(this).balance - msg.value // subtract the msg.value if the base token is ETH
            : ERC20(baseToken).balanceOf(address(this));
    }
}

/// @title CaviarZapRouter
/// @author out.eth
/// @notice This contract is used to buy and add NFTs on deposit or remove and
///         sell NFTs on withdraw in a single transaction.
contract CaviarZapRouter is ERC721TokenReceiver {
    using SafeTransferLib for address;

    struct BuyParams {
        uint256 outputAmount;
        uint256 maxInputAmount;
        uint256 deadline;
    }

    struct AddParams {
        uint256 baseTokenAmount;
        uint256 fractionalTokenAmount;
        uint256 minLpTokenAmount;
        uint256 minPrice;
        uint256 maxPrice;
        uint256 deadline;
    }

    struct RemoveParams {
        uint256 lpTokenAmount;
        uint256 minBaseTokenOutputAmount;
        uint256 minFractionalTokenOutputAmount;
        uint256 deadline;
    }

    struct SellParams {
        uint256 inputAmount;
        uint256 minOutputAmount;
        uint256 deadline;
    }

    receive() external payable {}

    function buyAndAdd(address pair, BuyParams calldata buyParams, AddParams calldata addParams)
        public
        payable
        returns (uint256 inputAmount, uint256 lpTokenAmount)
    {
        // buy some fractional tokens
        inputAmount = Pair(pair).buy{value: buyParams.maxInputAmount}(
            buyParams.outputAmount, buyParams.maxInputAmount, buyParams.deadline
        );

        // add fractional tokens and eth
        lpTokenAmount = Pair(pair).add{value: address(this).balance}(
            addParams.baseTokenAmount,
            addParams.fractionalTokenAmount,
            addParams.minLpTokenAmount,
            addParams.minPrice,
            addParams.maxPrice,
            addParams.deadline
        );

        // send the LP tokens to the caller
        // transfer the LP tokens to this contract
        LpToken lpToken = LpToken(Pair(pair).lpToken());
        lpToken.transfer(msg.sender, lpTokenAmount);
    }

    function removeAndSell(address pair, RemoveParams calldata removeParams, SellParams calldata sellParams)
        public
        returns (uint256 baseTokenOutputAmount, uint256 fractionalTokenOutputAmount, uint256 outputAmount)
    {
        // transfer the LP tokens to this contract
        LpToken lpToken = LpToken(Pair(pair).lpToken());
        lpToken.transferFrom(msg.sender, address(this), removeParams.lpTokenAmount);

        // remove fractional and base tokens
        (baseTokenOutputAmount, fractionalTokenOutputAmount) = Pair(pair).remove(
            removeParams.lpTokenAmount,
            removeParams.minBaseTokenOutputAmount,
            removeParams.minFractionalTokenOutputAmount,
            removeParams.deadline
        );

        // sell the fractional tokens
        outputAmount = Pair(pair).sell(sellParams.inputAmount, sellParams.minOutputAmount, sellParams.deadline);

        // send the ETH to the caller
        msg.sender.safeTransferETH(address(this).balance);
    }
}

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/**
 * @title IWETH9
 * @author Dapphub
 * @notice [Wrapped Ether](https://weth.io/) smart contract. Extends **ERC20**.
 */
interface IWETH9 is IERC20Metadata {
    /// @notice Emitted when **ETH** is wrapped.
    event Deposit(address indexed dst, uint256 wad);
    /// @notice Emitted when **ETH** is unwrapped.
    event Withdrawal(address indexed src, uint256 wad);

    /**
     * @notice Wraps Ether. **WETH** will be minted to the sender at 1 **ETH** : 1 **WETH**.
     */
    receive() external payable;

    /**
     * @notice Wraps Ether. **WETH** will be minted to the sender at 1 **ETH** : 1 **WETH**.
     */
    fallback() external payable;

    /**
     * @notice Wraps Ether. **WETH** will be minted to the sender at 1 **ETH** : 1 **WETH**.
     */
    function deposit() external payable;

    /**
     * @notice Unwraps Ether. **ETH** will be returned to the sender at 1 **ETH** : 1 **WETH**.
     * @param wad Amount to unwrap.
     */
    function withdraw(uint256 wad) external;
}

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

/// @title BatonFactory
/// @author Baton team
/// @notice Factory contract for creating new BatonFarm contract instances
contract BatonFactory {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for address;
    /*//////////////////////////////////////////////////////////////
                                 ENUMS
    //////////////////////////////////////////////////////////////*/

    enum Type {
        ETH,
        ERC20,
        NFT
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    IWETH9 public weth;
    Caviar public caviar;
    address public batonMonitor;

    /*//////////////////////////////////////////////////////////////
                    FEE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public batonRewardsFee;
    uint256 public proposedRewardsFee;
    uint256 public rewardsFeeProposalApprovalDate;

    uint256 public batonLPFee;
    uint256 public proposedLPFee;
    uint256 public LPFeeProposalApprovalDate;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event FarmCreated(
        address farmAddress,
        address owner,
        address rewardsDistributor,
        address rewardsToken,
        address pairAddress,
        uint256 rewardsDuration,
        Type farmType
    );

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address payable _weth, address _caviar, address _batonMonitor) {
        weth = IWETH9(_weth);
        caviar = Caviar(_caviar);
        batonMonitor = _batonMonitor;
    }

    /*//////////////////////////////////////////////////////////////
                        MANAGE FEES FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Propose a new fee
     * @param _proposedLPFee The proposed fee in basis points (100 bp = 1%)
     * @dev Only callable by the BatonMonitor.
     */
    function proposeNewLPFee(uint256 _proposedLPFee) external onlyBatonMonitor {
        require(_proposedLPFee <= 25 * 100, "must: _proposedLPFee <= 2500 bp");

        proposedLPFee = _proposedLPFee;
        LPFeeProposalApprovalDate = block.timestamp + 7 days;
    }

    /**
     * @notice Set the fee to the latest proposed fee if 7 days have passed from proposal
     * @notice Revert if the date of proposal approval has not arrived
     * @dev Only callable by the BatonMonitor.
     */
    function setLPFeeRate() external onlyBatonMonitor {
        require(LPFeeProposalApprovalDate != 0, "no fee proposal");
        require(LPFeeProposalApprovalDate < block.timestamp, "must: LPFeeProposalApprovalDate < block.timestamp");

        batonLPFee = proposedLPFee;
        LPFeeProposalApprovalDate = 0;
    }

    /**
     * @notice Propose a new fee
     * @param _proposedRewardsFee The proposed fee in basis points (100 bp = 1%)
     * @dev Only callable by the BatonMonitor.
     */
    function proposeNewRewardsFee(uint256 _proposedRewardsFee) external onlyBatonMonitor {
        require(_proposedRewardsFee <= 25 * 100, "must: _proposedRewardsFee <= 2500 bp");

        proposedRewardsFee = _proposedRewardsFee;
        rewardsFeeProposalApprovalDate = block.timestamp + 7 days;
    }

    /**
     * @notice Set the fee to the latest proposed fee if 7 days have passed from proposal
     * @notice Revert if the date of proposal approval has not arrived
     * @dev Only callable by the BatonMonitor.
     */
    function setRewardsFeeRate() external onlyBatonMonitor {
        require(rewardsFeeProposalApprovalDate != 0, "no fee proposal");
        require(
            rewardsFeeProposalApprovalDate < block.timestamp, "must: rewardsFeeProposalApprovalDate < block.timestamp"
        );

        batonRewardsFee = proposedRewardsFee;
        rewardsFeeProposalApprovalDate = 0;
    }

    /*//////////////////////////////////////////////////////////////
                              CREATE FARMS
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates an instance of BatonFarm, incentivising staking with ERC20 rewards
    /// @param _owner Owner of the farm
    /// @param _rewardsToken Address of the rewards token
    /// @param _rewardAmount Amount of the rewards token to initially bootstrap the pool with
    /// @param _pairAddress Address of the underlying staking pair
    /// @param _rewardsDuration Duration that the rewards should be vested over
    /// @return Address of the newly-created BatonFarm contract instance
    function createFarmFromExistingPairERC20(
        address _owner,
        address _rewardsToken,
        uint256 _rewardAmount,
        address _pairAddress,
        uint256 _rewardsDuration
    )
        external
        returns (address)
    {
        require(_rewardAmount > 0, "expected _rewardAmount > 0");
        // create farm
        BatonFarm farm =
        new BatonFarm(_owner, address(this), batonMonitor, _rewardsToken, _pairAddress, _rewardsDuration, address(this));

        // fund the farm with reward tokens
        ERC20 rewardsToken = ERC20(_rewardsToken);
        rewardsToken.safeTransferFrom(msg.sender, address(this), _rewardAmount);

        rewardsToken.approve(address(farm), _rewardAmount);
        // update farm with new rewards
        farm.notifyRewardAmount(_rewardAmount);

        // Emit event
        emit FarmCreated(
            address(farm), _owner, address(this), _rewardsToken, _pairAddress, _rewardsDuration, Type.ERC20
        );

        // Return address of the farm
        return address(farm);
    }

    /// @notice Creates an instance of BatonFarm, incentivising staking with ETH rewards
    /// @param _owner Owner of the farm
    /// @param _pairAddress Address of the underlying staking pair
    /// @param _rewardsDuration Duration that the rewards should be vested over
    /// @return Address of the newly-created BatonFarm contract instance
    /// @dev This is very much `createFarmFromExistingPairERC20` but with ETH
    function createFarmFromExistingPairETH(
        address _owner,
        address _pairAddress,
        uint256 _rewardsDuration
    )
        external
        payable
        returns (address)
    {
        require(msg.value > 0, "expected msg.value > 0");
        // deposit sent ETH into weth
        weth.deposit{ value: msg.value }();

        // create farm with WETH as reward
        BatonFarm farm =
        new BatonFarm(_owner, address(this), batonMonitor, address(weth), _pairAddress, _rewardsDuration, address(this));

        // transfer WETH into farm
        weth.approve(address(farm), msg.value);

        // update farm with new rewards
        farm.notifyRewardAmount(msg.value);

        //emit event
        emit FarmCreated(address(farm), _owner, address(this), address(weth), _pairAddress, _rewardsDuration, Type.ETH);

        // return address of the farm
        return address(farm);
    }

    /// @notice Creates an instance of BatonFarm, incentivising staking with fractional NFT rewards
    /// @param _owner Owner of the farm
    /// @param _rewardsNFT  Address of the NFT to be given as rewards once fractionalised
    /// @param _rewardsTokenIds IDs of the NFT to retrieve from the msg.sender
    /// @param _rewardsDuration Duration that the rewards should be vested over
    /// @param _oracleMessages Messages from Reservoir to send to Caviar for getting fractional amount
    /// @param _pairAddress Address of the underlying staking pair
    /// @return Address of the newly-created BatonFarm contract instance
    /// @dev This is very much `createFarmFromExistingPairERC20` but with fractional NFTs from Caviar
    function createFarmFromExistingPairNFT(
        address _owner,
        address _rewardsNFT,
        uint256[] calldata _rewardsTokenIds,
        uint256 _rewardsDuration,
        address _pairAddress,
        ReservoirOracle.Message[] calldata _oracleMessages
    )
        external
        returns (address)
    {
        ERC721 rewardsNFT = ERC721(_rewardsNFT);

        require(_rewardsTokenIds.length > 0, "expected _rewardsTokenIds.length > 0");
        // transfer all nfts to this contract
        for (uint256 i = 0; i < _rewardsTokenIds.length; i++) {
            rewardsNFT.transferFrom(msg.sender, address(this), _rewardsTokenIds[i]);
        }

        // Fractionalise via Caviar
        Pair pair = Pair(caviar.pairs(_rewardsNFT, address(0), bytes32(0)));
        rewardsNFT.setApprovalForAll(address(pair), true);

        // Get fractional token amounts that will be the rewards for staking
        bytes32[][] memory proof = new bytes32[][](0);
        uint256 fractionalTokenAmount = pair.wrap(_rewardsTokenIds, proof, _oracleMessages);

        // Create a new farm
        BatonFarm farm =
        new BatonFarm(_owner, address(this), batonMonitor, address(pair), _pairAddress, _rewardsDuration, address(this));

        // Deposit the fractionalised-NFT rewards into the farm
        ERC20(address(pair)).safeTransfer(address(this), fractionalTokenAmount);

        ERC20(address(pair)).approve(address(farm), fractionalTokenAmount);
        farm.notifyRewardAmount(fractionalTokenAmount);

        // Emit event
        emit FarmCreated(address(farm), _owner, address(this), address(pair), _pairAddress, _rewardsDuration, Type.NFT);

        // Return address of the farm
        return address(farm);
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice Modifier to ensure that only the BatonMonitor contract can call a function.
     * @dev Requires that the caller is the BatonMonitor contract.
     */
    modifier onlyBatonMonitor() {
        require(msg.sender == batonMonitor, "Caller is not BatonMonitor contract");
        _;
    }
}

/// @title BatonFarm
/// @author Baton team
/// @notice Yield farms that allow for users to stake their NFT AMM LP positions into our yield farm
/// @dev We note that this implementation is coupled to Caviar's Pair contract. A Pair represents a
///      a Uniswap-V2-like CFMM pool consisting of fractions of the NFT (hence a Pair.nft() function).
contract BatonFarm is Pausable, Owned, ERC721TokenReceiver {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for address;
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    // caviar
    Pair public immutable pair;

    ERC20 public immutable rewardsToken; // token given as reward
    ERC20 public immutable stakingToken; // token being staked
    uint256 public periodFinish; // timestamp in which the farm is shutdown
    uint256 public rewardRate; // amount of fees given persecond
    uint256 public rewardsDuration; // duration in seconds that the rewards should be vested over
    uint256 public lastUpdateTime; // last time the reward was updated
    uint256 public rewardPerTokenStored;
    uint256 private _totalSupply; // total amount of staked assets

    /*//////////////////////////////////////////////////////////////
                                MAPPINGS
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards; // user -> rewards
    mapping(address => uint256) private _balances; // user -> staked assets

    /*//////////////////////////////////////////////////////////////
                    MIGRATION VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public migration; // address to migrate to
    bool public migrationComplete; // has a migration been initilized and completed

    address public rewardsDistributor; // an address who is capable of updating the pool with new rewards

    /*//////////////////////////////////////////////////////////////
                    BATON VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public immutable batonMonitor; // this address is the only one who can complete a migration, propose and set
        // a new
        // farm fee.
    BatonFactory public immutable batonFactory;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event RewardAdded(uint256 reward);
    event Received(address indexed user, uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event MigrationInitiated(address migration);
    event MigrationComplete(address migration, uint256 amount, uint256 timestamp);
    event UpdateRewardsDistributor(address _rewardsDistributor);
    event UpdateRewardsDuration(uint256 newRewardsDuration);
    event Recovered(address tokenAddress, uint256 tokenAmount);
    event FoundSurplus(uint256 surplusAmount, address recoveredTo);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _owner,
        address _rewardsDistributor,
        address _batonMonitor,
        address _rewardsToken,
        address _pairAddress,
        uint256 _rewardsDuration, // in seconds
        address _batonFactory
    )
        Owned(_owner)
    {
        require(_owner != address(0), "_owner shouldnt be address(0)");
        require(_rewardsDistributor != address(0), "_rewardsDistributor shouldnt be address(0)");
        require(_batonMonitor != address(0), "_batonMonitor shouldnt be address(0)");
        require(_rewardsToken != address(0), "_rewardsToken shouldnt be address(0)");
        require(_pairAddress != address(0), "_pairAddress shouldnt be address(0)");
        require(_batonFactory != address(0), "_batonFactory shouldnt be address(0)");

        pair = Pair(_pairAddress);

        rewardsToken = ERC20(_rewardsToken);
        stakingToken = ERC20(address(pair.lpToken()));
        rewardsDistributor = _rewardsDistributor;

        require(_rewardsDuration > 0, "_rewardsDuration cannot be 0");
        require(_rewardsDuration < 5 * (365 days), "_rewardsDuration cannot be more then 5 years");
        rewardsDuration = _rewardsDuration;

        batonMonitor = _batonMonitor;
        batonFactory = BatonFactory(_batonFactory);

        ERC721(pair.nft()).setApprovalForAll(address(pair), true);
    }

    /*//////////////////////////////////////////////////////////////
                                RECEIVE
    //////////////////////////////////////////////////////////////*/

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /*//////////////////////////////////////////////////////////////
                                VIEWS
    //////////////////////////////////////////////////////////////*/

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Calculates the percentage of an amount based on basis points.
     * @param basisPoints The basis points value (100bp == 1%).
     * @param amount The amount to calculate the percentage of.
     * @return The calculated percentage.
     */
    function calculatePercentage(uint256 basisPoints, uint256 amount) public pure returns (uint256) {
        uint256 percentage = basisPoints * amount / 10_000;
        return percentage;
    }

    /**
     * @dev Returns the last time at which the reward is applicable.
     * @return The last time reward is applicable (either the current block timestamp or the end of the reward period).
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    /**
     * @dev Returns the reward per token earned.
     * @return The calculated reward per token.
     */
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }

        uint256 lastTimeApplicable = lastTimeRewardApplicable();
        uint256 lastUpdateTimeDiff = lastTimeApplicable - lastUpdateTime;
        uint256 rewardRateMul = rewardRate * 1e18;
        uint256 rewardPerTokenIncrease = (lastUpdateTimeDiff * rewardRateMul) / _totalSupply;

        return rewardPerTokenStored + rewardPerTokenIncrease;
    }

    /**
     * @dev Returns the amount of rewards earned by an account.
     * @param account The address of the account.
     * @return The amount of rewards earned.
     */
    function earned(address account) public view returns (uint256) {
        uint256 rpt = rewardPerToken();
        uint256 userRewardPerTokenPaidDiff = rpt - userRewardPerTokenPaid[account];
        uint256 balanceOfAccount = _balances[account];
        uint256 reward = (balanceOfAccount * userRewardPerTokenPaidDiff) / 1e18;
        return reward + rewards[account];
    }

    /**
     * @dev Returns the unearned rewards amount.
     * @return The unearned rewards.
     */
    function _unearnedRewards() internal view returns (uint256) {
        uint256 currentTime = block.timestamp;
        uint256 remainingTime = periodFinish - currentTime;
        uint256 remainingRewards = rewardRate * remainingTime;

        return remainingRewards;
    }

    /*//////////////////////////////////////////////////////////////
                        STAKE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows the user to stake `amount` of the `stakingToken` into this farm
     * @param amount Amount to stake into the farm
     */
    function stake(uint256 amount) external poolNotMigrated onlyWhenPoolActive whenNotPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply + amount;
        _balances[msg.sender] = _balances[msg.sender] + amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount);
    }

    /**
     * @notice Helper function to 1) deposit equal parts of ETH and NFTs into the related
     *         Caviar NFT AMM pool for the user, 2) auto-staking the LP position into this
     *         contract by letting the contract hold custody of the position
     * @param tokenIds Given that this farm is present to a Caviar pair, ids of underlying NFT
     * @param minLpTokenAmount Minimum LP token amount as a means of slippage control
     * @param minPrice The minimum price of the pair.
     * @param maxPrice The maximum price of the pair.
     * @param deadline The deadline for the transaction.
     */
    function nftAddAndStake(
        uint256[] calldata tokenIds,
        uint256 minLpTokenAmount,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 deadline,
        bytes32[][] calldata proofs,
        ReservoirOracle.Message[] calldata messages
    )
        external
        payable
        onlyWhenPoolActive
        whenNotPaused
        poolNotMigrated
        updateReward(msg.sender)
    {
        // Retrieve the NFTs from the user
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ERC721(pair.nft()).safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }

        // Deposit equal parts of ETH (msg.value) and NFTs into the Caviar NFT AMM pool
        uint256 lpTokenAmount = pair.nftAdd{ value: msg.value }(
            msg.value, tokenIds, minLpTokenAmount, minPrice, maxPrice, deadline, proofs, messages
        );

        require(lpTokenAmount > 0, "Cannot stake 0");

        // prevent a reentracny attack from `pair.nftAdd`, make sure that stakingToken.balanceOf is acctually updated
        require(
            stakingToken.balanceOf(address(this)) == _totalSupply + lpTokenAmount,
            "stakingToken balance didnt update from lpTokenAmount"
        );

        // Ensure that the LP amount isn't zilch and record in supply / user balance
        _totalSupply = _totalSupply + lpTokenAmount;
        _balances[msg.sender] = _balances[msg.sender] + lpTokenAmount;

        emit Staked(msg.sender, lpTokenAmount);
    }

    /*//////////////////////////////////////////////////////////////
                    WITHDRAWING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Withdraw Pair position from the contract, decomposed as the
     *         baseToken (e.g WETH) and fractionalised NFT tokens. NFTs are returned to the user.
     * @param amount Amount of the LP position to withdraw
     * @param minBaseTokenOutputAmount Min amount to get of the base token, accounting for slippage
     * @param deadline Deadline to retrieve position by
     * @param tokenIds NFT IDs to reddem from LP
     * @param withFee An optional unwrapping fee
     */
    function withdrawAndRemoveNftFromPool(
        uint256 amount,
        uint256 minBaseTokenOutputAmount,
        uint256 deadline,
        uint256[] calldata tokenIds,
        bool withFee
    )
        external
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot withdraw 0");
        require(amount <= _balances[msg.sender], "Cannot withdraw more then you have staked");

        // remove the amount the user is unstaking
        _totalSupply = _totalSupply - amount;
        _balances[msg.sender] = _balances[msg.sender] - amount;

        uint256 batonFeeAmount = calculatePercentage(batonFactory.batonLPFee(), amount); // calculate batons fee

        // if the fee is more then 0 send the fee to batonMonitor
        if (batonFeeAmount > 0) {
            stakingToken.safeTransfer(batonMonitor, batonFeeAmount);
        }

        uint256 amountToRemove = amount - batonFeeAmount;

        (uint256 baseTokenOutputAmount, uint256 fractionalTokenOutputAmount) =
            pair.nftRemove(amountToRemove, minBaseTokenOutputAmount, deadline, tokenIds, withFee);

        // transfer the base / fractional nft tokens to the user
        SafeTransferLib.safeTransferETH(msg.sender, baseTokenOutputAmount);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            ERC721(pair.nft()).safeTransferFrom(address(this), msg.sender, tokenIds[i]);
        }

        // send user his rewards
        harvest();

        // emit an event
        emit Withdrawn(msg.sender, amountToRemove);
    }

    /**
     * @notice Withdraw Pair position from the contract, decomposed as the
     *         baseToken (e.g WETH) and fractionalised NFT tokens
     * @param amount Amount of the LP position to withdraw
     * @param minBaseTokenOutputAmount Min amount to get of the base token, accounting for slippage
     * @param minFractionalTokenOutputAmount Min amount to get of fractional NFT, accounting for
     *                                       slippage
     * @param deadline Deadline to retrieve position by
     */
    function withdrawAndRemoveLPFromPool(
        uint256 amount,
        uint256 minBaseTokenOutputAmount,
        uint256 minFractionalTokenOutputAmount,
        uint256 deadline
    )
        external
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot withdraw 0");
        require(amount <= _balances[msg.sender], "Cannot withdraw more then you have staked");

        // remove the amount the user is unstaking
        _totalSupply = _totalSupply - amount;
        _balances[msg.sender] = _balances[msg.sender] - amount;

        // take fee from lptoken
        uint256 batonFeeAmount = calculatePercentage(batonFactory.batonLPFee(), amount); // calculate batons fee

        // if the fee is more then 0 send the fee to batonMonitor
        if (batonFeeAmount > 0) {
            stakingToken.safeTransfer(batonMonitor, batonFeeAmount);
        }

        uint256 amountToRemove = amount - batonFeeAmount;

        if (amountToRemove > 0) {
            // calculate the amount of base (eth for example) tokens and fractional nft tokens the user should receive
            (uint256 baseTokenOutputAmount, uint256 fractionalTokenOutputAmount) =
                pair.remove(amountToRemove, minBaseTokenOutputAmount, minFractionalTokenOutputAmount, deadline);

            // transfer the base / fractional nft tokens to the user
            SafeTransferLib.safeTransferETH(msg.sender, baseTokenOutputAmount);
            ERC20(address(pair)).safeTransfer(msg.sender, fractionalTokenOutputAmount);
        }

        // send user his rewards
        harvest();

        // emit an event
        emit Withdrawn(msg.sender, amountToRemove);
    }

    /**
     * @notice Withdraw staked tokens from the farm
     * @param amount Amount of the Pair position to withdraw
     */
    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(amount <= _balances[msg.sender], "Cannot withdraw more then you have staked");

        // remove the amount unstaked from the total balance
        _totalSupply = _totalSupply - amount;
        _balances[msg.sender] = _balances[msg.sender] - amount;

        uint256 batonFeeAmount = calculatePercentage(batonFactory.batonLPFee(), amount); // calculate batons fee

        // if the fee is more then 0 send the fee to batonMonitor
        if (batonFeeAmount > 0) {
            stakingToken.safeTransfer(batonMonitor, batonFeeAmount);
        }

        uint256 amountToWithdrawal = amount - batonFeeAmount;

        // transfer the tokens to user
        if (amountToWithdrawal > 0) {
            stakingToken.safeTransfer(msg.sender, amountToWithdrawal);
        }

        emit Withdrawn(msg.sender, amountToWithdrawal);
    }

    /*//////////////////////////////////////////////////////////////
                              GET REWARDS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allow a user to harvest the rewards accumulated up until this point
     * @notice If a fee is set then the contract will reduct the fee from the total sent to the fuction caller.
     */
    function harvest() public updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender]; // get users earned fees
        uint256 batonFeeAmount = calculatePercentage(batonFactory.batonRewardsFee(), reward); // calculate batons fee

        rewards[msg.sender] = 0; // clear the reward counter for the user

        // if the fee is more then 0 send the fee to batonMonitor
        if (batonFeeAmount > 0) {
            rewardsToken.safeTransfer(batonMonitor, batonFeeAmount);
        }

        uint256 amountToReward = reward - batonFeeAmount;

        if (amountToReward > 0) {
            // send the reward
            rewardsToken.safeTransfer(msg.sender, amountToReward);
        }

        // emit an event
        emit RewardPaid(msg.sender, amountToReward);
    }

    /**
     * @notice Withdraws staked tokens and harvests earned rewards in a single transaction.
     * @dev Calls both `withdraw` and `harvest` functions for the caller.
     */
    function withdrawAndHarvest() external {
        withdraw(_balances[msg.sender]);
        harvest();
    }

    /*//////////////////////////////////////////////////////////////
                           MIGRATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initiates the migration process by setting the migration target.
     * @dev Only callable by the contract owner when the pool is active.
     * @param _migration The address of the new contract to migrate to.
     */
    function initiateMigration(address _migration) external onlyOwner poolNotMigrated {
        require(_migration != address(0), "Please migrate to a valid address");
        require(_migration != address(this), "Cannot migrate to self");

        migration = _migration;

        // emit an event
        emit MigrationInitiated(_migration);
    }

    /**
     * @notice Migrates the unearned rewards to the new contract.
     * @dev Only callable by the BatonMonitor address when in migration mode and the pool is active.
     */
    function migrate() external onlyBatonMonitor inMigrationMode poolNotMigrated onlyWhenPoolActive {
        // calculate staking rewards still not rewarded
        uint256 rewardsToMigrate = _unearnedRewards();

        // complete migration
        migrationComplete = true;
        // stop farm
        periodFinish = block.timestamp;

        // transfer these rewards to the migration address.
        rewardsToken.safeTransfer(address(migration), rewardsToMigrate);

        // emit an event
        emit MigrationComplete(migration, rewardsToMigrate, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                            NOTIFY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Given a reward amount calculate the rewardRate per second
     * @notice Other fees may be incurred due to token spesific fees (some tokens may take a fee on transferFrom).
     * @dev Only callable by the rewards distributor or the contract owner. Updates the rewards state.
     *         This function should be called every time new rewards are added to the farm.
     * @param reward The amount of reward to be distributed.
     */
    function notifyRewardAmount(uint256 reward)
        external
        onlyRewardsDistributor
        poolNotMigrated
        updateReward(address(0))
    {
        require(reward > 0, "reward cannot be 0");
        rewardsToken.transferFrom(msg.sender, address(this), reward);

        uint256 surplusAmount = 0;
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
            periodFinish = block.timestamp + rewardsDuration;

            surplusAmount = reward - (rewardRate * rewardsDuration);
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / remaining;

            surplusAmount = (reward + leftover) - (rewardRate * remaining);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        require(rewardRate > 0, "reward rate = 0");
        require(rewardRate * rewardsDuration <= rewardsToken.balanceOf(address(this)), "Provided reward too high");

        // check for surplus, if it exist send back to rewards distributor
        if (surplusAmount != 0) {
            rewardsToken.safeTransfer(rewardsDistributor, surplusAmount);
            emit FoundSurplus(surplusAmount, rewardsDistributor);
        }

        lastUpdateTime = block.timestamp;
        emit RewardAdded(reward);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot withdraw the staking token");
        require(tokenAddress != address(rewardsToken), "Cannot withdraw the reward token");

        ERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * @notice Sets the address of the rewards distributor.
     * @dev Only callable by the contract owner.
     * @param _rewardsDistributor The address of the new rewards distributor.
     */
    function setRewardsDistributor(address _rewardsDistributor) external onlyOwner {
        require(_rewardsDistributor != address(0), "_rewardsDistributor cannot be address(0)");
        rewardsDistributor = _rewardsDistributor;

        emit UpdateRewardsDistributor(_rewardsDistributor);
    }

    /**
     * @notice Update the rewardsDuration.
     * @dev Only callable by the contract owner.
     * @param _rewardsDuration The new rewardsDuration
     */
    function setRewardsDuration(uint256 _rewardsDuration) public onlyOwner {
        require(block.timestamp >= periodFinish, "pool is running, cannot update the duration");
        rewardsDuration = _rewardsDuration;

        emit UpdateRewardsDuration(rewardsDuration);
    }

    /**
     * @notice pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice Modifier to update the rewards state before executing a function.
     * @dev Updates rewardPerTokenStored, lastUpdateTime, rewards[account], and userRewardPerTokenPaid[account].
     * @param account The address of the account for which to update the rewards state.
     */
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /**
     * @notice Modifier to ensure that only the rewards distributor or contract owner can call a function.
     * @dev Requires that the caller is either the rewards distributor or the contract owner.
     */
    modifier onlyRewardsDistributor() {
        require(msg.sender == rewardsDistributor || msg.sender == owner, "Caller is not RewardsDistributor contract");
        _;
    }

    /**
     * @notice Modifier to ensure that only the BatonMonitor contract can call a function.
     * @dev Requires that the caller is the BatonMonitor contract.
     */
    modifier onlyBatonMonitor() {
        require(msg.sender == batonMonitor, "Caller is not BatonMonitor contract");
        _;
    }

    /**
     * @notice Modifier to ensure that the contract is in migration mode.
     * @dev Requires that the migration address is not the zero address.
     */
    modifier inMigrationMode() {
        require(migration != address(0), "Contract owner must first call initiateMigration()");
        _;
    }

    /**
     * @notice Modifier to ensure that the pool is still active before calling a function.
     * @dev Requires that the migration has not been completed.
     */
    modifier poolNotMigrated() {
        require(!migrationComplete, "This contract has been migrated, you cannot deposit new funds.");
        _;
    }

    /**
     * @notice Modifier to ensure that the pool is active.
     * @dev Requires that block.timestamp < periodFinish
     */
    modifier onlyWhenPoolActive() {
        require(block.timestamp < periodFinish, "This farm is not active");
        _;
    }

    /**
     * @notice Modifier to ensure that the pool is still active before calling a function.
     * @dev Requires that the migration has not been completed.
     */
    modifier onlyWhenPoolOver() {
        require(block.timestamp >= periodFinish, "This farm is still active");
        _;
    }
}

/*
 * @author Inspiration from the work of Zapper and Beefy.
 */
contract BatonZapRouterV1 {
    using SafeTransferLib for address;

    function zapInETH(address payable farm, CaviarZapRouter.BuyParams calldata buyParams, CaviarZapRouter.AddParams calldata addParams) public payable {
        BatonFarm farm = BatonFarm(farm);
        Pair pair = Pair(farm.pair());

        // buy some fractional tokens
        pair.buy{value: buyParams.maxInputAmount}(
            buyParams.outputAmount, buyParams.maxInputAmount, buyParams.deadline
        );

        // add fractional tokens and eth
        uint256 lpTokenAmount = pair.add{value: address(this).balance}(
            addParams.baseTokenAmount,
            addParams.fractionalTokenAmount,
            addParams.minLpTokenAmount,
            addParams.minPrice,
            addParams.maxPrice,
            addParams.deadline
        );

        pair.lpToken().transfer(msg.sender, lpTokenAmount);
    }
}