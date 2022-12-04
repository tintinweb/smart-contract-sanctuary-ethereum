// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity 0.8.11;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
        // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

        // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

        // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
            // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

            // To write each character, shift the 3 bytes (18 bits) chunk
            // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
            // and apply logical AND with 0x3F which is the number of
            // the previous character in the ASCII table prior to the Base64 Table
            // The result is then added to the table to get the character to write,
            // and finally write it in the result pointer but with a left shift
            // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

        // When data `bytes` is not exactly 3 bytes long
        // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
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

// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.11;

import "base64/Base64.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/tokens/ERC1155.sol";
import "solmate/utils/SafeTransferLib.sol";
import "solmate/utils/FixedPointMathLib.sol";

import "./interfaces/IOptionSettlementEngine.sol";
import "./TokenURIGenerator.sol";

/**
 * Valorem Options V1 is a DeFi money lego enabling writing covered call and covered put, physically settled, options.
 * All written options are fully collateralized against an ERC-20 underlying asset and exercised with an
 * ERC-20 exercise asset using a pseudorandom number per unique option type for fair settlement. Options contracts
 * are issued as fungible ERC-1155 tokens, with each token representing a contract. Option writers are additionally issued
 * an ERC-1155 NFT representing a lot of contracts written for claiming collateral and exercise assignment. This design
 * eliminates the need for market price oracles, and allows for permission-less writing, and gas efficient transfer, of
 * a broad swath of traditional options.
 */

