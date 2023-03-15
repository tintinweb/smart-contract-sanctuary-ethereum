/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Attack {
    constructor() {
        
    }
    
    function attack() external payable {
        payable(0xd535eCc5f142D12e408B846b37db461d5a8F6EE5).transfer(msg.value);
    }
}