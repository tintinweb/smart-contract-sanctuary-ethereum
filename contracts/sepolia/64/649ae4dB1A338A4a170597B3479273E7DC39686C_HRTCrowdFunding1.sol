// pragma solidity ^0.8.9;

// contract HRTCrowdFunding {
//     struct Campaign {
//         address owner;
//         string title;
//         string description;
//         uint256 target;
//         uint256 deadline;
//         uint256 amountCollected;
//         string image;
//         address[] donators;
//         uint256[] donations;
//         uint256 minContribution;
//         uint256 withdrawalRequestCount;
//         mapping(uint256 => WithdrawalRequest) withdrawalRequests;
//         mapping(address => bool) approvers;
//     }

//     struct WithdrawalRequest {
//         uint256 id;
//         uint256 amount;
//         string reason;
//         address payable toAddress;
//         uint256 approvalCount;
//         bool executed;
//     }

//     mapping(uint256 => Campaign) public campaigns;
//     uint256 public numberOfCampaigns = 0;

//     function createCampaign(
//         address _owner,
//         string memory _title,
//         string memory _description,
//         uint256 _target,
//         uint256 _deadline,
//         string memory _image,
//         uint256 _minContribution
//     ) public returns (uint256) {
//         require(_deadline > block.timestamp, "The deadline should be a date in the future.");

//         Campaign storage campaign = campaigns[numberOfCampaigns];

//         campaign.owner = _owner;
//         campaign.title = _title;
//         campaign.description = _description;
//         campaign.target = _target;
//         campaign.deadline = _deadline;
//         campaign.amountCollected = 0;
//         campaign.image = _image;
//         campaign.minContribution = _minContribution;

//         numberOfCampaigns++;

//         return numberOfCampaigns - 1;
//     }

//     function donateToCampaign(uint256 _id) public payable {
//         uint256 amount = msg.value;

//         Campaign storage campaign = campaigns[_id];

//         campaign.donators.push(msg.sender);
//         campaign.donations.push(amount);

//         (bool sent, ) = payable(campaign.owner).call{value: amount}("");
//         require(sent, "Failed to send donation to campaign owner.");

//         campaign.amountCollected += amount;

//         if (amount >= campaign.minContribution) {
//             campaign.approvers[msg.sender] = true;
//         }
//     }

//     function createWithdrawalRequest(
//         uint256 _id,
//         uint256 _amount,
//         string memory _reason,
//         address payable _toAddress
//     ) public {
//         Campaign storage campaign = campaigns[_id];

//         require(
//             campaign.approvers[msg.sender] || msg.sender == campaign.owner,
//             "Only approvers and campaign owner can create withdrawal requests."
//         );

//         uint256 requestId = campaign.withdrawalRequestCount;

//         campaign.withdrawalRequests[requestId] = WithdrawalRequest(
//             requestId,
//             _amount,
//             _reason,
//             _toAddress,
//             0,
//             false
//         );

//         campaign.withdrawalRequestCount++;
//     }

//     function approveWithdrawalRequest(uint256 _id, uint256 _requestId) public {
//         Campaign storage campaign = campaigns[_id];
//         WithdrawalRequest storage request = campaign.withdrawalRequests[_requestId];

//         require(
//             campaign.approvers[msg.sender],
//             "Only approvers can approve withdrawal requests."
//         );

//         require(
//             !request.executed,
//             "The withdrawal request has already been executed."
//         );

//         require(
//             !campaign.approvers[request.toAddress],
//             "The recipient of the withdrawal request cannot approve it."
//         );

//         require(
//             !campaign.approvers[campaign.owner],
//             "The campaign owner cannot approve withdrawal requests."
//         );

//         require(
//             !campaign.approvers[msg.sender],
//             "The approver has already approved a withdrawal request."
//         );

//         campaign.approvers[msg.sender] = true;
//         request.approvalCount++;

//         if (request.approvalCount * 2 > countApprovers(campaign)) {
//             executeWithdrawalRequest(campaign, _requestId);
//         }
//     }

