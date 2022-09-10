/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

pragma solidity >= 0.8.0 < 0.9.0;

contract ElevatorFun{

    bool firstFloor = false;

    function isLastFloor(uint _floor) public returns (bool){
        if(!firstFloor){
            firstFloor = true;
            return false;
        }

        return true;
    }
}