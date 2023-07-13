// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserInfo4{

    address deployer;
    uint256 secretNumber;

    event tempEvent(uint256 messageSender, address number);

    function setNumber(uint256 number) external{
        secretNumber = number;
        emit tempEvent(number, msg.sender);
    }

    function getDeployer() external view returns(address){
        return deployer;
    }

    function getNumber() external view returns(uint256){
        return secretNumber;
    }
}