/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8;

contract testTimer {
    uint256 public lastCall;
    
    uint256 number;
    mapping(address => uint256) public balance;


    constructor () {
        lastCall = block.timestamp;
    }

    function updateBal(uint newBal) public {
      balance[msg.sender] = newBal;
    }

    
    function retrieveBal(address addy) public view returns(uint256){
        return balance[addy];
    }
    
    function beginBribeGov() public {
        lastCall = block.timestamp;
    }

    function executeBribeGov(uint256 newBal) external  {
        require(block.timestamp - lastCall > 2 minutes, 'Need to wait 2 minutes');
            updateBal(newBal);
        lastCall = block.timestamp;
    }
}