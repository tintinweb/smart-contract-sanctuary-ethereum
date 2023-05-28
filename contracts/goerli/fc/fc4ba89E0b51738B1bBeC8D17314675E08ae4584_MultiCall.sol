/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiCall {
    function callFunctions(address[] memory targets, bytes[] memory functionData) external payable {
        require(targets.length == functionData.length, "Arrays length mismatch");
        
        for (uint i = 0; i < targets.length; i++) {
            // Gọi hàm trên mỗi đích với dữ liệu tương ứng
            (bool success, ) = targets[i].call{value: msg.value}(functionData[i]);
            
            require(success, "Function call failed");
        }
    }
}