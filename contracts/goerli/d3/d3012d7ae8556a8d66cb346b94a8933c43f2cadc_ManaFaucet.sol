// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract ManaFaucet {
    address public owner;
    mapping (address => uint) timeouts;
    uint amount = 100 ether;
    uint cooldown = 24 hours;
    IERC20 constant MANA = IERC20(0xe7fDae84ACaba2A5Ba817B6E6D8A2d415DBFEdbe);
    
    event Withdrawal(address indexed to, uint timestamp);
    event Deposit(address indexed from, uint amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "not an owner");
        _;
    }

    modifier notEmpty() {
        require(MANA.balanceOf(address(this)) > 0);
        _;
    }

    constructor() {
        owner = msg.sender;
    }
    
    //  Sends 100 MANA to the sender when the faucet has enough funds
    //  Only allows one withdrawal every 24 hours
    function withdraw() public notEmpty() {
        require(timeouts[msg.sender] <= block.timestamp - cooldown, "You can only withdraw once every 24h");
        MANA.transfer(msg.sender, amount);
        timeouts[msg.sender] = block.timestamp;
        emit Withdrawal(msg.sender, block.timestamp);
    }

    function deposit(uint _amount) public payable {
        MANA.transferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, msg.value); 
    }

    function setAmount(uint _amount) public onlyOwner() {
        amount = _amount;
    }

    function setCooldown(uint _cooldown) public onlyOwner() {
        cooldown = _cooldown;
    }

    receive() external payable {} 
    
    function destroy() public onlyOwner {
        selfdestruct(payable(owner));
    }
}