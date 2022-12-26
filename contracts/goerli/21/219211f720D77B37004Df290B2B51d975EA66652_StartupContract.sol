// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract StartupContract {
    struct Startup {
        string image;
        address sOwner;
        string sName;
        string sEmail;
        string sDescription;
        string sVideoUrl;
        uint256 amountCollected;
        uint256 goal;
        uint256 minInvestment;
        uint256 valuationCap;
        uint256 discountRate;
        uint256 deadline;
        address[] pools; //list of address of pool
    }
    mapping(uint256 => Startup) public campaigns;
    uint256 public numberofStartups = 0;

    function createCampaign(
        address _onwer,
        string memory _image,
        string memory _name,
        string memory _email,
        string memory _description,
        string memory _videoUrl,
        uint256 _goal,
        uint256 _minInvestment,
        uint256 _valuationCap,
        uint256 _discountRate,
        uint256 _deadline
    ) public returns (uint256) {
        Startup storage startup = campaigns[numberofStartups];
        // is everything okay?
        require(
            startup.deadline < block.timestamp,
            "The deadlin should be a date in future"
        );

        startup.sOwner = _onwer;
        startup.image = _image;
        startup.sName = _name;
        startup.sEmail = _email;
        startup.sDescription = _description;
        startup.sVideoUrl = _videoUrl;

        startup.goal = _goal;
        startup.amountCollected = 0;
        startup.minInvestment = _minInvestment;
        startup.valuationCap = _valuationCap;
        startup.discountRate = _discountRate;
        startup.deadline = _deadline;
        numberofStartups++;

        return numberofStartups - 1; //index of mostly create startup
    }

    //get list of startups
    //get one startup
    function getCampaigns() public view returns (Startup[] memory) {
        Startup[] memory allCampaigns = new Startup[](numberofStartups);

        for (uint i = 0; i < numberofStartups; i++) {
            Startup storage item = campaigns[i];

            allCampaigns[i] = item;
        }
        return allCampaigns;
    }

    //donateToCampaign
    function InvestToStartup(uint256 _id) public payable {
        uint256 amount = msg.value;
        Startup storage campaign = campaigns[_id];

        campaign.pools.push(msg.sender);

        (bool sent, ) = payable(campaign.sOwner).call{value: amount}("");

        if (sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    //get list of investors
    function getPools(uint256 _id) public view returns (address[] memory) {
        return (campaigns[_id].pools);
    }
}