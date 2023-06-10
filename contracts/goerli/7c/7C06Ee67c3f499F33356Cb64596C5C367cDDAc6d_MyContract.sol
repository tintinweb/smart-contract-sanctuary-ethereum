// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
    uint256 totalCoffee;
    address payable public owner;

    constructor() payable {
        owner = payable(msg.sender);
    }

    // this Event will happen everytime someone buys a coffee
    // record this transaction and log it on the blockchain
    // deleted string message,
    event NewCoffee (
        address indexed from,
        uint256 timestamp,
        string name
    );

    struct Coffee {
        address sender;
        string message;
        string name;
        uint256 timestamp;
    }

    // coffee array
    Coffee[] coffee;

    // returns coffee array
    function getAllCoffee() public view returns (Coffee[] memory){
        return coffee;
    }

    // returns totalCoffee variable which increases whenever 
    // someone buys a new coffee
    function getTotalCoffee() public view returns (uint256){
        return totalCoffee;
    }

    // buy coffee function
    function buyCoffee(
        string memory _message,
        string memory _name
    ) payable public {
        require(msg.value == 0.01 ether, "You need to pay 0.01 ETH");

        totalCoffee += 1;
        coffee.push(Coffee(msg.sender, _message, _name, block.timestamp));

        // send the funds to the owner
        (bool success,) = owner.call{value: msg.value}("");
        require(success, "Failed to send Ether to owner");

        // emit the event when the transaction goes through 
        emit NewCoffee(msg.sender, block.timestamp, _name);
    }

}