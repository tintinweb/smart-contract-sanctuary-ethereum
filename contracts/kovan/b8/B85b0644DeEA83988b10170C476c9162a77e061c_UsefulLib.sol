/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
library UsefulLib{
    struct NUM{
        uint256 num;
    }
    function help(NUM storage n) external returns (uint){
        n.num = 100;

        return n.num;
    }
}