/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

/**

Socials: 

Telegram: https://t.me/AIGamblesJingTao

Website: https://Jingtaogambles.ai

Twitter: https://twitter.com/AIGamblesJingTao

*/

// SPDX-License-Identifier: NONE
pragma solidity 0.8.9;
 


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns(address pair);
}

interface IERC20 {

    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns(bool);

        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }

}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

        mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
 
    uint256 private _totalSupply;
 
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns(string memory) {
        return _name;
    }

    function symbol() public view virtual override returns(string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns(uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns(uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns(uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased cannot be below zero"));
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
 
library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

   
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    
        if (a == 0) {
            return 0;
        }
 
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

 
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

  
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    
}
 
contract Ownable is Context {
    address private _owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns(address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
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
 
 
 
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns(int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns(int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns(int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns(int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns(int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns(uint256) {
        require(a >= 0);
        return uint256(a);
    }
}
 
library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns(int256) {
    int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}


interface IUniswapV2Router01 {
    function factory() external pure returns(address);
    function WETH() external pure returns(address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns(uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns(uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns(uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns(uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns(uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns(uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns(uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns(uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns(uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns(uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
 
contract ArtificiallyIntelligentChineseGentlemanGamblerJingTao is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable router;
    address public immutable uniswapV2Pair;
    address private devWallet;
    address private marketingWallet;
    uint256 private maxBuyAmount;
    uint256 private maxSellAmount;   
    uint256 private maxWalletAmount;
    uint256 private thresholdSwapAmount;
    bool private isTrading = false;
    bool public swapEnabled = false;
    bool public isSwapping;
    struct Fees {
        uint256 buyTotalFees;
        uint256 buyMarketingFee;
        uint256 buyDevFee;
        uint256 buyLiquidityFee;

        uint256 sellTotalFees;
        uint256 sellMarketingFee;
        uint256 sellDevFee;
        uint256 sellLiquidityFee;
    }  
    Fees public _fees = Fees({
        buyTotalFees: 0,
        buyMarketingFee: 0,
        buyDevFee:0,
        buyLiquidityFee: 0,

        sellTotalFees: 0,
        sellMarketingFee: 0,
        sellDevFee:0,
        sellLiquidityFee: 0
    });
    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;
    uint256 public tokensForDev;
    uint256 private taxTill;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public _isExcludedMaxWalletAmount;
    mapping(address => bool) public marketPair;
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived
    );


    constructor() ERC20("ArtificiallyIntelligentChineseGentlemanGamblerJingTao", "GAMBLE") {
 
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        _isExcludedMaxTransactionAmount[address(router)] = true;
        _isExcludedMaxTransactionAmount[address(uniswapV2Pair)] = true;        
        _isExcludedMaxTransactionAmount[owner()] = true;
        _isExcludedMaxTransactionAmount[address(this)] = true;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedMaxWalletAmount[owner()] = true;
        _isExcludedMaxWalletAmount[address(this)] = true;
        _isExcludedMaxWalletAmount[address(uniswapV2Pair)] = true;
        marketPair[address(uniswapV2Pair)] = true;

        approve(address(router), type(uint256).max);
        uint256 totalSupply = 1e7 * 1e18;

        maxBuyAmount = totalSupply * 35 / 1000; 
        maxSellAmount = totalSupply * 35 / 1000; 
        maxWalletAmount = totalSupply * 35 / 1000; 
        thresholdSwapAmount = totalSupply * 1 / 10000; // 0.01% swap wallet

        _fees.buyMarketingFee = 0;
        _fees.buyLiquidityFee = 0;
        _fees.buyDevFee = 0;
        _fees.buyTotalFees = _fees.buyMarketingFee + _fees.buyLiquidityFee + _fees.buyDevFee;

        _fees.sellMarketingFee = 0;
        _fees.sellLiquidityFee = 0;
        _fees.sellDevFee = 0;
        _fees.sellTotalFees = _fees.sellMarketingFee + _fees.sellLiquidityFee + _fees.sellDevFee;


        marketingWallet = address(0xFac1ef1304e6e01Efd92EC2B55a0cAc779282311);
        devWallet = address(0xFac1ef1304e6e01Efd92EC2B55a0cAc779282311);
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {

    }

    // once enabled, can never be turned off
    function openTrading() external onlyOwner {
        isTrading = true;
        swapEnabled = true;
        taxTill = block.number + 0;
    }

    function updateThresholdSwapAmount(uint256 newAmount) external onlyOwner returns(bool){
        thresholdSwapAmount = newAmount;
        return true;
    }

    function updateMaxTxn(uint256 newMaxBuy, uint256 newMaxSell) external onlyOwner {
        require(((totalSupply() * newMaxBuy) / 100) >= (totalSupply() / 100), "Cannot set maxTransactionAmounts lower than 1%");
        require(((totalSupply() * newMaxSell) / 100) >= (totalSupply() / 100), "Cannot set maxTransactionAmounts lower than 1%");
        maxBuyAmount = (totalSupply() * newMaxBuy) / 100;
        maxSellAmount = (totalSupply() * newMaxSell) / 100;
    }


    function updateMaxWallet(uint256 newPercentage) external onlyOwner {
        require(((totalSupply() * newPercentage) / 100) >= (totalSupply() / 100), "Cannot set maxWallet lower than 1%");
        maxWalletAmount = (totalSupply() * newPercentage) / 100;
    }

    function toggleSwapEnabled(bool enabled) external onlyOwner(){
        swapEnabled = enabled;
    }

    function changeFees(uint256 _marketingFeeBuy, uint256 _liquidityFeeBuy,uint256 _devFeeBuy,uint256 _marketingFeeSell, uint256 _liquidityFeeSell,uint256 _devFeeSell) external onlyOwner{
        _fees.buyMarketingFee = _marketingFeeBuy;
        _fees.buyLiquidityFee = _liquidityFeeBuy;
        _fees.buyDevFee = _devFeeBuy;
        _fees.buyTotalFees = _fees.buyMarketingFee + _fees.buyLiquidityFee + _fees.buyDevFee;

        _fees.sellMarketingFee = _marketingFeeSell;
        _fees.sellLiquidityFee = _liquidityFeeSell;
        _fees.sellDevFee = _devFeeSell;
        _fees.sellTotalFees = _fees.sellMarketingFee + _fees.sellLiquidityFee + _fees.sellDevFee;
    
    }
    
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        
        if (amount == 0) {
            super._transfer(sender, recipient, 0);
            return;
        }

        if (
            sender != owner() &&
            recipient != owner() &&
            !isSwapping
        ) {

            if (!isTrading) {
                require(_isExcludedFromFees[sender] || _isExcludedFromFees[recipient], "Trading is not active.");
            }
            if (marketPair[sender] && !_isExcludedMaxTransactionAmount[recipient]) {
                require(amount <= maxBuyAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
            } 
            else if (marketPair[recipient] && !_isExcludedMaxTransactionAmount[sender]) {
                require(amount <= maxSellAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
            }

            if (!_isExcludedMaxWalletAmount[recipient]) {
                require(amount + balanceOf(recipient) <= maxWalletAmount, "Max wallet exceeded");
            }

        }

        uint256 contractTokenBalance = balanceOf(address(this));
 
        bool canSwap = contractTokenBalance >= thresholdSwapAmount;

        if (
            canSwap &&
            swapEnabled &&
            !isSwapping &&
            marketPair[recipient] &&
            !_isExcludedFromFees[sender] &&
            !_isExcludedFromFees[recipient]
        ) {
            isSwapping = true;
            swapBack();
            isSwapping = false;
        }
 
        bool takeFee = !isSwapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            takeFee = false;
        }
 
        
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            uint256 fees = 0;
            if(block.number < taxTill) {
                fees = amount.mul(99).div(100);
                tokensForMarketing += (fees * 94) / 99;
                tokensForDev += (fees * 5) / 99;
            } else if (marketPair[recipient] && _fees.sellTotalFees > 0) {
                fees = amount.mul(_fees.sellTotalFees).div(100);
                tokensForLiquidity += fees * _fees.sellLiquidityFee / _fees.sellTotalFees;
                tokensForMarketing += fees * _fees.sellMarketingFee / _fees.sellTotalFees;
                tokensForDev += fees * _fees.sellDevFee / _fees.sellTotalFees;
            }
            // on buy
            else if (marketPair[sender] && _fees.buyTotalFees > 0) {
                fees = amount.mul(_fees.buyTotalFees).div(100);
                tokensForLiquidity += fees * _fees.buyLiquidityFee / _fees.buyTotalFees;
                tokensForMarketing += fees * _fees.buyMarketingFee / _fees.buyTotalFees;
                tokensForDev += fees * _fees.buyDevFee / _fees.buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(sender, address(this), fees);
            }

            amount -= fees;

        }

        super._transfer(sender, recipient, amount);
    }

    function swapTokensForEth(uint256 tAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }

    function addLiquidity(uint256 tAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tAmount);

        // add the liquidity
        router.addLiquidityETH{ value: ethAmount } (address(this), tAmount, 0, 0 , address(this), block.timestamp);
    }

    function swapBack() private {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 toSwap = tokensForLiquidity + tokensForMarketing + tokensForDev;
        bool success;

        if (contractTokenBalance == 0 || toSwap == 0) { return; }

        if (contractTokenBalance > thresholdSwapAmount * 20) {
            contractTokenBalance = thresholdSwapAmount * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractTokenBalance * tokensForLiquidity / toSwap / 2;
        uint256 amountToSwapForETH = contractTokenBalance.sub(liquidityTokens);
 
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH); 
 
        uint256 newBalance = address(this).balance.sub(initialETHBalance);
 
        uint256 ethForMarketing = newBalance.mul(tokensForMarketing).div(toSwap);
        uint256 ethForDev = newBalance.mul(tokensForDev).div(toSwap);
        uint256 ethForLiquidity = newBalance - (ethForMarketing + ethForDev);


        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForDev = 0;


        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity);
        }

        (success,) = address(devWallet).call{ value: (address(this).balance - ethForMarketing) } ("");
        (success,) = address(marketingWallet).call{ value: address(this).balance } ("");
    }

}