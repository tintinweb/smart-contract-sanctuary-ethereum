/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

contract SimpleStorageLichessUser {

    event storedLichessUser(
        string indexed newLichessUser,
        string addedLichessUser,
        address sender
    );

    function store(string memory _newLichessUser) public {
        emit storedLichessUser(
            _newLichessUser,
            _newLichessUser,
            msg.sender
        );
    }

}