// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "openzeppelin/utils/Strings.sol";
import "solmate/tokens/ERC1155.sol";

import "./Owned.sol";

/// @title Solarbots Achievements
/// @author Solarbots (https://solarbots.io)
/// @notice All achievements are soulbound,
/// i.e. can't be transferred by the token owner.
/// Only approved operators can mint, transfer, and burn
/// tokens. Token owners can only burn their own tokens.
contract Achievements is ERC1155, Owned {
    // ---------- CONSTANTS ----------

    /// @dev bytes32(abi.encodePacked("INSUFFICIENT_BALANCE"))
    bytes32 private constant _INSUFFICIENT_BALANCE_MESSAGE = 0x494e53554646494349454e545f42414c414e4345000000000000000000000000;

    /// @dev "INSUFFICIENT_BALANCE" is 20 characters long
    uint256 private constant _INSUFFICIENT_BALANCE_LENGTH = 20;

    // ---------- STATE ----------

    /// @notice Metadata base URI
    string public baseURI;

    /// @notice Metadata URI suffix
    string public uriSuffix;

    // ---------- CONSTRUCTOR ----------

    /// @param owner Contract owner
    constructor(address owner) Owned(owner) {}

    // ---------- METADATA ----------

    /// @notice Get metadata URI
    /// @param id Token ID
    /// @return Metadata URI of token ID `id`
    function uri(uint256 id) public view override returns (string memory) {
        require(bytes(baseURI).length > 0, "NO_METADATA");
		return string(abi.encodePacked(baseURI, Strings.toString(id), uriSuffix));
    }

    /// @notice Set metadata base URI
    /// @param _baseURI New metadata base URI
    /// @dev Doesn't emit URI event, because `id` argument isn't used
    function setBaseURI(string calldata _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    /// @notice Set metadata URI suffix
    /// @param _uriSuffix New metadata URI suffix
    /// @dev Doesn't emit URI event, because `id` argument isn't used
    function setURISuffix(string calldata _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    // ---------- APPROVAL ----------

    /// @notice Grants or revokes permission to `operator` to transfer tokens
    /// @dev Only callable by contract owner
    /// @param operator Operator address
    /// @param approved Whether to grant or revoke permission
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override onlyOwner {
        isApprovedForAll[address(0)][operator] = approved;

        emit ApprovalForAll(address(0), operator, approved);
    }

    // ---------- TRANSFER ----------

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual override {
        require(isApprovedForAll[address(0)][msg.sender], "NOT_AUTHORIZED");

        // Use assembly to perform optimized balance updates
        // Same balance updates in unoptimized Solidity:
        //
        // balanceOf[from][id] -= amount;
        // balanceOf[to][id] += amount;
        //
        /// @solidity memory-safe-assembly
        assembly {
            // Calculate the storage slot of `balanceOf[from]`
            // by concatenating the `from` address and the
            // slot of `balanceOf` in the scratch space used
            // by hashing methods, i.e. the first two 32 bytes
            // of memory. The keccak256 hash of the concatenated
            // values is the storage slot we're looking for.
            mstore(0x00, from)
            mstore(0x20, balanceOf.slot)
            let balanceOfFromSlot := keccak256(0x00, 0x40)

            // Calculate storage slot of `balanceOf[to]`
            mstore(0x00, to)
            // 0x20 still contains `balanceOf.slot`
            let balanceOfToSlot := keccak256(0x00, 0x40)

            // Calculate storage slot of `balanceOf[from][id]`
            mstore(0x00, id)
            mstore(0x20, balanceOfFromSlot)
            let amountFromSlot := keccak256(0x00, 0x40)

            // Calculate storage slot of `balanceOf[to][id]`
            // 0x00 still contains current id
            mstore(0x20, balanceOfToSlot)
            let amountToSlot := keccak256(0x00, 0x40)

            // Load amount currently stored in `balanceOf[from][id]`
            let currentAmountFrom := sload(amountFromSlot)
            // Revert with message "INSUFFICIENT_BALANCE" if the
            // transfer amount is greater than the current amount
            // of `from` to prevent an integer underflow
            if gt(amount, currentAmountFrom) {
                let freeMemory := mload(0x40)
                // Store "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                mstore(freeMemory, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                // Store data offset
                mstore(add(freeMemory, 0x04), 0x20)
                // Store length of revert string
                mstore(add(freeMemory, 0x24), _INSUFFICIENT_BALANCE_LENGTH)
                // Store revert string
                mstore(add(freeMemory, 0x44), _INSUFFICIENT_BALANCE_MESSAGE)
                revert(freeMemory, 0x64)
            }
            // Subtract transfer amount from current amount of `from`
            let newAmountFrom := sub(currentAmountFrom, amount)

            // Load amount currently stored in `balanceOf[to][id]`
            let currentAmountTo := sload(amountToSlot)
            // Add transfer amount to current amount of `to`
            // Realistically this will never overflow
            let newAmountTo := add(currentAmountTo, amount)

            // Store new amount of `from` in `balanceOf[from][id]`
            sstore(amountFromSlot, newAmountFrom)
            // Store new amount of `to` in `balanceOf[to][id]`
            sstore(amountToSlot, newAmountTo)
        }

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override {
        require(isApprovedForAll[address(0)][msg.sender], "NOT_AUTHORIZED");
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        // Use assembly to perform optimized balance updates
        // Same balance updates in unoptimized Solidity:
        //
        // for (uint256 i = 0; i < ids.length; ++i) {
        //     uint256 id = ids[i];
        //     uint256 amount = amounts[i];
        //
        //     balanceOf[from][id] -= amount;
        //     balanceOf[to][id] += amount;
        // }
        /// @solidity memory-safe-assembly
        assembly {
            // Calculate the storage slot of `balanceOf[from]`
            // by concatenating the `from` address and the
            // slot of `balanceOf` in the scratch space used
            // by hashing methods, i.e. the first two 32 bytes
            // of memory. The keccak256 hash of the concatenated
            // values is the storage slot we're looking for.
            mstore(0x00, from)
            mstore(0x20, balanceOf.slot)
            let balanceOfFromSlot := keccak256(0x00, 0x40)

            // Calculate storage slot of `balanceOf[to]`
            mstore(0x00, to)
            // 0x20 still contains `balanceOf.slot`
            let balanceOfToSlot := keccak256(0x00, 0x40)

            // Calculate length of arrays `ids` and `amounts` in bytes
            let arrayLength := mul(ids.length, 0x20)

            // Loop over all values in `ids` and `amounts` by starting
            // with an index offset of 0 to access the first array element
            // and incrementing this index by 32 after each iteration to
            // access the next array element until the offset reaches the end
            // of the arrays, at which point all values the arrays contain
            // have been accessed
            for
                { let indexOffset := 0x00 }
                lt(indexOffset, arrayLength)
                { indexOffset := add(indexOffset, 0x20) }
            {
                // Load current array elements by adding offset of current
                // array index to start of each array's data area inside calldata
                let amount := calldataload(add(amounts.offset, indexOffset))

                // Calculate storage slot of `balanceOf[from][id]`
                // Load current id from calldata into the first 32 bytes of memory
                mstore(0x00, calldataload(add(ids.offset, indexOffset)))
                mstore(0x20, balanceOfFromSlot)
                let amountFromSlot := keccak256(0x00, 0x40)

                // Calculate storage slot of `balanceOf[to][id]`
                // 0x00 still contains current id
                mstore(0x20, balanceOfToSlot)
                let amountToSlot := keccak256(0x00, 0x40)

                // Load amount currently stored in `balanceOf[from][id]`
                let currentAmountFrom := sload(amountFromSlot)
                // Revert with message "INSUFFICIENT_BALANCE" if the
                // transfer amount is greater than the current amount
                // of `from` to prevent an integer underflow
                if gt(amount, currentAmountFrom) {
                    let freeMemory := mload(0x40)
                    // Store "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                    mstore(freeMemory, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    // Store data offset
                    mstore(add(freeMemory, 0x04), 0x20)
                    // Store length of revert string
                    mstore(add(freeMemory, 0x24), _INSUFFICIENT_BALANCE_LENGTH)
                    // Store revert string
                    mstore(add(freeMemory, 0x44), _INSUFFICIENT_BALANCE_MESSAGE)
                    revert(freeMemory, 0x64)
                }
                // Subtract transfer amount from current amount of `from`
                let newAmountFrom := sub(currentAmountFrom, amount)

                // Load amount currently stored in `balanceOf[to][id]`
                let currentAmountTo := sload(amountToSlot)
                // Add transfer amount to current amount of `to`
                // Realistically this will never overflow
                let newAmountTo := add(currentAmountTo, amount)

                // Store new amount of `from` in `balanceOf[from][id]`
                sstore(amountFromSlot, newAmountFrom)
                // Store new amount of `to` in `balanceOf[to][id]`
                sstore(amountToSlot, newAmountTo)
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    // ---------- MINT ----------

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public {
        require(isApprovedForAll[address(0)][msg.sender], "NOT_AUTHORIZED");

        // Realistically this will never overflow
        unchecked {
            balanceOf[to][id] += amount;
        }

        emit TransferSingle(msg.sender, address(0), to, id, amount);
    }

    function mint(
        address[] calldata addresses,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) public {
        require(addresses.length == ids.length && ids.length == amounts.length, "LENGTH_MISMATCH");

        // Calculate array length in bytes
        uint256 arrayLength;
        unchecked {
            arrayLength = addresses.length * 0x20;
        }

        for (uint256 indexOffset = 0x00; indexOffset < arrayLength;) {
            address addr;
            uint256 id;
            uint256 amount;

            /// @solidity memory-safe-assembly
            assembly {
                // Load current array elements by adding offset of current
                // array index to start of each array's data area inside calldata
                addr := calldataload(add(addresses.offset, indexOffset))
                id := calldataload(add(ids.offset, indexOffset))
                amount := calldataload(add(amounts.offset, indexOffset))

                // Increment index offset by 32 for next iteration
                indexOffset := add(indexOffset, 0x20)
            }

            mint(addr, id, amount);
        }
    }

    function safeMint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public {
        mint(to, id, amount);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function batchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) public {
        require(isApprovedForAll[address(0)][msg.sender], "NOT_AUTHORIZED");
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        // Use assembly to perform optimized balance updates
        // Same balance updates in unoptimized Solidity:
        //
        // for (uint256 i = 0; i < ids.length; ++i) {
        //     uint256 id = ids[i];
        //     uint256 amount = amounts[i];
        //
        //     balanceOf[to][id] += amount;
        // }
        /// @solidity memory-safe-assembly
        assembly {
            // Calculate the storage slot of `balanceOf[to]`
            // by concatenating the `to` address and the
            // slot of `balanceOf` in the scratch space used
            // by hashing methods, i.e. the first two 32 bytes
            // of memory. The keccak256 hash of the concatenated
            // values is the storage slot we're looking for.
            mstore(0x00, to)
            mstore(0x20, balanceOf.slot)
            let balanceOfToSlot := keccak256(0x00, 0x40)

            // Store storage slot of `balanceOf[to]` in the second
            // 32 bytes of scratch space to later calculate the storage
            // slot of `balanceOf[to][id]` inside the loop
            mstore(0x20, balanceOfToSlot)

            // Calculate length of arrays `ids` and `amounts` in bytes
            let arrayLength := mul(ids.length, 0x20)

            // Loop over all values in `ids` and `amounts` by starting
            // with an index offset of 0 to access the first array element
            // and incrementing this index by 32 after each iteration to
            // access the next array element until the offset reaches the end
            // of the arrays, at which point all values the arrays contain
            // have been accessed
            for
                { let indexOffset := 0x00 }
                lt(indexOffset, arrayLength)
                { indexOffset := add(indexOffset, 0x20) }
            {
                // Load current array elements by adding offset of current
                // array index to start of each array's data area inside calldata
                let id := calldataload(add(ids.offset, indexOffset))
                let amount := calldataload(add(amounts.offset, indexOffset))

                // Calculate storage slot of `balanceOf[to][id]`
                mstore(0x00, id)
                // 0x20 still contains `balanceOfToSlot`
                let amountToSlot := keccak256(0x00, 0x40)

                // Load amount currently stored in `balanceOf[to][id]`
                let currentAmountTo := sload(amountToSlot)

                // Add mint amount to current amount of `to`
                // Realistically this will never overflow
                let newAmountTo := add(currentAmountTo, amount)

                // Store new amount in `balanceOf[to][id]`
                sstore(amountToSlot, newAmountTo)
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);
    }

    function batchMint(
        address[] calldata addresses,
        uint256[][] calldata ids,
        uint256[][] calldata amounts
    ) public {
        require(addresses.length == ids.length && ids.length == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < addresses.length;) {
            address addr;

            /// @solidity memory-safe-assembly
            assembly {
                // Load current array element by adding offset of current
                // array index to start of array's data area inside calldata
                let indexOffset := mul(i, 0x20)
                addr := calldataload(add(addresses.offset, indexOffset))
            }

            batchMint(addr, ids[i], amounts[i]);

            unchecked {
                i++;
            }
        }
    }

    function safeBatchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public {
        batchMint(to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    // ---------- BURN ----------

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[address(0)][msg.sender], "NOT_AUTHORIZED");

        // Use assembly to perform optimized balance update
        // Same balance update in unoptimized Solidity:
        //
        // balanceOf[from][id] -= amount;
        //
        /// @solidity memory-safe-assembly
        assembly {
            // Calculate the storage slot of `balanceOf[from]`
            // by concatenating the `from` address and the
            // slot of `balanceOf` in the scratch space used
            // by hashing methods, i.e. the first two 32 bytes
            // of memory. The keccak256 hash of the concatenated
            // values is the storage slot we're looking for.
            mstore(0x00, from)
            mstore(0x20, balanceOf.slot)
            let balanceOfFromSlot := keccak256(0x00, 0x40)

            // Calculate storage slot of `balanceOf[from][id]`
            mstore(0x00, id)
            mstore(0x20, balanceOfFromSlot)
            let amountFromSlot := keccak256(0x00, 0x40)

            // Load amount currently stored in `balanceOf[from][id]`
            let currentAmountFrom := sload(amountFromSlot)
            // Revert with message "INSUFFICIENT_BALANCE" if the burn
            // amount is greater than the current amount of `from` to
            // prevent an integer underflow
            if gt(amount, currentAmountFrom) {
                let freeMemory := mload(0x40)
                // Store "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                mstore(freeMemory, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                // Store data offset
                mstore(add(freeMemory, 0x04), 0x20)
                // Store length of revert string
                mstore(add(freeMemory, 0x24), _INSUFFICIENT_BALANCE_LENGTH)
                // Store revert string
                mstore(add(freeMemory, 0x44), _INSUFFICIENT_BALANCE_MESSAGE)
                revert(freeMemory, 0x64)
            }
            // Subtract burn amount from current amount of `from`
            let newAmountFrom := sub(currentAmountFrom, amount)

            // Store new amount of `from` in `balanceOf[from][id]`
            sstore(amountFromSlot, newAmountFrom)
        }

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }

    function batchBurn(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[address(0)][msg.sender], "NOT_AUTHORIZED");
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        // Use assembly to perform optimized balance updates
        // Same balance updates in unoptimized Solidity:
        //
        // for (uint256 i = 0; i < ids.length; ++i) {
        //     uint256 id = ids[i];
        //     uint256 amount = amounts[i];
        //
        //     balanceOf[from][id] -= amount;
        // }
        /// @solidity memory-safe-assembly
        assembly {
            // Calculate the storage slot of `balanceOf[from]`
            // by concatenating the `from` address and the
            // slot of `balanceOf` in the scratch space used
            // by hashing methods, i.e. the first two 32 bytes
            // of memory. The keccak256 hash of the concatenated
            // values is the storage slot we're looking for.
            mstore(0x00, from)
            mstore(0x20, balanceOf.slot)
            let balanceOfFromSlot := keccak256(0x00, 0x40)

            // Store storage slot of `balanceOf[from]` in the second
            // 32 bytes of scratch space to later calculate the storage
            // slot of `balanceOf[from][id]` inside the loop
            mstore(0x20, balanceOfFromSlot)

            // Calculate length of arrays `ids` and `amounts` in bytes
            let arrayLength := mul(ids.length, 0x20)

            // Loop over all values in `ids` and `amounts` by starting
            // with an index offset of 0 to access the first array element
            // and incrementing this index by 32 after each iteration to
            // access the next array element until the offset reaches the end
            // of the arrays, at which point all values the arrays contain
            // have been accessed
            for
                { let indexOffset := 0x00 }
                lt(indexOffset, arrayLength)
                { indexOffset := add(indexOffset, 0x20) }
            {
                // Load current array elements by adding offset of current
                // array index to start of each array's data area inside calldata
                let id := calldataload(add(ids.offset, indexOffset))
                let amount := calldataload(add(amounts.offset, indexOffset))

                // Calculate storage slot of `balanceOf[from][id]`
                mstore(0x00, id)
                // 0x20 still contains `balanceOfFromSlot`
                let amountFromSlot := keccak256(0x00, 0x40)

                // Load amount currently stored in `balanceOf[from][id]`
                let currentAmountFrom := sload(amountFromSlot)
                // Revert with message "INSUFFICIENT_BALANCE" if the burn
                // amount is greater than the current amount of `from` to
                // prevent an integer underflow
                if gt(amount, currentAmountFrom) {
                    let freeMemory := mload(0x40)
                    // Store "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                    mstore(freeMemory, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    // Store data offset
                    mstore(add(freeMemory, 0x04), 0x20)
                    // Store length of revert string
                    mstore(add(freeMemory, 0x24), _INSUFFICIENT_BALANCE_LENGTH)
                    // Store revert string
                    mstore(add(freeMemory, 0x44), _INSUFFICIENT_BALANCE_MESSAGE)
                    revert(freeMemory, 0x64)
                }
                // Subtract burn amount from current amount of `from`
                let newAmountFrom := sub(currentAmountFrom, amount)

                // Store new amount of `from` in `balanceOf[from][id]`
                sstore(amountFromSlot, newAmountFrom)
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
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

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
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

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
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

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
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

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
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
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
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
pragma solidity 0.8.14;

/// @notice Simple contract ownership module
/// @author Solarbots (https://solarbots.io)
abstract contract Owned {
    address public owner;

    event OwnershipTransfer(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "NOT_OWNER");

        _;
    }

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransfer(address(0), _owner);
    }

    function setOwner(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "INVALID_OWNER");

        owner = newOwner;

        emit OwnershipTransfer(msg.sender, newOwner);
    }
}