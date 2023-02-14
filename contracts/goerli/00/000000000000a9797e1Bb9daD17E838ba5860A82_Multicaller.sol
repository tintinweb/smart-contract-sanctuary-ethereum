// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Multicaller
 * @author vectorized.eth
 * @notice Contract that allows for efficient aggregation
 *         of multiple calls in a single transaction.
 */
contract Multicaller {
    // =============================================================
    //                            EVENTS
    // =============================================================

    /**
     * @dev The lengths of the input arrays are not the same.
     */
    error ArrayLengthsMismatch();

    /**
     * @dev This function does not support reentrancy.
     */
    error Reentrancy();

    // =============================================================
    //                            STORAGE
    // =============================================================

    /**
     * @dev The storage slot for the sender and reentrancy guard flag.
     */
    bytes32 private _sender;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor() payable {
        assembly {
            sstore(_sender.slot, shl(160, 1))
        }
    }

    // =============================================================
    //                    AGGREGATION OPERATIONS
    // =============================================================

    /**
     * @dev Returns the address that called `aggregateWithSender` on this contract.
     *      The value is always the zero address outside a transaction.
     * @return The caller address.
     */
    function sender() external view returns (address) {
        assembly {
            mstore(0x00, and(sub(shl(160, 1), 1), sload(_sender.slot)))
            return(0x00, 0x20)
        }
    }

    /**
     * @dev Aggregates multiple calls in a single transaction.
     *      The `msg.value` will be forwarded to the starting call.
     *      This method will set `sender` to the `msg.sender` temporarily
     *      for the span of its execution.
     *      This method does not support reentrancy.
     * @param targets An array of addresses to call.
     * @param data    An array of calldata to forward to the targets.
     * @return An array of the returndata from each of the call.
     */
    function aggregateWithSender(address[] calldata targets, bytes[] calldata data)
        external
        payable
        returns (bytes[] memory)
    {
        assembly {
            if iszero(eq(targets.length, data.length)) {
                // Store the function selector of `ArrayLengthsMismatch()`.
                mstore(0x00, 0x3b800a46)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            if iszero(and(sload(_sender.slot), shl(160, 1))) {
                // Store the function selector of `Reentrancy()`.
                mstore(0x00, 0xab143c06)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Set the `_sender` slot temporarily for the span of this transaction.
            sstore(_sender.slot, caller())

            mstore(0x00, 0x20) // Store the memory offset of the `results`.
            mstore(0x20, data.length) // Store `data.length` into `results`.
            // Early return if no data.
            if iszero(data.length) { return(0x00, 0x40) }

            let results := 0x40
            // `shl` 5 is equivalent to multiplying by 0x20.
            let end := shl(5, data.length)
            // Copy the offsets from calldata into memory.
            calldatacopy(0x40, data.offset, end)
            // Pointer to the top of the memory (i.e. start of the free memory).
            let resultsOffset := end
            // The callvalue to forward to the starting call.
            let v := callvalue()

            for { end := add(results, end) } 1 {} {
                // The offset of the current bytes in the calldata.
                let o := add(data.offset, mload(results))
                let memPtr := add(resultsOffset, 0x40)
                // Copy the current bytes from calldata to the memory.
                calldatacopy(
                    memPtr,
                    add(o, 0x20), // The offset of the current bytes' bytes.
                    calldataload(o) // The length of the current bytes.
                )
                if iszero(
                    call(
                        gas(), // Remaining gas.
                        calldataload(targets.offset), // Address to call.
                        v, // Amount of ETH to send.
                        memPtr, // Start of input calldata in memory.
                        calldataload(o), // Size of input calldata.
                        0x00, // We will use returndatacopy instead.
                        0x00 // We will use returndatacopy instead.
                    )
                ) {
                    // Bubble up the revert if the call reverts.
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
                // We only forward the callvalue for the starting call.
                v := 0
                // Advance the `targets.offset`.
                targets.offset := add(targets.offset, 0x20)
                // Append the current `resultsOffset` into `results`.
                mstore(results, resultsOffset)
                results := add(results, 0x20)
                // Append the returndatasize, and the return data.
                mstore(memPtr, returndatasize())
                returndatacopy(add(memPtr, 0x20), 0x00, returndatasize())
                // Advance the `resultsOffset` by `returndatasize() + 0x20`,
                // rounded up to the next multiple of 32.
                resultsOffset := and(add(add(resultsOffset, returndatasize()), 0x3f), not(0x1f))
                if iszero(lt(results, end)) { break }
            }
            // Restore the `_sender` slot.
            sstore(_sender.slot, shl(160, 1))
            // Direct return.
            return(0x00, add(resultsOffset, 0x40))
        }
    }

    /**
     * @dev Aggregates multiple calls in a single transaction.
     *      The `msg.value` will be forwarded to the starting call.
     * @param targets An array of addresses to call.
     * @param data    An array of calldata to forward to the targets.
     * @return An array of the returndata from each of the call.
     */
    function aggregate(address[] calldata targets, bytes[] calldata data)
        external
        payable
        returns (bytes[] memory)
    {
        assembly {
            if iszero(eq(targets.length, data.length)) {
                // Store the function selector of `ArrayLengthsMismatch()`.
                mstore(0x00, 0x3b800a46)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x00, 0x20) // Store the memory offset of the `results`.
            mstore(0x20, data.length) // Store `data.length` into `results`.
            // Early return if no data.
            if iszero(data.length) { return(0x00, 0x40) }

            let results := 0x40
            // `shl` 5 is equivalent to multiplying by 0x20.
            let end := shl(5, data.length)
            // Copy the offsets from calldata into memory.
            calldatacopy(0x40, data.offset, end)
            // Pointer to the top of the memory (i.e. start of the free memory).
            let resultsOffset := end
            // The callvalue to forward to the starting call.
            let v := callvalue()

            for { end := add(results, end) } 1 {} {
                // The offset of the current bytes in the calldata.
                let o := add(data.offset, mload(results))
                let memPtr := add(resultsOffset, 0x40)
                // Copy the current bytes from calldata to the memory.
                calldatacopy(
                    memPtr,
                    add(o, 0x20), // The offset of the current bytes' bytes.
                    calldataload(o) // The length of the current bytes.
                )
                if iszero(
                    call(
                        gas(), // Remaining gas.
                        calldataload(targets.offset), // Address to call.
                        v, // Amount of ETH to send.
                        memPtr, // Start of input calldata in memory.
                        calldataload(o), // Size of input calldata.
                        0x00, // We will use returndatacopy instead.
                        0x00 // We will use returndatacopy instead.
                    )
                ) {
                    // Bubble up the revert if the call reverts.
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
                // We only forward the callvalue for the starting call.
                v := 0
                // Advance the `targets.offset`.
                targets.offset := add(targets.offset, 0x20)
                // Append the current `resultsOffset` into `results`.
                mstore(results, resultsOffset)
                results := add(results, 0x20)
                // Append the returndatasize, and the return data.
                mstore(memPtr, returndatasize())
                returndatacopy(add(memPtr, 0x20), 0x00, returndatasize())
                // Advance the `resultsOffset` by `returndatasize() + 0x20`,
                // rounded up to the next multiple of 32.
                resultsOffset := and(add(add(resultsOffset, returndatasize()), 0x3f), not(0x1f))
                if iszero(lt(results, end)) { break }
            }
            // Direct return.
            return(0x00, add(resultsOffset, 0x40))
        }
    }
}