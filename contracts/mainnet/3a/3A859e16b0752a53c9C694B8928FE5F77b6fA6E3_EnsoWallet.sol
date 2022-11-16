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
pragma solidity ^0.8.16;

import {VM} from "@ensofinance/weiroll/contracts/VM.sol";

contract EnsoWallet is VM {
    address public caller;
    bool public initialized;

    // Already initialized
    error AlreadyInit();
    // Not caller
    error NotCaller();
    // Invalid address
    error InvalidAddress();

    function initialize(
        address caller_,
        bytes32[] calldata commands,
        bytes[] calldata state
    ) external payable {
        if (initialized) revert AlreadyInit();
        caller = caller_;
        if (commands.length != 0) {
            _execute(commands, state);
        }
    }

    function execute(bytes32[] calldata commands, bytes[] calldata state)
        external
        payable
        returns (bytes[] memory returnData)
    {
        if (msg.sender != caller) revert NotCaller();
        returnData = _execute(commands, state);
    }

    receive() external payable {}
}