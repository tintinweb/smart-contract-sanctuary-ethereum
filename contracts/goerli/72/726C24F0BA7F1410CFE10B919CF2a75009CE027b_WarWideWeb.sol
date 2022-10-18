// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract WarWideWeb {
    address public owner;
    address private admin;
    address private dev_address = 0x02AAC4407e220Ef6B9289521BC85676aC61Dbc77;

    mapping(address => uint256) balances;
    mapping(address => bool) locked;

    uint256 public initialFee;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);
    event OwnershipTransferred(address indexed owner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyDev() {
        require(msg.sender == dev_address, "Only Dev can call this function.");
        _;
    }

    modifier onlyUnlocked() {
        require(locked[msg.sender] == false, "Can not call this function.");
        _;
    }

    constructor(uint256 _initialFee) {
        owner = msg.sender;
        initialFee = _initialFee;
    }

    function deposit() external payable {
        emit Deposited(msg.sender, msg.value);
        balances[msg.sender] += msg.value;
    }

    function payGameFee() external payable {
        require(msg.value >= initialFee, "inefficient value");
        balances[owner] += msg.value/2;
        balances[dev_address] += msg.value / 2;
    }

    function withdraw(uint256 amount) external onlyUnlocked {
        require(balances[msg.sender] >= amount, "inefficient value");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function lock(address _address) external onlyAdmin {
        require(!locked[_address]);
        locked[_address] = true;
    }

    function unLock(address _address) external onlyAdmin {
        require(locked[_address]);
        locked[_address] = false;
    }

    function setFee(uint256 _fee) external onlyOwner {
        initialFee = _fee;
    }

    function getFee() external view returns (uint256) {
        return initialFee;
    }

    function calculate(
        address _address1,
        address _address2,
        uint256 amount
    ) external onlyAdmin {
        require(
            balances[_address2] >= amount,
            "Balance is less than the room cost."
        );
        balances[_address2] -= amount;
        balances[_address1] += amount;
    }

    function balanceOf(address _address) external view returns (uint256) {
        return balances[_address];
    }

    function getTotalBalance() external view onlyAdmin returns (uint256) {
        return address(this).balance;
    }

    function withdrawOwnerFee(uint256 amount) external onlyOwner {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function withdrawDevFee(uint256 amount) external onlyDev {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setAdmin(address _address) external onlyOwner {
        admin = _address;
    }

    function getAdmin() external view onlyOwner returns (address) {
        return admin;
    }
}