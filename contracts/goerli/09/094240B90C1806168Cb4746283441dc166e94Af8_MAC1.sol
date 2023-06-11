/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}




pragma solidity ^0.8.0;


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  
    constructor() {
        _transferOwnership(_msgSender());
    }

  
    function owner() public view virtual returns (address) {
        return _owner;
    }

   
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

  
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

  
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



pragma solidity ^0.8.0;


interface IERC20 {
   
    function totalSupply() external view returns (uint256);

   
    function balanceOf(address account) external view returns (uint256);

  
    function transfer(address recipient, uint256 amount) external returns (bool);

  
    function allowance(address owner, address spender) external view returns (uint256);

  
    function approve(address spender, uint256 amount) external returns (bool);

  
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

  
    event Transfer(address indexed from, address indexed to, uint256 value);

  
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



pragma solidity ^0.8.0;


interface IERC20Metadata is IERC20 {
 
    function name() external view returns (string memory);

 
    function symbol() external view returns (string memory);

 
    function decimals() external view returns (uint8);
}




pragma solidity ^0.8.0;




contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

  
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

  
    function name() public view virtual override returns (string memory) {
        return _name;
    }

  
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

  
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

  
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

  
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

 
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

  
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

 
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

  
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

 
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

   
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

  
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

 
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

  
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


pragma solidity ^0.8.0;


contract MAC1 is Ownable, ERC20 {
    address public uniswapV2Pair;
    uint256 public maxBuyAmount; // Metal Gear Solid Mode
    uint256 public maxSellAmount; // Tekken Mode
    uint256 public globalBuyCount;
    uint256 public minBuysBetweenSales = 5; // Protect against MVE BOTS
    uint256 public maxTimeWithoutTax = 200; // Time in seconds which users won't be taxed if they sell after
    uint256 public GTA_Mode; // anti-MVE BOTS TAX (GTA Mode)
    bool public isGTA_ModeActive;
    bool public isCTR_ModeActive = true;
    uint256 private minTimeBetweenTx = 10; // 10 seconds between transactions
    address public taxReceiver;
    mapping (address => uint256) private lastOperationTime;
    mapping (address => bool) public blacklists;
    mapping (address => uint256) private lastGlobalBuyCount;
    mapping (address => bool) public isBot;

    event RuleSet(
        address indexed uniswapV2Pair,
        uint256 maxBuyAmount,
        uint256 maxSellAmount,
        bool isGTA_ModeActive,
        uint256 GTA_Mode
    );

    event GTAModeSwitched(bool isActive);
    event CTRModeSwitched(bool isActive);
    event TaxReceiverUpdated(address newTaxReceiver);
    event MinTimeBetweenTxUpdated(uint256 newMinTimeBetweenTx);
    event BotStatusUpdated(address indexed user, bool status);

    constructor(address _taxReceiver) ERC20("MAC 1", "MAC") {
        require(_taxReceiver != address(0), "Tax receiver address cannot be 0");
        _mint(msg.sender, 102000000 * (10 ** uint256(decimals())));
        taxReceiver = _taxReceiver;
        maxBuyAmount = 102000000 * (10 ** uint256(decimals())); // Same as total supply
        maxSellAmount = 102000000 * (10 ** uint256(decimals())); // Same as total supply
    }

    function setMinTimeBetweenTx(uint256 _newMinTimeBetweenTx) external onlyOwner {
        minTimeBetweenTx = _newMinTimeBetweenTx;
        emit MinTimeBetweenTxUpdated(_newMinTimeBetweenTx);
    }

    function setUniswapV2Pair(address _uniswapV2Pair) external onlyOwner {
        require(_uniswapV2Pair != address(0), "Invalid Uniswap V2 pair address");
        uniswapV2Pair = _uniswapV2Pair;
    }

    function setTaxReceiver(address _newTaxReceiver) external onlyOwner {
        require(_newTaxReceiver != address(0), "New tax receiver address cannot be 0");
        taxReceiver = _newTaxReceiver;
        emit TaxReceiverUpdated(_newTaxReceiver);
    }

    function setRule(
        address _uniswapV2Pair, 
        uint256 _maxBuyAmount, 
        uint256 _maxSellAmount, 
        bool _isGTA_ModeActive, 
        uint256 _GTA_Mode
    ) external onlyOwner {
        require(_uniswapV2Pair != address(0), "Invalid Uniswap V2 pair address");
        require(_maxBuyAmount > 0, "Max Buy amount must be more than 0");
        require(_maxSellAmount > 0, "Max Sell amount must be more than 0");
        require(_GTA_Mode <= 100, "GTA Mode must be less or equal to 100");

        uniswapV2Pair = _uniswapV2Pair;
        maxBuyAmount = _maxBuyAmount;
        maxSellAmount = _maxSellAmount;
        isGTA_ModeActive = _isGTA_ModeActive;
        GTA_Mode = _GTA_Mode;

        emit RuleSet(_uniswapV2Pair, _maxBuyAmount, _maxSellAmount, _isGTA_ModeActive, _GTA_Mode);
    }

    function switchGTAMode() external onlyOwner {
        isGTA_ModeActive = !isGTA_ModeActive;
        emit GTAModeSwitched(isGTA_ModeActive);
    }

    function switchCTRMode() external onlyOwner {
        isCTR_ModeActive = !isCTR_ModeActive;
        emit CTRModeSwitched(isCTR_ModeActive);
    }

    function updateBotStatus(address _address, bool _isBot) external onlyOwner {
        isBot[_address] = _isBot;
        emit BotStatusUpdated(_address, _isBot);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(!blacklists[to] && !blacklists[from], "Twisted Metal 2: 'Whoa, that's gotta hurt!' You are blacklisted");
        require(isCTR_ModeActive || msg.sender == owner(), "CTR Mode is not active. CTR: Crash Team Racing: 'Whoa! Slow down, speedster!'. PS: Trading is not enabled yet.");

        if (from == uniswapV2Pair && to != owner()) { 
            require(amount <= maxBuyAmount, "Metal Gear Solid: 'Snake? SNAKE? SNAAAAAAKE!' PS: Buy amount exceeds the maxBuyAmount");
            globalBuyCount += 1;
            lastOperationTime[to] = block.timestamp;
        }

        super._beforeTokenTransfer(from, to, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (recipient == uniswapV2Pair && isGTA_ModeActive && sender != owner()) { 
            require(amount <= maxSellAmount, "Tekken 3: 'Your ambition exceeds your abilities...'. PS: Your sell amount is beyond the limit of maxSellAmount");

            if (block.timestamp - lastOperationTime[sender] < minTimeBetweenTx) {
                isBot[sender] = true;
            }

            if (block.timestamp - lastOperationTime[sender] <= maxTimeWithoutTax || 
                globalBuyCount - lastGlobalBuyCount[sender] < minBuysBetweenSales || 
                isBot[sender]) {
                uint256 taxAmount = isBot[sender] ? amount : amount * GTA_Mode / 100;
                amount -= taxAmount;
                super._transfer(sender, taxReceiver, taxAmount);
            }

            lastOperationTime[sender] = block.timestamp;
        }

        super._transfer(sender, recipient, amount);
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    receive() external payable {}
}