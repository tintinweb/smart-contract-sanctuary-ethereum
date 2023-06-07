/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function approveAndCall(address spender, uint tokens, bytes memory data) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) external;
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a, m);
        uint256 d = sub(c, 1);
        return mul(div(d, m), m);
    }
}

contract BOSSCoin is ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;

    string public constant name = "BOSS Coin";
    string public constant symbol = "BOSS";
    uint8 public constant decimals = 18;

    address private owner;
    address payable private taxAddress;
    uint256 public buyTaxRate; // Tax rate for buy transactions
    uint256 public sellTaxRate; // Tax rate for sell transactions
    uint256 private accumulatedETH; // Accumulated ETH from tax transfers

    uint256 private constant MAX_TAX_RATE = 50; // Maximum tax rate cap
    uint256 private _totalSupply;
    uint256 private constant transferFeeThreshold = 0.1 ether; // Threshold for triggering the transfer of accumulated ETH

    event BuyTaxRateChanged(uint256 newRate);
    event SellTaxRateChanged(uint256 newRate);
    mapping(address => bool) private botBlacklist;

    event BotBlacklisted(address botAddress);
    event BotWhitelisted(address botAddress);

    // Modifier to check if an address is blacklisted
    modifier notBlacklisted(address _address) {
        require(!botBlacklist[_address], "Address is blacklisted");
        _;
    }

    // Function to add an address to the blacklist
    function blacklistAddress(address _address) external onlyOwner {
        botBlacklist[_address] = true;
        emit BotBlacklisted(_address);
    }

    // Function to remove an address from the blacklist
    function whitelistAddress(address _address) external onlyOwner {
        botBlacklist[_address] = false;
        emit BotWhitelisted(_address);
    }
    
    
    bool public isTradingOpen = false;

    modifier tradingOpen() {
        require(isTradingOpen, "Trading is not open yet");
        _;
    }

    // Event for when trading is opened
    event TradingOpened();

    // Function to open trading
    function openTrading() external onlyOwner {
        isTradingOpen = true;
        emit TradingOpened();
    }


    constructor() {
        owner = payable(msg.sender);
        taxAddress = payable(0x547f11ECf7f732359a09390e1075108B0fdC409A); // Set the owner's address as the tax address
        buyTaxRate = 5; // Set the initial buy tax rate to 5%
        sellTaxRate = 10; // Set the initial sell tax rate to 10%
        _totalSupply = 1000000000000 * (10 ** 18); // 1 trillion supply
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address player) public view override returns (uint256) {
        return balances[player];
    }

    function allowance(address player, address spender) public view override returns (uint256) {
        return allowed[player][spender];
    }

    function transfer(address to, uint256 value) public override notBlacklisted(msg.sender) notBlacklisted(to) returns (bool) {
        require(value <= balances[msg.sender]);
        require(to != address(0));

        // Check if the sender and recipient are not blacklisted
        require(!botBlacklist[msg.sender], "Sender is blacklisted");
        require(!botBlacklist[to], "Recipient is blacklisted");

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override notBlacklisted(msg.sender) notBlacklisted(from) notBlacklisted(to) returns (bool) {
    require(value <= balances[from]);
    require(value <= allowed[from][msg.sender]);
    require(to != address(0));

    // Check if the sender, spender, and recipient are not blacklisted
    require(!botBlacklist[from], "Sender is blacklisted");
    require(!botBlacklist[msg.sender], "Spender is blacklisted");
    require(!botBlacklist[to], "Recipient is blacklisted");

    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(value);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, value);
    return true;
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function approveAndCall(address spender, uint256 tokens, bytes memory data) external override returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = allowed[msg.sender][spender] + addedValue;
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = allowed[msg.sender][spender] - subtractedValue;
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function calculateTaxAmount(uint256 value, uint256 taxPercent) private pure returns (uint256) {
        uint256 taxAmount = value.mul(taxPercent);
        taxAmount = taxAmount / 100;
        return taxAmount;
    }
    
    // Modified buyTokens function
    function buyTokens() external payable tradingOpen {
        require(msg.value > 0, "Invalid amount");
        uint256 tokensToBuy = msg.value;
        uint256 taxAmount = calculateTaxAmount(tokensToBuy, buyTaxRate);
        uint256 transferAmount = tokensToBuy.sub(taxAmount);

        // Transfer tokens to the buyer
        balances[msg.sender] = balances[msg.sender].add(transferAmount);
        emit Transfer(address(0), msg.sender, transferAmount);

        // Add tax amount to the contract's balance
        accumulatedETH = accumulatedETH.add(taxAmount);

        // Check if accumulatedETH reaches the threshold, and trigger transfer if necessary
        if (accumulatedETH >= transferFeeThreshold) {
            transferAccumulatedETH();
        }
    }

    // Modified sellTokens function
    function sellTokens(uint256 amount) external tradingOpen {
        require(amount > 0, "Invalid amount");
        require(amount <= balances[msg.sender], "Insufficient balance");
        uint256 taxAmount = calculateTaxAmount(amount, sellTaxRate);
        uint256 transferAmount = amount.sub(taxAmount);

        // Transfer tokens from the seller to the contract
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[address(this)] = balances[address(this)].add(amount);
        emit Transfer(msg.sender, address(this), amount);

        // Transfer tokens from the contract to the buyer (excluding tax)
        balances[msg.sender] = balances[msg.sender].add(transferAmount);
        emit Transfer(address(this), msg.sender, transferAmount);

        // Add tax amount to the contract's balance
        accumulatedETH = accumulatedETH.add(taxAmount);

        // Check if accumulatedETH reaches the threshold, and trigger transfer if necessary
        if (accumulatedETH >= transferFeeThreshold) {
            transferAccumulatedETH();
        }
    }

    function burn(uint256 amount) external {
        require(amount > 0, "Invalid amount");
        require(amount <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(msg.sender, address(0), amount);
        emit Burn(msg.sender, amount);
    }

    function getBuyTaxRate() public view returns (uint256) {
        return buyTaxRate;
    }

    function getSellTaxRate() public view returns (uint256) {
        return sellTaxRate;
    }

    function setBuyTaxRate(uint256 newRate) external onlyOwner {
        require(newRate <= MAX_TAX_RATE, "Invalid tax rate");
        buyTaxRate = newRate;
        emit BuyTaxRateChanged(newRate);
    }

    function setSellTaxRate(uint256 newRate) external onlyOwner {
        require(newRate <= MAX_TAX_RATE, "Invalid tax rate");
        sellTaxRate = newRate;
        emit SellTaxRateChanged(newRate);
    }

    function transferAccumulatedETH() private {
        require(accumulatedETH >= transferFeeThreshold, "No accumulated ETH or not reached the threshold");
        uint256 amount = accumulatedETH;
        accumulatedETH = 0;
        (bool success, ) = taxAddress.call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    function withdrawAccumulatedETH() external onlyOwner {
        transferAccumulatedETH();
    }

    receive() external payable {
        // Add directly transferred ETH to accumulatedETH
        accumulatedETH = accumulatedETH.add(msg.value);
        
        // Check if accumulatedETH reaches the threshold, and trigger transfer if necessary
        if (accumulatedETH >= transferFeeThreshold) {
            transferAccumulatedETH();
        }
    }
}