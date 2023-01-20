/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract VerifyPublish{
    uint number=0;
    constructor (){

    }
    function getNumber() public view returns(uint){
        return number;
    }
    function setNumber(uint _number)public{
        number=_number;
    }

}