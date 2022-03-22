/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.13;

contract BubbleUpError {
    error PRBProxy__ExecutionReverted();

    event Execute(address indexed target, bytes data, bytes response);

    function execute(address target_, bytes memory data_) public returns (bytes memory response) {
        bool success;
        (success, response) = target_.delegatecall(data_);

        //
        emit Execute(target_, data_, response);

        // If there is return data, the call reverted with a reason or a custom error.
        if (response.length > 0) {
            assembly {
                let returndata_size := mload(response)
                revert(add(32, response), returndata_size)
            }
        } else {
            revert PRBProxy__ExecutionReverted();
        }
    }
}