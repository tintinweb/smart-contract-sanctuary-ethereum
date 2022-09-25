/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

//SPDX-License-Identifier: MIT

pragma solidity =0.8.10;
contract HelloWorld {   
    string public currentString;
    address owner;
    event StringUpdated(string  oldstring,string  newstring,address changedBy);
    event OwnershipTransfered(address previousOwner,address newOwner);
    constructor (address intitalOwner) {
        owner = intitalOwner;
    }
    function setText(string calldata input) public {
        string memory temp = currentString;
        currentString = input;
        emit StringUpdated(temp,input,msg.sender);

    }

    function TransferOwnership(address newOwner) public {
        address temp = owner;
        owner = newOwner;
        emit OwnershipTransfered(temp,newOwner);
    }
}