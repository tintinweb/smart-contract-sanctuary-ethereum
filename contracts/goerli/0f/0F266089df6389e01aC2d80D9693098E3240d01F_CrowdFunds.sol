// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interfaces/ICrowdFunds.sol";

// import "hardhat/console.sol";

contract CrowdFunds is ICrowdFunds {
    uint256 public fundCount = 0;

    // Creator address => currently active fund id
    mapping(address => uint256) public currentlyActiveFundId;

    // Fund id => fund state
    mapping(uint256 => Fund) public funds;

    // fund id => (contributor id => amount of contribution)
    mapping(uint256 => mapping(address => uint256)) public contributions;

    modifier fundExists(uint256 _fundId) {
        if (funds[_fundId].creator == address(0)) {
            revert FundNotFound();
        }
        _;
    }

    modifier fundIsActive(uint256 _fundId) {
        Fund memory fund = funds[_fundId];
        if (
            !fund.active ||
            fund.deadlineDate < block.timestamp ||
            fund.balance >= fund.goalAmount
        ) {
            revert FundIsNotActive();
        }
        _;
    }

    function createFund(FundParams calldata _fundParams)
        external
        payable
        override
    {
        uint256 fundId = currentlyActiveFundId[msg.sender];

        // Check if msg.sender has an active funding
        if (fundId > 0 && funds[fundId].deadlineDate > block.timestamp) {
            revert ForbiddenFundCreation();
        }

        // Check if deadline date is set more than a year from now
        if (
            _fundParams.deadlineDate < block.timestamp ||
            _fundParams.deadlineDate - block.timestamp > 52 weeks
        ) {
            revert InvalidDeadlineValue();
        }

        fundCount += 1;
        currentlyActiveFundId[msg.sender] = fundCount;

        Fund memory newFund = Fund(
            msg.sender,
            true,
            0,
            _fundParams.title,
            _fundParams.description,
            _fundParams.goalAmount,
            _fundParams.deadlineDate
        );
        funds[fundCount] = newFund;

        emit FundCreated(fundCount, msg.sender);
    }

    function contributeToFund(uint256 _fundId)
        external
        payable
        override
        fundExists(_fundId)
        fundIsActive(_fundId)
    {
        Fund memory fund = funds[_fundId];

        if (fund.creator == msg.sender) {
            revert ForbiddenContributor();
        }

        if (fund.goalAmount > fund.balance + msg.value) {
            // Update fund's balance
            funds[_fundId].balance += msg.value;
            // Update contribution amount
            contributions[_fundId][msg.sender] += msg.value;

            emit ContributionReceived(msg.sender, _fundId, msg.value);
        } else {
            uint256 contributionAmount = fund.goalAmount - fund.balance;
            // Update fund's balance
            funds[_fundId].balance += contributionAmount;
            // Update contribution amount
            contributions[_fundId][msg.sender] += msg.value;

            payable(msg.sender).transfer(msg.value - contributionAmount);

            emit FundGoalReached(
                msg.sender,
                fund.creator,
                _fundId,
                contributionAmount
            );
        }
    }

    function withdrawFund(uint256 _fundId, uint _amount)
        external
        override
        fundExists(_fundId)
        fundIsActive(_fundId)
    {
        if (contributions[_fundId][msg.sender] < _amount) {
            revert InsufficientFundToWithdraw();
        }

        payable(msg.sender).transfer(_amount);
        funds[_fundId].balance -= _amount;
        contributions[_fundId][msg.sender] -= _amount;

        emit ContributionWithdrawn(msg.sender, _fundId, _amount);
    }

    function claimFund()
        external
        override
        fundExists(currentlyActiveFundId[msg.sender])
    {
        uint256 fundId = currentlyActiveFundId[msg.sender];

        Fund memory fund = funds[fundId];

        if (fund.balance < fund.goalAmount) {
            revert FundGoalNotReached();
        }

        payable(fund.creator).transfer(fund.balance);
        funds[fundId].active = false;
        funds[fundId].balance = 0;
        delete currentlyActiveFundId[fund.creator];

        emit FundClaimed(fund.creator, fund.balance, fundId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ICrowdFunds {
    struct FundParams {
        string title;
        string description;
        uint128 goalAmount;
        uint256 deadlineDate;
    }

    struct Fund {
        address creator;
        bool active;
        uint balance;
        string title;
        string description;
        uint128 goalAmount;
        uint256 deadlineDate;
    }

    /// @notice allow a user to create a fund
    /// @param _fundParams params requried to create a valid fund
    function createFund(FundParams calldata _fundParams) external payable;

    /// @notice let contrubutors contribute to a specified fund
    /// @param _fundId the fund id that contribute to
    function contributeToFund(uint256 _fundId) external payable;

    /// @notice claim all the fund
    function claimFund() external;

    /// @notice let contributors to withdraw fundings of a given fund id
    /// @param _fundId the fund that the contributor wish to withdraw from
    /// @param _amount the amount of funding the contributor wish to withdraw
    function withdrawFund(uint256 _fundId, uint _amount) external;

    /// event emit after a fund is created
    event FundCreated(uint256 indexed fundId, address indexed creator);

    /// event emit after the send has successfully contributed the fund
    event ContributionReceived(
        address indexed contributor,
        uint256 indexed fundId,
        uint256 amount
    );

    /// event emit when a contributor withdrawn some fund of a specific funding
    event ContributionWithdrawn(
        address indexed contributor,
        uint256 indexed fundId,
        uint256 amount
    );

    /// event emit when the fund has reached the goal amount
    event FundGoalReached(
        address indexed contributor,
        address indexed creator,
        uint256 indexed fundId,
        uint256 amount
    );

    /// event emit when the creator of the fund claims the funding
    event FundClaimed(
        address indexed creator,
        uint256 balance,
        uint256 indexed fundId
    );

    /// @notice Fund id not found
    error FundNotFound();

    // @notice Error Fund state is not active
    error FundIsNotActive();

    /// @notice Fund creation is not allowed
    error ForbiddenFundCreation();

    /// @notice Invalid value input for deadline
    error InvalidDeadlineValue();

    /// @notice Fund creator cannot contribute their own fund
    error ForbiddenContributor();

    /// @notice not enough fund to withdraw
    error InsufficientFundToWithdraw();

    /// @notice No fund can be withdrawn by contributor
    error ForbiddenWithdraw();

    // @notice Fund goal amount is not reached
    error FundGoalNotReached();
}