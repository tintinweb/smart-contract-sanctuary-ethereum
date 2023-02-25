/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
contract Storage {
    mapping(address => uint) public points;
    mapping(address => bool) public isSuperVip;
    uint256 public numOfFree;
    event SuperVip(address user);

    function promotionSVip() public {
        require(points[msg.sender] >= 999, "don't have enough points");
        isSuperVip[msg.sender] = true;
    }

    function getPoint() public{
        require(numOfFree < 100);
        points[msg.sender] += 1;
        numOfFree++;
    }
    
    function transferPoints(address to, uint256 amount) public {
        uint256 tempSender = points[msg.sender];
        uint256 tempTo = points[to];
        require(tempSender > amount);
        require(tempTo + amount > amount);
        points[msg.sender] = tempSender - amount;
        points[to] = tempTo + amount;
    }

    function isComplete() public {
        require(isSuperVip[msg.sender]);
        emit SuperVip(msg.sender);
    }
}