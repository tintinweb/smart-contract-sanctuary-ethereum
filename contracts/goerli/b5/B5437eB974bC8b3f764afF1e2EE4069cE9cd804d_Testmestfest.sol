// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// @author: mr unbekannt boys
contract Testmestfest {
    address payable public owner;
    uint256 public favoriteNumber = 8;
    mapping(address => uint) balances;

    event Withdrawal(uint amount, uint when);

    constructor() payable {
        owner = payable(msg.sender);
    }

    function changeFaveNumber(uint256 _newNumber) public {
        favoriteNumber = _newNumber;
    }

    function withdraw() public {
        require(msg.sender == owner, "You aren't the owner");
        emit Withdrawal(address(this).balance, block.timestamp);
        owner.transfer(address(this).balance);
    }

    function depositFunds() payable external {
        require(msg.value == 0.001 ether);
        balances[msg.sender] += msg.value;
    }

    receive() external payable {}
}