// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract wallet {
    mapping(address => uint256) public paymentRecord;
    address[] records;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);

        _;
    }

    function deposit() public payable {
        paymentRecord[msg.sender] += msg.value;
        records.push(msg.sender);
    }

    function pay(address payable toAddress, uint256 amount) public onlyOwner {
        bool sent = toAddress.send(amount);
        require(sent, "Transaction Failed");
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }
}