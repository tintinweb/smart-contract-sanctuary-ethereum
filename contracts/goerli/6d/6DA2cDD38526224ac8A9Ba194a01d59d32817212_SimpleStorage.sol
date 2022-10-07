// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract SimpleStorage {
    // State variable to store a number
    uint public num;
    address public owner; // 0x00000000

    constructor () {
        owner = msg.sender;
    }

    event OwnerUpdated(address oldOwner, address newOwner);
    event NumberUpdated(uint newNumber, address indexed user);
    event ReceivedEthereum(address sender, uint amount);

    function changeOwner(address newOwner) onlyOwner public {
        address oldOwner = owner;
        owner = newOwner;

        emit OwnerUpdated(oldOwner, owner);
    }

    // You need to send a transaction to write to a state variable.
    function set(uint _num) public payable higherThanTen(_num) {
        require(msg.value >= 0.001 ether, "Error: not enough money"); //TODO: make fee dynamic
        num = _num;
        emit NumberUpdated(num, msg.sender);
    }

    // You can read from a state variable without sending a transaction.
    function get() public view returns (uint) {
        return num;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    // Modifier to check that the caller is the owner of
    // the contract.
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

    modifier higherThanTen(uint _num) {
        require(_num > 10, "Error: number must be greater than 10");
        _;
    }

    //TODO: add withdraw only by owner
    //https://solidity-by-example.org/sending-ether/

    // Fallback function must be declared as external.
    fallback() external payable {
    }

    receive() external payable {
        emit ReceivedEthereum(msg.sender, msg.value);
    }
}