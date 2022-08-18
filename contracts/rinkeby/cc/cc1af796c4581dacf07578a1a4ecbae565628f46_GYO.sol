/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

//V8

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 /* ================= INTERFACES ================= */

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to,uint256 deadline) external;
    //& function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    //& function removeLiquidityETH(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external returns (uint256 amountToken, uint256 amountETH);
    //& function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IDexFactory {
    //& function getPair(address tokenA, address tokenB) external view returns (address pair);
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

 /* ================= CONTRACT ================= */

contract GYO is Context, IERC20, Ownable {  //&
    string private constant _name = "GYO";  //&
    string private constant _symbol = "GGG"; //&
    uint8 private constant _decimals = 18;

    address payable public devWallet = payable(0xFb67144EEEcdD15E0A1A5c2B233f398Ad78Df2de); //& private ?
    address payable public marketingWallet = payable(0x32CA1c6E08bd89159816e8cF55768A0F4E8daA9D); //& private ?
    address payable private constant treasuryWallet = payable(0x1459B62E9c67178122Eb902FE12f9eB643D857eA); //& private ?
    //autoLiquidityReceiver

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isMarketPair;
    mapping(address => bool) public isEarlyBuyer;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public isWalletLimitExempt;

    uint256 public buyTax = 300;  // buy tax = 3%
    uint256 public sellTax = 300; // sell tax = 3%

    uint256 public lpShare = 1; //& 
    uint256 public marketingShare = 1; //&
    uint256 public autoBurnShare = 1; //&
    //uint256 public reflectionShare = 1; //&

    uint256 private constant _totalSupply = 100000 * 10**_decimals;
    uint256 public swapThreshold = 10 * 10**_decimals; //&
    uint256 public maxTxAmount = 5000 * 10**_decimals;
    uint256 public walletMax = 10000 * 10**_decimals;
    uint256 private constant supplyPercentageForLP = 6500; //65% of the token supply goes to the liquidity pool at start
    //add 5% supply dev wallet
    //uint256 private constant supplyPercentageForDev = 500; //5% of the token supply goes to the dev wallet --> vested 

    IDexRouter public immutable dexRouter;
    address public lpPair;

    bool private isInSwap; // to check wether the contract is already in a swap, so as to avoid fees from _transfer function while swapping
    bool public swapEnabled = true; //enable the swap of token stored on the contract from fees
    bool public swapByLimitOnly = false; //&
    bool public launched = false;
    bool public checkWalletLimit = true;
    bool public snipeBlockExpired = false;

    uint256 public launchBlock = 0;
    uint256 public snipeBlockAmount = 0;
    uint256 public sellBlockAmount = 0;

 // ------------------------
 // ****** Events ******
 // ------------------------

    event SwapSettingsUpdated(
        bool swapEnabled_,
        uint256 swapThreshold_,
        bool swapByLimitOnly_
    );
    event SwapTokensForETH(uint256 amountIn, address[] path);
    event AccountWhitelisted(
        address account,
        bool feeExempt,
        bool walletLimitExempt,
        bool txLimitExempt
    );
    //& event RouterVersionChanged(address newRouterAddress); --> delete?
    event TaxesChanged(uint256 newBuyTax, uint256 newSellTax);
    event TaxDistributionChanged(uint256 newLpShare, uint256 newMarketingShare, uint256 newAutoBurnShare);
    event MarketingWalletChanged(address marketingWallet_);
    event EarlyBuyerUpdated(address account, bool isEarlyBuyer_);
    event MarketPairUpdated(address account, bool isMarketPair_);
    event WalletLimitChanged(uint256 walletMax_);
    event MaxTxAmountChanged(uint256 maxTxAmount_);
    event MaxWalletCheckChanged(bool checkWalletLimit_);

 // ------------------------
 // ****** Modifiers ******
 // ------------------------

    modifier lockTheSwap() { //& change name
        isInSwap = true;
        _;
        isInSwap = false;
    }

 // ------------------------
 // ****** Constructor ******
 // ------------------------

    constructor() payable {
        dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Router Uniswap V2
        
        isExcludedFromFee[owner()] = true; //& devWallet   
        isExcludedFromFee[address(this)] = true;      
        isExcludedFromFee[address(marketingWallet)] = true;
        isExcludedFromFee[address(treasuryWallet)] = true;
        isExcludedFromFee[address(dexRouter)] = true;
        isExcludedFromFee[address(0xdead)] = true; 

        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(marketingWallet)] = true;
        isTxLimitExempt[address(treasuryWallet)] = true;
        isTxLimitExempt[address(dexRouter)] = true;
        isTxLimitExempt[address(0xdead)] = true;

        isWalletLimitExempt[owner()] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[address(marketingWallet)] = true;
        isWalletLimitExempt[address(treasuryWallet)] = true;
        isWalletLimitExempt[address(dexRouter)] = true;
        isWalletLimitExempt[address(0xdead)] = true;

        allowances[address(this)][address(dexRouter)] = _totalSupply;
        balances[address(this)] = _totalSupply * supplyPercentageForLP / 10000; //Tokens for LP
        emit Transfer(address(0), address(this), balanceOf(address(this)));
        balances[treasuryWallet] = _totalSupply - balanceOf(address(this)); // TreasuryWallet --> 30% of the totalSupply
        emit Transfer(address(0), treasuryWallet, balanceOf(treasuryWallet));
    }

    receive() external payable {} //to receive ETH from dexRouter when swapping

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
        return _totalSupply - balanceOf(address(0xdead));
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function allowance(address owner_, address spender)
        public
        view
        override
        returns (uint256)
    {
        return allowances[owner_][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(
        address owner_,
        address spender,
        uint256 amount
    ) private {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function setIsEarlyBuyer(address account, bool isEarlyBuyer_) public onlyOwner {
        isEarlyBuyer[account] = isEarlyBuyer_;
        emit EarlyBuyerUpdated(account, isEarlyBuyer_);
    }

    function massSetIsEarlyBuyer(address[] calldata accounts, bool isEarlyBuyer_) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++){
            isEarlyBuyer[accounts[i]] = isEarlyBuyer_;
            emit EarlyBuyerUpdated(accounts[i], isEarlyBuyer_);
        }
    }

    //&
    /*
    function setMarketPairStatus(address account, bool isMarketPair_)
        public
        onlyOwner
    {
        isMarketPair[account] = isMarketPair_;
        emit MarketPairUpdated(account, isMarketPair_);
    } */

    function setTaxes(uint256 newBuyTax, uint256 newSellTax) external onlyOwner { //& --> change SetNewTaxes external
        require(newBuyTax <= 3000, "Cannot exceed 30%"); //the maximum buy tax amount can't be set to a value higher than 30%
        require(newSellTax <= 3000, "Cannot exceed 30%"); //the maximum sell tax amount can't be set to a value higher than 30%
        buyTax = newBuyTax;
        sellTax = newSellTax;
        emit TaxesChanged(newBuyTax, newSellTax);
    }

    function setTaxDistribution(
        uint256 newLpShare,
        uint256 newMarketingShare,
        uint256 newAutoBurnShare
    ) external onlyOwner {
        lpShare = newLpShare;
        marketingShare = newMarketingShare;
        autoBurnShare = newAutoBurnShare; 
        emit TaxDistributionChanged(
            newLpShare,
            newMarketingShare,
            newAutoBurnShare
        );
    }

    function setMaxTx(uint256 maxTxAmount_) external onlyOwner { //& setNewMaxTx (uint256 newMaxTx_)
        require(maxTxAmount_ >= totalSupply() * 50 / 10000); //the maximum amount for a transaction can't be set to a value lower than 5%
        maxTxAmount = maxTxAmount_;
        emit MaxTxAmountChanged(maxTxAmount_);
    }

    function setWalletLimit(uint256 walletMax_) external onlyOwner {
        require(walletMax_ >= totalSupply() * 1 / 100);
        walletMax = walletMax_;
        emit WalletLimitChanged(walletMax_);
    }

    function enableDisableWalletLimit(bool checkWalletLimit_)
        external
        onlyOwner
    {
        checkWalletLimit = checkWalletLimit_;
        emit MaxWalletCheckChanged(checkWalletLimit_);
    }

    function whitelistAccount(address account, bool feeExempt, bool walletLimitExempt, bool txLimitExempt) public onlyOwner {
        isExcludedFromFee[account] = feeExempt;
        isWalletLimitExempt[account] = walletLimitExempt;
        isTxLimitExempt[account] = txLimitExempt;
        emit AccountWhitelisted(account, feeExempt, walletLimitExempt, txLimitExempt);
    }
    
    //&
    function updateSwapSettings(bool swapEnabled_, uint256 swapThreshold_, bool swapByLimitOnly_) public onlyOwner {
        swapEnabled = swapEnabled_;
        swapThreshold = swapThreshold_;
        swapByLimitOnly = swapByLimitOnly_;
        emit SwapSettingsUpdated(
            swapEnabled_,
            swapThreshold_,
            swapByLimitOnly_
        );
    }

    function setNewMarketingWallet(address marketingWallet_) external onlyOwner {
        require(marketingWallet_ != address(0), "New address cannot be zero address");
        marketingWallet = payable(marketingWallet_);
        emit MarketingWalletChanged(marketingWallet_);
    }

    function transferToAddressETH(address payable recipient, uint256 amount)
        private
    {
        bool success;
        (success, ) = address(recipient).call{value: amount}("");
    }

    function _transfer( 
        address sender,
        address recipient,
        uint256 amount
    ) private returns (bool) {

        if (isInSwap) {
            return _basicTransfer(sender, recipient, amount);
        } else {
            require(sender != address(0), "ERC20: transfer from the zero address");
            require(recipient != address(0), "ERC20: transfer to the zero address");
            require(!isEarlyBuyer[sender] && !isEarlyBuyer[recipient], "To/from address is blacklisted!");

            if (!isTxLimitExempt[sender] && !isTxLimitExempt[recipient]) {
                require(launched, "Not Launched.");
                if (isMarketPair[sender] || isMarketPair[recipient]) {
                    require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
                }
                if (!snipeBlockExpired) {
                    checkIfBot(sender, recipient);
                }
            }

            bool isTaxFree = ((!isMarketPair[sender] &&
                !isMarketPair[recipient]) ||
                isExcludedFromFee[sender] ||
                isExcludedFromFee[recipient]);

            if (
                !isTaxFree && !isMarketPair[sender] && swapEnabled && !isInSwap
            ) {
                uint256 contractTokenBalance = balanceOf(address(this));
                bool overMinimumTokenBalance = contractTokenBalance >=
                    swapThreshold;
                if (overMinimumTokenBalance) {
                    if (swapByLimitOnly) contractTokenBalance = swapThreshold;
                    if(contractTokenBalance > swapThreshold * 20) contractTokenBalance = swapThreshold * 20; 
                    swapAndLiquify(contractTokenBalance);
                }
            }
            
            balances[sender] = balances[sender] - amount;

            uint256 finalAmount = isTaxFree
                ? amount
                : takeFee(sender, recipient, amount);

            if (checkWalletLimit && !isWalletLimitExempt[recipient])
                require((balanceOf(recipient) + finalAmount) <= walletMax);

            balances[recipient] = balances[recipient] + finalAmount;
            emit Transfer(sender, recipient, finalAmount);

            return true;
        }
    }

    function checkIfBot(address sender, address recipient) private {
        if ((block.number - launchBlock) > snipeBlockAmount) {
            snipeBlockExpired = true;
        } else if (sender != owner() && recipient != owner()) {
            if (!isMarketPair[sender] && sender != address(this)) {
                isEarlyBuyer[sender] = true;
            }
            if (!isMarketPair[recipient] && recipient != address(this)) {
                isEarlyBuyer[recipient] = true;
            }
        }
    }

    function _basicTransfer( 
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) { //PUBLIC
        balances[sender] = balances[sender] - amount;
        balances[recipient] = balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap { //& rename ?
        uint256 totalShares = marketingShare + autoBurnShare; //LP shared was already added to pool
        uint256 tokensForBurn = (contractTokenBalance * autoBurnShare) / totalShares;
        uint256 tokensForSwap = contractTokenBalance - tokensForBurn;

        //swap Tokens on the the contract for ETH and send it to the marketing account
        swapTokensForEth(tokensForSwap);
        uint256 ethForMarketing = address(this).balance;
        if (ethForMarketing > 0) {
            transferToAddressETH(marketingWallet, ethForMarketing);
        }

        //transfer to the dead address (burn)
        if (autoBurnShare > 0) {
            _basicTransfer(address(this), address(0xdead), tokensForBurn);
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

        _approve(address(this), address(dexRouter), tokenAmount);  // approve token transfer to cover all possible scenarios

        dexRouter.addLiquidityETH{value: ethAmount}( // add the liquidity
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            //address(0xdead),
            address(devWallet),
            block.timestamp
        );
    }

    function getTotalFee() public view returns(uint256){
        return lpShare + marketingShare + autoBurnShare;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount = (amount * buyTax) / 10000;
        address feeReceiver = address(this);

        if (isEarlyBuyer[sender] || isEarlyBuyer[recipient]) {
            feeAmount = (amount * 9900) / 10000;
        } 
        else if (isMarketPair[recipient]) {
            // Early seller penalty
            if(launchBlock + sellBlockAmount > block.number){
                feeAmount = (amount * 9900) / 10000;
            } else {
                feeAmount = (amount * sellTax) / 10000;
            }
        }

        if (feeAmount > 0) { 
            //Inject the fees into the contract itself; 
            _basicTransfer(sender, feeReceiver, feeAmount);
      
            //if(lpShare > 0){ //auto LP (spiral method)
                //Re-inject the liquidity shares now held by the contract into the LP
                //uint256 lpFee = (feeAmount * lpShare) / getTotalFee();
                //_basicTransfer(feeReceiver, lpPair, lpFee);
            //}
        }

        return amount - feeAmount;
    }

    function launch(uint256 _snipePenaltyBlocks, uint256 _sellPenaltyBlocks) external onlyOwner {
        require(!launched, "Trading is already active, cannot relaunch.");

        // create pair
        lpPair = IDexFactory(dexRouter.factory()).createPair(address(this),dexRouter.WETH());
        isMarketPair[address(lpPair)] = true;
        isWalletLimitExempt[address(lpPair)] = true;

        // add the liquidity
        require(address(this).balance > 0, "Must have ETH on contract to launch");
        require(balanceOf(address(this)) > 0, "Must have Tokens on contract to launch");

        _approve(address(this), address(dexRouter), balanceOf(address(this)));
        dexRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(devWallet), //devWallet receive the LP tokens
            block.timestamp 
        );

        launched = true;
        launchBlock = block.number;
        snipeBlockAmount = _snipePenaltyBlocks;
        sellBlockAmount = _sellPenaltyBlocks;
    }

    // withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function transferForeignToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        require(_token != address(this)); //& || !launched, "Can't withdraw native tokens while trading is active");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }
}