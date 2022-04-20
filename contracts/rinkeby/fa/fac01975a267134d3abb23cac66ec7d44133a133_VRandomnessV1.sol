/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: MIT
// 20-04-2022

pragma solidity ^0.8.0;

contract VRandomnessV1 {
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }

    uint private randNonce = 0;
    
    function getRandomNumber(address senderAddress, uint _modulus) external returns (uint) {
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp, senderAddress, randNonce))) % _modulus;
    }

    function resetNonce() external {
        require(msg.sender == owner, "you can't call this function");
        require(randNonce != 0, "No need to reset nonce");
        randNonce = 0;
    }
}