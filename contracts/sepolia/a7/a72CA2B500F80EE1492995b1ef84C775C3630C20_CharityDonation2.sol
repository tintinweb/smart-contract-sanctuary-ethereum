/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract CharityDonation2 {

    // 合約擁有者
    address payable public immutable owner;
    // 合約截止日期
    uint256 public immutable fundraisingDeadline;
    // 合約建立日期
    uint256 public immutable creationTime;
    // 捐款目標
    uint256 public immutable donationGoal;
    // 總捐款數
    uint256 public totalBalance;


    // 事件紀錄，以便日後調用
    event Create(address indexed owner);
    event Withdraw(address indexed from, address indexed to, uint256 value);
    event DonationReceive(address donor, uint amount);

    // 記錄捐款者的捐款金額
    mapping(address => uint256) public donateAmount;
    mapping(address => uint256) private _balance;

    // 確認是否為擁有者
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner.");
        _;
    }
    // 截止時間前
    modifier beforeDeadline() {
        require(block.timestamp <= fundraisingDeadline, "Donation period has ended.");
        _;
    }
    // 目標金額達標 or 合約到期
    modifier reachGoalorAfterDeadline() {
        require(totalBalance >= donationGoal || block.timestamp >= fundraisingDeadline, "Not reach the goal yet or donation period has not ended yet.");
        _;
    }
    // 目標金額是否未達標
    modifier notReachGoal() {
        require(totalBalance + msg.value <= donationGoal, "Reach the goal.");
        _;
    }


    constructor(uint256 Goal, uint256 Second) {
        // 設定捐款目標單位為Ether
        donationGoal = Goal*(10**18);
        // 建立合約時間
        creationTime = block.timestamp;
        // 合約擁有者為建立合約者
        owner = payable(msg.sender);
        // 設定截止日期（2592000 sec = 1 month）
        fundraisingDeadline = creationTime + Second;
        
        // 建立合約者是誰事件紀錄
        emit Create(owner);
    }

    // 捐款的函式
    function donate() public payable beforeDeadline notReachGoal {
        // 確認捐款者錢包目前的金額有大於 0
        require(msg.value > 0, "Donation amount must be greater than zero.");
        // 捐款者原有捐款金額+現在捐款的金額
        donateAmount[msg.sender] += msg.value;
        // 總捐款數+捐款數
        totalBalance += msg.value;
        _balance[owner] += msg.value;

        // 捐款事件紀錄
        emit DonationReceive(msg.sender, msg.value);
    }

    // 查詢目前總金額
    function currentAmount() public view returns (uint256) {
        return address(this).balance;
    }
    
    // 合約擁有者進行捐款的使用
    function withdraw(address to, uint256 amount) external onlyOwner reachGoalorAfterDeadline returns (bool) {
        require(_balance[msg.sender] >= amount, "No tokens to withdraw.");
        // 錢包位址不可為0
        require(to != address(0), "Address can't be 0x0.");
        
        // 捐款的使用事件紀錄
        emit Withdraw(msg.sender, to, amount);

        _balance[msg.sender] -= amount;
        payable(to).transfer(amount);

        
        return true;
    }

}