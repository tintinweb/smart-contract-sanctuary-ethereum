/**
 *Submitted for verification at Etherscan.io on 2023-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract WhitelistApp {
    uint8 public numAddressesWhitelisted;
    uint8 maxWhitelistedAddresses;
    mapping(address => bool) public whitelistedAddresses;

    address private owner;

    constructor(uint8 _maxWhitelistedAddresses) {
        owner = msg.sender;
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner. Forbidden.");
        _;
    }

    function changeTheOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function addAddress(address _newAddress) public {
        require(
            !whitelistedAddresses[msg.sender],
            "You are already whitelisted..."
        );
        require(
            numAddressesWhitelisted < maxWhitelistedAddresses,
            "Sorry, no spots left..."
        );

        whitelistedAddresses[_newAddress] = true;

        numAddressesWhitelisted += 1;
    }

    function removeAddress(address _addressToRemove) public onlyOwner {
        require(
            whitelistedAddresses[msg.sender],
            "Address has not been whitelisted"
        );

        whitelistedAddresses[_addressToRemove] = false;

        numAddressesWhitelisted -= 1;
    }
}