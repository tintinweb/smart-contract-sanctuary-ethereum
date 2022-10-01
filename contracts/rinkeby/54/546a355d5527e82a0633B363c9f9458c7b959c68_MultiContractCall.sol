//  SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract MultiContractCall {
    function multicall(address[] calldata contracts, bytes[] calldata data) external payable returns (bool[] memory successes, bytes[] memory results) {
        successes = new bool[](data.length);
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = contracts[i].call(data[i]);
            successes[i] = success;
            results[i] = result;
        }
    }
}