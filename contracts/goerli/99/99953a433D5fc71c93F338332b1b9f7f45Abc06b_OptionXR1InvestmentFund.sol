/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

// SPDX-License-Identifier: MIT
// OptionX Round 1 Investment fund. Expect 100K value of token will be transferred. 
// V1. First code. fix the bug in the withdraw.

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);}

contract OptionXR1InvestmentFund {
    address public owner;
    IERC20 public token;
    uint256 public fundBalance;
    
    enum RequestStatus {Pending, Approved, Rejected}
    
    struct Request {
        address requestor;
        uint256 amount;
        string usage;
        RequestStatus status;
    }
    
    Request[] public requests;
    
    mapping(address => uint256) public requestIndex;
    
    event FundTransfer(address indexed recipient, uint256 amount);
    event RequestStatusUpdate(uint256 indexed requestId, RequestStatus status);
    
    constructor() {
        owner = msg.sender;
        token = IERC20(0xAB4147786d757aA235b4E8b18cdaed9B2CeaF624);
    }
    
    function deposit(uint256 amount) external {
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        fundBalance += amount;
    }
    
    function request(uint256 amount, string memory usage) external {
        require(amount <= fundBalance, "Insufficient fund");
        Request memory req = Request(msg.sender, amount, usage, RequestStatus.Pending);
        requests.push(req);
        requestIndex[msg.sender] = requests.length - 1;
    }
    
    function approveRequest(uint256 requestId) external {
        require(msg.sender == owner, "Only owner can approve request");
        Request storage req = requests[requestId];
        require(req.status == RequestStatus.Pending, "Request already processed");
        require(req.amount <= fundBalance, "Insufficient fund");
        require(token.transfer(req.requestor, req.amount), "Token transfer failed");
        fundBalance -= req.amount;
        req.status = RequestStatus.Approved;
        emit FundTransfer(req.requestor, req.amount);
        emit RequestStatusUpdate(requestId, RequestStatus.Approved);
    }


    function rejectRequest(uint256 requestId) external {
        require(msg.sender == owner, "Only owner can reject request");
        Request storage req = requests[requestId];
        require(req.status == RequestStatus.Pending, "Request already processed");
        req.status = RequestStatus.Rejected;
        emit RequestStatusUpdate(requestId, RequestStatus.Rejected);
    }

    
    function getRequestStatus(uint256 index) external view returns (RequestStatus) {
        require(index < requests.length, "Invalid request index");
        return requests[index].status;
    }

    
    function balance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    function withdraw(uint256 amount) external {
        require(msg.sender == owner, "Only owner can withdraw");
        require(amount < token.balanceOf(address(this)),"Insufficient balance");
        require(token.transfer(owner, amount), "Token transfer failed");
        fundBalance -= amount;
        emit FundTransfer(owner, amount);
    }
}