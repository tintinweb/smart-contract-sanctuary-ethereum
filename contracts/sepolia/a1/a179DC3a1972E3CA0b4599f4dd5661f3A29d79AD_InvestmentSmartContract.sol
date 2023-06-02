/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract InvestmentSmartContract {
    struct Investor {
        uint256 balance;
        uint256 percentage;
    }

    address immutable contractOwner = 0x5E4B7C08D32810282E1cB539e8b15173Fb5E38c4;
    address private startupOwner;
    mapping(address => uint256) private investorsBalances;
    mapping(address => uint256) private investorsPercentages;
    uint256 private startTime;
    uint256 private endTime;
    uint256 private tokensCollected;
    uint256 private investmentGoal;
    uint256 private sharePercentage;
    address[] private investorsList;

    constructor(uint256 _investmentGoal, uint256 _sharePercentage, uint256 _endTime) {
        startupOwner = msg.sender;
        investmentGoal = _investmentGoal;
        sharePercentage = _sharePercentage;
        startTime = block.timestamp;
        endTime = _endTime;
    }

    function invest() external payable {
        uint256 investmentAmount = msg.value;
        if (investmentAmount == 0) {
            revert("NO FUNDS ATTACHED");
        } else {
            address investor = msg.sender;
            investorsList.push(investor);
            investorsBalances[investor] += investmentAmount;
            tokensCollected += investmentAmount;
        }
    }

    function withdrawOwner(uint256 finalAmount) internal {
        address caller = msg.sender;
        if (tokensCollected >= investmentGoal && startupOwner == caller) {
            payable(caller).transfer(finalAmount);
        } else {
            revert("NOT ENOUGH FUNDS TO WITHDRAW");
        }
    }

    function withdrawTest() external {
        payable(msg.sender).transfer(tokensCollected);
    }

    function withdrawInvestor() external {
        address caller = msg.sender;
        if (tokensCollected >= investmentGoal) {
            uint256 amount = investorsBalances[caller];
            investorsBalances[caller] = 0;
            payable(caller).transfer(amount);
        } else {
            revert("NOT ENOUGH FUNDS TO WITHDRAW");
        }
    }

    function withdrawTokenvest(uint256 commission) internal {
        payable(contractOwner).transfer(commission);
    }

    function showAmount() external view returns (uint256) {
        return tokensCollected;
    }

    function showTime() external view returns (uint256) {
        return block.timestamp;
    }

    function finishStartup(uint256 commission) external {
        if (endTime > block.timestamp) {
            revert("CAMPAIGN STILL RUNNING");
        } else {
            if (tokensCollected < investmentGoal) {
                for (uint256 investorIndex = 0; investorIndex < investorsList.length; investorIndex++) {
                    uint256 refundAmount = investorsBalances[investorsList[investorIndex]];
                    payable(investorsList[investorIndex]).transfer(refundAmount);
                }   
                revert("CAMPAIGN FAILED");    
            } else {
                withdrawOwner(tokensCollected);
                withdrawTokenvest(commission);
            }
        }
    }

    function showInvestors() external view returns (address[] memory, uint256[] memory) {
        uint256[] memory balances = new uint256[](investorsList.length);
        for (uint256 i = 0; i < investorsList.length; i++) {
            balances[i] = investorsBalances[investorsList[i]];
        }
        return (investorsList, balances);
    }
}