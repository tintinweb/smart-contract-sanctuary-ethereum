// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.16;

contract Whitelist {

    // Max number of whitelisted addresses allowed
    uint8 public maxWhiteListedAddresses;

    // numAddressesWhitelisted would be used to keep track of how many addresses have been whitelisted
    // NOTE: Don't change this variable name, as it will be part of verification
    uint8 public numAddressesWhitelisted;

    // if an address is whitelisted, we would set it to true, it is false by default for all other addresses.
    mapping (address => bool) public addressWhitelisted;

    constructor(uint8 _maxWhiteListedAddresses) {
        maxWhiteListedAddresses = _maxWhiteListedAddresses;
    }

    function addAddressToWhitelist() public {
        // check if user already whitelisted
        require(!addressWhitelisted[address(msg.sender)], "Sender has already been whitelisted.");
        require(numAddressesWhitelisted < maxWhiteListedAddresses, "Max Number of Whitelisted Addresses already reached.");
        addressWhitelisted[address(msg.sender)] = true;
        numAddressesWhitelisted += 1;
    }

    function isAddressWhitelisted(address _addr) external view returns (bool) {
        return addressWhitelisted[_addr];
    }

    function getNumAddressesWhitelisted() public view returns(uint8) {
        return numAddressesWhitelisted;
    }
}