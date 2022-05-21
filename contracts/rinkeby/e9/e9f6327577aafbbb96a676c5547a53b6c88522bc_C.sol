/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity >= 0.7.0 < 0.9.0;


contract C {
    uint private data;
    uint public info;
    
    constructor() public{
        info = 10;
    }
    
    function increament (uint a) pure private returns(uint){
        return a + 1;
    }
    
    function dupdateData(uint a) public{
        data = a;
    }
    
    
    function getData () view public returns(uint){
        return data;
    }
    
    function compute (uint a, uint b) view internal returns(uint){
        return a + b;
    }
}

contract D {
    
    C c = new C();
    
    function readInfo() public view {
        c.info;
    }
    
}

contract E {
    
    
    
}