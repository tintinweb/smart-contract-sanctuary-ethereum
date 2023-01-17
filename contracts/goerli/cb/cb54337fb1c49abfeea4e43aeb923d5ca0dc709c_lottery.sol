/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract lottery{
    mapping (address => uint256) user;
    uint256 total_users;
    uint256 winning_users;
    uint256 winning_number1;
    uint256 winning_number2;
    uint256 winning_number3;
    uint256 winning_number4;
    uint256 winning_number5;

    uint256 winning_ether;
    address owner;

    constructor () {
        owner = msg.sender;
    }
    function lottery_in(uint256 number) public payable {
        if (msg.value == 0.01 ether) {
            if (user[msg.sender] == 0) {
                user[msg.sender] = number;
                total_users = total_users + 1;
            }
            else {
                revert();
            }
            
        }
        else {
            revert();
        }
    }

    function lottery_set(uint256 number) public {
        if (owner != msg.sender) {
            revert();
        }
        else if (number == winning_number1) {
            revert();
        }
        else if (number == winning_number2) {
            revert();
        }
        else if (number == winning_number3) {
            revert();
        }
        else if (number == winning_number4) {
            revert();
        }
        else if (number == winning_number5) {
            revert();
        }

        else {
            if (winning_number1 == 0) {
                winning_number1 = number;
                winning_users = winning_users + 1;
            }
            else if (winning_number2 == 0) {
                winning_number2 = number;
                winning_users = winning_users + 1;
            }
            else if (winning_number3 == 0) {
                winning_number3 = number;
                winning_users = winning_users + 1;
            }
            else if (winning_number4 == 0) {
                winning_number4 = number;
                winning_users = winning_users + 1;
            }
            else if (winning_number5 == 0) {
                winning_number5 = number;
                winning_users = winning_users + 1;
            }
            winning_ether = address(this).balance / winning_users;
        }
    }

 
    function claim() public {
        if (user[msg.sender] == winning_number1) {
            if (user[msg.sender] != 0) {
            address payable to = payable(msg.sender);
            to.transfer(winning_ether);
            user[msg.sender] = 0;
            }
        }
        else if (user[msg.sender] == winning_number2) {
            if (user[msg.sender] != 0) {
                address payable to = payable(msg.sender);
                to.transfer(winning_ether);
                user[msg.sender] = 0;
            }
        }
        else if (user[msg.sender] == winning_number3) {
            if (user[msg.sender] != 0) {
                address payable to = payable(msg.sender);
                to.transfer(winning_ether);
                user[msg.sender] = 0;
            }
        }
        else if (user[msg.sender] == winning_number4) {
            if (user[msg.sender] != 0) {
                address payable to = payable(msg.sender);
                to.transfer(winning_ether);
                user[msg.sender] = 0;
            }
        }
        else if (user[msg.sender] == winning_number5) {
            if (user[msg.sender] != 0) {
                address payable to = payable(msg.sender);
                to.transfer(winning_ether);
                user[msg.sender] = 0;
            }
        }

    }
}