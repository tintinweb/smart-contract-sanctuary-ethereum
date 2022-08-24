/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract WeightLoss {
    // State Variables
    
        // Address of Ccompetitor 1
        address Competitor1;
        // Address of Competitor 2
        address Competitor2;

        mapping(address => uint) public weight;

        address[] internal competitors;

    // Constructor
        constructor(address _competitor1, address _competitor2) {
            Competitor1 = _competitor1;
            Competitor2 = _competitor2;
        }

    // Event 
    event WeightGoal(address _competitionMember);

    // Function that lets competitors input their current weight which is stored in storage and emits an event 
        function weightGoal(uint _weightGoal) external {
            require(msg.sender == Competitor1);
            require(msg.sender == Competitor2);

            // Mapping the inputed address to their weight goal
            weight[msg.sender] = _weightGoal;
            // Weight is placed in storage
            competitors.push(msg.sender);
            // Emits an event
            emit WeightGoal(msg.sender);

        }
    // Function that returns us the weight goal of the competitor addresses
        function getWeight() public view returns (address[] memory) {
            return competitors;
        }

    // Function that rewards the competitor that wins the competion
        // Whichever competitor is closest to their weight goal wins once the timer runs up
        // If someone reaches that weight goal first then they win the money
        // No money will be stored in this contract for security reasons
        // We will have to figure out a way to prove that they in fact did reach their weight goal to reward them the prize
    




}