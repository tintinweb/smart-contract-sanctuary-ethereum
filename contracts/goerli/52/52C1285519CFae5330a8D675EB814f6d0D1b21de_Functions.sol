/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Functions{
    int public number;
    address payable public owner;
    constructor() {
        owner = payable(msg.sender);
    }
    function inc(int x) public returns(int)  {
        require (x !=5);
        number+=x;
        emit Event(x, number);
        return number;
    }
    function dec(int y )public returns(int){
        require(y!=0);
        number-=y;
        emit Event(y,number);
        return number;
    }

    event Event (int x, int indexed number); //indexed max 3
 
}