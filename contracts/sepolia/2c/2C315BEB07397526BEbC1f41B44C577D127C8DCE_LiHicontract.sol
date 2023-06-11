// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
//surround divert route extend popular pill normal second sort window buyer dial - pass:[email protected]@
contract LiHicontract {
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
    //create such a array to save
    mapping(uint256 => Campaign) public campaigns;

    //số lượng sản phẩm tung ra
    uint256 public numberOfCampaigns = 0;
    //set
    //public function with return number
    function createCampaign(address _owner,string memory _title,string memory _description, uint256 _target, uint256 _deadline, string memory _image )
    public returns (uint256)
    {
        Campaign storage campaign =  campaigns[numberOfCampaigns];

        //the first require : block.timestamp means the date at now
        require(campaign.deadline < block.timestamp, "The deadline should be a date in the future !");
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        //number of donations
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;
        //return the index of this campaign
        return numberOfCampaigns - 1;
    }
    //payable means can send crypto :  Payable ensures that the function can send and receive Ether
    function donateToCampaign(uint256 _id) public payable{
        uint256 amount = msg.value;
        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,) = payable(campaign.owner).call{value: amount}("");

        if(sent){
            //merge value of the sender into campaign
            campaign.amountCollected = campaign.amountCollected + amount;
        }   




    }
    //get 
    function getDonators(uint256 _id) view public returns(address[] memory, uint256[] memory){
        //get all donators and donations of particular campaign by its index
        return (campaigns[_id].donators,campaigns[_id].donations);
    }
    function getCampaigns() public view returns(Campaign[] memory){
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns); // just create empty arr

        for(uint i=0;i<numberOfCampaigns;i++){
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item; 
        }
        return allCampaigns;

    } 
}