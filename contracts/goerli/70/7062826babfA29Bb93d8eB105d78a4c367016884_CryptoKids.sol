/**
 *Submitted for verification at Etherscan.io on 2023-02-25
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
        address creator;
    }

    Campaign[] public campaigns;

    struct Donator {
        address walletAddress;
        address donator;
        uint amount;
    }

    Donator[] public donators;
    // address[] Depositdonators;

    // modifier onlyOwner() {
    //     require(msg.sender == owner, "Only the owner can add campaigns");
    //     _;
    // }

    // add Campaign to contract
    function addCampaign(address payable walletAddress, string memory charityName,string memory title, string memory desc, uint releaseTime, uint target,uint amount, bool canWithdraw,address creator) public {
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
            creator
        ));

    }


function getAllCampaigns() public view returns (Campaign[] memory){
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

function getCampaign(address walletAddress) public view returns (Campaign[] memory){
      Campaign[] memory temp = new Campaign[](campaigns.length);
      uint counter = 0;

      for (uint i = 0; i < campaigns.length; i++) {
          temp[counter] = campaigns[i];
          counter++;
      }
      
      Campaign[] memory result = new Campaign[] (counter);
       for (uint i = 0; i < counter; i++) {
           if (temp[i].walletAddress == walletAddress){
            result[i] = temp[i];
           }
      }
      return result;
}

    function balanceOf() public view returns(uint) {
        return address(this).balance;
    }

    function deposit(address walletAddress,address donator) payable public {
        bool foundExistingDonator = false;

        for(uint i = 0; i < donators.length; i++) {
            if(donators[i].donator == donator && donators[i].walletAddress == walletAddress) {
                donators[i].amount += msg.value;
                foundExistingDonator = true;
            }
        }
        if (foundExistingDonator == false){
                donators.push(Donator(
                walletAddress,
                donator,
                msg.value
            ));
        }
       
        
        addToKidsBalance(walletAddress);
    }

    function getDonators(address walletAddress) public view returns(Donator[] memory) {
        //retrive single campaign donators
         Donator[] memory temp = new Donator[](donators.length);
      uint counter = 0;

      for (uint i = 0; i < donators.length; i++) {
          temp[counter] = donators[i];
          counter++;
      }
      
      Donator[] memory result = new Donator[] (counter);
       for (uint i = 0; i < counter; i++) {
           if (temp[i].walletAddress == walletAddress){
            result[i] = temp[i];
           }
      }
      return result;
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
    }

}