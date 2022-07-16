// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Member{
    mapping(address => bool) public listMember;
    function addMember(address[] memory _members) external {
            for(uint256 i=0 ; i< _members.length;i++)
            {
                listMember[_members[i]]=true;
            }
    }
      function removeMember(address[] memory _members) external {
            for(uint256 i=0 ; i< _members.length;i++)
            {
                listMember[_members[i]]=false;
            }
    }
}