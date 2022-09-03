/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

pragma solidity ^0.8.1;

contract checkTime{
    uint public constructorTime;
    uint public contractTime = block.timestamp;
    uint public constructorBlock;
    uint public contractBlock = block.number;

    constructor() {
        constructorTime = block.timestamp;
        constructorBlock = block.number;
    }

}