/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error NotOwner();

contract IssueStorage {
    address public immutable i_owner;

    mapping(address => bytes32) public userToCredential;

    constructor(){
        i_owner = msg.sender;
    }

    function issue(address _userPk, address _issuerPk, bytes32 _hashAttr) public {
        bytes memory input = abi.encodePacked(_issuerPk, _hashAttr);
        userToCredential[_userPk] = keccak256(input);
    }

    function getCredential(address _userPk) public view returns(bytes32) {
        return userToCredential[_userPk];
    }

    modifier onlyOwner {
        if(msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }
}