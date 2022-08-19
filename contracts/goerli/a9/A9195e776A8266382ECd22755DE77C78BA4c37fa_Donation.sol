// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

/// @title Donate Funds
/// @author Mazen Jamshed
/// @notice Only use on testnet. Not fully tested yet

contract Donation {
    mapping(address => uint256) public addressToAmountDonated; // amount donated by an address

    address private owner; // Deployer
    address[] public supporters; // Array of donators

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner!");
        _;
    }

    function passOwnership(address payable newOwner) public onlyOwner {
        owner = newOwner;
    }

    function Donate() public payable {
        addressToAmountDonated[msg.sender] += msg.value;
        supporters.push(msg.sender);
    }

    function widthdraw() public payable onlyOwner {
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }
}