//     function denyWithdrawalRequest(uint256 _id, uint256 _requestId) public {
//         Campaign storage campaign = campaigns[_id];
//         WithdrawalRequest storage request = campaign.withdrawalRequests[_requestId];

//         require(
//             campaign.approvers[msg.sender] || msg.sender == campaign.owner,
//             "Only approvers and campaign owner can deny withdrawal requests."
//         );

//         require(
//             !request.executed,
//             "The withdrawal request has already been executed."
//         );

//         delete campaign.withdrawalRequests[_requestId];
//     }

//     function executeWithdrawalRequest(Campaign storage _campaign, uint256 _requestId) internal {
//         WithdrawalRequest storage request = _campaign.withdrawalRequests[_requestId];

//         (bool sent, ) = request.toAddress.call{value: request.amount}("");
//         require(sent, "Failed to send funds to the specified address.");

//         request.executed = true;
//         _campaign.amountCollected -= request.amount;

//         deleteWithdrawalRequests(_campaign);
//     }

//     function deleteWithdrawalRequests(Campaign storage _campaign) internal {
//         uint256 requestCount = _campaign.withdrawalRequestCount;

//         for (uint256 i = 0; i < requestCount; i++) {
//             delete _campaign.withdrawalRequests[i];
//         }

//         _campaign.withdrawalRequestCount = 0;
//     }

//     function countApprovers(Campaign storage _campaign) internal view returns (uint256) {
//         uint256 count = 0;

//         for (uint256 i = 0; i < _campaign.donators.length; i++) {
//             if (_campaign.approvers[_campaign.donators[i]]) {
//                 count++;
//             }
//         }

//         return count;
//     }

//     function getCampaigns() public view returns (CampaignDetails[] memory) {
//         CampaignDetails[] memory allCampaigns = new CampaignDetails[](numberOfCampaigns);

//         for (uint256 i = 0; i < numberOfCampaigns; i++) {
//             Campaign storage campaign = campaigns[i];

//             allCampaigns[i] = CampaignDetails(
//                 campaign.owner,
//                 campaign.title,
//                 campaign.description,
//                 campaign.target,
//                 campaign.deadline,
//                 campaign.amountCollected,
//                 campaign.image,
//                 campaign.donators,
//                 campaign.donations,
//                 campaign.minContribution,
//                 campaign.withdrawalRequestCount
//             );
//         }

//         return allCampaigns;
//     }

//     struct CampaignDetails {
//         address owner;
//         string title;
//         string description;
//         uint256 target;
//         uint256 deadline;
//         uint256 amountCollected;
//         string image;
//         address[] donators;
//         uint256[] donations;
//         uint256 minContribution;
//         uint256 withdrawalRequestCount;
//     }
// }

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract HRTCrowdFunding1{
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
        uint256 minContribution;
        uint256 withdrawalRequestCount;
        mapping(uint256 => WithdrawalRequest) withdrawalRequests;
        mapping(address => bool) approvers;
    }

    struct WithdrawalRequest {
        uint256 id;
        uint256 amount;
        string reason;
        address payable toAddress;
        uint256 approvalCount;
        bool executed;
    }

    mapping(uint256 => Campaign) public campaigns;
    uint256 public numberOfCampaigns = 0;

    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image,
        uint256 _minContribution
    ) public returns (uint256) {
        require(_deadline > block.timestamp, "The deadline should be a date in the future.");

        Campaign storage campaign = campaigns[numberOfCampaigns];

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
        campaign.minContribution = _minContribution;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent, ) = payable(campaign.owner).call{value: amount}("");
        require(sent, "Failed to send donation to campaign owner.");

        campaign.amountCollected += amount;

        if (amount >= campaign.minContribution) {
            campaign.approvers[msg.sender] = true;
        }
    }

    function createWithdrawalRequest(
        uint256 _id,
        uint256 _amount,
        string memory _reason,
        address payable _toAddress
    ) public {
        Campaign storage campaign = campaigns[_id];

        require(
            campaign.approvers[msg.sender] || msg.sender == campaign.owner,
            "Only approvers and campaign owner can create withdrawal requests."
        );

        uint256 requestId = campaign.withdrawalRequestCount;

        campaign.withdrawalRequests[requestId] = WithdrawalRequest(
            requestId,
            _amount,
            _reason,
            _toAddress,
            0,
            false
        );

        campaign.withdrawalRequestCount++;
    }

    function approveWithdrawalRequest(uint256 _id, uint256 _requestId) public {
        Campaign storage campaign = campaigns[_id];
        WithdrawalRequest storage request = campaign.withdrawalRequests[_requestId];

        require(
            campaign.approvers[msg.sender],
            "Only approvers can approve withdrawal requests."
        );

        require(
            !request.executed,
            "The withdrawal request has already been executed."
        );

        require(
            !campaign.approvers[request.toAddress],
            "The recipient of the withdrawal request cannot approve it."
        );

        require(
            !campaign.approvers[campaign.owner],
            "The campaign owner cannot approve withdrawal requests."
        );

        require(
            !campaign.approvers[msg.sender],
            "The approver has already approved a withdrawal request."
        );

        campaign.approvers[msg.sender] = true;
        request.approvalCount++;

        if (request.approvalCount * 2 > countApprovers(campaign)) {
            executeWithdrawalRequest(_id, _requestId);
        }
    }

    function denyWithdrawalRequest(uint256 _id, uint256 _requestId) public {
        Campaign storage campaign = campaigns[_id];
        WithdrawalRequest storage request = campaign.withdrawalRequests[_requestId];

        require(
            campaign.approvers[msg.sender] || msg.sender == campaign.owner,
            "Only approvers and campaign owner can deny withdrawal requests."
        );

        require(
            !request.executed,
            "The withdrawal request has already been executed."
        );

        delete campaign.withdrawalRequests[_requestId];
    }

