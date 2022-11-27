/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Whitelist {
    uint8 public maxWhitelistedAddresses;

    mapping(address => bool) public whitelistedAddresses;

    uint8 public numAddressesWhitelisted;

    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    function addAddressToWhitelist() public {
        require(
            !whitelistedAddresses[msg.sender],
            "Whitelist.sol: Sender already whitelisted"
        );
        require(
            numAddressesWhitelisted < maxWhitelistedAddresses,
            "Whitelist.sol: address limits reached"
        );
        whitelistedAddresses[msg.sender] = true;
        numAddressesWhitelisted += 1;
    }
}