// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

contract CharityPlatform {
    struct Campaign {
        uint256 id;

        string name;
        string description;
        uint256 fundingGoal;        

        uint256 campaignEnd;
        address creator;

        bool isSuccessful;
        uint256 totalFunds;
        mapping(address => uint) donators;
    }

    mapping(uint256 => Campaign) public campaigns;
    uint32 _counter = 0;

    /// Events:
    /**
     * @dev This emits when a new campaign is created.
     * @param creator The campaign creator
     * @param campaignId The campaign id
     * @param name The campaign name
     */
    event NewCampaign(
        address creator,
        uint32 indexed campaignId,
        string name       
    );

    /**
     * @dev This emits when a new donation is contributed.
     * @param donator The donator
     * @param campaignId The campaign id
     * @param donation The donation amount
     */
    event NewDonation(
        address donator,
        uint32 indexed campaignId,
        uint256 donation
    );

    /**
     * @dev This emits when the funds are collected by the campaign creator.
     * @param owner The campaign creator
     * @param campaignId The campaign id
     * @param fundsCollected The amount of funds collected by the campaign
     * @param fundsSendTo The beneficiary of the funds
     */
    event FundsCollected (
        address owner,
        uint32 indexed campaignId,
        uint256 fundsCollected,
        address fundsSendTo
    );

    /**
     * @dev This emits when a refund is initiated.
     * @param contributor The campaign donator (contributor)
     * @param campaignId The campaign id
     * @param refund The amount of the refund     
     */
    event NewRefund(
        address contributor,
        uint32 indexed campaignId,
        uint256 refund
    );

    /// Functions:
    /**
     * @notice Creates a new campaign
     * @dev Emits the NewCampaign event
     * @param name The campaign name
     * @param description The campaign description
     * @param fundingGoal The campaign funding goal
     * @param deadline The campaign deadline in seconds
     */
    function createCampaign(
        string memory name,       
        string memory description,
        uint256 fundingGoal,
        uint256 deadline        
    ) public {
        Campaign storage newCampaign = campaigns[_counter];

        newCampaign.id = _counter;
        newCampaign.name = name;
        newCampaign.description = description;
        newCampaign.fundingGoal = fundingGoal;
        uint campaignEnd = block.timestamp + deadline;
        newCampaign.campaignEnd = campaignEnd;
        newCampaign.creator = msg.sender;

        emit NewCampaign(msg.sender, _counter, name);

        _counter++;
    }

    /**
     * @notice Donates to a campaign
     * @dev Emits the NewDonation event.
     *  Throws if the campaign is not active.
     *  Throws if the funding goal is surpassed.
     * @param id The campaign identifier     
     */
    function donate(uint32 id) external payable isActive(id) {
        Campaign storage campaign = campaigns[id];
        uint donation  = msg.value;
        uint totalAmmount = campaign.totalFunds + donation;
        uint fundingGoal = campaign.fundingGoal;
        require(totalAmmount <= fundingGoal, "Funding goal is surpassed!");
        
        campaign.totalFunds += donation;
        campaign.donators[msg.sender] += donation;

        emit NewDonation(msg.sender, id, donation);

        if (campaign.totalFunds == fundingGoal) {
            campaign.isSuccessful = true;
            campaign.campaignEnd = block.timestamp;
        }
    }

    /**
     * @notice The campaign creator collects the funds
     * @dev Emits the FundsCollected event.
     *  Throws if not the owner (campaign creator).
     *  Throws if the campaign is still active.
     *  Throws if the campaing is not successful.
     * @param id The campaign identifier  
     * @param sendToAddress The funds beneficiary   
     * @return success If the funds were sent successfully.
     */
    function collectFunds(uint32 id, address sendToAddress) external payable onlyOwner(id) notActive(id) returns (bool success) {
        Campaign storage campaign = campaigns[id];        
        require(campaign.isSuccessful, "Campaign is not successful!");

        uint fundsToSend = campaign.totalFunds;
        campaign.totalFunds = 0;
        
        (bool sent, ) = payable(sendToAddress).call{value: fundsToSend}("");
         
        emit FundsCollected(campaign.creator, id, fundsToSend, sendToAddress);        

        return sent;
    }

    /**
     * @notice Refunds the funds to a contributor
     * @dev Emits the NewRefund event.     
     *  Throws if the campaign is still active.
     *  Throws if the campaing is successful.
     *  Throws if there is no funds to refund.
     * @param id The campaign identifier        
     * @return success If the refund was sent successfully.
     */
    function refund(uint32 id) external payable notActive(id) returns (bool success) {
        Campaign storage campaign = campaigns[id];
        require(!campaign.isSuccessful, "Successful campaign. Can't withdaw funds!"); 
        address contributor = msg.sender;   
        uint256 fundsToSend = campaign.donators[contributor];
        require(fundsToSend > 0, "No funds to refund!");
        
        campaign.donators[contributor] = 0;
        campaign.totalFunds -= fundsToSend;
        (bool sent, ) = payable(contributor).call{value: fundsToSend}("");
        
        if (sent) {
            emit NewRefund(contributor, id, fundsToSend);
        }

        return sent;
    }  

    /// Modifiers:    
    /// A modifier to check if the campaign is still active
    modifier isActive(uint id) {
        require(block.timestamp < campaigns[id].campaignEnd, "Campaign has ended!");
        _;
    }

    /// A modifier to check if the campaign is not active
    modifier notActive(uint id) {
        require(block.timestamp >= campaigns[id].campaignEnd, "Campaign is still active!");
        _;
    }

    /// A modifier to check if the owner is calling
    modifier onlyOwner(uint id) {
        require(msg.sender == campaigns[id].creator, "Not the owner");
        _;
    }

}