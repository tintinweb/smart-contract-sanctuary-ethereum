/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract SimpleRegistry {
    mapping(string => address) public owners;

    error AlreadyClaimed();
    error Unauthorized();

    event NameClaimed(string name, address owner);
    event NameReleased(string name, address owner);

    function claim(string calldata name) public {
        if(owners[name] != address(0)){
            revert AlreadyClaimed();
        }

        owners[name] = msg.sender;
        emit NameClaimed(name, msg.sender);
    }

    function release(string calldata name) public {
        if(owners[name] != msg.sender){
            revert Unauthorized();
        }

        delete owners[name];
        emit NameReleased(name, msg.sender);
    }
}