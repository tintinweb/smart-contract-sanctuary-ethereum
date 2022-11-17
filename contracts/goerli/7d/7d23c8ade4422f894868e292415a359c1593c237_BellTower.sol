/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract BellTower{
    uint public bellRung=100;

    event BellRung (uint numberOfRang, address whoRangIt);

    function ring() public{
        bellRung--;

        emit BellRung(bellRung, msg.sender);
    }
}