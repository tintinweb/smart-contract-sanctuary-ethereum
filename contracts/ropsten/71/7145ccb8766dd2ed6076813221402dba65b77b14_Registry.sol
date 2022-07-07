/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// Solidity contract with one function called prependIpfsCid which may only be called by the owner of the contract. The function takes a string and prepends it to the array of ipfs cids.
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract Registry {
    string[] public ipfsCids;
    address public owner;

    function prependIpfsCid(string memory _ipfsCid) public {
        require(msg.sender == owner);
        ipfsCids.push(_ipfsCid);
    }
}