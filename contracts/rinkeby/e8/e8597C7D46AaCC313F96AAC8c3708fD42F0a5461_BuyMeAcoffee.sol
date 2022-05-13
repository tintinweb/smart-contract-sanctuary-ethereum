//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract BuyMeAcoffee {

    event NewMemo(
        address indexed from,
        uint timestamp,
        string name,
        string message
    );

    struct Memo{
        address from;
        uint timestamp;
        string name;
        string mesaage;
    }

    Memo[] memos;

    address payable owner;

constructor (){
    owner = payable(msg.sender);

}

function buyCoffee(string memory _name, string memory _message) public payable {
    require(msg.value > 0, "can't buy coffe with 0 ether");


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
 
function getmemos() public view returns(Memo[] memory) {
    return memos;

}




}