/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiCall {
    function multicall(address[] calldata addr, bytes[] calldata data)
        external
        returns (bool[] memory bools,bytes[] memory results)
    {
        require(addr.length==data.length);
        bools = new bool[](data.length);
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(addr[i]).delegatecall(
                data[i]
            );
            bools[i] = success;
            if(success) results[i] = result;
        }
    }
}