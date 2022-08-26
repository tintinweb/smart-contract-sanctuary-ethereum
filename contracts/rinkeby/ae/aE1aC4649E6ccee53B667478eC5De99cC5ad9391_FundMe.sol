// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract FundMe {
address[] public funders; 
address public owner; 
uint256 public amountFunded;
uint256 minimumAmount = 0.01*10**18;
mapping(address => uint256) public addressToAmountFunded; 

    constructor() public {
        owner = msg.sender; 
    }
    function fund() public payable {
        require(msg.value >= minimumAmount, "Amount less than the minimum fee");
        amountFunded += msg.value;
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender); 
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner can withdraw from the Contract");
        _;
    }
    function Withdraw() public payable onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }
}