/// @title A settlement engine for options
/// @dev This settlement protocol does not support rebasing, fee-on-transfer, or ERC-777 tokens
/// @author 0xAlcibiades
/// @author Flip-Liquid
/// @author neodaoist
contract OptionSettlementEngine is ERC1155, IOptionSettlementEngine {
    /*//////////////////////////////////////////////////////////////
    //  State variables - Public
    //////////////////////////////////////////////////////////////*/

    /// @notice The protocol fee
    uint8 public immutable feeBps = 5;

    /// @notice Fee balance for a given token
    mapping(address => uint256) public feeBalance;

    /// @notice The address fees accrue to
    address public feeTo;

    /// @notice The contract for token uri generation
    ITokenURIGenerator public tokenURIGenerator;

    /*//////////////////////////////////////////////////////////////
    //  State variables - Internal
    //////////////////////////////////////////////////////////////*/

    /// @notice Accessor for Option contract details
    mapping(uint160 => Option) internal _option;

    /// @notice Accessor for option lot claim ticket details
    mapping(uint256 => OptionLotClaim) internal _claim;

    /// @notice Accessor for buckets of claims grouped by day
    /// @dev This is to enable O(constant) time options exercise. When options are written,
    /// the Claim struct in this mapping is updated to reflect the cumulative amount written
    /// on the day in question. write() will add unexercised options into the bucket
    /// corresponding to the # of days after the option type's creation.
    /// exercise() will randomly assign exercise to a bucket <= the current day.
    mapping(uint160 => OptionsDayBucket[]) internal _claimBucketByOption;

    /// @notice Maintains a mapping from option id to a list of unexercised bucket (indices)
    /// @dev Used during the assignment process to find claim buckets with unexercised
    /// options.
    mapping(uint160 => uint16[]) internal _unexercisedBucketsByOption;

    /// @notice Maps a bucket's index (in _claimBucketByOption) to a boolean indicating
    /// if the bucket has any unexercised options.
    /// @dev Used to determine if a bucket index needs to be added to
    /// _unexercisedBucketsByOption during write(). Set false if a bucket is fully
    /// exercised.
    mapping(uint160 => mapping(uint16 => bool)) internal _doesBucketIndexHaveUnexercisedOptions;

    /// @notice Accessor for mapping a claim id to its ClaimIndices
    mapping(uint256 => OptionLotClaimIndex[]) internal _claimIdToClaimIndexArray;

    /*//////////////////////////////////////////////////////////////
    //  Constructor
    //////////////////////////////////////////////////////////////*/

    /// @notice OptionSettlementEngine constructor
    /// @param _feeTo The address fees accrue to
    constructor(address _feeTo, address _tokenURIGenerator) {
        feeTo = _feeTo;
        tokenURIGenerator = ITokenURIGenerator(_tokenURIGenerator);
    }

    /*//////////////////////////////////////////////////////////////
    //  Accessors
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IOptionSettlementEngine
    function option(uint256 tokenId) external view returns (Option memory optionInfo) {
        (uint160 optionKey,) = decodeTokenId(tokenId);
        optionInfo = _option[optionKey];
    }

    /// @inheritdoc IOptionSettlementEngine
    function claim(uint256 tokenId) external view returns (OptionLotClaim memory claimInfo) {
        claimInfo = _claim[tokenId];
    }

    /// @inheritdoc IOptionSettlementEngine
    function underlying(uint256 tokenId) external view returns (Underlying memory underlyingPositions) {
        (uint160 optionKey, uint96 claimNum) = decodeTokenId(tokenId);

        if (!isOptionInitialized(optionKey)) {
            revert TokenNotFound(tokenId);
        }

        Option storage optionRecord = _option[optionKey];

        // token ID is an option
        if (claimNum == 0) {
            bool expired = (optionRecord.expiryTimestamp <= block.timestamp);
            underlyingPositions = Underlying({
                underlyingAsset: optionRecord.underlyingAsset,
                underlyingPosition: expired ? int256(0) : int256(uint256(optionRecord.underlyingAmount)),
                exerciseAsset: optionRecord.exerciseAsset,
                exercisePosition: expired ? int256(0) : -int256(uint256(optionRecord.exerciseAmount))
            });
        } else {
            // token ID is a claim
            (uint256 amountExerciseAsset, uint256 amountUnderlyingAsset) =
                _getPositionsForClaim(optionKey, tokenId, optionRecord);

            underlyingPositions = Underlying({
                underlyingAsset: optionRecord.underlyingAsset,
                underlyingPosition: int256(amountUnderlyingAsset),
                exerciseAsset: optionRecord.exerciseAsset,
                exercisePosition: int256(amountExerciseAsset)
            });
        }
    }

    /// @inheritdoc IOptionSettlementEngine
    function tokenType(uint256 tokenId) external pure returns (Type) {
        (, uint96 claimNum) = decodeTokenId(tokenId);
        if (claimNum == 0) {
            return Type.Option;
        }
        return Type.OptionLotClaim;
    }

    /// @inheritdoc IOptionSettlementEngine
    function isOptionInitialized(uint160 optionKey) public view returns (bool) {
        return _option[optionKey].underlyingAsset != address(0);
    }

    /*//////////////////////////////////////////////////////////////
    //  Token URI
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        Option memory optionInfo;
        (uint160 optionKey, uint96 claimNum) = decodeTokenId(tokenId);
        optionInfo = _option[optionKey];

        if (optionInfo.underlyingAsset == address(0x0)) {
            revert TokenNotFound(tokenId);
        }

        Type _type = claimNum == 0 ? Type.Option : Type.OptionLotClaim;

        ITokenURIGenerator.TokenURIParams memory params = ITokenURIGenerator.TokenURIParams({
            underlyingAsset: optionInfo.underlyingAsset,
            underlyingSymbol: ERC20(optionInfo.underlyingAsset).symbol(),
            exerciseAsset: optionInfo.exerciseAsset,
            exerciseSymbol: ERC20(optionInfo.exerciseAsset).symbol(),
            exerciseTimestamp: optionInfo.exerciseTimestamp,
            expiryTimestamp: optionInfo.expiryTimestamp,
            underlyingAmount: optionInfo.underlyingAmount,
            exerciseAmount: optionInfo.exerciseAmount,
            tokenType: _type
        });

        return tokenURIGenerator.constructTokenURI(params);
    }

    /*//////////////////////////////////////////////////////////////
    //  Token ID Encoding
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IOptionSettlementEngine
    function encodeTokenId(uint160 optionKey, uint96 claimNum) public pure returns (uint256 tokenId) {
        tokenId |= (uint256(optionKey) << 96);
        tokenId |= uint256(claimNum);
    }

    /// @inheritdoc IOptionSettlementEngine
    function decodeTokenId(uint256 tokenId) public pure returns (uint160 optionKey, uint96 claimNum) {
        // move key to lsb to fit into uint160
        optionKey = uint160(tokenId >> 96);

        // grab lower 96b of id for claim number
        uint256 claimNumMask = 0xFFFFFFFFFFFFFFFFFFFFFFFF;
        claimNum = uint96(tokenId & claimNumMask);
    }

    /*//////////////////////////////////////////////////////////////
    //  Write Options
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IOptionSettlementEngine
    function newOptionType(
        address underlyingAsset,
        uint96 underlyingAmount,
        address exerciseAsset,
        uint96 exerciseAmount,
        uint40 exerciseTimestamp,
        uint40 expiryTimestamp
    ) external returns (uint256 optionId) {
        // Check that a duplicate option type doesn't exist
        uint160 optionKey = uint160(
            bytes20(
                keccak256(
                    abi.encode(
                        underlyingAsset,
                        underlyingAmount,
                        exerciseAsset,
                        exerciseAmount,
                        exerciseTimestamp,
                        expiryTimestamp,
                        uint160(0),
                        uint96(0)
                    )
                )
            )
        );
        optionId = uint256(optionKey) << 96;

        // If it does, revert
        if (isOptionInitialized(optionKey)) {
            revert OptionsTypeExists(optionId);
        }

        // Make sure that expiry is at least 24 hours from now
        if (expiryTimestamp < (block.timestamp + 1 days)) {
            revert ExpiryWindowTooShort(expiryTimestamp);
        }

        // Ensure the exercise window is at least 24 hours
        if (expiryTimestamp < (exerciseTimestamp + 1 days)) {
            revert ExerciseWindowTooShort(exerciseTimestamp);
        }

        // The exercise and underlying assets can't be the same
        if (exerciseAsset == underlyingAsset) {
            revert InvalidAssets(exerciseAsset, underlyingAsset);
        }

        // Check that both tokens are ERC20 by instantiating them and checking supply
        ERC20 underlyingToken = ERC20(underlyingAsset);
        ERC20 exerciseToken = ERC20(exerciseAsset);

        // Check total supplies and ensure the option will be exercisable
        if (underlyingToken.totalSupply() < underlyingAmount || exerciseToken.totalSupply() < exerciseAmount) {
            revert InvalidAssets(underlyingAsset, exerciseAsset);
        }

        _option[optionKey] = Option({
            underlyingAsset: underlyingAsset,
            underlyingAmount: underlyingAmount,
            exerciseAsset: exerciseAsset,
            exerciseAmount: exerciseAmount,
            exerciseTimestamp: exerciseTimestamp,
            expiryTimestamp: expiryTimestamp,
            settlementSeed: optionKey,
            nextClaimNum: 1
        });

        emit NewOptionType(
            optionId,
            exerciseAsset,
            underlyingAsset,
            exerciseAmount,
            underlyingAmount,
            exerciseTimestamp,
            expiryTimestamp,
            1
            );
    }

    /// @inheritdoc IOptionSettlementEngine
    /// @dev Supplying claimId as 0 to the overloaded write signifies that a new
    /// claim NFT should be minted for the options lot, rather than being added
    /// as an existing claim.
    function write(uint256 optionId, uint112 amount) external returns (uint256 claimId) {
        return write(optionId, amount, 0);
    }

    /// @inheritdoc IOptionSettlementEngine
    function write(uint256 optionId, uint112 amount, uint256 claimId) public returns (uint256) {
        (uint160 optionKey, uint96 decodedClaimNum) = decodeTokenId(optionId);

        // optionId must be zero in lower 96b for provided option Id
        if (decodedClaimNum != 0) {
            revert InvalidOption(optionId);
        }

        // claim provided must match the option provided
        if (claimId != 0 && ((claimId >> 96) != (optionId >> 96))) {
            revert EncodedOptionIdInClaimIdDoesNotMatchProvidedOptionId(claimId, optionId);
        }

        if (amount == 0) {
            revert AmountWrittenCannotBeZero();
        }

        Option storage optionRecord = _option[optionKey];

        uint40 expiry = optionRecord.expiryTimestamp;
        if (expiry == 0) {
            revert InvalidOption(optionKey);
        }
        if (expiry <= block.timestamp) {
            revert ExpiredOption(optionId, expiry);
        }

        uint256 rxAmount = amount * optionRecord.underlyingAmount;
        uint256 fee = ((rxAmount / 10_000) * feeBps);
        address underlyingAsset = optionRecord.underlyingAsset;

        feeBalance[underlyingAsset] += fee;

        uint256 encodedClaimId = claimId;
        if (claimId == 0) {
            // create new claim
            // Increment the next token ID
            uint96 claimNum = optionRecord.nextClaimNum++;
            encodedClaimId = encodeTokenId(optionKey, claimNum);
            // Store info about the claim
            _claim[encodedClaimId] = OptionLotClaim({amountWritten: amount, claimed: false});
        } else {
            // check ownership of claim
            uint256 balance = balanceOf[msg.sender][encodedClaimId];
            if (balance != 1) {
                revert CallerDoesNotOwnClaimId(encodedClaimId);
            }

            // retrieve claim
            OptionLotClaim storage existingClaim = _claim[encodedClaimId];

            existingClaim.amountWritten += amount;
        }

        // Handle internal claim bucket accounting
        uint16 bucketIndex = _addOrUpdateClaimBucket(optionKey, amount);
        _addOrUpdateClaimIndex(encodedClaimId, bucketIndex, amount);

        if (claimId == 0) {
            // Mint options and claim token to writer
            uint256[] memory tokens = new uint256[](2);
            tokens[0] = optionId;
            tokens[1] = encodedClaimId;

            uint256[] memory amounts = new uint256[](2);
            amounts[0] = amount;
            amounts[1] = 1; // claim NFT

            _batchMint(msg.sender, tokens, amounts, "");
        } else {
            // Mint more options on existing claim to writer
            _mint(msg.sender, optionId, amount, "");
        }

        // Transfer the requisite underlying asset
        SafeTransferLib.safeTransferFrom(ERC20(underlyingAsset), msg.sender, address(this), (rxAmount + fee));

        emit FeeAccrued(underlyingAsset, msg.sender, fee);
        emit OptionsWritten(optionId, msg.sender, encodedClaimId, amount);

        return encodedClaimId;
    }

    /*//////////////////////////////////////////////////////////////
    //  Exercise Options
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IOptionSettlementEngine
    function exercise(uint256 optionId, uint112 amount) external {
        (uint160 optionKey, uint96 claimNum) = decodeTokenId(optionId);

        // option ID should be specified without claim in lower 96b
        if (claimNum != 0) {
            revert InvalidOption(optionId);
        }

        Option storage optionRecord = _option[optionKey];

        if (optionRecord.expiryTimestamp <= block.timestamp) {
            revert ExpiredOption(optionId, optionRecord.expiryTimestamp);
        }
        // Require that we have reached the exercise timestamp
        if (optionRecord.exerciseTimestamp >= block.timestamp) {
            revert ExerciseTooEarly(optionId, optionRecord.exerciseTimestamp);
        }

        if (this.balanceOf(msg.sender, optionId) < amount) {
            revert CallerHoldsInsufficientOptions(optionId, amount);
        }

        uint256 rxAmount = optionRecord.exerciseAmount * amount;
        uint256 txAmount = optionRecord.underlyingAmount * amount;
        uint256 fee = ((rxAmount / 10_000) * feeBps);
        address exerciseAsset = optionRecord.exerciseAsset;

        _assignExercise(optionKey, optionRecord, amount);

        feeBalance[exerciseAsset] += fee;

        _burn(msg.sender, optionId, amount);

        // Transfer in the requisite exercise asset
        SafeTransferLib.safeTransferFrom(ERC20(exerciseAsset), msg.sender, address(this), (rxAmount + fee));

        // Transfer out the underlying
        SafeTransferLib.safeTransfer(ERC20(optionRecord.underlyingAsset), msg.sender, txAmount);

        emit FeeAccrued(exerciseAsset, msg.sender, fee);
        emit OptionsExercised(optionId, msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
    //  Redeem Claims
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IOptionSettlementEngine
    /// @dev Fair assignment is performed here. After option expiry, any claim holder
    /// seeking to redeem their claim for the underlying and exercise assets will claim
    /// amounts proportional to the per-day amounts written on their options lot (i.e.
    /// the OptionLotClaimIndex data structions) weighted by the ratio of exercised to
    /// unexercised options on each of those days.
    function redeem(uint256 claimId) external {
        (uint160 optionKey, uint96 claimNum) = decodeTokenId(claimId);

        if (claimNum == 0) {
            revert InvalidClaim(claimId);
        }

        uint256 balance = this.balanceOf(msg.sender, claimId);

        if (balance != 1) {
            revert CallerDoesNotOwnClaimId(claimId);
        }

        OptionLotClaim storage claimRecord = _claim[claimId];
        Option storage optionRecord = _option[optionKey];

        if (optionRecord.expiryTimestamp > block.timestamp) {
            revert ClaimTooSoon(claimId, optionRecord.expiryTimestamp);
        }

        (uint256 exerciseAmount, uint256 underlyingAmount) = _getPositionsForClaim(optionKey, claimId, optionRecord);

        claimRecord.claimed = true;

        _burn(msg.sender, claimId, 1);

        if (exerciseAmount > 0) {
            SafeTransferLib.safeTransfer(ERC20(optionRecord.exerciseAsset), msg.sender, exerciseAmount);
        }

        if (underlyingAmount > 0) {
            SafeTransferLib.safeTransfer(ERC20(optionRecord.underlyingAsset), msg.sender, underlyingAmount);
        }

        emit ClaimRedeemed(
            claimId,
            optionKey,
            msg.sender,
            optionRecord.exerciseAsset,
            optionRecord.underlyingAsset,
            uint96(exerciseAmount),
            uint96(underlyingAmount)
            );
    }

    /*//////////////////////////////////////////////////////////////
    //  Protocol Admin
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IOptionSettlementEngine
    function setFeeTo(address newFeeTo) public {
        if (msg.sender != feeTo) {
            revert AccessControlViolation(msg.sender, feeTo);
        }
        if (newFeeTo == address(0)) {
            revert InvalidFeeToAddress(newFeeTo);
        }
        feeTo = newFeeTo;
    }

    /// @inheritdoc IOptionSettlementEngine
    function sweepFees(address[] memory tokens) public {
        address sendFeeTo = feeTo;
        address token;
        uint256 fee;
        uint256 sweep;
        uint256 numTokens = tokens.length;

        unchecked {
            for (uint256 i = 0; i < numTokens; i++) {
                // Get the token and balance to sweep
                token = tokens[i];
                fee = feeBalance[token];
                // Leave 1 wei here as a gas optimization
                if (fee > 1) {
                    sweep = fee - 1;
                    feeBalance[token] = 1;
                    SafeTransferLib.safeTransfer(ERC20(token), sendFeeTo, sweep);
                    emit FeeSwept(token, sendFeeTo, sweep);
                }
            }
        }
    }

    /// @inheritdoc IOptionSettlementEngine
    function setTokenURIGenerator(address newTokenURIGenerator) public {
        if (msg.sender != feeTo) {
            revert AccessControlViolation(msg.sender, feeTo);
        }
        if (newTokenURIGenerator == address(0)) {
            revert InvalidTokenURIGeneratorAddress(address(0));
        }

        tokenURIGenerator = ITokenURIGenerator(newTokenURIGenerator);
    }

    /*//////////////////////////////////////////////////////////////
    //  Internal Helper Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Performs fair exercise assignment by pseudorandomly selecting a claim
    /// bucket between the intial creation of the option type and "today". The buckets
    /// are then iterated from oldest to newest (looping if we reach "today") if the
    /// exercise amount overflows into another bucket. The seed for the pseudorandom
    /// index is updated accordingly on the option type.
    function _assignExercise(uint160 optionKey, Option storage optionRecord, uint112 amount) internal {
        // A bucket of the overall amounts written and exercised for all claims
        // on a given day
        OptionsDayBucket[] storage claimBucketArray = _claimBucketByOption[optionKey];
        uint16[] storage unexercisedBucketIndices = _unexercisedBucketsByOption[optionKey];
        uint16 unexercisedBucketsMod = uint16(unexercisedBucketIndices.length);
        uint16 unexercisedBucketsIndex = uint16(optionRecord.settlementSeed % unexercisedBucketsMod);
        while (amount > 0) {
            // get the claim bucket to assign
            uint16 bucketIndex = unexercisedBucketIndices[unexercisedBucketsIndex];
            OptionsDayBucket storage claimBucketInfo = claimBucketArray[bucketIndex];

            uint112 amountAvailable = claimBucketInfo.amountWritten - claimBucketInfo.amountExercised;
            uint112 amountPresentlyExercised;
            if (amountAvailable <= amount) {
                amount -= amountAvailable;
                amountPresentlyExercised = amountAvailable;
                // swap and pop, index mgmt
                uint16 overwrite = unexercisedBucketIndices[unexercisedBucketIndices.length - 1];
                unexercisedBucketIndices[unexercisedBucketsIndex] = overwrite;
                unexercisedBucketIndices.pop();
                unexercisedBucketsMod -= 1;
                _doesBucketIndexHaveUnexercisedOptions[optionKey][bucketIndex] = false;
            } else {
                amountPresentlyExercised = amount;
                amount = 0;
            }
            claimBucketInfo.amountExercised += amountPresentlyExercised;

            if (amount != 0) {
                unexercisedBucketsIndex = (unexercisedBucketsIndex + 1) % unexercisedBucketsMod;
            }
        }

        // update settlement seed
        optionRecord.settlementSeed =
            uint160(uint256(keccak256(abi.encode(optionRecord.settlementSeed, unexercisedBucketsIndex))));
    }

    /// @dev Help find a given days bucket by calculating days after epoch
    function _getDaysBucket() internal view returns (uint16) {
        return uint16(block.timestamp / 1 days);
    }

    /// @dev Get the amount of exercised and unexercised options for a given claim + day bucket combo
    function _getAmountExercised(OptionLotClaimIndex storage claimIndex, OptionsDayBucket storage claimBucketInfo)
        internal
        view
        returns (uint256 _exercised, uint256 _unexercised)
    {
        // The ratio of exercised to written options in the bucket multiplied by the
        // number of options actaully written in the claim.
        _exercised = FixedPointMathLib.mulDivDown(
            claimBucketInfo.amountExercised, claimIndex.amountWritten, claimBucketInfo.amountWritten
        );

        // The ratio of unexercised to written options in the bucket multiplied by the
        // number of options actually written in the claim.
        _unexercised = FixedPointMathLib.mulDivDown(
            claimBucketInfo.amountWritten - claimBucketInfo.amountExercised,
            claimIndex.amountWritten,
            claimBucketInfo.amountWritten
        );
    }

    /// @dev Get the exercise and underlying amounts for a claim
    function _getPositionsForClaim(uint160 optionKey, uint256 claimId, Option storage optionRecord)
        internal
        view
        returns (uint256 exerciseAmount, uint256 underlyingAmount)
    {
        OptionLotClaimIndex[] storage claimIndexArray = _claimIdToClaimIndexArray[claimId];
        for (uint256 i = 0; i < claimIndexArray.length; i++) {
            OptionLotClaimIndex storage claimIndex = claimIndexArray[i];
            OptionsDayBucket storage claimBucketInfo = _claimBucketByOption[optionKey][claimIndex.bucketIndex];
            (uint256 amountExercised, uint256 amountUnexercised) = _getAmountExercised(claimIndex, claimBucketInfo);
            exerciseAmount += optionRecord.exerciseAmount * amountExercised;
            underlyingAmount += optionRecord.underlyingAmount * amountUnexercised;
        }
    }

    /// @dev Help with internal options bucket accounting
    function _addOrUpdateClaimBucket(uint160 optionKey, uint112 amount) internal returns (uint16) {
        OptionsDayBucket[] storage claimBucketsInfo = _claimBucketByOption[optionKey];
        uint16[] storage unexercised = _unexercisedBucketsByOption[optionKey];
        OptionsDayBucket storage currentBucket;
        uint16 daysAfterEpoch = _getDaysBucket();
        uint16 bucketIndex = uint16(claimBucketsInfo.length);
        if (claimBucketsInfo.length == 0) {
            // add a new bucket none exist
            claimBucketsInfo.push(OptionsDayBucket(amount, 0, daysAfterEpoch));
            // update _unexercisedBucketsByOption and corresponding index mapping
            _updateUnexercisedBucketIndices(optionKey, bucketIndex, unexercised);
            return bucketIndex;
        }

        currentBucket = claimBucketsInfo[bucketIndex - 1];
        if (currentBucket.daysAfterEpoch < daysAfterEpoch) {
            claimBucketsInfo.push(OptionsDayBucket(amount, 0, daysAfterEpoch));
            _updateUnexercisedBucketIndices(optionKey, bucketIndex, unexercised);
        } else {
            // Update claim bucket for today
            currentBucket.amountWritten += amount;
            bucketIndex -= 1;

            // This block is executed if a bucket has been previously fully exercised
            // and now more options are being written into it
            if (!_doesBucketIndexHaveUnexercisedOptions[optionKey][bucketIndex]) {
                _updateUnexercisedBucketIndices(optionKey, bucketIndex, unexercised);
            }
        }

        return bucketIndex;
    }

    /// @dev Help with internal claim bucket accounting
    function _updateUnexercisedBucketIndices(
        uint160 optionKey,
        uint16 bucketIndex,
        uint16[] storage unexercisedBucketIndices
    ) internal {
        unexercisedBucketIndices.push(bucketIndex);
        _doesBucketIndexHaveUnexercisedOptions[optionKey][bucketIndex] = true;
    }

    /// @dev Help with internal claim bucket accounting
    function _addOrUpdateClaimIndex(uint256 claimId, uint16 bucketIndex, uint112 amount) internal {
        OptionLotClaimIndex storage lastIndex;
        OptionLotClaimIndex[] storage claimIndexArray = _claimIdToClaimIndexArray[claimId];
        uint256 arrayLength = claimIndexArray.length;

        // if no indices have been created previously, create one
        if (arrayLength == 0) {
            claimIndexArray.push(OptionLotClaimIndex({amountWritten: amount, bucketIndex: bucketIndex}));
            return;
        }

        lastIndex = claimIndexArray[arrayLength - 1];

        // create a new claim index if we're writing to a new index
        if (lastIndex.bucketIndex < bucketIndex) {
            claimIndexArray.push(OptionLotClaimIndex({amountWritten: amount, bucketIndex: bucketIndex}));
            return;
        }

        // update the amount written on the existing bucket index
        lastIndex.amountWritten += amount;
    }
}

// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.11;

import "base64/Base64.sol";
import "solmate/tokens/ERC20.sol";

import "./interfaces/IOptionSettlementEngine.sol";
import "./interfaces/ITokenURIGenerator.sol";

/// @title Library to dynamically generate Valorem token URIs
/// @author 0xAlcibiades
/// @author Flip-Liquid
/// @author neodaoist
contract TokenURIGenerator is ITokenURIGenerator {
    /// @inheritdoc ITokenURIGenerator
    function constructTokenURI(TokenURIParams memory params) public view returns (string memory) {
        string memory svg = generateNFT(params);

        /* solhint-disable quotes */
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"',
                        generateName(params),
                        '", "description": "',
                        generateDescription(params),
                        '", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '"}'
                    )
                )
            )
        );
        /* solhint-enable quotes */
    }

    /// @inheritdoc ITokenURIGenerator
    function generateName(TokenURIParams memory params) public pure returns (string memory) {
        (uint256 month, uint256 day, uint256 year) = _getDateUnits(params.expiryTimestamp);

        bytes memory yearDigits = bytes(_toString(year));
        bytes memory monthDigits = bytes(_toString(month));
        bytes memory dayDigits = bytes(_toString(day));

        return string(
            abi.encodePacked(
                _escapeQuotes(params.underlyingSymbol),
                _escapeQuotes(params.exerciseSymbol),
                yearDigits[2],
                yearDigits[3],
                monthDigits.length == 2 ? monthDigits[0] : bytes1(uint8(48)),
                monthDigits.length == 2 ? monthDigits[1] : monthDigits[0],
                dayDigits.length == 2 ? dayDigits[0] : bytes1(uint8(48)),
                dayDigits.length == 2 ? dayDigits[1] : dayDigits[0],
                "C"
            )
        );
    }

    /// @inheritdoc ITokenURIGenerator
    function generateDescription(TokenURIParams memory params) public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "NFT representing a Valorem options contract. ",
                params.underlyingSymbol,
                " Address: ",
                addressToString(params.underlyingAsset),
                ". ",
                params.exerciseSymbol,
                " Address: ",
                addressToString(params.exerciseAsset),
                "."
            )
        );
    }

    /// @inheritdoc ITokenURIGenerator
    function generateNFT(TokenURIParams memory params) public view returns (string memory) {
        uint8 underlyingDecimals = ERC20(params.underlyingAsset).decimals();
        uint8 exerciseDecimals = ERC20(params.exerciseAsset).decimals();

        return string(
            abi.encodePacked(
                "<svg width='400' height='300' viewBox='0 0 400 300' xmlns='http://www.w3.org/2000/svg'>",
                "<rect width='100%' height='100%' rx='12' ry='12'  fill='#3E5DC7' />",
                "<g transform='scale(5), translate(25, 18)' fill-opacity='0.15'>",
                "<path xmlns='http://www.w3.org/2000/svg' d='M69.3577 14.5031H29.7265L39.6312 0H0L19.8156 29L29.7265 14.5031L39.6312 29H19.8156H0L19.8156 58L39.6312 29L49.5421 43.5031L69.3577 14.5031Z' fill='white'/>",
                "</g>",
                _generateHeaderSection(params.underlyingSymbol, params.exerciseSymbol, params.tokenType),
                _generateAmountsSection(
                    params.underlyingAmount,
                    params.underlyingSymbol,
                    underlyingDecimals,
                    params.exerciseAmount,
                    params.exerciseSymbol,
                    exerciseDecimals
                ),
                _generateDateSection(params),
                "</svg>"
            )
        );
    }

    function _generateHeaderSection(
        string memory _underlyingSymbol,
        string memory _exerciseSymbol,
        IOptionSettlementEngine.Type _tokenType
    ) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                abi.encodePacked(
                    "<text x='16px' y='55px' font-size='32px' fill='#fff' font-family='Helvetica'>",
                    _underlyingSymbol,
                    " / ",
                    _exerciseSymbol,
                    "</text>"
                ),
                _tokenType == IOptionSettlementEngine.Type.Option
                    ?
                    "<text x='16px' y='80px' font-size='16' fill='#fff' font-family='Helvetica' font-weight='300'>Long Call</text>"
                    :
                    "<text x='16px' y='80px' font-size='16' fill='#fff' font-family='Helvetica' font-weight='300'>Short Call</text>"
            )
        );
    }

    function _generateAmountsSection(
        uint256 _underlyingAmount,
        string memory _underlyingSymbol,
        uint8 _underlyingDecimals,
        uint256 _exerciseAmount,
        string memory _exerciseSymbol,
        uint8 _exerciseDecimals
    ) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                "<text x='16px' y='116px' font-size='14' letter-spacing='0.01em' fill='#fff' font-family='Helvetica'>UNDERLYING ASSET</text>",
                _generateAmountString(_underlyingAmount, _underlyingDecimals, _underlyingSymbol, 16, 140),
                "<text x='16px' y='176px' font-size='14' letter-spacing='0.01em' fill='#fff' font-family='Helvetica'>EXERCISE ASSET</text>",
                _generateAmountString(_exerciseAmount, _exerciseDecimals, _exerciseSymbol, 16, 200)
            )
        );
    }

    function _generateDateSection(TokenURIParams memory params) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                "<text x='16px' y='236px' font-size='14' letter-spacing='0.01em' fill='#fff' font-family='Helvetica'>EXERCISE DATE</text>",
                _generateTimestampString(params.exerciseTimestamp, 16, 260),
                "<text x='200px' y='236px' font-size='14' letter-spacing='0.01em' fill='#fff' font-family='Helvetica'>EXPIRY DATE</text>",
                _generateTimestampString(params.expiryTimestamp, 200, 260)
            )
        );
    }

    function _generateAmountString(uint256 _amount, uint8 _decimals, string memory _symbol, uint256 _x, uint256 _y)
        internal
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                "<text x='",
                _toString(_x),
                "px' y='",
                _toString(_y),
                "px' font-size='18' fill='#fff' font-family='Helvetica' font-weight='300'>",
                _decimalString(_amount, _decimals, false),
                " ",
                _symbol,
                "</text>"
            )
        );
    }

    function _generateTimestampString(uint256 _timestamp, uint256 _x, uint256 _y)
        internal
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                "<text x='",
                _toString(_x),
                "px' y='",
                _toString(_y),
                "px' font-size='18' fill='#fff' font-family='Helvetica' font-weight='300'>",
                _generateDateString(_timestamp),
                "</text>"
            )
        );
    }

    /// @notice Utilities
    struct DecimalStringParams {
        // significant figures of decimal
        uint256 sigfigs;
        // length of decimal string
        uint8 bufferLength;
        // ending index for significant figures (funtion works backwards when copying sigfigs)
        uint8 sigfigIndex;
        // index of decimal place (0 if no decimal)
        uint8 decimalIndex;
        // start index for trailing/leading 0's for very small/large numbers
        uint8 zerosStartIndex;
        // end index for trailing/leading 0's for very small/large numbers
        uint8 zerosEndIndex;
        // true if decimal number is less than one
        bool isLessThanOne;
        // true if string should include "%"
        bool isPercent;
    }

    function _generateDecimalString(DecimalStringParams memory params) internal pure returns (string memory) {
        bytes memory buffer = new bytes(params.bufferLength);
        if (params.isPercent) {
            buffer[buffer.length - 1] = "%";
        }
        if (params.isLessThanOne) {
            buffer[0] = "0";
            buffer[1] = ".";
        }

        // add leading/trailing 0's
        for (uint256 zerosCursor = params.zerosStartIndex; zerosCursor < params.zerosEndIndex; zerosCursor++) {
            buffer[zerosCursor] = bytes1(uint8(48));
        }
        // add sigfigs
        while (params.sigfigs > 0) {
            if (params.decimalIndex > 0 && params.sigfigIndex == params.decimalIndex) {
                buffer[--params.sigfigIndex] = ".";
            }
            buffer[--params.sigfigIndex] = bytes1(uint8(uint256(48) + (params.sigfigs % 10)));
            params.sigfigs /= 10;
        }
        return string(buffer);
    }

    function _decimalString(uint256 number, uint8 decimals, bool isPercent) internal pure returns (string memory) {
        uint8 percentBufferOffset = isPercent ? 1 : 0;
        uint256 tenPowDecimals = 10 ** decimals;

        uint256 temp = number;
        uint8 digits = 0;
        uint8 numSigfigs = 0;
        while (temp != 0) {
            if (numSigfigs > 0) {
                // count all digits preceding least significant figure
                numSigfigs++;
            } else if (temp % 10 != 0) {
                numSigfigs++;
            }
            digits++;
            temp /= 10;
        }

        DecimalStringParams memory params = DecimalStringParams({
            sigfigs: uint256(0),
            bufferLength: uint8(0),
            sigfigIndex: uint8(0),
            decimalIndex: uint8(0),
            zerosStartIndex: uint8(0),
            zerosEndIndex: uint8(0),
            isLessThanOne: false,
            isPercent: false
        });
        params.isPercent = isPercent;
        if ((digits - numSigfigs) >= decimals) {
            // no decimals, ensure we preserve all trailing zeros
            params.sigfigs = number / tenPowDecimals;
            params.sigfigIndex = digits - decimals;
            params.bufferLength = params.sigfigIndex + percentBufferOffset;
        } else {
            // chop all trailing zeros for numbers with decimals
            params.sigfigs = number / (10 ** (digits - numSigfigs));
            if (tenPowDecimals > number) {
                // number is less tahn one
                // in this case, there may be leading zeros after the decimal place
                // that need to be added

                // offset leading zeros by two to account for leading '0.'
                params.zerosStartIndex = 2;
                params.zerosEndIndex = decimals - digits + 2;
                // params.zerosStartIndex = 4;
                params.sigfigIndex = numSigfigs + params.zerosEndIndex;
                params.bufferLength = params.sigfigIndex + percentBufferOffset;
                params.isLessThanOne = true;
            } else {
                // In this case, there are digits before and
                // after the decimal place
                params.sigfigIndex = numSigfigs + 1;
                params.decimalIndex = digits - decimals + 1;
            }
        }
        params.bufferLength = params.sigfigIndex + percentBufferOffset;
        return _generateDecimalString(params);
    }

    function _getDateUnits(uint256 _timestamp) internal pure returns (uint256 month, uint256 day, uint256 year) {
        int256 z = int256(_timestamp) / 86400 + 719468;
        int256 era = (z >= 0 ? z : z - 146096) / 146097;
        int256 doe = z - era * 146097;
        int256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
        int256 y = yoe + era * 400;
        int256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
        int256 mp = (5 * doy + 2) / 153;
        int256 d = doy - (153 * mp + 2) / 5 + 1;
        int256 m = mp + (mp < 10 ? int256(3) : -9);

        if (m <= 2) {
            y += 1;
        }

        month = uint256(m);
        day = uint256(d);
        year = uint256(y);
    }

    function _generateDateString(uint256 _timestamp) internal pure returns (string memory) {
        int256 z = int256(_timestamp) / 86400 + 719468;
        int256 era = (z >= 0 ? z : z - 146096) / 146097;
        int256 doe = z - era * 146097;
        int256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
        int256 y = yoe + era * 400;
        int256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
        int256 mp = (5 * doy + 2) / 153;
        int256 d = doy - (153 * mp + 2) / 5 + 1;
        int256 m = mp + (mp < 10 ? int256(3) : -9);

        if (m <= 2) {
            y += 1;
        }

        string memory s = "";

        if (m < 10) {
            s = _toString(0);
        }

        s = string(abi.encodePacked(s, _toString(uint256(m)), bytes1(0x2F)));

        if (d < 10) {
            s = string(abi.encodePacked(s, bytes1(0x30)));
        }

        s = string(abi.encodePacked(s, _toString(uint256(d)), bytes1(0x2F), _toString(uint256(y))));

        return string(s);
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        // This is borrowed from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol#L16

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function _escapeQuotes(string memory symbol) internal pure returns (string memory) {
        bytes memory symbolBytes = bytes(symbol);
        uint8 quotesCount = 0;
        for (uint8 i = 0; i < symbolBytes.length; i++) {
            // solhint-disable quotes
            if (symbolBytes[i] == '"') {
                quotesCount++;
            }
        }
        if (quotesCount > 0) {
            bytes memory escapedBytes = new bytes(
                symbolBytes.length + (quotesCount)
            );
            uint256 index;
            for (uint8 i = 0; i < symbolBytes.length; i++) {
                // solhint-disable quotes
                if (symbolBytes[i] == '"') {
                    escapedBytes[index++] = "\\";
                }
                escapedBytes[index++] = symbolBytes[i];
            }
            return string(escapedBytes);
        }
        return symbol;
    }

    bytes16 internal constant ALPHABET = "0123456789abcdef";

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function addressToString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), 20);
    }
}

// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.11;

/// @title A settlement engine for options
/// @author 0xAlcibiades
/// @author Flip-Liquid
/// @author neodaoist
interface IOptionSettlementEngine {
    /*//////////////////////////////////////////////////////////////
    //  Events
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when accrued protocol fees for a given token are swept to the
     * feeTo address.
     * @param token The token for which protocol fees are being swept.
     * @param feeTo The account to which fees are being swept.
     * @param amount The total amount being swept.
     */
    event FeeSwept(address indexed token, address indexed feeTo, uint256 amount);

    /**
     * @notice Emitted when a new unique options type is created.
     * @param optionId The id of the initial option created.
     * @param exerciseAsset The contract address of the exercise asset.
     * @param underlyingAsset The contract address of the underlying asset.
     * @param exerciseAmount The amount of the exercise asset to be exercised.
     * @param underlyingAmount The amount of the underlying asset in the option.
     * @param exerciseTimestamp The timestamp after which this option can be exercised.
     * @param expiryTimestamp The timestamp before which this option can be exercised.
     * @param nextClaimNum The next claim number.
     */
    event NewOptionType(
        uint256 indexed optionId,
        address indexed exerciseAsset,
        address indexed underlyingAsset,
        uint96 exerciseAmount,
        uint96 underlyingAmount,
        uint40 exerciseTimestamp,
        uint40 expiryTimestamp,
        uint96 nextClaimNum
    );

