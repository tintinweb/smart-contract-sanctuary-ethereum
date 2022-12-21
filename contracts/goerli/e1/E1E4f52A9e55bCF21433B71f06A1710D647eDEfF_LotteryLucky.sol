/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract LotteryLucky {
    address participator;
    uint256  number;

    function enter(uint256 luckyNumber) public {
        number = luckyNumber;
        participator = msg.sender;
    }

    function reveal() public view returns(uint256, address){
        return (number, participator);
    }
    
}