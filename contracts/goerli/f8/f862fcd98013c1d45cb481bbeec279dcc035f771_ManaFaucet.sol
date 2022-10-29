// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract ManaFaucet {
    address public owner;
    bool public paused = false;
    mapping (address => uint) public timeouts;
    uint public amount = 100 ether;
    uint public cooldown = 24 hours;
    IERC20 public constant MANA = IERC20(0xe7fDae84ACaba2A5Ba817B6E6D8A2d415DBFEdbe);
    
    event ManaGetted(address indexed to, uint indexed amount, uint timestamp);
    event AmountUpdated(address indexed owner, uint indexed oldAmount, uint indexed newAmount, uint timestamp);
    event CooldownUpdated(address indexed owner, uint indexed oldCooldown, uint indexed newCooldown, uint timestamp);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner, uint timestamp);
    event ManaWithdrawal(address indexed owner, uint indexed amount, uint timestamp);
    event Withdrawal(address indexed owner, uint indexed amount, uint timestamp);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "not an owner");
        _;
    }

    modifier notNullAddress(address _address) {
        require(_address != address(0));
        _;
    }

    modifier notManaEmpty() {
        require(MANA.balanceOf(address(this)) > 0, "faucet is empty");
        _;
    }

    modifier greaterThanZero(uint _value) {
        require(_value > 0, "value must be greater than zero");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "faucet paused");
        _;
    }

    modifier whenNotTimeout() {
        require(timeouts[msg.sender] <= block.timestamp - cooldown, "try later");
        _;
    }

    constructor() {
        owner = msg.sender;
    }
    
    function getMana() public whenNotPaused() whenNotTimeout() {
        transferMana(msg.sender, amount);
        timeouts[msg.sender] = block.timestamp;
        emit ManaGetted(msg.sender, amount, block.timestamp);
    }

    function getTimeout() public view returns(uint) {
        return timeouts[msg.sender];
    }

    function setTimeout(uint _timeout) public onlyOwner() {
        timeouts[msg.sender] = _timeout;
    }

    function updateAmount(uint _newAmount) public onlyOwner() greaterThanZero(_newAmount) {
        emit AmountUpdated(msg.sender, amount, _newAmount, block.timestamp);
        amount = _newAmount;
    }

    function updateACooldown(uint _newCooldown) public onlyOwner() greaterThanZero(_newCooldown)  {
        emit CooldownUpdated(msg.sender, cooldown, _newCooldown, block.timestamp);
        cooldown = _newCooldown;
    }

    function manaBalance() public view returns(uint) {
        return manaBalanceOf(address(this));
    }

    function manaBalanceOf(address _address) public view returns(uint) {
        return MANA.balanceOf(_address);
    }

    function withdraw(uint _amount) public onlyOwner() {
        payable(owner).transfer(_amount);
        emit Withdrawal(owner, _amount, block.timestamp);
    }

    function withdrawAll() public onlyOwner() {
        uint balance = address(this).balance;
        payable(owner).transfer(balance);
        emit Withdrawal(owner, balance, block.timestamp);
    }

    function withdrawMana(uint _amount) public onlyOwner() {
        transferMana(owner, _amount);
        emit ManaWithdrawal(owner, _amount, block.timestamp);
    }

    function withdrawAllMana() public onlyOwner() notManaEmpty() {
        uint balance = manaBalance();
        transferMana(owner, balance);
        emit ManaWithdrawal(owner, balance, block.timestamp);
    }

    function transferMana(address _to, uint _amount) private notManaEmpty() {
        MANA.transfer(_to, _amount);
    }

    function transferOwnership(address _newOwner) public onlyOwner() notNullAddress(_newOwner) {
        emit OwnershipTransferred(owner, _newOwner, block.timestamp);
        owner = _newOwner;
    }
    
    function destroyFaucet() public onlyOwner {
        withdrawAllMana();
        selfdestruct(payable(owner));
    }

    receive() external payable {} 
}