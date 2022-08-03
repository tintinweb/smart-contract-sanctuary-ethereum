/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BuyMeACoffee {
    //Event to emit when a Memo created.
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );

    //Memo struct
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    //List of all Memo's received from friends
    Memo[] memos;

    //Address of contract deployer
    address payable owner;

    //Deploy logic
    constructor() {
        owner = payable(msg.sender);
    }

    function buyCoffee(string memory _name, string memory _message) public payable {
        require(msg.value > 0, "Can't buy coffee with 0 Eth");

        memos.push(Memo(msg.sender, block.timestamp, _name, _message));

        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }

    function getMemos() public view returns(Memo[] memory){
        return memos;
    }
}