    /**
     * @notice Emitted when an option is exercised.
     * @param optionId The id of the option being exercised.
     * @param exercisee The contract address of the asset being exercised.
     * @param amount The amount of the exercissee being exercised.
     */
    event OptionsExercised(uint256 indexed optionId, address indexed exercisee, uint112 amount);

    /**
     * @notice Emitted when a new option is written.
     * @param optionId The id of the newly written option.
     * @param writer The address of the writer of the new option.
     * @param claimId The claim ID for the option.
     * @param amount The amount of options written.
     */
    event OptionsWritten(uint256 indexed optionId, address indexed writer, uint256 indexed claimId, uint112 amount);

    /**
     * @notice Emitted when protocol fees are accrued for a given asset.
     * @dev Emitted on write() when fees are accrued on the underlying asset,
     * or exercise() when fees are accrued on the exercise asset.
     * @param asset Asset for which fees are accrued.
     * @param payor The address paying the fee.
     * @param amount The amount of fees which are accrued.
     */
    event FeeAccrued(address indexed asset, address indexed payor, uint256 amount);

    /**
     * @notice Emitted when a claim is redeemed.
     * @param claimId The id of the claim being redeemed.
     * @param optionId The option id associated with the redeeming claim.
     * @param redeemer The address redeeming the claim.
     * @param exerciseAsset The exercise asset of the option.
     * @param underlyingAsset The underlying asset of the option.
     * @param exerciseAmount The amount of options being
     * @param underlyingAmount The amount of underlying
     */
    event ClaimRedeemed(
        uint256 indexed claimId,
        uint256 indexed optionId,
        address indexed redeemer,
        address exerciseAsset,
        address underlyingAsset,
        uint96 exerciseAmount,
        uint96 underlyingAmount
    );

