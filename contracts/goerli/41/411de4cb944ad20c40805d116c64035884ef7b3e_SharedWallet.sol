/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

// SPDX-License-Identifier: MIT
// File: contracts/SharedWallet.sol/SharedWallet_Struct.sol


pragma solidity ^0.8.0;

contract SharedWallet {
    address public admin;
    address[] usersKeys;
    struct User {
        uint256 allowance;
        bool authorized;
        uint256 expires;
    }
    mapping(address => User) public users;
    event LogFundsAdded(address user, uint256 amount);
    event LogFundsSpent(address user, uint256 amount);
    event LogAuthorizationChanged(address user, bool authorized);

    constructor() {
        admin = msg.sender;
    }

    function addFunds() public payable {
        require(msg.sender == admin, "Only admin can add funds.");
        require(msg.value > 0, "Amount must be greater than 0.");
        emit LogFundsAdded(msg.sender, msg.value);
    }

    function authorize(
        address user,
        uint256 allowance,
        uint256 expires
    ) public {
        require(msg.sender == admin, "Only admin can authorize users.");
        require(allowance > 0, "Allowance must be greater than 0.");
        require(expires > block.timestamp, "Expiration must be in the future.");
        users[user].allowance = allowance;
        users[user].authorized = true;
        users[user].expires = expires;
        usersKeys.push(user);
        emit LogAuthorizationChanged(user, true);
    }

    function revoke(address user) public {
        require(msg.sender == admin, "Only admin can revoke authorization.");
        require(users[user].authorized, "User is not authorized.");
        users[user].authorized = false;
        emit LogAuthorizationChanged(user, false);
    }

    function spend(address payable to, uint256 amount) public {
        if (msg.sender == admin) {
            require(amount <= getBalance(), "Insufficient funds.");
            to.transfer(amount);
        } else {
            require(users[msg.sender].authorized, "Sender is not authorized.");
            require(
                users[msg.sender].allowance >= amount,
                "Allowance exceeded."
            );
            require(
                block.timestamp < users[msg.sender].expires,
                "Authorization has expired."
            );
            require(amount <= getBalance(), "Insufficient funds.");
            to.transfer(amount);
            users[msg.sender].allowance -= amount;
        }
        emit LogFundsSpent(msg.sender, amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function checkExpirations() public {
        for (uint256 i = 0; i < usersKeys.length; i++) {
            address user = usersKeys[i];
            if (block.timestamp >= users[user].expires) {
                users[user].authorized = false;
                emit LogAuthorizationChanged(user, false);
            }
        }
    }
}