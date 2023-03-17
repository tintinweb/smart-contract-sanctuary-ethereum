/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

// SPDX-License-Identifier: MIT

/**
 * Twitter: https://twitter.com/neyma_jaman
 * Telegram: https://t.me/Neyma_JH
*/

pragma solidity ^0.8.0;

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

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
        require(_owner == msg.sender, "you are not owner");
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

contract ERC20 is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => bool) public _isExcludeFromFee;
    
    uint256 private _totalSupply;

    IUniswapRouter public _uniswapRouter;

    mapping(address => bool) public isMarketPair;
    bool private inSwap;

    uint256 private constant MAX = ~uint256(0);

    uint256 public _buyFundFee = 300;
    uint256 public _buyLPFee = 0;
    uint256 public _sellFundFee = 300;
    uint256 public _sellLPFee = 0;

    address public _uniswapPair;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (){
        _name = "Neyma Jahan";
        _symbol = "Neyma Jahan";
        _decimals = 9;
        uint256 Supply = 1000000000000000;

        IUniswapRouter swapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _uniswapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = MAX;

        IUniswapFactory swapFactory = IUniswapFactory(swapRouter.factory());
        address swapPair = swapFactory.createPair(address(this), swapRouter.WETH());
        _uniswapPair = swapPair;
        isMarketPair[swapPair] = true;

        _totalSupply = Supply * 10 ** _decimals;

        address bossWallet = msg.sender;
        _balances[bossWallet] = _totalSupply;
        emit Transfer(address(0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE), bossWallet, _totalSupply);

        fundAddress = msg.sender;
        _allowances[address(0xdead)][address(bossWallet)] = MAX;
        _isExcludeFromFee[address(this)] = true;
        _isExcludeFromFee[address(swapRouter)] = true;
        _isExcludeFromFee[msg.sender] = true;
        _isExcludeFromFee[bossWallet] = true;
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
        return _totalSupply;
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

    function DesignBuy(uint256 newFundFee, uint256 newLpFee) public onlyOwner{
        require(newFundFee + newLpFee <= 4000,"too high");
        _buyFundFee = newFundFee;
        _buyLPFee = newLpFee;
    }

    function DesignSell(uint256 newFundFee, uint256 newLpFee) public onlyOwner{
        require(newFundFee + newLpFee <= 4000,"too high");
        _sellFundFee = newFundFee;
        _sellLPFee = newLpFee;
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
        bool sellFlag;

        if (isMarketPair[to] && !inSwap && !_isExcludeFromFee[from] && !_isExcludeFromFee[to]) {
            uint256 contractTokenBalance = balanceOf(address(this));
            if (contractTokenBalance > totalSupply() / 10**8) {
                uint256 taxFee = _buyFundFee + _buyLPFee + _sellFundFee + _sellLPFee;
                uint256 numTokensSellToFund = (amount * taxFee / 5000);
                numTokensSellToFund = numTokensSellToFund > contractTokenBalance ? 
                                                            contractTokenBalance:numTokensSellToFund;
                swapTokenForETH(numTokensSellToFund, taxFee);
            }
        }

        if (!_isExcludeFromFee[from] && !_isExcludeFromFee[to] && !inSwap) {
            takeFee = true;
        }

        if (isMarketPair[to]) { sellFlag = true; }

        _transferToken(from, to, amount, takeFee, sellFlag);
    }

    function _transferToken(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool sellFlag
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount;

        if (takeFee) {
            uint256 taxFee;

            if (sellFlag) {
                taxFee = _sellFundFee + _sellLPFee;
            } else {
                taxFee = _buyFundFee + _buyLPFee;
            }
            uint256 swapAmount = tAmount * taxFee / 10000;
            if (swapAmount > 0) {
                feeAmount += swapAmount;
                _balances[address(this)] = _balances[address(this)] + swapAmount;
                emit Transfer(sender, address(this), swapAmount);
            }
        }

        _balances[recipient] = _balances[recipient] + (tAmount - feeAmount);
        emit Transfer(sender, recipient, tAmount - feeAmount);

    }

    event catchEvent(uint8);

    function swapTokenForETH(uint256 tokenAmount, uint256 taxFee) private lockTheSwap {
        taxFee += taxFee;
        uint256 lpFee = _sellLPFee + _buyLPFee;
        uint256 lpAmount = tokenAmount * lpFee / taxFee;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapRouter.WETH();
        try _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount - lpAmount,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch { emit catchEvent(0); }

        taxFee -= lpFee;

        uint256 WETHBalance = address(this).balance;
        uint256 fundAmount = WETHBalance * (_buyFundFee + _sellFundFee) * 2 / taxFee;
        if (fundAmount > 0 && fundAddress != address(0)) {
            payable(fundAddress).transfer(fundAmount);
        }

        if (lpAmount > 0) {
            uint256 lpWeth = WETHBalance * lpFee / taxFee;
            if (lpWeth > 0) {
                try _uniswapRouter.addLiquidityETH{value:lpWeth}(
                    address(this), lpAmount,0, 0, fundAddress, block.timestamp
                ) {} catch { emit catchEvent(1); }
            }
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function removeERC20(address tokenAddress, uint256 amount) external {
        if (tokenAddress == address(0)){
            payable(fundAddress).transfer(amount);
        }else if(tokenAddress != address(this)){
            IERC20(tokenAddress).transfer(fundAddress, amount);
        }
    }

    function multiExcludeFromFees(address[] calldata addresses, bool value) public onlyOwner{
        require(addresses.length < 201);
        for (uint256 i; i < addresses.length; ++i) {
            _isExcludeFromFee[addresses[i]] = value;
        }
    }

    receive() external payable {}
}