/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

pragma solidity ^0.8.4;

contract whitelist {
    // Max number of whitelisted addresses allowed
    uint8 public maxWhitelistedAddresses;
    uint8 public numAddressesWhitelisted = 0;

    mapping(address => bool) public whitelistedAddresses;

    // Setting the Max number of whitelisted addresses
    // User will put the value at the time of deployment
    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    function addAddressToWhitelist() public {
        require(
            !whitelistedAddresses[msg.sender],
            "You are already in the list"
        );
        require(
            numAddressesWhitelisted > 10,
            "Max list"
        );

        //else whitelist the address
        whitelistedAddresses[msg.sender] = true;
        numAddressesWhitelisted++;
    }
}