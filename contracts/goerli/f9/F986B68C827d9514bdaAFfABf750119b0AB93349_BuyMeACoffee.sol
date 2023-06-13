/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
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

    // deploy logic
    constructor() {
        owner = payable(msg.sender);
    }

    function buyCoffee(string memory _name, string memory _message) public payable {
        require(msg.value > 0, "Can't buy coffee with 0 eth");

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
            _message);
    }

    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }

    // view is to send a signal that nothing will be changed state on the blockchain
    // and it will save on gas fee
    function getMemos() public view returns(Memo [] memory){
        return memos;
    }
}