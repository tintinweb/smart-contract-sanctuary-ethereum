/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
contract WalletManagement {
    address payable public owner;
    bool private newVoteConversation = false;

    mapping(address => uint) public allowance;
    mapping(address => bool) public isAllownace;

    struct guardian { 
        uint levelVote;
        bool isVote;
    }
    struct newOwner {
        address voted;
        uint numVotes;
        mapping(address => guardian) listVoteds;
    }
    newOwner public newVotedOwner;
    uint constant public numVotePass  = 3; 
    mapping(address => guardian) public guardians;
    // Event config
    event isNotOwner(string notification);  
    modifier isOwner(){
        require(msg.sender == owner, "You not owner, aborting");
        _;
    }

    modifier isGuardian(){
        require(guardians[msg.sender].levelVote > 0, "You not guardian, aborting");
        _;
    }

    modifier isStartVoteConversation() {
        require(newVoteConversation == true, "You will be wait to owner start vote conversation, aborting");
        _;
    }
    function getCurrentOwner() public view returns(address) {
        return owner;
    }
    function proposeNewOwner() public isStartVoteConversation isGuardian{
        require(guardians[msg.sender].isVote == false, "You are already voted, aborting");
        newVotedOwner.numVotes += guardians[msg.sender].levelVote;
        newVotedOwner.listVoteds[msg.sender] = guardians[msg.sender];
        guardians[msg.sender].isVote = true;
    }

    function startVotedFor(address _for) public isOwner {
        newVoteConversation = true;
        newVotedOwner.voted = _for;
        newVotedOwner.numVotes = 0;
    }


    function endVoted() public isOwner isStartVoteConversation{
        newVoteConversation = false;
        require(newVotedOwner.numVotes >= numVotePass, "Voted new owner unsuccessfully!");
        owner = payable(newVotedOwner.voted);
    }

    function setGuardian(address _for, uint _levelVote) public isOwner{
        guardians[_for].isVote = false;
        guardians[_for].levelVote = _levelVote;
    }
    function setAllowace(address _for, uint _amount) public isOwner{
        allowance[_for] = _amount;
        if(_amount > 0) {
            isAllownace[_for] = true;
        }
        else {
            isAllownace[_for] = false;
        }
    }

    function transfer(address _to, uint _amount, bytes memory _payload) public payable returns(bytes memory){
        if(msg.sender != owner) {
            require(isAllownace[_to], "You don't have authorize to transfer money from smart contract, aborting");
            require(allowance[_to] < _amount, "You can transfer more than money you have authorize, aborting");
        }
        (bool result, bytes memory data) = _to.call{value: _amount}(_payload);
        require(result, "Aborting, call was not successful");
        return data;
    }

    constructor(){
        owner = payable(msg.sender);
    }

    receive() external payable {}
}