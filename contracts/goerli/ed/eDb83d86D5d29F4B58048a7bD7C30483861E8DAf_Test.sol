/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ERC20.sol
abstract contract ERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Ownable.sol
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// ReentrancyGuard.sol
contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}


// Tst.sol
contract Test is ERC20, Ownable, ReentrancyGuard {
    uint256 private constant INITIAL_SUPPLY = 100000000 * (10 ** 18);
    uint256 private constant TARGET_PRICE = 1 * (10 ** 18);
    uint256 private constant MAX_PRICE_CHANGE = 10 * (10 ** 16); // 1%
    uint256 private constant PROTOCOL_FEE = 5; // 5%
    uint256 private constant MARKETING_FEE = 3; // 3%
    uint256 private constant LIQUIDITY_FEE = 1; // 1%
    uint256 private constant TX_WINDOW_DURATION = 1 hours;

    bool private isBuySell;
    address private protocolWallet;
    address private marketingWallet;
    address private liquidityPool;

    mapping(address => bool) private taxWhitelist;
    mapping(address => bool) private windowWhitelist;
    mapping(address => uint256) private lastTransaction;

    constructor(
        address _protocolWallet,
        address _marketingWallet,
        address _liquidityPool
    ) ERC20("Test 5", "TST5") {
        _mint(msg.sender, INITIAL_SUPPLY);
        protocolWallet = _protocolWallet;
        marketingWallet = _marketingWallet;
        liquidityPool = _liquidityPool;
    }

    modifier onlyBuySell() {
        require(isBuySell, "Buy/sell only");
        _;
    }

    modifier antiBot(
        address sender,
        address recipient,
        uint256 amount
    ) {
        require(
            windowWhitelist[sender] ||
                windowWhitelist[recipient] ||
                block.timestamp >= lastTransaction[sender] + TX_WINDOW_DURATION,
            "Anti-bot: Excessive transactions"
        );
        _;
        lastTransaction[sender] = block.timestamp;
    }

    function burn(uint256 amount) public nonReentrant {
        _burn(msg.sender, amount);
    }

    function buy() public payable nonReentrant {
        require(isBuySell || taxWhitelist[msg.sender], "Buy/sell only");
        uint256 price = getPrice();
        uint256 amount = msg.value / price;
        uint256 totalFees = (amount * (PROTOCOL_FEE + MARKETING_FEE + LIQUIDITY_FEE)) / 100;
        uint256 total = amount - totalFees;
        _mint(msg.sender, total);
    
        (bool protocolSuccess, ) = protocolWallet.call{value: (msg.value * PROTOCOL_FEE) / 100}("");
        (bool marketingSuccess, ) = marketingWallet.call{value: (msg.value * MARKETING_FEE) / 100}("");
        (bool liquiditySuccess, ) = liquidityPool.call{value: (msg.value * LIQUIDITY_FEE) / 100}("");
    
        require(protocolSuccess, "Failed to send protocol fee");
        require(marketingSuccess, "Failed to send marketing fee");
        require(liquiditySuccess, "Failed to send liquidity fee");
    
        isBuySell = true;
    }

    function sell(uint256 amount) public nonReentrant {
        require(isBuySell || taxWhitelist[msg.sender], "Buy/sell only");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        uint256 price = getPrice();
        uint256 value = amount * price;
        uint256 totalFees = (value * (PROTOCOL_FEE + MARKETING_FEE + LIQUIDITY_FEE)) / 100;
        uint256 total = value - totalFees;
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(total);
    
        (bool protocolSuccess, ) = protocolWallet.call{value: (value * PROTOCOL_FEE) / 100}("");
        (bool marketingSuccess, ) = marketingWallet.call{value: (value * MARKETING_FEE) / 100}("");
        (bool liquiditySuccess, ) = liquidityPool.call{value: (value * LIQUIDITY_FEE) / 100}("");
    
        require(protocolSuccess, "Failed to send protocol fee");
        require(marketingSuccess, "Failed to send marketing fee");
        require(liquiditySuccess, "Failed to send liquidity fee");
    
        isBuySell = true;
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        onlyBuySell
        antiBot(msg.sender, recipient, amount)
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function getPrice() public view returns (uint256) {
        uint256 supply = totalSupply();
        uint256 balance = address(this).balance;
        uint256 price = balance / supply;
        uint256 maxPrice = TARGET_PRICE + MAX_PRICE_CHANGE;
        uint256 minPrice = TARGET_PRICE - MAX_PRICE_CHANGE;
        if (price > maxPrice) {
            return maxPrice;
        } else if (price < minPrice) {
            return minPrice;
        } else {
            return price;
        }
    }

    function setProtocolWallet(address wallet) public onlyOwner {
        protocolWallet = wallet;
    }

    function setMarketingWallet(address wallet) public onlyOwner {
        marketingWallet = wallet;
    }

    function setLiquidityPool(address pool) public onlyOwner {
        liquidityPool = pool;
    }

    function addToTaxWhitelist(address account) public onlyOwner {
        taxWhitelist[account] = true;
    }

    function removeFromTaxWhitelist(address account) public onlyOwner {
        taxWhitelist[account] = false;
    }

    function addToWindowWhitelist(address account) public onlyOwner {
        windowWhitelist[account] = true;
    }

    function removeFromWindowWhitelist(address account) public onlyOwner {
        windowWhitelist[account] = false;
    }

    function withdraw() public onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }

}