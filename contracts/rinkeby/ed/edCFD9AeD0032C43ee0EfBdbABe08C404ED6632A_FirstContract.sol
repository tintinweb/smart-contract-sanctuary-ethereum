/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FirstContract {
    address public ownerAddress;
    string public owner;

    mapping (address => uint256) whitelist;

    constructor(string memory _name) {
        ownerAddress = msg.sender;
        owner = _name;
    }

    function setName(string memory _name) public {
        owner = _name;
    }

    function addToWhiteList(address _to, uint256 _allow) public {
        require(msg.sender == ownerAddress, "only owner can whitelist");
        whitelist[_to] = _allow;
    }

}