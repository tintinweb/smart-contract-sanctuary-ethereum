// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Compaign {
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

    mapping(uint256 => Compaign) public compaigns;

    uint256 public numberOfCompaigns = 0;

    function createCompaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
        Compaign storage compaign = compaigns[numberOfCompaigns];

        //require() is used to check, Is everything okay... 
        require(compaign.deadline < block.timestamp, "The deadline shouule be a date in the future.");

        compaign.owner = _owner;
        compaign.title = _title;
        compaign.description = _description;
        compaign.deadline = _deadline;
        compaign.amountCollected = 0;
        compaign.image = _image;

        numberOfCompaigns++;

        return numberOfCompaigns-1;
    }

    //payable used to send cryptocurrency through function.
    function donateToCompaign(uint256 _id) public payable {
        uint256 amount = msg.value;

        Compaign storage compaign = compaigns[_id];

        compaign.donators.push(msg.sender);
        compaign.donations.push(amount);

        (bool sent, ) = payable(compaign.owner).call{value: amount}("");

        if(sent) {
            compaign.amountCollected = compaign.amountCollected + amount;
        }
        
    }

    //Give the list of all donators also who donate to which specific compaign
    function getDonators(uint256 _id) view public returns(address[] memory, uint256[] memory) {
        //return the array of address of donators and array of donations
        return(compaigns[_id].donators, compaigns[_id].donations);
    }

    //list of all compaigns
    function getCompaigns() public view returns(Compaign[] memory){ 
        //we creating  new variable called allCompaigns which is a type array of multiple compaign structures.
        Compaign[] memory allCompaigns = new Compaign[](numberOfCompaigns);

        for(uint i=0; i < numberOfCompaigns; i++){
            Compaign storage item = compaigns[i];

            allCompaigns[i] = item;
        }
        return allCompaigns;
    }
}