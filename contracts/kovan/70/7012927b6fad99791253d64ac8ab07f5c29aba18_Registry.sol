// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

/**
@title A name registry
@author Sabnock01
@notice You can use this contract to register and release names. A name once
registered cannot be claimed by another until released. 
*/
contract Registry {
    // mapping from names to holders
    mapping (string => address) holder;

    event Registered(address to, string name);
    event Released(address from, string name);

    /**
    @notice Registers a name
    @param name The name to register
     */
    function register(string calldata name) public {
        require(holder[name] == address(0), "Already registered!");
        holder[name] = msg.sender;
        emit Registered(msg.sender, name);
    }

    /**
    @notice Releases a name
    @param name The name to release
     */
    function release(string calldata name) public {
        require(holder[name] == msg.sender, "You haven't registered this!");
        delete holder[name];
        emit Released(msg.sender, name);
    }
}