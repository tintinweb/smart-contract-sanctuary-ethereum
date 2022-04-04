/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract NFTMetadataQuest {

    struct Submission{
        address user;
        string answerHash;
    }

    Submission [] public submissions;

    event QuestSubmission(address indexed user, uint256 indexed questNumber);

    constructor(){}


    function submitQuest(string memory answerHash) public {
        Submission memory sub = Submission(msg.sender, answerHash);
        submissions.push(sub);
        emit QuestSubmission(msg.sender, 3);
    }


    function viewSubmissions() public view returns (Submission [] memory){
        return submissions;
    }
}