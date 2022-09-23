/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract VotingSimulation {

    struct politicalParty {
        uint256 numberOfParty;
        uint256 numberOfVotes;
    }

    struct voter {
        uint256 votedFor;
    }

    struct votingCenter {
        voter[] allVoters;
    }

    politicalParty private s_winner;
    voter[100] s_votersArray; 
    politicalParty[5] s_politicalPartiesArray;
    votingCenter[10] s_votingCentersArray;

    function startVotingSimulation() public{
        delete s_politicalPartiesArray;
        delete s_votingCentersArray;
        delete s_votersArray;
        delete s_winner;
        
        for (uint256 i;i<5;i++){
            s_politicalPartiesArray[i] = politicalParty(i,0);
        }

        for (uint256 i; i< 100; i++){
            s_votersArray[i] = voter({votedFor: uint(keccak256(abi.encodePacked(block.timestamp + block.difficulty + i))) % 4});
            s_politicalPartiesArray[s_votersArray[i].votedFor].numberOfVotes += 1;
            s_votingCentersArray[uint(keccak256(abi.encodePacked(block.timestamp + block.difficulty + i))) % 9].allVoters.push(s_votersArray[i]);
        }
        
        politicalParty memory newWinner  = s_politicalPartiesArray[0];
        for (uint256 i=1; i< 5; i++){
            if(s_politicalPartiesArray[i].numberOfVotes > s_politicalPartiesArray[i-1].numberOfVotes){
                newWinner = s_politicalPartiesArray[i]; 
            }
        }

        s_winner = newWinner;
    }

    function  viewPoliticalParties() view public returns(politicalParty[5] memory)  {
            return s_politicalPartiesArray;
        }

    function  viewVoters()  public view returns(voter[100] memory) {
            return s_votersArray;
        }
     
    function  viewVotingCenters()  public view returns(votingCenter[10] memory) {
    
            return s_votingCentersArray;
        }

    function viewWinner() public view returns(politicalParty memory) {
        return s_winner;
    }
    
    

}