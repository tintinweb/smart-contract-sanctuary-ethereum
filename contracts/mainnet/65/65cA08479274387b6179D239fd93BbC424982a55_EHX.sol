// SPDX-License-Identifier: MIT                                                                               
                                                    
pragma solidity ^0.8.16;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is Context, IERC20 {
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
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
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract AuthorizedRole is Ownable {
    using Roles for Roles.Role;

    event AuthorizedAdded(address indexed account);
    event AuthorizedRemoved(address indexed account);

    Roles.Role private _authorizeds;

    modifier onlyAuthorized() {
        require(isAuthorized(msg.sender), "AuthorizedRole: caller does not have the Authorized role");
        _;
    }

    function isAuthorized(address account) public view returns (bool) {
        return _authorizeds.has(account);
    }

    function addAuthorized(address account) public onlyOwner {
        _addAuthorized(account);
    }

    function removeAuthorized(address account) public onlyOwner {
        _removeAuthorized(account);
    }

    function renounceAuthorized() public {
        _removeAuthorized(msg.sender);
    }

    function _addAuthorized(address account) internal {
        _authorizeds.add(account);
        emit AuthorizedAdded(account);
    }

    function _removeAuthorized(address account) internal {
        _authorizeds.remove(account);
        emit AuthorizedRemoved(account);
    }
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract EHX is ERC20, Ownable, AuthorizedRole {

    uint256 public maxTransaction;

    address public robinHoodWallet;
    uint256 public robinHoodPercent = 10;

    IDexRouter public immutable dexRouter;
    //address public immutable lpPair;
    address public immutable lpPairEth;

    mapping (address => uint256) public lastBuyBlock;

    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    mapping (address => bool) public restrictedWallets;
    uint256 public blockForPenaltyEnd;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public robinHoodActive = true;
    
    mapping (address => bool) public _isWhitelisted;

    mapping (address => bool) public automatedMarketMakerPairs;

    // Events

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event EnabledTrading();
    event RemovedLimits();
    event Whitelisted(address indexed account, bool isWhitelisted);
    event UpdatedMaxTransaction(uint256 newAmount);
    event TransferForeignToken(address token, uint256 amount);

    constructor() ERC20("Eterna", "EHX") {

        address stablecoinAddress;
        address _dexRouter;

        // automatically detect router/desired stablecoin
        if(block.chainid == 1){
            stablecoinAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC
            _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH: Uniswap V2
        } else if(block.chainid == 4){
            stablecoinAddress  = 0xE7d541c18D6aDb863F4C570065c57b75a53a64d3; // Rinkeby Testnet USDC
            _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH: Uniswap V2
        } else if(block.chainid == 56){
            stablecoinAddress  = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // BUSD
            _dexRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BNB Chain: PCS V2
        } else if(block.chainid == 97){
            stablecoinAddress  = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; // BSC Testnet BUSD
            _dexRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // BNB Chain: PCS V2
        } else {
            revert("Chain not configured");
        }

        dexRouter = IDexRouter(_dexRouter);

        // create pair
        // lpPair = IDexFactory(dexRouter.factory()).createPair(address(this), address(stablecoinAddress));
        // setAutomatedMarketMakerPair(address(lpPair), true);

        lpPairEth = IDexFactory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        setAutomatedMarketMakerPair(address(lpPairEth), true);

        uint256 totalSupply = 2 * 1e9 * 1e18;
        
        maxTransaction = totalSupply * 5 / 1000;

        setWhitelistedAddress(address(this), true);
        setWhitelistedAddress(address(0xdead), true);
        setWhitelistedAddress(address(dexRouter), true);
        setWhitelistedAddress(address(msg.sender), true);

        _mint(address(msg.sender), totalSupply);
    }

    // Owner / Whitelisted Functions

    function enableTrading() external onlyOwner {
        require(!tradingActive, "Trading is already active, cannot relaunch.");
        tradingActive = true;
        tradingActiveBlock = block.number;
        emit EnabledTrading();
    }

    function manageRestrictedWallets(address[] calldata wallets, bool restricted) external onlyOwner {
        for(uint256 i = 0; i < wallets.length; i++){
            restrictedWallets[wallets[i]] = restricted;
        }
    }
    
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        maxTransaction = totalSupply();
        emit RemovedLimits();
    }

    function setRobinHoodActive(bool active) external onlyOwner {
        robinHoodActive = active;
    }

    function setRobinHoodPercent(uint256 perc) external onlyOwner {
        require(perc <= 10000, "too high");
        robinHoodPercent = perc;
    }

    function setRobinHoodAddress(address wallet) external onlyOwner {
        require(wallet != address(0), "zero address");
        robinHoodWallet = wallet;
    }

    function updateMaxTransaction(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 1000) / (10 ** decimals()), "Cannot set max buy amount lower than 0.1%");
        maxTransaction = newNum * (10 ** decimals());
        emit UpdatedMaxTransaction(maxTransaction);
    }
    
    function transferForeignToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }
        
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(value, "The pair cannot be removed from automatedMarketMakerPairs");
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setWhitelistedAddress(address account, bool excluded) public onlyOwner {
        _isWhitelisted[account] = excluded;
        emit Whitelisted(account, excluded);
    }

    function mintTokens(address destination, uint256 amount) public onlyAuthorized {
        _mint(destination, amount);
    }

    function burnTokens(uint256 amount) public onlyAuthorized {
        _burn(msg.sender, amount);
    }

    // private / internal functions

    function _transfer(address from, address to, uint256 amount) internal override {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        // transfer of 0 is allowed, but triggers no logic.  In case of staking where a staking pool is paying out 0 rewards.
        if(amount == 0){
            super._transfer(from, to, 0);
            return;
        }
        
        if(!tradingActive){
            require(_isWhitelisted[from] || _isWhitelisted[to], "Trading is not active.");
        }

        if(tradingActiveBlock > 0){
            require((!restrictedWallets[from] && !restrictedWallets[to]) || to == owner() || to == address(0xdead), "Restricted wallet");
        }
        
        if(robinHoodActive && (!_isWhitelisted[to] && !_isWhitelisted[from])){
            if(automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to]){
                lastBuyBlock[to] = block.number;
            } else if(lastBuyBlock[from] == block.number && robinHoodPercent > 0){
                uint256 robinHoodAmount = amount * robinHoodPercent / 10000;
                uint256 transferAmount = amount - robinHoodAmount;
                super._transfer(from, robinHoodWallet, robinHoodAmount);
                super._transfer(from, to, transferAmount);
                return;
            }
        }

        if(limitsInEffect){
            if (!_isWhitelisted[from] && !_isWhitelisted[to]){
                //on buy or sell
                if (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]) {
                    require(amount <= maxTransaction, "Buy transfer amount exceeds the max buy.");
                }
            }
        }

        super._transfer(from, to, amount);
    }
}