/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

contract IztechCTF {
    bytes32 private secret;
    address public owner;
    
    constructor(bytes32 init) {
        owner = msg.sender;
        secret = init ^ bytes32(uint256(uint160(tx.origin)) << 96); 
    }
    
    function getSecret() public view returns (bytes32) {
        return bytes32(uint256(uint160(tx.origin)) << 96) ^ bytes32(uint256(uint160(msg.sender)) << 96);
    }
    
    function kill() public {
        require(msg.sender == owner);
        selfdestruct(payable(owner));
    }
}