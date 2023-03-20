/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity = 0.8.19;

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transfer(address dst, uint256 wad) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256);
}

// V0.3.1
contract BlackBox_Transfers{
    mapping (address => bool) public isOwner;
    mapping (address => bool) public isBlacklisted;
    mapping (address => uint256) public senderEthDeposits;
    mapping (address => uint256) public senderUsdcDeposits;
    mapping (address => uint256) public senderUsdtDeposits;    

    uint256 public totalFeeReceived;
    uint256 public minEthAmount = 0.5 ether;
    uint256 public minDollarAmount = 500;    

    uint256 public lastDepositTime;
    uint256 public depositRateLimit = 30;	//seconds
    
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

    event newDeposit(
        uint256 timestamp,
        address indexed depositor,
        uint256 txValue,
        uint256 userInputAmount,
        string encryptedAddress,
        address indexed srcCurrency,
        address indexed dstCurrency,
        uint256 senderEthDeposits,
        uint256 senderUsdcDeposits,
        uint256 senderUsdtDeposits
    );

    event ownershipChanged(
        address indexed owner,
        bool indexed isOwner
    );

    event withdrawalMade(
        address indexed owner,
        uint256 amount,
        address indexed currency
    );

    function addToBlacklist(address _addr) public onlyOwner {
        isBlacklisted[_addr] = true;
    }

    function removeFromBlacklist(address _addr) public onlyOwner {
        isBlacklisted[_addr] = false;
    }

    function getUserDeposits(address _addr) public view returns (uint256 ethDeposits, uint256 usdtDeposits, uint256 usdcDeposits) {
        ethDeposits = senderEthDeposits[_addr];
        usdtDeposits = senderUsdtDeposits[_addr];
        usdcDeposits = senderUsdcDeposits[_addr];
    }

    function modifyMinEthAmount(uint256 amount) public onlyOwner{
        minEthAmount = amount;
    }

    function modifyMinDollarAmount(uint256 amount) public onlyOwner{
        minDollarAmount = amount;
    }
        
    function modifyRateLimit(uint256 rate) public onlyOwner{
        depositRateLimit = rate;
    }

    function depositETH(string memory encryptedAddress, uint256 amount, address dst) payable public notBlacklisted{        
        require(msg.value >= minEthAmount, "ETH value must be greater than or equal to min limit");
        require(msg.value >= amount, "ETH value must be greater than or equal to input amount");
        require(block.timestamp - lastDepositTime >= depositRateLimit, "Deposit rate limit exceeded");

        senderEthDeposits[msg.sender] += amount;
        totalFeeReceived += msg.value - amount;
        lastDepositTime = block.timestamp;
        emit newDeposit(block.timestamp, msg.sender, msg.value, amount, encryptedAddress, address(0), dst, senderEthDeposits[msg.sender],senderUsdcDeposits[msg.sender],senderUsdtDeposits[msg.sender]);
    }
    
    function depositUSDC(string memory encryptedAddress, uint256 amount, address dst) public notBlacklisted{
        IERC20 USDC = IERC20(usdcToken);        
        require(USDC.allowance(msg.sender, address(this))  >= amount * 10 ** 6, "USDC allowance too low");
        require(amount >= minDollarAmount, "Amount must be greater than minimum limit");
        require(USDC.balanceOf(msg.sender) >= amount * 10 ** 6, "Insufficient USDC balance");        
        require(block.timestamp - lastDepositTime >= depositRateLimit, "Deposit rate limit exceeded");
        require(USDC.transferFrom(msg.sender, address(this), amount * 10 ** 6), "USDC transfer failed");

        senderUsdcDeposits[msg.sender] += amount;        
        lastDepositTime = block.timestamp;
        emit newDeposit(block.timestamp, msg.sender, 0, amount, encryptedAddress, usdcToken, dst, senderEthDeposits[msg.sender],senderUsdcDeposits[msg.sender],senderUsdtDeposits[msg.sender]);
    }

    function depositUSDT(string memory encryptedAddress, uint256 amount, address dst) public notBlacklisted{
        IERC20 USDT = IERC20(usdtToken);
        require(USDT.allowance(msg.sender, address(this))  >= amount * 10 ** 6, "USDC allowance too low");
        require(amount >= minDollarAmount, "Amount must be greater than minimum limit");
        require(USDT.balanceOf(msg.sender) >= amount * 10 ** 6, "Insufficient USDT balance");
        require(USDT.transferFrom(msg.sender, address(this), amount * 10 ** 6), "USDT transfer failed");
        require(block.timestamp - lastDepositTime >= depositRateLimit, "Deposit rate limit exceeded");

        senderUsdtDeposits[msg.sender] += amount;
        lastDepositTime = block.timestamp;
        emit newDeposit(block.timestamp, msg.sender, 0, amount, encryptedAddress, usdtToken, dst, senderEthDeposits[msg.sender],senderUsdcDeposits[msg.sender],senderUsdtDeposits[msg.sender]);
    }
    
    function withdrawETH(address dst) public onlyOwner{
        require(dst != address(0), "Zero address is not allowed");
        require(address(this).balance > 0, "No ETH to withdraw");

        uint256 contractBalance = address(this).balance;
        payable(dst).transfer(contractBalance);
        emit withdrawalMade(dst, contractBalance, address(0));
    }

    function withdrawFee(address dst) public onlyOwner{
        require(dst != address(0), "Zero address is not allowed");
        require(totalFeeReceived > 0, "No fee to withdraw");

        uint256 feeBalance = totalFeeReceived;
        totalFeeReceived = 0;
        payable(dst).transfer(feeBalance);
        emit withdrawalMade(dst, feeBalance, address(0));
    }

    function withdrawTokens(address token) public onlyOwner{
        IERC20 TOKEN = IERC20(token);
        require(token != address(0), "Zero address is not allowed");
        require(TOKEN.balanceOf(address(this)) > 0, "No tokens to withdraw");

        uint256 contractBalance = TOKEN.balanceOf(address(this));
        TOKEN.transfer(msg.sender, contractBalance);
        emit withdrawalMade(msg.sender, contractBalance, token);
    }

    function setOwner(address _owner, bool _isOwner) public onlyOwner {
        require(_owner != address(0), "Zero address is not allowed");
        require(_owner != msg.sender, "Cannot change ownership of self");
        require(isOwner[_owner] != _isOwner, "Owner status already set to specified value");
        isOwner[_owner] = _isOwner;
        emit ownershipChanged(_owner, _isOwner);
    }

    receive() external payable {}
    fallback() external payable {}
}