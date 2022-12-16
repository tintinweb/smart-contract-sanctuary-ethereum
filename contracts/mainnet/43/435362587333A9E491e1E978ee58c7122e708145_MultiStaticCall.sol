// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title MultiStaticCall - Aggregate results from multiple static calls
/// @dev Derived from https://github.com/makerdao/multicall (MIT licence)
contract MultiStaticCall {
    struct Call {
        address target;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    /// @notice Aggregates the results of multiple static calls.
    /// @dev Reverts if `requireSuccess` is true and one of the static calls fails.
    /// @param requireSuccess Whether a failed static call should trigger a revert.
    /// @param calls The list of target contracts and encoded function calls for each static call.
    /// @return returnData The list of success flags and raw return data for each static call.
    function tryAggregate(bool requireSuccess, Call[] calldata calls) public view returns (Result[] memory returnData) {
        uint256 length = calls.length;
        returnData = new Result[](length);
        unchecked {
            for (uint256 i; i != length; ++i) {
                (bool success, bytes memory ret) = calls[i].target.staticcall(calls[i].callData);

                if (requireSuccess) {
                    require(success, "MultiStaticCall: call failed");
                }

                returnData[i] = Result(success, ret);
            }
        }
    }

    /// @notice Aggregates the results of multiple static calls, together with the associated block number.
    /// @dev Warning: Do not use this function as part of a transaction: `blockNumber` would not be meaningful due to transactions ordering.
    /// @dev Reverts if `requireSuccess` is true and one of the static calls fails.
    /// @param requireSuccess Whether a failed static call should trigger a revert.
    /// @param calls The list of target contracts and encoded function calls for each static call.
    /// @return blockNumber The latest mined block number indicating at which point the return data is valid.
    /// @return returnData The list of success flags and raw return data for each static call.
    function tryBlockAndAggregate(bool requireSuccess, Call[] calldata calls) public view returns (uint256 blockNumber, Result[] memory returnData) {
        blockNumber = block.number;
        returnData = tryAggregate(requireSuccess, calls);
    }
}