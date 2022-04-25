/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
@title An on-chain name registry
@author Calnix
@notice A registed name can be released, availing to be registered by another user
*/
contract SimpleNameRegister {
    
    /// @notice Map a name to an address to identify current holder 
    mapping (string => address) public holder;    

    /// @notice Emit event when a name is registered
    event Register(address indexed holder, string name);

    /// @notice Emit event when a name is released
    event Release(address indexed holder, string name);

    /// @notice User can register an available name
    /// @param name The string to register
    function register(string calldata name) public {
        require(holder[name] == address(0), "Already registered!");
        holder[name] = msg.sender;
        emit Register(msg.sender, name);
    }

    /// @notice Holder can release a name, making it available
    /// @param name The string to release
    function release(string calldata name) public {
        require(holder[name] == msg.sender, "Not your name!");
        delete holder[name];
        emit Release(msg.sender, name);
    }
}