// SPDX-License-Identifier: GPL-3.0-only

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
        bytes32 indices,
        uint256 indicesLength
    ) internal view returns (bytes memory ret) {
        uint256 idx; // The current command index
        uint256 offsetIdx; // The index of the current free offset

        uint256 count; // Number of bytes in whole ABI encoded message
        uint256 free; // Pointer to first free byte in tail part of message
        uint256[] memory dynamicLengths = new uint256[](10); // Optionally store the length of all dynamic types (a command cannot fit more than 10 dynamic types)

        bytes memory stateData; // Optionally encode the current state if the call requires it

        // Determine the length of the encoded data
        for (uint256 i; i < indicesLength; ) {
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
                } else {
                    (dynamicLengths, offsetIdx, count, i) = setupDynamicType(
                        state,
                        indices,
                        dynamicLengths,
                        idx,
                        offsetIdx,
                        count,
                        i
                    );
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
        offsetIdx = 0;
        // Use count to track current memory slot
        assembly {
            count := add(ret, 36)
        }
        for (uint256 i; i < indicesLength; ) {
            idx = uint8(indices[i]);
            if (idx & IDX_VARIABLE_LENGTH != 0) {
                if (idx == IDX_USE_STATE) {
                    assembly {
                        mstore(count, free)
                    }
                    memcpy(stateData, 32, ret, free + 4, stateData.length - 32);
                    unchecked {
                        free += stateData.length - 32;
                    }
                } else if (idx == IDX_ARRAY_START) {
                    // Start of dynamic type, put pointer in current slot
                    assembly {
                        mstore(count, free)
                    }
                    (offsetIdx, free, i, ) = encodeDynamicArray(
                        ret,
                        state,
                        indices,
                        dynamicLengths,
                        offsetIdx,
                        free,
                        i
                    );
                } else if (idx == IDX_TUPLE_START) {
                    // Start of dynamic type, put pointer in current slot
                    assembly {
                        mstore(count, free)
                    }
                    (offsetIdx, free, i, ) = encodeDynamicTuple(
                        ret,
                        state,
                        indices,
                        dynamicLengths,
                        offsetIdx,
                        free,
                        i
                    );
                } else {
                    // Variable length data
                    uint256 argLen = state[idx & IDX_VALUE_MASK].length;
                    // Put a pointer in the current slot and write the data to first free slot
                    assembly {
                        mstore(count, free)
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
                    }
                }
            } else {
                // Fixed length data (length previously checked to be 32 bytes)
                bytes memory stateVar = state[idx & IDX_VALUE_MASK];
                // Write the data to current slot
                assembly {
                    mstore(count, mload(add(stateVar, 32)))
                }
            }
            unchecked {
                count += 32;
                ++i;
            }
        }
    }

    function setupStaticVariable(
        bytes[] memory state,
        uint256 count,
        uint256 idx
    ) internal pure returns (uint256 newCount) {
        require(
            state[idx & IDX_VALUE_MASK].length == 32,
            "Static state variables must be 32 bytes"
        );
        unchecked {
            newCount = count + 32;
        }
    }

    function setupDynamicVariable(
        bytes[] memory state,
        uint256 count,
        uint256 idx
    ) internal pure returns (uint256 newCount) {
        bytes memory arg = state[idx & IDX_VALUE_MASK];
        // Validate the length of the data in state is a multiple of 32
        uint256 argLen = arg.length;
        require(
            argLen != 0 && argLen % 32 == 0,
            "Dynamic state variables must be a multiple of 32 bytes"
        );
        // Add the length of the value, rounded up to the next word boundary, plus space for pointer
        unchecked {
            newCount = count + argLen + 32;
        }
    }

    function setupDynamicType(
        bytes[] memory state,
        bytes32 indices,
        uint256[] memory dynamicLengths,
        uint256 idx,
        uint256 offsetIdx,
        uint256 count,
        uint256 index
    ) internal view returns (
        uint256[] memory newDynamicLengths,
        uint256 newOffsetIdx,
        uint256 newCount,
        uint256 newIndex
    ) {
        if (idx == IDX_ARRAY_START) {
            (newDynamicLengths, newOffsetIdx, newCount, newIndex) = setupDynamicArray(
                state,
                indices,
                dynamicLengths,
                offsetIdx,
                count,
                index
            );
        } else if (idx == IDX_TUPLE_START) {
            (newDynamicLengths, newOffsetIdx, newCount, newIndex) = setupDynamicTuple(
                state,
                indices,
                dynamicLengths,
                offsetIdx,
                count,
                index
            );
        } else {
            newDynamicLengths = dynamicLengths;
            newOffsetIdx = offsetIdx;
            newIndex = index;
            newCount = setupDynamicVariable(state, count, idx);
        }
    }

    function setupDynamicArray(
        bytes[] memory state,
        bytes32 indices,
        uint256[] memory dynamicLengths,
        uint256 offsetIdx,
        uint256 count,
        uint256 index
    ) internal view returns (
        uint256[] memory newDynamicLengths,
        uint256 newOffsetIdx,
        uint256 newCount,
        uint256 newIndex
    ) {
        // Current idx is IDX_ARRAY_START, next idx will contain the array length
        unchecked {
            newIndex = index + 1;
            newCount = count + 32;
        }
        uint256 idx = uint8(indices[newIndex]);
        require(
            state[idx & IDX_VALUE_MASK].length == 32,
            "Array length must be 32 bytes"
        );
        (newDynamicLengths, newOffsetIdx, newCount, newIndex) = setupDynamicTuple(
            state,
            indices,
            dynamicLengths,
            offsetIdx,
            newCount,
            newIndex
        );
    }

    function setupDynamicTuple(
        bytes[] memory state,
        bytes32 indices,
        uint256[] memory dynamicLengths,
        uint256 offsetIdx,
        uint256 count,
        uint256 index
    ) internal view returns (
        uint256[] memory newDynamicLengths,
        uint256 newOffsetIdx,
        uint256 newCount,
        uint256 newIndex
    ) {
        uint256 idx;
        uint256 offset;
        newDynamicLengths = dynamicLengths;
        // Progress to first index of the data and progress the next offset idx
        unchecked {
            newIndex = index + 1;
            newOffsetIdx = offsetIdx + 1;
            newCount = count + 32;
        }
        while (newIndex < 32) {
            idx = uint8(indices[newIndex]);
            if (idx & IDX_VARIABLE_LENGTH != 0) {
                if (idx == IDX_DYNAMIC_END) {
                    newDynamicLengths[offsetIdx] = offset;
                    // explicit return saves gas ¯\_(ツ)_/¯
                    return (newDynamicLengths, newOffsetIdx, newCount, newIndex);
                } else {
                    require(idx != IDX_USE_STATE, "Cannot use state from inside dynamic type");
                    (newDynamicLengths, newOffsetIdx, newCount, newIndex) = setupDynamicType(
                        state,
                        indices,
                        newDynamicLengths,
                        idx,
                        newOffsetIdx,
                        newCount,
                        newIndex
                    );
                }
            } else {
                newCount = setupStaticVariable(state, newCount, idx);
            }
            unchecked {
                offset += 32;
                ++newIndex;
            }
        }
        revert("Dynamic type was not properly closed");
    }

    function encodeDynamicArray(
        bytes memory ret,
        bytes[] memory state,
        bytes32 indices,
        uint256[] memory dynamicLengths,
        uint256 offsetIdx,
        uint256 currentSlot,
        uint256 index
    ) internal view returns (
        uint256 newOffsetIdx,
        uint256 newSlot,
        uint256 newIndex,
        uint256 length
    ) {
        // Progress to array length metadata
        unchecked {
            newIndex = index + 1;
            newSlot = currentSlot + 32;
        }
        // Encode array length
        uint256 idx = uint8(indices[newIndex]);
        // Array length value previously checked to be 32 bytes
        bytes memory stateVar = state[idx & IDX_VALUE_MASK];
        assembly {
            mstore(add(add(ret, 36), currentSlot), mload(add(stateVar, 32)))
        }
        (newOffsetIdx, newSlot, newIndex, length) = encodeDynamicTuple(
            ret,
            state,
            indices,
            dynamicLengths,
            offsetIdx,
            newSlot,
            newIndex
        );
        unchecked {
            length += 32; // Increase length to account for array length metadata
        }
    }

    function encodeDynamicTuple(
        bytes memory ret,
        bytes[] memory state,
        bytes32 indices,
        uint256[] memory dynamicLengths,
        uint256 offsetIdx,
        uint256 currentSlot,
        uint256 index
    ) internal view returns (
        uint256 newOffsetIdx,
        uint256 newSlot,
        uint256 newIndex,
        uint256 length
    ) {
        uint256 idx;
        uint256 argLen;
        uint256 freePointer = dynamicLengths[offsetIdx]; // The pointer to the next free slot
        unchecked {
            newSlot = currentSlot + freePointer; // Update the next slot
            newOffsetIdx = offsetIdx + 1; // Progress to next offsetIdx
            newIndex = index + 1; // Progress to first index of the data
        }
        // Shift currentSlot to correct location in memory
        assembly {
            currentSlot := add(add(ret, 36), currentSlot)
        }
        while (newIndex < 32) {
            idx = uint8(indices[newIndex]);
            if (idx & IDX_VARIABLE_LENGTH != 0) {
                if (idx == IDX_DYNAMIC_END) {
                    break;
                } else if (idx == IDX_ARRAY_START) {
                    // Start of dynamic type, put pointer in current slot
                    assembly {
                        mstore(currentSlot, freePointer)
                    }
                    (newOffsetIdx, newSlot, newIndex, argLen) = encodeDynamicArray(
                        ret,
                        state,
                        indices,
                        dynamicLengths,
                        newOffsetIdx,
                        newSlot,
                        newIndex
                    );
                    unchecked {
                        freePointer += argLen;
                        length += (argLen + 32); // data + pointer
                    }
                } else if (idx == IDX_TUPLE_START) {
                    // Start of dynamic type, put pointer in current slot
                    assembly {
                        mstore(currentSlot, freePointer)
                    }
                    (newOffsetIdx, newSlot, newIndex, argLen) = encodeDynamicTuple(
                        ret,
                        state,
                        indices,
                        dynamicLengths,
                        newOffsetIdx,
                        newSlot,
                        newIndex
                    );
                    unchecked {
                        freePointer += argLen;
                        length += (argLen + 32); // data + pointer
                    }
                } else  {
                    // Variable length data
                    argLen = state[idx & IDX_VALUE_MASK].length;
                    // Start of dynamic type, put pointer in current slot
                    assembly {
                        mstore(currentSlot, freePointer)
                    }
                    memcpy(
                        state[idx & IDX_VALUE_MASK],
                        0,
                        ret,
                        newSlot + 4,
                        argLen
                    );
                    unchecked {
                        newSlot += argLen;
                        freePointer += argLen;
                        length += (argLen + 32); // data + pointer
                    }
                }
            } else {
                // Fixed length data (length previously checked to be 32 bytes)
                bytes memory stateVar = state[idx & IDX_VALUE_MASK];
                // Write to first free slot
                assembly {
                    mstore(currentSlot, mload(add(stateVar, 32)))
                }
                unchecked {
                    length += 32;
                }
            }
            unchecked {
                currentSlot += 32;
                ++newIndex;
            }
        }
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
                require(idx & IDX_VALUE_MASK < state.length, "Index out-of-bounds");
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
            require(idx & IDX_VALUE_MASK < state.length, "Index out-of-bounds");
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

        bytes memory entry = state[idx & IDX_VALUE_MASK] = new bytes(output.length + 32);
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.16;

import "./CommandBuilder.sol";

abstract contract VM {
    using CommandBuilder for bytes[];

    uint256 constant FLAG_CT_DELEGATECALL = 0x00; // Delegate call not currently supported
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
        uint256 indicesLength;
        for (uint256 i; i < commandsLength; i = _uncheckedIncrement(i)) {
            command = commands[i];
            flags = uint256(uint8(bytes1(command << 32)));

            if (flags & FLAG_EXTENDED_COMMAND != 0) {
                i = _uncheckedIncrement(i);
                indices = commands[i];
                indicesLength = 32;
            } else {
                indices = bytes32(uint256(command << 40) | SHORT_COMMAND_FILL);
                indicesLength = 6;
            }

            if (flags & FLAG_CT_MASK == FLAG_CT_CALL) {
                (success, outData) = address(uint160(uint256(command))).call( // target
                    // inputs
                    flags & FLAG_DATA == 0
                        ? state.buildInputs(
                            bytes4(command), // selector
                            indices,
                            indicesLength
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
                                indices,
                                indicesLength
                            )
                            : state[
                                uint8(bytes1(indices)) &
                                CommandBuilder.IDX_VALUE_MASK
                            ]
                    );
            } else if (flags & FLAG_CT_MASK == FLAG_CT_VALUECALL) {
                bytes memory v = state[
                    uint8(bytes1(indices)) &
                    CommandBuilder.IDX_VALUE_MASK
                ];
                require(v.length == 32, "Value must be 32 bytes");
                uint256 callEth = uint256(bytes32(v));
                (success, outData) = address(uint160(uint256(command))).call{ // target
                    value: callEth
                }(
                    // inputs
                    flags & FLAG_DATA == 0
                        ? state.buildInputs(
                            bytes4(command), // selector
                            indices << 8, // skip value input
                            indicesLength - 1 // max indices length reduced by value input
                        )
                        : state[
                            uint8(bytes1(indices << 8)) & // first byte after value input
                            CommandBuilder.IDX_VALUE_MASK
                        ]
                );
            } else {
                revert("Invalid calltype");
            }

            if (!success) {
                string memory message = "Unknown";
                if (outData.length > 68) {
                    // This might be an error message, parse the outData
                    // Estimate the bytes length of the possible error message
                    uint256 estimatedLength = _estimateBytesLength(outData, 68);
                    // Remove selector. First 32 bytes should be a pointer that indicates the start of data in memory
                    assembly {
                        outData := add(outData, 4)
                    }
                    uint256 pointer = uint256(bytes32(outData));
                    if (pointer == 32) {
                        // Remove pointer. If it is a string, the next 32 bytes will hold the size
                        assembly {
                            outData := add(outData, 32)
                        }
                        uint256 size = uint256(bytes32(outData));
                        // If the size variable is the same as the estimated bytes length, we can be fairly certain
                        // this is a dynamic string, so convert the bytes to a string and emit the message. While an
                        // error function with 3 static parameters is capable of producing a similar output, there is
                        // low risk of a contract unintentionally emitting a message.
                        if (size == estimatedLength) {
                            // Remove size. The remaining data should be the string content
                            assembly {
                                outData := add(outData, 32)
                            }
                            message = string(outData);
                        }
                    }
                }
                revert ExecutionFailed({
                    command_index: flags & FLAG_EXTENDED_COMMAND == 0
                        ? i
                        : i - 1,
                    target: address(uint160(uint256(command))),
                    message: message
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

    function _estimateBytesLength(bytes memory data, uint256 pos) internal pure returns (uint256 estimate) {
        uint256 length = data.length;
        estimate = length - pos; // Assume length equals alloted space
        for (uint256 i = pos; i < length; ) {
            if (data[i] == 0) {
                // Zero bytes found, adjust estimated length
                estimate = i - pos;
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    function _uncheckedIncrement(uint256 i) private pure returns (uint256) {
        unchecked {
            ++i;
        }
        return i;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.17;

import {VM} from "enso-weiroll/VM.sol";

contract SafeEnsoShortcuts is VM {
    address private immutable __self = address(this);

    event ShortcutExecuted(bytes32 shortcutId);

    error OnlyDelegateCall();

    // @notice Execute a shortcut via delegate call
    // @param shortcutId The bytes32 value representing a shortcut
    // @param commands An array of bytes32 values that encode calls
    // @param state An array of bytes that are used to generate call data for each command
    function executeShortcut(
        bytes32 shortcutId,
        bytes32[] calldata commands,
        bytes[] calldata state
    ) external payable returns (bytes[] memory returnData) {
        if (address(this) == __self) revert OnlyDelegateCall();
        returnData = _execute(commands, state);
        emit ShortcutExecuted(shortcutId);
    }
}