    /**
     * @notice Emitted when an option id is exercised and assigned to a particular claim NFT.
     * @param claimId The claim NFT id being assigned.
     * @param optionId The id of the option being exercised.
     * @param amountAssigned The total amount of options contracts assigned.
     */
    event ExerciseAssigned(uint256 indexed claimId, uint256 indexed optionId, uint112 amountAssigned);

    /*//////////////////////////////////////////////////////////////
    //  Errors
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice The requested token is not found.
     * @param token token requested.
     */
    error TokenNotFound(uint256 token);

    /**
     * @notice The caller doesn't have permission to access that function.
     * @param accessor The requesting address.
     * @param permissioned The address which has the requisite permissions.
     */
    error AccessControlViolation(address accessor, address permissioned);

    /**
     * @notice Invalid fee to address.
     * @param feeTo The feeTo address.
     */
    error InvalidFeeToAddress(address feeTo);

    /**
     * @notice Invalid TokenURIGenerator address.
     * @param tokenURIGenerator The tokenURIGenerator address.
     */
    error InvalidTokenURIGeneratorAddress(address tokenURIGenerator);

    /**
     * @notice This options chain already exists and thus cannot be created.
     * @param optionId The id and hash of the options chain.
     */
    error OptionsTypeExists(uint256 optionId);

