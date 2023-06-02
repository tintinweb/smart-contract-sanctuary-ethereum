/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ProxyContract {
    function callAttempt(address target) external {
        (bool success, ) = target.call(abi.encodeWithSignature("attempt()"));
        require(success, "External call failed");
    }
}