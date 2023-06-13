/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public lockedWallets;
    mapping(address => uint256) public stakedBalance;
    
    uint256 public transactionFee;
    uint256 public maxTransactionSize;
    
    uint256 public lotteryTicketPrice;
    mapping(address => uint256) public lotteryTickets;
    address[] public lotteryParticipants;
    bool public isLotteryActive;
    address public lotteryWinner;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event TransactionFeeUpdated(uint256 newFee);
    event MaxTransactionSizeUpdated(uint256 newSize);
    event LotteryTicketPurchased(address indexed participant, uint256 ticketCount);
    event LotteryWinnerSelected(address indexed winner);
    event WalletLocked(address indexed wallet);
    event WalletUnlocked(address indexed wallet);
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * 10 ** uint256(_decimals);
        balanceOf[msg.sender] = totalSupply;
        
        isLotteryActive = false;
    }
    
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Address not whitelisted");
        _;
    }
    
    modifier onlyUnlocked(address _wallet) {
        require(!lockedWallets[_wallet], "Wallet is locked");
        _;
    }
    
    function transfer(address _to, uint256 _value) external onlyUnlocked(msg.sender) returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(_value <= maxTransactionSize, "Transaction size exceeds the limit");
        
        uint256 fee = (_value * transactionFee) / 100;
        uint256 transferAmount = _value - fee;
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += transferAmount;
        balanceOf[address(this)] += fee;
        
        emit Transfer(msg.sender, _to, transferAmount);
        emit Transfer(msg.sender, address(this), fee);
        
        return true;
    }
    
    function updateTransactionFee(uint256 _newFee) external onlyWhitelisted {
        transactionFee = _newFee;
        emit TransactionFeeUpdated(_newFee);
    }
    
    function updateMaxTransactionSize(uint256 _newSize) external onlyWhitelisted {
        maxTransactionSize = _newSize;
        emit MaxTransactionSizeUpdated(_newSize);
    }
    
    function addToWhitelist(address[] memory _addresses) external onlyWhitelisted {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }
    
    function lockWallet(address _wallet) external onlyWhitelisted {
        lockedWallets[_wallet] = true;
        emit WalletLocked(_wallet);
    }
    
    function unlockWallet(address _wallet) external onlyWhitelisted {
        lockedWallets[_wallet] = false;
        emit WalletUnlocked(_wallet);
    }
    
    function distributeToken(address[] memory _addresses, uint256[] memory _amounts) external onlyWhitelisted {
        require(_addresses.length == _amounts.length, "Invalid input length");
        
        for (uint256 i = 0; i < _addresses.length; i++) {
            address recipient = _addresses[i];
            uint256 amount = _amounts[i] * 10 ** uint256(decimals);
            
            balanceOf[address(this)] -= amount;
            balanceOf[recipient] += amount;
            
            emit Transfer(address(this), recipient, amount);
        }
    }
    
    function stakeTokens(uint256 _amount) external {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");
        
        balanceOf[msg.sender] -= _amount;
        stakedBalance[msg.sender] += _amount;
    }
    
    function unstakeTokens(uint256 _amount) external {
        require(stakedBalance[msg.sender] >= _amount, "Insufficient staked balance");
        
        balanceOf[msg.sender] += _amount;
        stakedBalance[msg.sender] -= _amount;
    }
    
    function startLottery(uint256 _ticketPrice) external onlyWhitelisted {
        require(!isLotteryActive, "Lottery is already active");
        
        lotteryTicketPrice = _ticketPrice;
        isLotteryActive = true;
    }
    
    function purchaseLotteryTickets(uint256 _ticketCount) external payable {
        require(isLotteryActive, "Lottery is not active");
        require(msg.value == _ticketCount * lotteryTicketPrice, "Incorrect payment amount");
        
        lotteryTickets[msg.sender] += _ticketCount;
        
        for (uint256 i = 0; i < _ticketCount; i++) {
            lotteryParticipants.push(msg.sender);
        }
        
        emit LotteryTicketPurchased(msg.sender, _ticketCount);
    }
    
    function selectLotteryWinner() external onlyWhitelisted {
        require(isLotteryActive, "Lottery is not active");
        require(lotteryParticipants.length > 0, "No participants in the lottery");
        
        uint256 winnerIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % lotteryParticipants.length;
        lotteryWinner = lotteryParticipants[winnerIndex];
        
        // Transfer the entire balance of the contract to the lottery winner
        uint256 lotteryPrize = address(this).balance;
        payable(lotteryWinner).transfer(lotteryPrize);
        
        isLotteryActive = false;
        delete lotteryParticipants;
        
        emit LotteryWinnerSelected(lotteryWinner);
    }
    
    function withdrawLotteryFunds() external onlyWhitelisted {
        require(!isLotteryActive, "Lottery is still active");
        
        // Transfer any remaining balance of the contract to the contract owner
        uint256 contractBalance = address(this).balance;
        payable(msg.sender).transfer(contractBalance);
    }
}