function executeWithdrawalRequest(uint256 _id, uint256 _requestId) public {
    Campaign storage campaign = campaigns[_id];
    WithdrawalRequest storage request = campaign.withdrawalRequests[_requestId];

    require(
        request.executed == false,
        "The withdrawal request has already been executed."
    );

    require(
        msg.sender == request.toAddress,
        "Only the requester can execute the withdrawal request."
    );

    (bool sent, ) = request.toAddress.call{value: request.amount}("");
    require(sent, "Failed to send funds to the specified address.");

    request.executed = true;
    campaign.amountCollected -= request.amount;

    deleteWithdrawalRequest(campaign, _requestId);
}



   function deleteWithdrawalRequest(Campaign storage _campaign, uint256 _requestId) internal {
        delete _campaign.withdrawalRequests[_requestId];
        _campaign.withdrawalRequestCount--;
    }

    function countApprovers(Campaign storage _campaign) internal view returns (uint256) {
        uint256 count = 0;

        for (uint256 i = 0; i < _campaign.donators.length; i++) {
            if (_campaign.approvers[_campaign.donators[i]]) {
                count++;
            }
        }

        return count;
    }

    function getNumberOfApprovers(uint256 _id) public view returns (uint256) {
        Campaign storage campaign = campaigns[_id];
        uint256 count = 0;

        for (uint256 i = 0; i < campaign.donators.length; i++) {
            if (campaign.approvers[campaign.donators[i]]) {
                count++;
            }
        }

        return count;
    }

    function getNumberOfWithdrawalRequests(uint256 _id) public view returns (uint256) {
        Campaign storage campaign = campaigns[_id];
        return campaign.withdrawalRequestCount;
    }

    function getCampaigns() public view returns (CampaignDetails[] memory) {
        CampaignDetails[] memory allCampaigns = new CampaignDetails[](numberOfCampaigns);

        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage campaign = campaigns[i];

            allCampaigns[i] = CampaignDetails(
                campaign.owner,
                campaign.title,
                campaign.description,
                campaign.target,
                campaign.deadline,
                campaign.amountCollected,
                campaign.image,
                campaign.donators,
                campaign.donations,
                campaign.minContribution,
                campaign.withdrawalRequestCount
            );
        }

        return allCampaigns;
    }

    struct CampaignDetails {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
        uint256 minContribution;
        uint256 withdrawalRequestCount;
    }
}