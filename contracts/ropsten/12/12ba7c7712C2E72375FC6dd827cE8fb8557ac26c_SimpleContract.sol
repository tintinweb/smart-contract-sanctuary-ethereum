// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SimpleContract {

    string public name;
    
    uint256 public voteCount;

    mapping (uint256 => VoteData) public votes;

    struct VoteData {
        string name;
        uint256 agree;
        uint256 disagree;
        // bool isCompleted
    }

    event CreateVote (
        address operator, 
        string voteTitle, 
        uint256 voteId
    );
    event Vote (address operator, uint256 voteId, bool isAgree);


    constructor (string memory _name) {
        name = _name;
    }

    function createVote(string memory _voteTitle) external {
        voteCount++;
        uint256 voteId = voteCount;

        votes[voteId] = VoteData(_voteTitle, 0, 0);

        emit CreateVote(msg.sender, _voteTitle, voteId);
    }

    function vote(uint256 _id, bool _isAgree) external {
        require(_id <= voteCount, "This vote is not defined yet.");

        if(_isAgree){
            votes[_id].agree++;
        }
        else{
            votes[_id].disagree++;
        }

        emit Vote(msg.sender, _id, _isAgree);
    }
}