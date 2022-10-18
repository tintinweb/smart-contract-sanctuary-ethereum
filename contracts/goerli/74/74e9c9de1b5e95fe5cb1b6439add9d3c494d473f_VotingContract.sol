/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract VotingContract {
    address public owner;
    uint256 public counter;
    uint256 public maxCandidatesNum;

// ---- Структура кандидата ----
    struct Candidate {
        uint256 balance;
        bool isExistOnThisVoting;
    }
//----- Храним голосование--------
    struct Voting {
        bool started;
        address Winner;
        uint256 StartDate;
        uint256 WinnerBalance;
        uint256 Bank;
        uint256 Period;
        mapping(address => Candidate) Candidates;
    }

    mapping(uint256 => Voting) private Votings;


//---------------------------
    uint8 public immutable Comission;

    constructor(uint256 _maxCandidatesNum, uint8 _comission) {
        owner = msg.sender;
        Comission = _comission;
        maxCandidatesNum = _maxCandidatesNum;
    }

    function takePartInVoting(uint8 _votingID, address _candidate)
        public
        payable
    {
        require(Votings[_votingID].started, "Voting not started yet");
        require(
            Votings[_votingID].StartDate + Votings[_votingID].Period >
                block.timestamp,
            "Voting is ended"
        );
        require(
            checkCandidate(_votingID, _candidate),
            "Candidate does not exist on this voting"
        );
        Votings[_votingID].Candidates[_candidate].balance += msg.value;
        Votings[_votingID].Bank += msg.value;
        if (
            Votings[_votingID].Candidates[_candidate].balance >
            Votings[_votingID].WinnerBalance
        ) {
            Votings[_votingID].WinnerBalance = Votings[_votingID]
                .Candidates[_candidate]
                .balance;
            Votings[_votingID].Winner = _candidate;
        }
    }

    function WithdrowMyPrize(uint256 _votingID) public {
        require(Votings[_votingID].started, "Voting not started yet");
        require(
            Votings[_votingID].StartDate + Votings[_votingID].Period <
                block.timestamp,
            "Voting is not over yet!"
        );
        require(
            msg.sender == Votings[_votingID].Winner,
            "You are not a winner!"
        );
        require(
            Votings[_votingID].Bank > 0,
            "You have already received your prize!"
        );
        uint256 amount = Votings[_votingID].Bank;
        uint256 ownersComission = (Comission * amount) / 100;
        uint256 clearAmount = amount - ownersComission;
        Votings[_votingID].Bank = 0;
        payable(owner).transfer(ownersComission);
        payable(msg.sender).transfer(clearAmount);
    }

    function getVotingInfo(uint256 _votingID)
        public
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256,
            uint256,
            address
        )
    {
        return (
            Votings[_votingID].started,
            Votings[_votingID].StartDate,
            Votings[_votingID].Period,
            Votings[_votingID].WinnerBalance,
            Votings[_votingID].Bank,
            Votings[_votingID].Winner
        );
    }

    function checkCandidate(uint256 _votingID, address _candidate)
        public
        view
        returns (bool)
    {
        return (Votings[_votingID].Candidates[_candidate].isExistOnThisVoting);
    }

    function addVoting(uint256 _period, address[] calldata _candidates)
        public
        onlyOwner
    {
        require(_candidates.length < maxCandidatesNum, "Too many candidates!");
        Votings[counter].Period = _period;
        for (uint256 i = 0; i < _candidates.length; i++) {
            addCandidate(counter, _candidates[i]);
        }
        emit votingDraftCreated(counter);
        counter++;
    }

    function startVoting(uint256 _votingID) public onlyOwner {
        Votings[_votingID].started = true;
        Votings[_votingID].StartDate = block.timestamp;
        emit votingStarted(_votingID, block.timestamp);
    }

    function editVotingPeriod(uint256 _votingID, uint256 _newPeriod)
        public
        onlyOwner
    {
        require(
            Votings[_votingID].started == false,
            "Voting has already begun!"
        );
        Votings[_votingID].Period = _newPeriod;
    }

    function addCandidate(uint256 _votingID, address _candidate)
        public
        onlyOwner
    {
        require(
            Votings[_votingID].started == false,
            "Voting has already begun!"
        );
        Votings[_votingID].Candidates[_candidate].isExistOnThisVoting = true;
        emit candidateInfo(_votingID, _candidate, true);
    }

    function deleteCandidate(uint256 _votingID, address _candidate)
        public
        onlyOwner
    {
        require(
            Votings[_votingID].started == false,
            "Voting has already begun!"
        );
        Votings[_votingID].Candidates[_candidate].isExistOnThisVoting = false;
        emit candidateInfo(_votingID, _candidate, false);
    }

    function setMaxCandidatesNum(uint256 _maxCandidatesNum) public onlyOwner {
        maxCandidatesNum = _maxCandidatesNum;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Error! You're not the smart contract owner!"
        );
        _;
    }

    event candidateInfo(
        uint256 indexed votingID,
        address indexed candidate,
        bool existOnThisVoting
    );
    event votingDraftCreated(uint256 indexed votingID);
    event votingStarted(uint256 indexed votingID, uint256 startDate);
}