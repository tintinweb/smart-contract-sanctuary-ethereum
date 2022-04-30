//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/access/AccessControl.sol";

//library to manage signature resolving
library SignatureSuite {
    //signature method
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        //check signature length
        require(sig.length == 65, "check signature & retry");
        assembly {
            //first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            //next 32 bytes
            s := mload(add(sig, 64))
            // final 32byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }

    function getSigner(bytes32 _msgHash, bytes memory _signature)
        internal
        pure
        returns (address _addr)
    {
        _addr = recoverSigner(_msgHash, _signature);
        return _addr;
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, message));
        return ecrecover(prefixedHash, v, r, s);
    }
}

contract ZuriVote {
    string public description;
   // address public votersID;
    bool public isActive = false;
    bool public isEnded = false;
    // bool public voteEnabled;
    // bool public isEligible = false;
    address public chairman;
    uint256 public electionTimeline;

    event ElectionEnded(
        uint256[] indexed _winnerIDs,
        uint256 indexed _winnerVoteCount
    );

    event Voted(uint256 indexed _candidateID);

    event VotedFor(
        uint256 indexed _candidateID,
        uint256 indexed candidateVoteCount
    );

    //Add candidate event
    event CandidateAdded(uint256 indexed candidatesCount, string _name);

    // Instantiate the Boadrd of Directors struct
    struct BOD {
        address bodID;
    }

    // Instantiate the Teachers  struct
    struct Teachers {
        address teachersID;
    }

    struct Students {
        address votersID;
    }

    struct Candidate {
        string candidateName;
        uint256 candidateID;
        uint256 voteCount;
    }

    // Modifier granting permision to only Admin
    modifier onlyAdmin() {
        bool IsAdmin = false;
        for (uint256 i; i < adminCount; i++) {
            if (msg.sender == admins[i]) {
                IsAdmin = true;
                break;
            }
        }
        require(IsAdmin, "You are not Admin");
        _;
    }

    modifier onlyCandidateManager() {
        bool IsCandidateManager = false;
        for (uint256 i; i < candidateManagerCount; i++) {
            if (msg.sender == candidateManagers[i]) {
                IsCandidateManager = true;
                break;
            }
        }
        require(IsCandidateManager, "You are not a Candidate Manager");
        _;
    }

    //modifier grants permission to only valid candidate
    modifier onlyValidCandidate(uint256 _candidateID) {
        require(
            _candidateID < candidatesCount && _candidateID >= 0,
            "Invalid candidate"
        );
        _;
    }

    // Ensures only called when Elction is ongoing
    modifier electionIsOngoing() {
        require(!isEnded, "Election has ended");
        _;
    }

    modifier electionIsActive() {
        require(isActive, "Election has not commenced");
        _;
    }

    //admin addresses
    mapping(uint256 => address) public admins;

    mapping(uint256 => address) public candidateManagers;
    //store address that have voted
    mapping(address => bool) public voters;
    //Store candiates in a map
    mapping(uint256 => Candidate) public candidates;
    //store candidates standing in the election
    uint256 public candidatesCount = 0;
    //number of admin available
    uint256 public adminCount = 0;
    uint256 public candidateManagerCount = 0;
    //Stores final election results
    uint256 public winnerVoteCount;

    //array to handle ties where we have multiple winners with equal number of vote
    uint256[] public winnerIDs;

    constructor() {
        electionTimeline = block.timestamp + 20 minutes;
        _addAdmin(chairman = msg.sender);
        //_addCandidateManger(chairman = msg.sender);
        //_setUpElection(_nda, _candidates);
    }

    //time left for voting to end
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= electionTimeline) {
            return 0;
        } else {
            return electionTimeline - block.timestamp;
        }
    }

    //add an admin
    function _addAdmin(address _newAdmin) public {
        admins[adminCount] = _newAdmin;
        adminCount++;
    }

    //add a candidateManager
    function addCandidateManager(address _newCM) public onlyAdmin {
        candidateManagers[candidateManagerCount] = _newCM;
        candidateManagerCount++;
    }

    //commence election & begin accepting vote
    function startElection() public onlyAdmin {
        require(
            msg.sender == chairman,
            "You're Not Chairman"
        );
        isActive = true;
    }

    //End election & stop accepting votes
    function endElection() public onlyAdmin {
        require(msg.sender == chairman, "You are Not Chairman");
        require(block.timestamp >= electionTimeline, "election still ongoing");
        isEnded = true;
        _calculateWinner();
        emit ElectionEnded(winnerIDs, winnerVoteCount);
    }

    //Fucntion to add candidate
    function _addCandidate(string memory _name) public onlyCandidateManager {
        candidates[candidatesCount] = Candidate({
            candidateID: candidatesCount,
            candidateName: _name,
            voteCount: 0
        });
        emit CandidateAdded(candidatesCount, _name);
        candidatesCount++;
    }

    //Vote for your preferred candidate
    function vote(uint256 _candidateID)
        public
        electionIsOngoing
        electionIsActive
    {
        _vote(_candidateID, msg.sender);
    }

    //Enable voters, vote for a candidate off-chain using signatures

    function voteWithSig(
        uint256 _candidateID,
        bytes memory signature,
        address _voter
    ) public electionIsOngoing electionIsActive {
        bytes32 msgHash = keccak256(abi.encodePacked(_candidateID, _voter));
        require(
            SignatureSuite.getSigner(msgHash, signature) == _voter,
            "Invalid Signature"
        );
        //allow vote
        _vote(_candidateID, _voter);
    }

    function _calculateWinner() public onlyAdmin {
        for (uint256 i = 0; i < candidatesCount; i++) {
            if (candidates[i].voteCount > winnerVoteCount) {
                winnerVoteCount = candidates[i].voteCount;
                delete winnerIDs;
                winnerIDs.push(candidates[i].candidateID);
            } else if (candidates[i].voteCount == winnerVoteCount) {
                winnerIDs.push(candidates[i].candidateID);
            }
        }
        (winnerVoteCount, winnerIDs);
    }

    /* setup variables and date to create electon contract
  //  function _setUpElection(string[] memory _nda, string[] memory _candidates)
    //    public
    //{
      //  require(_candidates.length > 0, "You need at least 1 candidate.");
       // name = _nda[0];
       // description = _nda[1];
        //for (uint256 i = 0; i < _candidates.length; i++) {
       //     _addCandidate(_candidates[i]);
        //}
    //}*/

    function _vote(uint256 _candidateID, address _voter)
        public
        onlyValidCandidate(_candidateID)
    {
        require(!voters[_voter], "You have voted already");
        voters[_voter] = true;
        candidates[_candidateID].voteCount++;
        emit VotedFor(_candidateID, candidates[_candidateID].voteCount);
    } 
}