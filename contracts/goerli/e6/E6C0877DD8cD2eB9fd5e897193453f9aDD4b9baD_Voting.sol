// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

// contract deployed at: 0xE6C0877DD8cD2eB9fd5e897193453f9aDD4b9baD

contract Voting{
    struct candidate{
        uint id;
        address generater;
        string name;
        uint votes;
    }


    uint tokenID = 0;

    candidate[] public candidates;

    event candidate_gen(address indexed sender,uint id, string _name, uint votes);
    mapping (address => bool) userVoted;
    mapping(address => bool) candidateGenerator;
    

    function newCandidate(string memory _name) public {
        require(!candidateGenerator[msg.sender],"you can create only one candidate");
        
        candidates.push(candidate(tokenID,msg.sender,_name,0));
        emit candidate_gen(msg.sender,tokenID,_name,0);
        candidateGenerator[msg.sender] = true;
        tokenID+=1;



    }
    function castVote(uint token) public{
        require(!userVoted[msg.sender],"you can cote only once");
        candidates[token].votes +=1;
        userVoted[msg.sender] = true;




    }

    function getCandidates() public view returns(candidate[] memory){
        return candidates;
    }



}