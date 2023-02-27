// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

 

contract CrowdFunding{
    struct Campaign{
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    struct Request {
        string description;
        uint256 value;
        address recipient;
        bool complete;
        uint256 approvalCount;
        mapping(address => bool) approvals;
    }

     
    mapping(address => bool) public approvers;
    uint256 public approversCount;
    address public manager;
    mapping(uint256 => Request) public requests;
    uint256 public numberOfrequests = 0;
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }


    mapping(uint256 => Campaign) public campaigns;
    uint256 public numberOfCampaigns = 0;

    function createCampiagn(address _owner,string memory _title,string memory _description,uint256 _target,uint256 _deadline,string memory _image) public returns(uint256){
        Campaign storage campaign = campaigns[numberOfCampaigns];
        
        
        require(campaign.deadline < block.timestamp,"The deadline is over");

        campaign.owner = _owner;
        manager=_owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;
        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id)public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);
        (bool sent,)=payable(campaign.owner).call{value: amount}("");
        if(sent){
            campaign.amountCollected = campaign.amountCollected + amount;
        }
        approvers[msg.sender] = true;
        approversCount++;
    }

    function getDonators(uint256 _id)view public returns(address[] memory,uint256[] memory) {
        return (campaigns[_id].donators,campaigns[_id].donations);
    }
    function createRequest(string memory rdescription, uint value, address recipient) public restricted {
    Request storage newRequest = requests[numberOfrequests];
    newRequest.description = rdescription;
    newRequest.value = value;
    newRequest.recipient = recipient;
    newRequest.complete = false;
    newRequest.approvalCount =0;

    numberOfrequests++;
 
    }
    function getCampaigns()public view returns(Campaign[] memory){
        Campaign[] memory allcampaigns = new Campaign[](numberOfCampaigns);
        for (uint i =0;i<numberOfCampaigns;i++){
            Campaign storage item = campaigns[i];
            allcampaigns[i] = item;
        }
        return allcampaigns;
    }


    function approveRequest(uint index) public {
        Request storage request = requests[index];

        require(approvers[msg.sender]);
        require(!request.approvals[msg.sender]);

        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }
    function finalizeRequest(uint index) public payable restricted {
        Request storage request = requests[index];

        require(request.approvalCount > (approversCount / 2));
        require(!request.complete);
        (request.complete,) = payable(request.recipient).call{value: request.value}("");
    }
    function getSummary() public view returns(
        uint,uint,address
    ){
        return(
            numberOfrequests,
            approversCount,
            manager
             );
    }
    
     
}