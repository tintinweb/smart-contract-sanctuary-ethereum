/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Avengers {

    event AvengersTransferred(string from, string to, uint256 amount);

    struct Transfer{
        string from;
        string to;
        uint256 amount;
    }

    function log(Transfer[] memory transfers) public {
        for(uint256 i = 0; i < transfers.length; i++) {
            emit AvengersTransferred(transfers[i].from, transfers[i].to, transfers[i].amount);
        }
    }


}