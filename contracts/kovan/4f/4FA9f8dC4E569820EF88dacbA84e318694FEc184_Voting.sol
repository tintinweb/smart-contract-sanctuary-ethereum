/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract Voting {
    string[] public candidateList;

    mapping (string => uint256) votesReceived;


    constructor(string[] memory candidateNames) public {
        candidateList = candidateNames;
    }

    function voteForCandidate(string memory candidate) public {
        votesReceived[candidate] += 1;
    }
    function totalVotesFor(string memory candidate) public view returns (uint256) {
        return votesReceived[candidate];
    }
    function candidateCount() public view returns (uint256) {
        return candidateList.length;
    }
}