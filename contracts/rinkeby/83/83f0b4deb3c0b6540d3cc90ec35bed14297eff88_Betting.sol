/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

//// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.0;

contract Betting{

    uint totalAmount = 0;
    address[] public particepants;
    mapping(address => uint) winnerVote;
    mapping(address => bool) voted;
    mapping(address => bool) userExists;
    uint state = 0;

    constructor(){
        
    }

    receive() external payable {
        totalAmount = totalAmount+msg.value;
    }

    fallback() external payable {
        totalAmount = totalAmount+msg.value;
    }

    function voteWinner(address winner) public{
        uint votes = winnerVote[winner];
        winnerVote[winner] = votes+1;
        voted[msg.sender] = true;
    }

    function getWinner() public view returns (address winner){

        for(uint i =0; i < particepants.length; i++){
            require(voted[particepants[i]] == true, "Everyone has not voted");
        }
        uint maxVotes;
        for(uint i =0; i < particepants.length; i++) {
            if(maxVotes < winnerVote[particepants[i]]){
                maxVotes = winnerVote[particepants[i]];
                winner = particepants[i];
            }
        }
        return winner;
    }

    function participate() public payable{
        require(userExists[msg.sender] == false," already participated");
        require(msg.value >= 100000000000000000 ,"not ok");
        particepants.push(msg.sender);
    }
}