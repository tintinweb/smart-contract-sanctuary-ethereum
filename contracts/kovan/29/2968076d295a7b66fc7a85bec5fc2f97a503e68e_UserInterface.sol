/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
library UsefulLib{
    struct NUM{
        uint256 num;
    }
    function help() public view returns (uint){
        return 1;
    }

    function help2() public view returns (uint){
        return 2;
    }
}

contract UserInterface{
    UsefulLib.NUM public n;

    constructor(uint _num){
        n.num = _num;
    }

    function getHelp() public{
        UsefulLib.help();
    }

    function getHelp2() public{
        UsefulLib.help2();
    }
}