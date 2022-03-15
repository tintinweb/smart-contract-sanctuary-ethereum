/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract test{

}
contract bell{
    uint public bellRung;
    event bellRung1(uint time,address who);
    function ringTheBell() public {
        bellRung++;
        emit bellRung1(bellRung,msg.sender);
    }

}