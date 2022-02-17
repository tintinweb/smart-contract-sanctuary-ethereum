/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;


contract Election {

    address public owner;
    string public electionName;


      constructor(string memory _appName) {                  
        electionName = _appName;    
        owner = msg.sender;
    }

    struct Candidate {
        string name;
        uint voteCount;
    }

    struct Voter {
        bool authorized;
        bool voted;
        uint vote;
    }


    modifier ownerOnly(){
        require(msg.sender == owner);
        _;
    }

    
    mapping(address => Voter) public voters;
    
    Candidate[] public candidates;
    address[] public voter_list;
    
    uint public totalVotes;


    function addCandidate(string memory _name) public {
        candidates.push(
            Candidate(_name,0)
        );

    }

    function sendEthertoContract() external payable{
           
    }

       function sendEther(address payable _recepient) external{
           _recepient.transfer(1 ether);
    }

    function balanceOf() external view returns(uint) {
        return address(this).balance;
    }
   

    //  function getVoters() public view returns(string[] memory ) {

    //       address[] memory result;
 
    //      for(uint i=0; i<voter_list.length; i++){
    //             result.append(voter_list[0]);
    //     }
    //     return result;

    // }

    function getNumCandidates() public view returns(uint) {
        return candidates.length;
    }

       function getNumOfVoters() public view returns(uint) {
        return voter_list.length;
    }

    function getCandidates() public view returns(Candidate[] memory) {
        return candidates;
    }



    function authorize(address _personAddress) ownerOnly public {
          voter_list.push(_personAddress);
          voters[_personAddress].authorized = true; 
        
    }

    function vote(uint _voteIndex) public {
        // require(!voters[msg.sender].voted, "You already voted"); 
        // require(voters[msg.sender].authorized, "First you should authorize"); 

        voters[msg.sender].vote = _voteIndex; 
        voters[msg.sender].voted = true; 

        candidates[_voteIndex].voteCount += 1;
        totalVotes += 1;
        
    }


   
}