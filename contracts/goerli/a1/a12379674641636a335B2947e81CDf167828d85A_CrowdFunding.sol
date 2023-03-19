// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {

    enum Category {
        Biology,  // medecin, biology, organic chemistry ...etc
        Physical,  // physics, chemistry, architecture ...
        Social,  // psychology, behavioural studies ...
        Formal   // mathematics, theoritical computer science ...
    }

    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        string link;
        uint256 amountCollected;
        string image;
        bool isComplete;
        bool isConfirmed;
        Category category;  // 0 : "", 1 : "", 2 : "", 3 : ""
        // address[] donators;
        // uint256[] donations;
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;

    enum globalState { NonSelected, Selected }

    mapping(Category => globalState) public categoryStates;    
    mapping(Category => Campaign) public primaryCampaigns;

    constructor() {
        categoryStates[Category.Biology] = globalState.NonSelected;
        categoryStates[Category.Formal] = globalState.NonSelected;
        categoryStates[Category.Social] = globalState.NonSelected;
        categoryStates[Category.Physical] = globalState.NonSelected;

    }

    function get_category_state(uint cat) public view returns (globalState) {
        require(cat < 4);
        return categoryStates[Category(cat)];
    }

    function set_campaign_as_primary(uint256 _id) public {
        Campaign memory camp = campaigns[_id];
        if(categoryStates[camp.category] == globalState.NonSelected){
            categoryStates[camp.category] = globalState.Selected;
            primaryCampaigns[camp.category] = camp;
            camp.isConfirmed = true;
        }
    }

    function GI_simulation(Category cat) public {
        for(uint i = 0; i < numberOfCampaigns; i++) {
            if(campaigns[i].category == cat && !campaigns[i].isComplete && !campaigns[i].isConfirmed) {
                set_campaign_as_primary(i);
                return;
            }
        }
        categoryStates[cat] = globalState.NonSelected;
    }

    function get_primary_campagne(uint16 num) public view returns (Campaign memory) {
        Campaign memory camp = primaryCampaigns[Category(num)];
        return camp;
    }



    function createCampaign(address _owner, string memory _title, string memory _description,string memory _link , uint256 _target, string memory _image, uint16 _category) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.link = _link;
        campaign.amountCollected = 0;
        campaign.image = _image;
        campaign.isComplete = false;
        campaign.isConfirmed = false;
        campaign.category = Category(_category%4);

        numberOfCampaigns++;

        if(categoryStates[Category(_category)] == globalState.NonSelected) {
            set_campaign_as_primary(numberOfCampaigns - 1);
        }

        return numberOfCampaigns - 1;
    }

    event CampaignTargetReached(uint256 id);

    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        (bool sent,) = payable(campaign.owner).call{value: amount}("");

        if(sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
            if(campaign.amountCollected >= campaign.target){
                campaign.isComplete = true;
                categoryStates[campaign.category] = globalState.NonSelected;
                emit CampaignTargetReached(_id);
                
            }
            // campaign.donators.push(msg.sender);
            // campaign.donations.push(amount);
        }
    }

    // function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
    //     return (campaigns[_id].donators, campaigns[_id].donations);
    // }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }

        return allCampaigns;
    }

    function destruct() public {
        selfdestruct(payable(0xDE15035A5F592AA70d8c4CA2F91A59AAC1EE706C));
    }
}