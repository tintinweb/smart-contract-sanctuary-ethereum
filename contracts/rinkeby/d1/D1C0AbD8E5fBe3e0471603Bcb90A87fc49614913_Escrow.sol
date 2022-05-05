/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// File: Escrow.sol

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/access/Ownership.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// contract Escrow is Ownable, ERC20{
contract Escrow {
    address[] public usersActive;
    event Deposit(address indexed _from, uint256 _value);
    event Withdrawal(address indexed _from, uint256 _value);

    struct User {
        uint256 originalBalance;
        uint256 totalDuration;
        uint256 nextPaymentTime;
        uint256 stdPayment;
        uint256 counter;
        uint256 remainingDuration;
        uint256 remainingBalance;
    }

    mapping(address => User) user;

    constructor() {}

    function deposit(uint256 _duration) public payable {
        require(!isActive(), "address in use!");
        require(msg.value > 0, "value too low!");
        require(_duration > 0, "duration cannot be zero!");

        user[msg.sender].counter = 1;
        user[msg.sender].originalBalance = msg.value;
        user[msg.sender].totalDuration = _duration;
        user[msg.sender].nextPaymentTime = block.timestamp + 1 weeks;

        user[msg.sender].remainingBalance = user[msg.sender].originalBalance;
        user[msg.sender].remainingDuration = user[msg.sender].totalDuration;
        user[msg.sender].stdPayment =
            user[msg.sender].originalBalance /
            user[msg.sender].totalDuration;

        usersActive.push(msg.sender);
        emit Deposit(msg.sender, msg.value);
    }

    function isActive() public view returns (bool) {
        for (uint256 i = 0; i < usersActive.length; i++) {
            if (usersActive[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function checkMyWithdrawals() public view returns (uint256) {
        return user[msg.sender].counter;
    }

    function checkRemainingBalance() public view returns (uint256) {
        return user[msg.sender].remainingBalance;
    }

    function checkRemainingDuration() public view returns (uint256) {
        return user[msg.sender].remainingDuration;
    }

    function checkNextWithdrawl() public view returns (uint256) {
        return user[msg.sender].nextPaymentTime;
    }

    function withdraw() public payable {
        require(
            user[msg.sender].counter < user[msg.sender].totalDuration,
            "pre-agreed no. of withdrawals complete"
        );
        require(
            block.timestamp > user[msg.sender].nextPaymentTime,
            "Please wait for next payment release"
        );

        user[msg.sender].counter++;

        if (user[msg.sender].counter == user[msg.sender].totalDuration) {
            payable(msg.sender).transfer(user[msg.sender].remainingBalance);
            emit Withdrawal(msg.sender, user[msg.sender].remainingBalance);

            for (uint256 i; i < usersActive.length; i++) {
                if (usersActive[i] == msg.sender) {
                    delete usersActive[i];
                }
            }
        } else {
            payable(msg.sender).transfer(user[msg.sender].stdPayment);
            emit Withdrawal(msg.sender, user[msg.sender].remainingBalance);

            user[msg.sender].nextPaymentTime = block.timestamp + 1 weeks;
            user[msg.sender].remainingBalance =
                user[msg.sender].remainingBalance -
                (user[msg.sender].stdPayment);
        }
    }
}