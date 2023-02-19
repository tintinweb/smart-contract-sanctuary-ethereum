// // SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./Stake.sol";

error Campaign__SendMinFund();
error Campaign__NotOwner();
error Campaign__NotEnoughToWithdraw();
error Campaign__RequestIsUnderProcess();
error Campaign__RequestRejected();
error Campaign__NotAnEligiableContributer();
error Campaign__ContributionTransactionFailed();
error Campaign__WithdrawTransactionFailed();
error Campaign__NoEnoughAmount();
error Campaign__NotAContributer();

contract Campaign is Stake {
    mapping(address => uint256) public s_contributerFund;
    uint256 private immutable i_campaignGoal;
    uint256 private immutable i_minContribution;
    uint256 private s_TotalFunded;
    address private s_owner;
    Request[] private s_requests;
    address[] private s_contributers;

    event FundWithdrawed(uint256 amountWithdrawed);
    event OwnershipTransfered(address from, address to);
    event FundTransfered(address from, uint256 fundedAmount);
    event RequestApplied(uint256 requestIndex);
    event RequestResult(uint256 requestIndex, bool approved);

    constructor(uint256 campaignGoal, uint256 minContribution) {
        i_campaignGoal = campaignGoal;
        i_minContribution = minContribution;
        s_owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != s_owner) {
            revert Campaign__NotOwner();
        }
        _;
    }

    modifier onlyContributers() {
        if (s_contributerFund[msg.sender] == 0) {
            revert Campaign__NotAContributer();
        }
        _;
    }

    modifier permissionIssued(uint256 requestIndex) {
        executeResult(requestIndex);
        if (
            getPermissionStatus(s_requests[requestIndex]) ==
            CampaignLib.permission.PROCESSING
        ) {
            revert Campaign__RequestIsUnderProcess();
        }
        if (
            getPermissionStatus(s_requests[requestIndex]) ==
            CampaignLib.permission.REJECTED
        ) {
            revert Campaign__RequestRejected();
        }
        _;
    }

    function contribute() public payable {
        if (msg.value < i_minContribution) {
            revert Campaign__SendMinFund();
        }
        (bool sent, ) = address(this).call{value: msg.value}("");

        if (!sent) {
            revert Campaign__ContributionTransactionFailed();
        }

        emit FundTransfered(msg.sender, msg.value);

        s_contributerFund[msg.sender] += msg.value;
        s_TotalFunded += msg.value;
        s_contributers.push(msg.sender);
    }

    function withdraw(
        uint256 requestIndex
    ) public payable onlyOwner permissionIssued(requestIndex) {
        uint256 amount = getRequestedAmount(s_requests[requestIndex]);
        if (address(this).balance < amount) {
            revert Campaign__NotEnoughToWithdraw();
        }
        (bool sent, ) = s_owner.call{value: amount}("");

        if (!sent) {
            revert Campaign__WithdrawTransactionFailed();
        }

        setRecieved(s_requests[requestIndex]);
        emit FundWithdrawed(amount);
    }

    function makeRequest(
        uint256 _durationOfRequest,
        uint256 _withdrawAmount
    ) public onlyOwner {
        // Stake happens here

        Request storage request = s_requests.push();
        request.durationOfRequest = _durationOfRequest;
        request.requestedAmount = _withdrawAmount;
        request.requestedTime = block.timestamp;
        request.totalAcceptVote = 0;
        request.totalRejectVote = 0;
        request.amountRecieved = false;
        request.campaignAddress = address(this);
        request.currentStatus = CampaignLib.permission.PROCESSING;
        emit RequestApplied(s_requests.length - 1);
    }

    function stakeInRequest(uint256 requestId, CampaignLib.vote myVote) public {
        uint256 weightage = calcualtePercent(
            s_contributerFund[msg.sender],
            10000,
            s_TotalFunded
        );
        stake(s_requests[requestId], myVote, msg.sender, weightage);
    }

    function executeResult(uint256 requestIndex) public {
        result(s_requests[requestIndex]);

        emit RequestResult(
            requestIndex,
            getPermissionStatus(s_requests[requestIndex]) ==
                CampaignLib.permission.ACCEPTED
        );
    }

    // Getter and setter functions

    function getContributors() public view returns (address[] memory) {
        return s_contributers;
    }

    function getTotalFund() public view returns (uint256) {
        return s_TotalFunded;
    }

    function getFundByAddress(
        address contributer
    ) public view returns (uint256) {
        return s_contributerFund[contributer];
    }

    function getOwnerAddress() public view returns (address) {
        return s_owner;
    }

    function transferOwnerShip(address to) public onlyOwner {
        s_owner = to;
        emit OwnershipTransfered(msg.sender, to);
    }

    function getCurrentFundInContract() public view returns (uint256) {
        return address(this).balance;
    }

    function getContributorsFundAmount(
        address contributerAddress
    ) public view returns (uint256) {
        return s_contributerFund[contributerAddress];
    }

    function getCampaignGoal() public view returns (uint256) {
        return i_campaignGoal;
    }

    function getTotalContributers() public view returns (uint256) {
        return s_contributers.length;
    }

    function calcualtePercent(
        uint256 amount,
        uint256 bps,
        uint256 totalAmount
    ) internal pure returns (uint256) {
        if (amount * bps < totalAmount) {
            revert Campaign__NoEnoughAmount();
        }
        return (amount * bps) / totalAmount;
    }

    // uint256 durationOfRequest;
    //     uint256 requestedAmount;
    //     uint256 requestedTime;
    //     address campaignAddress;
    //     // Voting variables
    //     uint256 totalAcceptVote;
    //     uint256 totalRejectVote;
    //     // status
    //     CampaignLib.permission currentStatus;
    //     bool amountRecieved;

    function getRequestInfo(
        uint256 requestId
    ) public view returns (uint256, uint256, uint256, uint256, bool) {
        return (
            s_requests[requestId].requestedAmount,
            s_requests[requestId].requestedTime,
            s_requests[requestId].durationOfRequest,
            uint256(s_requests[requestId].currentStatus),
            s_requests[requestId].amountRecieved
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library CampaignLib {
    enum permission {
        PROCESSING,
        ACCEPTED,
        REJECTED
    }

    enum vote {
        ACCEPT,
        REJECT
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./Campaign.sol";

contract CrowdFunding {
    mapping(address => Campaign[]) private s_campaigns;
    address[] private s_campaignCreaters;
    uint256 private s_totalCampaign;

    event CampaignCreated(
        address campaignCreator,
        uint256 campaginId,
        address campaignAddress
    );

    function createCampaign(
        uint256 _campaignGoal,
        uint256 _minContribution
    ) public {
        Campaign campaign = new Campaign(_campaignGoal, _minContribution);
        campaign.transferOwnerShip(msg.sender);

        s_campaigns[msg.sender].push(campaign);
        s_campaignCreaters.push(msg.sender);

        s_totalCampaign += 1;

        emit CampaignCreated(
            msg.sender,
            s_campaigns[msg.sender].length,
            address(campaign)
        );
    }

    function getCampaign(
        address owner,
        uint256 campaignId
    ) public view returns (address) {
        return address(s_campaigns[owner][campaignId]);
    }

    function getAllCampaignOfOwner(
        address owner
    ) public view returns (address[] memory) {
        uint256 totalCampaign = s_campaigns[owner].length;
        address[] memory campaigns = new address[](totalCampaign);
        for (uint i = 0; i < totalCampaign; i++) {
            campaigns[i] = address(s_campaigns[owner][i]);
        }
        return campaigns;
    }

    function getTotalCampaign() public view returns (uint256) {
        return s_totalCampaign;
    }

    // Implement a function to get s_campagins
    // function getAllCampaign() public view returns () {

    // }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./CampaignLib.sol";

// TO DO
//
// Start the stake event
// contributers can vote
// End the event
// Send the result and withdraw if needed
//

error Stake__DeadlineNotReached();
error Stake__DeadLineReached();
error Stake__ContributerAlreadyVoted();

contract Stake {
    struct Request {
        mapping(address => bool) contributersVoted;
        uint256 durationOfRequest;
        uint256 requestedAmount;
        uint256 requestedTime;
        address campaignAddress;
        // Voting variables
        uint256 totalAcceptVote;
        uint256 totalRejectVote;
        // status
        CampaignLib.permission currentStatus;
        bool amountRecieved;
    }

    modifier deadlineReached(Request storage request, bool requireReached) {
        uint256 timeRemaining = timeLeft(request);
        if (requireReached) {
            if (timeRemaining > 0) {
                revert Stake__DeadlineNotReached();
            }
            // require(timeRemaining == 0, "Deadline has not reached");
        } else {
            if (timeRemaining == 0) {
                revert Stake__DeadLineReached();
            }
            // require(timeRemaining > 0, "Deadline is already reached");
        }
        _;
    }

    // Add a modifier if all the contributers voted

    function stake(
        Request storage request,
        CampaignLib.vote myVote,
        address contributer,
        uint256 weightage
    ) internal deadlineReached(request, false) {
        if (request.contributersVoted[contributer]) {
            revert Stake__ContributerAlreadyVoted();
        }
        request.contributersVoted[contributer] = true;
        if (myVote == CampaignLib.vote.ACCEPT) {
            request.totalAcceptVote += weightage;
        } else {
            request.totalRejectVote += weightage;
        }
    }

    // Make a function that gets call for chainlink

    function result(
        Request storage request
    ) internal deadlineReached(request, true) {
        if (request.totalAcceptVote > request.totalRejectVote) {
            request.currentStatus = CampaignLib.permission.ACCEPTED;
        } else {
            request.currentStatus = CampaignLib.permission.REJECTED;
        }
    }

    function timeLeft(
        Request storage request
    ) internal view returns (uint256 timeleft) {
        uint256 deadline = request.requestedTime + request.durationOfRequest;
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    function getCurrentStatus(
        Request storage request
    ) internal view returns (CampaignLib.permission) {
        return request.currentStatus;
    }

    function getRequestedAmount(
        Request storage request
    ) internal view returns (uint256) {
        return request.requestedAmount;
    }

    function setRecieved(Request storage request) internal {
        request.amountRecieved = true;
    }

    function getPermissionStatus(
        Request storage request
    ) internal view returns (CampaignLib.permission) {
        return request.currentStatus;
    }
}