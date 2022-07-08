// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IERC20.sol";
import "./Owner.sol";
import "./ReentrancyGuard.sol";

contract VoteContract is Owner, ReentrancyGuard {

    address public token;
    uint256 public proposalsCount;

    struct Proposal {
        string title;
        string description;
        uint256 startDate;
        uint256 endDate;
        bool status;
    }

    struct ProposalOption {
        string name;
        string image;
        uint256 count;
        bool status; 
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(uint256 => ProposalOption)) public proposalOptions;
    mapping(uint256 => mapping(address => bool)) public proposalVoted;

    event SetTokenContract(
        address tokenContract
    );

    event SetProposal(
        uint256 indexed proposalId,
        string title,
        string description,
        uint256 startDate,
        uint256 endDate
    );

    event SetProposalOptions(
        uint256 indexed proposalId,
        uint256 optionIndex,
        string name,
        string image
    );

    event Vote(
        uint256 indexed proposalId,
        uint256 optionIndex,
        address voter,
        uint256 votes
    );

    constructor(address _tokenContract) {
        setTokenContract(_tokenContract);
    }

    function setTokenContract(address _tokenContract) public isOwner {
        token = _tokenContract;
        emit SetTokenContract(_tokenContract);
    }

    function createProposal(string memory _title, string memory _description, uint256 _startDate, uint256 _endDate) external isOwner {
        uint256 newId = proposalsCount+1;
        proposals[newId] = Proposal(_title, _description, _startDate, _endDate, true);
        proposalsCount+=1;
        emit SetProposal(newId, _title, _description, _startDate, _endDate);
    }

    function setProposal(uint256 _proposalId, string memory _title, string memory _description, uint256 _startDate, uint256 _endDate) external isOwner {
        require(proposals[_proposalId].status, "this proposal does not exist");
        proposals[_proposalId].title = _title;
        proposals[_proposalId].description = _description;
        proposals[_proposalId].startDate = _startDate;
        proposals[_proposalId].endDate = _endDate;
        emit SetProposal(_proposalId, _title, _description, _startDate, _endDate);
    }

    function setProposalOptions(uint256 _proposalId, string[] memory _name, string[] memory _image) external isOwner {
        require(proposals[_proposalId].status, "this proposal does not exist");
        require(_name.length<=10, "the maximum number of options must be less than or equal to 10");
        require(_name.length == _image.length, "the length of name and image must be equal");
        
        for(uint256 i=0; i<_name.length; i++){
            if(!proposalOptions[_proposalId][i].status){
                proposalOptions[_proposalId][i] = ProposalOption(_name[i], _image[i], 0, true);
            }else{
                proposalOptions[_proposalId][i].name = _name[i];
                proposalOptions[_proposalId][i].image = _image[i];
            }
            emit SetProposalOptions(_proposalId, i, _name[i], _image[i]);
        }
    }

    function vote(uint256 _proposalId, uint256 _optionIndex) external nonReentrant {
        require(proposals[_proposalId].status, "this proposal does not exist");
        require(!proposalVoted[_proposalId][msg.sender], "you already voted on this proposal");
        uint256 myVotes = IERC20(token).balanceOf(msg.sender);
        require(myVotes > 0, "you dont have balance to vote");
        require(block.timestamp >= proposals[_proposalId].startDate, "please wait for start date");
        require(block.timestamp <= proposals[_proposalId].endDate, "this proposal is closed");

        proposalVoted[_proposalId][msg.sender] = true;
        proposalOptions[_proposalId][_optionIndex].count += myVotes;
        emit Vote(_proposalId, _optionIndex, msg.sender, myVotes);
    }

}