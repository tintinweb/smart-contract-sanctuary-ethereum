/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract DeBank {

    struct SavingsDeposit {
        uint balance;
        uint rate;
        uint time;
    }

    struct Loan {
        uint balance;
        uint rate;
        uint time;
        uint endTime;
    }

    address public manager;
    mapping(address => uint) private balances;
    uint public shortTermRate;
    uint public longTermRate;
    uint public loanRate;
    uint public defaultLoan;
    uint public totalDeposits;
    uint public totalLoans;
    mapping(address => uint) private possibleLoan;
    mapping(address => SavingsDeposit) private shortTermDeposit;
    mapping(address => SavingsDeposit) private longTermDeposit;
    mapping(address => Loan) private loans;

    constructor() {
        manager = msg.sender;
        shortTermRate = 10000; //"1.00% annualy"
        longTermRate = 20000; //"2.00% annualy"
        loanRate = 30000; //"3.00% annualy"
        defaultLoan = 0;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "You are not allowed to use this function");
        _;
    }

    function changeManager(address _newManager) public onlyManager {
        manager = _newManager;
    }

    function deposit() payable public {
        require(msg.value > 0, "No ether was sent");
        balances[msg.sender] = balances[msg.sender] + msg.value;
    }

    function withdraw(uint _amount) public {
        require(balances[msg.sender] >= _amount, "The amount requested is more than your balance");
        require(address(this).balance >= _amount, "The request is not possible at the moment");
        payable(msg.sender).transfer(_amount);
        balances[msg.sender] = balances[msg.sender] - _amount;
    }

    function transferTo(address _to, uint _amount) public {
        require(balances[msg.sender] >= _amount, "Please first deposit enough funds");
        balances[msg.sender] = balances[msg.sender] - _amount;
        balances[_to] = balances[_to] + _amount;
    }

    function shortTerm(uint _amount) public {
        require(balances[msg.sender] >= _amount, "Please first deposit enough funds");
        require(shortTermDeposit[msg.sender].balance == 0, "You can only have one short term deposit at a time");
        balances[msg.sender] = balances[msg.sender] - _amount;
        shortTermDeposit[msg.sender].balance = _amount;
        shortTermDeposit[msg.sender].rate = shortTermRate;
        shortTermDeposit[msg.sender].time = block.timestamp;
        totalDeposits = totalDeposits + _amount;
    }

    function longTerm(uint _amount) public {
        require(balances[msg.sender] >= _amount, "Please first deposit enough funds");
        require(longTermDeposit[msg.sender].balance == 0, "You can only have one long term deposit at a time");
        balances[msg.sender] = balances[msg.sender] - _amount;
        longTermDeposit[msg.sender].balance = _amount;
        longTermDeposit[msg.sender].rate = longTermRate;
        longTermDeposit[msg.sender].time = block.timestamp;
        totalDeposits = totalDeposits + _amount;
    }

    function releaseDeposits() public {
        uint rate;
        uint amount;

        if (longTermDeposit[msg.sender].balance > 0 
            && block.timestamp >= longTermDeposit[msg.sender].time + 365 days) {
            rate = longTermDeposit[msg.sender].rate;
            amount = longTermDeposit[msg.sender].balance * rate *
                (block.timestamp - longTermDeposit[msg.sender].time) / (365 days)
                / 1000000 + longTermDeposit[msg.sender].balance;
            balances[msg.sender] = balances[msg.sender] + amount;
            totalDeposits = totalDeposits - longTermDeposit[msg.sender].balance;
            longTermDeposit[msg.sender].balance = 0;
            longTermDeposit[msg.sender].time = 0;
            longTermDeposit[msg.sender].rate = 0;
        }

        if (shortTermDeposit[msg.sender].balance > 0 
            && block.timestamp >= shortTermDeposit[msg.sender].time + 30 days) {
            rate = shortTermDeposit[msg.sender].rate;
            amount = shortTermDeposit[msg.sender].balance * rate * 
                (block.timestamp - shortTermDeposit[msg.sender].time) / (365 days)
                / 1000000 + shortTermDeposit[msg.sender].balance;
            balances[msg.sender] = balances[msg.sender] + amount;
            totalDeposits = totalDeposits - shortTermDeposit[msg.sender].balance;
            shortTermDeposit[msg.sender].balance = 0;
            shortTermDeposit[msg.sender].time = 0;
            shortTermDeposit[msg.sender].rate = 0;
        }
    }

    function getLoan(uint _amount) public {
        require(loans[msg.sender].balance == 0, "You can get one loan at a time");
        if (possibleLoan[msg.sender] > 0) {
            require(possibleLoan[msg.sender] >= _amount, "Your request was declined, please talk to manager");
        } else {
            require(defaultLoan >= _amount, "Your request was declined, please talk to manager");
        }
        require(_amount + totalLoans <= address(this).balance / 2, "Your request is not possible at the moment");
        loans[msg.sender].balance = _amount;
        loans[msg.sender].rate = loanRate;
        loans[msg.sender].time = block.timestamp;
        loans[msg.sender].endTime = block.timestamp + 365 days;
        balances[msg.sender] = balances[msg.sender] + _amount;
        totalLoans = totalLoans + _amount;
    }

    function payLoan() public {
        require(loans[msg.sender].balance > 0, "You are free of obligations");
        if (block.timestamp <= loans[msg.sender].endTime) {
            uint principalAmount = loans[msg.sender].balance * (block.timestamp - loans[msg.sender].time)
                / (loans[msg.sender].endTime - loans[msg.sender].time);
            uint interestAmount = loans[msg.sender].balance * loans[msg.sender].rate * (block.timestamp - loans[msg.sender].time)
                / (365 days) / 1000000;
            uint totalAmount = principalAmount + interestAmount;
            require(balances[msg.sender] >= totalAmount, "You need to deposit more money to your account");
            balances[msg.sender] = balances[msg.sender] - totalAmount;
            loans[msg.sender].balance = loans[msg.sender].balance - principalAmount;
            loans[msg.sender].time = block.timestamp;
            totalLoans = totalLoans - principalAmount;
        } else {
            uint principalAmount = loans[msg.sender].balance;
            uint interestAmount = loans[msg.sender].balance * loans[msg.sender].rate * (block.timestamp - loans[msg.sender].time)
                / (365 days) / 1000000;
            uint totalAmount = principalAmount + interestAmount;
            require(balances[msg.sender] >= totalAmount, "You need to deposit more money to your account");
            balances[msg.sender] = balances[msg.sender] - totalAmount;
            loans[msg.sender].balance = 0;
            loans[msg.sender].time = 0;
            loans[msg.sender].rate = 0;
            loans[msg.sender].endTime = 0;
            totalLoans = totalLoans - principalAmount;
        }
    }

    function getBalance() public view returns(uint) {
        return balances[msg.sender];
    }

    function dividend(uint _amount) public onlyManager {
        uint availableForDividend = address(this).balance/10;
        require(_amount <= availableForDividend, "The amount requested is not allowed");
        payable(msg.sender).transfer(_amount);
    }

    function setShortTermRate(uint _rate) public onlyManager {
        require(_rate <= 1000000, "Cannot set rate above 100 percent");
        shortTermRate = _rate;
    }

    function setLongTermRate(uint _rate) public onlyManager {
        require(_rate <= 1000000, "Cannot set rate above 100 percent");
        longTermRate = _rate;
    }

    function setLoanRate(uint _rate) public onlyManager {
        require(_rate <= 1000000, "Cannot set rate above 100 percent");
        loanRate = _rate;
    }

    function setDefaultLoan(uint _amount) public onlyManager {
        defaultLoan = _amount;
    }

    function setPossibleLoan(address _account, uint _amount) public onlyManager {
        possibleLoan[_account] = _amount;
    }

    function bankBalance() public view returns(uint) {
        return address(this).balance;
    }

    receive() external payable {
        deposit();
    }

}