/**
 *Submitted for verification at Etherscan.io on 2023-01-24
*/

// SPDX-License-Identifier: No license
pragma solidity >=0.8.17;

contract Multicall {
    struct Call {
        address to;
        bytes data;
    }

    struct Result {
        bool success;
        bytes data;
    }

    function multicall(Call[] calldata calls) external returns (Result[] memory results) {
        results = new Result[](calls.length);
        for (uint i; i < calls.length; i++) {
            bool success;
            (success, results[i].data) = calls[i].to.call(calls[i].data);
            require(success);
            results[i].success = success;
        }
    }
}