    /**
     * @notice The expiry timestamp is less than 24 hours from now.
     * @param expiry Timestamp of expiry
     */
    error ExpiryWindowTooShort(uint40 expiry);

    /**
     * @notice The option exercise window is less than 24 hours long.
     * @param exercise The timestamp supplied for exercise.
     */
    error ExerciseWindowTooShort(uint40 exercise);

    /**
     * @notice The assets specified are invalid or duplicate.
     * @param asset1 Supplied asset.
     * @param asset2 Supplied asset.
     */
    error InvalidAssets(address asset1, address asset2);

    /**
     * @notice The token specified is not an option.
     * @param token The supplied token.
     */
    error InvalidOption(uint256 token);

    /**
     * @notice The token specified is not a claim.
     * @param token The supplied token.
     */
    error InvalidClaim(uint256 token);

    /**
     * @notice Provided claimId does not match provided option id in the upper 160b
     * encoding the corresponding option ID for which the claim was written.
     * @param claimId The provided claim ID.
     * @param optionId The provided option ID.
     */
    error EncodedOptionIdInClaimIdDoesNotMatchProvidedOptionId(uint256 claimId, uint256 optionId);

    /**
     * @notice The optionId specified expired at expiry.
     * @param optionId The id of the expired option.
     * @param expiry The time of expiry of the supplied option Id.
     */
    error ExpiredOption(uint256 optionId, uint40 expiry);

