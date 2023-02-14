// // SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./Stake.sol";
import "./Library.sol";

error Campagin__SendMinFund();
error Campagin__NotOwner();
error Campagin__NotEnoughToWithdraw();
error Campagin__RequestIsUnderProcess();
error Campagin__RequestRejected();
error CrowdFunding__RequestRejected();

contract CrowdFunding {
    mapping(address => uint256) public s_contributerFund;
    uint256 private immutable i_campaginGoal;
    uint256 private immutable i_minContribution;
    uint256 private s_TotalFunded;
    address private s_owner;
    Stake[] private s_requestes;
    address[] private s_contributers;

    event FundWithdrawed(uint256 amountWithdrawed);
    event OwnershipTransfered(address from, address to);
    event FundTransfered(address from, uint256 fundedAmount);
    event RequestApplied(Stake request);

    constructor(uint256 campaginGoal, uint256 minContribution) {
        i_campaginGoal = campaginGoal;
        i_minContribution = minContribution;
        s_owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != s_owner) {
            revert Campagin__NotOwner();
        }
        _;
    }

    modifier permissionIssued(uint256 requestIndex) {
        if (
            s_requestes[requestIndex].getPermission() ==
            withdrawLib.withdrawPermission.PROCESSING
        ) {
            revert Campagin__RequestIsUnderProcess();
        }
        if (
            s_requestes[requestIndex].getPermission() ==
            withdrawLib.withdrawPermission.REJECTED
        ) {
            revert Campagin__RequestRejected();
        }
        _;
    }

    function contribute() public payable {
        if (msg.value < i_minContribution) {
            revert Campagin__SendMinFund();
        }
        (bool send, ) = address(this).call{value: msg.value}("");

        emit FundTransfered(msg.sender, msg.value);

        s_contributerFund[msg.sender] += msg.value;
        s_TotalFunded += msg.value;
        s_contributers.push(msg.sender);
    }

    // function withdraw() public payable onlyOwner {
    //     if (address(this).balance <= 0) {
    //         revert Campagin__NotEnoughToWithdraw();
    //     }
    //     uint256 withdrawAmount = address(this).balance;
    //     (bool sent, ) = s_owner.call{value: address(this).balance}("");
    //     emit FundWithdrawed(withdrawAmount);
    // }

    function withdraw(
        uint256 requestIndex
    ) public payable onlyOwner permissionIssued(requestIndex) {
        uint256 amount = s_requestes[requestIndex].getRequestedAmount();
        if (address(this).balance < amount) {
            revert Campagin__NotEnoughToWithdraw();
        }
        (bool sent, ) = s_owner.call{value: amount}("");
        s_requestes[requestIndex].setRecieved();
        emit FundWithdrawed(amount);
    }

    function makeRequest(
        uint256 durationOfRequest,
        uint256 withdrawAmount,
        uint256 minContributionToVote
    ) public {
        // Stake happens here

        Stake request = new Stake(
            address(this),
            durationOfRequest,
            withdrawAmount,
            minContributionToVote
        );
        s_requestes.push(request);
        emit RequestApplied(request);
    }

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library withdrawLib {
    enum withdrawPermission {
        PROCESSING,
        ACCEPTED,
        REJECTED
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./Library.sol";

// TO DO
//
// Start the stake event
// contributers can vote
// End the event
// Send the result and withdraw if needed

contract Stake {
    enum vote {
        ACCEPT,
        REJECT,
        NEUTRAL
    }

    mapping(address => bool) private s_contributersVoted;
    address private immutable i_campaginAddress;
    uint256 private immutable i_minContributionToVote;
    uint256 private s_durationOfRequest;
    uint256 private s_requestedAmount;
    uint256 private s_requestedTime;

    uint256 private s_totalNeutralVote;
    uint256 private s_totalAcceptVote;
    uint256 private s_totalRejectVote;

    withdrawLib.withdrawPermission private s_permission;

    bool private s_recieved;

    constructor(
        address campaginAddress,
        uint256 duration,
        uint256 requestedAmount,
        uint256 minContributionToVote
    ) {
        i_campaginAddress = campaginAddress;
        i_minContributionToVote = minContributionToVote;
        s_durationOfRequest = duration;
        s_permission = withdrawLib.withdrawPermission.PROCESSING;
        s_requestedAmount = requestedAmount;
        s_requestedTime = block.timestamp;
        s_recieved = false;
    }

    modifier deadlineReached(bool requireReached) {
        uint256 timeRemaining = timeLeft();
        if (requireReached) {
            require(timeRemaining == 0, "Deadline is not reached yet");
        } else {
            require(timeRemaining > 0, "Deadline is already reached");
        }
        _;
    }

    // Add a modifier if all the contributers voted

    function stake(vote myVote) public deadlineReached(false) {
        if (myVote == vote.ACCEPT) {
            s_totalAcceptVote += 1;
        } else if (myVote == vote.NEUTRAL) {
            s_totalNeutralVote += 1;
        } else {
            s_totalRejectVote;
        }
    }

    // Make a function that gets call for chainlink

    function result() public deadlineReached(true) {
        if (s_totalAcceptVote > s_totalRejectVote) {
            s_permission = withdrawLib.withdrawPermission.ACCEPTED;
        } else {
            s_permission = withdrawLib.withdrawPermission.REJECTED;
        }
    }

    function timeLeft() public view returns (uint256 timeleft) {
        uint256 deadline = s_requestedTime + s_durationOfRequest;
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    function getPermission()
        public
        view
        returns (withdrawLib.withdrawPermission)
    {
        return s_permission;
    }

    function getRequestedAmount() public view returns (uint256) {
        return s_requestedAmount;
    }

    function setRecieved() public {
        s_recieved = true;
    }
}