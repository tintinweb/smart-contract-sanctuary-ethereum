// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/Counters.sol";

contract CharityPlatform {
    using Counters for Counters.Counter;

    Counters.Counter internal _campaignIdCounter;

    struct Campaign {
        uint256 id;
        string name;
        string description;
        uint256 fundingGoal;
        uint64 deadline;
        address campaignCreator;
    }

    mapping(uint256 => Campaign) campaigns;
    mapping(uint256 => uint256) donations;
    // campaignId => (donatorAddress => donationAmount)
    mapping(uint256 => mapping(address => uint256)) donationsHistory;

    event FullAmountDonated(
        uint256 donationAmount,
        address donator,
        uint256 campaignId
    );
    event PartialAmountDonated(
        uint256 donationAmount,
        uint256 amountReturned,
        address donator,
        uint256 campaignId
    );

    event FundsCollected(uint256 id, uint256 amount, address withdrawAddress);

    function createCampaign(
        string memory name,
        string memory description,
        uint256 fundingGoal,
        uint64 deadline
    ) external {
        require(deadline > block.timestamp, "Deadline is in the past");

        uint256 id = _campaignIdCounter.current();
        _campaignIdCounter.increment();

        Campaign memory newCampaign = Campaign(
            id,
            name,
            description,
            fundingGoal,
            deadline,
            msg.sender
        );
        campaigns[id] = newCampaign;
    }

    function donate(uint256 id) external payable {
        uint256 donation = msg.value;

        require(donation > 0, "Invalid donation");
        require(campaigns[id].deadline != 0, "Invalid campaign");

        bool isExceedingGoal = donations[id] + donation >
            campaigns[id].fundingGoal;

        if (isExceedingGoal) {
            uint256 amountToReturn = donations[id] +
                donation -
                campaigns[id].fundingGoal;

            // goal reached
            donations[id] = campaigns[id].fundingGoal;
            donationsHistory[id][msg.sender] += (donation - amountToReturn);

            // return the exceeding amount
            (bool success, ) = msg.sender.call{value: amountToReturn}("");

            require(success, "Donation failed");

            emit PartialAmountDonated(donation, amountToReturn, msg.sender, id);

            return;
        }

        emit FullAmountDonated(donation, msg.sender, id);

        donations[id] += donation;
        donationsHistory[id][msg.sender] += donation;
    }

    function collectFunds(uint256 id, address toWithdraw) external {
        // access control
        uint256 goal = campaigns[id].fundingGoal;
        require(msg.sender == campaigns[id].campaignCreator, "Access denied");
        require(donations[id] == goal, "Campaign failed to reach goal");

        donations[id] = 0;

        (bool success, ) = payable(toWithdraw).call{value: goal}("");
        require(success, "Funds collection failed");
        emit FundsCollected(id, goal, toWithdraw);
    }

    function refund(uint256 id) external {
        require(
            campaigns[id].deadline <= block.timestamp,
            "Campaign is in progress"
        );
        require(
            donations[id] != campaigns[id].fundingGoal,
            "Campaign goal reached"
        );
        uint256 refundAmount = donationsHistory[id][msg.sender];

        require(refundAmount != 0, "Nothing to refund");

        donationsHistory[id][msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
        require(success, "Refund failed");
    }

    function getCamapignDetails(
        uint256 id
    )
        external
        view
        returns (uint256, string memory, string memory, uint256, uint64)
    {
        Campaign memory campaign = campaigns[id];

        return (
            campaign.id,
            campaign.name,
            campaign.description,
            campaign.fundingGoal,
            campaign.deadline
        );
    }

    function getDonationAmountForCampaign(
        uint id
    ) external view returns (uint256) {
        return donations[id];
    }

    function getDonationAmountForUser(
        uint256 id,
        address user
    ) external view returns (uint256) {
        return donationsHistory[id][user];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}