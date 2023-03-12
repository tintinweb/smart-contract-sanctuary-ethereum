// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

// import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";

// contract CrowdFunding is ContractMetadata.sol{
contract CrowdFunding{
    struct Campaign {
        address owner;
        string title;
        // string description;
        uint256 deadline;
        uint256 amountCollected;
        // string image;
        address[] donators;
        uint256[] donations;
        uint256 food;
        uint256 healthcare;
        uint256 shelter;
        uint256 sanitation;
        uint256 collectedfood;
        uint256 collectedhealthcare;
        uint256 collectedshelter;
        uint256 collectedsanitation;
    }

    // address public deployer;

    // constructor() {
    //     deployer = msg.sender;
    // }

    // function _canSetContractURI() internal view virtual override returns (bool){
    //     return msg.sender ==deployer;
    // }

    mapping(uint256 => Campaign) public campaigns;

    uint256 numberOfCampaigns = 0;
    uint256 price_food = 2;
    uint256 price_healthcare = 15;
    uint256 price_sanitation = 2;
    uint256 price_shelter = 45;

    uint256 number_food;
    uint256 number_healthcare;
    uint256 number_sanitation;
    uint256 number_shelter;
    
    uint256 Fprice_food;
    uint256 Fprice_healthcare;
    uint256 Fprice_sanitation;
    uint256 Fprice_shelter;



    function fetchfoodprice() public view returns (uint) {
        return Fprice_food;
    }

    function incrementfood() public {
        Fprice_food = Fprice_food + price_food;
        number_food = number_food + 1;
    }

    function decrementfood() public {
        require(Fprice_food > 0);
        Fprice_food = Fprice_food - price_food;
        number_food = number_food - 1;
    }

    function fetchhealthprice() public view returns (uint) {
        return Fprice_healthcare;
    }

    function incrementhealth() public {
        Fprice_healthcare = Fprice_healthcare + price_healthcare;
        number_healthcare = number_healthcare + 1;
    }

    function decrementhealth() public {
        require(Fprice_healthcare > 0);
        Fprice_healthcare = Fprice_healthcare - price_healthcare;
        number_healthcare = number_healthcare - 1;
    }

    function fetchsanitationprice() public view returns (uint) {
        return Fprice_sanitation;
    }

    function incrementsani() public {
        Fprice_sanitation = Fprice_sanitation + price_sanitation;
        number_sanitation = number_sanitation + 1;
    }

    function decrementsani() public {
        require(Fprice_sanitation > 0);
        Fprice_sanitation = Fprice_sanitation - price_sanitation;
        number_sanitation = number_sanitation - 1;
    }

    function fetchshelterprice() public view returns (uint) {
        return Fprice_shelter;
    }

    function incrementshelter() public {
        Fprice_shelter = Fprice_shelter + price_shelter;
        number_shelter = number_shelter + 1;
    }

    function decrementshelter() public {
        require(Fprice_shelter > 0);
        Fprice_shelter = Fprice_shelter - price_shelter;
        number_shelter = number_shelter - 1;
    }

    // function add(uint256 a , uint256 b) public view returns(uint) {

    //     uint c = a+b;
    //     return c;
    //     }


    function createCampaign(address _owner, string memory _title, uint256 _deadline, uint256 _food, uint256 _healthcare, uint256 _shelter, uint256 _sanitation) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(campaign.deadline < block.timestamp, "The deadline should be a date in the future.");

        campaign.owner = _owner;
        campaign.title = _title;
        // campaign.description = _description;
        // campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.collectedfood = 0;
        campaign.collectedhealthcare = 0;
        campaign.collectedshelter = 0;
        campaign.collectedsanitation = 0;
        // campaign.image = _image;
        campaign.food = _food;
        campaign.shelter = _shelter;
        campaign.sanitation = _sanitation;
        campaign.healthcare = _healthcare;

        // uint256 d = add(price_food*campaign.food , price_healthcare*campaign.healthcare);
        // uint256 e = add(price_shelter*campaign.shelter , price_sanitation*campaign.sanitation);
        // uint256 Target = add(d,e);

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    // function add(uint256 a , uint256 b) public view returns(uint) {

    //     uint c = a+b;
    //     return c;
    // }

    // uint256 d = add(price_food*campaign.food , price_healthcare*campaign.healthcare);
    // uint256 e = add(price_shelter*campaign.shelter , price_sanitation*campaign.sanitation);
    // uint256 Target = add(d,e);

    function totalTarget(uint256 _id) public view returns(uint) {
        Campaign storage campaign = campaigns[_id];
        uint Target = price_food*campaign.food + price_healthcare*campaign.healthcare + price_shelter*campaign.shelter + price_sanitation*campaign.sanitation;
        return Target;
    }

    function payableAmount() public view returns(uint256) {
        uint total_value = Fprice_food + Fprice_healthcare + Fprice_sanitation + Fprice_shelter;
        return total_value;
    }

    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,) = payable(campaign.owner).call{value: amount}("");

        if(sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
            
            campaign.collectedfood = campaign.collectedfood + number_food;
            campaign.collectedhealthcare = campaign.collectedhealthcare + number_healthcare;
            campaign.collectedsanitation = campaign.collectedsanitation + number_sanitation;
            campaign.collectedshelter = campaign.collectedshelter + number_shelter;

        }
    }

    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }
        return allCampaigns;
    }
}