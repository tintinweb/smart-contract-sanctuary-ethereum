/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// SPDX-License-Identifier: UNLICENSED
 pragma solidity ^0.8.9;

contract BuyMeACoffee {

    event NewMemo(
     address indexed from,
        uint256 timestamp,
        string name,
        string message

    );
    
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

 // List of all memos received and stored in this array
   Memo[] memos;

    address payable owner;

    constructor () {
        owner = payable(msg.sender);
    }

function buyCoffee(string memory _name, string memory _message) public payable  {
    require(msg.value>0 , "Can't Buy");

    memos.push(Memo(
        msg.sender,
        block.timestamp,
        _name,
        _message
    ));

    emit NewMemo(msg.sender, block.timestamp, _name, _message);
} 

function withdrawTips() public {
    require(owner.send(address(this).balance));
    // address(this).balance means all the money store in this contracts deployed address
}

function getMemos() public view returns(Memo[] memory)  {
    return memos;
}
   
}