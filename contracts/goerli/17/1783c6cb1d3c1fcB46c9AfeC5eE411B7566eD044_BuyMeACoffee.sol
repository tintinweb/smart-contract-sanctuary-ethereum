/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract BuyMeACoffee {
    // Memo Struct to store the memo
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    // event to emit when a memo is created
    event MemoCreated(address from, uint256 timestamp, string name, string message);

    // Address of the owner of the contract. Should be payable to be able to receive funds
    address payable public owner;

    // Memos array to store all the memos
    Memo[] public memos;

    // constructor to
    // // set the owner of the contract
    constructor() {
        owner = payable(msg.sender);
    }

    /**
    * @dev Function to fetch all the memos
    */

    /**
    * @dev Function to buy a coffee to the owner of the contract
    * @param _name name of the person who is buying the coffee
    * @param _message message to be sent to the owner of the contract
    */
    function buyCoffee(string calldata _name, string calldata _message) public payable {
        // check if the value sent is greater than 0.001
        require(msg.value > 0.001 ether, "Value should be greater than 0.001");

        // add the memo to the memos array
        memos.push(Memo(msg.sender, block.timestamp, _name, _message));

        // emit the MemoCreated event
        emit MemoCreated(msg.sender, block.timestamp, _name, _message);

    }

    /**
    * @dev Function to withdraw the funds to the owner of the contract
    */
    function withdraw() public {
        // check if the caller is the owner of the contract
        require(msg.sender == owner, "Only the owner can withdraw the funds.");

        // transfer the funds to the owner
        owner.transfer(address(this).balance);
    }

}