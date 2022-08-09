/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract VotingContract {
    mapping(string => uint256) public votes;
    string[] public valid_proposals;

    event VoteCountsUpdated(string proposal, uint256 new_count);

    constructor(string[] memory valid_proposals_) {
        valid_proposals = valid_proposals_;
    }

    function vote_cat(string memory proposal) public {
        for (uint256 i; i < valid_proposals.length; ++i) {
            if (
                keccak256(bytes(proposal)) ==
                keccak256(bytes(valid_proposals[i]))
            ) {
                votes[proposal] += 1000;
                emit VoteCountsUpdated(proposal, votes[proposal]);
                return;
            }
        }
        revert("Invalid proposal.");
    }
}