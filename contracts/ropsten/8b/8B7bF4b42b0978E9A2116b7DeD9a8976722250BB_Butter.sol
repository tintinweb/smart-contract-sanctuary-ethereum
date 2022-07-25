/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
contract Peanut{
    event PeanutLog(string message);

    function log() external{
        emit PeanutLog("Peanut Log....");
    }
}


contract Butter {
    Peanut p;
    constructor(address _peanut){
        p = Peanut(_peanut);
    }

    function callPeanutLog() external{
        p.log();
    }
}