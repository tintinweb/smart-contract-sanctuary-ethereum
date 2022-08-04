/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

contract DroptListings {
    uint256 listingFee = 0.0025 ether;
    address owner;
    

    //Define a Nft drop object
    struct Drop {
        string imageUri;
        string name;
        string description;       
        string social_1;
        string social_2;
        string websiteUrl;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        
        bool approved;
          
    }

    bool approved = false;
    
// "https://img.seadn.io/files/a41803ffbac10336b05367df826f2d99.png?auto=format&w=600",
// "Test Collection",
// "This is my drop this month",
// "twitter",
// "https://testtest.com",
// "faffaf",
// "0.05",
// "22",
// 1234567890,
// 1234567890,
// 1,
// false

    //Get Listing fee
    function getListingFee() public view returns (uint256) {
        return listingFee;
    }

    // Create a list to hold the objects
    Drop[] public drops;
    mapping (uint256 => address) public users;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner.");
        _;
    }

    // Get the NFT drop objects list
    function getDrops() public view returns (Drop[] memory) {
        return drops;
    }

    //Add to the NFT drop objects list
    function addDrop(Drop memory _drop) public payable {
        _drop.approved = false; 
        drops.push(_drop);          
        uint256 id = drops.length - 1;
        users[id] = msg.sender;
        require(listingFee> 0, "Amount must be higher than 0");
        require(msg.value == listingFee, "Please allow transfer of listing fee to complete listing.");
        payable(msg.sender); payable(address(this)); listingFee;

    }
    
    //Update from the nft drops list
    function updateDrop(
        uint256 _index, Drop memory _drop) public {
            require(msg.sender == users[_index], "You are not the owner of this listing");
            _drop.approved = false;
            drops[_index] = _drop;     
    }
    //Remove drop object
    // function unListDrop(
    // uint256 _index, Drop memory _drop)public {
    //     require(msg.sender == owner, "You are not the Father.");
    // }

    //Approve drop object to enable displaying
    function setApproveDrop(uint256 _index, bool _state) public {
        require(msg.sender == owner, "You are not the Father.");
        Drop storage drop = drops[_index];
        drop.approved = _state;
    }

    // function removeDrop(uint256 _index) public {
    //     require(msg.sender == owner, "You are not the Father.");
    //     Drop storage drop = drops[_index];
    //     drop.remove = false;
    // }

    function getBalance() external view returns (uint256) {
        require(msg.sender == owner, "You are not the Father.");
        return address(this).balance;
    }

    function withdraw() public {
        require(msg.sender == owner, "You are not the father.");
        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        require(success);

        // This will split payment and send 5% to other address
        // (bool hs, ) = payable(OWNERS WALLET ADDRESS).call{value: address(this).balance * 5 / 100}("");
    }

    //Must set cost in WEI
    
    function setListingFee(uint256 _listingFee) public onlyOwner {
        require(msg.sender == owner, "You are not the Father.");
        listingFee = _listingFee;
    }

    

    //Clear out all drop objects from list
}