/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT

/**

ShibaMaster

Web: https://www.shibamaster.xyz/
Twitter: https://twitter.com/ShibaMasterETH

Tokenomics

5% Buy
5% Sell

1% LP
2% ShibMaster Burn
2% External Burn
Refer to website / litepaper for detailed tokenomics on burn

*/

pragma solidity ^0.8.13;

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external payable;
}

contract ShibaMaster is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
   
    string private constant _name = "ShibaMaster";
    string private constant _symbol = "ShibaM ";
    uint8 private constant _decimals = 9;
    uint256 private _tTotal = 1000000000000 * 10**_decimals;

    uint256 public _maxWalletAmount = 10000000000 * 10**_decimals;
    uint256 public _maxTxAmount = 10000000000 * 10**_decimals;
    uint256 public swapTokenAtAmount = 1250000000 * 10**_decimals;

    address public liquidityReceiver;

    uint256 public totalTokenBurned;
    mapping (address => uint256) private _erc20TokenBurned;

    struct BuyFees{
        uint256 liquidity;
        uint256 selfBurn;
        uint256 externalBurn;
    }

    struct SellFees{
        uint256 liquidity;
        uint256 selfBurn;
        uint256 externalBurn;
    }

    BuyFees public buyFee;
    SellFees public sellFee;

    uint256 private liquidityFee;
    uint256 private selfBurnFee;
    uint256 private externalBurnFee;
    
    bool private swapping;

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
        
    constructor () {
        balances[_msgSender()] = _tTotal;
        
        buyFee.liquidity = 4;
        buyFee.selfBurn = 2;
        buyFee.externalBurn = 2;

        sellFee.liquidity = 4;
        sellFee.selfBurn = 2;
        sellFee.externalBurn = 2;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        
        liquidityReceiver = msg.sender;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    receive() external payable {}
    
    function ERC20TokenBurned(address tokenAddress) public view returns (uint256) {
        return _erc20TokenBurned[tokenAddress];
    }

    function takeBuyFees(uint256 amount, address from) private returns (uint256) {
        uint256 liquidityFeeToken = amount * buyFee.liquidity / 100; 
        uint256 selfBurnFeeToken = amount * buyFee.selfBurn / 100; 
        uint256 externalBurnFeeToken = amount * buyFee.externalBurn / 100; 

        balances[address(this)] += liquidityFeeToken + externalBurnFeeToken;
        balances[address(0x00)] += selfBurnFeeToken;
        _tTotal -= selfBurnFeeToken;
        totalTokenBurned += selfBurnFeeToken;

        emit Transfer (from, address(0x000), selfBurnFeeToken);
        emit Transfer (from, address(this), externalBurnFeeToken + liquidityFeeToken);

        return (amount -liquidityFeeToken -selfBurnFeeToken -externalBurnFeeToken);
    }

    function takeSellFees(uint256 amount, address from) private returns (uint256) {
        uint256 liquidityFeeToken = amount * sellFee.liquidity / 100; 
        uint256 selfBurnFeeToken = amount * sellFee.selfBurn / 100; 
        uint256 externalBurnFeeToken = amount * sellFee.externalBurn / 100; 

        balances[address(this)] += liquidityFeeToken + externalBurnFeeToken;
        balances[address(0x00)] += selfBurnFeeToken;
        _tTotal -= selfBurnFeeToken;
        totalTokenBurned += selfBurnFeeToken;

        emit Transfer (from, address(0x000), selfBurnFeeToken);
        emit Transfer (from, address(this), externalBurnFeeToken + liquidityFeeToken);

        return (amount -liquidityFeeToken -selfBurnFeeToken -externalBurnFeeToken);
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setBuyFees(uint256 newLiquidityFee, uint256 newSelfBurnFee, uint256 newExternalBurnFee) public onlyOwner {
        require(newLiquidityFee + newSelfBurnFee + newExternalBurnFee <= 25, "Can't set buyFee above 25%");
        buyFee.liquidity = newLiquidityFee;
        buyFee.selfBurn = newSelfBurnFee;
        buyFee.externalBurn= newExternalBurnFee;
    }

    function setSellFees(uint256 newLiquidityFee, uint256 newSelfBurnFee, uint256 newExternalBurnFee) public onlyOwner {
        require(newLiquidityFee + newSelfBurnFee + newExternalBurnFee <= 25, "Can't set sellFee above 25%");
        sellFee.liquidity = newLiquidityFee;
        sellFee.selfBurn = newSelfBurnFee;
        sellFee.externalBurn= newExternalBurnFee;
    }

    function setMaxTxPercent(uint256 newMaxTxPercent) public onlyOwner {
        require(newMaxTxPercent >= 1, "MaxTx atleast 1% or higher");
        _maxTxAmount = _tTotal.mul(newMaxTxPercent).div(10**2);
    }

    function setMaxWalletPercent(uint256 newMaxWalletPercent) public onlyOwner {
        require(newMaxWalletPercent >= 1, "MaxWallet atleast 1% or higher");
        _maxWalletAmount = _tTotal.mul(newMaxWalletPercent).div(10**2);    
    }

    function setSwapTokenAtAmountPermille(uint256 newSwapTokenAmountPermille) public onlyOwner {
        swapTokenAtAmount = _tTotal.mul(newSwapTokenAmountPermille).div(10**3);
    }

    function buyAndBurnERC20Token(address tokenAddress, uint256 ethAmount) public onlyOwner {
	swapETHForExternalTokens(tokenAddress, ethAmount);
    }

    function setLiquidityReceiver(address newLiqReceiver) public onlyOwner {
        liquidityReceiver = newLiqReceiver;
        _isExcludedFromFee[newLiqReceiver] = true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        balances[from] -= amount;
        uint256 transferAmount = amount;
        
        bool takeFee;

        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            takeFee = true;
        } 

        if(takeFee){
            if(to != uniswapV2Pair){
                require(amount <= _maxTxAmount, "Transfer Amount exceeds the maxTxAmount");
                require(balanceOf(to) + amount <= _maxWalletAmount, "Transfer amount exceeds the maxWalletAmount.");
                 transferAmount = takeBuyFees(amount, from);
            }

            if(from != uniswapV2Pair){
                require(amount <= _maxTxAmount, "Transfer Amount exceeds the maxTxAmount");
                transferAmount = takeSellFees(amount, from);

               if (balanceOf(address(this)) >= swapTokenAtAmount && !swapping) {
                    swapping = true;
                    swapBack();
                    swapping = false;
              }
            }

            if(to != uniswapV2Pair && from != uniswapV2Pair){
                require(amount <= _maxTxAmount, "Transfer Amount exceeds the maxTxAmount");
                require(balanceOf(to) + amount <= _maxWalletAmount, "Transfer amount exceeds the maxWalletAmount.");
            }
        }
        
        balances[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
    }
    
    
    function swapBack() private {
        uint256 contractBalance = swapTokenAtAmount;
        uint256 liquidityTokens = contractBalance * (buyFee.liquidity + sellFee.liquidity) / (buyFee.externalBurn + buyFee.liquidity + sellFee.externalBurn + sellFee.liquidity);
        uint256 externalBurnTokens = contractBalance - liquidityTokens;
        uint256 totalTokensToSwap = liquidityTokens + externalBurnTokens;
        
        uint256 tokensForLiquidity = liquidityTokens.div(2);
        uint256 amountToSwapForETH = contractBalance.sub(tokensForLiquidity);
        
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(amountToSwapForETH); 
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        
        uint256 ethForLiquidity = ethBalance.mul(liquidityTokens).div(totalTokensToSwap);

        addLiquidity(tokensForLiquidity, ethForLiquidity);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapETHForExternalTokens(address tokenToBuy, uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = tokenToBuy;
        
        IERC20(uniswapV2Router.WETH()).approve(address(uniswapV2Router), amount);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 tokenReceived = IERC20(tokenToBuy).balanceOf(address(this));
        _erc20TokenBurned[tokenToBuy] += tokenReceived;
        IERC20(tokenToBuy).transfer(address(0xdead), tokenReceived);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH {value: ethAmount} (
            address(this),
            tokenAmount,
            0,
            0,
            liquidityReceiver,
            block.timestamp
        );
    }
}