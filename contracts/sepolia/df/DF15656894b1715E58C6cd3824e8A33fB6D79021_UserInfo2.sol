// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserInfo2{

    address deployer;
    uint256 secretNumber;

    event setEvent(address messageSender, uint256 number);

    function setNumber(uint256 number) external{
        secretNumber = number;
        emit setEvent(msg.sender, number);
    }

    function getNumber() external view returns(uint256){
        return secretNumber;
    }
}