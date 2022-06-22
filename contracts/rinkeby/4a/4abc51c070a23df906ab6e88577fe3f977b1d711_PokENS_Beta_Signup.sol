/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.14;

// <3 ho-oh

contract PokENS_Beta_Signup {

    uint256 currentReward = 69420;

    struct BetaTester {
        string favMon;
        uint reward;
        bool active;
    }

    mapping(address => BetaTester) public betaTester;

    address[] public betaTesterIds;

    function registerForBeta(string memory favMon) public {
        require(currentReward >= 1, "Sorry, this round of beta testing is full");
        require(betaTester[msg.sender].active != true, "Tester already registered");
        betaTesterIds.push(msg.sender);
        BetaTester storage newTester = betaTester[msg.sender];
        newTester.active = true;
        newTester.favMon = favMon;
        newTester.reward = currentReward;
        currentReward = currentReward - (currentReward / 20);        
    }

    function getNumTesters() public view returns (uint256) {
        uint256 num = betaTesterIds.length;
        return num;
    }

}