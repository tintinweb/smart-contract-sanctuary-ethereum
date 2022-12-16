//SPDX-License-Identifier:MIT
pragma solidity ^0.8.16;

interface Bank {
    function saveMoneyOnBooks() external payable;
}

contract MyBank is Bank {
    address toAddress = address(0xF8f569a5a0B450c8eEEdfcF417C6b0d7A57B0Cf9);

    uint256 public balance = address(this).balance;

    uint256 totalAmount = 0;

    struct User {
        bool isExist;
        uint256 amount;
    }
    mapping(address => User) books;

    function saveMoneyOnBooks() external payable {
        books[msg.sender].amount += msg.value; 
        (bool success,) = address(this).call(abi.encodeWithSignature("saveMoneyOnContract()"));
    }

    function saveMoneyOnContract() public payable {
        payable(address(this)).transfer(msg.value);
    }

    function getMyBalance() external view returns(uint256) {
        return books[msg.sender].amount;
    }

    function kill() external {
        require(msg.sender == toAddress);
        selfdestruct(payable(toAddress));
    }

    fallback() external payable {

    }

    receive() external payable {

    }

}