// SPDX-License-Identifier: MIT

pragma solidity >=0.4.16 <0.9.0;

error crowdFunding_NotOwner();

contract crowdFunding {
    address[] public s_funders;
    address immutable owner;
    mapping(address => uint256) public s_addressToAmountFunded;
    uint256 public amount;

    modifier onlyOwner() {
        // if msg.sender != owner revert
        if (msg.sender != owner) revert crowdFunding_NotOwner();
        _;
    }

    constructor() {
        owner = payable(msg.sender);
        amount = 2 ether;
    }

    function fund() public payable {
        // funder.transfer(10);
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function withdraw() public payable onlyOwner {
        for (
            uint128 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success);
    }
}