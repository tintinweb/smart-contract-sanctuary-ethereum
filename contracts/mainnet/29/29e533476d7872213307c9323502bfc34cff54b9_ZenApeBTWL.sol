/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OTU BurnToWL -- One-Time-Use Burn to Whitelist Contract for ZenApes
// This contract was originally written by 0xInuarashi, and has been altered by M1nn1eR1dsy

// First, we define the contract inheritances that we want
abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

// Then, we define the interfaces we will be using
interface IERC721 {
    function ownerOf(uint256 tokenId_) external returns (address);
    function transferFrom(address from_, address to_, uint256 tokenId_) external;
}

// Now, we write the smart contract.
contract ZenApeBTWL is Ownable {

    // First, we define the interface.

    // ZenApe ERC721
    IERC721 public ZenApe = IERC721(0x838804a3dd7c717396a68F94E736eAf76b911632);

    // Default Burn Address
    // address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    // ZenApe Burn Address (Override)
    address public burnAddress = 0xD687386D60cfBedF9f02554CA33f865fEd7B9Cf5;

    // There are 20 spots.
    uint256 public totalSpots = 20;

    // We define a simple mapping method to push in allowed addresses to BTWL
    mapping(address => bool) public addressToAllowedBTWL;

    // Then, we define a simple method to push the data into the mapping
    function setAddressToBTWLs(address[] calldata addresses_, bool bool_) 
    external onlyOwner {
        for (uint256 i = 0; i < addresses_.length; i++) {
            addressToAllowedBTWL[addresses_[i]] = bool_;
        }
    }

    // We define an array to store the addresses AND compare to totalSpots
    address[] public whitelistedAddresses;

    // We also give the array a method to return all the addresses at once
    function getAllWhitelistedAddresses() external view returns (address[] memory) {
        return whitelistedAddresses;
    }

    // Now, we define the BTWL mechanics.
    function burnToWhitelist(uint256[] calldata tokenIds_) external {
        // They can burn 2 and only 2 in a transaction
        require(2 == tokenIds_.length,
            "Array length invalid!");

        // The whitelisted addresses must have available slots
        // The length gets added + 1 everytime there is a .push()
        require(totalSpots > whitelistedAddresses.length,   
            "No more spots left!");

        // The msg.sender must be in the allowed list of BTWL users
        require(addressToAllowedBTWL[msg.sender],
            "You do not have access to BTWL!");

        // NOTE: This is not required. It's good for error messages. 
        // In this case, we remove the statement for gas savings.
        // If the transferFrom is not possible, the function will revert anyway.
        // ~0xInuarashi 
        //
        // // The user must own the token
        // require(msg.sender == ZenApe.ownerOf(tokenId_),
        //     "You are not the owner of this ZenApe!");
        
        // Transfer the tokens in the array
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            ZenApe.transferFrom(msg.sender, burnAddress, tokenIds_[i]);
        }

        // We save gas by resetting the mapping storage to 0
        delete addressToAllowedBTWL[msg.sender];

        // Add them to the whitelisted addresses list 
        whitelistedAddresses.push(msg.sender);
    }
}