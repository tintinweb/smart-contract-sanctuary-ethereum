// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Crowdfunding {
    struct Campaign// similar to object in JavaScript
{
  address owner;
  string title;
  string description;
  uint256 target;
  uint256 deadline;
  uint256 amountCollected;
  string image; // to put url of image
  address[] donators;
  uint256[] donations;
}

mapping(uint256 => Campaign) public campaigns; // we created a mapping so we can use campaign[0], which in javascript you can use natively but in solidity you need to create a mapping
uint256 public numberOfCampaigns = 0 ; // public variable to keep track of the number of campaigns we have created to be able to give them ids

function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) // underscore used to show that the parameter is only for this specific function, memory keyword is needed with every string. In solidity you have to specify if the function is internal or we can use it from frontend so we write public and then also specify what it will return (in this case ID of that campaign)
{
    Campaign storage campaign = campaigns[numberOfCampaigns]; // at the start it will be 0 as declared above, means we will be populating our first element in our campaigns array, later increment it. Thus filling our array. 


    require(campaign.deadline < block.timestamp,"The deadline should be a date in the future." );// test to check is everything good?
    
    // so now we start filling up our campaign
    campaign.owner = _owner;
    campaign.title = _title;
    campaign.description = _description;
    campaign.target = _target;
    campaign.deadline = _deadline;
    campaign.amountCollected = 0;
    campaign.image = _image;

    numberOfCampaigns++;

    return numberOfCampaigns - 1; // index of the most newly created campaign

}


function donateToCampaign(uint256 _id) public payable // payable is a special keyword that signifies that we are to send some cryptocurrency through it
{
 uint256 amount = msg.value; // what we will be getting from the frontend

 Campaign storage campaign = campaigns[_id]; // the campaigns here is the mapping we created at the top
 campaign.donators.push(msg.sender); 
 campaign.donations.push(amount);

 (bool sent,) = payable(campaign.owner).call{value: amount} (""); // variable to tell us if the transaction amount has been sent to the owner or not

 if(sent) 
 {
    campaign.amountCollected = campaign.amountCollected + amount;
 }
}

function getDonaotors(uint256 _id) view public returns(address[] memory, uint256[] memory) // it is going to return the array of address in memory, something we have stored beforehand i.e address of donators and number of donations

{
return (campaigns[_id].donators, campaigns[_id].donations);
}

function getCampaigns() public view returns (Campaign[] memory) // to get list of campaigns. Takes no parameters as we want to return all campaigns
{
Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns); // we are creating a new variable called allCampaigns which is of type array of multiple campaign structures. we are not getting campagigns here but creating an empty array with as many empty elements as there are actual campaigns
// so now we loop through all campaigns and populate that variable 
 for(uint i = 0; i<numberOfCampaigns; i++){
    Campaign storage item = campaigns[i]; // getting item from storage and populating in campaigns[i]

    allCampaigns[i] = item; // fetching that specific campaign from storage and populating it straight to our allcampaigns


 }
 return allCampaigns;
}


}