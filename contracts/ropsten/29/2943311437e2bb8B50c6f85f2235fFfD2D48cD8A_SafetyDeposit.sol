/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

pragma solidity ^0.8.11;

contract SafetyDeposit {
    address payable public owner;

    event DepositInfo(address indexed from, uint256 indexed depositTime, uint256 amount);
    event WithdrawInfo(address indexed to, uint256 indexed withdrawTime, uint256 amount);
    event BlockInfo(address blockTarget, uint blockingAmount, uint indexed blockTime, string blockReason);

    enum Status {Empty, Active, Blocked}

    struct Holder {
        address holder;
        uint balance;
        bool valid;
        Status status;
    }

    mapping(address => Holder) public holders;

    receive() external payable {}
    fallback() external {}

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOnwer {
        require(msg.sender == owner, "You are not a contract owner");
        _;
    }

    modifier onlyHolder(address _holder) {
        require(holders[msg.sender].valid == true, "You are not deposit owner");
        _;
    }

    modifier checkBalance(address _holder, uint _amount) {
        require(holders[_holder].balance >= _amount, "Overflow value of withdrawals");
        _;
    }

    modifier checkOption(uint8 test) {
        require(test == 0 || test == 1, "Use 0 or 1");
        _;
    }

    modifier blockCheck(address _target) {
        if (holders[_target].status == Status.Blocked) {
            revert("Deposit is blocked");
        }
        _;
    }

    function deposit() public payable {
        holders[msg.sender].holder = msg.sender;
        holders[msg.sender].balance += msg.value;
        holders[msg.sender].valid = true;
        holders[msg.sender].status = Status.Active;
        emit DepositInfo(msg.sender, block.timestamp, msg.value);
    }

    function withdrawOptional(uint8 option, uint amount) public onlyOnwer checkOption(option) {
        if (option == 0) { // если введем опцию 0 - выведем указанную сумму
            if (address(this).balance < amount) {
                revert("Overflow value of withdrawals");
            }
            owner.transfer(amount);
        }
        if (option == 1) {
           owner.transfer(address(this).balance);
        }
    }

    function withdrawALL() public onlyOnwer {
            payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawHolder(address payable recipient, uint value) public
        onlyHolder(recipient)
        checkBalance(recipient, value)
        blockCheck(recipient)
    {   
        recipient.send(value);

        holders[recipient].balance -= value;
        if (holders[recipient].balance == 0) {
            holders[recipient].status = Status.Empty;
        }
        emit WithdrawInfo(recipient, block.timestamp, value);
    }

    function getBalance() public view onlyOnwer returns (uint) {
        return address(this).balance;
    }

    function getDepositInfo() public view onlyHolder(msg.sender) returns (
        uint balance,
        bool validation,
        Status _status
    )
    {
        balance = holders[msg.sender].balance;
        validation = holders[msg.sender].valid;
        _status = holders[msg.sender].status;
    }

    function getDepositInfo(address target) public view onlyOnwer returns (
        address holder,
        uint balance,
        bool validation,
        Status _status
    )
    {
        holder = holders[target].holder;
        balance = holders[target].balance;
        validation = holders[target].valid;
        _status = holders[target].status;
    }

    function blockDeposit(address target, string memory reason) public onlyOnwer {
        holders[target].status = Status.Blocked;
        emit BlockInfo(target, holders[target].balance, block.timestamp, reason);
    }

    function unblockDeposit(address target) public onlyOnwer {
        holders[target].status = Status.Active;
    }
}