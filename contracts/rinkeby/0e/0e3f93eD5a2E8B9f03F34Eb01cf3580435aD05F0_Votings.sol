/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Votings {
    struct Campaign {
        bool ended;
        uint32 duration;
        uint startAt;
        uint256 bid;
        uint256 founded;
        uint256 commonVoteCount;
        uint256 maxVotesValue;
        uint256 prize;
        mapping(address => bool) voters;
        mapping(address => bool) candidates;
        mapping(address => uint256) voteCounter;
        mapping(address => uint256) prizeSum;
        address[] candidatesList;
        address[] winnersList;
    }

    uint8 public commissionPercent = 10;
    address public owner;
    uint256 public ownerBalance;
    uint256 currentCampaignIndex;

    mapping(uint256 => Campaign) campaigns;

    event newCampaignCreated(
        uint256 indexed campaignId,
        uint32 duration,
        uint256 bid,
        address indexed iniciator
    );

    event campaingnFinished(
        uint256 indexed campaignId,
        uint256 prize,
        address[] winnersList
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    function createCampaign(
        address[] memory _candidateList,
        uint256 _bid,
        uint32 _duration
    ) external returns (uint256) {
        require(_candidateList.length > 0, "Add more candidates");
        Campaign storage c = campaigns[currentCampaignIndex];
        c.startAt = block.timestamp;
        c.bid = _bid;
        c.duration = _duration;

        for (uint256 i = 0; i < _candidateList.length; i++) {
            //addresses must not be duplicated
            if (!c.candidates[_candidateList[i]]) {
                c.candidates[_candidateList[i]] = true;
                c.candidatesList.push(_candidateList[i]);
            }
        }

        emit newCampaignCreated(
            currentCampaignIndex,
            _duration,
            _bid,
            msg.sender
        );
        return currentCampaignIndex++;
    }

    function finishCampaign(uint256 _index) external {
        Campaign storage c = campaigns[_index];

        require(
            (c.startAt + c.duration) <= block.timestamp,
            "Time is not up yet."
        );
        require(c.ended == false, "Voting already ended");

        c.ended = true;
        if (c.commonVoteCount > 0) {
            uint256 comission = ((campaigns[_index].founded *
                commissionPercent) / 100);
            ownerBalance += comission;
            c.prize = c.founded - comission;
            uint256 prize = c.prize / c.winnersList.length;
            //every vinner receive its prize
            for (uint256 i = 0; i < c.winnersList.length; i++) {
                payable(c.winnersList[i]).transfer(prize);
            }
        }
        emit campaingnFinished(_index, c.founded, c.winnersList);
    }

    function vote(uint256 _index, address _candidateAddress) external payable {
        Campaign storage c = campaigns[_index];
        require(c.startAt + c.duration > block.timestamp, "Voting time is up");
        require(c.candidates[_candidateAddress], "Unknown candidate");
        require(!c.voters[msg.sender], "You have already voted");
        require((msg.value == c.bid), "Wrong bid");
        c.voters[msg.sender] = true;
        c.founded += c.bid;
        c.voteCounter[_candidateAddress] += 1;
        if (c.voteCounter[_candidateAddress] > c.maxVotesValue) {
            c.maxVotesValue = c.voteCounter[_candidateAddress];
            c.winnersList = [_candidateAddress];
        } else if (c.voteCounter[_candidateAddress] == c.maxVotesValue) {
            c.winnersList.push(_candidateAddress);
        }
        c.commonVoteCount += 1;
    }

    function comissionWithdraw(uint256 _amount) external onlyOwner {
        require(_amount <= ownerBalance, "insufficient funds");
        ownerBalance -= _amount;
        payable(owner).transfer(_amount);
    }

    function setComissionPercent(uint8 _newComissionPercent)
        external
        onlyOwner
    {
        commissionPercent = _newComissionPercent;
    }

    function getVotesCount(uint256 _campaignId)
        external
        view
        returns (uint256)
    {
        return campaigns[_campaignId].commonVoteCount;
    }

    function getComissionPercent() external view returns (uint8) {
        return commissionPercent;
    }

    function getCampaignInformation(uint256 _campaignId)
        external
        view
        returns (
            bool,
            uint256,
            uint32,
            uint256,
            address[] memory,
            uint256,
            uint256
        )
    {
        Campaign storage c = campaigns[_campaignId];
        return (
            c.ended,
            c.startAt,
            c.duration,
            c.bid,
            c.candidatesList,
            c.commonVoteCount,
            c.founded
        );
    }

    function getVoteCounterOfCandidate(uint256 _id, address _candidate)
        external
        view
        returns (uint256)
    {
        return campaigns[_id].voteCounter[_candidate];
    }

    function getOwnerBalance() external view returns (uint256) {
        return ownerBalance;
    }
}