pragma solidity ^0.8.9;

contract MyContract {
    


    struct Campaign {  
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
     

        address[] donators;
        uint256[] donations;

        address[] NoOfApprovers;
        uint256 NoOfApproversCount;
        
        address[] NoOfApprovals;
        uint256 NoOfApprovalsCount;
        bool complete;

    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;
    

    function ValidateFrauders(uint _id,address addr) internal view returns(bool){ 
         
         Campaign storage campaign = campaigns[_id];

         for(uint i=0;i<campaign.NoOfApprovers.length;i++){

             if(campaign.NoOfApprovers[i]==addr){
                  return true;
             }

         }
         return false;
         
    }
    


    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(campaign.deadline < block.timestamp, "The deadline should be a date in the future.");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
        campaign.NoOfApproversCount = 0; 
        numberOfCampaigns++;
        campaign.complete = false;
        campaign.NoOfApprovalsCount = 0;

        return numberOfCampaigns - 1;
    }
      



    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;
        
        Campaign storage campaign = campaigns[_id];
        require(!campaign.complete,"You cannot donate it is closed");
        
        campaign.amountCollected += amount;
        campaign.NoOfApprovers.push(msg.sender);
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);
        campaign.NoOfApproversCount++;

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
    
    function approveRequest(uint _id) public{
        Campaign storage campaign = campaigns[_id];
        require(!ValidateFrauders(_id,msg.sender),"You have are not a approver");

        campaign.NoOfApprovals.push(msg.sender);
        campaign.NoOfApprovalsCount++;
    }

    function finalizeRequest(uint _id) public {
       
       Campaign storage campaign = campaigns[_id];
       require(msg.sender==campaign.owner,"You are not a owner");
       require(campaign.NoOfApprovalsCount > (campaign.NoOfApproversCount/2));

       (bool sent,) = payable(campaign.owner).call{value : campaign.amountCollected}("");
       require(sent,"");
       campaign.complete = true;

    }
    
    function getSummary(uint _id) public view returns(uint256,uint256,uint256,address,uint256,bool){
          Campaign storage campaign = campaigns[_id];

        return(
          campaign.amountCollected,
          campaign.NoOfApprovalsCount,
          campaign.NoOfApproversCount,
          campaign.owner,
          campaign.deadline,
          campaign.complete
        );
    }

    
}