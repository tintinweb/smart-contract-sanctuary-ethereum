// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        // Owner of the campaign.
        address owner;
        // title of the campaign.
        string title;
        // Campaign description.
        string description;
        // Campaign target amount.
        uint256 target;
        // Campaign deadline.
        uint256 deadline;
        // Total amount collected through Campaign.
        uint256 AmountCollected;
        // Image of campaign.
        string image;
        /* Instead of mapping array is used to return the donators & dontions amount on calling 'getDonators' function & to get rid of nested mapping */
        // Array of donators.
        address[] donators;
        // Amount donated by donators.
        uint256[] donations;
        // To ask if the user allows the campaign owner to withdraw the funds even if the target is not met.
        int256[] agree;
    }

    mapping(uint256 => Campaign) public campaigns;

    // to remove the campaign once it is finished;
    function destroyCampaign(uint256 _id) internal {
        delete campaigns[_id];
    }

    // events to log when the campaign is created, donated and refunded by the user.
    event CampaignCreated(
        address indexed owner,
        string title,
        string description,
        uint256 target,
        uint256 deadline,
        string image
    );
    event DonationMade(
        uint256 indexed id,
        address indexed donator,
        uint256 amount,
        bool agreed
    );
    event RefundIssued(
        uint256 indexed id,
        address indexed donator,
        uint256 amount
    );
    event withdrawn(uint256 _id, string message);

    modifier onlyOwner(uint256 _id) {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.owner, "Only owner can withdraw funds.");
        _;
    }

    // To keep track of campaigns.
    uint256 public numberOfCampaigns = 0;

    // To create new campaign.
    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        // Check if the passed date is valid.
        require(
            _deadline > block.timestamp,
            "Deadline should be a date in future"
        );
        // Check if the target value is greater than zero.
        require(_target > 0, "Target value should be greater than zero");
        // Check if the input parameters are not empty or null.
        require(
            bytes(_title).length > 0 &&
                bytes(_description).length > 0 &&
                bytes(_image).length > 0,
            "Input parameter should not be empty or null"
        );

        // Get the camapign.
        Campaign storage campaign = campaigns[numberOfCampaigns];

        // Set the details of campaign.
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.image = _image;

        // emit the event to log that the campaign was successfully created.
        emit CampaignCreated(
            _owner,
            _title,
            _description,
            _target,
            _deadline,
            _image
        );
        numberOfCampaigns++;
        return numberOfCampaigns - 1;
    }

    // To donate to a campaign of a specific ID
    function donateToCampaign(uint256 _id, bool _agree) public payable {
        uint256 amount = msg.value;

        // Get the campaign which the user is willing to fund.
        Campaign storage campaign = campaigns[_id];

        // check if the campaign was successfully completed.
        require(
            campaign.owner != address(0),
            "Campaign was successfully completed"
        );

        // Check if the deadline is met or not.
        require(campaign.deadline > block.timestamp, "deadline already met");

        // Check if the minimum value is met so that we can ensue the fee of the transaction even.
        require(amount >= 62000 wei, "Minimum contribution value not met.");

        // Check if the owner is not calling the transaction.
        require(msg.sender != campaign.owner, "Owner can't call transaction");

        bool donatorExists = false;
        uint i;
        for (i = 0; i < campaign.donators.length; i++) {
            if (msg.sender == campaign.donators[i]) {
                donatorExists = true;
            }
        }
        if (donatorExists) {
            campaign.donations[i] = campaign.donations[i] + amount;
        } else {
            // Add the donator to Donators list.
            campaign.donators.push(msg.sender);

            // Add the donation amount to Donations.
            campaign.donations.push(amount);
        }

        if (_agree == false) {
            campaign.agree.push(-1);
        } else {
            campaign.agree.push(1);
        }

        // emit the event to specify that the donation has been sent.
        emit DonationMade(_id, msg.sender, amount, _agree);
        // Increment the donation amount collected.
        campaign.AmountCollected += amount;
    }

    // Allow users to refund the money collected if target is not reached.
    function refund(uint256 _id) public {
        // Get the campaign.
        Campaign storage campaign = campaigns[_id];

        // check if the campaign was successfully completed.
        require(
            campaign.owner != address(0),
            "Campaign was successfully completed"
        );

        // Check if the deadline for the campaign is exceeded.
        require(campaign.deadline < block.timestamp, "Deadline not met");

        // Check if the target has been reached.
        require(campaign.AmountCollected < campaign.target, "Target reached");

        // Check if the owner is not calling the transaction.
        require(msg.sender != campaign.owner, "Owner can't call transaction");

        // check if the amount is already withdrawn by campaign owner.
        require(
            campaign.AmountCollected > 0,
            "Amount has already been withdrawn by campaign owner"
        );

        // Find the index of the donator in the donators array.
        uint256 donatorIndex = 0;
        bool foundDonator = false;
        for (uint256 i = 0; i < campaign.donators.length; i++) {
            if (campaign.donators[i] == msg.sender) {
                donatorIndex = i;
                foundDonator = true;
                break;
            }
        }

        // Check if the sender has donated to the campaign.
        require(
            foundDonator == true,
            "You haven't donated to the campaign yet"
        );

        // Get the donation amount.
        uint256 donationAmount = campaign.donations[donatorIndex];

        // Remove the donator from the donators array.
        campaign.donators[donatorIndex] = campaign.donators[
            campaign.donators.length - 1
        ];
        campaign.donators.pop();

        // Remove the donation amount from the donations array.
        campaign.donations[donatorIndex] = campaign.donations[
            campaign.donations.length - 1
        ];
        campaign.donations.pop();

        // Transfer the donation amount back to the donator.
        (bool sent, ) = payable(msg.sender).call{value: donationAmount}("");
        require(sent == true, "Failed to send refund");

        // emit the event to specify that the refund was successful.
        emit RefundIssued(_id, msg.sender, donationAmount);

        // Decrement the amount collected.
        campaign.AmountCollected -= donationAmount;
    }

    // Get all the donators with their donations amount & return.
    function getDonators(
        uint256 _id
    ) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    // Get all the campaigns that are created & return.
    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }

    /* 
    1.  Allow the creator of the campaign to take out the funds if all conditions met.
    2.  if the required amount for the campaign is not met, there there should be a option for the campaign owner to have 
        a poll to donators & if there is 51% support to withdraw the funds for the campaign even if the target amount is
        not met & withdraw the funded amount.
    */
    function withdrawFunds(uint256 _id) public onlyOwner(_id) {
        // Get the campaign.
        Campaign storage campaign = campaigns[_id];

        // check if the campaign was successfully completed.
        require(
            campaign.owner != address(0),
            "Campaign was successfully completed"
        );

        // Check if the deadline for the campaign is exceeded.
        require(block.timestamp > campaign.deadline, "Deadline not met");

        // Check if the amount collected is greater than zero.
        require(campaign.AmountCollected > 0, "No funds to withdraw");

        // Check if the target has not been reached.
        if (campaign.AmountCollected < campaign.target) {
            // Get the number of donators.
            uint256 numDonators = campaign.donators.length;

            // Calculate the minimum support required.
            uint256 minSupport = (numDonators * 51) / 100;

            // Initialize the support counter.
            uint256 supportCount = 0;

            // Iterate through the donators and count the number of supporters.
            for (uint256 i = 0; i < numDonators; i++) {
                // Get the donation amount.
                int256 agree = campaign.agree[i];

                // If the donation amount is greater than zero, the donator is a supporter.
                if (agree == 1) {
                    supportCount++;
                }
            }

            // Check if the number of supporters is greater than or equal to the minimum required support.
            require(supportCount >= minSupport, "Insufficient support");

            // Transfer the collected amount to the campaign owner.
            (bool sent, ) = payable(campaign.owner).call{
                value: campaign.AmountCollected
            }("");
            require(sent == true, "Failed to send funds to campaign owner");

            // emit to specify that the withdrawal was successful, even if the target was not met.
            emit withdrawn(
                _id,
                "Successfully withdrawn funds from campaign owner, by donators agreement"
            );

            // Set the amount collected to zero.
            campaign.AmountCollected = 0;
        } else {
            // Transfer the collected amount to the campaign owner.
            (bool sent, ) = payable(campaign.owner).call{
                value: campaign.AmountCollected,
                gas: 10000
            }("");
            require(sent == true, "Failed to send funds to campaign owner");

            // Destroy the campaign.
            destroyCampaign(_id);

            // emit to specify that the withdrawal was successful
            emit withdrawn(
                _id,
                "Successfully withdrawn funds from campaign owner"
            );
            // Set the amount collected to zero.
            campaign.AmountCollected = 0;
        }
    }
}