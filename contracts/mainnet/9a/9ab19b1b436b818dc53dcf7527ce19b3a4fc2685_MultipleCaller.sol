/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract MultipleCaller {

    struct Call { 
        address contractAddress;
        bytes payload;
    }

    function call (Call[] memory calls) external view returns (bytes[] memory) {
        bytes[] memory results = new bytes[](calls.length);
        for (uint i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(calls[i].contractAddress).staticcall(calls[i].payload);
            require(success);
            results[i] = result;
        }
        return results;
    }

    function call (bytes[] calldata calls) external view returns (bytes[] memory) {
        bytes[] memory results = new bytes[](calls.length);
        for (uint i = 0; i < calls.length; i++) {
            require(calls[i].length >= 20);
            address contractAddress = address(bytes20(calls[i][0:20]));
            bytes calldata payload = calls[i][20:];
            (bool success, bytes memory result) = address(contractAddress).staticcall(payload);
            require(success);
            results[i] = result;
        }
        return results;
    }
}