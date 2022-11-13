// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    uint256 minimum = 2 * 1e18;
    address owner;

    constructor() {
        owner = msg.sender;
    }
    
    function fund() public payable {
        require(msg.value >= minimum, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function amount() view public returns(uint256) {
        return address(this).balance;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++ ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //funders array will be initialized to 0
        funders = new address[](0);
    }

}