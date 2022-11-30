// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library CommandBuilder {
    uint256 constant IDX_VARIABLE_LENGTH = 0x80;
    uint256 constant IDX_VALUE_MASK = 0x7f;
    uint256 constant IDX_END_OF_ARGS = 0xff;
    uint256 constant IDX_USE_STATE = 0xfe;
    uint256 constant IDX_ARRAY_START = 0xfd;
    uint256 constant IDX_TUPLE_START = 0xfc;
    uint256 constant IDX_DYNAMIC_END = 0xfb;

    function buildInputs(
        bytes[] memory state,
        bytes4 selector,
        bytes32 indices
    ) internal view returns (bytes memory ret) {
        uint256 idx; // The current command index
        uint256 offsetIdx; // The index of the current free offset

        uint256 count; // Number of bytes in whole ABI encoded message
        uint256 free; // Pointer to first free byte in tail part of message
        uint256[] memory offsets = new uint256[](10); // Optionally store the length of all dynamic types (a command cannot fit more than 10 dynamic types)

        bytes memory stateData; // Optionally encode the current state if the call requires it

        uint256 indicesLength; // Number of indices

        // Determine the length of the encoded data
        for (uint256 i; i < 32; ) {
            idx = uint8(indices[i]);
            if (idx == IDX_END_OF_ARGS) {
                indicesLength = i;
                break;
            }
            if (idx & IDX_VARIABLE_LENGTH != 0) {
                if (idx == IDX_USE_STATE) {
                    if (stateData.length == 0) {
                        stateData = abi.encode(state);
                    }
                    unchecked {
                        count += stateData.length;
                    }
                } else if (idx == IDX_ARRAY_START) {
                    (offsets, offsetIdx, count, i) = setupDynamicArray(state, indices, offsets, offsetIdx, count, i);
                } else if (idx == IDX_TUPLE_START) {
                    (offsets, offsetIdx, count, i) = setupDynamicTuple(state, indices, offsets, offsetIdx, count, i);
                } else {
                    count = setupDynamicVariable(state, count, idx);
                }
            } else {
                count = setupStaticVariable(state, count, idx);
            }
            unchecked {
                free += 32;
                ++i;
            }
        }

        // Encode it
        ret = new bytes(count + 4);
        assembly {
            mstore(add(ret, 32), selector)
        }
        count = 0;
        offsetIdx = 0;
        for (uint256 i; i < indicesLength; ) {
            idx = uint8(indices[i]);
            if (idx & IDX_VARIABLE_LENGTH != 0) {
                if (idx == IDX_USE_STATE) {
                    assembly {
                        mstore(add(add(ret, 36), count), free)
                    }
                    memcpy(stateData, 32, ret, free + 4, stateData.length - 32);
                    unchecked {
                        free += stateData.length - 32;
                        count += 32;
                    }
                } else if (idx == IDX_ARRAY_START) {
                    // Start of dynamic type, put pointer in current slot
                    assembly {
                        mstore(add(add(ret, 36), count), free)
                    }
                    (offsetIdx, free, , i) = encodeDynamicArray(ret, state, indices, offsets, offsetIdx, free, i);
                    unchecked {
                        count += 32;
                    }
                } else if (idx == IDX_TUPLE_START) {
                    // Start of dynamic type, put pointer in current slot
                    assembly {
                        mstore(add(add(ret, 36), count), free)
                    }
                    (offsetIdx, free, , i) = encodeDynamicTuple(ret, state, indices, offsets, offsetIdx, free, i);
                    unchecked {
                        count += 32;
                    }
                } else {
                    // Variable length data
                    uint256 argLen = state[idx & IDX_VALUE_MASK].length;
                    // Put a pointer in the current slot and write the data to first free slot
                    assembly {
                        mstore(add(add(ret, 36), count), free)
                    }
                    memcpy(
                        state[idx & IDX_VALUE_MASK],
                        0,
                        ret,
                        free + 4,
                        argLen
                    );
                    unchecked {
                        free += argLen;
                        count += 32;
                    }
                }
            } else {
                // Fixed length data
                bytes memory stateVar = state[idx & IDX_VALUE_MASK];
                // Write the data to current slot
                assembly {
                    mstore(add(add(ret, 36), count), mload(add(stateVar, 32)))
                }
                unchecked {
                    count += 32;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    function setupStaticVariable(
        bytes[] memory state,
        uint256 count,
        uint256 idx
    ) internal pure returns (uint256) {
        require(
            state[idx & IDX_VALUE_MASK].length == 32,
            "Static state variables must be 32 bytes"
        );
        unchecked {
            count += 32;
        }
        return count;
    }

    function setupDynamicVariable(
        bytes[] memory state,
        uint256 count,
        uint256 idx
    ) internal pure returns (uint256) {
        // Add the length of the value, rounded up to the next word boundary, plus space for pointer and length
        uint256 argLen = state[idx & IDX_VALUE_MASK].length;
        require(
            argLen % 32 == 0,
            "Dynamic state variables must be a multiple of 32 bytes"
        );
        unchecked {
            count += argLen + 32;
        }
        return count;
    }

    function setupDynamicArray(
        bytes[] memory state,
        bytes32 indices,
        uint256[] memory offsets,
        uint256 offsetIdx,
        uint256 count,
        uint256 i
    ) internal view returns (uint256[] memory, uint256, uint256, uint256) {
        // Current idx is IDX_ARRAY_START, next idx will contain the array length
        unchecked {
            ++i;
            count += 32;
        }
        uint256 idx = uint8(indices[i]);
        require(
            state[idx & IDX_VALUE_MASK].length == 32,
            "Array length must be 32 bytes"
        );
        return setupDynamicTuple(state, indices, offsets, offsetIdx, count, i);
    }

    function setupDynamicTuple(
        bytes[] memory state,
        bytes32 indices,
        uint256[] memory offsets,
        uint256 offsetIdx,
        uint256 count,
        uint256 i
    ) internal view returns (uint256[] memory, uint256, uint256, uint256) {
        uint256 idx;
        uint256 offset;
        uint256 nextOffsetIdx;
        // Progress to first index of the data and progress the next offset idx
        unchecked {
            ++i;
            nextOffsetIdx = offsetIdx + 1;
            count += 32;
        }
        while (i < 32) {
            idx = uint8(indices[i]);
            if (idx & IDX_VARIABLE_LENGTH != 0) {
                if (idx == IDX_DYNAMIC_END) {
                    offsets[offsetIdx] = offset;
                    // Return
                    return (offsets, nextOffsetIdx, count, i);
                } else if (idx == IDX_ARRAY_START) {
                    (offsets, nextOffsetIdx, count, i) = setupDynamicArray(state, indices, offsets, nextOffsetIdx, count, i);
                } else if (idx == IDX_TUPLE_START) {
                    (offsets, nextOffsetIdx, count, i) = setupDynamicTuple(state, indices, offsets, nextOffsetIdx, count, i);
                } else {
                    count = setupDynamicVariable(state, count, idx);
                }
            } else {
                count = setupStaticVariable(state, count, idx);
            }
            unchecked {
                offset += 32;
                ++i;
            }
        }
        return (offsets, nextOffsetIdx, count, i);
    }

    function encodeDynamicArray(
        bytes memory ret,
        bytes[] memory state,
        bytes32 indices,
        uint256[] memory offsets,
        uint256 offsetIdx,
        uint256 free,
        uint256 i
    ) internal view returns (uint256, uint256, uint256, uint256) {
        // Progress to array length metadata
        unchecked {
            ++i;
        }
        // Encode array length
        uint256 idx = uint8(indices[i]);
        bytes memory stateVar = state[idx & IDX_VALUE_MASK];
        assembly {
            mstore(add(add(ret, 36), free), mload(add(stateVar, 32)))
        }
        unchecked {
            free += 32;
        }
        uint256 length;
        (offsetIdx, free, length, i) = encodeDynamicTuple(ret, state, indices, offsets, offsetIdx, free, i);
        unchecked {
            length += 32; // Increase length to account for array length metadata
        }
        return (offsetIdx, free, length, i);
    }

    function encodeDynamicTuple(
        bytes memory ret,
        bytes[] memory state,
        bytes32 indices,
        uint256[] memory offsets,
        uint256 offsetIdx,
        uint256 free,
        uint256 i
    ) internal view returns (uint256, uint256, uint256, uint256) {
        uint256 idx;
        uint256 length; // The number of bytes in this tuple
        uint256 offset = offsets[offsetIdx]; // The current offset location
        uint256 pointer = offset; // The current pointer for dynamic types
        unchecked {
            offset += free; // Update the offset location
            ++offsetIdx; // Progress to next offsetIdx
            ++i; // Progress to first index of the data
        }
        while (i < 32) {
            idx = uint8(indices[i]);
            if (idx & IDX_VARIABLE_LENGTH != 0) {
                if (idx == IDX_DYNAMIC_END) {
                    return (offsetIdx, offset, length, i);
                } else if (idx == IDX_ARRAY_START) {
                    // Start of dynamic type, put pointer in current slot
                    assembly {
                        mstore(add(add(ret, 36), free), pointer)
                    }
                    uint256 argLen;
                    (offsetIdx, offset, argLen, i) = encodeDynamicArray(ret, state, indices, offsets, offsetIdx, offset, i);
                    unchecked {
                        pointer += argLen;
                        length += (argLen + 32); // data + pointer
                        free += 32;
                    }
                } else if (idx == IDX_TUPLE_START) {
                    // Start of dynamic type, put pointer in current slot
                    assembly {
                        mstore(add(add(ret, 36), free), pointer)
                    }
                    uint256 argLen;
                    (offsetIdx, offset, argLen, i) = encodeDynamicTuple(ret, state, indices, offsets, offsetIdx, offset, i);
                    unchecked {
                        pointer += argLen;
                        length += (argLen + 32); // data + pointer
                        free += 32;
                    }
                } else  {
                    // Variable length data
                    uint256 argLen = state[idx & IDX_VALUE_MASK].length;
                    // Put a pointer in the first free slot and write the data to the offset free slot
                    assembly {
                        mstore(add(add(ret, 36), free), pointer)
                    }
                    memcpy(
                        state[idx & IDX_VALUE_MASK],
                        0,
                        ret,
                        offset + 4,
                        argLen
                    );
                    unchecked {
                        offset += argLen;
                        pointer += argLen;
                        length += (argLen + 32); // data + pointer
                        free += 32;
                    }
                }
            } else {
                // Fixed length data
                bytes memory stateVar = state[idx & IDX_VALUE_MASK];
                // Write to first free slot
                assembly {
                    mstore(add(add(ret, 36), free), mload(add(stateVar, 32)))
                }
                unchecked {
                    length += 32;
                    free += 32;
                }
            }
            unchecked {
                ++i;
            }
        }
        return (offsetIdx, offset, length, i);
    }

    function writeOutputs(
        bytes[] memory state,
        bytes1 index,
        bytes memory output
    ) internal pure returns (bytes[] memory) {
        uint256 idx = uint8(index);
        if (idx == IDX_END_OF_ARGS) return state;

        if (idx & IDX_VARIABLE_LENGTH != 0) {
            if (idx == IDX_USE_STATE) {
                state = abi.decode(output, (bytes[]));
            } else {
                // Check the first field is 0x20 (because we have only a single return value)
                uint256 argPtr;
                assembly {
                    argPtr := mload(add(output, 32))
                }
                require(
                    argPtr == 32,
                    "Only one return value permitted (variable)"
                );

                assembly {
                    // Overwrite the first word of the return data with the length - 32
                    mstore(add(output, 32), sub(mload(output), 32))
                    // Insert a pointer to the return data, starting at the second word, into state
                    mstore(
                        add(add(state, 32), mul(and(idx, IDX_VALUE_MASK), 32)),
                        add(output, 32)
                    )
                }
            }
        } else {
            // Single word
            require(
                output.length == 32,
                "Only one return value permitted (static)"
            );

            state[idx & IDX_VALUE_MASK] = output;
        }

        return state;
    }

    function writeTuple(
        bytes[] memory state,
        bytes1 index,
        bytes memory output
    ) internal view {
        uint256 idx = uint8(index);
        if (idx == IDX_END_OF_ARGS) return;

        bytes memory entry = state[idx] = new bytes(output.length + 32);
        memcpy(output, 0, entry, 32, output.length);
        assembly {
            let l := mload(output)
            mstore(add(entry, 32), l)
        }
    }

    function memcpy(
        bytes memory src,
        uint256 srcIdx,
        bytes memory dest,
        uint256 destIdx,
        uint256 len
    ) internal view {
        assembly {
            pop(
                staticcall(
                    gas(),
                    4,
                    add(add(src, 32), srcIdx),
                    len,
                    add(add(dest, 32), destIdx),
                    len
                )
            )
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./CommandBuilder.sol";

abstract contract VM {
    using CommandBuilder for bytes[];

    uint256 constant FLAG_CT_DELEGATECALL = 0x00;
    uint256 constant FLAG_CT_CALL = 0x01;
    uint256 constant FLAG_CT_STATICCALL = 0x02;
    uint256 constant FLAG_CT_VALUECALL = 0x03;
    uint256 constant FLAG_CT_MASK = 0x03;
    uint256 constant FLAG_DATA = 0x20;
    uint256 constant FLAG_EXTENDED_COMMAND = 0x40;
    uint256 constant FLAG_TUPLE_RETURN = 0x80;

    uint256 constant SHORT_COMMAND_FILL =
        0x000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    error ExecutionFailed(
        uint256 command_index,
        address target,
        string message
    );

    function _execute(bytes32[] calldata commands, bytes[] memory state)
        internal
        returns (bytes[] memory)
    {
        bytes32 command;
        uint256 flags;
        bytes32 indices;

        bool success;
        bytes memory outData;

        uint256 commandsLength = commands.length;
        for (uint256 i; i < commandsLength; i = _uncheckedIncrement(i)) {
            command = commands[i];
            flags = uint256(uint8(bytes1(command << 32)));

            if (flags & FLAG_EXTENDED_COMMAND != 0) {
                i = _uncheckedIncrement(i);
                indices = commands[i];
            } else {
                indices = bytes32(uint256(command << 40) | SHORT_COMMAND_FILL);
            }

            if (flags & FLAG_CT_MASK == FLAG_CT_DELEGATECALL) {
                (success, outData) = address(uint160(uint256(command))) // target
                    .delegatecall(
                        // inputs
                        flags & FLAG_DATA == 0
                            ? state.buildInputs(
                                bytes4(command), // selector
                                indices
                            )
                            : state[
                                uint8(bytes1(indices)) &
                                CommandBuilder.IDX_VALUE_MASK
                            ]
                    );
            } else if (flags & FLAG_CT_MASK == FLAG_CT_CALL) {
                (success, outData) = address(uint160(uint256(command))).call( // target
                    // inputs
                    flags & FLAG_DATA == 0
                        ? state.buildInputs(
                            bytes4(command), // selector
                            indices
                        )
                        : state[
                            uint8(bytes1(indices)) &
                            CommandBuilder.IDX_VALUE_MASK
                        ]
                );
            } else if (flags & FLAG_CT_MASK == FLAG_CT_STATICCALL) {
                (success, outData) = address(uint160(uint256(command))) // target
                    .staticcall(
                        // inputs
                        flags & FLAG_DATA == 0
                            ? state.buildInputs(
                                bytes4(command), // selector
                                indices
                            )
                            : state[
                                uint8(bytes1(indices)) &
                                CommandBuilder.IDX_VALUE_MASK
                            ]
                    );
            } else if (flags & FLAG_CT_MASK == FLAG_CT_VALUECALL) {
                uint256 callEth;
                bytes memory v = state[uint8(bytes1(indices))];
                assembly {
                    callEth := mload(add(v, 0x20))
                }
                (success, outData) = address(uint160(uint256(command))).call{ // target
                    value: callEth
                }(
                    // inputs
                    flags & FLAG_DATA == 0
                        ? state.buildInputs(
                            bytes4(command), // selector
                            indices << 8 // skip value input
                        )
                        : state[
                            uint8(
                                bytes1(indices << 8) // first byte after value input
                            ) & CommandBuilder.IDX_VALUE_MASK
                        ]
                );
            } else {
                revert("Invalid calltype");
            }

            if (!success) {
                if (outData.length > 0) {
                    assembly {
                        outData := add(outData, 68)
                    }
                }
                revert ExecutionFailed({
                    command_index: flags & FLAG_EXTENDED_COMMAND == 0
                        ? i
                        : i - 1,
                    target: address(uint160(uint256(command))),
                    message: outData.length > 0 ? string(outData) : "Unknown"
                });
            }

            if (flags & FLAG_TUPLE_RETURN != 0) {
                state.writeTuple(bytes1(command << 88), outData);
            } else {
                state = state.writeOutputs(bytes1(command << 88), outData);
            }
        }
        return state;
    }

    function _uncheckedIncrement(uint256 i) private pure returns (uint256) {
        unchecked {
            ++i;
        }
        return i;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

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
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@ensofinance/weiroll/contracts/VM.sol";
import "./access/AccessController.sol";
import "./wallet/ERC1271.sol";
import "./wallet/MinimalWallet.sol";
import "./interfaces/IEnsoWallet.sol";

contract EnsoWallet is IEnsoWallet, VM, AccessController, ERC1271, MinimalWallet {
    using StorageAPI for bytes32;

    // Using same slot generation technique as eip-1967 -- https://eips.ethereum.org/EIPS/eip-1967
    bytes32 internal constant SALT = bytes32(uint256(keccak256("enso.wallet.salt")) - 1);

    error AlreadyInit();

    // @notice Initialize wallet by setting state and permissions
    // @dev A wallet is considered initialized if the SALT is set in state. Subsequent calls to this function will fail.
    // @param owner The address of the wallet owner
    // @param salt The salt used to deploy the proxy that uses this contract as it's implementation
    // @param shortcutId The bytes32 value representing a shortcut
    // @param commands The optional commands for executing a shortcut
    // @param state The optional state for executing a shortcut
    function initialize(
        address owner,
        bytes32 salt,
        bytes32 shortcutId,
        bytes32[] calldata commands,
        bytes[] calldata state
    ) external override payable {
        if (SALT.getBytes32() != bytes32(0)) revert AlreadyInit();
        SALT.setBytes32(salt);
        _setPermission(OWNER_ROLE, owner, true);
        _setPermission(EXECUTOR_ROLE, owner, true);
        if (commands.length != 0) {
            _executeShortcut(shortcutId, commands, state);
        }
    }

    // @notice A function to execute an arbitrary call on another contract
    // @param target The address of the target contract
    // @param value The ether value that is to be sent with the call
    // @param data The call data to be sent to the target
    function execute(
        address target,
        uint256 value,
        bytes memory data
    ) external payable isPermitted(EXECUTOR_ROLE) returns (bool success) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := call(gas(), target, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    // @notice Execute a shortcut from this contract
    // @param shortcutId The bytes32 value representing a shortcut
    // @param commands An array of bytes32 values that encode calls
    // @param state An array of bytes that are used to generate call data for each command
    function executeShortcut(
        bytes32 shortcutId,
        bytes32[] calldata commands,
        bytes[] calldata state
    )
        external
        payable
        isPermitted(EXECUTOR_ROLE)
        returns (bytes[] memory returnData)
    {
        returnData = _executeShortcut(shortcutId, commands, state);
    }

    // @notice Internal function to execute a shortcut from this contract
    // @param shortcutId The bytes32 value representing a shortcut
    // @param commands An array of bytes32 values that encode calls
    // @param state An array of bytes that are used to generate call data for each command
    function _executeShortcut(
        bytes32 shortcutId,
        bytes32[] calldata commands,
        bytes[] calldata state
    )
        internal
        returns (bytes[] memory returnData)
    {
        (shortcutId); // ShortcutId just needs to be retrieved from call data, can support events in future upgrade
        returnData = _execute(commands, state);
    }


    // @notice Internal function for checking the ERC-1271 signer
    // @param signer The address that signed a message
    function _checkSigner(address signer) internal view override returns (bool) {
        return _getPermission(OWNER_ROLE, signer);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "../libraries/StorageAPI.sol";

abstract contract ACL {
    using StorageAPI for bytes32;

    error NotPermitted();

    modifier isPermitted(bytes32 role) {
        bool permitted = _getPermission(role, msg.sender); // TODO: support GSN/Account abstraction
        if (!permitted) revert NotPermitted();
        _;
    }

    // @notice Gets user permission for a role
    // @param role The bytes32 value of the role
    // @param account The address of the account
    // @return The permission status
    function getPermission(
        bytes32 role,
        address account
    ) external view returns (bool) {
        return _getPermission(role, account);
    }

    // @notice Internal function to get user permission for a role
    // @param role The bytes32 value of the role
    // @param account The address of the account
    // @return The permission status
    function _getPermission(
        bytes32 role,
        address account
    ) internal view returns (bool) {
        bytes32 key = _getKey(role, account);
        return key.getBool();
    }

    // @notice Internal function to get the key for the storage slot
    // @param role The bytes32 value of the role
    // @param account The address of the account
    // @return The bytes32 storage slot
    function _getKey(
        bytes32 role,
        address account
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(role, account));
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "./ACL.sol";
import "./Roles.sol";

// @notice The OWNER_ROLE must be set in the importing contract's constructor or initialize function
abstract contract AccessController is ACL, Roles {
    using StorageAPI for bytes32;

    event PermissionSet(bytes32 role, address account, bool permission);

    error UnsafeSetting();

    // @notice Sets user permission over a role
    // @param role The bytes32 value of the role
    // @param account The address of the account
    // @param permission The permission status
    function setPermission(
        bytes32 role,
        address account,
        bool permission
    ) external isPermitted(OWNER_ROLE) {
        if (role == OWNER_ROLE && account == msg.sender && permission == false)
            revert UnsafeSetting();
        _setPermission(role, account, permission);
    }

    // @notice Internal function to set user permission over a role
    // @param role The bytes32 value of the role
    // @param account The address of the account
    // @param permission The permission status
    function _setPermission(
        bytes32 role,
        address account,
        bool permission
    ) internal {
        bytes32 key = _getKey(role, account);
        key.setBool(permission);
        emit PermissionSet(role, account, permission);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

abstract contract Roles {
    bytes32 public constant OWNER_ROLE = keccak256("enso.access.roles.owner");
    bytes32 public constant EXECUTOR_ROLE = keccak256("enso.access.roles.executor");
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC1271 {
    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signature
    ) external view returns (bytes4 magicValue);

    function isValidSignature(
       bytes calldata _message,
       bytes calldata _signature
    ) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IEnsoWallet {
    function initialize(
        address owner,
        bytes32 salt,
        bytes32 shortcutId,
        bytes32[] calldata commands,
        bytes[] calldata state
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library StorageAPI {
    function setBytes(bytes32 key, bytes memory data) internal {
        bytes32 slot = keccak256(abi.encodePacked(key));
        assembly {
            let length := mload(data)
            switch gt(length, 0x1F)
            case 0x00 {
                sstore(key, or(mload(add(data, 0x20)), mul(length, 2)))
            }
            case 0x01 {
                sstore(key, add(mul(length, 2), 1))
                for {let i:= 0} lt(mul(i, 0x20), length) {i := add(i, 0x01)} {
                    sstore(add(slot, i), mload(add(data, mul(add(i, 1), 0x20))))
                }
            }
        }
    }

    function setBytes32(bytes32 key, bytes32 val) internal {
        assembly {
            sstore(key, val)
        }
    }

    function setAddress(bytes32 key, address a) internal {
        assembly {
            sstore(key, a)
        }
    }

    function setUint256(bytes32 key, uint256 val) internal {
        assembly {
            sstore(key, val)
        }
    }

    function setInt256(bytes32 key, int256 val) internal {
        assembly {
            sstore(key, val)
        }
    }

    function setBool(bytes32 key, bool val) internal {
        assembly {
            sstore(key, val)
        }
    }

    function getBytes(bytes32 key) internal view returns (bytes memory data) {
        bytes32 slot = keccak256(abi.encodePacked(key));
        assembly {
            let length := sload(key)
            switch and(length, 0x01)
            case 0x00 {
                let decodedLength := div(and(length, 0xFF), 2)
                mstore(data, decodedLength)
                mstore(add(data, 0x20), and(length, not(0xFF)))
                mstore(0x40, add(data, 0x40))
            }
            case 0x01 {
                let decodedLength := div(length, 2)
                let i := 0
                mstore(data, decodedLength)
                for {} lt(mul(i, 0x20), decodedLength) {i := add(i, 0x01)} {
                    mstore(add(add(data, 0x20), mul(i, 0x20)), sload(add(slot, i)))
                }
                mstore(0x40, add(data, add(0x20, mul(i, 0x20))))
            }
        }
    }

    function getBytes32(bytes32 key) internal view returns (bytes32 val) {
        assembly {
            val := sload(key)
        }
    }

    function getAddress(bytes32 key) internal view returns (address a) {
        assembly {
            a := sload(key)
        }
    }

    function getUint256(bytes32 key) internal view returns (uint256 val) {
        assembly {
            val := sload(key)
        }
    }

    function getInt256(bytes32 key) internal view returns (int256 val) {
        assembly {
            val := sload(key)
        }
    }

    function getBool(bytes32 key) internal view returns (bool val) {
        assembly {
            val := sload(key)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IERC1271.sol";

abstract contract ERC1271 is IERC1271 {
    using ECDSA for bytes32;

    bytes4 constant internal MAGICVALUE_BYTES = 0x20c13b0b;
    bytes4 constant internal MAGICVALUE_BYTES32 = 0x1626ba7e;
    bytes4 constant internal INVALID_SIGNATURE = 0xffffffff;

    // @notice Checks for a valid signature
    // @param hash A bytes32 hash of a message
    // @param signature The signed hash of the message
    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    )
        public
        override
        view
        returns (bytes4 magicValue)
    {
        address signer = hash.recover(signature);
        magicValue = _checkSigner(signer) ? MAGICVALUE_BYTES32 : INVALID_SIGNATURE;
    }

    // @notice Checks for a valid signature
    // @param message The message that has been signed
    // @param signature The signed hash of the message
    function isValidSignature(
        bytes memory message,
        bytes memory signature
    )
        public
        override
        view
        returns (bytes4 magicValue)
    {
        address signer = ECDSA.toEthSignedMessageHash(message).recover(signature);
        magicValue = _checkSigner(signer) ? MAGICVALUE_BYTES : INVALID_SIGNATURE;
    }

    // @notice Confirm signer is permitted to sign on behalf of contract
    // @dev Abstract function to implemented by importing contract
    // @param signer The address of the message signer
    // @return Bool confirming whether signer is permitted
    function _checkSigner(address signer) internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../access/ACL.sol";
import "../access/Roles.sol";

contract MinimalWallet is ACL, Roles, ERC721Holder, ERC1155Holder {
    using SafeERC20 for IERC20;

    enum Protocol {
        ETH,
        ERC20,
        ERC721,
        ERC1155
    }

    struct TransferNote {
        Protocol protocol;
        address token;
        uint256[] ids;
        uint256[] amounts;
    }

    struct ApprovalNote {
        Protocol protocol;
        address token;
        address[] operators;
    }

    error WithdrawFailed();
    error InvalidArrayLength();

    ////////////////////////////////////////////////////
    // External functions //////////////////////////////
    ////////////////////////////////////////////////////

    // @notice Withdraw an array of assets
    // @dev Works for ETH, ERC20s, ERC721s, and ERC1155s
    // @param notes A tuple that contains the protocol id, token address, array of ids and amounts
    function withdraw(TransferNote[] memory notes) external isPermitted(OWNER_ROLE) {
        TransferNote memory note;
        Protocol protocol;
        uint256[] memory ids;
        uint256[] memory amounts;

        uint256 length = notes.length;
        for (uint256 i; i < length; ) {
            note = notes[i];
            protocol = note.protocol;
            if (protocol == Protocol.ETH) {
                amounts = note.amounts;
                if (amounts.length != 1) revert InvalidArrayLength();
                _withdrawETH(amounts[0]);
            } else if (protocol == Protocol.ERC20) {
                amounts = note.amounts;
                if (amounts.length != 1) revert InvalidArrayLength();
                _withdrawERC20(IERC20(note.token), amounts[0]);
            } else if (protocol == Protocol.ERC721) {
                ids = note.ids;
                _withdrawERC721s(IERC721(note.token), ids);
            } else if (protocol == Protocol.ERC1155) {
                ids = note.ids;
                amounts = note.amounts;
                _withdrawERC1155s(IERC1155(note.token), ids, amounts);
            }
            unchecked { ++i; }
        }
    }

    // @notice Withdraw ETH from this contract to the msg.sender
    // @param amount The amount of ETH to be withdrawn
    function withdrawETH(uint256 amount) external isPermitted(OWNER_ROLE) {
        _withdrawETH(amount);
    }

    // @notice Withdraw ERC20s
    // @param erc20s An array of erc20 addresses
    // @param amounts An array of amounts for each erc20
    function withdrawERC20s(
        IERC20[] memory erc20s,
        uint256[] memory amounts
    ) external isPermitted(OWNER_ROLE) {
        uint256 length = erc20s.length;
        if (amounts.length != length) revert InvalidArrayLength();
        for (uint256 i; i < length; ) {
            _withdrawERC20(erc20s[i], amounts[i]);
            unchecked { ++i; }
        }
    }

    // @notice Withdraw multiple ERC721 ids for a single ERC721 contract
    // @param erc721 The address of the ERC721 contract
    // @param ids An array of ids that are to be withdrawn
    function withdrawERC721s(
        IERC721 erc721,
        uint256[] memory ids
    ) external isPermitted(OWNER_ROLE) {
        _withdrawERC721s(erc721, ids);
    }

    // @notice Withdraw multiple ERC1155 ids for a single ERC1155 contract
    // @param erc1155 The address of the ERC155 contract
    // @param ids An array of ids that are to be withdrawn
    // @param amounts An array of amounts per id
    function withdrawERC1155s(
        IERC1155 erc1155,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external isPermitted(OWNER_ROLE) {
        _withdrawERC1155s(erc1155, ids, amounts);
    }

    // @notice Revoke approval on an array of assets and operators
    // @dev Works for ERC20s, ERC721s, and ERC1155s
    // @param notes A tuple that contains the protocol id, token address, and array of operators
    function revokeApprovals(ApprovalNote[] memory notes) external isPermitted(OWNER_ROLE) {
        ApprovalNote memory note;
        Protocol protocol;

        uint256 length = notes.length;
        for (uint256 i; i < length; ) {
            note = notes[i];
            protocol = note.protocol;
            if (protocol == Protocol.ERC20) {
                _revokeERC20Approvals(IERC20(note.token), note.operators);
            } else if (protocol == Protocol.ERC721) {
                _revokeERC721Approvals(IERC721(note.token), note.operators);
            } else if (protocol == Protocol.ERC1155) {
                _revokeERC1155Approvals(IERC1155(note.token), note.operators);
            }
            unchecked { ++i; }
        }
    }

    // @notice Revoke approval of an ERC20 for an array of operators
    // @param erc20 The address of the ERC20 token
    // @param operators The array of operators to have approval revoked
    function revokeERC20Approvals(
        IERC20 erc20,
        address[] memory operators
    ) external isPermitted(OWNER_ROLE) {
        _revokeERC20Approvals(erc20, operators);
    }

    // @notice Revoke approval of an ERC721 for an array of operators
    // @param erc721 The address of the ERC721 token
    // @param operators The array of operators to have approval revoked
    function revokeERC721Approvals(
        IERC721 erc721,
        address[] memory operators
    ) external isPermitted(OWNER_ROLE) {
        _revokeERC721Approvals(erc721, operators);
    }

    // @notice Revoke approval of an ERC1155 for an array of operators
    // @param erc1155 The address of the ERC1155 token
    // @param operators The array of operators to have approval revoked
    function revokeERC1155Approvals(
        IERC1155 erc1155,
        address[] memory operators
    ) external isPermitted(OWNER_ROLE) {
        _revokeERC1155Approvals(erc1155, operators);
    }

    ////////////////////////////////////////////////////
    // Internal functions //////////////////////////////
    ////////////////////////////////////////////////////

    function _withdrawETH(uint256 amount) internal {
        (bool success, ) = msg.sender.call{ value : amount }("");
        if (!success) revert WithdrawFailed();
    }

    function _withdrawERC20(
        IERC20 erc20,
        uint256 amount
    ) internal {
        erc20.safeTransfer(msg.sender, amount);
    }

    function _withdrawERC721s(
        IERC721 erc721,
        uint256[] memory ids
    ) internal {
        uint256 length = ids.length;
        for (uint256 i; i < length; ) {
            erc721.safeTransferFrom(address(this), msg.sender, ids[i]);
            unchecked { ++i; }
        }
    }

    function _withdrawERC1155s(
        IERC1155 erc1155,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        // safeBatchTransferFrom will validate the array lengths
        erc1155.safeBatchTransferFrom(address(this), msg.sender, ids, amounts, "");
    }

    function _revokeERC20Approvals(
        IERC20 erc20,
        address[] memory operators
    ) internal {
        uint256 length = operators.length;
        for (uint256 i; i < length; ) {
            erc20.safeApprove(operators[i], 0);
            unchecked { ++i; }
        }
    }

    function _revokeERC721Approvals(
        IERC721 erc721,
        address[] memory operators
    ) internal {
        uint256 length = operators.length;
        for (uint256 i; i < length; ) {
            erc721.setApprovalForAll(operators[i], false);
            unchecked { ++i; }
        }
    }

    function _revokeERC1155Approvals(
        IERC1155 erc1155,
        address[] memory operators
    ) internal {
        uint256 length = operators.length;
        for (uint256 i; i < length; ) {
            erc1155.setApprovalForAll(operators[i], false);
            unchecked { ++i; }
        }
    }

    ////////////////////////////////////////////////////
    // Fallback functions //////////////////////////////
    ////////////////////////////////////////////////////

    receive() external payable {}
}