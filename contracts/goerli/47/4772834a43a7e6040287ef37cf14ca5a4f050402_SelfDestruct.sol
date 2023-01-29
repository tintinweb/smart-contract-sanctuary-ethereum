/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SelfDestruct {
    function selfDestruct(address payable transferAddress) external {
        selfdestruct(transferAddress);
    }

    receive() external payable { }
}