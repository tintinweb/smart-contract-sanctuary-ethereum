/**
 *Submitted for verification at Etherscan.io on 2022-02-04
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

    // владелец депозита
    modifier verifyDeposit(address _recipient) {
        require(verifyHolder[_recipient] == true, "You are not a deposit owner");
        _;
    }

    modifier checkBalance(address _recipient, uint _amount) {
        if (holderBalance[_recipient] < _amount)
            revert("The output value exceeds the balance");
        _;
    }

    function deposit() public payable {
        verifyHolder[msg.sender] = true;
        holderBalance[msg.sender] += msg.value;
        emit depositInfo(msg.sender, msg.value); // записываем в лог отправителя и сумму
    }

    function withdraw(uint amount) external onlyOnwer {
        require(address(this).balance >= amount, "Incorrect amount");
        owner.transfer(amount);
        emit withdrawInfo(block.timestamp, amount);
    }

    // функция вывода средства для держателя
    function withdrawHolder(address payable recipient, uint256 amount) public
        verifyDeposit(recipient)
        checkBalance(recipient, amount)
    {
            recipient.send(amount);
            holderBalance[msg.sender] -= amount;
    }

    function getBalance() public view onlyOnwer returns (uint) {
        return address(this).balance;
    }
}