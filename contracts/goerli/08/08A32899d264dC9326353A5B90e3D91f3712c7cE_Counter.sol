//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Counter {
    uint256 private counter;
    address public owner;
    uint256 public constant SET_PRICE = 0.0001 ether;

    modifier isOwner {
        require(owner == msg.sender, "Should be an owner.");
        _;
    }
    
    constructor(uint256 _counter) {
        owner = msg.sender;
        counter = _counter;
     }

    function getCount() public view returns (uint256) {
        return counter;
    }

    function increment() public {
        counter++;
    }

    function decrement() public {
        require(counter >= 0, "Cannot go below 0");
        counter--;
    }

    function setCounter(uint256 _newCount) public isOwner {
       counter = _newCount;
    }

    function payToSetCounter(uint256 _newCount) public payable {
        require(msg.value == SET_PRICE, "You did not send the correct amount of ethers");

        counter = _newCount;
    }

    function withdrawBalance() public isOwner {
        (bool sent, bytes memory data) = owner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {

    }
}