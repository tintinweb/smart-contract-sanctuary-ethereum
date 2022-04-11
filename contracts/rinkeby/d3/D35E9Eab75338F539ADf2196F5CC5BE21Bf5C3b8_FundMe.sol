//SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract FundMe {
    address public owner;
    mapping(address => uint256) public funderToAmount;
    address[] public funders;
    uint256 public total;

    constructor() {
        owner = msg.sender;
    }

    function fund() public payable {
        funders.push(msg.sender);
        funderToAmount[msg.sender] += msg.value;
        total += msg.value;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 i = 0; i < funders.length; i++) {
            funderToAmount[funders[i]] = 0;
        }
        delete funders;
        total = 0;
    }    

    function getAllDonations() public view returns (address[] memory, uint256[] memory) {
        uint256[] memory amount = new uint256[](funders.length);
        for (uint256 i = 0; i < funders.length; i++) {
            amount[i] = funderToAmount[funders[i]];
        }
        return (funders, amount);
    }
}