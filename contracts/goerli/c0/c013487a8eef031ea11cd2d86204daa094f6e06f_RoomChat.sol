/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract RoomChat {
    uint id;
    address admin;

    /* EVENTS */
    event NewMessage(uint id, address owner, string content);    
    event NewLike(uint id, address liker);    
    event HideMessage(uint id);

    /* ERRORS */
    error NotAuthorised();
    error MessageDoesntExist();

    constructor() {
        admin = msg.sender;
    }

    function postMessage(string calldata content) external {
        emit NewMessage(id, msg.sender, content);
        unchecked {
            ++id;
        }
    }

    function hideMessage(uint _id) external {
        if (msg.sender != admin) revert NotAuthorised();
        emit HideMessage(_id);
    }

    function likeMessage(uint _id) external {
        if (_id > id) revert MessageDoesntExist();
        emit NewLike(_id, msg.sender);
    }

    function setAdmin(address newAdmin) external {
        if (msg.sender != admin) revert NotAuthorised();
        admin = newAdmin;
    }
}