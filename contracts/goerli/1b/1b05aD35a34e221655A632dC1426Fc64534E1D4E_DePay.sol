/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DePay {
    struct Request {
        string description;
        uint256 value;
        bool complete;
        address from;
    }

    mapping(address => Request[]) public requests;
    mapping(address => uint256) public balance;
    mapping(address => mapping(address => uint256)) public given;
    mapping(address => mapping(address => uint256)) public used;
    mapping(address => mapping(address => uint256)) public borrowed;
    mapping(address => mapping(address => uint256)) public paidTo;
    mapping(address => mapping(address => uint256)) public ReceivedFrom;
    mapping(address => address[]) public paidArr;
    mapping(address => address[]) public receivedArr;
    mapping(address => address[]) public loanGivenArr;
    mapping(address => address[]) public loanTakenArr;
    mapping(address => uint256) public totalBalanceIHaveAdded;
    event transactionData(
        address indexed _from,
        uint256 amount,
        address indexed _to,
        uint256 date,
        uint256 time,
        string purpose
    );

    function addFund() public payable {
        require(msg.value > 0, "transaction with 0 eth is not allowed");
        balance[msg.sender] += msg.value;
        totalBalanceIHaveAdded[msg.sender] += msg.value;
    }

    function pay(
        address payable _to,
        uint256 amount,
        uint256 date,
        uint256 time,
        string memory purpose
    ) public payable {
        require(amount < balance[msg.sender], "Insufficient funds");
        require(amount > 0, "transaction with 0 eth is not allowed");
        require(_to != msg.sender, "You cannot pay money to yourself");
        _to.transfer(amount);
        balance[_to] += amount;
        balance[msg.sender] -= amount;
        if (paidTo[msg.sender][_to] == 0) {
            paidArr[msg.sender].push(_to);
            receivedArr[_to].push(msg.sender);
        }
        paidTo[msg.sender][_to] += amount;
        ReceivedFrom[_to][msg.sender] += amount;
        emit transactionData(msg.sender, amount, _to, date, time, purpose);
    }

    function withdraw(uint256 amount) public payable {
        require(amount < balance[msg.sender], "Insufficient funds");
        require(amount > 0, "transaction with 0 eth is not allowed");
        (payable(msg.sender)).transfer(amount);
        balance[msg.sender] -= amount;
    }

    function lend(uint256 amount, address payable _to) public payable {
        require(amount <= balance[msg.sender], "Insufficient funds");
        require(amount > 0, "transaction with 0 eth is not allowed");
        require(_to != msg.sender, "You cannot lend money to yourself");
        balance[msg.sender] -= amount;
        given[msg.sender][_to] += amount;
        borrowed[_to][msg.sender] += amount;
        loanGivenArr[msg.sender].push(_to);
        loanTakenArr[_to].push(msg.sender);
    }

    function takeBack(uint256 amount, address payable _to) public payable {
        require(
            given[msg.sender][_to] - used[msg.sender][_to] >= amount,
            "The address doesnt have that much funds"
        );
        balance[msg.sender] += amount;
        given[msg.sender][_to] -= amount;
        borrowed[_to][msg.sender] -= amount;
        (payable(msg.sender)).transfer(amount);
    }

    function createRequest(
        string memory description,
        uint256 value,
        address _to
    ) public {
        require(
            given[_to][msg.sender] - used[msg.sender][_to] > 0,
            "You have used all the money that was lent to you"
        );
        require(
            given[_to][msg.sender] - used[msg.sender][_to] >= value,
            "you are asking for more money than what has been lent to you"
        );
        Request storage newRequest = requests[_to].push();
        newRequest.description = description;
        newRequest.value = value;
        newRequest.complete = false;
        newRequest.from = msg.sender;
    }

    function approveRequest(uint256 index) public payable {
        Request storage request = requests[msg.sender][index];
        require(
            request.complete == false,
            "request has already been finalised"
        );
        if (
            given[msg.sender][request.from] - used[msg.sender][request.from] > 0
        ) {
            (payable(request.from)).transfer((request.value));
            request.complete = true;
            balance[request.from] += request.value;
            used[msg.sender][request.from] += request.value;
        } else {
            rejectRequest(index);
        }
    }

    function rejectRequest(uint256 index) public {
        Request storage request = requests[msg.sender][index];
        require(
            request.complete == false,
            "request has already been finalised"
        );
        request.complete = true;
    }

    function numberOfRequets() external view returns (uint256) {
        return (requests[msg.sender].length);
    }

    function numberOfPeopleIPaid() external view returns (uint256) {
        return (paidArr[msg.sender].length);
    }

    function numberOfPeopleWhoPaidMe() external view returns (uint256) {
        return (receivedArr[msg.sender].length);
    }

    function numberOfPeopleWhomIHaveGivenLoan()
        external
        view
        returns (uint256)
    {
        return (loanGivenArr[msg.sender].length);
    }

    function numberOfPeopleWhoHaveGivenLoanToMe()
        external
        view
        returns (uint256)
    {
        return (loanTakenArr[msg.sender].length);
    }

    function clearedMyDebt(address _to) public {
        used[msg.sender][_to] = 0;
    }
}