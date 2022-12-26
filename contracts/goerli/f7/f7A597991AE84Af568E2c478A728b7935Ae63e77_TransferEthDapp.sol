// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TransferEthDapp {
    address payable owner;
    struct Memo{
        string name;
        string message;
        uint timestamp;
        address from;
    }
    Memo[] memos;

    constructor(){
        owner = payable(msg.sender);
    }
    function buyProduct(string memory name, string memory message) public payable {
        require(msg.value > 0, "The value should be greater then 0");
        owner.transfer(msg.value);
        memos.push(Memo(name, message, block.timestamp,msg.sender));
    }
    function getMemos() public view returns(Memo[] memory){
        return memos;
    }
}