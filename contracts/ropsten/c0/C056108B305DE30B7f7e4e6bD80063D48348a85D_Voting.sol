/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: GPL-3.0
// File: contracts/Context.sol


pragma solidity >=0.4.22 <0.9.0;

abstract contract Context {
  
  constructor () { }

  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; 
    return msg.data;
  }
}
// File: contracts/Voting.sol


pragma solidity >=0.7.0 <0.9.0;


contract Voting is Context {

    // var
    struct Voter {
        address voterAddress;
        uint idVoteCandidate;
        bool voted;
    }
    struct Candidate {
        uint id;
        uint age;
        uint voteCount;
        string name;
        string imgProfile;
    }

    uint public candidateCounter = 0;

    mapping(address => Voter) public Voters;
    mapping(uint => Candidate) public Candidates;

    address public owner;

    // modifier
    modifier onlyOwner() {
        require(owner == _msgSender(), "You are not owner !");
        _;
    }

    // event

    // function
    constructor() {
        owner = _msgSender();
    }

    function getCandidate(uint _idCandidate) public view returns(uint, uint, string memory, string memory) {

        uint _age = Candidates[_idCandidate].age;   
        uint _voteCount = Candidates[_idCandidate].voteCount;      
        string memory _name = Candidates[_idCandidate].name;       
        string memory _imgProfile = Candidates[_idCandidate].imgProfile;     

        return (_age, _voteCount, _name, _imgProfile);
        
    }

    function addCandidate(uint _age, string memory _name, string memory _imgProfile) public onlyOwner {
        candidateCounter++;

        Candidate memory Candid;
        Candid.id = candidateCounter;
        Candid.name = _name;
        Candid.age = _age;
        Candid.imgProfile = _imgProfile;

        Candidates[candidateCounter] = Candid;
    }

    function addVote(uint _idCandidate) public {

        
        require(Voters[_msgSender()].voted == false, "You have already voted !");

        Voter memory Vot;
        Vot.idVoteCandidate = _idCandidate;
        Vot.voterAddress = _msgSender();
        Vot.voted = true;
        Voters[_msgSender()] = Vot;

        Candidates[_idCandidate].voteCount++;
            
    }

}