/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IDexFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

contract WingsToken is Context, IERC20, Ownable {
    
    string constant private _name = "Super wings";
    string constant private _symbol = "$Wings";
    uint8 constant private _decimals = 18;

    address public constant  deadAddress = 0x000000000000000000000000000000000000dEaD;
    address payable public autoLiquidityReceiver = payable(0x65C0853A49325d8BA537402A3183d6AFc3DD1210); // LP Address
    address payable public marketingFeeReceiver = payable(0x159e563e5fB5d80dA04a02FA562851A198916b2D); // Marketing Address
    address payable public buybackFeeReceiver = payable(0x6f2d3987C1053dFae6a27251038938e1Ec661270); // Buyback Address
    
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;
    
    mapping (address => bool) public isBot;
    mapping (address => bool) public isMarketPair;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isWalletLimitExempt;

    bool public txLimitsEnabled = true;

    uint256 public buyTax = 200;
    uint256 public sellTax = 450;
    uint256 public transferTax = 40;

    uint256 public lpShare = 20;
    uint256 public marketingShare = 40;
    uint256 public buybackShare = 20;

    uint256 constant private _totalSupply = 77 * 10**6 * 10**_decimals;
    uint256 public swapThreshold = 1000 * 10**_decimals; 

    uint256 public maxTx = 0;
    uint256 public walletMax = 2310000 * 10**_decimals;

    IDexRouter public dexRouter;
    address public lpPair;
    
    bool private isInSwap;
    bool public swapEnabled = true;
    bool public swapByLimitOnly = false;
    bool public checkWalletLimit = true;

    event BotStatusUpdated(address account, bool isBot_);
    event SwapTokensForETH(uint256 amountIn, address[] path);
    event MaxTxAmountChanged(uint256 maxTx_);
    event MarketPairUpdated(address account, bool isMarketPair_);
    event TaxesChanged(uint256 buyTax_, uint256 sellTax_, uint256 transferTax_);
    event SwapSettingsUpdated(bool swapEnabled_, uint256 swapThreshold_, bool swapByLimitOnly_);
    event AccountWhitelisted(address account, bool feeExempt, bool walletLimitExempt, bool txLimitExempt);
    event TaxDistributionChanged(uint256 buybackShare_, uint256 lpShare_, uint256 marketingShare_);

    modifier lockTheSwap {
        isInSwap = true;
        _;
        isInSwap = false;
    }
    
    constructor () {
        
        dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        lpPair = IDexFactory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;

        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[address(this)] = true;

        isWalletLimitExempt[owner()] = true;
        isWalletLimitExempt[address(lpPair)] = true;
        isWalletLimitExempt[address(this)] = true;
        
        isMarketPair[address(lpPair)] = true;

        allowances[address(this)][address(dexRouter)] = _totalSupply;
        balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

     //to receive ETH from dexRouter when swapping
    receive() external payable {}

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }
    
    function circulatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(deadAddress);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function allowance(address owner_, address spender) public view override returns (uint256) {
        return allowances[owner_][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner_, address spender, uint256 amount) private {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowances[sender][_msgSender()] - amount);
        return true;
    }

    function changeBotStatus(address account, bool isBot_) public onlyOwner {
        isBot[account] = isBot_;
        emit BotStatusUpdated(account, isBot_);
    }

    function changeMarketPairStatus(address account, bool isMarketPair_) public onlyOwner {
        isMarketPair[account] = isMarketPair_;
        emit MarketPairUpdated(account, isMarketPair_);
    }
    
    function setTaxes(uint256 buyTax_, uint256 sellTax_, uint256 transferTax_) external onlyOwner {
        buyTax = buyTax_;
        sellTax = sellTax_;
        transferTax = transferTax_;
        emit TaxesChanged(buyTax_, sellTax_, transferTax_);
    }

    function changeTaxDistribution(uint256 buybackShare_, uint256 lpShare_, uint256 marketingShare_) external onlyOwner {
        buybackShare = buybackShare_;
        lpShare = lpShare_;
        marketingShare = marketingShare_;
        emit TaxDistributionChanged(buybackShare_, lpShare_, marketingShare_);
    }

    function changeTxLimits(uint256 maxTx_, bool txLimitsEnabled_) external onlyOwner {
        maxTx = maxTx_;
        txLimitsEnabled = txLimitsEnabled_;
        emit MaxTxAmountChanged(maxTx_);
    }

    function changeWalletLimits(bool checkWalletLimit_, uint256 walletMax_) external onlyOwner {
        checkWalletLimit = checkWalletLimit_;
        walletMax  = walletMax_;
    }

    function whitelistAccounts(address[] memory wallets, bool feeExempt, bool walletLimitExempt, bool txLimitExempt) public onlyOwner {
        for(uint256 i = 0; i < wallets.length; i++){
            isExcludedFromFee[wallets[i]] = feeExempt;
            isWalletLimitExempt[wallets[i]] = walletLimitExempt;
            isTxLimitExempt[wallets[i]] = txLimitExempt;
            emit AccountWhitelisted(wallets[i], feeExempt, walletLimitExempt, txLimitExempt);
        }
    }

    function changeSwapSettings(bool swapEnabled_, uint256 swapThreshold_, bool swapByLimitOnly_) public onlyOwner {
        swapEnabled = swapEnabled_;
        swapThreshold = swapThreshold_;
        swapByLimitOnly = swapByLimitOnly_;
        emit SwapSettingsUpdated(swapEnabled_, swapThreshold_, swapByLimitOnly_);
    }

    function changeMarketingFeeReceiver(address marketingFeeReceiver_) external onlyOwner {
        require(marketingFeeReceiver_ != address(0), "New address cannot be zero address");
        marketingFeeReceiver = payable(marketingFeeReceiver_);
    }

    function changeBuybackFeeReceiver(address buybackFeeReceiver_) external onlyOwner {
        require(buybackFeeReceiver_ != address(0), "New address cannot be zero address");
        buybackFeeReceiver = payable(buybackFeeReceiver_);
    }

    function changeAutoLiquidityReceiver(address autoLiquidityReceiver_) external onlyOwner {
        require(autoLiquidityReceiver_ != address(0), "New address cannot be zero address");
        autoLiquidityReceiver = payable(autoLiquidityReceiver_);
    }

    function transferETH(address payable recipient, uint256 amount) private {
        bool success;
        (success,) = address(recipient).call{value: amount}("");
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        if(isInSwap) { 
            return _basicTransfer(sender, recipient, amount); 
        } else {
            require(sender != address(0), "ERC20: transfer from the zero address");
            require(recipient != address(0), "ERC20: transfer to the zero address");
            require(!isBot[sender] && !isBot[recipient], "To/from address is blacklisted!");

            if(txLimitsEnabled && !isTxLimitExempt[sender] && !isTxLimitExempt[recipient]) {
                require(amount <= maxTx, "Transfer amount exceeds the max transaction limit.");
            }

            bool isTaxFree = (isExcludedFromFee[sender] || isExcludedFromFee[recipient]);

            if (!isTaxFree && !isMarketPair[sender] && swapEnabled) 
            {
                uint256 contractTokenBalance = balanceOf(address(this));
                bool overMinimumTokenBalance = contractTokenBalance >= swapThreshold;
                if(overMinimumTokenBalance) {
                    if(swapByLimitOnly)
                        contractTokenBalance = swapThreshold;
                    swapAndLiquify(contractTokenBalance);    
                }
            }

            balances[sender] = balances[sender] - amount;

            uint256 finalAmount = isTaxFree ? amount : takeFee(sender, recipient, amount);

            if(checkWalletLimit && !isWalletLimitExempt[recipient]) {
                require((balanceOf(recipient) + finalAmount) <= walletMax);
            }

            balances[recipient] = balances[recipient] + finalAmount;

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        balances[sender] = balances[sender] - amount;
        balances[recipient] = balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
        uint256 totalShares = buybackShare + lpShare + marketingShare;
        uint256 tokensForLP = ((tAmount * lpShare) / totalShares) / 2;
        uint256 tokensForSwap = tAmount - tokensForLP;

        swapTokensForEth(tokensForSwap);
        
        uint256 amountReceived = address(this).balance;

        uint256 ethShares = totalShares - (lpShare / 2);
        
        uint256 ethForLiquidity = ((amountReceived * lpShare) / ethShares) / 2;
        uint256 ethForBuyback = (amountReceived * buybackShare) / ethShares;
        uint256 ethForMarketing = amountReceived - ethForLiquidity - ethForBuyback;

        if(ethForMarketing > 0) {
            transferETH(marketingFeeReceiver, ethForMarketing);
        }

        if(ethForBuyback > 0) {
            transferETH(buybackFeeReceiver, ethForBuyback);
        }

        if(ethForLiquidity > 0 && tokensForLP > 0) {
            addLiquidity(tokensForLP, ethForLiquidity);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(dexRouter), tokenAmount);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            autoLiquidityReceiver,
            block.timestamp
        );
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {

        uint256 feeAmount = (amount * transferTax) / 1000;   

        if(isMarketPair[recipient]) {
            feeAmount = (amount * sellTax) / 1000; 
        } else if(isMarketPair[sender]) {
            feeAmount = (amount * buyTax) / 1000; 
        }
        
        if(feeAmount > 0) {
            balances[address(this)] = balances[address(this)] + feeAmount;
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount - feeAmount;
    }
    
}