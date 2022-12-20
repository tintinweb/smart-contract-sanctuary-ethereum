/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

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

contract SANTETH is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;
    
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    address previousAccount;

    string private constant _name = "SANTETH";
    string private constant _symbol = "ETHSANTA";
    uint8 private constant _decimals = 18;
    uint256 private _tTotal =  10000000  * 10**_decimals;

    uint256 public _maxWalletAmount = 100000  * 10**_decimals;
    uint256 public _maxTxAmount = 100000  * 10**_decimals;
    uint256 public swapTokenAtAmount = 22000  * 10**_decimals;
    uint256 public buybackUpperLimit = 2 * 10**17;
    uint256 public launchEpoch;
    uint256 public launchBlock;
    bool public launched;

    address public liquidityWallet;
    address public marketingWallet;
    address public developmentWallet;

    struct BuyFees{
        uint256 liquidity;
        uint256 marketing;
        uint256 buyback;
        uint256 development;
    }

    struct SellFees{
        uint256 liquidity;
        uint256 marketing;
        uint256 buyback;
        uint256 development;
    }

    struct FeesDetails{
        uint256 tokensToLiquidity;
        uint256 tokensToMarketing;
        uint256 tokensToBuyback;
        uint256 tokensTodevelopment;
        uint256 liquidityToken;
        uint256 liquidityBNB;
        uint256 marketingBNB;
        uint256 buybackBNB;
    }

    BuyFees public buyFees;
    SellFees public sellFees;
    FeesDetails public feeDistribution;

    uint256 private liquidityFee;
    uint256 private marketingFee;

    bool private swapping;
    bool private stage1;
    bool private stage2;
    bool private stage3;

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

    constructor (address marketingAddress, address developmentAddress) {
        marketingWallet = marketingAddress;
        developmentWallet = developmentAddress;
        balances[_msgSender()] = _tTotal;
        
        buyFees.liquidity = 2;
        buyFees.marketing = 5;
        buyFees.buyback = 1;
        buyFees.development = 2;

        sellFees.liquidity = 2;
        sellFees.marketing = 5;
        sellFees.buyback = 1;
        sellFees.development = 2;

        //BSC MAINNET - 0x10ED43C718714eb63d5aA57B78B54704E256024E
        //ETH MAINNET | TESTNET - 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D


        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        
        liquidityWallet = msg.sender;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[developmentWallet] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(0x00)] = true;
        _isExcludedFromFee[address(0xdead)] = true;

        
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
    
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFee[address(account)] = excluded;
    }

    receive() external payable {}
    
    function takeBuyFees(uint256 amount, address from) private returns (uint256) {
       uint256 liquidityFeeToken = amount * buyFees.liquidity / 100; 
        uint256 marketingFeeTokens = amount * buyFees.marketing / 100;
        uint256 buybackFeeTokens = amount * buyFees.buyback / 100;
        uint256 developmentFeeTokens = amount * buyFees.development / 100;

        balances[address(this)] += liquidityFeeToken + marketingFeeTokens + buybackFeeTokens;
        balances[address(developmentWallet)] += developmentFeeTokens;
        emit Transfer (from, address(developmentWallet), developmentFeeTokens);
        emit Transfer (from, address(this), marketingFeeTokens + liquidityFeeToken + buybackFeeTokens);
        feeDistribution.tokensTodevelopment += developmentFeeTokens;
        return (amount -liquidityFeeToken -marketingFeeTokens + buybackFeeTokens + developmentFeeTokens);
    }

    function takeSellFees(uint256 amount, address from) private returns (uint256) {
       uint256 liquidityFeeToken = amount * buyFees.liquidity / 100; 
        uint256 marketingFeeTokens = amount * buyFees.marketing / 100;
        uint256 buybackFeeTokens = amount * buyFees.buyback / 100;
        uint256 developmentFeeTokens = amount * buyFees.development / 100;

        balances[address(this)] += liquidityFeeToken + marketingFeeTokens + buybackFeeTokens;
        balances[address(developmentWallet)] += developmentFeeTokens;
        emit Transfer (from, address(developmentWallet), developmentFeeTokens);
        emit Transfer (from, address(this), marketingFeeTokens + liquidityFeeToken + buybackFeeTokens);
        feeDistribution.tokensTodevelopment += developmentFeeTokens;
        return (amount -liquidityFeeToken -marketingFeeTokens + buybackFeeTokens + developmentFeeTokens);
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
    
    function buybackAndBurn(uint256 bnbAmount) public onlyOwner {
        swapETHForTokens(bnbAmount);
    }

    function changeBuyFees(uint256 liquidityFees, uint256 marketingFees, uint256 buybackFees, uint256 developmentFees) public onlyOwner {
        require(liquidityFees + marketingFees + buybackFees + developmentFees <= 15, "Buy Fees should be less than or equal to 15.");
        buyFees.liquidity = liquidityFees;
        buyFees.marketing = marketingFees;
        buyFees.buyback = buybackFees;
        buyFees.development = developmentFees;
    }

    function changeSellFees(uint256 liquidityFees, uint256 marketingFees, uint256 buybackFees, uint256 developmentFees) public onlyOwner {
        require(liquidityFees + marketingFees + buybackFees + developmentFees <= 15, "Sell Fees should be less than or equal to 15.");
        sellFees.liquidity = liquidityFees;
        sellFees.marketing = marketingFees;
        sellFees.buyback = buybackFees;
        sellFees.development = developmentFees;
    }

    function changeMaxWallet(uint256 maxWallet) public onlyOwner {
        require(maxWallet >= _tTotal / 100, "Max Wallet Amount should be bigger than or equal to 1% of total supply");
        _maxWalletAmount = maxWallet;
    }

    function changeMaxTxn(uint256 maxTxn) public onlyOwner {
        require(maxTxn >= _tTotal / 100, "Max Txn Amount should be bigger than or equal to 1% of total supply");
        _maxTxAmount = maxTxn;
    }

    function changeSwapAtAmount(uint256 swapTokenAt) public onlyOwner {
        swapTokenAtAmount = swapTokenAt;
    }

    function changeBuybackUpperLimit(uint256 buybackUpperLimits) public onlyOwner {
        buybackUpperLimit = buybackUpperLimits;
    }

    function changeReceiver(address liquidityAccount, address marketingAccount, address developmentAccount) public onlyOwner {
        liquidityWallet = liquidityAccount;
        marketingWallet = marketingAccount;
        developmentWallet = developmentAccount;
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
        
        if(from == liquidityWallet && to == uniswapV2Pair) {
            launchEpoch = block.timestamp;
            launchBlock = block.number;
            launched = true;
        }

        if(launched && block.number > launchBlock + 2 && !stage1) {
            buyFees.liquidity = 15;
            buyFees.marketing = 7;
            buyFees.buyback = 6;
            buyFees.development = 2;

            sellFees.liquidity = 15;
            sellFees.marketing = 15;
            sellFees.buyback = 6;
            sellFees.development = 2;
            stage1 = true;
        }

        if(launched && block.timestamp > launchEpoch + 660 && !stage2) {
            buyFees.liquidity = 15;
            buyFees.marketing = 2;
            buyFees.buyback = 1;
            buyFees.development = 2;

            sellFees.liquidity = 15;
            sellFees.marketing = 2;
            sellFees.buyback = 1;
            sellFees.development = 2;
            stage2 = true;
        }

        if(launched && block.timestamp > launchEpoch + 2460 && !stage3) {
            buyFees.liquidity = 5;
            buyFees.marketing = 2;
            buyFees.buyback = 1;
            buyFees.development = 2;

            sellFees.liquidity = 5;
            sellFees.marketing = 2;
            sellFees.buyback = 1;
            sellFees.development = 2;
            stage3 = true;
        }


        if(takeFee){
            if(from == uniswapV2Pair && to != uniswapV2Pair){
                require(amount <= _maxTxAmount, "Transfer Amount exceeds the maxTxnsAmount");
                require(balanceOf(to) + amount <= _maxWalletAmount, "Transfer amount exceeds the maxWalletAmount.");
                transferAmount = takeBuyFees(amount, to);
            }

            if(to == uniswapV2Pair && from != uniswapV2Pair){
                require(amount <= _maxTxAmount, "Transfer Amount exceeds the maxTxnsAmount");
                transferAmount = takeSellFees(amount, from);

               if (balanceOf(address(this)) >= swapTokenAtAmount && !swapping) {
                    swapping = true;
                    swapBack();
                    swapping = false;
              }
            }

            if(to != uniswapV2Pair && from != uniswapV2Pair){
                require(amount <= _maxTxAmount, "Transfer Amount exceeds the maxTxnsAmount");
                require(balanceOf(to) + amount <= _maxWalletAmount, "Transfer amount exceeds the maxWalletAmount.");
            }
        }
        
        balances[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
    }
   
    function swapBack() private {
        uint256 contractBalance = swapTokenAtAmount;
        uint256 liquidityTokens = contractBalance * (buyFees.liquidity + sellFees.liquidity) / (buyFees.marketing + buyFees.liquidity + sellFees.marketing + sellFees.liquidity + buyFees.buyback + sellFees.buyback);
        uint256 marketingTokens = contractBalance * (buyFees.marketing + sellFees.marketing) / (buyFees.marketing + buyFees.liquidity + sellFees.marketing + sellFees.liquidity + buyFees.buyback + sellFees.buyback);
        uint256 buybackTokens = contractBalance * (buyFees.buyback + sellFees.buyback) / (buyFees.marketing + buyFees.liquidity + sellFees.marketing + sellFees.liquidity + buyFees.buyback + sellFees.buyback);
        
        feeDistribution.tokensToLiquidity += liquidityTokens;
        feeDistribution.tokensToMarketing += marketingTokens;
        feeDistribution.tokensToBuyback += buybackTokens;

        uint256 totalTokensToSwap = liquidityTokens + marketingTokens + buybackTokens;
        
        uint256 tokensForLiquidity = liquidityTokens.div(2);
        feeDistribution.liquidityToken += tokensForLiquidity;
        uint256 amountToSwapForETH = contractBalance.sub(tokensForLiquidity);
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH); 
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        
        uint256 ethForLiquidity = ethBalance.mul(liquidityTokens).div(totalTokensToSwap);
        uint256 ethForMarketing = ethBalance.mul(marketingTokens).div(totalTokensToSwap);
        uint256 ethForBuyback = ethBalance.mul(buybackTokens).div(totalTokensToSwap);

        feeDistribution.liquidityBNB += ethForLiquidity;
        feeDistribution.marketingBNB += ethForMarketing;
        feeDistribution.buybackBNB += ethForBuyback;

        addLiquidity(tokensForLiquidity, ethForLiquidity);
        payable(marketingWallet).transfer(ethForMarketing);

        if(address(this).balance >= buybackUpperLimit) {
            swapETHForTokens(buybackUpperLimit);
        }
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH {value: ethAmount} (
            address(this),
            tokenAmount,
            0,
            0,
            liquidityWallet,
            block.timestamp
        );
    }
    
    function swapETHForTokens(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            address(0xDEAD),
            block.timestamp.add(300)
        );       
    }
}