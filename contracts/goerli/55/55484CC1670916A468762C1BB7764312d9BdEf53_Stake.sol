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

import "./CampaignLib.sol";

// TO DO
//
// Start the stake event
// contributers can vote
// End the event
// Send the result and withdraw if needed

error Stake__DeadlineNotReached();
error Stake__DeadLineReached();

contract Stake {
    struct Request {
        mapping(address => bool) contributersVoted;
        uint256 minContributionToVote;
        uint256 durationOfRequest;
        uint256 requestedAmount;
        uint256 requestedTime;
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
        CampaignLib.vote myVote
    ) internal deadlineReached(request, false) {
        if (myVote == CampaignLib.vote.ACCEPT) {
            request.totalAcceptVote += 1;
        } else {
            request.totalRejectVote += 1;
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

    function getMinimumContribution(
        Request storage request
    ) internal view returns (uint256) {
        return request.minContributionToVote;
    }

    function getPermissionStatus(
        Request storage request
    ) internal view returns (CampaignLib.permission) {
        return request.currentStatus;
    }
}