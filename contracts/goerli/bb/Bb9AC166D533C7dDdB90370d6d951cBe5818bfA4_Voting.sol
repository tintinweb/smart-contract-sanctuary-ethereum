/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// SPDX-License-Identifier: MIT

// File: contracts/Types.sol



pragma solidity >=0.7.0 <0.9.0;

library Types {
    struct Affair {
        uint256 id; // AffairID, e.g. 20210044
        string ref; // AffairID, e.g. 21.044
        string topic; // Thema, e.g. Keine Massentierhaltung in der Schweiz (Massentierhaltungsinitiative). Volksinitiative und direkter Gegenentwurf
        string date; // Einreichungsdatum, e.g. 19.05.2021
    }

    struct Vote {
        uint256 id; // AffairID
        bool voted; // Ja oder Nein
        uint256 votedAt; // Wann wurde die Stimme abgegeben?
    }

    struct Votes {
        uint256 id; // AffairID
        uint256 yay; // Ja-Stimmen
        uint256 nay; // Nein-Stimmen
    }
}

// File: contracts/Voting.sol



/*
[
    [20210044,"21.044","Keine Massentierhaltung in der Schweiz (Massentierhaltungsinitiative).\nVolksinitiative und direkter Gegenentwurf","19.05.2021"],
    [20210024,"21.024","Verrechnungssteuergesetz.\nStärkung des Fremdkapitalmarkts","14.04.2021"],
    [20190050,"19.050","Stabilisierung der AHV (AHV 21)\nBundesgesetz über die Alters- und Hinterlassenenversicherung (AHVG)\nBundesbeschluss über die Zusatzfinanzierung der AHV durch eine Erhöhung der Mehrwertsteuer","28.08.2019"]
]
*/

pragma solidity >=0.7.0 <0.9.0;


/**
 * @title Voting
 * @dev Implements the functions for voting
 */
contract Voting {
    mapping(uint256 => Types.Affair) affairs;
    mapping(uint256 => Types.Votes) votes;
    mapping(address => mapping(uint256 => Types.Vote)) voters;

    uint256[] private affairIDs;

    uint256 private startTime;
    uint256 private endTime;

    address public executor;

    string public name; // Volksabstimmung vom 25. September 2022

    event VotingStarted();
    event VotingEnded();
    event VotesUpdated(Types.Votes);

    constructor(string memory _name, Types.Affair[] memory _affairs) {
        name = _name;

        for (uint256 i = 0; i < _affairs.length; i++) {
            Types.Affair memory affair = _affairs[i];

            affairs[affair.id] = affair;
            affairIDs.push(affair.id);

            votes[affair.id].id = affair.id;
        }

        executor = msg.sender;
    }

    function getAffairs() public view returns (Types.Affair[] memory) {
        Types.Affair[] memory _affairs = new Types.Affair[](affairIDs.length);

        for (uint256 i = 0; i < affairIDs.length; i++) {
            _affairs[i] = affairs[affairIDs[i]];
        }

        return _affairs;
    }

    function isVoting() public view returns (bool) {
        return (startTime > 0 &&
            block.timestamp >= startTime &&
            endTime > 0 &&
            block.timestamp <= endTime);
    }

    // Public vote function for voting on an affair
    function vote(uint256 _id, bool _vote) public isOpen {
        require(affairs[_id].id == _id, "affair does not exist");

        Types.Vote memory oldVote = voters[msg.sender][_id];
        if (oldVote.id == _id) {
            // revert old vote
            if (oldVote.voted) {
                votes[_id].yay--;
            } else {
                votes[_id].nay--;
            }
        }

        voters[msg.sender][_id] = Types.Vote({
            id: _id,
            voted: _vote,
            votedAt: block.timestamp
        });

        if (_vote) {
            votes[_id].yay++;
        } else {
            votes[_id].nay++;
        }

        emit VotesUpdated(votes[_id]);
    }

    function hasVoted(uint256 _id) public view hasStarted returns (bool) {
        require(affairs[_id].id == _id, "affair does not exist");

        Types.Vote memory _vote = voters[msg.sender][_id];
        require(_vote.id == _id, "vote does not exist");

        return _vote.voted;
    }

    function getVote(uint256 _id)
        public
        view
        hasStarted
        returns (Types.Vote memory)
    {
        require(affairs[_id].id == _id, "affair does not exist");

        Types.Vote memory _vote = voters[msg.sender][_id];
        require(_vote.id == _id, "vote does not exist");

        return _vote;
    }

    function getVotes(uint256 _id)
        public
        view
        hasStarted
        returns (Types.Votes memory)
    {
        require(affairs[_id].id == _id, "affair does not exist");
        // require(votes[_id].id == _id, "votes do not exist");

        return votes[_id];
    }

    function getResults() public view isClosed returns (Types.Votes[] memory) {
        Types.Votes[] memory _votes = new Types.Votes[](affairIDs.length);

        for (uint256 i = 0; i < affairIDs.length; i++) {
            _votes[i] = votes[affairIDs[i]];
        }

        return _votes;
    }

    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    // Owner functions

    function startVoting() public onlyExecutor {
        startTime = block.timestamp;
        endTime = block.timestamp + 1 days;

        emit VotingStarted();
    }

    function stopVoting() public onlyExecutor {
        endTime = block.timestamp;

        emit VotingEnded();
    }

    function setStartTime(uint256 _startTime) public onlyExecutor {
        startTime = _startTime;
    }

    function setEndTime(uint256 _endTime) public onlyExecutor {
        endTime = _endTime;
    }

    // Helper functions

    modifier onlyExecutor() {
        require(msg.sender == executor, "only for executor");
        _;
    }

    modifier isOpen() {
        require(
            startTime > 0 && block.timestamp >= startTime,
            "voting not started"
        );
        require(endTime > 0 && block.timestamp <= endTime, "voting ended");
        _;
    }

    modifier isClosed() {
        require(
            startTime > 0 && block.timestamp >= startTime,
            "voting not started"
        );
        require(endTime > 0 && block.timestamp >= endTime, "voting not ended");
        _;
    }

    modifier hasStarted() {
        require(
            startTime > 0 && block.timestamp >= startTime,
            "voting not started"
        );
        _;
    }

    modifier hasEnded() {
        require(endTime > 0 && block.timestamp >= endTime, "voting not ended");
        _;
    }
}