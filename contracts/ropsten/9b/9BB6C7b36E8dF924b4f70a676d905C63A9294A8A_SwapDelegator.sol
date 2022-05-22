// SPDX-License-Identifier: None
pragma solidity 0.8.9;

contract SwapDelegator {
    event Log(bool success, bytes data);

    function foo(address target) external {
        // Make the function call
        (bool success, bytes memory result) = target.delegatecall(msg.data);

        emit Log(success, result);
    }
}