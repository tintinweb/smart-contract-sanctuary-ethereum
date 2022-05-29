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

    function call (Call[] memory requests) external view returns (bytes[] memory) {
        bytes[] memory results = new bytes[](requests.length);
        for (uint i = 0; i < requests.length; i++) {
            Call memory request = requests[i];
            (bool success, bytes memory result) = request.contractAddress.staticcall(request.payload);
            require(success);
            results[i] = result;
        }
        return results;
    }

    function call (bytes[] calldata requests) external view returns (bytes[] memory) {
        bytes[] memory results = new bytes[](requests.length);
        for (uint i = 0; i < requests.length; i++) {
            bytes calldata request = requests[i];
            require(request.length >= 20);
            address contractAddress = address(bytes20(request[0:20]));
            bytes calldata payload = request[20:];
            (bool success, bytes memory result) = contractAddress.staticcall(payload);
            require(success);
            results[i] = result;
        }
        return results;
    }
}