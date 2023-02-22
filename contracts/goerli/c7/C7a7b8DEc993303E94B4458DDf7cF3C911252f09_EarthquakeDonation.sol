// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

contract EarthquakeDonation {

    address public owner;

    Donation [] public donations;
    Store [] public storeProducts;

    event ProductAdded(string productName, uint productCount);
    event DonationRequestAdded(string demand);

    struct Donation {
        string demand;
        string latestStatus;
        bool isProvided;
    }

    struct Store {
        string productName;
        uint productCount;
    }

    constructor() {
        owner = msg.sender;
    }

    function addStoreProduct(string memory _productName, uint _productCount) external onlyOwner {
        require(keccak256(abi.encodePacked(_productName)) != keccak256(abi.encodePacked("")), "invalid demand");
        Store memory newProduct = Store(_productName, _productCount);
        storeProducts.push(newProduct);
        emit ProductAdded(_productName, _productCount); 
    }

    function addDonationRequest(string memory _demand) external onlyOwner {
        require(keccak256(abi.encodePacked(_demand)) != keccak256(abi.encodePacked("")), "invalid demand");
        Donation memory newDonation = Donation(_demand, "", false);
        donations.push(newDonation);
        emit DonationRequestAdded(_demand); 
    }

    function updateDonationRequest(uint id, string memory _latestStatus) external onlyOwner {
        donations[id].latestStatus = _latestStatus;
    }

    function makeDonation(uint id) external onlyOwner {
        donations[id].isProvided = true;
    }
    
    function deleteDonationRequest(uint id) external onlyOwner {
        donations[id].latestStatus="deleted";
    }

    function changeOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function getDonations() public view returns (Donation[] memory) {
        return donations;
    }

    function getStoreProducts() public view returns (Store[] memory) {
        return storeProducts;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "you are not allowed to call the function");
        _;
    }
}