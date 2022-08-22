/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract BHWallet {
    address payable public owner;

    // account balance
    mapping(address => uint) public balances;

    // events
    event Deposit(address indexed from, uint value);
    event Withdrawal(address indexed to, uint value);
    event ChangeBalance(string action, address indexed to, uint value);
    event ChangeOwner(address indexed oldOwner, address indexed newOwner);

    // constructor
    constructor() {
        owner = payable(msg.sender);
    }

    // deposit ether to the wallet
    function deposit() public payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // withdraw ether from the wallet
    function withdraw(address _to, uint _amount) external {
        require(msg.sender == owner, "caller is not the owner");
        require(balances[_to] >= _amount, "account not enough balance");
        require(
            address(this).balance >= _amount,
            "contract not enough balance"
        );
        balances[_to] -= _amount;
        payable(_to).transfer(_amount);
        emit Withdrawal(_to, _amount);
    }

    // add account balance
    function addBalance(address _to, uint _amount) public {
        require(msg.sender == owner, "caller is not the owner");
        balances[_to] += _amount;
        emit ChangeBalance("Add", msg.sender, _amount);
    }

    // remove account balance
    function removeBalance(address to, uint _amount) public {
        require(msg.sender == owner, "caller is not the owner");
        balances[to] -= _amount;
        emit ChangeBalance("Remove", to, _amount);
    }

    // get account balance
    function getBalance(address _to) external view returns (uint) {
        return balances[_to];
    }

    // get contract balance
    function getContractBalance() external view returns (uint) {
        return address(this).balance;
    }

    // burn all ether to owner
    function burn() public {
        require(msg.sender == owner, "caller is not the owner");
        uint amount = address(this).balance;
        owner.transfer(amount);
        emit Withdrawal(owner, amount);
    }

    // get owner
    function getOwner() public view returns (address) {
        return owner;
    }

    // change owner
    function changeOwner(address _to) public {
        require(msg.sender == owner, "caller is not the owner");
        owner = payable(_to);
        emit ChangeOwner(msg.sender, _to);
    }

    fallback() external payable {
        deposit();
    }

    receive() external payable {
        deposit();
    }
}