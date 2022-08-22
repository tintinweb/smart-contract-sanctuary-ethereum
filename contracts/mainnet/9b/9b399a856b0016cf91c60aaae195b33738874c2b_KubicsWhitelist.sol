/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error Whitelist__WhitelistClosed();
error Whitelist__AlreadyWhitelisted();
error Whitelist__WhitelistLimitReached();
error Whitelist__NotWhitelisted();

contract KubicsWhitelist {
    //Maximum number of whitelisted address. Needs to be define when deploying or in the constuctor
    uint256 public maxWhitelistedAddresses;
    //Mapping from address to bool. Defines if an address is whitelisted or not
    mapping(address => bool) public whitelistedAddresses;
    //Mapping from uint to address. Returns whitelisted address by index. Does not eliminate removed address
    mapping(uint256 => address) public addressById;
    //Counter of total address whitelisted. Whithout removed address.
    uint8 public numAddressesWhitelisted;
    //Counter of total address whitelisted. Does not eliminate removed address
    uint256 public counter;
    //Boolean with whithelist status
    bool whitelistStatus;
    //Owner address
    address public owner;

    constructor() {
        maxWhitelistedAddresses = 2500;
        whitelistStatus = true;
        owner = msg.sender;
    }

    //onlyOwner modifier
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier whitelistCompliance() {
        if (whitelistStatus != true) {
            revert Whitelist__WhitelistClosed();
        }
        if (numAddressesWhitelisted >= maxWhitelistedAddresses) {
            revert Whitelist__WhitelistLimitReached();
        }
        _;
    }

    //Function for the user to join the whitelist
    function addAddressToWhitelist() public whitelistCompliance {
        // check if the sender is already whitelisted
        if (whitelistedAddresses[msg.sender] == true) {
            revert Whitelist__AlreadyWhitelisted();
        }
        // Add the address which called the function to the whitelistedAddress mapping
        whitelistedAddresses[msg.sender] = true;
        //Add the addres which called the function to the addressById mapping
        addressById[counter] = msg.sender;
        // Increase the number of whitelisted addresses
        numAddressesWhitelisted += 1;
        counter += 1;
    }

    //Function to manually add a user to the whitelist
    function manuallyAddAddressToWhitelist(address addAddress) public whitelistCompliance {
        // check if the whitelist is open
        if (whitelistedAddresses[addAddress] == true) {
            revert Whitelist__AlreadyWhitelisted();
        }
        // Add the address which called the function to the whitelistedAddress mapping
        whitelistedAddresses[addAddress] = true;
        //Add the addres which called the function to the addressById mapping
        addressById[counter] = addAddress;
        // Increase the number of whitelisted addresses
        numAddressesWhitelisted += 1;
        counter += 1;
    }

    function removeAddressFromWhitelist(address removeAddress) public payable onlyOwner {
        if (whitelistedAddresses[removeAddress] != true) {
            revert Whitelist__NotWhitelisted();
        }
        whitelistedAddresses[removeAddress] = false;
        numAddressesWhitelisted -= 1;
    }

    //Sets the whitelist status (true/false = open/close)
    function setWhitelistMintStatus(bool status) public payable onlyOwner {
        whitelistStatus = status;
    }

    function isAddressWhitelisted(address addressWhitelisted) public view returns (bool) {
        bool isUserWhitelisted = whitelistedAddresses[addressWhitelisted];
        return isUserWhitelisted;
    }

    function getContractAddress() public view returns (address) {
        return address(this);
    }

    function getWhitelistStatus() public view returns (bool) {
        return whitelistStatus;
    }
}