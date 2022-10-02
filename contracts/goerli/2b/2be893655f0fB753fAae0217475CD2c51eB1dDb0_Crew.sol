//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Crew {
    struct Member{
        bytes32 title;
        uint256 bounty;
    }
    mapping (bytes32 => Member) who;
    function iAm(bytes32 _name,bytes32 _title, uint256 _bounty) public {
        who[_name] = Member(_title, _bounty);
    }
    function whoIs(bytes32 _name) public view returns (Member memory) {
        return who[_name];
    }
}