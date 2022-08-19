// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./DEFI.sol";
import "./LazyGolos.sol";

contract VotingMachine {
    address public owner;
    Golos public token;
    DEFI public dao;

    uint32 total;

    uint32[] openedId = [ 0 ];

    uint constant DEFAULT_DURATION = 5 minutes;
    uint constant MIN_DURATION = 40 seconds;
    uint constant MAX_DURATION = 15 days;

    struct Voting {
        uint newFee;
        uint deadline;
        uint yes;
        uint no;
    }

    mapping (uint32 => Voting) votings;

    event CreatedVoting(uint32 indexed id, address indexed initiator, uint fee, uint startTime, uint endTime);
    event UpdateVote(uint32 indexed id, uint yes, uint no);
    event SummarizedVoting(uint32 indexed id, uint fee, uint yes, uint no);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "u no owner");
        _;
    }

    function setTokens(Golos golos) external onlyOwner {
        token = golos;
    }

    function setDAO(DEFI dao_) external onlyOwner {
        dao = dao_;
    }

    function actualVotings() external view returns(uint32[] memory) {
        return openedId;
    }

    function createVoting(uint newFee, uint duration) public {
        require((token.balanceOf(msg.sender) * 100 ) / token.totalSupply() > 10,
                "u can't create voting");
        require(duration >= MIN_DURATION && duration <= MAX_DURATION , "uncorrect duration");
        uint deadline = block.timestamp + duration;

        uint32[] memory openId = openedId;

        for (uint i = 1; i < openId.length; ++i) {
            require(deadline != votings[openId[i]].deadline, "uncorrect deadline");
        }
        Voting storage v = votings[++total];
        v.newFee = newFee;
        v.deadline = deadline;
        openedId.push(total);

        emit CreatedVoting(total, msg.sender, newFee, block.timestamp, deadline);
    }

    function createVoting(uint newFee) external {
        createVoting(newFee, DEFAULT_DURATION);
    }

        // require(msg.sender == address(token), "u no tokens");
    function findIndex(uint32 id) external view returns(uint) {
        for (uint i = 1; i < openedId.length; ++i)
            if (openedId[i] == id)
                return i;
        return 0;
    }

    function isActual(uint32 id) public view returns(bool) {
        return votings[id].deadline > block.timestamp;
    }

    function vote(uint32 id, bool uAgree) external {
        require(isActual(id), "voting already finished");

        uint votes = token.burnVotes(id, msg.sender);
        Voting storage voting = votings[id];

        if (uAgree) {
            voting.yes += votes;
        } else {
            voting.no += votes;
        }
        emit UpdateVote(id, voting.yes, voting.no);
    }

    function summarizingAll() external {
        uint count;
        uint newFee;
        uint last;
        uint32[] memory openId = openedId;
        uint length = openId.length;
        uint32[] memory actualIds = new uint32[](length);
        for (uint i = 1; i < length; ++i) {
            uint32 id = openId[i];
            if (isActual(id)) {
                actualIds[++count] = id;
                continue;
            }

            Voting memory voting = votings[id];
            if(voting.yes > voting.no && voting.deadline > last) {
                last = voting.deadline;
                newFee = voting.newFee;
            }
            emit SummarizedVoting(id, voting.newFee, voting.yes, voting.no);
            delete votings[id];
        }
        delete openedId;
        for(uint i = 0; i <= count; ++i) {
            openedId.push(actualIds[i]);
        }

        if (last > 0) {
            dao.setFEE(newFee);
        }
    }
}