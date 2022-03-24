/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract RewardSystem {

    uint256 totalAmountinPool;
    address[] userAddress;
    mapping(address => uint256) userDepositValue;
    mapping(address => uint8) userExist;

    constructor() {
        totalAmountinPool = 0;
    }

    receive() external payable {
        
    }

    function getWithdrawValue() public view returns (uint256 result){

        uint256 curAmount = userDepositValue[msg.sender];

        result = curAmount;

    }

    function withdraw() public{

        uint256 curAmount = userDepositValue[msg.sender];
        if(curAmount > 0) {
            userDepositValue[msg.sender] = 0;
            totalAmountinPool -= curAmount;

            payable(msg.sender).transfer(curAmount);
        }
    }

    function putReward(uint256 amount) public {

        require(amount > 0 && totalAmountinPool > 0);

        uint256 currentAmount = userDepositValue[msg.sender];

        for (uint i = 0; i < userAddress.length; i ++) {
            userDepositValue[userAddress[i]] += amount * currentAmount / totalAmountinPool;
        }
        totalAmountinPool += amount;
    }

    function deposit() payable public {

        require(msg.value > 0);

        if(userExist[msg.sender] != 1) {
            userExist[msg.sender] = 1;
            userAddress.push(msg.sender);
        }

        totalAmountinPool += msg.value;
        userDepositValue[msg.sender] += msg.value;

        payable(this).transfer(msg.value);
    }
}