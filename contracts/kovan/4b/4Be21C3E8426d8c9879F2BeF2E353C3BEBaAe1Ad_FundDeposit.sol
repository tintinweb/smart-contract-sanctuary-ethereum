// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FundDeposit {
    address owner;
    mapping (address => bool) private whiteListedUsers;
    mapping (address => uint) userBalance;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can whitelist the user");
        _;
    }

    function whiteListUser(address user) public onlyOwner {
        whiteListedUsers[user] = true;
    }

    /// @notice only whitelisted users can deposit the funds
    function sendEth() public payable {
        require(whiteListedUsers[msg.sender], "user is not in whitelist");
        require(msg.value != 0, "amount should be more than zero");
        userBalance[msg.sender] += msg.value;

    }

    function myBalance() public view returns (uint) {
        require(whiteListedUsers[msg.sender], "user doesn't exist");
        return userBalance[msg.sender];
    }
}