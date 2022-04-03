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

    function withdraw(uint256 _amount) public {

        require(Deposits[msg.sender] >= _amount, "Not enough balance to withdraw");

        payable(owner).transfer(_amount);
        Deposits[msg.sender] = Deposits[msg.sender] - _amount;
        
        emit Withdraw(msg.sender, _amount);

    }

    function balance(address _address) public view returns (uint256){
        return Deposits[_address];
    }

    function myBalance() public view returns (uint256) {
        return Deposits[msg.sender];
    }

    function getPool() public view returns (uint256) {
        return address(this).balance;
    }

}