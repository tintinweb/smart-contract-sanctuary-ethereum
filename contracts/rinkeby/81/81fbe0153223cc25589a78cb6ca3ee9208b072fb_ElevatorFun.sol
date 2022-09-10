/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// File: contracts/ElevatorInterface.sol

pragma solidity >=0.8.0 <0.9.0;

interface ElevatorInterface {
  function goTo(uint _floor) external;
}
// File: contracts/ElevatorFun.sol

pragma solidity >= 0.8.0 < 0.9.0;


contract ElevatorFun{

    bool firstFloor = false;
    address elevatorAddress = 0xf66B053BC1eC90Db355d257Ec598d83dd26C7D03;

    function goTo(uint _floor) public {
        ElevatorInterface(elevatorAddress).goTo(_floor);
    }

    function isLastFloor(uint _floor) public returns (bool){
        if(!firstFloor){
            firstFloor = true;
            return false;
        }

        return true;
    }
}