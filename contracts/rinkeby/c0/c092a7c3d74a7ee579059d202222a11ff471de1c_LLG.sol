/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
}

contract LLG is ERC20, Ownable {
    using SafeMath for uint256;

    string private _name = "LLG";
    string private _symbol = "LLG";
    uint8 private _decimals = 18;

    bool public isTradingEnabled;
    uint256 constant initialSupply = 100000000 * (10**18);
    uint256 public maxWalletAmount = 1200000 * (10**18);
    uint256 public maxTxAmount = initialSupply * 20 / 10000; //200_000_000 
    bool private _swapping;
    // reward wallets
    address public marketingWallet;
    address public devWallet;
    address public liquidityWallet;
    // Base taxes
    uint256 public marketingFee = 4;
    uint256 public devFee = 3;
    uint256 public liquidityFee = 3;
    
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromMaxTransactionLimit;
    mapping (address => bool) private _isExcludedFromMaxWalletLimit;
    mapping (address => bool) private _isBlacklisted;

    event DividendTrackerChange(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFeesChange(address indexed account, bool isExcluded);
    event LiquidityWalletChange(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event MarketingWalletChange(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    event DevWalletChange(address indexed newBuyBackWallet, address indexed oldBuyBackWallet);
    event FeeChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType);


    event SalaryWalletChange(address indexed newSalaryWallet, address indexed oldSalaryWallet);
    event GasForProcessingChange(uint256 indexed newValue, uint256 indexed oldValue);
    event FeeOnSellChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType);
    event FeeOnBuyChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType);
    event CustomTaxPeriodChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType, bytes23 period);
    event BlacklistChange(address indexed holder, bool indexed status);
    event KodiRoarChange(bool indexed newValue, bool indexed oldValue);
    event MaxTransactionAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event MaxWalletAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
    event ExcludeFromMaxTransferChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
    event ExcludeFromDividendsChange(address indexed account, bool isExcluded);

    constructor() ERC20("LLG", "LLG") {
      devWallet = address(0x0e38abe3b61c596c8caaCdd5c75584bF37a94c65);
      liquidityWallet = address(0xD7B3DA72a306574F2f806A22521b1E3BD47C86F4);
    	marketingWallet = address(0x56baAa0824228d12fAdFbE32514d1dD70BB92E9A);

      marketingFee = 4;
      devFee = 3;
      liquidityFee = 3;

      _isExcludedFromFee[owner()] = true;
      _isExcludedFromFee[address(this)] = true;
      _isExcludedFromFee[marketingWallet] = true;
      _isExcludedFromFee[devWallet] = true;
      _isExcludedFromFee[liquidityWallet] = true;

      _isExcludedFromMaxTransactionLimit[owner()] = true;
      _isExcludedFromMaxTransactionLimit[address(this)] = true;
      _isExcludedFromMaxTransactionLimit[marketingWallet] = true;
      _isExcludedFromMaxTransactionLimit[devWallet] = true;
      _isExcludedFromMaxTransactionLimit[liquidityWallet] = true;
      
      _isExcludedFromMaxWalletLimit[address(this)] = true;
      _isExcludedFromMaxWalletLimit[owner()] = true;

      _mint(owner(), initialSupply);
    }
    
    receive() external payable {}
    
    // Setters
    function _getNow() private view returns (uint256) {
        return block.timestamp;
    }
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFee[account] != excluded, "LLG: Account is already the value of 'excluded'");
        _isExcludedFromFee[account] = excluded;
        emit ExcludeFromFeesChange(account, excluded);
    }
    function excludeFromMaxTransactionLimit(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromMaxTransactionLimit[account] != excluded, "LLG: Account is already the value of 'excluded'");
        _isExcludedFromMaxTransactionLimit[account] = excluded;
        emit ExcludeFromMaxTransferChange(account, excluded);
    }
    function excludeFromMaxWalletLimit(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromMaxWalletLimit[account] != excluded, "LLG: Account is already the value of 'excluded'");
        _isExcludedFromMaxWalletLimit[account] = excluded;
        emit ExcludeFromMaxWalletChange(account, excluded);
    }
    function blacklistAccount(address account) public onlyOwner {
        require(!_isBlacklisted[account], "LLG: Account is already blacklisted");
        _isBlacklisted[account] = true;
        emit BlacklistChange(account, true);
    }
    function unBlacklistAccount(address account) public onlyOwner {
        require(_isBlacklisted[account], "LLG: Account is not blacklisted");
        _isBlacklisted[account] = false;
        emit BlacklistChange(account, false);
    }
    function setLiquidityWallet(address newAddress) public onlyOwner {
        require(liquidityWallet != newAddress, "LLG: The liquidityWallet is already that address");
        emit LiquidityWalletChange(newAddress, liquidityWallet);
        liquidityWallet = newAddress;
    }
    function setMarketingWallet(address newAddress) public onlyOwner {
        require(marketingWallet != newAddress, "LLG: The marketingWallet is already that address");
        emit MarketingWalletChange(newAddress, marketingWallet);
        marketingWallet = newAddress;
    }
    function setDevWallet(address newAddress) public onlyOwner {
        require(devWallet != newAddress, "LLG: The devWallet is already that address");
        emit DevWalletChange(newAddress, devWallet);
        devWallet = newAddress;
    }

    function setLiquidityFee(uint256 newvalue) public onlyOwner {
        require(liquidityFee != newvalue, "LLG: The liquidityFee is already that value");
        emit FeeChange(newvalue, liquidityFee, "liquidityFee");
        liquidityFee = newvalue;
    }
    function setMarketingFee(uint256 newvalue) public onlyOwner {
        require(marketingFee != newvalue, "LLG: The marketingFee is already that value");
        emit FeeChange(newvalue, marketingFee, "marketingFee");
        marketingFee = newvalue;
    }
    function setDevFee(uint256 newvalue) public onlyOwner {
        require(devFee != newvalue, "LLG: The devFee is already that value");
        emit FeeChange(newvalue, marketingFee, "devFee");
        devFee = newvalue;
    }
    function setMaxTxAmount(uint256 newValue) public onlyOwner {
        require(newValue != maxTxAmount, "LLG: Cannot update maxTxAmount to same value");
        emit MaxTransactionAmountChange(newValue, maxTxAmount);
        maxTxAmount = newValue;
    }
    function setMaxWalletAmount(uint256 newValue) public onlyOwner {
        require(newValue != maxWalletAmount, "LLG: Cannot update maxWalletAmount to same value");
        emit MaxWalletAmountChange(newValue, maxWalletAmount);
        maxWalletAmount = newValue;
    }

    // Main
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        if(from != owner() && to != owner()) {
            require(!_isBlacklisted[to], "LLG: Account is blacklisted");
            require(!_isBlacklisted[from], "LLG: Account is blacklisted");
            if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[from]) {
                require(amount <= maxTxAmount, "LLG: Buy amount exceeds the maxTxBuyAmount.");
            }
            if (!_isExcludedFromMaxWalletLimit[to]) {
                require(balanceOf(to).add(amount) <= maxWalletAmount, "LLG: Expected wallet amount exceeds the maxWalletAmount.");
            }
        }
        
        bool takeFee = true;
        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        if (takeFee) {
            (uint256 returnAmount, uint256 fee) = _getCurrentTotalFee(amount);
            amount = returnAmount;
            super._transfer(from, address(this), fee);
        }
        
        super._transfer(from, to, amount);
    }

    function _getCurrentTotalFee(uint256 amount) public view returns (uint256 returnAmount, uint256 fee) {
        uint256 _liquidityFee = liquidityFee;
        uint256 _marketingFee = marketingFee;
        uint256 _devFee = devFee;

        uint256 _totalFee = _liquidityFee.add(_marketingFee).add(_devFee);

        fee = amount.mul(_totalFee).div(100);
        returnAmount = amount.sub(fee);
        return (returnAmount, fee);
    }
}