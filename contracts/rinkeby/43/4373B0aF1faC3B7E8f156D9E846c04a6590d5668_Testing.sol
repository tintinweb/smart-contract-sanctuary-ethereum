// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

contract Testing {

    address public owner;

    mapping(address => uint256) private Deposits;

    event Deposit(address indexed _address, uint256 _amount);
    event Withdraw(address indexed _address, uint256 _amount);

    constructor() {

        owner = msg.sender;

    }

    function deposit() payable public {

        Deposits[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);

    }

    function withdraw() payable public {

        require(Deposits[msg.sender] >= msg.value, "Not enough balance to withdraw");

        payable(owner).transfer(msg.value);
        Deposits[msg.sender] = Deposits[msg.sender] - msg.value;
        
        emit Withdraw(msg.sender, msg.value);

    }

    function getPool() public view returns (uint256) {
        return address(this).balance;
    }

}