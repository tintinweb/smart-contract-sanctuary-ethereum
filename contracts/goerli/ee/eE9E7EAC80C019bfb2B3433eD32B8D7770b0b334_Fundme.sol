//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Fundme {
    address immutable ownerAddress;
    address[] public funders;
    mapping(address => uint256) public fundersToAmount;

    constructor() {
        ownerAddress = msg.sender;
    }

    function FundMe() public payable {
        require(msg.value >= 1e18, "Not enough funds");
        funders.push(msg.sender);
        fundersToAmount[msg.sender] += msg.value;
    }

    function withdraw() public payable OnlyOwner {
        (bool sendStatus, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(sendStatus, "Transaction failed");

        for (uint256 index = 0; index < funders.length; index++) {
            fundersToAmount[funders[index]] = 0;
        }

        funders = new address[](0);
    }

    modifier OnlyOwner() {
        require(
            msg.sender == ownerAddress,
            "Not authorised to call this function"
        );
        _;
    }

    receive() external payable {
        FundMe();
    }

    fallback() external {
        FundMe();
    }
}