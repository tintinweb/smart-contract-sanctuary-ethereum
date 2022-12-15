/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// SPDX - License-Indentifier:Mit 

pragma solidity ^0.8.15;


contract Challange { 

    address[] winners;
    bool lock; 

    function exploitMe (address winner) public { 
        lock = false; 

        msg.sender.call("");

        require(lock, "are locked!");
        winners.push(winner);
    }   

    function unlock () public { 
        lock = true;
    }

}