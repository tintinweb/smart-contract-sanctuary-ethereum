/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract AggregationCall {
    // call struct
    struct Call {
        address target;
        bytes callData;
    }

    // call result
    struct Result {
        bool success;
        bytes returnData;
    }

    /**
     * @notice Perform aggregation call.
     */
    function aggregateCall(bool requireSuccess, Call[] memory calls)
        public
        returns (uint256 blockNumber, Result[] memory results)
    {
        blockNumber = block.number;
        results = new Result[](calls.length);

        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory returnData) = calls[i].target.call(
                calls[i].callData
            );

            if (requireSuccess) {
                require(success, "call failed");
            }

            results[i] = Result(success, returnData);
        }
    }
}