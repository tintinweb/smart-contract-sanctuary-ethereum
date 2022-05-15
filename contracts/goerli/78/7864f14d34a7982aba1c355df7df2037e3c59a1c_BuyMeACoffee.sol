/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BuyMeACoffee {
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );

    struct Memo{
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    address payable owner;
    address payable recipient;

    Memo[] memos;

    constructor (){
        owner = payable(msg.sender);
        recipient = owner;
    }

    function buyCoffee(string memory _name, string memory _message) public payable {
        require(msg.value > 0, "Can't buy coffee with 0 eth");

        memos.push(Memo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));

        emit NewMemo (
            msg.sender,
            block.timestamp,
            _name,
            _message
        );
    }

    function changeRecipient(address payable _recipient) public {
        require(msg.sender == owner, "You are not allowed to change the withdrawal address");
        recipient = _recipient;
    }

    function withdrawTips() public {
        require(recipient.send(address(this).balance));
    }

    function getMemos() public view returns (Memo[] memory){
        return memos;

    }
}