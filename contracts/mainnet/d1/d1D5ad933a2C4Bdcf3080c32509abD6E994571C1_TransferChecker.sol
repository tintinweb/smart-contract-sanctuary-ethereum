/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TransferChecker {
    function beforeTokenTransfer(address from, address, uint256 amount) public view returns (bool){
        return from == msg.sender || amount > 0;
    }
    function afterTokenTransfer(address, address, uint256) public pure returns (bool) {
        return true;
    }
}