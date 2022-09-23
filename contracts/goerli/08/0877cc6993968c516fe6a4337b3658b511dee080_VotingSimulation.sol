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

    struct voter{
        uint256 vote;
        uint256 number;
    }

    struct votingCenter {
        voter[] allVoters;
    }

    


    politicalParty private s_winner;
    uint256[100] s_votesArray; 
    politicalParty[5] s_politicalPartiesArray;
    votingCenter[10] s_votingCentersArray;

    function createVoters(uint256[] memory randomNumbers) public {
        delete s_politicalPartiesArray;
        delete s_votingCentersArray;
        delete s_votesArray;
        delete s_winner;

        for (uint256 i;i<5;i++){
            s_politicalPartiesArray[i] = politicalParty(i,0);
        }

         for (uint256 i; i< 100; i++){
            s_votesArray[i] = 0;
            s_votingCentersArray[randomNumbers[i]].allVoters.push(voter(0,i));
        }
        
    }

    function startVoting(uint256[] memory randomNumbers) public{
        
        

       for (uint256 i; i<100; i++){
        s_votesArray[i] = randomNumbers[i];
        s_politicalPartiesArray[randomNumbers[i]].numberOfVotes += 1;
       }

       for (uint256 i; i<10;i++){
        uint256 numberOfVoters = s_votingCentersArray[i].allVoters.length;
            for (uint256 j; j<numberOfVoters; j++){
                s_votingCentersArray[i].allVoters[j].vote = randomNumbers[s_votingCentersArray[i].allVoters[j].number];
            }
       }

        
    }

    function  viewVotes()  public view returns(uint256[100] memory, voter[] memory, voter[] memory, voter[] memory, voter[] memory, voter[] memory, 
    voter[] memory, voter[] memory, voter[] memory, voter[] memory, voter[] memory) {
       

           return(s_votesArray, s_votingCentersArray[0].allVoters, s_votingCentersArray[1].allVoters,
           s_votingCentersArray[2].allVoters, s_votingCentersArray[3].allVoters,s_votingCentersArray[4].allVoters,
           s_votingCentersArray[5].allVoters,s_votingCentersArray[6].allVoters,s_votingCentersArray[7].allVoters,
           s_votingCentersArray[8].allVoters,s_votingCentersArray[9].allVoters);      
        }
     

    function viewWinner() public view returns(politicalParty memory) {
        return s_winner;
    }

    function viewParties() public view returns(politicalParty[5] memory){
        
    }
    
    

}