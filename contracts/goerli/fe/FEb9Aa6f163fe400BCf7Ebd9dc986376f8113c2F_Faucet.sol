/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

contract Faucet {
    // The address that deployed the contract.
    address public owner;

    // The amount of ether that can be withdrawn in a single request.
    uint public withdrawalLimit;

    // Mapping of address to last withdrawal time.
    mapping(address => uint) public lastWithdrawalTime;

    // Events for logging withdrawals and deposits.
    event Withdrawal(address indexed to, uint amount);
    event Deposit(address indexed from, uint amount);

    // Constructor function that sets the owner and withdrawal limit.
    constructor(uint _withdrawalLimit) {
        owner = msg.sender;
        withdrawalLimit = _withdrawalLimit;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    // Fallback function that allows the contract to accept ether deposits.
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // Owner-only function that can be used to change the withdrawal limit.
    function setWithdrawalLimit(uint _withdrawalLimit) public onlyOwner {
        withdrawalLimit = _withdrawalLimit;
    }

    // Owner-only function that sends ether to the specified address, up to the withdrawal limit.
    function withdraw(address payable to) public onlyOwner {

        require(address(this).balance >= withdrawalLimit, "Insufficient balance");
        require(block.timestamp - lastWithdrawalTime[to] >= 1 days, "You can only withdraw once per 24 hours");

        bool sent = to.send(withdrawalLimit);
        require(sent, "Failed to send ether");

        lastWithdrawalTime[to] = block.timestamp;

        emit Withdrawal(to, withdrawalLimit);
    }
}