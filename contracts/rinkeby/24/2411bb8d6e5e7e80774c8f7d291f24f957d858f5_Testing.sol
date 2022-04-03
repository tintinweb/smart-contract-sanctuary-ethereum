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

    function deposit(uint _amount) payable public {

        require(_amount >= 1 ether, "You need to send at least 1 ether");

        Deposits[msg.sender] += _amount;

        emit Deposit(msg.sender, msg.value);

    }

    function withdraw(uint256 _amount) payable public {

        require(Deposits[msg.sender] > 0, "No deposits");
        require(Deposits[msg.sender] >= 100, "Min withdraw is 100");

        payable(owner).transfer(_amount);
        Deposits[msg.sender] = Deposits[msg.sender] - _amount;
        
        emit Withdraw(msg.sender, _amount);

    }

    function getPool() public view returns (uint256) {
        return address(this).balance;
    }

}