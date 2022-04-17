/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Adoption{
    address public owner;

    struct Pet {
        uint id;
        uint voteCount;
        Breed breed;
        bool adopted;
    }
    struct Breed {
        uint id;
        uint adotpionCount;
    }

    uint public petCount;
    uint public breedCount;
    uint public petAdotptionCount;
    uint public mostAdoptedBreedId;
    uint public adopterCount;

    mapping(uint=>Pet) public pets;
    mapping(uint=>Breed) public breeds;
    mapping(address=>bool) public votedAddresses;
    mapping(address=>bool) public isAdopter;

    event DonationWithdrawn(uint amount);
    event PetAdopted(uint petId);
    event PetAdded(uint petId);

    constructor() {
        owner = msg.sender;
        petCount = 0;
        breedCount = 0;
        petAdotptionCount = 0;
        mostAdoptedBreedId = 0;
        adopterCount = 0;
    }
    
    // Add breed
    function addBreed() external {
        require(msg.sender == owner, "Only owner allowed.");
        breeds[breedCount] = Breed(breedCount, 0);
        breedCount += 1;
    }   

    // Add/register pet
    function addPet(uint _breedId) external {
        require(_breedId <= breedCount, "Breed does not exist.");
        pets[petCount] = Pet(petCount, 0, breeds[_breedId], false);
        emit PetAdded(petCount);
        petCount += 1;
    }

    // Adopt a pet
    function adoptPet(uint _petId) external {
        require(!pets[_petId].adopted, "Pet already adopted");
        pets[_petId].adopted = true;
        breeds[pets[_petId].breed.id].adotpionCount += 1;
        petAdotptionCount += 1;
        if (breeds[pets[_petId].breed.id].adotpionCount > breeds[mostAdoptedBreedId].adotpionCount) {
            mostAdoptedBreedId = pets[_petId].breed.id;
        }
        if (!isAdopter[msg.sender]) {
            isAdopter[msg.sender] = true;
            adopterCount += 1;
        }
        emit PetAdopted(_petId);
    }

    // Vote
    function votePet(uint _petId) external {
        require(!votedAddresses[msg.sender], "Already voted.");
        require(_petId <= petCount, "Pet does not exist.");
        pets[_petId].voteCount += 1;
        votedAddresses[msg.sender] = true;
    }

    // Withdraw donation from contract
    function withdrawDonation(uint amount) external returns (bool) {
        require(msg.sender == owner, "Only owner allowed.");
        if (!payable(msg.sender).send(amount)) {
            return false;
        }
        emit DonationWithdrawn(amount);
        return true;
    }

    // Donate ether to petshop
    function donate() external payable{ }
}