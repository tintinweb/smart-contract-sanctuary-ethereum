/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// The CharityRegistry contract stores a list of registered charities and allows users to donate to them.
contract CharityRegistry {
  // Struct to store the details of a charity
  struct Charity {
    string name;
    string mission;
    string website;
    uint totalDonation;
    bool active;
    address payable wallet;
  }

  // Mapping from charity id to charity details
  mapping(uint => Charity) public charities;

  // Array to store the list of charity ids in the order they were added
  uint[] public charityIds;


  // Counter to generate unique ids for charities
  uint public charityIdCounter;

  // Events to track when a charity is added or when a donation is made
  event CharityAdded(uint indexed charityId, string name, string mission, string website, bool active, address payable wallet);
  event CharityUpdated(uint indexed charityId, string name, string mission, string website, bool active, address payable wallet);
  event DonationMade(uint indexed charityId, address donor, uint amount);

  // Address of the contract owner
  address public owner;

  constructor() {
    // Assign msg.sender as the owner of the contract
    owner = msg.sender;
  }

  // Only allow the owner to add new charities
  modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can add new charities.");
    _;
  }

  // Function to add a new charity to the registry
  function addCharity(string memory name, string memory mission, string memory website, bool active, address payable wallet) public onlyOwner {
    // Generate a unique id for the charity
    uint charityId = charityIdCounter++;

    // Create a new charity struct and add it to the mapping
    charities[charityId] = Charity(name, mission, website, 0, active, wallet);

    // Add the charity id to the list of charity ids
    charityIds.push(charityId);

    // Emit an event to track the addition of the charity
    emit CharityAdded(charityId, name, mission, website, active, wallet);
  }

  // Ensure that the charity exists
  modifier onlyValidCharity(uint charityId) {
    require(charityId <= charityIdCounter, "Invalid charity ID");
    require(!compareStrings(charities[charityId].name, ""), "Charity does not exist");
    require(charities[charityId].active, "Charity is not active");
    _;
  }

  // Function to update an existing charity
  function updateCharity(uint charityId, string memory name, string memory mission, string memory website, bool active, address payable wallet) public onlyOwner onlyValidCharity(charityId) {
    Charity storage charity = charities[charityId];

    charity.name = name;
    charity.mission = mission;
    charity.website = website;
    charity.active = active;
    charity.wallet = wallet;

    // Emit an event to track the charity update
    emit CharityUpdated(charityId, name, mission, website, active, wallet);
  }


  // Function to allow users to donate to a registered charity
  function donate(uint charityId) public payable onlyValidCharity(charityId) {
    // Get the details of the charity
    Charity storage charity = charities[charityId];

    // Transfer the donation amount to the charity's wallet
    charity.wallet.transfer(msg.value);
    charity.totalDonation += msg.value;

    // Emit an event to track the donation
    emit DonationMade(charityId, msg.sender, msg.value);
  }

  function compareStrings(string memory _a, string memory _b) public pure returns (bool) {
    bytes32 hashA = keccak256(abi.encodePacked(_a));
    bytes32 hashB = keccak256(abi.encodePacked(_b));
    return hashA == hashB;
  }

}