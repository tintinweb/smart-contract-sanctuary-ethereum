/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CryptoKids {
   
    address owner;

    event LogCampaignFundingReceived(address addr, uint amount, uint contractBalance);

    constructor() {
        owner = msg.sender;
    }
    struct Campaign {
        address payable walletAddress;
        string charityName;
        string title;
        string desc;
        uint releaseTime;
        uint target;
        uint amount;
        bool canWithdraw;
        // uint noOfDonations;
        string donators;
    }

    Campaign[] public campaigns;

    address[] Depositdonators;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can add campaigns");
        _;
    }

    // add Campaign to contract
    function addCampaign(address payable walletAddress, string memory charityName,string memory title, string memory desc, uint releaseTime, uint target,uint amount, bool canWithdraw,string memory donators) public onlyOwner {
    //    uint noOfDonation = 0; 

        campaigns.push(Campaign(
            walletAddress,
            charityName,
            title,
            desc,
            releaseTime,
            target,
            amount,
            canWithdraw,
            donators 
        ));

    }


function getMembers() public view returns (Campaign[] memory){
      Campaign[] memory temp = new Campaign[](campaigns.length);
      uint counter = 0;

      for (uint i = 0; i < campaigns.length; i++) {
          temp[counter] = campaigns[i];
          counter++;
      }
      
      Campaign[] memory result = new Campaign[] (counter);
       for (uint i = 0; i < counter; i++) {
         result[i] = temp[i];
      }
      return result;
  
}

    function balanceOf() public view returns(uint) {
        return address(this).balance;
    }

    function deposit(address walletAddress,address donators) payable public {
        Depositdonators.push(donators);
        addToKidsBalance(walletAddress);
    }

    function getDonators() public view returns(address[] memory) {
        return Depositdonators;
    }

    function addToKidsBalance(address walletAddress) private {
        for(uint i = 0; i < campaigns.length; i++) {
            if(campaigns[i].walletAddress == walletAddress) {
                campaigns[i].amount += msg.value;
                emit LogCampaignFundingReceived(walletAddress, msg.value, balanceOf());
            }
        }
    }

    function getIndex(address walletAddress) view private returns(uint) {
        for(uint i = 0; i < campaigns.length; i++) {
            if (campaigns[i].walletAddress == walletAddress) {
                return i;
            }
        }
        return 999;
    }

    function availableToWithdraw(address walletAddress) public returns(bool) {
        uint i = getIndex(walletAddress);
        require(block.timestamp > campaigns[i].releaseTime, "You cannot withdraw yet");
        if (block.timestamp > campaigns[i].releaseTime) {
            campaigns[i].canWithdraw = true;
            return true;
        } else {
            return false;
        }
    }

    // withdraw money
    function withdraw(address payable walletAddress) payable public {
        uint i = getIndex(walletAddress);
        require(msg.sender == campaigns[i].walletAddress, "You must be the owner to withdraw");
        require(campaigns[i].canWithdraw == true, "You are not able to withdraw at this time");
        campaigns[i].walletAddress.transfer(campaigns[i].amount);
        getMembers();
    }

}