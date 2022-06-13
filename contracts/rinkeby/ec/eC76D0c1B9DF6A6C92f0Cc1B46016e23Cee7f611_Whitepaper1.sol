/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;



// File: Whitepaper.sol

contract Whitepaper1 {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function timestamp() public view returns (uint256) {
        return now;
    }

    string public content = "anna lea packt das!";

    function disown() public {
        require(msg.sender == owner);
        delete owner;
    }
}