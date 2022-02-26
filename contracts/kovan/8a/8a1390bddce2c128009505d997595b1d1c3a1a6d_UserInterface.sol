/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
library UsefulLib{
    struct NUM{
        uint256 num;
    }
    function help(NUM storage n) public view returns (uint){
        return n.num + 1;
    }
}

contract UserInterface{
    UsefulLib.NUM public n;

    constructor(uint _num){
        n.num = _num;
    }

    function getHelp() public{
        UsefulLib.help(n);
    }
}