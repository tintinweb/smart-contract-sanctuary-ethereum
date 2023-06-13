/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract VOTE {
    int256 public dog1;
    int256 public dog2;
    int256 public dog3;
    address founder;
    mapping(address => Voter) voter;
    struct Voter {
        uint256 weight;
        bool voted;
    }

    constructor()  {
        dog1 = 0;
        dog2 = 0;
        dog3 = 0;
        founder = msg.sender;
        voter[founder].weight = 1;
    }

    function GiveVote(address voters) public {
        require(msg.sender == founder);
        require(voter[voters].voted == false);
        require(voter[voters].weight == 0);
        voter[voters].weight = 1;
    }

    function vote(int256 choose) public {
        Voter storage sender = voter[msg.sender];
        require(sender.voted == false);
        require(sender.weight > 0);
        sender.voted = true;
        if (choose == 1) {
            dog1++;
        }
        if (choose == 2) {
            dog2++;
        }
        if (choose == 3) {
            dog3++;
        }
    }

    function result(int256 sum) public view returns (int256 count) {
        if (sum == 1) {
            return dog1;
        } else if (sum == 2) {
            return dog2;
        } else if (sum == 3) {
            return dog3;
        }
    }

    function who_winner() public view  returns (int256 winner) {
        if (dog1 > dog2 && dog1 > dog3) {
            return dog1;
        }
        if (dog2 > dog3 && dog2 > dog1) {
            return dog2;
        }
        if (dog3 > dog1 && dog3 > dog2) {
            return dog2;
        }
    }
}