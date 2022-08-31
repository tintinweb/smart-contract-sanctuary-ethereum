/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

/*
vitaliksbighardcock.eth | t.me/vitaliksbighardcock
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IINCH {
    function deposit() external payable;
}

contract VBHC is IERC20, Ownable {
    string public constant _name = "Vitalik's Big Hard Cock";
    string public constant _symbol = "VBHC";
    uint8 public constant _decimals = 9;

    uint256 public constant _totalSupply = 1000000000 * (10 ** _decimals);

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;

    mapping (address => bool) public noTax;
    mapping (address => bool) public noMax;
    mapping (address => bool) public dexPair;

    uint256 public buyFeeLiquidity = 200;
    uint256 public buyFeeDev1 = 400;
    uint256 public buyFeeDev2 = 100;
    uint256 public buyFeeDev3 = 100;
    uint256 public buyFeeInch = 0;
    uint256 public buyFeeInchStretched = 0;
    uint256 public buyFee = 800;

    uint256 public sellFeeLiquidity = 200;
    uint256 public sellFeeDev1 = 0;
    uint256 public sellFeeDev2 = 0;
    uint256 public sellFeeDev3 = 0;
    uint256 public sellFeeInch = 150;
    uint256 public sellFeeInchStretched = 450;
    uint256 public sellFee = 800;

    uint256 public lowerSellFeeLiquidity = 200;
    uint256 public lowerSellFeeDev1 = 0;
    uint256 public lowerSellFeeDev2 = 0;
    uint256 public lowerSellFeeDev3 = 0;
    uint256 public lowerSellFeeInch = 0;
    uint256 public lowerSellFeeInchStretched = 0;
    uint256 public lowerSellFee = 200;

    uint256 private _tokensLiquidity;
    uint256 private _tokensDev1;
    uint256 private _tokensDev2;
    uint256 private _tokensDev3;
    uint256 private _tokensInch;
    uint256 private _tokensInchStretched;

    address public walletLiquidity = 0x000000000000000000000000000000000000dEaD;
    address public walletDev1 = 0x492781e3A18d2949fCB199b2bc14aC684BE682c7;
    address public walletDev2 = 0x6e36E3FEf37Ad566cF9E21B3210094949e906115;
    address public walletDev3 = 0xb58C3F7E5a5F62B26E2DA1C6A5f6920Feb262383;
    address public walletInch;
    address public walletInchStretched;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IRouter public constant router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public pair;

    uint256 public maxWallet = _totalSupply / 50;
    uint256 public swapTrigger = 0;
    uint256 public swapThreshold = _totalSupply / 40000;

    bool public tradingLive = false;

    bool private _swapping;

    modifier swapping() {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor () {
        pair = IFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;

        noTax[msg.sender] = true;
        noMax[msg.sender] = true;

        dexPair[pair] = true;
        noMax[pair] = true;

        approve(address(router), _totalSupply);
        approve(address(pair), _totalSupply);

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
        require(tradingLive || sender == owner(), "Trading not live");

        address routerAddress = address(router);
        bool _sell = dexPair[recipient] || recipient == routerAddress;

        if (!_sell && !noMax[recipient]) require((_balances[recipient] + amount) < maxWallet, "Max wallet triggered");

        if (_sell && amount >= swapTrigger) {
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
                if (sellFeeLiquidity > 0) _tokensLiquidity += _tax * sellFeeLiquidity / _fee;
                if (sellFeeDev1 > 0) _tokensDev1 += _tax * sellFeeDev1 / _fee;
                if (sellFeeDev2 > 0) _tokensDev2 += _tax * sellFeeDev2 / _fee;
                if (sellFeeDev3 > 0) _tokensDev3 += _tax * sellFeeDev3 / _fee;
                if (sellFeeInch > 0) _tokensInch += _tax * sellFeeInch / _fee;
                if (sellFeeInchStretched > 0) _tokensInchStretched += _tax * sellFeeInchStretched / _fee;
            } else {
                if (buyFeeLiquidity > 0) _tokensLiquidity += _tax * buyFeeLiquidity / _fee;
                if (buyFeeDev1 > 0) _tokensDev1 += _tax * buyFeeDev1 / _fee;
                if (buyFeeDev2 > 0) _tokensDev2 += _tax * buyFeeDev2 / _fee;
                if (buyFeeDev3 > 0) _tokensDev3 += _tax * buyFeeDev3 / _fee;
                if (buyFeeInch > 0) _tokensInch += _tax * buyFeeInch / _fee;
                if (buyFeeInchStretched > 0) _tokensInchStretched += _tax * buyFeeInchStretched / _fee;
            }
        }

        _balances[address(this)] = _balances[address(this)] + _tax;
        emit Transfer(sender, address(this), _tax);

        return amount - _tax;
    }

    function _sellTaxedTokens() private swapping {
        uint256 _tokens = _tokensLiquidity + _tokensDev1 + _tokensDev2 + _tokensDev3 + _tokensInch + _tokensInchStretched;

        uint256 _liquidityTokensToSwapHalf = _tokensLiquidity / 2;
        uint256 _swapInput = balanceOf(address(this)) - _liquidityTokensToSwapHalf;

        uint256 _balanceSnapshot = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(_swapInput, 0, path, address(this), block.timestamp);

        uint256 _tax = address(this).balance - _balanceSnapshot;

        uint256 _taxLiquidity = _tax * _tokensLiquidity / _tokens / 2;
        uint256 _taxDev1 = _tax * _tokensDev1 / _tokens;
        uint256 _taxDev2 = _tax * _tokensDev2 / _tokens;
        uint256 _taxDev3 = _tax * _tokensDev3 / _tokens;
        uint256 _taxInch = _tax * _tokensInch / _tokens;
        uint256 _taxInchStretched = _tax * _tokensInchStretched / _tokens;

        _tokensLiquidity = 0;
        _tokensDev1 = 0;
        _tokensDev2 = 0;
        _tokensDev3 = 0;
        _tokensInch = 0;
        _tokensInchStretched = 0;

        if (_taxLiquidity > 0) router.addLiquidityETH{value: _taxLiquidity}(address(this), _liquidityTokensToSwapHalf, 0, 0, walletLiquidity, block.timestamp);
        if (_taxDev1 > 0) payable(walletDev1).call{value: _taxDev1}("");
        if (_taxDev2 > 0) payable(walletDev2).call{value: _taxDev2}("");
        if (_taxDev3 > 0) payable(walletDev3).call{value: _taxDev3}("");
        if (_taxInch > 0) try IINCH(walletInch).deposit{value: _taxInch}() {} catch { payable(address(this)).call{value: _taxInch}(""); }
        if (_taxInchStretched > 0) try IINCH(walletInchStretched).deposit{value: _taxInchStretched}() {} catch { payable(address(this)).call{value: _taxInchStretched}(""); }
    }

    function changeDexPair(address _pair, bool _value) external onlyOwner {
        dexPair[_pair] = _value;
    }

    function fetchDexPair(address _pair) external view returns (bool) {
        return dexPair[_pair];
    }

    function changeNoTax(address _wallet, bool _value) external onlyOwner {
        noTax[_wallet] = _value;
    }

    function fetchNoTax(address _wallet) external view returns (bool) {
        return noTax[_wallet];
    }

    function changeNoMax(address _wallet, bool _value) external onlyOwner {
        noMax[_wallet] = _value;
    }

    function fetchNoMax(address _wallet) external view onlyOwner returns (bool) {
        return noMax[_wallet];
    }

    function changeMaxWallet(uint256 _maxWallet) external onlyOwner {
        maxWallet = _maxWallet;
    }

    function changeBuyFees(uint256 _buyFeeLiquidity, uint256 _buyFeeDev1, uint256 _buyFeeDev2, uint256 _buyFeeDev3, uint256 _buyFeeInch, uint256 _buyFeeInchStretched) external onlyOwner {
        buyFeeLiquidity = _buyFeeLiquidity;
        buyFeeDev1 = _buyFeeDev1;
        buyFeeDev2 = _buyFeeDev2;
        buyFeeDev3 = _buyFeeDev3;
        buyFeeInch = _buyFeeInch;
        buyFeeInchStretched = _buyFeeInchStretched;
        buyFee = _buyFeeLiquidity + _buyFeeDev1 + _buyFeeDev2 + _buyFeeDev3 + _buyFeeInch + _buyFeeInchStretched;
    }

    function changeSellFees(uint256 _sellFeeLiquidity, uint256 _sellFeeDev1, uint256 _sellFeeDev2, uint256 _sellFeeDev3, uint256 _sellFeeInch, uint256 _sellFeeInchStretched) external onlyOwner {
        sellFeeLiquidity = _sellFeeLiquidity;
        sellFeeDev1 = _sellFeeDev1;
        sellFeeDev2 = _sellFeeDev2;
        sellFeeDev3 = _sellFeeDev3;
        sellFeeInch = _sellFeeInch;
        sellFeeInchStretched = _sellFeeInchStretched;
        sellFee = _sellFeeLiquidity + _sellFeeDev1 + _sellFeeDev2 + _sellFeeDev3 + _sellFeeInch + _sellFeeInchStretched;
    }

    function changeLowerSellFees(uint256 _lowerSellFeeLiquidity, uint256 _lowerSellFeeDev1, uint256 _lowerSellFeeDev2, uint256 _lowerSellFeeDev3, uint256 _lowerSellFeeInch, uint256 _lowerSellFeeInchStretched) external onlyOwner {
        lowerSellFeeLiquidity = _lowerSellFeeLiquidity;
        lowerSellFeeDev1 = _lowerSellFeeDev1;
        lowerSellFeeDev2 = _lowerSellFeeDev2;
        lowerSellFeeDev3 = _lowerSellFeeDev3;
        lowerSellFeeInch = _lowerSellFeeInch;
        lowerSellFeeInchStretched = _lowerSellFeeInchStretched;
        lowerSellFee = _lowerSellFeeLiquidity + _lowerSellFeeDev1 + _lowerSellFeeDev2 + _lowerSellFeeDev3 + _lowerSellFeeInch + _lowerSellFeeInchStretched;
    }

    function changeWallets(address _walletLiquidity, address _walletDev1, address _walletDev2, address _walletDev3, address _walletInch, address _walletInchStretched) external onlyOwner {
        walletLiquidity = _walletLiquidity;
        walletDev1 = _walletDev1;
        walletDev2 = _walletDev2;
        walletDev3 = _walletDev3;
        walletInch = _walletInch;
        walletInchStretched = _walletInchStretched;
    }

    function enableTrading() external onlyOwner {
        tradingLive = true;
    }

    function changeSwapConfiguration(uint256 _swapTrigger, uint256 _swapThreshold) external onlyOwner {
        swapTrigger = _swapTrigger;
        swapThreshold = _swapThreshold;
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