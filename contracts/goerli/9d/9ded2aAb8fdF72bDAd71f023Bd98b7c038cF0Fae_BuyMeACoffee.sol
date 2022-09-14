// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
// import "hardhat/console.sol";

contract BuyMeACoffee {
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message);

    struct Memo{
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    Memo[] memos;

    address payable owner;

    constructor(){
        owner = payable(msg.sender);
    }

    
    function buyCoffee(string memory _name, string memory _message) public payable {
        require(msg.value > 0, "Can't buy coffee with 0 ether");
        
        memos.push(Memo(msg.sender, block.timestamp, _name, _message));

        // Emit a log event when a new memo is createed!
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }

    function getMemos() public view returns(Memo[] memory){
        return memos;
    }
    
}