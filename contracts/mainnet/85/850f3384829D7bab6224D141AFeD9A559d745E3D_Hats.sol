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

    mapping(address => mapping(uint256 => uint256)) internal _balanceOf;

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

        _balanceOf[from][id] -= amount;
        _balanceOf[to][id] += amount;

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

            _balanceOf[from][id] -= amount;
            _balanceOf[to][id] += amount;

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

    function balanceOf(address owner, uint256 id) public view virtual returns (uint256 balance) {
        balance = _balanceOf[owner][id];
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
                balances[i] = _balanceOf[owners[i]][ids[i]];
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
        _balanceOf[to][id] += amount;

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
            _balanceOf[to][ids[i]] += amounts[i];

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
            _balanceOf[from][ids[i]] -= amounts[i];

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
        _balanceOf[from][id] -= amount;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library to encode and decode strings in Base64.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/utils/Base64.sol)
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base64.sol)
library Base64 {
    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    function encode(bytes memory data, bool fileSafe, bool noPadding) internal pure returns (string memory result) {
        assembly {
            let dataLength := mload(data)

            if dataLength {
                // Multiply by 4/3 rounded up.
                // The `shl(2, ...)` is equivalent to multiplying by 4.
                let encodedLength := shl(2, div(add(dataLength, 2), 3))

                // Set `result` to point to the start of the free memory.
                result := mload(0x40)

                // Store the table into the scratch space.
                // Offsetted by -1 byte so that the `mload` will load the character.
                // We will rewrite the free memory pointer at `0x40` later with
                // the allocated size.
                // The magic constant 0x0230 will translate "-_" + "+/".
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, sub("ghijklmnopqrstuvwxyz0123456789-_", mul(iszero(fileSafe), 0x0230)))

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, encodedLength)

                // Run over the input, 3 bytes at a time.
                // prettier-ignore
                for {} 1 {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(    ptr    , mload(and(shr(18, input), 0x3F)))
                    mstore8(add(ptr, 1), mload(and(shr(12, input), 0x3F)))
                    mstore8(add(ptr, 2), mload(and(shr( 6, input), 0x3F)))
                    mstore8(add(ptr, 3), mload(and(        input , 0x3F)))
                    
                    ptr := add(ptr, 4) // Advance 4 bytes.
                    // prettier-ignore
                    if iszero(lt(ptr, end)) { break }
                }

                let r := mod(dataLength, 3)

                switch noPadding
                case 0 {
                    // Offset `ptr` and pad with '='. We can simply write over the end.
                    mstore8(sub(ptr, iszero(iszero(r))), 0x3d) // Pad at `ptr - 1` if `r > 0`.
                    mstore8(sub(ptr, shl(1, eq(r, 1))), 0x3d) // Pad at `ptr - 2` if `r == 1`.
                    // Write the length of the string.
                    mstore(result, encodedLength)
                }
                default {
                    // Write the length of the string.
                    mstore(result, sub(encodedLength, add(iszero(iszero(r)), eq(r, 1))))
                }

                // Allocate the memory for the string.
                // Add 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(31)))
            }
        }
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, false, false)`.
    function encode(bytes memory data) internal pure returns (string memory result) {
        result = encode(data, false, false);
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, fileSafe, false)`.
    function encode(bytes memory data, bool fileSafe) internal pure returns (string memory result) {
        result = encode(data, fileSafe, false);
    }

    /// @dev Decodes base64 encoded `data`.
    ///
    /// Supports:
    /// - RFC 4648 (both standard and file-safe mode).
    /// - RFC 3501 (63: ',').
    ///
    /// Does not support:
    /// - Line breaks.
    ///
    /// Note: For performance reasons,
    /// this function will NOT revert on invalid `data` inputs.
    /// Outputs for invalid inputs will simply be undefined behaviour.
    /// It is the user's responsibility to ensure that the `data`
    /// is a valid base64 encoded string.
    function decode(string memory data) internal pure returns (bytes memory result) {
        assembly {
            let dataLength := mload(data)

            if dataLength {
                let end := add(data, dataLength)
                let decodedLength := mul(shr(2, dataLength), 3)

                switch and(dataLength, 3)
                case 0 {
                    // If padded.
                    decodedLength := sub(
                        decodedLength,
                        add(eq(and(mload(end), 0xFF), 0x3d), eq(and(mload(end), 0xFFFF), 0x3d3d))
                    )
                }
                default {
                    // If non-padded.
                    decodedLength := add(decodedLength, sub(and(dataLength, 3), 1))
                }

                result := mload(0x40)

                // Write the length of the string.
                mstore(result, decodedLength)

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)

                // Load the table into the scratch space.
                // Constants are optimized for smaller bytecode with zero gas overhead.
                // `m` also doubles as the mask of the upper 6 bits.
                let m := 0xfc000000fc00686c7074787c8084888c9094989ca0a4a8acb0b4b8bcc0c4c8cc
                mstore(0x5b, m)
                mstore(0x3b, 0x04080c1014181c2024282c3034383c4044484c5054585c6064)
                mstore(0x1a, 0xf8fcf800fcd0d4d8dce0e4e8ecf0f4)

                // prettier-ignore
                for {} 1 {} {
                    // Read 4 bytes.
                    data := add(data, 4)
                    let input := mload(data)

                    // Write 3 bytes.
                    mstore(ptr, or(
                        and(m, mload(byte(28, input))),
                        shr(6, or(
                            and(m, mload(byte(29, input))),
                            shr(6, or(
                                and(m, mload(byte(30, input))),
                                shr(6, mload(byte(31, input)))
                            ))
                        ))
                    ))

                    ptr := add(ptr, 3)
                    
                    // prettier-ignore
                    if iszero(lt(data, end)) { break }
                }

                // Allocate the memory for the string.
                // Add 32 + 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(add(result, decodedLength), 63), not(31)))

                // Restore the zero slot.
                mstore(0x60, 0)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for converting numbers into strings and other string operations.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/utils/LibString.sol)
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    /// @dev The `length` of the output is too small to contain all the hex digits.
    error HexLengthInsufficient();

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    /// @dev The constant returned when the `search` is not found in the string.
    uint256 internal constant NOT_FOUND = uint256(int256(-1));

    /// -----------------------------------------------------------------------
    /// Decimal Operations
    /// -----------------------------------------------------------------------

    /// @dev Returns the base 10 decimal representation of `value`.
    function toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    /// -----------------------------------------------------------------------
    /// Hexadecimal Operations
    /// -----------------------------------------------------------------------

    /// @dev Returns the hexadecimal representation of `value`,
    /// left-padded to an input length of `length` bytes.
    /// The output is prefixed with "0x" encoded using 2 hexadecimal digits per byte,
    /// giving a total length of `length * 2 + 2` bytes.
    /// Reverts if `length` is too small for the output to contain all the digits.
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the trailing zeros padding, `length * 2` bytes
            // for the digits, 0x02 bytes for the prefix, and 0x20 bytes for the length.
            // We add 0x20 to the total and round down to a multiple of 0x20.
            // (0x20 + 0x20 + 0x02 + 0x20) = 0x62.
            let m := add(start, and(add(shl(1, length), 0x62), not(0x1f)))
            // Allocate the memory.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end to calculate the length later.
            let end := str
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            let temp := value
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for {} 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                length := sub(length, 1)
                // prettier-ignore
                if iszero(length) { break }
            }

            if temp {
                // Store the function selector of `HexLengthInsufficient()`.
                mstore(0x00, 0x2194895a)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 0x20)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is prefixed with "0x" and encoded using 2 hexadecimal digits per byte.
    /// As address are 20 bytes long, the output will left-padded to have
    /// a length of `20 * 2 + 2` bytes.
    function toHexString(uint256 value) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the trailing zeros padding, 0x20 bytes for the length,
            // 0x02 bytes for the prefix, and 0x40 bytes for the digits.
            // The next multiple of 0x20 above (0x20 + 0x20 + 0x02 + 0x40) is 0xa0.
            let m := add(start, 0xa0)
            // Allocate the memory.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end to calculate the length later.
            let end := str
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 0x20)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is prefixed with "0x" and encoded using 2 hexadecimal digits per byte.
    function toHexString(address value) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the length, 0x02 bytes for the prefix,
            // and 0x28 bytes for the digits.
            // The next multiple of 0x20 above (0x20 + 0x02 + 0x28) is 0x60.
            str := add(start, 0x60)

            // Allocate the memory.
            mstore(0x40, str)
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            let length := 20
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                length := sub(length, 1)
                // prettier-ignore
                if iszero(length) { break }
            }

            // Move the pointer and write the "0x" prefix.
            str := sub(str, 32)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, 42)
        }
    }

    /// -----------------------------------------------------------------------
    /// Other String Operations
    /// -----------------------------------------------------------------------

    // For performance and bytecode compactness, all indices of the following operations
    // are byte (ASCII) offsets, not UTF character offsets.

    /// @dev Returns `subject` all occurances of `search` replaced with `replacement`.
    function replace(
        string memory subject,
        string memory search,
        string memory replacement
    ) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            let searchLength := mload(search)
            let replacementLength := mload(replacement)

            subject := add(subject, 0x20)
            search := add(search, 0x20)
            replacement := add(replacement, 0x20)
            result := add(mload(0x40), 0x20)

            let subjectEnd := add(subject, subjectLength)
            if iszero(gt(searchLength, subjectLength)) {
                let subjectSearchEnd := add(sub(subjectEnd, searchLength), 1)
                let h := 0
                if iszero(lt(searchLength, 32)) {
                    h := keccak256(search, searchLength)
                }
                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(search)
                // prettier-ignore
                for {} 1 {} {
                    let t := mload(subject)
                    // Whether the first `searchLength % 32` bytes of 
                    // `subject` and `search` matches.
                    if iszero(shr(m, xor(t, s))) {
                        if h {
                            if iszero(eq(keccak256(subject, searchLength), h)) {
                                mstore(result, t)
                                result := add(result, 1)
                                subject := add(subject, 1)
                                // prettier-ignore
                                if iszero(lt(subject, subjectSearchEnd)) { break }
                                continue
                            }
                        }
                        // Copy the `replacement` one word at a time.
                        // prettier-ignore
                        for { let o := 0 } 1 {} {
                            mstore(add(result, o), mload(add(replacement, o)))
                            o := add(o, 0x20)
                            // prettier-ignore
                            if iszero(lt(o, replacementLength)) { break }
                        }
                        result := add(result, replacementLength)
                        subject := add(subject, searchLength)
                        if searchLength {
                            // prettier-ignore
                            if iszero(lt(subject, subjectSearchEnd)) { break }
                            continue
                        }
                    }
                    mstore(result, t)
                    result := add(result, 1)
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
            }

            let resultRemainder := result
            result := add(mload(0x40), 0x20)
            let k := add(sub(resultRemainder, result), sub(subjectEnd, subject))
            // Copy the rest of the string one word at a time.
            // prettier-ignore
            for {} lt(subject, subjectEnd) {} {
                mstore(resultRemainder, mload(subject))
                resultRemainder := add(resultRemainder, 0x20)
                subject := add(subject, 0x20)
            }
            result := sub(result, 0x20)
            // Zeroize the slot after the string.
            let last := add(add(result, 0x20), k)
            mstore(last, 0)
            // Allocate memory for the length and the bytes,
            // rounded up to a multiple of 32.
            mstore(0x40, and(add(last, 31), not(31)))
            // Store the length of the result.
            mstore(result, k)
        }
    }

    /// @dev Returns the byte index of the first location of `search` in `subject`,
    /// searching from left to right, starting from `from`.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function indexOf(string memory subject, string memory search, uint256 from) internal pure returns (uint256 result) {
        assembly {
            // prettier-ignore
            for { let subjectLength := mload(subject) } 1 {} {
                if iszero(mload(search)) {
                    // `result = min(from, subjectLength)`.
                    result := xor(from, mul(xor(from, subjectLength), lt(subjectLength, from)))
                    break
                }
                let searchLength := mload(search)
                let subjectStart := add(subject, 0x20)    
                
                result := not(0) // Initialize to `NOT_FOUND`.

                subject := add(subjectStart, from)
                let subjectSearchEnd := add(sub(add(subjectStart, subjectLength), searchLength), 1)

                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(add(search, 0x20))

                // prettier-ignore
                if iszero(lt(subject, subjectSearchEnd)) { break }

                if iszero(lt(searchLength, 32)) {
                    // prettier-ignore
                    for { let h := keccak256(add(search, 0x20), searchLength) } 1 {} {
                        if iszero(shr(m, xor(mload(subject), s))) {
                            if eq(keccak256(subject, searchLength), h) {
                                result := sub(subject, subjectStart)
                                break
                            }
                        }
                        subject := add(subject, 1)
                        // prettier-ignore
                        if iszero(lt(subject, subjectSearchEnd)) { break }
                    }
                    break
                }
                // prettier-ignore
                for {} 1 {} {
                    if iszero(shr(m, xor(mload(subject), s))) {
                        result := sub(subject, subjectStart)
                        break
                    }
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
                break
            }
        }
    }

    /// @dev Returns the byte index of the first location of `search` in `subject`,
    /// searching from left to right.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function indexOf(string memory subject, string memory search) internal pure returns (uint256 result) {
        result = indexOf(subject, search, 0);
    }

    /// @dev Returns the byte index of the first location of `search` in `subject`,
    /// searching from right to left, starting from `from`.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function lastIndexOf(
        string memory subject,
        string memory search,
        uint256 from
    ) internal pure returns (uint256 result) {
        assembly {
            // prettier-ignore
            for {} 1 {} {
                let searchLength := mload(search)
                let fromMax := sub(mload(subject), searchLength)
                if iszero(gt(fromMax, from)) {
                    from := fromMax
                }
                if iszero(mload(search)) {
                    result := from
                    break
                }
                result := not(0) // Initialize to `NOT_FOUND`.

                let subjectSearchEnd := sub(add(subject, 0x20), 1)

                subject := add(add(subject, 0x20), from)
                // prettier-ignore
                if iszero(gt(subject, subjectSearchEnd)) { break }
                // As this function is not too often used,
                // we shall simply use keccak256 for smaller bytecode size.
                // prettier-ignore
                for { let h := keccak256(add(search, 0x20), searchLength) } 1 {} {
                    if eq(keccak256(subject, searchLength), h) {
                        result := sub(subject, add(subjectSearchEnd, 1))
                        break
                    }
                    subject := sub(subject, 1)
                    // prettier-ignore
                    if iszero(gt(subject, subjectSearchEnd)) { break }
                }
                break
            }
        }
    }

    /// @dev Returns the index of the first location of `search` in `subject`,
    /// searching from right to left.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function lastIndexOf(string memory subject, string memory search) internal pure returns (uint256 result) {
        result = lastIndexOf(subject, search, uint256(int256(-1)));
    }

    /// @dev Returns whether `subject` starts with `search`.
    function startsWith(string memory subject, string memory search) internal pure returns (bool result) {
        assembly {
            let searchLength := mload(search)
            // Just using keccak256 directly is actually cheaper.
            result := and(
                iszero(gt(searchLength, mload(subject))),
                eq(keccak256(add(subject, 0x20), searchLength), keccak256(add(search, 0x20), searchLength))
            )
        }
    }

    /// @dev Returns whether `subject` ends with `search`.
    function endsWith(string memory subject, string memory search) internal pure returns (bool result) {
        assembly {
            let searchLength := mload(search)
            let subjectLength := mload(subject)
            // Whether `search` is not longer than `subject`.
            let withinRange := iszero(gt(searchLength, subjectLength))
            // Just using keccak256 directly is actually cheaper.
            result := and(
                withinRange,
                eq(
                    keccak256(
                        // `subject + 0x20 + max(subjectLength - searchLength, 0)`.
                        add(add(subject, 0x20), mul(withinRange, sub(subjectLength, searchLength))),
                        searchLength
                    ),
                    keccak256(add(search, 0x20), searchLength)
                )
            )
        }
    }

    /// @dev Returns `subject` repeated `times`.
    function repeat(string memory subject, uint256 times) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            if iszero(or(iszero(times), iszero(subjectLength))) {
                subject := add(subject, 0x20)
                result := mload(0x40)
                let output := add(result, 0x20)
                // prettier-ignore
                for {} 1 {} {
                    // Copy the `subject` one word at a time.
                    // prettier-ignore
                    for { let o := 0 } 1 {} {
                        mstore(add(output, o), mload(add(subject, o)))
                        o := add(o, 0x20)
                        // prettier-ignore
                        if iszero(lt(o, subjectLength)) { break }
                    }
                    output := add(output, subjectLength)
                    times := sub(times, 1)
                    // prettier-ignore
                    if iszero(times) { break }
                }
                // Zeroize the slot after the string.
                mstore(output, 0)
                // Store the length.
                let resultLength := sub(output, add(result, 0x20))
                mstore(result, resultLength)
                // Allocate memory for the length and the bytes,
                // rounded up to a multiple of 32.
                mstore(0x40, add(result, and(add(resultLength, 63), not(31))))
            }
        }
    }

    /// @dev Returns a copy of `subject` sliced from `start` to `end` (exclusive).
    /// `start` and `end` are byte offsets.
    function slice(string memory subject, uint256 start, uint256 end) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            if iszero(gt(subjectLength, end)) {
                end := subjectLength
            }
            if iszero(gt(subjectLength, start)) {
                start := subjectLength
            }
            if lt(start, end) {
                result := mload(0x40)
                let resultLength := sub(end, start)
                mstore(result, resultLength)
                subject := add(subject, start)
                // Copy the `subject` one word at a time, backwards.
                // prettier-ignore
                for { let o := and(add(resultLength, 31), not(31)) } 1 {} {
                    mstore(add(result, o), mload(add(subject, o)))
                    o := sub(o, 0x20)
                    // prettier-ignore
                    if iszero(o) { break }
                }
                // Zeroize the slot after the string.
                mstore(add(add(result, 0x20), resultLength), 0)
                // Allocate memory for the length and the bytes,
                // rounded up to a multiple of 32.
                mstore(0x40, add(result, and(add(resultLength, 63), not(31))))
            }
        }
    }

    /// @dev Returns a copy of `subject` sliced from `start` to the end of the string.
    /// `start` is a byte offset.
    function slice(string memory subject, uint256 start) internal pure returns (string memory result) {
        result = slice(subject, start, uint256(int256(-1)));
    }

    /// @dev Returns all the indices of `search` in `subject`.
    /// The indices are byte offsets.
    function indicesOf(string memory subject, string memory search) internal pure returns (uint256[] memory result) {
        assembly {
            let subjectLength := mload(subject)
            let searchLength := mload(search)

            if iszero(gt(searchLength, subjectLength)) {
                subject := add(subject, 0x20)
                search := add(search, 0x20)
                result := add(mload(0x40), 0x20)

                let subjectStart := subject
                let subjectSearchEnd := add(sub(add(subject, subjectLength), searchLength), 1)
                let h := 0
                if iszero(lt(searchLength, 32)) {
                    h := keccak256(search, searchLength)
                }
                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(search)
                // prettier-ignore
                for {} 1 {} {
                    let t := mload(subject)
                    // Whether the first `searchLength % 32` bytes of 
                    // `subject` and `search` matches.
                    if iszero(shr(m, xor(t, s))) {
                        if h {
                            if iszero(eq(keccak256(subject, searchLength), h)) {
                                subject := add(subject, 1)
                                // prettier-ignore
                                if iszero(lt(subject, subjectSearchEnd)) { break }
                                continue
                            }
                        }
                        // Append to `result`.
                        mstore(result, sub(subject, subjectStart))
                        result := add(result, 0x20)
                        // Advance `subject` by `searchLength`.
                        subject := add(subject, searchLength)
                        if searchLength {
                            // prettier-ignore
                            if iszero(lt(subject, subjectSearchEnd)) { break }
                            continue
                        }
                    }
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
                let resultEnd := result
                // Assign `result` to the free memory pointer.
                result := mload(0x40)
                // Store the length of `result`.
                mstore(result, shr(5, sub(resultEnd, add(result, 0x20))))
                // Allocate memory for result.
                // We allocate one more word, so this array can be recycled for {split}.
                mstore(0x40, add(resultEnd, 0x20))
            }
        }
    }

    /// @dev Returns a arrays of strings based on the `delimiter` inside of the `subject` string.
    function split(string memory subject, string memory delimiter) internal pure returns (string[] memory result) {
        uint256[] memory indices = indicesOf(subject, delimiter);
        assembly {
            if mload(indices) {
                let indexPtr := add(indices, 0x20)
                let indicesEnd := add(indexPtr, shl(5, add(mload(indices), 1)))
                mstore(sub(indicesEnd, 0x20), mload(subject))
                mstore(indices, add(mload(indices), 1))
                let prevIndex := 0
                // prettier-ignore
                for {} 1 {} {
                    let index := mload(indexPtr)
                    mstore(indexPtr, 0x60)                        
                    if iszero(eq(index, prevIndex)) {
                        let element := mload(0x40)
                        let elementLength := sub(index, prevIndex)
                        mstore(element, elementLength)
                        // Copy the `subject` one word at a time, backwards.
                        // prettier-ignore
                        for { let o := and(add(elementLength, 31), not(31)) } 1 {} {
                            mstore(add(element, o), mload(add(add(subject, prevIndex), o)))
                            o := sub(o, 0x20)
                            // prettier-ignore
                            if iszero(o) { break }
                        }
                        // Zeroize the slot after the string.
                        mstore(add(add(element, 0x20), elementLength), 0)
                        // Allocate memory for the length and the bytes,
                        // rounded up to a multiple of 32.
                        mstore(0x40, add(element, and(add(elementLength, 63), not(31))))
                        // Store the `element` into the array.
                        mstore(indexPtr, element)                        
                    }
                    prevIndex := add(index, mload(delimiter))
                    indexPtr := add(indexPtr, 0x20)
                    // prettier-ignore
                    if iszero(lt(indexPtr, indicesEnd)) { break }
                }
                result := indices
                if iszero(mload(delimiter)) {
                    result := add(indices, 0x20)
                    mstore(result, sub(mload(indices), 2))
                }
            }
        }
    }

    /// @dev Returns a concatenated string of `a` and `b`.
    /// Cheaper than `string.concat()` and does not de-align the free memory pointer.
    function concat(string memory a, string memory b) internal pure returns (string memory result) {
        assembly {
            result := mload(0x40)
            let aLength := mload(a)
            // Copy `a` one word at a time, backwards.
            // prettier-ignore
            for { let o := and(add(mload(a), 32), not(31)) } 1 {} {
                mstore(add(result, o), mload(add(a, o)))
                o := sub(o, 0x20)
                // prettier-ignore
                if iszero(o) { break }
            }
            let bLength := mload(b)
            let output := add(result, mload(a))
            // Copy `b` one word at a time, backwards.
            // prettier-ignore
            for { let o := and(add(bLength, 32), not(31)) } 1 {} {
                mstore(add(output, o), mload(add(b, o)))
                o := sub(o, 0x20)
                // prettier-ignore
                if iszero(o) { break }
            }
            let totalLength := add(aLength, bLength)
            let last := add(add(result, 0x20), totalLength)
            // Zeroize the slot after the string.
            mstore(last, 0)
            // Stores the length.
            mstore(result, totalLength)
            // Allocate memory for the length and the bytes,
            // rounded up to a multiple of 32.
            mstore(0x40, and(add(last, 31), not(31)))
        }
    }

    /// @dev Packs a single string with its length into a single word.
    /// Returns `bytes32(0)` if the length is zero or greater than 31.
    function packOne(string memory a) internal pure returns (bytes32 result) {
        assembly {
            // We don't need to zero right pad the string,
            // since this is our own custom non-standard packing scheme.
            result := mul(
                // Load the length and the bytes.
                mload(add(a, 0x1f)),
                // `length != 0 && length < 32`. Abuses underflow.
                // Assumes that the length is valid and within the block gas limit.
                lt(sub(mload(a), 1), 0x1f)
            )
        }
    }

    /// @dev Unpacks a string packed using {packOne}.
    /// Returns the empty string if `packed` is `bytes32(0)`.
    /// If `packed` is not an output of {packOne}, the output behaviour is undefined.
    function unpackOne(bytes32 packed) internal pure returns (string memory result) {
        assembly {
            // Grab the free memory pointer.
            result := mload(0x40)
            // Allocate 2 words (1 for the length, 1 for the bytes).
            mstore(0x40, add(result, 0x40))
            // Zeroize the length slot.
            mstore(result, 0)
            // Store the length and bytes.
            mstore(add(result, 0x1f), packed)
            // Right pad with zeroes.
            mstore(add(add(result, 0x20), mload(result)), 0)
        }
    }

    /// @dev Packs two strings with their lengths into a single word.
    /// Returns `bytes32(0)` if combined length is zero or greater than 30.
    function packTwo(string memory a, string memory b) internal pure returns (bytes32 result) {
        assembly {
            let aLength := mload(a)
            // We don't need to zero right pad the strings,
            // since this is our own custom non-standard packing scheme.
            result := mul(
                // Load the length and the bytes of `a` and `b`.
                or(shl(shl(3, sub(0x1f, aLength)), mload(add(a, aLength))), mload(sub(add(b, 0x1e), aLength))),
                // `totalLength != 0 && totalLength < 31`. Abuses underflow.
                // Assumes that the lengths are valid and within the block gas limit.
                lt(sub(add(aLength, mload(b)), 1), 0x1e)
            )
        }
    }

    /// @dev Unpacks strings packed using {packTwo}.
    /// Returns the empty strings if `packed` is `bytes32(0)`.
    /// If `packed` is not an output of {packTwo}, the output behaviour is undefined.
    function unpackTwo(bytes32 packed) internal pure returns (string memory resultA, string memory resultB) {
        assembly {
            // Grab the free memory pointer.
            resultA := mload(0x40)
            resultB := add(resultA, 0x40)
            // Allocate 2 words for each string (1 for the length, 1 for the byte). Total 4 words.
            mstore(0x40, add(resultB, 0x40))
            // Zeroize the length slots.
            mstore(resultA, 0)
            mstore(resultB, 0)
            // Store the lengths and bytes.
            mstore(add(resultA, 0x1f), packed)
            mstore(add(resultB, 0x1f), mload(add(add(resultA, 0x20), mload(resultA))))
            // Right pad with zeroes.
            mstore(add(add(resultA, 0x20), mload(resultA)), 0)
            mstore(add(add(resultB, 0x20), mload(resultB)), 0)
        }
    }

    /// @dev Directly returns `a` without copying.
    function directReturn(string memory a) internal pure {
        assembly {
            // Right pad with zeroes. Just in case the string is produced
            // by a method that doesn't zero right pad.
            mstore(add(add(a, 0x20), mload(a)), 0)
            // Store the return offset.
            // Assumes that the string does not start from the scratch space.
            mstore(sub(a, 0x20), 0x20)
            // End the transaction, returning the string.
            return(sub(a, 0x20), add(mload(a), 0x40))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
// Copyright (C) 2023 Haberdasher Labs
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.8.13;

import { ERC1155 } from "lib/ERC1155/ERC1155.sol";
// import { console2 } from "forge-std/Test.sol"; //remove after testing
import "./Interfaces/IHats.sol";
import "./HatsIdUtilities.sol";
import "./Interfaces/IHatsToggle.sol";
import "./Interfaces/IHatsEligibility.sol";
import "solbase/utils/Base64.sol";
import "solbase/utils/LibString.sol";

/// @title Hats Protocol
/// @notice Hats are DAO-native, revocable, and programmable roles that are represented as non-transferable ERC-1155-similar tokens for composability
/// @dev This is a multitenant contract that can manage all hats for a given chain. While it fully implements the ERC1155 interface, it does not fully comply with the ERC1155 standard.
/// @author Haberdasher Labs
contract Hats is IHats, ERC1155, HatsIdUtilities {
    /*//////////////////////////////////////////////////////////////
                              HATS DATA MODELS
    //////////////////////////////////////////////////////////////*/

    /// @notice A Hat object containing the hat's properties
    /// @dev The members are packed to minimize storage costs
    /// @custom:member eligibility Module that rules on wearer eligibiliy and standing
    /// @custom:member maxSupply The max number of hats with this id that can exist
    /// @custom:member supply The number of this hat that currently exist
    /// @custom:member lastHatId Indexes how many different child hats an admin has
    /// @custom:member toggle Module that sets the hat's status
    /**
     * @custom:member config Holds status and other settings, with this bitwise schema:
     *
     *  0th bit  | `active` status; can be altered by toggle
     *  1        | `mutable` setting
     *  2 - 95   | unassigned
     */
    /// @custom:member details Holds arbitrary metadata about the hat
    /// @custom:member imageURI A uri pointing to an image for the hat
    struct Hat {
        // 1st storage slot
        address eligibility; // ─┐ 20
        uint32 maxSupply; //     │ 4
        uint32 supply; //        │ 4
        uint16 lastHatId; //    ─┘ 2
        // 2nd slot
        address toggle; //      ─┐ 20
        uint96 config; //       ─┘ 12
        // 3rd+ slot (optional)
        string details;
        string imageURI;
    }

    /*//////////////////////////////////////////////////////////////
                              HATS STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The name of the contract, typically including the version
    string public name;

    /// @notice The first 4 bytes of the id of the last tophat created.
    uint32 public lastTopHatId; // first tophat id starts at 1

    /// @notice The fallback image URI for hat tokens with no `imageURI` specified in their branch
    string public baseImageURI;

    /// @dev Internal mapping of hats to hat ids. See HatsIdUtilities.sol for more info on how hat ids work
    mapping(uint256 => Hat) internal _hats; // key: hatId => value: Hat struct

    /// @notice Mapping of wearers in bad standing for certain hats
    /// @dev Used by external contracts to trigger penalties for wearers in bad standing
    ///      hatId => wearer => !standing
    mapping(uint256 => mapping(address => bool)) public badStandings;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice All arguments are immutable; they can only be set once during construction
    /// @param _name The name of this contract, typically including the version
    /// @param _baseImageURI The fallback image URI
    constructor(string memory _name, string memory _baseImageURI) {
        name = _name;
        baseImageURI = _baseImageURI;
    }

    /*//////////////////////////////////////////////////////////////
                              HATS LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates and mints a Hat that is its own admin, i.e. a "topHat"
    /// @dev A topHat has no eligibility and no toggle
    /// @param _target The address to which the newly created topHat is minted
    /// @param _details A description of the Hat [optional]. Should not be larger than 7000 bytes
    ///                 (enforced in changeHatDetails)
    /// @param _imageURI The image uri for this top hat and the fallback for its
    ///                  downstream hats [optional]. Should not be large than 7000 bytes
    ///                  (enforced in changeHatImageURI)
    /// @return topHatId The id of the newly created topHat
    function mintTopHat(address _target, string calldata _details, string calldata _imageURI)
        public
        returns (uint256 topHatId)
    {
        // create hat

        topHatId = uint256(++lastTopHatId) << 224;

        _createHat(
            topHatId,
            _details, // details
            1, // maxSupply = 1
            address(0), // there is no eligibility
            address(0), // it has no toggle
            false, // its immutable
            _imageURI
        );

        _mintHat(_target, topHatId);
    }

    /// @notice Creates a new hat. The msg.sender must wear the `_admin` hat.
    /// @dev Initializes a new Hat struct, but does not mint any tokens.
    /// @param _details A description of the Hat. Should not be larger than 7000 bytes (enforced in changeHatDetails)
    /// @param _maxSupply The total instances of the Hat that can be worn at once
    /// @param _admin The id of the Hat that will control who wears the newly created hat
    /// @param _eligibility The address that can report on the Hat wearer's status
    /// @param _toggle The address that can deactivate the Hat
    /// @param _mutable Whether the hat's properties are changeable after creation
    /// @param _imageURI The image uri for this hat and the fallback for its
    ///                  downstream hats [optional]. Should not be larger than 7000 bytes (enforced in changeHatImageURI)
    /// @return newHatId The id of the newly created Hat
    function createHat(
        uint256 _admin,
        string calldata _details,
        uint32 _maxSupply,
        address _eligibility,
        address _toggle,
        bool _mutable,
        string calldata _imageURI
    ) public returns (uint256 newHatId) {
        if (uint16(_admin) > 0) {
            revert MaxLevelsReached();
        }

        if (_eligibility == address(0)) revert ZeroAddress();
        if (_toggle == address(0)) revert ZeroAddress();
        // check that the admin id is valid, ie does not contain empty levels between filled levels
        if (!isValidHatId(_admin)) revert InvalidHatId();
        // construct the next hat id
        newHatId = getNextId(_admin);
        // to create a hat, you must be wearing one of its admin hats
        _checkAdmin(newHatId);
        // create the new hat
        _createHat(newHatId, _details, _maxSupply, _eligibility, _toggle, _mutable, _imageURI);
        // increment _admin.lastHatId
        // use the overflow check to constrain to correct number of hats per level
        ++_hats[_admin].lastHatId;
    }

    /// @notice Creates new hats in batch. The msg.sender must be an admin of each hat.
    /// @dev This is a convenience function that loops through the arrays and calls `createHat`.
    /// @param _admins Array of ids of admins for each hat to create
    /// @param _details Array of details for each hat to create
    /// @param _maxSupplies Array of supply caps for each hat to create
    /// @param _eligibilityModules Array of eligibility module addresses for each hat to
    /// create
    /// @param _toggleModules Array of toggle module addresses for each hat to create
    /// @param _mutables Array of mutable flags for each hat to create
    /// @param _imageURIs Array of imageURIs for each hat to create
    /// @return success True if all createHat calls succeeded
    function batchCreateHats(
        uint256[] calldata _admins,
        string[] calldata _details,
        uint32[] calldata _maxSupplies,
        address[] memory _eligibilityModules,
        address[] memory _toggleModules,
        bool[] calldata _mutables,
        string[] calldata _imageURIs
    ) public returns (bool success) {
        // check if array lengths are the same
        uint256 length = _admins.length; // save an MLOAD

        {
            bool sameLengths = (
                length == _details.length // details
                    && length == _maxSupplies.length // supplies
                    && length == _eligibilityModules.length // eligibility
                    && length == _toggleModules.length // toggle
                    && length == _mutables.length // mutable
                    && length == _imageURIs.length
            ); // imageURI
            if (!sameLengths) revert BatchArrayLengthMismatch();
        }

        // loop through and create each hat
        for (uint256 i = 0; i < length;) {
            createHat(
                _admins[i],
                _details[i],
                _maxSupplies[i],
                _eligibilityModules[i],
                _toggleModules[i],
                _mutables[i],
                _imageURIs[i]
            );

            unchecked {
                ++i;
            }
        }

        success = true;
    }

    /// @notice Gets the id of the next child hat of the hat `_admin`
    /// @dev Does not incrememnt lastHatId
    /// @param _admin The id of the hat to serve as the admin for the next child hat
    /// @return nextId The new hat id
    function getNextId(uint256 _admin) public view returns (uint256 nextId) {
        uint16 nextHatId = _hats[_admin].lastHatId + 1;
        nextId = buildHatId(_admin, nextHatId);
    }

    /// @notice Mints an ERC1155-similar token of the Hat to an eligible recipient, who then "wears" the hat
    /// @dev The msg.sender must wear an admin Hat of `_hatId`, and the recipient must be eligible to wear `_hatId`
    /// @param _hatId The id of the Hat to mint
    /// @param _wearer The address to which the Hat is minted
    /// @return success Whether the mint succeeded
    function mintHat(uint256 _hatId, address _wearer) public returns (bool success) {
        Hat storage hat = _hats[_hatId];
        if (hat.maxSupply == 0) revert HatDoesNotExist(_hatId);
        // only eligible wearers can receive minted hats
        if (!isEligible(_wearer, _hatId)) revert NotEligible();
        // only active hats can be minted
        if (!_isActive(hat, _hatId)) revert HatNotActive();
        // only the wearer of one of a hat's admins can mint it
        _checkAdmin(_hatId);
        // hat supply cannot exceed maxSupply
        if (hat.supply >= hat.maxSupply) revert AllHatsWorn(_hatId);
        // wearers cannot wear the same hat more than once
        if (_staticBalanceOf(_wearer, _hatId) > 0) revert AlreadyWearingHat(_wearer, _hatId);
        // if we've made it through all the checks, mint the hat
        _mintHat(_wearer, _hatId);

        success = true;
    }

    /// @notice Mints new hats in batch. The msg.sender must be an admin of each hat.
    /// @dev This is a convenience function that loops through the arrays and calls `mintHat`.
    /// @param _hatIds Array of ids of hats to mint
    /// @param _wearers Array of addresses to which the hats will be minted
    /// @return success True if all mintHat calls succeeded
    function batchMintHats(uint256[] calldata _hatIds, address[] calldata _wearers) public returns (bool success) {
        uint256 length = _hatIds.length;
        if (length != _wearers.length) revert BatchArrayLengthMismatch();

        for (uint256 i = 0; i < length;) {
            mintHat(_hatIds[i], _wearers[i]);
            unchecked {
                ++i;
            }
        }

        success = true;
    }

    /// @notice Toggles a Hat's status from active to deactive, or vice versa
    /// @dev The msg.sender must be set as the hat's toggle
    /// @param _hatId The id of the Hat for which to adjust status
    /// @param _newStatus The new status to set
    /// @return toggled Whether the status was toggled
    function setHatStatus(uint256 _hatId, bool _newStatus) external returns (bool toggled) {
        Hat storage hat = _hats[_hatId];

        if (msg.sender != hat.toggle) {
            revert NotHatsToggle();
        }

        toggled = _processHatStatus(_hatId, _newStatus);
    }

    /// @notice Checks a hat's toggle module and processes the returned status
    /// @dev May change the hat's status in storage
    /// @param _hatId The id of the Hat whose toggle we are checking
    /// @return toggled Whether there was a new status
    function checkHatStatus(uint256 _hatId) public returns (bool toggled) {
        Hat storage hat = _hats[_hatId];

        // attempt to retrieve the hat's status from the toggle module
        (bool success, bool newStatus) = _pullHatStatus(hat, _hatId);

        // if unsuccessful (ie toggle was humanistic), process the new status
        if (!success) revert NotHatsToggle();

        // if successful (ie toggle was mechanistic), process the new status
        toggled = _processHatStatus(_hatId, newStatus);
    }

    function _pullHatStatus(Hat storage _hat, uint256 _hatId) internal view returns (bool success, bool newStatus) {
        bytes memory data = abi.encodeWithSignature("getHatStatus(uint256)", _hatId);
        bytes memory returndata;
        (success, returndata) = _hat.toggle.staticcall(data);

        /* 
        * if function call succeeds with data of length == 32, then we know the contract exists 
        * and has the getHatStatus function.
        * But — since function selectors don't include return types — we still can't assume that the return data is a boolean, 
        * so we treat it as a uint so it will always safely decode without throwing.
        */
        if (success && returndata.length == 32) {
            // check the returndata manually
            uint256 uintReturndata = abi.decode(returndata, (uint256));
            // false condition
            if (uintReturndata == 0) {
                newStatus = false;
                // true condition
            } else if (uintReturndata == 1) {
                newStatus = true;
            }
            // invalid condition
            else {
                success = false;
            }
        } else {
            success = false;
        }
    }

    /// @notice Report from a hat's eligibility on the status of one of its wearers and, if `false`, revoke their hat
    /// @dev Burns the wearer's hat, if revoked
    /// @param _hatId The id of the hat
    /// @param _wearer The address of the hat wearer whose status is being reported
    /// @param _eligible Whether the wearer is eligible for the hat (will be revoked if
    /// false)
    /// @param _standing False if the wearer is no longer in good standing (and potentially should be penalized)
    /// @return updated Whether the report succeeded
    function setHatWearerStatus(uint256 _hatId, address _wearer, bool _eligible, bool _standing)
        external
        returns (bool updated)
    {
        Hat storage hat = _hats[_hatId];

        if (msg.sender != hat.eligibility) {
            revert NotHatsEligibility();
        }

        updated = _processHatWearerStatus(_hatId, _wearer, _eligible, _standing);
    }

    /// @notice Check a hat's eligibility for a report on the status of one of the hat's wearers and, if `false`, revoke their hat
    /// @dev Burns the wearer's hat, if revoked
    /// @param _hatId The id of the hat
    /// @param _wearer The address of the Hat wearer whose status report is being requested
    /// @return updated Whether the wearer's status was altered
    function checkHatWearerStatus(uint256 _hatId, address _wearer) public returns (bool updated) {
        bool eligible;
        bool standing;

        (bool success, bytes memory returndata) = _hats[_hatId].eligibility.staticcall(
            abi.encodeWithSignature("getWearerStatus(address,uint256)", _wearer, _hatId)
        );

        /* 
        * if function call succeeds with data of length == 64, then we know the contract exists 
        * and has the getWearerStatus function (which returns two words).
        * But — since function selectors don't include return types — we still can't assume that the return data is two booleans, 
        * so we treat it as a uint so it will always safely decode without throwing.
        */
        if (success && returndata.length == 64) {
            // check the returndata manually
            (uint256 firstWord, uint256 secondWord) = abi.decode(returndata, (uint256, uint256));
            // returndata is valid
            if (firstWord < 2 && secondWord < 2) {
                standing = (secondWord == 1) ? true : false;
                // never eligible if in bad standing
                eligible = (standing && firstWord == 1) ? true : false;
            }
            // returndata is invalid
            else {
                revert NotHatsEligibility();
            }
        } else {
            revert NotHatsEligibility();
        }

        updated = _processHatWearerStatus(_hatId, _wearer, eligible, standing);
    }

    /// @notice Stop wearing a hat, aka "renounce" it
    /// @dev Burns the msg.sender's hat
    /// @param _hatId The id of the Hat being renounced
    function renounceHat(uint256 _hatId) external {
        if (_staticBalanceOf(msg.sender, _hatId) < 1) {
            revert NotHatWearer();
        }
        // remove the hat
        _burnHat(msg.sender, _hatId);
    }

    /*//////////////////////////////////////////////////////////////
                              HATS INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Internal call for creating a new hat
    /// @dev Initializes a new Hat in storage, but does not mint any tokens
    /// @param _id ID of the hat to be stored
    /// @param _details A description of the hat
    /// @param _maxSupply The total instances of the Hat that can be worn at once
    /// @param _eligibility The address that can report on the Hat wearer's status
    /// @param _toggle The address that can deactivate the hat [optional]
    /// @param _mutable Whether the hat's properties are changeable after creation
    /// @param _imageURI The image uri for this top hat and the fallback for its
    ///                  downstream hats [optional]
    function _createHat(
        uint256 _id,
        string calldata _details,
        uint32 _maxSupply,
        address _eligibility,
        address _toggle,
        bool _mutable,
        string calldata _imageURI
    ) internal {
        /* 
          We write directly to storage instead of first building the Hat struct in memory.
          This allows us to cheaply use the existing lastHatId value in case it was incremented by creating a hat while skipping admin levels.
          (Resetting it to 0 would be bad since this hat's child hat(s) would overwrite the previously created hat(s) at that level.)
        */
        Hat storage hat = _hats[_id];
        hat.details = _details;
        hat.maxSupply = _maxSupply;
        hat.eligibility = _eligibility;
        hat.toggle = _toggle;
        hat.imageURI = _imageURI;
        // config is a concatenation of the status and mutability properties
        hat.config = _mutable ? uint96(3 << 94) : uint96(1 << 95);

        emit HatCreated(_id, _details, _maxSupply, _eligibility, _toggle, _mutable, _imageURI);
    }

    /// @notice Internal function to process hat status
    /// @dev Updates a hat's status if different from current
    /// @param _hatId The id of the Hat in quest
    /// @param _newStatus The status to potentially change to
    /// @return updated - Whether the status was updated
    function _processHatStatus(uint256 _hatId, bool _newStatus) internal returns (bool updated) {
        // optimize later
        Hat storage hat = _hats[_hatId];

        if (_newStatus != _getHatStatus(hat)) {
            _setHatStatus(hat, _newStatus);
            emit HatStatusChanged(_hatId, _newStatus);
            updated = true;
        }
    }

    /// @notice Internal call to process wearer status from the eligibility module
    /// @dev Burns the wearer's Hat token if _eligible is false, and updates badStandings
    /// state if necessary
    /// @param _hatId The id of the Hat to revoke
    /// @param _wearer The address of the wearer in question
    /// @param _eligible Whether _wearer is eligible for the Hat (if false, this function
    /// will revoke their Hat)
    /// @param _standing Whether _wearer is in good standing (to be recorded in storage)
    /// @return updated Whether the wearer standing was updated
    function _processHatWearerStatus(uint256 _hatId, address _wearer, bool _eligible, bool _standing)
        internal
        returns (bool updated)
    {
        // revoke/burn the hat if _wearer has a positive balance
        if (_staticBalanceOf(_wearer, _hatId) > 0) {
            // always ineligible if in bad standing
            if (!_eligible || !_standing) {
                _burnHat(_wearer, _hatId);
            }
        }

        // record standing for use by other contracts
        // note: here, standing and badStandings are opposite
        // i.e. if standing (true = good standing)
        // then badStandings[_hatId][wearer] will be false
        // if they are different, then something has changed, and we need to update
        // badStandings marker
        if (_standing == badStandings[_hatId][_wearer]) {
            badStandings[_hatId][_wearer] = !_standing;
            updated = true;

            emit WearerStandingChanged(_hatId, _wearer, _standing);
        }
    }

    /// @notice Internal function to set a hat's status in storage
    /// @dev Flips the 0th bit of _hat.config via bitwise operation
    /// @param _hat The hat object
    /// @param _status The status to set for the hat
    function _setHatStatus(Hat storage _hat, bool _status) internal {
        if (_status) {
            _hat.config |= uint96(1 << 95);
        } else {
            _hat.config &= ~uint96(1 << 95);
        }
    }

    /**
     * @notice Internal function to retrieve an account's internal "static" balance directly from internal storage,
     * @dev This function bypasses the dynamic `_isActive` and `_isEligible` checks
     * @param _account The account to check
     * @param _hatId The hat to check
     * @return staticBalance The account's static of the hat, from internal storage
     */
    function _staticBalanceOf(address _account, uint256 _hatId) internal view returns (uint256 staticBalance) {
        staticBalance = _balanceOf[_account][_hatId];
    }

    /*//////////////////////////////////////////////////////////////
                              HATS ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Checks whether msg.sender is an admin of a hat, and reverts if not
    function _checkAdmin(uint256 _hatId) internal view {
        if (!isAdminOfHat(msg.sender, _hatId)) {
            revert NotAdmin(msg.sender, _hatId);
        }
    }

    /// @notice checks whether the msg.sender is either an admin or wearer or a hat, and reverts the appropriate error if not
    function _checkAdminOrWearer(uint256 _hatId) internal view {
        if (!isAdminOfHat(msg.sender, _hatId) && !isWearerOfHat(msg.sender, _hatId)) {
            revert NotAdminOrWearer();
        }
    }

    /// @notice Transfers a hat from one wearer to another eligible wearer
    /// @dev The hat must be mutable, and the transfer must be initiated by an admin
    /// @param _hatId The hat in question
    /// @param _from The current wearer
    /// @param _to The new wearer
    function transferHat(uint256 _hatId, address _from, address _to) public {
        _checkAdmin(_hatId);
        // cannot transfer immutable hats, except for tophats, which can always transfer themselves
        if (!isTopHat(_hatId)) {
            if (!_isMutable(_hats[_hatId])) revert Immutable();
        }
        // Checks storage instead of `isWearerOfHat` since admins may want to transfer revoked Hats to new wearers
        if (_staticBalanceOf(_from, _hatId) < 1) revert NotHatWearer();
        // Check if recipient is already wearing hat; also checks storage to maintain balance == 1 invariant
        if (_staticBalanceOf(_to, _hatId) > 0) revert AlreadyWearingHat(_to, _hatId);
        // only eligible wearers can receive transferred hats
        if (!isEligible(_to, _hatId)) revert NotEligible();
        // only active hats can be transferred
        if (!_isActive(_hats[_hatId], _hatId)) revert HatNotActive();
        // we've made it passed all the checks, so adjust balances to execute the transfer
        _balanceOf[_from][_hatId] = 0;
        _balanceOf[_to][_hatId] = 1;
        // emit the ERC1155 standard transfer event
        emit TransferSingle(msg.sender, _from, _to, _hatId, 1);
    }

    /// @notice Set a mutable hat to immutable
    /// @dev Sets the second bit of hat.config to 0
    /// @param _hatId The id of the Hat to make immutable
    function makeHatImmutable(uint256 _hatId) external {
        _checkAdmin(_hatId);

        Hat storage hat = _hats[_hatId];

        if (!_isMutable(hat)) {
            revert Immutable();
        }

        hat.config &= ~uint96(1 << 94);

        emit HatMutabilityChanged(_hatId);
    }

    /// @notice Change a hat's details
    /// @dev Hat must be mutable, except for tophats.
    /// @param _hatId The id of the Hat to change
    /// @param _newDetails The new details. Must not be larger than 7000 bytes.
    function changeHatDetails(uint256 _hatId, string calldata _newDetails) external {
        if (bytes(_newDetails).length > 7000) revert StringTooLong();

        _checkAdmin(_hatId);

        Hat storage hat = _hats[_hatId];

        // a tophat can change its own details, but otherwise only mutable hat details can be changed
        if (!isTopHat(_hatId)) {
            if (!_isMutable(hat)) revert Immutable();
        }

        hat.details = _newDetails;

        emit HatDetailsChanged(_hatId, _newDetails);
    }

    /// @notice Change a hat's details
    /// @dev Hat must be mutable
    /// @param _hatId The id of the Hat to change
    /// @param _newEligibility The new eligibility module
    function changeHatEligibility(uint256 _hatId, address _newEligibility) external {
        if (_newEligibility == address(0)) revert ZeroAddress();

        _checkAdmin(_hatId);
        Hat storage hat = _hats[_hatId];

        if (!_isMutable(hat)) {
            revert Immutable();
        }

        hat.eligibility = _newEligibility;

        emit HatEligibilityChanged(_hatId, _newEligibility);
    }

    /// @notice Change a hat's details
    /// @dev Hat must be mutable
    /// @param _hatId The id of the Hat to change
    /// @param _newToggle The new toggle module
    function changeHatToggle(uint256 _hatId, address _newToggle) external {
        if (_newToggle == address(0)) revert ZeroAddress();

        _checkAdmin(_hatId);
        Hat storage hat = _hats[_hatId];

        if (!_isMutable(hat)) {
            revert Immutable();
        }

        // record hat status from old toggle before changing; ensures smooth transition to new toggle,
        // especially in case of switching from mechanistic to humanistic toggle
        // a) attempt to retrieve hat status from old toggle
        (bool success, bool newStatus) = _pullHatStatus(hat, _hatId);
        // b) if succeeded, (ie if old toggle was mechanistic), store the retrieved status
        if (success) _processHatStatus(_hatId, newStatus);

        // set the new toggle
        hat.toggle = _newToggle;

        emit HatToggleChanged(_hatId, _newToggle);
    }

    /// @notice Change a hat's details
    /// @dev Hat must be mutable, except for tophats
    /// @param _hatId The id of the Hat to change
    /// @param _newImageURI The new imageURI. Must not be larger than 7000 bytes.
    function changeHatImageURI(uint256 _hatId, string calldata _newImageURI) external {
        if (bytes(_newImageURI).length > 7000) revert StringTooLong();

        _checkAdmin(_hatId);
        Hat storage hat = _hats[_hatId];

        // a tophat can change its own imageURI, but otherwise only mutable hat imageURIs can be changed
        if (!isTopHat(_hatId)) {
            if (!_isMutable(hat)) revert Immutable();
        }

        hat.imageURI = _newImageURI;

        emit HatImageURIChanged(_hatId, _newImageURI);
    }

    /// @notice Change a hat's details
    /// @dev Hat must be mutable; new max supply cannot be less than current supply
    /// @param _hatId The id of the Hat to change
    /// @param _newMaxSupply The new max supply
    function changeHatMaxSupply(uint256 _hatId, uint32 _newMaxSupply) external {
        _checkAdmin(_hatId);
        Hat storage hat = _hats[_hatId];

        if (!_isMutable(hat)) {
            revert Immutable();
        }

        if (_newMaxSupply < hat.supply) {
            revert NewMaxSupplyTooLow();
        }

        if (_newMaxSupply != hat.maxSupply) {
            hat.maxSupply = _newMaxSupply;
            emit HatMaxSupplyChanged(_hatId, _newMaxSupply);
        }
    }

    /// @notice Submits a request to link a Hat Tree under a parent tree. Requests can be
    /// submitted by either...
    ///     a) the wearer of a topHat, previous to any linkage, or
    ///     b) the admin(s) of an already-linked topHat (aka tree root), where such a
    ///        request is to move the tree root to another admin within the same parent
    ///        tree
    /// @dev A topHat can have at most 1 request at a time. Submitting a new request will
    ///      replace the existing request.
    /// @param _topHatDomain The domain of the topHat to link
    /// @param _requestedAdminHat The hat that will administer the linked tree
    function requestLinkTopHatToTree(uint32 _topHatDomain, uint256 _requestedAdminHat) external {
        uint256 fullTopHatId = uint256(_topHatDomain) << 224; // (256 - TOPHAT_ADDRESS_SPACE);

        // The wearer of an unlinked tophat is also the admin of same; once a tophat is linked, its wearer is no longer its admin
        _checkAdmin(fullTopHatId);

        linkedTreeRequests[_topHatDomain] = _requestedAdminHat;
        emit TopHatLinkRequested(_topHatDomain, _requestedAdminHat);
    }

    /// @notice Approve a request to link a Tree under a parent tree, with options to add eligibility or toggle modules and change its metadata
    /// @dev Requests can only be approved by wearer or an admin of the `_newAdminHat`, and there
    ///      can only be one link per tree root at a given time.
    /// @param _topHatDomain The 32 bit domain of the topHat to link
    /// @param _newAdminHat The hat that will administer the linked tree
    /// @param _eligibility Optional new eligibility module for the linked topHat
    /// @param _toggle Optional new toggle module for the linked topHat
    /// @param _details Optional new details for the linked topHat
    /// @param _imageURI Optional new imageURI for the linked topHat
    function approveLinkTopHatToTree(
        uint32 _topHatDomain,
        uint256 _newAdminHat,
        address _eligibility,
        address _toggle,
        string calldata _details,
        string calldata _imageURI
    ) external {
        // for everything but the last hat level, check the admin of `_newAdminHat`'s theoretical child hat, since either wearer or admin of `_newAdminHat` can approve
        if (getHatLevel(_newAdminHat) < MAX_LEVELS) {
            _checkAdmin(buildHatId(_newAdminHat, 1));
        } else {
            // the above buildHatId trick doesn't work for the last hat level, so we need to explicitly check both admin and wearer in this case
            _checkAdminOrWearer(_newAdminHat);
        }

        // Linkages must be initiated by a request
        if (_newAdminHat != linkedTreeRequests[_topHatDomain]) revert LinkageNotRequested();

        // remove the request -- ensures all linkages are initialized by unique requests,
        // except for relinks (see `relinkTopHatWithinTree`)
        delete linkedTreeRequests[_topHatDomain];

        // execute the link. Replaces existing link, if any.
        _linkTopHatToTree(_topHatDomain, _newAdminHat, _eligibility, _toggle, _details, _imageURI);
    }

    /// @notice Unlink a Tree from the parent tree
    /// @dev This can only be called by an admin of the tree root
    /// @param _topHatDomain The 32 bit domain of the topHat to unlink
    function unlinkTopHatFromTree(uint32 _topHatDomain) external {
        uint256 fullTopHatId = uint256(_topHatDomain) << 224; // (256 - TOPHAT_ADDRESS_SPACE);
        _checkAdmin(fullTopHatId);

        delete linkedTreeAdmins[_topHatDomain];
        delete linkedTreeRequests[_topHatDomain];

        // reset eligibility and storage to defaults for unlinked top hats
        Hat storage hat = _hats[fullTopHatId];
        delete hat.eligibility;
        delete hat.toggle;

        emit TopHatLinked(_topHatDomain, 0);
    }

    /// @notice Move a tree root to a different position within the same parent tree,
    ///         without a request. Valid destinations include within the same local tree as the origin,
    ///         or to the local tree of the tippyTopHat. TippyTopHat wearers can bypass this restriction
    ///         to relink to anywhere in its full tree.
    /// @dev Caller must be both an admin tree root and admin or wearer of `_newAdminHat`.
    /// @param _topHatDomain The 32 bit domain of the topHat to relink
    /// @param _newAdminHat The new admin for the linked tree
    /// @param _eligibility Optional new eligibility module for the linked topHat
    /// @param _toggle Optional new toggle module for the linked topHat
    /// @param _details Optional new details for the linked topHat
    /// @param _imageURI Optional new imageURI for the linked topHat
    function relinkTopHatWithinTree(
        uint32 _topHatDomain,
        uint256 _newAdminHat,
        address _eligibility,
        address _toggle,
        string calldata _details,
        string calldata _imageURI
    ) external {
        uint256 fullTopHatId = uint256(_topHatDomain) << 224; // (256 - TOPHAT_ADDRESS_SPACE);

        // msg.sender being capable of both requesting and approving allows us to skip the request step
        _checkAdmin(fullTopHatId); // "requester" must be admin

        // "approver" can be wearer or admin
        if (getHatLevel(_newAdminHat) < MAX_LEVELS) {
            _checkAdmin(buildHatId(_newAdminHat, 1));
        } else {
            // the above buildHatId trick doesn't work for the last hat level, so we need to explicitly check both admin and wearer in this case
            _checkAdminOrWearer(_newAdminHat);
        }

        // execute the new link, replacing the old link
        _linkTopHatToTree(_topHatDomain, _newAdminHat, _eligibility, _toggle, _details, _imageURI);
    }

    /// @notice Internal function to link a Tree under a parent Tree, with protection against circular linkages and relinking to a separate Tree,
    ///         with options to add eligibility or toggle modules and change its metadata
    /// @dev Linking `_topHatDomain` replaces any existing links
    /// @param _topHatDomain The 32 bit domain of the topHat to link
    /// @param _newAdminHat The new admin for the linked tree
    /// @param _eligibility Optional new eligibility module for the linked topHat
    /// @param _toggle Optional new toggle module for the linked topHat
    /// @param _details Optional new details for the linked topHat
    /// @param _imageURI Optional new imageURI for the linked topHat
    function _linkTopHatToTree(
        uint32 _topHatDomain,
        uint256 _newAdminHat,
        address _eligibility,
        address _toggle,
        string calldata _details,
        string calldata _imageURI
    ) internal {
        if (!noCircularLinkage(_topHatDomain, _newAdminHat)) revert CircularLinkage();
        {
            uint256 linkedAdmin = linkedTreeAdmins[_topHatDomain];

            // disallow relinking to separate tree
            if (linkedAdmin > 0) {
                uint256 tippyTopHat = uint256(getTippyTopHatDomain(_topHatDomain)) << 224;
                if (!isWearerOfHat(msg.sender, tippyTopHat)) {
                    uint256 destLocalTopHat = uint256(_newAdminHat >> 224 << 224); // (256 - TOPHAT_ADDRESS_SPACE);
                    // for non-tippyTopHat wearers: destination local tophat must be either...
                    // a) the same as origin local tophat, or
                    // b) within the tippy top hat's local tree
                    uint256 originLocalTopHat = linkedAdmin >> 224 << 224; // (256 - TOPHAT_ADDRESS_SPACE);
                    if (destLocalTopHat != originLocalTopHat && destLocalTopHat != tippyTopHat) {
                        revert CrossTreeLinkage();
                    }
                    // for tippyTopHat weerers: destination must be within the same super tree
                } else if (!sameTippyTopHatDomain(_topHatDomain, _newAdminHat)) {
                    revert CrossTreeLinkage();
                }
            }
        }

        // update and log the linked topHat's modules and metadata, if any changes
        uint256 topHatId = uint256(_topHatDomain) << 224;
        Hat storage hat = _hats[topHatId];

        if (_eligibility != address(0)) {
            hat.eligibility = _eligibility;
            emit HatEligibilityChanged(topHatId, _eligibility);
        }
        if (_toggle != address(0)) {
            hat.toggle = _toggle;
            emit HatToggleChanged(topHatId, _toggle);
        }

        uint256 length = bytes(_details).length;
        if (length > 0) {
            if (length > 7000) revert StringTooLong();
            hat.details = _details;
            emit HatDetailsChanged(topHatId, _details);
        }

        length = bytes(_imageURI).length;
        if (length > 0) {
            if (length > 7000) revert StringTooLong();
            hat.imageURI = _imageURI;
            emit HatImageURIChanged(topHatId, _imageURI);
        }

        // store the new linked admin
        linkedTreeAdmins[_topHatDomain] = _newAdminHat;
        emit TopHatLinked(_topHatDomain, _newAdminHat);
    }

    /*//////////////////////////////////////////////////////////////
                              HATS VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice View the properties of a given Hat
    /// @param _hatId The id of the Hat
    /// @return details The details of the Hat
    /// @return maxSupply The max supply of tokens for this Hat
    /// @return supply The number of current wearers of this Hat
    /// @return eligibility The eligibility address for this Hat
    /// @return toggle The toggle address for this Hat
    /// @return imageURI The image URI used for this Hat
    /// @return lastHatId The most recently created Hat with this Hat as admin; also the count of Hats with this Hat as admin
    /// @return mutable_ Whether this hat's properties can be changed
    /// @return active Whether the Hat is current active, as read from `_isActive`
    function viewHat(uint256 _hatId)
        public
        view
        returns (
            string memory details,
            uint32 maxSupply,
            uint32 supply,
            address eligibility,
            address toggle,
            string memory imageURI,
            uint16 lastHatId,
            bool mutable_,
            bool active
        )
    {
        Hat storage hat = _hats[_hatId];
        details = hat.details;
        maxSupply = hat.maxSupply;
        supply = hat.supply;
        eligibility = hat.eligibility;
        toggle = hat.toggle;
        imageURI = getImageURIForHat(_hatId);
        lastHatId = hat.lastHatId;
        mutable_ = _isMutable(hat);
        active = _isActive(hat, _hatId);
    }

    /// @notice Checks whether a given address wears a given Hat
    /// @dev Convenience function that wraps `balanceOf`
    /// @param _user The address in question
    /// @param _hatId The id of the Hat that the `_user` might wear
    /// @return isWearer Whether the `_user` wears the Hat.
    function isWearerOfHat(address _user, uint256 _hatId) public view returns (bool isWearer) {
        isWearer = (balanceOf(_user, _hatId) > 0);
    }

    /// @notice Checks whether a given address serves as the admin of a given Hat
    /// @dev Recursively checks if `_user` wears the admin Hat of the Hat in question. This is recursive since there may be a string of Hats as admins of Hats.
    /// @param _user The address in question
    /// @param _hatId The id of the Hat for which the `_user` might be the admin
    /// @return isAdmin Whether the `_user` has admin rights for the Hat
    function isAdminOfHat(address _user, uint256 _hatId) public view returns (bool isAdmin) {
        uint256 linkedTreeAdmin;
        uint32 adminLocalHatLevel;
        if (isLocalTopHat(_hatId)) {
            linkedTreeAdmin = linkedTreeAdmins[getTopHatDomain(_hatId)];
            if (linkedTreeAdmin == 0) {
                // tree is not linked
                return isAdmin = isWearerOfHat(_user, _hatId);
            } else {
                // tree is linked
                if (isWearerOfHat(_user, linkedTreeAdmin)) {
                    return isAdmin = true;
                } // user wears the treeAdmin
                else {
                    adminLocalHatLevel = getLocalHatLevel(linkedTreeAdmin);
                    _hatId = linkedTreeAdmin;
                }
            }
        } else {
            // if we get here, _hatId is not a tophat of any kind
            // get the local tree level of _hatId's admin
            adminLocalHatLevel = getLocalHatLevel(_hatId) - 1;
        }

        // search up _hatId's local address space for an admin hat that the _user wears
        while (adminLocalHatLevel > 0) {
            if (isWearerOfHat(_user, getAdminAtLocalLevel(_hatId, adminLocalHatLevel))) {
                return isAdmin = true;
            }
            // should not underflow given stopping condition > 0
            unchecked {
                --adminLocalHatLevel;
            }
        }

        // if we get here, we've reached the top of _hatId's local tree, ie the local tophat
        // check if the user wears the local tophat
        if (isWearerOfHat(_user, getAdminAtLocalLevel(_hatId, 0))) return isAdmin = true;

        // if not, we check if it's linked to another tree
        linkedTreeAdmin = linkedTreeAdmins[getTopHatDomain(_hatId)];
        if (linkedTreeAdmin == 0) {
            // tree is not linked
            // we've already learned that user doesn't wear the local tophat, so there's nothing else to check; we return false
            return isAdmin = false;
        } else {
            // tree is linked
            // check if user is wearer of linkedTreeAdmin
            if (isWearerOfHat(_user, linkedTreeAdmin)) return true;
            // if not, recurse to traverse the parent tree for a hat that the user wears
            isAdmin = isAdminOfHat(_user, linkedTreeAdmin);
        }
    }

    /// @notice Checks the active status of a hat
    /// @dev For internal use instead of `isActive` when passing Hat as param is preferable
    /// @param _hat The Hat struct
    /// @param _hatId The id of the hat
    /// @return active The active status of the hat
    function _isActive(Hat storage _hat, uint256 _hatId) internal view returns (bool active) {
        (bool success, bytes memory returndata) =
            _hat.toggle.staticcall(abi.encodeWithSignature("getHatStatus(uint256)", _hatId));

        /*
        * if function call succeeds with data of length == 32, then we know the contract exists
        * and has the getHatStatus function.
        * But — since function selectors don't include return types — we still can't assume that the return data is a boolean,
        * so we treat it as a uint so it will always safely decode without throwing.
        */
        if (success && returndata.length == 32) {
            // check the returndata manually
            uint256 uintReturndata = uint256(bytes32(returndata));
            // false condition
            if (uintReturndata == 0) {
                active = false;
                // true condition
            } else if (uintReturndata == 1) {
                active = true;
            }
            // invalid condition
            else {
                active = _getHatStatus(_hat);
            }
        } else {
            active = _getHatStatus(_hat);
        }
    }

    /// @notice Internal function to retrieve a hat's status from storage
    /// @dev reads the 0th bit of the hat's config
    /// @param _hat The hat object
    /// @return status Whether the hat is active
    function _getHatStatus(Hat storage _hat) internal view returns (bool status) {
        status = (_hat.config >> 95 != 0);
    }

    /// @notice Internal function to retrieve a hat's mutability setting
    /// @dev reads the 1st bit of the hat's config
    /// @param _hat The hat object
    /// @return _mutable Whether the hat is mutable
    function _isMutable(Hat storage _hat) internal view returns (bool _mutable) {
        _mutable = (_hat.config & uint96(1 << 94) != 0);
    }

    /// @notice Checks whether a wearer of a Hat is in good standing
    /// @param _wearer The address of the Hat wearer
    /// @param _hatId The id of the Hat
    /// @return standing Whether the wearer is in good standing
    function isInGoodStanding(address _wearer, uint256 _hatId) public view returns (bool standing) {
        (bool success, bytes memory returndata) = _hats[_hatId].eligibility.staticcall(
            abi.encodeWithSignature("getWearerStatus(address,uint256)", _wearer, _hatId)
        );

        /* 
        * if function call succeeds with data of length == 64, then we know the contract exists 
        * and has the getWearerStatus function (which returns two words).
        * But — since function selectors don't include return types — we still can't assume that the return data is two booleans, 
        * so we treat it as a uint so it will always safely decode without throwing.
        */
        if (success && returndata.length == 64) {
            // check the returndata manually
            (uint256 firstWord, uint256 secondWord) = abi.decode(returndata, (uint256, uint256));
            // returndata is valid
            if (firstWord < 2 && secondWord < 2) {
                standing = (secondWord == 1) ? true : false;
                // returndata is invalid
            } else {
                standing = !badStandings[_hatId][_wearer];
            }
        } else {
            standing = !badStandings[_hatId][_wearer];
        }
    }

    /// @notice Internal call to check whether an address is eligible for a given Hat
    /// @dev Tries an external call to the Hat's eligibility module, defaulting to existing badStandings state if the call fails (ie if the eligibility module address does not conform to the IHatsEligibility interface)
    /// @param _wearer The address of the Hat wearer
    /// @param _hat The Hat object
    /// @param _hatId The id of the Hat
    /// @return eligible Whether the wearer is eligible for the Hat
    function _isEligible(address _wearer, Hat storage _hat, uint256 _hatId) internal view returns (bool eligible) {
        (bool success, bytes memory returndata) =
            _hat.eligibility.staticcall(abi.encodeWithSignature("getWearerStatus(address,uint256)", _wearer, _hatId));

        /* 
        * if function call succeeds with data of length == 64, then we know the contract exists 
        * and has the getWearerStatus function (which returns two words).
        * But — since function selectors don't include return types — we still can't assume that the return data is two booleans, 
        * so we treat it as a uint so it will always safely decode without throwing.
        */
        if (success && returndata.length == 64) {
            bool standing;
            // check the returndata manually
            (uint256 firstWord, uint256 secondWord) = abi.decode(returndata, (uint256, uint256));
            // returndata is valid
            if (firstWord < 2 && secondWord < 2) {
                standing = (secondWord == 1) ? true : false;
                // never eligible if in bad standing
                eligible = (standing && firstWord == 1) ? true : false;
            }
            // returndata is invalid
            else {
                eligible = !badStandings[_hatId][_wearer];
            }
        } else {
            eligible = !badStandings[_hatId][_wearer];
        }
    }

    /// @notice Checks whether an address is eligible for a given Hat
    /// @dev Public function for use when passing a Hat object is not possible or preferable
    /// @param _hatId The id of the Hat
    /// @param _wearer The address to check
    /// @return eligible Whether the wearer is eligible for the Hat
    function isEligible(address _wearer, uint256 _hatId) public view returns (bool eligible) {
        eligible = _isEligible(_wearer, _hats[_hatId], _hatId);
    }

    /// @notice Gets the current supply of a Hat
    /// @dev Only tracks explicit burns and mints, not dynamic revocations
    /// @param _hatId The id of the Hat
    /// @return supply The current supply of the Hat
    function hatSupply(uint256 _hatId) external view returns (uint32 supply) {
        supply = _hats[_hatId].supply;
    }

    /// @notice Gets the imageURI for a given hat
    /// @dev If this hat does not have an imageURI set, recursively get the imageURI from
    ///      its admin
    /// @param _hatId The hat whose imageURI we're looking for
    /// @return _uri The imageURI of this hat or, if empty, its admin
    function getImageURIForHat(uint256 _hatId) public view returns (string memory _uri) {
        // check _hatId first to potentially avoid the `getHatLevel` call
        Hat storage hat = _hats[_hatId];

        string memory imageURI = hat.imageURI; // save 1 SLOAD

        // if _hatId has an imageURI, we return it
        if (bytes(imageURI).length > 0) {
            return imageURI;
        }

        // otherwise, we check its branch of admins
        uint256 level = getHatLevel(_hatId);

        // but first we check if _hatId is a tophat, in which case we fall back to the global image uri
        if (level == 0) return baseImageURI;

        // otherwise, we check each of its admins for a valid imageURI
        uint256 id;

        // already checked at `level` above, so we start the loop at `level - 1`
        for (uint256 i = level - 1; i > 0;) {
            id = getAdminAtLevel(_hatId, uint32(i));
            hat = _hats[id];
            imageURI = hat.imageURI;

            if (bytes(imageURI).length > 0) {
                return imageURI;
            }
            // should not underflow given stopping condition is > 0
            unchecked {
                --i;
            }
        }

        id = getAdminAtLevel(_hatId, 0);
        hat = _hats[id];
        imageURI = hat.imageURI;

        if (bytes(imageURI).length > 0) {
            return imageURI;
        }

        // if none of _hatId's admins has an imageURI of its own, we again fall back to the global image uri
        _uri = baseImageURI;
    }

    /// @notice Constructs the URI for a Hat, using data from the Hat struct
    /// @param _hatId The id of the Hat
    /// @return _uri An ERC1155-compatible JSON string
    function _constructURI(uint256 _hatId) internal view returns (string memory _uri) {
        Hat storage hat = _hats[_hatId];

        uint256 hatAdmin;

        if (isTopHat(_hatId)) {
            hatAdmin = _hatId;
        } else {
            hatAdmin = getAdminAtLevel(_hatId, getHatLevel(_hatId) - 1);
        }

        // split into two objects to avoid stack too deep error
        string memory idProperties = string.concat(
            '"domain": "',
            LibString.toString(getTopHatDomain(_hatId)),
            '", "id": "',
            LibString.toString(_hatId),
            '", "pretty id": "',
            LibString.toHexString(_hatId, 32),
            '",'
        );

        string memory otherProperties = string.concat(
            '"status": "',
            (_isActive(hat, _hatId) ? "active" : "inactive"),
            '", "current supply": "',
            LibString.toString(hat.supply),
            '", "supply cap": "',
            LibString.toString(hat.maxSupply),
            '", "admin (id)": "',
            LibString.toString(hatAdmin),
            '", "admin (pretty id)": "',
            LibString.toHexString(hatAdmin, 32),
            '", "eligibility module": "',
            LibString.toHexString(hat.eligibility),
            '", "toggle module": "',
            LibString.toHexString(hat.toggle),
            '", "mutable": "',
            _isMutable(hat) ? "true" : "false",
            '"'
        );

        _uri = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        string.concat(
                            '{"name": "',
                            "Hat",
                            '", "description": "',
                            hat.details,
                            '", "image": "',
                            getImageURIForHat(_hatId),
                            '",',
                            '"properties": ',
                            "{",
                            idProperties,
                            otherProperties,
                            "}",
                            "}"
                        )
                    )
                )
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC1155 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @notice Gets the Hat token balance of a user for a given Hat
    /// @dev Balance is dynamic based on the hat's status and wearer's eligibility, so off-chain balance data indexed from events may not be in sync
    /// @param _wearer The address whose balance is being checked
    /// @param _hatId The id of the Hat
    /// @return balance The `wearer`'s balance of the Hat tokens. Can never be > 1.
    function balanceOf(address _wearer, uint256 _hatId)
        public
        view
        override(ERC1155, IHats)
        returns (uint256 balance)
    {
        Hat storage hat = _hats[_hatId];

        balance = 0;

        if (_isActive(hat, _hatId) && _isEligible(_wearer, hat, _hatId)) {
            balance = super.balanceOf(_wearer, _hatId);
        }
    }

    /// @notice Internal call to mint a Hat token to a wearer
    /// @dev Unsafe if called when `_wearer` has a non-zero balance of `_hatId`
    /// @param _wearer The wearer of the Hat and the recipient of the newly minted token
    /// @param _hatId The id of the Hat to mint
    function _mintHat(address _wearer, uint256 _hatId) internal {
        unchecked {
            // should not overflow since `mintHat` enforces max balance of 1
            _balanceOf[_wearer][_hatId] = 1;

            // increment Hat supply counter
            // should not overflow given AllHatsWorn check in `mintHat`
            ++_hats[_hatId].supply;
        }

        emit TransferSingle(msg.sender, address(0), _wearer, _hatId, 1);
    }

    /// @notice Internal call to burn a wearer's Hat token
    /// @dev Unsafe if called when `_wearer` doesn't have a zero balance of `_hatId`
    /// @param _wearer The wearer from which to burn the Hat token
    /// @param _hatId The id of the Hat to burn
    function _burnHat(address _wearer, uint256 _hatId) internal {
        // neither should underflow since `_burnHat` is never called on non-positive balance
        unchecked {
            _balanceOf[_wearer][_hatId] = 0;

            // decrement Hat supply counter
            --_hats[_hatId].supply;
        }

        emit TransferSingle(msg.sender, _wearer, address(0), _hatId, 1);
    }

    /// @notice Approvals are not necessary for Hats since transfers are not handled by the wearer
    /// @dev Admins should use `transferHat()` to transfer
    function setApprovalForAll(address, bool) public pure override {
        revert();
    }

    /// @notice Safe transfers are not necessary for Hats since transfers are not handled by the wearer
    /// @dev Admins should use `transferHat()` to transfer
    function safeTransferFrom(address, address, uint256, uint256, bytes calldata) public pure override {
        revert();
    }

    /// @notice Safe transfers are not necessary for Hats since transfers are not handled by the wearer
    function safeBatchTransferFrom(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        public
        pure
        override
    {
        revert();
    }

    /**
     * @notice ERC165 interface detection
     *  @dev While Hats Protocol conforms to the ERC1155 *interface*, it does not fully conform to the ERC1155 *specification*
     *  since it does not implement the ERC1155Receiver functionality.
     *  For this reason, this function overrides the ERC1155 implementation to return false for ERC1155.
     *  @param interfaceId The interface identifier, as specified in ERC-165
     *  @return bool True if the contract implements `interfaceId` and false otherwise
     */
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            // interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            || interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /// @notice Batch retrieval for wearer balances
    /// @dev Given the higher gas overhead of Hats balanceOf checks, large batches may be high cost or run into gas limits
    /// @param _wearers Array of addresses to check balances for
    /// @param _hatIds Array of Hat ids to check, using the same index as _wearers
    function balanceOfBatch(address[] calldata _wearers, uint256[] calldata _hatIds)
        public
        view
        override(ERC1155, IHats)
        returns (uint256[] memory balances)
    {
        if (_wearers.length != _hatIds.length) revert BatchArrayLengthMismatch();

        balances = new uint256[](_wearers.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i; i < _wearers.length; ++i) {
                balances[i] = balanceOf(_wearers[i], _hatIds[i]);
            }
        }
    }

    /// @notice View the uri for a Hat
    /// @param id The id of the Hat
    /// @return _uri An 1155-compatible JSON object
    function uri(uint256 id) public view override(ERC1155, IHats) returns (string memory _uri) {
        _uri = _constructURI(id);
    }
}

// SPDX-License-Identifier: AGPL-3.0
// Copyright (C) 2023 Haberdasher Labs
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.8.13;

import "./Interfaces/IHatsIdUtilities.sol";
// import { console2 } from "forge-std/Test.sol"; //remove after testing

/// @notice see HatsErrors.sol for description
error MaxLevelsReached();

/// @title Hats Id Utilities
/// @dev Functions for working with Hat Ids from Hats Protocol. Factored out of Hats.sol
/// for easier use by other contracts.
/// @author Haberdasher Labs
contract HatsIdUtilities is IHatsIdUtilities {
    /// @notice Mapping of tophats requesting to link to admin hats in other trees
    /// @dev Linkage only occurs if request is approved by the new admin
    mapping(uint32 => uint256) public linkedTreeRequests; // topHatDomain => requested new admin

    /// @notice Mapping of approved & linked tophats to admin hats in other trees, used for grafting one hats tree onto another
    /// @dev Trees can only be linked to another tree via their tophat
    mapping(uint32 => uint256) public linkedTreeAdmins; // topHatDomain => hatId

    /**
     * Hat Ids serve as addresses. A given Hat's Id represents its location in its
     * hat tree: its level, its admin, its admin's admin (etc, all the way up to the
     * tophat).
     *
     * The top level consists of 4 bytes and references all tophats.
     *
     * Each level below consists of 16 bits, and contains up to 65,536 child hats.
     *
     * A uint256 contains 4 bytes of space for tophat addresses, giving room for ((256 -
     * 32) / 16) = 14 levels of delegation, with the admin at each level having space for
     * 65,536 different child hats.
     *
     * A hat tree consists of a single tophat and has a max depth of 14 levels.
     */

    /// @dev Number of bits of address space for tophat ids, ie the tophat domain
    uint256 internal constant TOPHAT_ADDRESS_SPACE = 32;

    /// @dev Number of bits of address space for each level below the tophat
    uint256 internal constant LOWER_LEVEL_ADDRESS_SPACE = 16;

    /// @dev Maximum number of levels below the tophat, ie max tree depth
    ///      (256 - TOPHAT_ADDRESS_SPACE) / LOWER_LEVEL_ADDRESS_SPACE;
    uint256 internal constant MAX_LEVELS = 14;

    /// @notice Constructs a valid hat id for a new hat underneath a given admin
    /// @dev Reverts if the admin has already reached `MAX_LEVELS`
    /// @param _admin the id of the admin for the new hat
    /// @param _newHat the uint16 id of the new hat
    /// @return id The constructed hat id
    function buildHatId(uint256 _admin, uint16 _newHat) public pure returns (uint256 id) {
        uint256 mask;
        for (uint256 i = 0; i < MAX_LEVELS;) {
            unchecked {
                mask = uint256(
                    type(uint256).max
                    // should not overflow given known constants
                    >> (TOPHAT_ADDRESS_SPACE + (LOWER_LEVEL_ADDRESS_SPACE * i))
                );
            }
            if (_admin & mask == 0) {
                unchecked {
                    id = _admin
                        | (
                            uint256(_newHat)
                            // should not overflow given known constants
                            << (LOWER_LEVEL_ADDRESS_SPACE * (MAX_LEVELS - 1 - i))
                        );
                }
                return id;
            }

            // should not overflow based on < MAX_LEVELS stopping condition
            unchecked {
                ++i;
            }
        }

        // if _admin is already at MAX_LEVELS, child hats are not possible, so we revert
        revert MaxLevelsReached();
    }

    /// @notice Identifies the level a given hat in its hat tree
    /// @param _hatId the id of the hat in question
    /// @return level (0 to type(uint32).max)
    function getHatLevel(uint256 _hatId) public view returns (uint32 level) {
        // uint256 mask;
        // uint256 i;
        level = getLocalHatLevel(_hatId);

        uint256 treeAdmin = linkedTreeAdmins[getTopHatDomain(_hatId)];

        if (treeAdmin != 0) {
            level = 1 + level + getHatLevel(treeAdmin);
        }
    }

    /// @notice Identifies the level a given hat in its local hat tree
    /// @dev Similar to getHatLevel, but does not account for linked trees
    /// @param _hatId the id of the hat in question
    /// @return level The local level, from 0 to 14
    function getLocalHatLevel(uint256 _hatId) public pure returns (uint32 level) {
        if (_hatId & uint256(type(uint224).max) == 0) return 0;
        if (_hatId & uint256(type(uint208).max) == 0) return 1;
        if (_hatId & uint256(type(uint192).max) == 0) return 2;
        if (_hatId & uint256(type(uint176).max) == 0) return 3;
        if (_hatId & uint256(type(uint160).max) == 0) return 4;
        if (_hatId & uint256(type(uint144).max) == 0) return 5;
        if (_hatId & uint256(type(uint128).max) == 0) return 6;
        if (_hatId & uint256(type(uint112).max) == 0) return 7;
        if (_hatId & uint256(type(uint96).max) == 0) return 8;
        if (_hatId & uint256(type(uint80).max) == 0) return 9;
        if (_hatId & uint256(type(uint64).max) == 0) return 10;
        if (_hatId & uint256(type(uint48).max) == 0) return 11;
        if (_hatId & uint256(type(uint32).max) == 0) return 12;
        if (_hatId & uint256(type(uint16).max) == 0) return 13;
        return 14;
    }

    /// @notice Checks whether a hat is a topHat
    /// @param _hatId The hat in question
    /// @return _isTopHat Whether the hat is a topHat
    function isTopHat(uint256 _hatId) public view returns (bool _isTopHat) {
        _isTopHat = isLocalTopHat(_hatId) && linkedTreeAdmins[getTopHatDomain(_hatId)] == 0;
    }

    /// @notice Checks whether a hat is a topHat in its local hat tree
    /// @dev Similar to isTopHat, but does not account for linked trees
    /// @param _hatId The hat in question
    /// @return _isLocalTopHat Whether the hat is a topHat for its local tree
    function isLocalTopHat(uint256 _hatId) public pure returns (bool _isLocalTopHat) {
        _isLocalTopHat = _hatId > 0 && uint224(_hatId) == 0;
    }

    function isValidHatId(uint256 _hatId) public pure returns (bool validHatId) {
        // valid top hats are valid hats
        if (isLocalTopHat(_hatId)) return true;

        uint32 level = getLocalHatLevel(_hatId);
        uint256 admin;
        // for each subsequent level up the tree, check if the level is 0 and return false if so
        for (uint256 i = level - 1; i > 0;) {
            // truncate to find the (truncated) admin at this level
            // we don't need to check _hatId's own level since getLocalHatLevel already ensures that its non-empty
            admin = _hatId >> (LOWER_LEVEL_ADDRESS_SPACE * (MAX_LEVELS - i));
            // if the lowest level of the truncated admin is empty, the hat id is invalid
            if (uint16(admin) == 0) return false;

            unchecked {
                --i;
            }
        }
        // if there are no empty levels, return true
        return true;
    }

    /// @notice Gets the hat id of the admin at a given level of a given hat
    /// @dev This function traverses trees by following the linkedTreeAdmin
    ///       pointer to a hat located in a different tree
    /// @param _hatId the id of the hat in question
    /// @param _level the admin level of interest
    /// @return admin The hat id of the resulting admin
    function getAdminAtLevel(uint256 _hatId, uint32 _level) public view returns (uint256 admin) {
        uint256 linkedTreeAdmin = linkedTreeAdmins[getTopHatDomain(_hatId)];
        if (linkedTreeAdmin == 0) return admin = getAdminAtLocalLevel(_hatId, _level);

        uint32 localTopHatLevel = getHatLevel(getAdminAtLocalLevel(_hatId, 0));

        if (localTopHatLevel <= _level) return admin = getAdminAtLocalLevel(_hatId, _level - localTopHatLevel);

        return admin = getAdminAtLevel(linkedTreeAdmin, _level);
    }

    /// @notice Gets the hat id of the admin at a given level of a given hat
    ///         local to the tree containing the hat.
    /// @param _hatId the id of the hat in question
    /// @param _level the admin level of interest
    /// @return admin The hat id of the resulting admin
    function getAdminAtLocalLevel(uint256 _hatId, uint32 _level) public pure returns (uint256 admin) {
        uint256 mask = type(uint256).max << (LOWER_LEVEL_ADDRESS_SPACE * (MAX_LEVELS - _level));

        admin = _hatId & mask;
    }

    /// @notice Gets the tophat domain of a given hat
    /// @dev A domain is the identifier for a given hat tree, stored in the first 4 bytes of a hat's id
    /// @param _hatId the id of the hat in question
    /// @return domain The domain of the hat's tophat
    function getTopHatDomain(uint256 _hatId) public pure returns (uint32 domain) {
        domain = uint32(_hatId >> (LOWER_LEVEL_ADDRESS_SPACE * MAX_LEVELS));
    }

    /// @notice Gets the domain of the highest parent tophat — the "tippy tophat"
    /// @param _topHatDomain the 32 bit domain of a (likely linked) tophat
    /// @return domain The tippy tophat domain
    function getTippyTopHatDomain(uint32 _topHatDomain) public view returns (uint32 domain) {
        uint256 linkedAdmin = linkedTreeAdmins[_topHatDomain];
        if (linkedAdmin == 0) return domain = _topHatDomain;
        return domain = getTippyTopHatDomain(getTopHatDomain(linkedAdmin));
    }

    /// @notice Checks For any circular linkage of trees
    /// @param _topHatDomain the 32 bit domain of the tree to be linked
    /// @param _linkedAdmin the hatId of the potential tree admin
    /// @return notCircular circular link has not been found
    function noCircularLinkage(uint32 _topHatDomain, uint256 _linkedAdmin) public view returns (bool notCircular) {
        if (_linkedAdmin == 0) return true;
        uint32 adminDomain = getTopHatDomain(_linkedAdmin);
        if (_topHatDomain == adminDomain) return false;
        uint256 parentAdmin = linkedTreeAdmins[adminDomain];
        return noCircularLinkage(_topHatDomain, parentAdmin);
    }

    /// @notice Checks that a tophat domain and its potential linked admin are from the same tree, ie have the same tippy tophat domain
    /// @param _topHatDomain The 32 bit domain of the tophat to be linked
    /// @param _newAdminHat The new admin for the linked tree
    /// @return sameDomain Whether the _topHatDomain and the domain of its potential linked _newAdminHat domains are the same
    function sameTippyTopHatDomain(uint32 _topHatDomain, uint256 _newAdminHat) public view returns (bool sameDomain) {
        // get highest parent domains for current and new tree root admins
        uint32 currentTippyTophatDomain = getTippyTopHatDomain(_topHatDomain);
        uint32 newAdminDomain = getTopHatDomain(_newAdminHat);
        uint32 newHTippyTophatDomain = getTippyTopHatDomain(newAdminDomain);

        // check that both domains are equal
        sameDomain = (currentTippyTophatDomain == newHTippyTophatDomain);
    }
}

// SPDX-License-Identifier: AGPL-3.0
// Copyright (C) 2023 Haberdasher Labs
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.8.13;

interface HatsErrors {
    /// @notice Emitted when `user` is attempting to perform an action on `hatId` but is not wearing one of `hatId`'s admin hats
    /// @dev Can be equivalent to `NotHatWearer(buildHatId(hatId))`, such as when emitted by `approveLinkTopHatToTree` or `relinkTopHatToTree`
    error NotAdmin(address user, uint256 hatId);

    /// @notice Emitted when attempting to perform an action as or for an account that is not a wearer of a given hat
    error NotHatWearer();

    /// @notice Emitted when attempting to perform an action that requires being either an admin or wearer of a given hat
    error NotAdminOrWearer();

    /// @notice Emitted when attempting to mint `hatId` but `hatId`'s maxSupply has been reached
    error AllHatsWorn(uint256 hatId);

    /// @notice Emitted when attempting to create a hat with a level 14 hat as its admin
    error MaxLevelsReached();

    /// @notice Emitted when an attempted hat id has empty intermediate level(s)
    error InvalidHatId();

    /// @notice Emitted when attempting to mint `hatId` to a `wearer` who is already wearing the hat
    error AlreadyWearingHat(address wearer, uint256 hatId);

    /// @notice Emitted when attempting to mint a non-existant hat
    error HatDoesNotExist(uint256 hatId);

    /// @notice Emmitted when attempting to mint or transfer a hat that is not active
    error HatNotActive();

    /// @notice Emitted when attempting to mint or transfer a hat to an ineligible wearer
    error NotEligible();

    /// @notice Emitted when attempting to check or set a hat's status from an account that is not that hat's toggle module
    error NotHatsToggle();

    /// @notice Emitted when attempting to check or set a hat wearer's status from an account that is not that hat's eligibility module
    error NotHatsEligibility();

    /// @notice Emitted when array arguments to a batch function have mismatching lengths
    error BatchArrayLengthMismatch();

    /// @notice Emitted when attempting to mutate or transfer an immutable hat
    error Immutable();

    /// @notice Emitted when attempting to change a hat's maxSupply to a value lower than its current supply
    error NewMaxSupplyTooLow();

    /// @notice Emitted when attempting to link a tophat to a new admin for which the tophat serves as an admin
    error CircularLinkage();

    /// @notice Emitted when attempting to link or relink a tophat to a separate tree
    error CrossTreeLinkage();

    /// @notice Emitted when attempting to link a tophat without a request
    error LinkageNotRequested();

    /// @notice Emmited when attempting to change a hat's eligibility or toggle module to the zero address
    error ZeroAddress();

    /// @notice Emmitted when attempting to change a hat's details or imageURI to a string with over 7000 bytes (~characters)
    /// @dev This protects against a DOS attack where an admin iteratively extend's a hat's details or imageURI
    ///      to be so long that reading it exceeds the block gas limit, breaking `uri()` and `viewHat()`
    error StringTooLong();
}

// SPDX-License-Identifier: AGPL-3.0
// Copyright (C) 2023 Haberdasher Labs
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.8.13;

interface HatsEvents {
    /// @notice Emitted when a new hat is created
    /// @param id The id for the new hat
    /// @param details A description of the Hat
    /// @param maxSupply The total instances of the Hat that can be worn at once
    /// @param eligibility The address that can report on the Hat wearer's status
    /// @param toggle The address that can deactivate the Hat
    /// @param mutable_ Whether the hat's properties are changeable after creation
    /// @param imageURI The image uri for this hat and the fallback for its
    event HatCreated(
        uint256 id,
        string details,
        uint32 maxSupply,
        address eligibility,
        address toggle,
        bool mutable_,
        string imageURI
    );

    /// @notice Emitted when a hat wearer's standing is updated
    /// @dev Eligibility is excluded since the source of truth for eligibility is the eligibility module and may change without a transaction
    /// @param hatId The id of the wearer's hat
    /// @param wearer The wearer's address
    /// @param wearerStanding Whether the wearer is in good standing for the hat
    event WearerStandingChanged(uint256 hatId, address wearer, bool wearerStanding);

    /// @notice Emitted when a hat's status is updated
    /// @param hatId The id of the hat
    /// @param newStatus Whether the hat is active
    event HatStatusChanged(uint256 hatId, bool newStatus);

    /// @notice Emitted when a hat's details are updated
    /// @param hatId The id of the hat
    /// @param newDetails The updated details
    event HatDetailsChanged(uint256 hatId, string newDetails);

    /// @notice Emitted when a hat's eligibility module is updated
    /// @param hatId The id of the hat
    /// @param newEligibility The updated eligibiliy module
    event HatEligibilityChanged(uint256 hatId, address newEligibility);

    /// @notice Emitted when a hat's toggle module is updated
    /// @param hatId The id of the hat
    /// @param newToggle The updated toggle module
    event HatToggleChanged(uint256 hatId, address newToggle);

    /// @notice Emitted when a hat's mutability is updated
    /// @param hatId The id of the hat
    event HatMutabilityChanged(uint256 hatId);

    /// @notice Emitted when a hat's maximum supply is updated
    /// @param hatId The id of the hat
    /// @param newMaxSupply The updated max supply
    event HatMaxSupplyChanged(uint256 hatId, uint32 newMaxSupply);

    /// @notice Emitted when a hat's image URI is updated
    /// @param hatId The id of the hat
    /// @param newImageURI The updated image URI
    event HatImageURIChanged(uint256 hatId, string newImageURI);

    /// @notice Emitted when a tophat linkage is requested by its admin
    /// @param domain The domain of the tree tophat to link
    /// @param newAdmin The tophat's would-be admin in the parent tree
    event TopHatLinkRequested(uint32 domain, uint256 newAdmin);

    /// @notice Emitted when a tophat is linked to a another tree
    /// @param domain The domain of the newly-linked tophat
    /// @param newAdmin The tophat's new admin in the parent tree
    event TopHatLinked(uint32 domain, uint256 newAdmin);
}

// SPDX-License-Identifier: AGPL-3.0
// Copyright (C) 2023 Haberdasher Labs
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.8.13;

import "./IHatsIdUtilities.sol";
import "./HatsErrors.sol";
import "./HatsEvents.sol";

interface IHats is IHatsIdUtilities, HatsErrors, HatsEvents {
    function mintTopHat(address _target, string memory _details, string memory _imageURI)
        external
        returns (uint256 topHatId);

    function createHat(
        uint256 _admin,
        string calldata _details,
        uint32 _maxSupply,
        address _eligibility,
        address _toggle,
        bool _mutable,
        string calldata _imageURI
    ) external returns (uint256 newHatId);

    function batchCreateHats(
        uint256[] calldata _admins,
        string[] calldata _details,
        uint32[] calldata _maxSupplies,
        address[] memory _eligibilityModules,
        address[] memory _toggleModules,
        bool[] calldata _mutables,
        string[] calldata _imageURIs
    ) external returns (bool success);

    function getNextId(uint256 _admin) external view returns (uint256 nextId);

    function mintHat(uint256 _hatId, address _wearer) external returns (bool success);

    function batchMintHats(uint256[] calldata _hatIds, address[] calldata _wearers) external returns (bool success);

    function setHatStatus(uint256 _hatId, bool _newStatus) external returns (bool toggled);

    function checkHatStatus(uint256 _hatId) external returns (bool toggled);

    function setHatWearerStatus(uint256 _hatId, address _wearer, bool _eligible, bool _standing)
        external
        returns (bool updated);

    function checkHatWearerStatus(uint256 _hatId, address _wearer) external returns (bool updated);

    function renounceHat(uint256 _hatId) external;

    function transferHat(uint256 _hatId, address _from, address _to) external;

    /*//////////////////////////////////////////////////////////////
                              HATS ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function makeHatImmutable(uint256 _hatId) external;

    function changeHatDetails(uint256 _hatId, string memory _newDetails) external;

    function changeHatEligibility(uint256 _hatId, address _newEligibility) external;

    function changeHatToggle(uint256 _hatId, address _newToggle) external;

    function changeHatImageURI(uint256 _hatId, string memory _newImageURI) external;

    function changeHatMaxSupply(uint256 _hatId, uint32 _newMaxSupply) external;

    function requestLinkTopHatToTree(uint32 _topHatId, uint256 _newAdminHat) external;

    function approveLinkTopHatToTree(
        uint32 _topHatId,
        uint256 _newAdminHat,
        address _eligibility,
        address _toggle,
        string calldata _details,
        string calldata _imageURI
    ) external;

    function unlinkTopHatFromTree(uint32 _topHatId) external;

    function relinkTopHatWithinTree(
        uint32 _topHatDomain,
        uint256 _newAdminHat,
        address _eligibility,
        address _toggle,
        string calldata _details,
        string calldata _imageURI
    ) external;

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function viewHat(uint256 _hatId)
        external
        view
        returns (
            string memory details,
            uint32 maxSupply,
            uint32 supply,
            address eligibility,
            address toggle,
            string memory imageURI,
            uint16 lastHatId,
            bool mutable_,
            bool active
        );

    function isWearerOfHat(address _user, uint256 _hatId) external view returns (bool isWearer);

    function isAdminOfHat(address _user, uint256 _hatId) external view returns (bool isAdmin);

    function isInGoodStanding(address _wearer, uint256 _hatId) external view returns (bool standing);

    function isEligible(address _wearer, uint256 _hatId) external view returns (bool eligible);

    function hatSupply(uint256 _hatId) external view returns (uint32 supply);

    function getImageURIForHat(uint256 _hatId) external view returns (string memory _uri);

    function balanceOf(address wearer, uint256 hatId) external view returns (uint256 balance);

    function balanceOfBatch(address[] calldata _wearers, uint256[] calldata _hatIds)
        external
        view
        returns (uint256[] memory);

    function uri(uint256 id) external view returns (string memory _uri);
}

// SPDX-License-Identifier: AGPL-3.0
// Copyright (C) 2023 Haberdasher Labs
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.8.13;

interface IHatsEligibility {
    /// @notice Returns the status of a wearer for a given hat
    /// @dev If standing is false, eligibility MUST also be false
    /// @param _wearer The address of the current or prospective Hat wearer
    /// @param _hatId The id of the hat in question
    /// @return eligible Whether the _wearer is eligible to wear the hat
    /// @return standing Whether the _wearer is in goog standing
    function getWearerStatus(address _wearer, uint256 _hatId) external view returns (bool eligible, bool standing);
}

// SPDX-License-Identifier: AGPL-3.0
// Copyright (C) 2023 Haberdasher Labs
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.8.13;

interface IHatsIdUtilities {
    function buildHatId(uint256 _admin, uint16 _newHat) external pure returns (uint256 id);

    function getHatLevel(uint256 _hatId) external view returns (uint32 level);

    function getLocalHatLevel(uint256 _hatId) external pure returns (uint32 level);

    function isTopHat(uint256 _hatId) external view returns (bool _topHat);

    function isLocalTopHat(uint256 _hatId) external pure returns (bool _localTopHat);

    function isValidHatId(uint256 _hatId) external view returns (bool validHatId);

    function getAdminAtLevel(uint256 _hatId, uint32 _level) external view returns (uint256 admin);

    function getAdminAtLocalLevel(uint256 _hatId, uint32 _level) external pure returns (uint256 admin);

    function getTopHatDomain(uint256 _hatId) external view returns (uint32 domain);

    function getTippyTopHatDomain(uint32 _topHatDomain) external view returns (uint32 domain);

    function noCircularLinkage(uint32 _topHatDomain, uint256 _linkedAdmin) external view returns (bool notCircular);

    function sameTippyTopHatDomain(uint32 _topHatDomain, uint256 _newAdminHat)
        external
        view
        returns (bool sameDomain);
}

// SPDX-License-Identifier: AGPL-3.0
// Copyright (C) 2023 Haberdasher Labs
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.8.13;

interface IHatsToggle {
    function getHatStatus(uint256 _hatId) external view returns (bool);
}