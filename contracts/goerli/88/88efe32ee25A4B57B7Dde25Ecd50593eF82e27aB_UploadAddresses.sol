// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract UploadAddresses {
    address public owner;
    mapping(address => bool) public members;
    uint256 public membersCount;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor () {
        owner = msg.sender;
    }
    
    function addAddresses(address[] calldata  _members) public onlyOwner {
        uint256 i = 0;

        for(i;i<_members.length;i++){
            address member = _members[i];
            if(members[member] == false){
                members[member] = true;
                membersCount++;
            }
            
        }
    }

    function removeAddresses(address[] calldata  _members)  public onlyOwner {
        uint256 i = 0;

        for(i;i<_members.length;i++){
            address member = _members[i];
            if(members[member] == true){
                members[member] = false;
                membersCount--;
            }
            
        }
    }
}