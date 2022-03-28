// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract Factory{
    address[] public deployedElections;
    address gctcAddress;
    uint256 requiredGCTCamount;

    constructor(address _gctcAddress, uint256 _requiredGCTCamount) {
        gctcAddress = _gctcAddress;
        requiredGCTCamount = _requiredGCTCamount;
    }

    function createElection(string memory title, string memory description) public {
        require(IERC20(gctcAddress).balanceOf(msg.sender) >= requiredGCTCamount,"Not enough token to create election."); 
        address cont = address(new Election(msg.sender, title, description, gctcAddress, requiredGCTCamount));
        
        deployedElections.push(cont);
    }

    function setRequiredGCTCamount(uint256 _requiredGCTCamount) public {
        requiredGCTCamount = _requiredGCTCamount;
    }   

    function getDeployedElections() public view returns (address[] memory) {
        return deployedElections;
    }
}

contract Election {
    address public ORGANIZER;
    string[] public options;
    
    mapping(string => uint) totalVotes;
    mapping(address => bool) hasVoted;
    
    bool public votingStatus = false;
    string public description;
    string public title;
    address gctcAddress;
    uint256 requiredGCTCamount;
    string winner;

    constructor(address _org, string memory _title, string memory _description, address _gctcAddress, uint256 _requiredGCTCamount) {
        title = _title;
        description = _description;
        ORGANIZER = _org;
        gctcAddress = _gctcAddress;
        requiredGCTCamount = _requiredGCTCamount;
        options = ["Accept","Reject"];
        for(uint i = 0; i<options.length; i++){
            totalVotes[options[i]] = 0;
        }
        winner = "";
        votingStatus = true;
    }
    
    function vote(uint i) public {
        require(votingStatus,"Voting is ended.");
        require(!hasVoted[msg.sender],"Already did a vote.");
        require(IERC20(gctcAddress).balanceOf(msg.sender) >= requiredGCTCamount,"Not enough token to vote."); 

        hasVoted[msg.sender] = true;
        totalVotes[options[i]]++;
    }
    
    function endVoting() public{
        require(votingStatus);
        require(msg.sender == ORGANIZER);
            if(totalVotes[options[0]] > totalVotes[options[1]]){
                winner = options[0];
            }else if (totalVotes[options[0]] < totalVotes[options[1]]){
                winner = options[1];
            }else{
                winner = "neutral";   
            }
        votingStatus = false;
        ORGANIZER = address(0);
    }
    
    function votesCount() public view returns (uint256[2] memory, uint256){
        uint256[2] memory count;
        uint256 total;
        count = [totalVotes[options[0]],totalVotes[options[1]]];
        total = count[0]+count[1];
        return (count,total);
    }   

    function result() public view returns (string memory){
        require(!votingStatus);
        return winner;
    }

    function giveOptionsList() public view returns (string[] memory) {
        return options;
    }
}