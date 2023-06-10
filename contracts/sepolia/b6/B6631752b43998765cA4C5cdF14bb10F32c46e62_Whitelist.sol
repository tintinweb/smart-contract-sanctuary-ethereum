// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Whitelist {

    address owner;

    uint8 public maxWhitelistedAddresses;
    
    mapping (address => bool) public whitelistedAddresses;

    uint8 public numAddressesWhitelisted;

    event AddedToWhitelist(address);

    event RemovedFromWhitelist(address);

    constructor(uint8 _maxWhitelistedAddresses) {
        owner = msg.sender;
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    function addAddressToWhitelist() public {
        require(numAddressesWhitelisted < maxWhitelistedAddresses, "Maximum Whitelist Address Reached!");
        require(!whitelistedAddresses[msg.sender], "Already in the Whitelist!");
        
        whitelistedAddresses[msg.sender] = true;
        
        numAddressesWhitelisted += 1;
        
        emit AddedToWhitelist(msg.sender);
    }

    function removeAddressFromWhitelist(address _whitelistedAddress) external onlyOwner {
        require(whitelistedAddresses[_whitelistedAddress], "Not in the Whitelist!");
        
        whitelistedAddresses[_whitelistedAddress] = false;
        
        numAddressesWhitelisted -= 1;
        
        emit RemovedFromWhitelist(_whitelistedAddress);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Not Authorized!");
        _;
    }
}