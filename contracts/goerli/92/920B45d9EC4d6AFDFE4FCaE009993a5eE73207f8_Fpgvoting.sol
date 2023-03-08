// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Fpgvoting {
    struct Candidate {
        string candidateId;
        address[] voters;
    }

    mapping(string => Candidate) public candidates;

    // struct Vote {
    //     address[] voters;
    // }

    struct Campaign {
        address owner;
        uint256 startTime;
        uint256 deadline;
        Candidate[] candidates;
        string image;
    }

    mapping(string => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;

    function createCampaign(
        string memory _campaignId,
        uint256 _startTime,
        uint256 _deadline,
        string memory _image,
        string[] memory _candidates
    ) public payable returns (string memory) {
        // checking
        require(
            _startTime > block.timestamp,
            "The start time should be a date in the future."
        );

        // checking
        require(
            _deadline > _startTime,
            "The deadline should be a date in the future."
        );

        // checking
        require(
            _deadline > block.timestamp,
            "The deadline should be a date in the future."
        );

        require(_candidates.length > 0, "Error");

        Campaign storage campaign = campaigns[_campaignId];
        campaign.owner = msg.sender;
        campaign.startTime = _startTime;
        campaign.deadline = _deadline;
        campaign.image = _image;

        for (uint i = 0; i < _candidates.length; i++) {
            Candidate storage candidate = candidates[_candidates[i]];
            candidate.candidateId = _candidates[i];
            campaign.candidates.push(candidate);
        }

        return _campaignId;
    }

    function Vote(string memory _candidateId) public payable {
        bool doesListContainElement = false;

        for (uint i = 0; i < candidates[_candidateId].voters.length; i++) {
            if (msg.sender == candidates[_candidateId].voters[i]) {
                doesListContainElement = true;

                break;
            }
        }

        require(!doesListContainElement, "You have voted");

        candidates[_candidateId].voters.push(msg.sender);
    }

    // function getDonators(
    //     uint256 _id
    // ) public view returns (address[] memory, uint256[] memory) {
    //     return (campaigns[_id].donators, campaigns[_id].donations);
    // }

    // function getCampaigns() public view returns (Campaign[] memory) {
    //     Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

    //     for (uint i = 0; i < numberOfCampaigns; i++) {
    //         Campaign storage item = campaigns[i];

    //         allCampaigns[i] = item;
    //     }

    //     return allCampaigns;
    // }
}