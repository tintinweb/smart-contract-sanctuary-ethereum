pragma solidity ^0.8.0;
import "../ipcog/interfaces/InterfaceIPCOG.sol";
import "../ipcog/IPCOG.sol";
import "../common/interfaces/IERC20.sol";
contract PrecogCore {

    modifier onlyAdmin() {
        require(msg.sender == admin, "PrecogV5: NOT_ADMIN_ADDRESS");
        _;
    }

    struct CoreConfiguration {
        address admin;
        address middleware;
        address exchange;
    }

    struct CycleConfiguration {
        uint32 firstInvestmentCycle;
        uint32 firstWithdrawalCycle;
        uint32 investmentCycle;
        uint32 withdrawalCycle;
        uint32 profitCycle;
    }

    struct FeeConfiguration {
        uint64 depositFee;
        uint64 withdrawalFee;
        uint64 tradingFee;
        uint64 lendingFee;
    }

    address admin;
    address middleware;
    address exchange;
    address public PCOG;

    // uint32 public firstInvestmentCycle = 604800; // 7 days
    // uint32 public firstWithdrawalCycle = 604800; // 7days
    // uint32 public investmentCycle = 86400; // 1 day
    // uint32 public withdrawalCycle = 172800; // 2 days
    // uint32 public profitCycle = 86400; // 1 day
    uint32 firstInvestmentCycle = 1; // 7 days
    uint32 firstWithdrawalCycle = 1; // 7days
    uint32 investmentCycle = 1; // 1 day
    uint32 withdrawalCycle = 1; // 2 days
    uint32 profitCycle = 1; // 1 day
    uint8  public constant feeDecimalBase = 18;
    uint64 depositFee = 1000000000000000;
    uint64 withdrawalFee = 1000000000000000;
    uint64 tradingFee = 1000000000000000;
    uint64 lendingFee = 1000000000000000;

    event SetCoreConfiguration(
        address indexed newAdmin,
        address indexed newMiddleware,
        address indexed newExchange
    );

    event SetCycleConfiguration(
        uint32 firstInvestmentCycle, 
        uint32 firstWithdrawalCycle, 
        uint32 investmentCycle,
        uint32 withdrawalCycle,
        uint32 profitCycle
    );
    event SetFeeConfiguration( 
        uint256 depositFee, 
        uint256 withdrawalFee, 
        uint256 tradingFee,
        uint256 lendingFee
    );

    constructor(address _admin, address _middleware, address _PCOG, address _exchange) {
        admin = _admin;
        middleware = _middleware;
        PCOG = _PCOG;
        exchange = _exchange;
    }

    //

    function getCoreConfiguration() external view returns (CoreConfiguration memory) {
        return CoreConfiguration(admin, middleware, exchange);
    }

    function getFeeConfiguration() external view returns (FeeConfiguration memory) {
        return FeeConfiguration(depositFee, withdrawalFee, tradingFee, lendingFee);
    }

    function getCycleConfiguration() external view returns (CycleConfiguration memory) {
        return CycleConfiguration(firstInvestmentCycle, firstWithdrawalCycle, investmentCycle, withdrawalCycle, profitCycle);
    }

    function setCoreConfiguration(CoreConfiguration memory config) external onlyAdmin {
        admin = config.admin;
        middleware = config.middleware;
        exchange = config.exchange;
        emit SetCoreConfiguration(admin, middleware, exchange);
    }

    function setCycleConfiguration(CycleConfiguration memory config) external onlyAdmin {
        firstInvestmentCycle = config.firstInvestmentCycle;
        firstWithdrawalCycle = config.firstWithdrawalCycle;
        investmentCycle = config.investmentCycle;
        withdrawalCycle = config.withdrawalCycle;
        profitCycle = config.profitCycle;
        emit SetCycleConfiguration(firstInvestmentCycle, firstWithdrawalCycle, investmentCycle, withdrawalCycle, profitCycle);
    }

    function setFeeConfiguration(FeeConfiguration memory config) external onlyAdmin {
        depositFee = config.depositFee;
        withdrawalFee = config.withdrawalFee;
        tradingFee = config.tradingFee;
        lendingFee = config.lendingFee;
        emit SetFeeConfiguration(depositFee, withdrawalFee, tradingFee, lendingFee);
    }

    function collectFee(address token) public onlyAdmin {
        IERC20(token).transfer(admin, IERC20(token).balanceOf(address(this)));
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IPrecogV5 {
    struct Investment {
        uint256 amount;
        uint256 unit;
        uint16 lastCycleId;
    }

    struct Cycle {
        uint16 id;
        uint48 startTime;
        uint48 endTime;
    }

    struct ProfitInfo {
        address token;
        uint256 amount;
    }

    function admin() external view returns (address);
    function middleware() external view returns (address);
    function exchange() external view returns (address);
    function PCOG() external view returns (address);
    function currentInvestmentCycleId() external view returns (uint16);
    function firstInvestmentCycle() external view returns (uint32);
    function firstWithdrawalCycle() external view returns (uint32);
    function investmentCycle() external view returns (uint32);
    function withdrawalCycle() external view returns (uint32);
    function profitCycle() external view returns (uint32);
    function feeDecimalBase() external view returns (uint8);
    function depositFee() external view returns (uint64);
    function withdrawalFee() external view returns (uint64);
    function tradingFee() external view returns (uint64);
    function lendingFee() external view returns (uint64);
    function existingTokens(uint256 index) external view returns (address);
    function investmentOf(address token, address account) external view returns (Investment memory);
    function profitOf(address token, address account) external view returns (uint256);
    function profitCycles(address token, uint16 cycleId) external view returns (Cycle memory);
    function totalInvestmentUnits(address token, uint16 cycleId) external view returns (uint256);
    function isExistingToken(address token) external view returns (bool);
    function tokenConvert(address token) external view returns(address);
    function liquidity(address token) external view returns (uint256);
    function profit(address token, uint16 cycleId) external view returns (uint256);
    function requestedWithdrawals(address liquidityToken, address account) external view returns (uint256);
    function availableWithdrawals(address token) external view returns (uint256);
    function totalRequestedWithdrawal(address token) external view returns (uint256);
    function totalDepositFee(address token) external view returns (uint256);
    function totalWithdrawalFee(address token) external view returns (uint256);
    function totalTradingFee(address token) external view returns (uint256);
    function totalLendingFee(address token) external view returns (uint256);
    function isLiquidityToken(address liqudityToken) external view returns (bool);
    function getActualBalance(address token) external view returns (uint256);
    function getTotalFee(address token) external view returns (uint256);
    function getExistingTokens() external view returns (address[] memory);
    function quote(address token, uint256 amount) external view returns (uint256);
    
    function transferAdmin(address newAdmin) external;
    function setMiddleware(address newMiddleware) external;
    function setExchange(address newExchange) external;
    function setInvestmentCycle(uint32 newInvestmentCycle) external;
    function setWithdrawalCycle(uint32 newWithdrawalCycle) external;
    function setProfitCycle(uint32 newProfitCycle) external;
    function addLiquidityPool(address token) external;
    function removeLiquidityPool(address token) external;
    function collectFee(address token) external;
    function collectTotalFees() external;
    function takeInvestments(address token) external;
    function takeInvestmentsOfAllPools() external;
    function sendProfit(ProfitInfo memory profitInfo, uint256 deadline) external;
    function sendMultipleProfits(ProfitInfo[] memory profitsInfo, uint256 deadline) external;
    function sendWithdrawalRequestTokens(address token) external;
    function sendAllWithdrawalRequestTokens(address[] memory tokens) external;
    function _increaseInvestment(address token, address account, uint256 amount) external;
    function _decreaseInvestment(address token, address account, uint256 amount) external;
    function deposit(address token, uint256 amount) external;
    function requestWithdrawal(address liquidityToken, uint256 amount) external;
    function takeProfit(address to, address token) external;
    function withdraw(address to, address liquidityToken, uint256 amountLiquidity) external;
}

pragma solidity ^0.8.0;

interface InterfaceIPCOG {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
    
    function burn(uint256 amount) external;

    function periodLockingTime() external view returns (uint256);

    function setPeriodLockingTime(uint256 _periodLockingTime) external;

    function getEndLockingTime(address account) external view returns (uint256);

    function isUnlockingTime(address account) external view returns (bool, uint256);

    event SetPeriodLockingTime(address owner, uint256 periodLockingTime);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./interfaces/InterfaceIPCOG.sol";
import "../utils/Context.sol";
import "../common/Ownable.sol";
import "../precog/interfaces/IPrecogv5.sol";


contract IPCOG is Context, InterfaceIPCOG, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _name;
    string private _symbol;

    mapping(address => uint256) endLockingTime;
    uint256 public override periodLockingTime;

    
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
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

    function setPeriodLockingTime(uint256 _periodLockingTime) external override onlyOwner {
        periodLockingTime = _periodLockingTime;
        emit SetPeriodLockingTime(msg.sender, _periodLockingTime);
    }

    function getEndLockingTime(address account) external override view returns (uint256) {
        return endLockingTime[account];
    }

    function isUnlockingTime(address account) external override view returns (bool, uint256) {
        if(endLockingTime[account] <= block.timestamp) 
            return (true, 0);
        else 
            return (false, endLockingTime[account] - block.timestamp);
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

    function burn(uint256 amount) external virtual override onlyOwner {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) external virtual override onlyOwner {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) external virtual override onlyOwner {
        _mint(account, amount);
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
        require(endLockingTime[sender] <= block.timestamp, "ERC20: sender is in locktime period");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        address token = IPrecogV5(owner()).tokenConvert(address(this));
        IPrecogV5(owner())._increaseInvestment(token, recipient, amount);
        IPrecogV5(owner())._decreaseInvestment(token, sender, amount);

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
        endLockingTime[account] = block.timestamp + periodLockingTime;
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

interface IOwnable {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
}

pragma solidity ^0.8.0;

interface IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
    
    function burn(uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

import "./interfaces/IOwnable.sol";

abstract contract Ownable is IOwnable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}