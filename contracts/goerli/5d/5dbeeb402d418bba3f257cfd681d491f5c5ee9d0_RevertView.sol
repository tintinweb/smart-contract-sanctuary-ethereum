/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

contract RevertView{
    uint8 oneNumber = 1;
    uint8 secondNumber = 2;

    function setNumberOne(uint8 number) public {
        oneNumber = number;
    }

    function canDeposit() public view returns (bool dep){
        require(oneNumber > secondNumber, "expected revert");
        return true;
    }
}