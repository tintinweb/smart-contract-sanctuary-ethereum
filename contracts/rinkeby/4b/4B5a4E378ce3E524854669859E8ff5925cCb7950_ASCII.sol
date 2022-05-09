/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;



// File: ASCII.sol

contract ASCII {
    string public art;
    address private owner;

    constructor(string memory _art) {
        owner = msg.sender;
        art = _art;
        emit Art(_art);
    }

    event Art(string _art);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeArt(string memory _art) public onlyOwner {
        art = _art;
        emit Art(_art);
    }
}