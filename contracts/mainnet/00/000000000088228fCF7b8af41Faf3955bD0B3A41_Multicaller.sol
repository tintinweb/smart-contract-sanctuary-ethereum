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
    //                            ERRORS
    // =============================================================

    /**
     * @dev The lengths of the input arrays are not the same.
     */
    error ArrayLengthsMismatch();

    // =============================================================
    //                    AGGREGATION OPERATIONS
    // =============================================================

    /**
     * @dev Aggregates multiple calls in a single transaction.
     * @param targets An array of addresses to call.
     * @param data    An array of calldata to forward to the targets.
     * @param values  How much ETH to forward to each target.
     * @return An array of the returndata from each call.
     */
    function aggregate(address[] calldata targets, bytes[] calldata data, uint256[] calldata values)
        external
        payable
        returns (bytes[] memory)
    {
        assembly {
            if iszero(and(eq(targets.length, data.length), eq(data.length, values.length))) {
                // Store the function selector of `ArrayLengthsMismatch()`.
                mstore(returndatasize(), 0x3b800a46)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(returndatasize(), 0x20) // Store the memory offset of the `results`.
            mstore(0x20, data.length) // Store `data.length` into `results`.
            // Early return if no data.
            if iszero(data.length) { return(returndatasize(), 0x40) }

            let results := 0x40
            // Left shift by 5 is equivalent to multiplying by 0x20.
            data.length := shl(5, data.length)
            // Copy the offsets from calldata into memory.
            calldatacopy(results, data.offset, data.length)
            // Offset into `results`.
            let resultsOffset := data.length
            // Pointer to the end of `results`.
            // Recycle `data.length` to avoid stack too deep.
            data.length := add(results, data.length)

            for {} 1 {} {
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
                        calldataload(values.offset), // ETH to send.
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
                // Advance the `targets.offset`.
                targets.offset := add(targets.offset, 0x20)
                // Advance the `values.offset`.
                values.offset := add(values.offset, 0x20)
                // Append the current `resultsOffset` into `results`.
                mstore(results, resultsOffset)
                results := add(results, 0x20)
                // Append the returndatasize, and the returndata.
                mstore(memPtr, returndatasize())
                returndatacopy(add(memPtr, 0x20), 0x00, returndatasize())
                // Advance the `resultsOffset` by `returndatasize() + 0x20`,
                // rounded up to the next multiple of 0x20.
                resultsOffset := and(add(add(resultsOffset, returndatasize()), 0x3f), not(0x1f))
                if iszero(lt(results, data.length)) { break }
            }
            // Direct return.
            return(0x00, add(resultsOffset, 0x40))
        }
    }
}