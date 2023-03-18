/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity = 0.8.19;

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transfer(address dst, uint wad) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256);
}

// V0.3.x
contract BBTT_contract {
    mapping (address => bool) public isOwner;
    mapping (address => bool) public isBlacklisted;
    mapping (address => uint) public senderEthDeposits;
    mapping (address => uint) public senderUsdcDeposits;
    mapping (address => uint) public senderUsdtDeposits;

    uint public minEthAmount = 0.005 ether;
    uint public minDollarAmount = 1000 * 1e6;

    uint256 public lastDepositTime;
    uint public depositRateLimit = 60;          //seconds
    
    address public usdcToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public usdtToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    constructor() {
        isOwner[msg.sender] = true;
    }

    modifier onlyOwner {
        require(isOwner[msg.sender], "Only owner can call this function");
        _;
    }

    modifier notBlacklisted {
        require(!isBlacklisted[msg.sender], "Sender is blacklisted"); _;
    }

    event NewDeposit(
        uint256 timestamp,
        address indexed depositor,
        uint256 txValue,
        uint userInputAmount,
        string encryptedAddress,
        address dst,
        uint senderEthDeposits,
        uint senderUsdcDeposits,
        uint senderUsdtDeposits
    );

    function addToBlacklist(address _addr) public onlyOwner {
        isBlacklisted[_addr] = true;
    }

    function removeFromBlacklist(address _addr) public onlyOwner {
        isBlacklisted[_addr] = false;
    }

    //Value in wei (Example 1ETH = 10^18)
    function modifyMinEthAmount(uint amount) public onlyOwner{
        minEthAmount = amount;
    }
        
    function modifyRateLimit(uint rate) public onlyOwner{
        depositRateLimit = rate;
    }

    //Value in wei Example (1000 USDC = 10^21)
    function modifyMinDollarAmount(uint amount) public onlyOwner{
        minDollarAmount = amount;
    }

    function getMinEthAmount() public view returns (uint) {
        return minEthAmount;
    }

    function getDepositRateLimit() public view returns (uint) {
        return depositRateLimit;
    }

    function getMinDollarAmount() public view returns (uint) {
        return minDollarAmount;
    }

    function depositETH(string memory encryptedAddress, uint amount, address dst) payable public notBlacklisted{        
        require(msg.value >= minEthAmount, "ETH value must be greater than or equal to 0.5 ETH");
        require(msg.value >= amount, "ETH value must be greater than or equal to input amount");
        require(block.timestamp - lastDepositTime >= depositRateLimit, "Deposit rate limit exceeded");

        senderEthDeposits[msg.sender] += amount;
        emit NewDeposit(block.timestamp, msg.sender, msg.value, amount, encryptedAddress, dst, senderEthDeposits[msg.sender],senderUsdcDeposits[msg.sender],senderUsdtDeposits[msg.sender]);
        lastDepositTime = block.timestamp;
    }
    
    function depositUSDC(string memory encryptedAddress, uint amount, address dst) public notBlacklisted{
        IERC20 USDC = IERC20(usdcToken);
        require(amount >= minDollarAmount, "Amount must be greater than minimum limit");
        require(USDC.balanceOf(msg.sender) > amount, "Insufficient USDC balance");
        require(USDC.allowance(msg.sender, address(this)) >= amount, "You must approve the contract to spend USDC before depositing");
        require(USDC.transferFrom(msg.sender, address(this), amount), "USDC transfer failed");
        require(block.timestamp - lastDepositTime >= depositRateLimit, "Deposit rate limit exceeded");
        
        senderUsdcDeposits[msg.sender] += amount;
        emit NewDeposit(block.timestamp, msg.sender, 0, amount, encryptedAddress, dst, senderEthDeposits[msg.sender],senderUsdcDeposits[msg.sender],senderUsdtDeposits[msg.sender]);
        lastDepositTime = block.timestamp;
    }

    function depositUSDT(string memory encryptedAddress, uint amount, address dst) public notBlacklisted{
        IERC20 USDT = IERC20(usdtToken);
        require(amount >= minDollarAmount, "Amount must be greater than minimum limit");
        require(USDT.balanceOf(msg.sender) > amount, "Insufficient USDT balance");
        require(USDT.allowance(msg.sender, address(this)) >= amount, "You must approve the contract to spend USDC before depositing");
        require(USDT.transferFrom(msg.sender, address(this), amount), "USDT transfer failed");
        require(block.timestamp - lastDepositTime >= depositRateLimit, "Deposit rate limit exceeded");

        senderUsdtDeposits[msg.sender] += amount;
        emit NewDeposit(block.timestamp, msg.sender, 0, amount, encryptedAddress, dst, senderEthDeposits[msg.sender],senderUsdcDeposits[msg.sender],senderUsdtDeposits[msg.sender]);
        lastDepositTime = block.timestamp;
    }
    
    function withdrawETH(address dst) public onlyOwner{
        require(dst != address(0), "Zero address is not allowed");
        uint contractBalance = address(this).balance;
        payable(dst).transfer(contractBalance);
    }

    function withdrawTokens(address token) public onlyOwner{
        require(token != address(0), "Zero address is not allowed");
        IERC20 TOKEN = IERC20(token);
        uint contractBalance = TOKEN.balanceOf(address(this));
        TOKEN.transfer(msg.sender, contractBalance);
    }

    function setOwner(address _owner, bool _isOwner) public onlyOwner {
        require(_owner != address(0), "Zero address is not allowed");
        require(_owner != msg.sender, "Cannot change ownership of self");
        require(isOwner[_owner] != _isOwner, "Owner status already set to specified value");
        isOwner[_owner] = _isOwner;
    }

    receive() external payable {}
    fallback() external payable {}
}