/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// pre sure this function only allows viewing 
contract MultiCall {
    function multiCall(address[] calldata targets, bytes[] calldata data)
        external
        returns (bytes[] memory)
    {
        require(targets.length == data.length, "target length != data length");

        bytes[] memory results = new bytes[](data.length);

        for (uint i; i < targets.length; i++) {
            // staticcall is for view functions
            // (remove view to send tx)
            // (bool success, bytes memory result) = targets[i].delegatecall(data[i]);
            (, bytes memory result) = targets[i].call(data[i]);
            // require(success, "call failed");
            results[i] = result;
        }

        return results;
    }
}