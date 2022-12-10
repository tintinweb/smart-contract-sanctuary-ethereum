//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract Whitelist {
    // The number of accounts we want to have in our whitelist.
    uint256 public maxNumberOfWhitelistedAddresses;

    // Track the number of whitelisted addresses.
    uint256 public numberOfAddressesWhitelisted;

    // The owner of the contract
    address owner;

    // To store our addresses, we need to create a mapping that will receive the user's address and return if he is whitelisted or not.
    mapping(address => bool) whitelistedAddresses;

    constructor(uint256 _maxWhitelistedAddresses) {
        owner = msg.sender;
        maxNumberOfWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    // Validate only the owner can call the function
    modifier onlyOwner() {
        require(msg.sender == owner, "Error: Caller is not the owner");
        _;
    }

    function addUserAddressToWhitelist(address _addressToWhitelist)
        public
        onlyOwner
    {
        // Validate the caller is not already part of the whitelist.
        require(
            !whitelistedAddresses[_addressToWhitelist],
            "Error: Sender already been whitelisted"
        );

        // Validate if the maximum number of whitelisted addresses is not reached. If not, then throw an error.
        require(
            numberOfAddressesWhitelisted < maxNumberOfWhitelistedAddresses,
            "Error: Whitelist Limit exceeded"
        );

        // Set whitelist boolean to true.
        whitelistedAddresses[_addressToWhitelist] = true;

        // Increasing the count
        numberOfAddressesWhitelisted += 1;
    }

    function verifyUserAddress(address _whitelistedAddress)
        public
        view
        returns (bool)
    {
        // Verifying if the user has been whitelisted
        bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
        return userIsWhitelisted;
    }

 // Is the user whitelisted?
    function isWhitelisted(address _whitelistedAddress)
        public
        view
        returns (bool)
    {
        // Verifying if the user has been whitelisted
        return whitelistedAddresses[_whitelistedAddress];
    }

  // Remove user from whitelist
    function removeUserAddressFromWhitelist(address _addressToRemove)
        public
        onlyOwner
    {
        // Validate the caller is already part of the whitelist.
        require(
            whitelistedAddresses[_addressToRemove],
            "Error: Sender is not whitelisted"
        );

        // Set whitelist boolean to false.
        whitelistedAddresses[_addressToRemove] = false;

        // This will decrease the number of whitelisted addresses.
        numberOfAddressesWhitelisted -= 1;
    }

    // Get the number of whitelisted addresses
    function getNumberOfWhitelistedAddresses() public view returns (uint256) {
        return numberOfAddressesWhitelisted;
    }

    // Get the maximum number of whitelisted addresses
    function getMaxNumberOfWhitelistedAddresses()
        public
        view
        returns (uint256)
    {
        return maxNumberOfWhitelistedAddresses;
    }

    // Get the owner of the contract
    function getOwner() public view returns (address) {
        return owner;
    }
}