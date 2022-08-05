/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiStaticCall {
    function staticCall(address[] calldata addr, bytes[] calldata data)
        external
        view
        returns (bool[] memory bools,bytes[] memory results)
    {
        require(addr.length==data.length);
        bools = new bool[](data.length);
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(addr[i]).staticcall(
                data[i]
            );
            bools[i] = success;
            if(success) results[i] = result;
        }
    }
}