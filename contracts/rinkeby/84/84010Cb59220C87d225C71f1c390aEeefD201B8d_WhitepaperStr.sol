/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;



// File: WhitepaperStr.sol

contract WhitepaperStr {
    address public owner;
    string storedData;

    constructor() public {
        owner = msg.sender;
    }

    string reveal = "fd1643fd9e57e15e443c9916607c2176220805a7";

    string message = "This is the content";

    function Content() public view returns (string memory) {
        return message;
    }

    function Reveal() public view returns (string memory) {
        return reveal;
    }

    function timestamp() public view returns (uint256) {
        return now;
    }

    function disown() public {
        require(msg.sender == owner);
        delete owner;
    }
}