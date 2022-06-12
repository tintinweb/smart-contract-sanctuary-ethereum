/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8;

contract testTimer {
    uint256 lastRun;
    
     uint256 number;
    mapping(address => uint256) public balance;


    function updateBal(uint newBal) public {
      balance[msg.sender] = newBal;
    }

    
    function retrieveBal(address addy) public view returns(uint256){
        return balance[addy];
    }


    function updateBalTimer(uint256 help) external {
        require(block.timestamp - lastRun > 1 minutes, 'Need to wait 1 minutes');
        this.updateBal(help);
        lastRun = block.timestamp;
    }

    function updateBalTimerHr(uint256 help) external {
        require(block.timestamp - lastRun > 1 hours, 'Need to wait 1 hour');
        this.updateBal(help);
        lastRun = block.timestamp;
    }
}