/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract BuyMeACoffee {
 // event to emit when a memo is created
 event newMemo(

    address indexed from,
    uint256 timestamp,
    string name,
    string message
 );
// memo struct
struct Memo{
    address from;
    uint256 timestamp;
    string name;
    string message;
}
    //list of all memos 
    Memo[] memos;

    address payable owner;

    constructor(){
        owner = payable(msg.sender);
    }
    function buyCoffee(string memory _name,string memory _message) public payable {
        require(msg.value >0,"dong have enought eth");
        memos.push(Memo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));
        emit newMemo( 
            msg.sender,
            block.timestamp,
            _name,
            _message);
    }
    function withdraw() public {
        require(owner.send(address(this).balance));
    }
    function getMemos() public view returns(Memo[] memory){
        return memos;
    }
}