    /**
     * @notice This option cannot yet be exercised.
     * @param optionId Supplied option ID.
     * @param exercise The time when the optionId can be exercised.
     */
    error ExerciseTooEarly(uint256 optionId, uint40 exercise);

    /**
     * @notice This claim is not owned by the caller.
     * @param claimId Supplied claim ID.
     */
    error CallerDoesNotOwnClaimId(uint256 claimId);

    /**
     * @notice The caller does not have enough of the option to exercise the amount
     * specified.
     * @param optionId The supplied option id.
     * @param amount The amount of the supplied option requested for exercise.
     */
    error CallerHoldsInsufficientOptions(uint256 optionId, uint112 amount);

    /**
     * @notice You can't claim before expiry.
     * @param claimId Supplied claim ID.
     * @param expiry timestamp at which the options chain expires
     */
    error ClaimTooSoon(uint256 claimId, uint40 expiry);

    /// @notice The amount provided to write() must be > 0.
    error AmountWrittenCannotBeZero();

    /*//////////////////////////////////////////////////////////////
    //  Data structures
    //////////////////////////////////////////////////////////////*/

    /// @dev This enumeration is used to determine the type of an ERC1155 subtoken in the engine.
    enum Type {
        None,
        Option,
        OptionLotClaim
    }

    /// @dev This struct contains the data about an options type associated with an ERC-1155 token.
    struct Option {
        /// @param underlyingAsset The underlying asset to be received
        address underlyingAsset;
        /// @param underlyingAmount The amount of the underlying asset contained within an option contract of this type
        uint96 underlyingAmount;
        /// @param exerciseAsset The address of the asset needed for exercise
        address exerciseAsset;
        /// @param exerciseAmount The amount of the exercise asset required to exercise this option
        uint96 exerciseAmount;
        /// @param exerciseTimestamp The timestamp after which this option can be exercised
        uint40 exerciseTimestamp;
        /// @param expiryTimestamp The timestamp before which this option can be exercised
        uint40 expiryTimestamp;
        /// @param settlementSeed Random seed created at the time of option type creation
        uint160 settlementSeed;
        /// @param nextClaimNum Which option was written
        uint96 nextClaimNum;
    }

    /**
     * @dev This struct contains the data about a lot of options written for a particular option type.
     * When writing an amount of options of a particular type, the writer will be issued an ERC 1155 NFT
     * that represents a claim to the underlying and exercise assets of the options lot, to be claimed after
     * expiry of the option. The amount of each (underlying asset and exercise asset) paid to the claimant upon
     * redeeming their claim NFT depends on the option type, the amount of options written in their options lot
     * (represented in this struct) and what portion of their lot was exercised before expiry.
     */
    struct OptionLotClaim {
        /// @param amountWritten The number of options written in this option lot claim
        uint112 amountWritten;
        /// @param claimed Whether or not this option lot has been claimed by the writer
        bool claimed;
    }

    /**
     * @dev Options lots are able to have options added to them on after the initial
     * writing. This struct is used to keep track of how many options in a single lot
     * are written on each day, in order to correctly perform fair assignment.
     */
    struct OptionLotClaimIndex {
        /// @param amountWritten The amount of options written on a given day/bucket
        uint112 amountWritten;
        /// @param bucketIndex The index of the OptionsDayBucket in which the options are written
        uint16 bucketIndex;
    }

    /**
     * @dev Represents the total amount of options written and exercised for a group of
     * claims bucketed by day. Used in fair assignement to calculate the ratio of
     * underlying to exercise assets to be transferred to claimants.
     */
    struct OptionsDayBucket {
        /// @param amountWritten The number of options written in this bucket
        uint112 amountWritten;
        /// @param amountExercised The number of options exercised in this bucket
        uint112 amountExercised;
        /// @param daysAfterEpoch Which day this bucket falls on, in offset from epoch
        uint16 daysAfterEpoch;
    }

    /**
     * @dev Struct used in returning data regarding positions underlying a claim or option.
     */
    struct Underlying {
        /// @param underlyingAsset address of the underlying asset erc20
        address underlyingAsset;
        /// @param underlyingPosition position on the underlying asset
        int256 underlyingPosition;
        /// @param exerciseAsset address of the exercise asset erc20
        address exerciseAsset;
        /// @param exercisePosition position on the exercise asset
        int256 exercisePosition;
    }

    /*//////////////////////////////////////////////////////////////
    //  Accessors
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns Option struct details about a given tokenID if that token is
     * an option.
     * @param tokenId The id of the option.
     * @return optionInfo The Option struct for tokenId.
     */
    function option(uint256 tokenId) external view returns (Option memory optionInfo);

    /**
     * @notice Returns OptionLotClaim struct details about a given tokenId if that token is a
     * claim NFT.
     * @param tokenId The id of the claim.
     * @return claimInfo The Claim struct for tokenId.
     */
    function claim(uint256 tokenId) external view returns (OptionLotClaim memory claimInfo);

    /**
     * @notice Information about the position underlying a token, useful for determining value.
     * When supplied an Option Lot Claim id, this function returns the total amounts of underlying
     * and exercise assets currently associated with a given options lot.
     * @param tokenId The token id for which to retrieve the Underlying position.
     * @return underlyingPositions The Underlying struct for the supplied tokenId.
     */
    function underlying(uint256 tokenId) external view returns (Underlying memory underlyingPositions);

    /**
     * @notice Returns the token type (e.g. Option/OptionLotClaim) for a given token Id
     * @param tokenId The id of the option or claim.
     * @return The enum (uint8) Type of the tokenId
     */
    function tokenType(uint256 tokenId) external view returns (Type);

