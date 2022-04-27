// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
@title Simple Name Registry
@author hashedMae
@notice A simple name registry that stores the data on chain
 */
contract Registry {


    ///@notice Mapping of a name to address of currentOwner
     mapping(string => address) public nameToUser;

    ///@dev events for tracking when names are registered or released
    event Registered(address user, string name);
    event Released(address user, string name);

    

     /**
     @notice function to register a name
     @dev emits NameRegistered on success
     @param name string that is being registered
      */
    function registerName(string calldata name) external {
        require(nameToUser[name] == address(0x0), "name is already registered");
        nameToUser[name] = msg.sender;
        emit Registered(msg.sender, name);
    }

    /**
    @notice function to release a name from the user
    @dev emits NameReleased on success
    @param name string that is being released from ownership
     */
    function releaseName(string calldata name) external {
        require(nameToUser[name] == msg.sender, "name can only be released by current owner");
        nameToUser[name] = address(0x0);
        emit Released(msg.sender, name);
    }
}