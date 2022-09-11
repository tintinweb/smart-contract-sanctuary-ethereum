// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IFactory.sol";

contract HRD is IERC20, Ownable {
    string public constant _name = "Hoard";
    string public constant _symbol = "HRD";
    uint8 public constant _decimals = 9;

    uint256 public constant _totalSupply = 10_000_000 * (10 ** _decimals);

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;

    mapping (address => bool) public antibotWhitelist;

    IRouter public constant router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    bool public taxes = true;
    bool public antibot = true;
    bool public swapping;

    mapping (address => bool) public noTax;
    mapping (address => bool) public dexPair;

    uint256 public buyFee = 300;
    uint256 public sellFee = 300;
    bool public halfLiq;

    uint256 private _tokens = 0;

    uint256 public swapTrigger = 0;
    uint256 public swapThreshold = _totalSupply / 40000;

    bool private _swapping;

    modifier intraswap() {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor () {
        address _pair = IFactory(router.factory()).createPair(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, address(this));

        _allowances[address(this)][address(router)] = _totalSupply;

        antibotWhitelist[msg.sender] = true;
        antibotWhitelist[_pair] = true;

        noTax[msg.sender] = true;
        dexPair[_pair] = true;

        approve(address(router), _totalSupply);
        approve(address(_pair), _totalSupply);

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            require(_allowances[sender][msg.sender] >= amount, "Insufficient allowance");
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) private returns (bool) {
        if (_swapping) return _basicTransfer(sender, recipient, amount);
        require(swapping || sender == owner());
        if (antibot) require(antibotWhitelist[sender] || _balances[recipient] + amount < 100_000_000_000_000, "Antibot enabled");

        address routerAddress = address(router);
        bool _sell = dexPair[recipient] || recipient == routerAddress;

        if (_sell && amount >= swapTrigger && _tokens > 0) {
            if (!dexPair[msg.sender] && !_swapping && _balances[address(this)] >= swapThreshold) _sellTaxedTokens();
        }

        require(_balances[sender] >= amount, "Insufficient balance");
        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = (((dexPair[sender] || sender == address(router)) || (dexPair[recipient]|| recipient == address(router))) ? !noTax[sender] && !noTax[recipient] : false) ? _collectTaxedTokens(sender, recipient, amount) : amount;

        _balances[recipient] = _balances[recipient] + amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(_balances[sender] >= amount, "Insufficient balance");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        return true;
    }

    function _collectTaxedTokens(address sender, address receiver, uint256 amount) private returns (uint256) {
        bool _sell = dexPair[receiver] || receiver == address(router);
        uint256 _fee = _sell ? sellFee : buyFee;
        uint256 _tax = amount * _fee / 10000;

        if (_fee > 0) {
            if (_sell) {
                if (sellFee > 0) _tokens += _tax * sellFee / _fee;
            } else {
                if (buyFee > 0) _tokens += _tax * buyFee / _fee;
            }
        }

        _balances[address(this)] = _balances[address(this)] + _tax;
        emit Transfer(sender, address(this), _tax);

        return amount - _tax;
    }

    function _sellTaxedTokens() private intraswap {
        uint256 _tokensHalf = _tokens / 2;
        uint256 _balanceSnapshot = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(balanceOf(address(this)) - _tokensHalf, 0, path, address(this), block.timestamp);

        uint256 _tax = (address(this).balance - _balanceSnapshot);
        if (halfLiq) _tax = _tax / 2;

        if (_tax > 0) router.addLiquidityETH{value: _tax}(address(this), _tokensHalf, 0, 0, 0x000000000000000000000000000000000000dEaD, block.timestamp);

        _tokens = 0;
    }

    function taxesDisabled() external view returns (bool) {
        return !taxes;
    }

    function disableTaxes() external onlyOwner {
        require(taxes);
        taxes = false;
        buyFee = 0;
        sellFee = 0;
    }

    function antibotDisabled() external view returns (bool) {
        return !antibot;
    }

    function disableAntibot() external onlyOwner {
        require(antibot);
        antibot = false;
    }

    function swappingEnabled() external view returns (bool) {
        return swapping;
    }

    function enableSwapping() external onlyOwner {
        require(!swapping);
        swapping = true;
    }

    function addDexPair(address _pair) external onlyOwner {
        dexPair[_pair] = true;
    }

    function getDexPair(address _pair) external view returns (bool) {
        return dexPair[_pair];
    }

    function removeNoTax(address _wallet) external onlyOwner {
        noTax[_wallet] = false;
    }

    function getNoTax(address _wallet) external view returns (bool) {
        return noTax[_wallet];
    }

    function changeFees(uint256 _buyFee, uint256 _sellFee, bool _halfLiq, uint256 _swapTrigger, uint256 _swapThreshold) external onlyOwner {
        if (taxes) {
            buyFee = _buyFee;
            sellFee = _sellFee;
            halfLiq = _halfLiq;
        }
        swapTrigger = _swapTrigger;
        swapThreshold = _swapThreshold;
    }

    function rescue(address token) external onlyOwner {
        if (token == 0x0000000000000000000000000000000000000000) {
            payable(msg.sender).call{value: address(this).balance}("");
        } else {
            IERC20 Token = IERC20(token);
            Token.transfer(msg.sender, Token.balanceOf(address(this)));
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IRouter {
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}