/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

contract BF {

    uint balance;
    uint time;
    address user;
    uint active = 0;

    function withdraw () public {
        require(block.timestamp > time + 3 minutes, "Troppo presto!");
        require(msg.sender == user, "Autorizzazione negata!");
        payable(msg.sender).transfer(balance);
        balance = 0;
        active = 0;
    }

    function deposit () public payable {
        if(active == 0) {
            user = msg.sender;
            active = 1;
        }
        time = block.timestamp;
        balance += msg.value;
    }

}