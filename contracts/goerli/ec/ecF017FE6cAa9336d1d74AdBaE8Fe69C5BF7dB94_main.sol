/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// optional todo: if only one policy is available, need more than x number unique votes to pass
// optional todo: reuse policies which havent been passed in new round

contract main {
    struct Vote {
        uint256 positive;
        uint256 negative;
    }

    struct Policy {
        string title;
        string description;
        string author;
        string link; // link to detail document and policy
        uint256 duration;
        
        uint256 id;
        uint256 startTime;

        bool ended; // init to false
        string result; // init to ""
        uint256 voterCount; // init to 0. Count the number of voter
        mapping(address => uint256) voterList; // store the vote amount of each voter
    }

    event PolicyCreated (
        address indexed from,
        uint256 indexed id,
        string title
    );

    event PolicyEnded(
        address indexed from,
        uint256 indexed id,
        string title
    );

    Policy[] public policyList; // List of policy
    uint256 public policyID;
    mapping(uint256 => Vote) voteCount;
    mapping(uint256 => mapping(address => bool)) policyBidClaimed;

    function createPolicy(
        string calldata _title,
        string calldata _description,
        string calldata _author,
        string calldata _link,
        uint256 _duration
    ) public {
        require(_duration > 60, "Your duration is too short");
        Policy storage _policy = policyList.push();
        _policy.title = _title;
        _policy.description = _description;
        _policy.author = _author;
        _policy.link = _link;
        _policy.duration = _duration;

        _policy.id = policyID;
        _policy.startTime = block.timestamp;

        emit PolicyCreated(msg.sender, policyID, _policy.title);
        policyID++;

    }

    function vote(
        uint256 _policyID, 
        uint256 option
    ) public payable {
        // store the policy to _policy variable for ease of access
        Policy storage _policy = policyList[_policyID];
        // Check for whether Policy has ended
        require(
            !_policy.ended, 
            "Policy voting duration has ended"
        );
        require(
            block.timestamp - _policy.startTime <= _policy.duration,
            "Policy voting duration has ended"
        );
        // Check if option is out of range
        require(
            option >= 0,
            "Option out of range. 0 for negative, 1 for positive"
        );
        require(
            option <= 1,
            "Option out of range. 0 for negative, 1 for positive"
        );

        // Check if vote value higher than old vote
        uint256 currentVoteValue = _policy.voterList[msg.sender];
        require(
            msg.value > currentVoteValue, 
            "You can only enter a higher bid"
        );
        // Only increase voterCount if the person never voted before
        if (currentVoteValue == 0) {
            _policy.voterCount += 1;
        }

        _policy.voterList[msg.sender] = msg.value;

        uint256 valueDiff = msg.value - currentVoteValue;

        if (option == 0) {
            voteCount[_policyID].negative += valueDiff;
        } else if (option == 1) {
            voteCount[_policyID].positive += valueDiff;
        }

        // If fail revert everything back to previous state
        if (!payable(msg.sender).send(valueDiff)) {
            _policy.voterList[msg.sender] = currentVoteValue;
            if (option == 0) {
                voteCount[_policyID].negative -= valueDiff;
            } else if (option == 1) {
                voteCount[_policyID].positive -= valueDiff;
            }
        }
    }

    function getVoteValue(
        uint256 _policyID
    ) public view
        returns (
            uint256 totalValue, 
            uint256 positive, 
            uint256 negative
        )
    {
        return (
            policyList[_policyID].voterList[msg.sender], 
            voteCount[_policyID].positive, 
            voteCount[_policyID].negative
        );
    }

    function endPolicy(
        uint256 _policyID
    ) public {
        Policy storage _policy = policyList[_policyID];
        require(
            block.timestamp - _policy.startTime > _policy.duration,
            "Policy duration has not ended yet."
        );
        require(!_policy.ended, "Policy has ended");

        uint256 posVote = voteCount[_policyID].positive;
        uint256 negVote = voteCount[_policyID].negative;

        if (posVote > negVote) {
            _policy.result = "Policy successfully passed.";
        } else if (posVote < negVote) {
            _policy.result = "Policy failed to gather enough vote.";
        } else {
            _policy.result = "Undecided result.";
        }

        emit PolicyEnded(msg.sender, policyID, _policy.title);
        _policy.ended = true;
    }

    function withdrawBid(
        uint256 _policyID
    ) public {
        Policy storage _policy = policyList[_policyID];
        require(_policy.ended, "Policy has not ended yet.");

        uint256 withdrawAmount = (voteCount[_policyID].positive +
            voteCount[_policyID].negative) / _policy.voterCount;
        uint256 amount = _policy.voterList[msg.sender];

        if (amount > 0) {
            if (!policyBidClaimed[_policyID][msg.sender]) {
                policyBidClaimed[_policyID][msg.sender] = true;
                if (!payable(msg.sender).send(withdrawAmount)) {
                    policyBidClaimed[_policyID][msg.sender] = false;
                }
            }
        }
    }
}