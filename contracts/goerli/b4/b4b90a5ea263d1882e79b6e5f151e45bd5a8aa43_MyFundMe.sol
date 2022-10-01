// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyFundMe {
    address public owner;
    mapping(address => uint256) public amountFunded;
    address[] public funders;

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not Owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function fund() public payable {
        require(msg.value != 0, "Value caannot be Zero");

        amountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        require(address(this).balance != 0, "Funding is zero");

        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        require(success, "TX failed");

        for (uint256 i = 0; i < funders.length; i++) {
            amountFunded[funders[i]] = 0;
        }

        funders = new address[](0);
    }
}