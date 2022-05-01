// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bounty {
    address public owner;
    string public bounty_name;
    uint256 public bounty_amount;
    string public bounty_link;

    constructor(string memory _bounty_name, string memory _bounty_link) {
        owner = msg.sender;
        bounty_name = _bounty_name;
        bounty_link = _bounty_link;
    }

    function fund_bounty() public payable {
        bounty_amount = address(this).balance;
    }

    function view_bounty() public view returns (address, uint256) {
        return (owner, bounty_amount);

        // Add bounty_name and bounty_link later
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw_bounty() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        bounty_amount = address(this).balance;
    }
}