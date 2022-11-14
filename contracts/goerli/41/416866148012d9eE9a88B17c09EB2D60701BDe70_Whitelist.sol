// SPDX-License-Identifier: Yod

pragma solidity 0.8.17;

contract Whitelist {
    uint public maxWhiteListAddress;
    uint public numAddressesWhitelisted;
    mapping(address => bool) public whitelistedAddresses;

    constructor(uint _maxWhitelistAdress) {
        maxWhiteListAddress = _maxWhitelistAdress;
    }

    function addAddressToWhitelist() public {
        require(!whitelistedAddresses[msg.sender], "Sender is already whitelisted" );
        require(numAddressesWhitelisted < maxWhiteListAddress, "limit reached" );
        whitelistedAddresses[msg.sender] = true;
        numAddressesWhitelisted += 1;
    }

}