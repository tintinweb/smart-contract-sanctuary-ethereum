// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract BlockchainFlippa{
    
    struct Listing{
        uint256 id;
        string name;
        string websiteURL;
        string description;
        uint256 price;
        uint256 profitPerMonth;
        uint256 siteAge;
        bool purchased;
        bool approved;
        address owner;
    }
    
    mapping(address => mapping(uint256 => Listing)) public sellerListings;
    address[] public sellerAddresses;
    mapping(address => address) public buyer;
    Listing[] public allListings;
    
    receive() external payable {}
    
    function List(uint256 _id, string memory _name, string memory _websiteURL, string memory _description, uint256 _price, uint256 _profitPerMonth, uint256 _siteAge) public {
        require(sellerListings[msg.sender][_id].id != _id,"The Id is already in use. Please Change ");
        Listing storage newListing = sellerListings[msg.sender][_id];
        newListing.id = _id;
        newListing.name = _name;
        newListing.websiteURL = _websiteURL;
        newListing.description = _description;
        newListing.price = _price;
        newListing.profitPerMonth = _profitPerMonth;
        newListing.siteAge = _siteAge;
        newListing.owner = msg.sender;
        
        sellerAddresses.push(msg.sender);
        allListings.push(newListing);
    }
    
    function buy(address _sellerAddress, uint256 _id) public payable{
        require(sellerListings[_sellerAddress][_id].price == msg.value, "Wrong Price");
        require(msg.sender != _sellerAddress,"Hey Dumbass, You can't buy your own Listing");
        (bool sent, ) = address(this).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        sellerListings[_sellerAddress][_id].purchased = true;
        buyer[_sellerAddress] = msg.sender;
    }
    
    function buyerApprove(address _sellerAddress, uint256 _id) public payable{
        require( buyer[_sellerAddress] == msg.sender, "Haha! You are not the Approver");
        sellerListings[_sellerAddress][_id].approved = true;
        sellerListings[_sellerAddress][_id].owner = msg.sender;
        uint256 _price = sellerListings[_sellerAddress][_id].price;
        (bool sent, ) = payable(_sellerAddress).call{value: _price}("");
        require(sent, "Failed to send Ether");
    }
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function getAllListing() public view returns (Listing[] memory){
        return allListings;
    }
}