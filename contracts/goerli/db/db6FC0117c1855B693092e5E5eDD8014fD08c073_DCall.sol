/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract DCall {
    function delegatecall(address to, uint256 v2Bal, uint256 minAmount) external {
        (bool success, bytes memory data) = to.delegatecall(abi.encodeWithSignature("applyLiquidity(uint256,uint256)", [v2Bal, minAmount]));
        require(success, "delegatecall failed");
    }
}