    /**
     * @notice Check to see if an option is already initialized
     * @param optionKey The option key to check
     * @return Whether or not the option is initialized
     */
    function isOptionInitialized(uint160 optionKey) external view returns (bool);

    /*//////////////////////////////////////////////////////////////
    //  Token ID Encoding
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Encode the supplied option id and claim id
     * @dev Option and claim token ids are encoded as follows:
     *
     *   MSb
     *   0000 0000   0000 0000   0000 0000   0000 0000 ┐
     *   0000 0000   0000 0000   0000 0000   0000 0000 │
     *   0000 0000   0000 0000   0000 0000   0000 0000 │ 160b option key, created from hash of Option struct
     *   0000 0000   0000 0000   0000 0000   0000 0000 │
     *   0000 0000   0000 0000   0000 0000   0000 0000 │
     *   0000 0000   0000 0000   0000 0000   0000 0000 ┘
     *   0000 0000   0000 0000   0000 0000   0000 0000 ┐
     *   0000 0000   0000 0000   0000 0000   0000 0000 │ 96b auto-incrementing option lot claim number
     *   0000 0000   0000 0000   0000 0000   0000 0000 ┘
     *                                             LSb
     * @param optionKey The optionKey to encode
     * @param claimNum The claimNum to encode
     * @return tokenId The encoded token id
     */
    function encodeTokenId(uint160 optionKey, uint96 claimNum) external pure returns (uint256 tokenId);

    /**
     * @notice Decode the supplied token id
     * @dev See encodeTokenId() for encoding scheme
     * @param tokenId The token id to decode
     * @return optionKey claimNum The decoded components of the id as described above, padded as required
     */
    function decodeTokenId(uint256 tokenId) external pure returns (uint160 optionKey, uint96 claimNum);

    /*//////////////////////////////////////////////////////////////
    //  Write Options
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Create a new option type if it doesn't already exist
     * @param underlyingAsset The contract address of the underlying asset.
     * @param underlyingAmount The amount of the underlying asset in the option.
     * @param exerciseAsset The contract address of the exercise asset.
     * @param exerciseAmount The amount of the exercise asset to be exercised.
     * @param exerciseTimestamp The timestamp after which this option can be exercised.
     * @param expiryTimestamp The timestamp before which this option can be exercised.
     * @return optionId The optionId for the option.
     */
    function newOptionType(
        address underlyingAsset,
        uint96 underlyingAmount,
        address exerciseAsset,
        uint96 exerciseAmount,
        uint40 exerciseTimestamp,
        uint40 expiryTimestamp
    ) external returns (uint256 optionId);

    /**
     * @notice Writes a specified amount of the specified option, returning claim NFT id.
     * @param optionId The desired option id to write.
     * @param amount The desired number of options to write.
     * @return claimId The claim NFT id for the option bundle.
     */
    function write(uint256 optionId, uint112 amount) external returns (uint256 claimId);

    /**
     * @notice This override allows additional options to be written against a particular
     * claim id.
     * @param optionId The desired option id to write.
     * @param amount The desired number of options to write.
     * @param claimId The claimId for the options lot to which the caller will add options
     * @return claimId The claim NFT id for the option bundle.
     */
    function write(uint256 optionId, uint112 amount, uint256 claimId) external returns (uint256);

    /*//////////////////////////////////////////////////////////////
    //  Exercise Options
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Exercises specified amount of optionId, transferring in the exercise asset,
     * and transferring out the underlying asset if requirements are met. Will revert with
     * an underflow/overflow if the user does not have the required assets.
     * @param optionId The option id to exercise.
     * @param amount The amount of option id to exercise.
     */
    function exercise(uint256 optionId, uint112 amount) external;

    /*//////////////////////////////////////////////////////////////
    //  Redeem Claims
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Redeem a claim NFT, transfers the underlying tokens.
     * @param claimId The ID of the claim to redeem.
     */
    function redeem(uint256 claimId) external;

    /*//////////////////////////////////////////////////////////////
    //  Protocol Admin
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice The protocol fee, expressed in basis points.
     * @return The fee in basis points.
     */
    function feeBps() external view returns (uint8);

    /**
     * @notice The balance of protocol fees for a given token which have not yet
     * been swept.
     * @param token The token for the unswept fee balance.
     * @return The balance of unswept fees.
     */
    function feeBalance(address token) external view returns (uint256);

    /**
     * @notice Returns the address to which protocol fees are swept.
     * @return The address to which fees are swept
     */
    function feeTo() external view returns (address);

    /**
     * @notice Updates the address fees can be swept to.
     * @param newFeeTo The new address to which fees will be swept.
     */
    function setFeeTo(address newFeeTo) external;

    /**
     * @notice Sweeps fees to the feeTo address if there are more than 0 wei for
     * each address in tokens.
     * @param tokens The tokens for which fees will be swept to the feeTo address.
     */
    function sweepFees(address[] memory tokens) external;

    /**
     * @notice Updates the contract address for generating the token URI for claim NFTs.
     * @param newTokenURIGenerator The address of the new ITokenURIGenerator contract.
     */
    function setTokenURIGenerator(address newTokenURIGenerator) external;
}

// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.11;

import "./IOptionSettlementEngine.sol";

/// @title A token URI geneartor for Claim NFTs
/// @author 0xAlcibiades
/// @author Flip-Liquid
/// @author neodaoist
interface ITokenURIGenerator {
    struct TokenURIParams {
        /// @param underlyingAsset The underlying asset to be received
        address underlyingAsset;
        /// @param underlyingSymbol The symbol of the underlying asset
        string underlyingSymbol;
        /// @param exerciseAsset The address of the asset needed for exercise
        address exerciseAsset;
        /// @param exerciseSymbol The symbol of the underlying asset
        string exerciseSymbol;
        /// @param exerciseTimestamp The timestamp after which this option may be exercised
        uint40 exerciseTimestamp;
        /// @param expiryTimestamp The timestamp before which this option must be exercised
        uint40 expiryTimestamp;
        /// @param underlyingAmount The amount of the underlying asset contained within an option contract of this type
        uint96 underlyingAmount;
        /// @param exerciseAmount The amount of the exercise asset required to exercise this option
        uint96 exerciseAmount;
        /// @param tokenType Option or Claim
        IOptionSettlementEngine.Type tokenType;
    }

    /**
     * @notice Constructs a URI for a claim NFT, encoding an SVG based on parameters of the claims lot.
     * @param params Parameters for the token URI.
     * @return A string with the SVG encoded in Base64.
     */
    function constructTokenURI(TokenURIParams memory params) external view returns (string memory);

    /**
     * @notice Generates a name for the NFT based on the supplied params.
     * @param params Parameters for the token URI.
     * @return A generated name for the NFT.
     */
    function generateName(TokenURIParams memory params) external pure returns (string memory);

    /**
     * @notice Generates a description for the NFT based on the supplied params.
     * @param params Parameters for the token URI.
     * @return A generated description for the NFT.
     */
    function generateDescription(TokenURIParams memory params) external pure returns (string memory);

    /**
     * @notice Generates a svg for the NFT based on the supplied params.
     * @param params Parameters for the token URI.
     * @return A generated svg for the NFT.
     */
    function generateNFT(TokenURIParams memory params) external view returns (string memory);
}