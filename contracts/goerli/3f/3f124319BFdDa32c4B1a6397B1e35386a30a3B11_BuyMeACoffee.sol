//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract BuyMeACoffee {
    //define state variable
    address payable owner;

    // define data structure
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    // define data structure type
    Memo[] memos;

    // define events
    event MemoHis(address indexed from,uint256 timestamp,string name,string message);

    //define constructor
    constructor(){
        owner=payable(msg.sender);
    }

    //define modifiers
    modifier onlyOwner() {
        require(msg.sender == owner ," you must be the owner");
        _;
    }

    //define Functions
    function buyCoffee(string memory _name , string memory _message) public payable {
        require(msg.value>0 ,"Please provide a valid value");
        memos.push(Memo(msg.sender , block.timestamp , _name , _message));
        emit MemoHis(msg.sender , block.timestamp , _name , _message);
    }
    
    function withdrawTip() public onlyOwner{
        require(owner.send(address(this).balance));
    }
    
    function getMemos() public view returns(Memo[] memory) {
        return memos;
    }



    
}