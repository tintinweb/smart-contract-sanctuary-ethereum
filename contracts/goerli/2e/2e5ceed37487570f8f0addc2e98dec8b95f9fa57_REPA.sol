/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract REPA {
    mapping(address => mapping(string => string)) public SocialMedia;

    function set(string memory _id, string memory _data) public {
        SocialMedia[msg.sender][_id] = _data;
    }

    function get(string memory _id, address _user) public view returns (bool) {
        bytes memory tempTest = bytes(SocialMedia[_user][_id]);

        if (tempTest.length == 0) {
            return false;
        } else {
            return true;
        }
    }
}