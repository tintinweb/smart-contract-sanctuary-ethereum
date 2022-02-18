// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract ETHPool {
    struct Pool {
        uint256 totalDeposits;
        uint256 totalRewards;
        mapping(address => uint256) deposits;
    }
    
    uint256 public totalHoldings;
    uint256 public currentPool;
    address public owner;
    address public teamAddress;

    mapping(address => uint256) private nextWithdrawalPoolStart;
    mapping(uint256 => Pool) private pools;
    mapping(address => uint256[]) userPools;

    event EthDeposit(address indexed depositor, uint256 amount, uint256 timestamp);
    event Withdrawal(address indexed withdrawer, uint256 amount, uint256 timestamp);
    event RewardDeposit(uint256 amount, uint256 timestamp);
    
    constructor()
    payable
    {
        owner = msg.sender;
    }
    
    function setTeamAddress(address addr)
    public
    {
        require(msg.sender == owner, "ACCESS_DENIED");
        teamAddress = addr;
    }
    
    function deposit()
    public payable
    {
        require(msg.value > 0, "INVALID_DEPOSIT_AMOUNT");
        Pool storage pool = pools[currentPool];
        pool.totalDeposits += msg.value;
        pool.deposits[msg.sender] += msg.value;
        
        uint256[] storage senderPools = userPools[msg.sender];
        if (senderPools.length == 0 || senderPools[senderPools.length - 1] != currentPool) {
            senderPools.push(currentPool);
        }
        
        totalHoldings += msg.value;
        emit EthDeposit(msg.sender, msg.value, block.timestamp);
    }
    
    function depositReward()
    public payable
    {
        require(msg.sender == teamAddress, "ACCESS_DENIED");
        require(msg.value > 0, "INVALID_DEPOSIT_AMOUNT");
        
        uint256 poolNumber = currentPool;
        if (poolNumber > 0 && pools[poolNumber].totalDeposits == 0) {
            poolNumber--;
        }
        
        pools[poolNumber].totalRewards += msg.value;
        totalHoldings += msg.value;
        currentPool = poolNumber + 1;
        emit RewardDeposit(msg.value, block.timestamp);
    }
    
    function withdraw()
    public payable
    {
        uint256 i;
        uint256 withdrawalAmount;
        uint256[] storage senderPools = userPools[msg.sender];
        for (i = 0; i < senderPools.length; i++) {
            if (i < nextWithdrawalPoolStart[msg.sender]) {
                continue;
            }
            Pool storage pool = pools[senderPools[i]];
            withdrawalAmount += pool.deposits[msg.sender] * pool.totalRewards / pool.totalDeposits;
            withdrawalAmount += pool.deposits[msg.sender];
        }

        if (senderPools.length > 0) {
            nextWithdrawalPoolStart[msg.sender] = senderPools[senderPools.length - 1] + 1;
        }
        totalHoldings -= withdrawalAmount;
        emit Withdrawal(msg.sender, withdrawalAmount, block.timestamp);
        
        assert(address(this).balance >= withdrawalAmount);
        (bool sent,) = msg.sender.call{value : withdrawalAmount}("");
        require(sent, "WITHDRAWAL_CALL_FAILED");
    }
}