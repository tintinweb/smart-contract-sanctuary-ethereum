// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract ManaFaucet {
    address public owner;
    mapping (address => uint) timeouts;
    uint public amount = 100 ether;
    uint public cooldown = 24 hours;
    IERC20 constant MANA = IERC20(0xe7fDae84ACaba2A5Ba817B6E6D8A2d415DBFEdbe);
    uint manaBalance;
    
    event Withdrawal(address indexed to, uint amount, uint timestamp);
    event Deposit(address indexed from, uint amount, uint timestamp);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "not an owner");
        _;
    }

    modifier notEmpty() {
        require(MANA.balanceOf(address(this)) > 0);
        _;
    }

    modifier greaterThanZero(uint _value) {
        require(_value > 0, "value must be greater than zero");
        _;
    }

    constructor() {
        owner = msg.sender;
    }
    
    function withdraw() public notEmpty() {
        require(timeouts[msg.sender] <= block.timestamp - cooldown, "try later");
        MANA.transfer(msg.sender, amount);
        timeouts[msg.sender] = block.timestamp;
        emit Withdrawal(msg.sender, amount, block.timestamp);
    }

    function deposit(uint _amount) public {
        MANA.transferFrom(msg.sender, address(this), _amount);
        manaBalance += _amount;
        emit Deposit(msg.sender, _amount, block.timestamp); 
    }

    function setAmount(uint _amount) public onlyOwner() greaterThanZero(_amount) {
        amount = _amount;
    }

    function setCooldown(uint _cooldown) public onlyOwner() greaterThanZero(_cooldown)  {
        cooldown = _cooldown;
    }

    function balance() public view returns(uint) {
        return MANA.balanceOf(address(this));
    }

    function balanceOf(address _address) public view returns(uint) {
        return MANA.balanceOf(_address);
    }

    fallback() external {
        manaBalance = MANA.balanceOf(address(this));
    }

    receive() external payable {} 
    
    function destroy() public onlyOwner {
        MANA.transfer(owner, MANA.balanceOf(address(this)));
        selfdestruct(payable(owner));
    }
}