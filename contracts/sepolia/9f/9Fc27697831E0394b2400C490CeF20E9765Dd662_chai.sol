/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License Identifier MIT;

pragma solidity >= 0.5.0 < 0.9.0;


contract chai {
    struct Memo{
            string name;
            string message;
            uint timestamp;
            address from;
    }
    address payable owner;
    constructor(){
        owner = payable(msg.sender);
    }

    Memo[] memos;
    function buyChai (string memory name, string memory message) public payable{
        require( msg.value >= 0, "Please pay greater than 0 ether");
        owner.transfer(msg.value);
        memos.push(Memo(name,message,block.timestamp,msg.sender));

    }

      function getMemos() public view returns (Memo[] memory) {
        return memos;
    }
}