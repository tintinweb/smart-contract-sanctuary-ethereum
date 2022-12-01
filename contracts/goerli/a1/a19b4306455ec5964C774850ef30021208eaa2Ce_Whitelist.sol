// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*//////////////////////////////////////////////////////////////   
                        Custom Errors
//////////////////////////////////////////////////////////////*/
error addAddressToWhitelist_SenderAlreadyWhitelisted();
error addAddressToWhitelist_AddressesLimitReached();

/// @title Whitelist dApp
/// @author Kehinde A.
/// @notice You can use this contract for creating a whitelist dapp when you are launching your NFT collection
contract Whitelist {
    /*//////////////////////////////////////////////////////////////   
                            Variables
    //////////////////////////////////////////////////////////////*/

    //Max number of whitelisted addresses allowed
    uint8 private immutable i_maxWhitelistedAddresses;

    // Create a mapping of whitelistedAddresses
    // if an address is whitelisted, we would set it to true, it is false by default for all other addresses.
    mapping(address => bool) public s_whitelistedAddresses;

    // numAddressesWhitelisted would be used to keep track of how many addresses have been whitelisted
    // NOTE: Don't change this variable name, as it will be part of verification
    uint8 s_numAddressesWhitelisted;

    /*//////////////////////////////////////////////////////////////   
                        Constructor Functions
    //////////////////////////////////////////////////////////////*/

    // Setting the Max number of whitelisted addresses
    // User will put the value at the time of deployment
    constructor(uint8 _maxWhitelistedAddresses) {
        i_maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    /*//////////////////////////////////////////////////////////////   
                            Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice This function adds the address of the sender to the whitelist
    function addAddressToWhitelist() public {
        //check if the user has already been whitelisted
        if (s_whitelistedAddresses[msg.sender]) {
            revert addAddressToWhitelist_SenderAlreadyWhitelisted();
        }

        // check if the numAddressesWhitelisted > maxWhitelistedAddresses, if not then throw an error.
        if (s_numAddressesWhitelisted > i_maxWhitelistedAddresses) {
            revert addAddressToWhitelist_AddressesLimitReached();
        }

        // Add the address which called the function to the whitelistedAddress array
        s_whitelistedAddresses[msg.sender] = true;

        // Increase the number of whitelisted addresses
        s_numAddressesWhitelisted += 1;
    }

    /*//////////////////////////////////////////////////////////////   
                            Getter Functions
    //////////////////////////////////////////////////////////////*/
    function getMaxWhitelistedAddresses() public view returns (uint8) {
        return i_maxWhitelistedAddresses;
    }

    function getWhitelistedAddresses(address index) public view returns (bool) {
        return s_whitelistedAddresses[index];
    }

    function getNumAddressesWhitelisted() public view returns (uint8) {
        return s_numAddressesWhitelisted;
    }
}
/**
 * Contract deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
 */