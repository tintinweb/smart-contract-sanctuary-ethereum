/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract PurposeSetter{

address private owner;
string public purpose;

event PurposeSet(address msgSetter, string newMessage);
event OwnerSet(address indexed oldOwner, address indexed newOwner);

constructor() {
        
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        purpose = "default";
        emit OwnerSet(address(0), owner);
        emit PurposeSet(owner, purpose);
    }

function setNewPurpose(string memory newMessage) public {
    purpose = newMessage;
    emit PurposeSet(msg.sender, newMessage);
}

function getPurpose() external view returns (string memory){
    return purpose;

}}