// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        address payable owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
        uint256 noOfVoters;
        bool completed;
    }

    mapping(address=>bool) voters;

    mapping(address=>uint) public contributors;

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(campaign.deadline < block.timestamp, "The deadline should be a date in the future.");

        campaign.owner = payable(_owner);
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
        campaign.noOfVoters = 0;
        campaign.completed = false;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        if(contributors[msg.sender] == 0){
            campaign.donators.push(msg.sender);
            campaign.donations.push(amount);
        } else {
            for(uint i=0; i<campaign.donators.length; i++){
                uint256 newAmount = campaign.donations[i] + amount;
                campaign.donations[i] = newAmount;
            }
        }
               
        contributors[msg.sender] += amount;
        campaign.amountCollected = campaign.amountCollected + amount;
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

    function refund(uint256 _id) public payable {
        require(campaigns[_id].deadline < block.timestamp && campaigns[_id].amountCollected < campaigns[_id].target, "You are not eligible");
        require(contributors[msg.sender]>0);
        address payable user=payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        campaigns[_id].amountCollected -= contributors[msg.sender];
        updateDonators(msg.sender, campaigns[_id].donators, _id);
        contributors[msg.sender]=0;  
    }

    function updateDonators(address element, address[] memory arr, uint _id) private {

        for (uint i = 0 ; i < arr.length; i++) {
            if (element == arr[i]) {
                for (uint j = i; j < arr.length - 1; j++) {
                    campaigns[_id].donators[i] = campaigns[_id].donators[i + 1];
                    campaigns[_id].donations[i] = campaigns[_id].donations[i + 1];
                }
                campaigns[_id].donators.pop();
                campaigns[_id].donations.pop();
                break ;
            }
        }
    }

    function voteRequest(uint256 _requestNo) public{
        require(contributors[msg.sender]>0,"You must be contributor");
        Campaign storage thisRequest=campaigns[_requestNo];
        require(voters[msg.sender]==false,"You have already voted");
        voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }

    function withdraw(uint256 _requestNo) public{
        Campaign storage thisRequest=campaigns[_requestNo];
        require(thisRequest.owner == msg.sender, "You are not the owner of this campaign");
        require(block.timestamp > thisRequest.deadline, "You cannot withdraw before deadline");
        require(thisRequest.amountCollected>=thisRequest.target);
        require(thisRequest.completed==false,"The request has been completed");
        require(thisRequest.noOfVoters > thisRequest.donators.length/2,"Majority does not support");
        thisRequest.owner.transfer(thisRequest.amountCollected);
        thisRequest.completed=true;
    }
}