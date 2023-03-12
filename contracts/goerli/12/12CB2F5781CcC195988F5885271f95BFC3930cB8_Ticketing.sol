/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
contract Ticketing {
    address public owner;
    mapping(address => uint256) public countTickets;
    constructor() {
        owner = msg.sender;
        countTickets[address(this)] = 100;
    }
    function getCountTickets() public view returns (uint256) {
        return countTickets[address(this)];
    }
    function addTickets(uint256 _count) public onlyOwner {
        countTickets[address(this)] += _count;
    }
    function purchaseTickets(uint256 _count) public payable {
        require(msg.value == _count * 2 ether, "Invalid amount sent!");
        require(countTickets[address(this)] >= _count, "Not enough tickets left!");
        countTickets[address(this)] -= _count;
        countTickets[msg.sender] += _count;
    }
    function useTickets(uint256 _count) public {
        require(countTickets[msg.sender] >= _count, "Not enough tickets available!");
        countTickets[msg.sender] -= _count;
        payable(msg.sender).transfer(_count * 2 ether);
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this operation!");
        _;
    }
}