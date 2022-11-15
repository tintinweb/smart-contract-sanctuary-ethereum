/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// File: question8.sol

pragma solidity ^0.6.0;
contract increment{
    uint Counter;
    constructor() public{
        Counter=0;
    }

    function getContract() public view returns(uint){
        return Counter;
    }
    function incrementCount() public{
        Counter=Counter+1;
    }
}