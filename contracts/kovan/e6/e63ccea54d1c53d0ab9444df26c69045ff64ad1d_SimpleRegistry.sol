// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

 /// @title A simple name registry
 /// @author davidbrai
 /// @notice Use this contract for claiming names. A name can be claimed by only one address. A name can be released by the claimer.
contract SimpleRegistry {

    mapping(string => address) public owners;

    error Unauthorized();
    error AlreadyClaimed();

    event NameClaimed(string name, address owner);
    event NameReleased(string name, address owner);

    /// @notice Claims a name. Reverts if a name was already claimed
    /// @param name The name to be claimed
    function claim(string calldata name) public {
        if (owners[name] != address(0)) {
            revert AlreadyClaimed();
        }

        owners[name] = msg.sender;
        emit NameClaimed(name, msg.sender);
    }

    /// @notice Releases a previously claimed name. Only the owner who claimed the name can release it
    /// @param name The name to be released
    function release(string calldata name) public {
        if (msg.sender != owners[name]) {
            revert Unauthorized();
        }

        delete owners[name];
        emit NameReleased(name, msg.sender);
    }
}