/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;


contract Buy555920ACoffee {
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
    
    address payable owner;

    Memo[] memos;

    constructor() {
        owner = payable(msg.sender);
    }

    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }

    function buyCoffee(string memory _name, string memory _message) public payable {
        require(msg.value > 0, "can't buy coffee for free!");

        memos.push(Memo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));

        emit NewMemo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        );
    }

    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }
}