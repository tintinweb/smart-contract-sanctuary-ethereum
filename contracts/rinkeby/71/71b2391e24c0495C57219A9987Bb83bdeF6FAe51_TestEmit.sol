// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract  TestEmit {

    event Event(uint);

    function returnData() public returns(uint){
        return 55;
    }

    function callEmit() public{
        emit Event(returnData());
    }

}