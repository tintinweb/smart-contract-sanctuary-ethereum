/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

/*
 * DRIPTO | $DRYP 
 * The 1st shop-to-earn token and crypto e-commerce platform
 * TG: https://t.me/driptotoken
 * Website: https://dripto.com
 * All Links: https://linktr.ee/dripto
 
#  ██████╗ ██████╗ ██╗██████╗ ████████╗ ██████╗ 
#  ██╔══██╗██╔══██╗██║██╔══██╗╚══██╔══╝██╔═══██╗
#  ██║  ██║██████╔╝██║██████╔╝   ██║   ██║   ██║
#  ██║  ██║██╔══██╗██║██╔═══╝    ██║   ██║   ██║
#  ██████╔╝██║  ██║██║██║        ██║   ╚██████╔╝
#  ╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝        ╚═╝    ╚═════╝                                                                                           
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

contract Dripto is Context, IERC20, Ownable {
    
    string constant private _name = "Dripto";
    string constant private _symbol = "DRYP";
    uint8 constant private _decimals = 18;

    address public constant  deadAddress = 0x000000000000000000000000000000000000dEaD;
    address payable public autoLiquidityReceiver = payable(0x7576E8a7ff15977b6c36aa869Fdf04D8Fb71E98f); // LP Address
    address payable public marketingWalletAddress = payable(0xeEBE80A2d80d4e54500c5AE081BD052E0ff9E6D7); // Marketing Address
    address payable public operationsWalletAddress = payable(0x5b7f00DF069Cb67189B57ff44693AeE455738E0d); // operations Address
    
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;
    
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isMarketPair;
    mapping (address => bool) public isEarlyBuyer;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isWalletLimitExempt;

    uint256 public buyTax = 70;
    uint256 public sellTax = 90;

    uint256 public lpShare = 10;
    uint256 public marketingShare = 40;
    uint256 public operationsShare = 40;

    uint256 constant private _totalSupply = 150 * 10**6 * 10**_decimals;
    uint256 public swapThreshold = 10000 * 10**_decimals; 
    uint256 public maxTxAmount = 1 * 10**6 * 10**_decimals;
    uint256 public walletMax = 3 * 10**6 * 10**_decimals;

    IDexRouter public dexRouter;
    address public lpPair;
    
    bool private isInSwap;
    bool public swapEnabled = true;
    bool public swapByLimitOnly = false;
    bool public launched = false;
    bool public checkWalletLimit = true;
    bool public snipeBlockExpired = false;

    uint256 public launchBlock = 0;
    uint256 public snipeBlockAmount = 0;

    event SwapSettingsUpdated(bool swapEnabled_, uint256 swapThreshold_, bool swapByLimitOnly_);
    event SwapTokensForETH(uint256 amountIn, address[] path);
    event AccountWhitelisted(address account, bool feeExempt, bool walletLimitExempt, bool txLimitExempt);
    event RouterVersionChanged(address newRouterAddress);
    event TaxesChanged(uint256 newBuyTax, uint256 newSellTax);
    event TaxDistributionChanged(uint256 newLpShare, uint256 newMarketingShare, uint256 newOperationsShare);
    event MarketingWalletChanged(address marketingWalletAddress_);
    event OperationsWalletChanged(address operationsWalletAddress_);
    event AutoLiquidityReceiverChanged(address autoLiquidityReceiver_);
    event EarlyBuyerUpdated(address account, bool isEarlyBuyer_);
    event MarketPairUpdated(address account, bool isMarketPair_);
    event WalletLimitChanged(uint256 walletMax_);
    event MaxTxAmountChanged(uint256 maxTxAmount_);
    event MaxWalletCheckChanged(bool checkWalletLimit_);

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
        isExcludedFromFee[address(marketingWalletAddress)] = true;
        isExcludedFromFee[address(operationsWalletAddress)] = true;

        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(marketingWalletAddress)] = true;
        isTxLimitExempt[address(operationsWalletAddress)] = true;
        isTxLimitExempt[address(autoLiquidityReceiver)] = true;

        isWalletLimitExempt[owner()] = true;
        isWalletLimitExempt[address(lpPair)] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[address(marketingWalletAddress)] = true;
        isWalletLimitExempt[address(operationsWalletAddress)] = true;
        isWalletLimitExempt[address(autoLiquidityReceiver)] = true;
        
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
    
    function getCirculatingSupply() public view returns (uint256) {
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
    
    function updateRouter(address newRouterAddress) public onlyOwner returns(address newPairAddress) {
        IDexRouter dexRouter_ = IDexRouter(newRouterAddress); 
        newPairAddress = IDexFactory(dexRouter_.factory()).getPair(address(this), dexRouter_.WETH());

        if(newPairAddress == address(0)) { //Create If Doesnt exist
            newPairAddress = IDexFactory(dexRouter_.factory()).
                                createPair(address(this), dexRouter_.WETH());
        }

        lpPair = newPairAddress; //Set new pair address
        dexRouter = dexRouter_; //Set new router address

        isWalletLimitExempt[address(lpPair)] = true;
        isMarketPair[address(lpPair)] = true;
        emit RouterVersionChanged(newRouterAddress);
    }

    function launch(uint256 snipeBlockAmount_) public onlyOwner {
        launched = true;
        launchBlock = block.number;
        snipeBlockAmount = snipeBlockAmount_;
    }

    function setLaunchStatus(bool launched_) public onlyOwner {
        launched = launched_;
    }

    function setIsEarlyBuyer(address account, bool isEarlyBuyer_) public onlyOwner {
        isEarlyBuyer[account] = isEarlyBuyer_;
        emit EarlyBuyerUpdated(account, isEarlyBuyer_);
    }

    function setMarketPairStatus(address account, bool isMarketPair_) public onlyOwner {
        isMarketPair[account] = isMarketPair_;
        emit MarketPairUpdated(account, isMarketPair_);
    }
    
    function setTaxes(uint256 newBuyTax, uint256 newSellTax) external onlyOwner {
        require(newBuyTax <= 300, "Cannot exceed 30%");
        require(newSellTax <= 300, "Cannot exceed 30%");
        buyTax = newBuyTax;
        sellTax = newSellTax;
        emit TaxesChanged(newBuyTax, newSellTax);
    }

    function setTaxDistribution(uint256 newLpShare, uint256 newMarketingShare, uint256 newOperationsShare) external onlyOwner {
        lpShare = newLpShare;
        marketingShare = newMarketingShare;
        operationsShare = newOperationsShare;
        emit TaxDistributionChanged(newLpShare, newMarketingShare, newOperationsShare);
    }

    function setMaxTxAmount(uint256 maxTxAmount_) external onlyOwner {
        maxTxAmount = maxTxAmount_;
        emit MaxTxAmountChanged(maxTxAmount_);
    }

    function setWalletLimit(uint256 walletMax_) external onlyOwner {
        walletMax  = walletMax_;
        emit WalletLimitChanged(walletMax_);
    }

    function enableDisableWalletLimit(bool checkWalletLimit_) external onlyOwner {
        checkWalletLimit = checkWalletLimit_;
        emit MaxWalletCheckChanged(checkWalletLimit_);
    }

    function whitelistAccount(address account, bool feeExempt, bool walletLimitExempt, bool txLimitExempt) public onlyOwner {
        isExcludedFromFee[account] = feeExempt;
        isWalletLimitExempt[account] = walletLimitExempt;
        isTxLimitExempt[account] = txLimitExempt;
        emit AccountWhitelisted(account, feeExempt, walletLimitExempt, txLimitExempt);
    }

    function updateSwapSettings(bool swapEnabled_, uint256 swapThreshold_, bool swapByLimitOnly_) public onlyOwner {
        swapEnabled = swapEnabled_;
        swapThreshold = swapThreshold_;
        swapByLimitOnly = swapByLimitOnly_;
        emit SwapSettingsUpdated(swapEnabled_, swapThreshold_, swapByLimitOnly_);
    }

    function setMarketingWalletAddress(address marketingWalletAddress_) external onlyOwner {
        require(marketingWalletAddress_ != address(0), "New address cannot be zero address");
        marketingWalletAddress = payable(marketingWalletAddress_);
        emit MarketingWalletChanged(marketingWalletAddress_);
    }

    function setOperationsWalletAddress(address operationsWalletAddress_) external onlyOwner {
        require(operationsWalletAddress_ != address(0), "New address cannot be zero address");
        operationsWalletAddress = payable(operationsWalletAddress_);
        emit OperationsWalletChanged(operationsWalletAddress_);
    }

    function setAutoLiquidityReceiver(address autoLiquidityReceiver_) external onlyOwner {
        require(autoLiquidityReceiver_ != address(0), "New address cannot be zero address");
        autoLiquidityReceiver = payable(autoLiquidityReceiver_);
        emit AutoLiquidityReceiverChanged(autoLiquidityReceiver_);
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        bool success;
        (success,) = address(recipient).call{value: amount}("");
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        if(isInSwap) { 
            return _basicTransfer(sender, recipient, amount); 
        } else {
            require(sender != address(0), "ERC20: transfer from the zero address");
            require(recipient != address(0), "ERC20: transfer to the zero address");
            require(!isEarlyBuyer[sender] && !isEarlyBuyer[recipient], "To/from address is blacklisted!");

            if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient]) {
                require(launched, "Not Launched.");
                if(isMarketPair[sender] || isMarketPair[recipient]) {
                    require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
                }
                if(!snipeBlockExpired) {
                    checkIfBot(sender, recipient);
                }
            }

            bool isTaxFree = ((!isMarketPair[sender] && !isMarketPair[recipient]) || 
                                isExcludedFromFee[sender] || isExcludedFromFee[recipient]);

            if (!isTaxFree && !isMarketPair[sender] && swapEnabled && !isInSwap) 
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

            if(checkWalletLimit && !isWalletLimitExempt[recipient])
                require((balanceOf(recipient) + finalAmount) <= walletMax);

            balances[recipient] = balances[recipient] + finalAmount;

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }

    function checkIfBot(address sender, address recipient) private {
        if((block.number - launchBlock) > snipeBlockAmount) {
            snipeBlockExpired = true;
        } else if(sender != owner() && recipient != owner()) {
            if(!isMarketPair[sender] && sender != address(this)) {
                isEarlyBuyer[sender] = true;
            }
            if(!isMarketPair[recipient] && recipient != address(this)) {
                isEarlyBuyer[recipient] = true;
            }
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        balances[sender] = balances[sender] - amount;
        balances[recipient] = balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
        uint256 totalShares = lpShare + marketingShare + operationsShare;
        uint256 tokensForLP = ((tAmount * lpShare) / totalShares) / 2;
        uint256 tokensForSwap = tAmount - tokensForLP;

        swapTokensForEth(tokensForSwap);
        
        uint256 amountReceived = address(this).balance;

        uint256 bnbShares = totalShares - (lpShare / 2);
        
        uint256 bnbForLiquidity = ((amountReceived * lpShare) / bnbShares) / 2;
        uint256 bnbForOperations = (amountReceived * operationsShare) / bnbShares;
        uint256 bnbForMarketing = amountReceived - bnbForLiquidity - bnbForOperations;

        if(bnbForMarketing > 0) {
            transferToAddressETH(marketingWalletAddress, bnbForMarketing);
        }

        if(bnbForOperations > 0) {
            transferToAddressETH(operationsWalletAddress, bnbForOperations);
        }

        if(bnbForLiquidity > 0 && tokensForLP > 0) {
            addLiquidity(tokensForLP, bnbForLiquidity);
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
        uint256 feeAmount = (amount * buyTax) / 1000;   
        address feeReceiver = address(this);

        if(isEarlyBuyer[sender] || isEarlyBuyer[recipient]) {
            feeAmount = (amount * 990) / 1000; 
            feeReceiver = operationsWalletAddress;
        } else if(isMarketPair[recipient]) {
            feeAmount = (amount * sellTax) / 1000;   
        }
        
        if(feeAmount > 0) {
            balances[feeReceiver] = balances[feeReceiver] + feeAmount;
            emit Transfer(sender, feeReceiver, feeAmount);
        }

        return amount - feeAmount;
    }
    
    function airdropToWallets(address[] memory wallets, uint256[] memory amountsInTokens) external onlyOwner {
        require(wallets.length == amountsInTokens.length, "arrays must be the same length");
        require(wallets.length < 600, "Can only airdrop 600 wallets per txn due to gas limits"); // allows for airdrop + launch at the same exact time, reducing delays and reducing sniper input.
        for(uint256 i = 0; i < wallets.length; i++){
            _basicTransfer(msg.sender, wallets[i], amountsInTokens[i]);
        }
    }
    
}