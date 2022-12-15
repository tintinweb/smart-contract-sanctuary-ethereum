/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// SPDX-License-Identifier: GPL-3.0

    // ===- Energy Source -===
    // 1. Solar power;
    // 2. Wind energy;
    // 3. Geothermal energy;
    // 4. Hydroelectric energy;
    // 5. Biomass energy.


pragma solidity >=0.7.0 <0.9.0;
contract EnergyContract {
    uint256 public producersCount = 0;
    mapping(uint => Producer) public producers;
    address owner;
    mapping(address => bool) whitelistedAddresses;  // List of whitelisted address 

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    struct Producer {
        uint _id;
        address _addr;
        string _producerName;
        uint _energySource;
        uint256 _milliWatt;
        uint timestamp;
    }

    constructor()  {
        owner = msg.sender;
    }

    function addUser(address _addressToWhitelist) public onlyOwner {
        whitelistedAddresses[_addressToWhitelist] = true;
    }

    function verifyUser(address _whitelistedAddress) public view returns(bool) {
        bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
        return userIsWhitelisted;
    }

    modifier isWhitelisted(address _address) {
        require(whitelistedAddresses[_address], "You need to be whitelisted");
        _;
    }

    function addProducer( string memory _producerName, uint _energySource, uint256 _milliWatt) public isWhitelisted(msg.sender) returns(uint256)
    {
        producersCount += 1;
        producers[producersCount] = Producer(producersCount, tx.origin, _producerName, _energySource, _milliWatt, block.timestamp);
        return (producersCount);
    }
}