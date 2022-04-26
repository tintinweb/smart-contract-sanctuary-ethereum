/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;
pragma abicoder v2;

/**
 * @title BabyShowerFunds
 * @dev Users can vote on a name if they make a donation to the new baby fund. Each vote has a fixed price and voters can vote as many times as they like.
 */
contract BabyShowerFunds {

    // struct Name {
    //     string name;
    //     uint votes;
    // }
    string[] public names;
    uint[] public votes;

    address payable public owner;
    uint public amount;
    // address[] public players;

    /**
     * @dev Set contract deployer as owner and initializes array with babynames
     */
    constructor(string[] memory babyNames, uint vote_cost) {
        owner = msg.sender;
        amount = vote_cost;
        names = babyNames;
        for (uint i = 0; i < babyNames.length; i++) {
            votes.push(0);
        }
    }

    // function enter(uint name_index) public payable {
    //     require(msg.value > .01 ether);
    //     players.push(msg.sender);
    // }


    function vote(uint name_index) public payable {
        require(msg.value > amount);
        owner.transfer(msg.value);

        votes[name_index] += 1;
    }

}