/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

pragma solidity ^0.8.11;

contract Deposit {
    address payable private owner;
    event depositInfo(address sender, uint amount);
    event withdrawInfo(uint time, uint amount);

    mapping(address => uint) public holderBalance;
    mapping(address => bool) public verifyHolder;

    receive() external payable {}
    fallback() external {}

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOnwer {
        require(msg.sender == owner, "You are not a contract owner");
        _;
    }

    modifier verifyDeposit(address _recipient) {
        require(verifyHolder[_recipient] == true, "You are not a deposit owner");
        _;
    }

    modifier checkBalance(address _recipient, uint _amount) {
        require(holderBalance[_recipient] > _amount, "Incorrect amount");
        _;
    }

    function depositSend(address payable to) public payable {
        to.send(msg.value);
        emit depositInfo(msg.sender, msg.value);
        verifyHolder[msg.sender] = true;
        holderBalance[msg.sender] += msg.value;
    }

    function withdraw(uint amount) external onlyOnwer {
        require(address(this).balance >= amount, "Incorrect amount");
        payable(msg.sender).transfer(amount);
        emit withdrawInfo(block.timestamp, amount);
    }

    function withdrawHolder(address payable recipient, uint256 amount) public payable
        verifyDeposit(recipient)
        checkBalance(recipient, amount)
    {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Failed to withdraw Ether");
        holderBalance[msg.sender] -= amount;
    }

    function getBalance() public view onlyOnwer returns (uint) {
        return address(this).balance;
    }
}