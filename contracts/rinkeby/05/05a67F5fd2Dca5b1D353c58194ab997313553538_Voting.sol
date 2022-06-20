/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Voting {
    mapping(address => uint256[]) public NftAddressElections; //(NftAddress to electionId-Array)
    mapping(uint256 => ElectionSpecs) public elections; //mapping(electionId => Election) elections;
    mapping(uint256 => mapping(address => bool)) public hasVoted; //    mapping(electionId => mapping(userAddress => boolean)) hasVoted;
    mapping(uint256 => Candidate[]) public electionCandidates; //electionID--> Candidate[]

    //this tracks the number of elections to assign election id's..
    uint256 public electionCounter;

    struct Candidate {
        address candidate; //first only msg.sender, maybe later
        string name;
        string about;
        uint256 electionId;
    }

    struct ElectionSpecs {
        address electioncreator; //msg.sender
        uint256 endOfElectionDate;
        uint256 numberofElected;
        uint256 numberofCastBallots;
    }

    struct Ballot {
        address voter;
        address[] preferences;
    }

    // struct NFT{

    // }
    //MVP:
    //function createNewElection()
    function createNewElection(
        address NFTCollection,
        uint256 endOfElectionDate,
        uint256 numberofElected
    ) external {
        //technically need a security check here again to see if user holds the NFT as could call SC function and input name of NFT Collection
        //create new election
        ElectionSpecs memory newElection = ElectionSpecs(
            msg.sender,
            endOfElectionDate,
            numberofElected,
            0
        );
        //adding election id to mappign of election id's for the NFTaddress
        NftAddressElections[NFTCollection].push(electionCounter);
        //electionId=> electionspec mapping
        elections[electionCounter] = newElection;
        electionCounter++;
    }

    //function addNewCandidate();
    function addNewCandidate(
        address nftAddress,
        uint256 electionId,
        address candidateAddress,
        string calldata candidateName,
        string calldata candidateAbout
    ) external {
        //making candidates struct instance;
        Candidate memory newCandidate = Candidate(
            candidateAddress,
            candidateName,
            candidateAbout,
            electionId
        );
        //push to list of candidates for the election
        electionCandidates[electionId].push(newCandidate);
        NftAddressElections[nftAddress].push(electionId);
    }

    //function vote()

    //function mintWinnerNFTWithResults() //laterstage ?

    //optional:
    //function removeCandidatebeforeFirstVote()
    //function deleteElectionbeforeFirstVote()
    //function requireStaking()
    //function sendBackStake()
    //function approveCandidateByCreator()
    //function setCandidateNFT()

    //the algorithm:
    //once the cutoff date arrives, trigger the voting

    //1.Step sort ballots/user votes according to first preferences and count them.
    //2.Step Determine total Number of ballots. Calculate quota for election (Droop quota).
    //3.Step distribute surplus ballots to other next preferred candidates.
    //4.Step eleminate candidates with the least votes and distribute their ballots to peoples next preference
    //5. Continue transferring ballots form winners/loosers until all winners are selected

    //collection of things that could go wrong:
    //people can pretend to run as someone else -> proof of  humanity?

    //

    //Voting functions

    // function castBallot(uint256 _electionId, address[] calldata _preferences)
    //     public
    // {
    //     Ballot storage ballot = ballotBox[_electionId].push();
    //     ballot.voter = msg.sender;
    //     ballot.preferences = _preferences;
    //     elections[_electionId].numberofCastBallots++;
    // }

    // function getVote(uint256 _electionId, uint256 i)
    //     public
    //     view
    //     returns (Vote memory)
    // {
    //     return ballotBox[_electionId][i];
    // }

    // //5.1.1 Count all the voting papers to determine the total number of votes cast.
    // uint256 totalNumberofVotsCast = elections[_electionId].numberofCastBallots;
    // //5.1.2 Sort the voting papers into first preferences. (No invalid votes coming from Frontend)

    // //How to store the ballots?
    // //First idea: Map the electionId to an array of Ballots. The ballots are stored in a dynamic array
    // mapping(uint256 => Ballot[]) public ballotBox;

    // //how to pull out the first preference:
    // function sortBallots(uint256 _electionId) public {
    //     for (uint256 i; i < ballotBox[electionId].length; i++) {
    //         ballot = ballotBox[electionId][i];
    //     }
    // }
}