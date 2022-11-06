// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Whitelist {
    // max number of whitelisted addresses allowed
    uint256 public maxWhitelistedAddresses;

    // create a mapping of whitelistedAddress
    // if an address is whitelisted, we would set it true, it is false by default for all other address
    mapping(address => bool) public whitelistedAddresses;
    // numAddressWhitelisted would be used to keeep track of how many address have been whitelisted
    // NOTE: Don't change this variable name, as it will be party of verification
    uint8 public numAddressesWhitelisted;

    // setting the Max number of whitelisted address
    // user will put the value at the time of deployment
    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    /**
     * addressToWhitelist - This function adds the address of the sender to whitelist
     */
    function addAddressToWhitelist() public {
        // check if the user has already been whitelisted
        require(!whitelistedAddresses[msg.sender], "sender has already been whitelisted");
        // check if the numAddressWhitelisted < mazWhitelistedAddresses, if not then throw an error
        require(
            numAddressesWhitelisted < maxWhitelistedAddresses,
            "more addrres cant be added, limit reached"
        );
        // add the addresses which called the function tot he whitelistedAddress array
        whitelistedAddresses[msg.sender] = true;
        // increase the number of whitelisted address
        numAddressesWhitelisted += 1;
    }

    // return the number of address whitelited
    function getNumberOfWhitelisted() public view returns (uint8) {
        return numAddressesWhitelisted;
    }
}