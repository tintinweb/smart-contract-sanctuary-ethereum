/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

/*

GYOTO $GYOTO

THE DUMPLING GANG - For the baddest only

Website: https://gyoto.xyz/

*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.16;

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

 /* ======================================== INTERFACES ======================================== */

interface IDexRouter {
    function factory() external pure returns (address);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline
    ) external;
    function addLiquidity(
        address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline
    ) external payable returns (uint256 amountA, uint256 amountB, uint256 liquidity); 
}

interface IDexFactory {
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

 /* ======================================== CONTRACT ======================================== */

contract GYOTO is Context, IERC20, Ownable {  
    string private constant _name = "Gyoto";  
    string private constant _symbol = "GYOTO"; 
    uint8 private constant _decimals = 18;

    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; 

    address payable public devWallet = payable(0x7054AAA2Ee9D6Bd788430d09F53F60f617e6fC16); 
    address payable public treasuryWallet = payable(0x69f918fB1eC59E7DEDAD5959a7B17C768143d43d); 
    address payable private developmentWallet = payable(0xa0BA136cCa334cCa33ee6aA38a8aeBbdB750cEb1); 
    address payable private gyoWallet = payable(0xdCB37CB368B83aDd890E80CDDC1fd65436556660); 

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isMarketPair;
    mapping(address => bool) public isEarlyBuyer;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public isWalletLimitExempt;

    uint256 public buyTax = 500;  // buy tax = 5%
    uint256 public sellTax = 500; // sell tax = 5%

    uint256 public autoBurnShare = 1;
    uint256 public lpShare = 2;
    uint256 public developmentShare = 2;
    uint256 public gyoShare = 0; // to be activated later

    uint256 private constant _totalSupply = 100000 * 10**_decimals;
    uint256 private constant supplyPercentageForLP = 6500; // 65% of the token supply goes to the liquidity pool 
    uint256 private constant supplyPercentageForTreasury = 3000; // 30% of the token supply goes to the treasury wallet
    uint256 private constant supplyPercentageForDev = 500; // 5% of the token supply goes to the dev wallet (vested)
    
    uint256 public maxTxAmount = 500 * 10**_decimals; // max tx = 0.50% 
    uint256 public walletMax = 1000 * 10**_decimals; // max wallet = 1%
    uint256 public swapThreshold = 50 * 10**_decimals;

    IDexRouter public immutable dexRouter;
    address public lpPair;

    bool private isInSwap; // to check wether the contract is already in a swap, so as to avoid fees from _transfer function while swapping
    bool public swapEnabled = true; // enable the swap of token stored on the contract from fees
    bool public swapByLimitOnly = false;
    bool public launched = false;
    bool public checkWalletLimit = true;
    bool public snipeBlockExpired = false;

    uint256 public launchBlock = 0;
    uint256 public snipeBlockAmount = 0;
    uint256 public sellBlockAmount = 0;

 /* ============= EVENTS ============= */

    event SwapSettingsUpdated(
        bool swapEnabled_,
        uint256 swapThreshold_,
        bool swapByLimitOnly_
    );
    event SwapTokensForUSDC(uint256 amountIn, address[] path); 
    event AccountWhitelisted(
        address account,
        bool feeExempt,
        bool walletLimitExempt,
        bool txLimitExempt
    );
    event TaxesChanged(uint256 newBuyTax, uint256 newSellTax);
    event TaxDistributionChanged(uint256 newLpShare, uint256 newDevelopmentShare, uint256 newAutoBurnShare, uint256 newGyoShare);
    event DevelopmentWalletChanged(address developmentWallet_);
    event TreasuryWalletChanged(address treasuryWallet_);
    event GyoWalletChanged(address gyoWallet_);
    event EarlyBuyerUpdated(address account, bool isEarlyBuyer_);
    event MarketPairUpdated(address account, bool isMarketPair_);
    event WalletLimitChanged(uint256 walletMax_);
    event MaxTxAmountChanged(uint256 maxTxAmount_);
    event MaxWalletCheckChanged(bool checkWalletLimit_);

 /* ============= MODIFIERS ============= */

    modifier lockTheSwap() {
        isInSwap = true;
        _;
        isInSwap = false;
    }

 /* ============= CONSTRUCTOR ============= */

    constructor() payable {
        dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Router Uniswap V2
        
        isExcludedFromFee[owner()] = true;  
        isExcludedFromFee[address(this)] = true;      
        isExcludedFromFee[address(developmentWallet)] = true;
        isExcludedFromFee[address(treasuryWallet)] = true;
        isExcludedFromFee[address(gyoWallet)] = true;
        isExcludedFromFee[address(dexRouter)] = true;
        isExcludedFromFee[address(0xdead)] = true; 

        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(developmentWallet)] = true;
        isTxLimitExempt[address(treasuryWallet)] = true;
        isTxLimitExempt[address(gyoWallet)] = true;
        isTxLimitExempt[address(dexRouter)] = true;
        isTxLimitExempt[address(0xdead)] = true;

        isWalletLimitExempt[owner()] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[address(developmentWallet)] = true;
        isWalletLimitExempt[address(treasuryWallet)] = true;
        isWalletLimitExempt[address(gyoWallet)] = true;
        isWalletLimitExempt[address(dexRouter)] = true;
        isWalletLimitExempt[address(0xdead)] = true;

        allowances[address(this)][address(dexRouter)] = _totalSupply;

        balances[address(this)] = _totalSupply * supplyPercentageForLP / 10000; // tokens for LP
        emit Transfer(address(0), address(this), balanceOf(address(this)));

        balances[treasuryWallet] = _totalSupply * supplyPercentageForTreasury / 10000; // tokens for TreasuryWallet 
        emit Transfer(address(0), treasuryWallet, balanceOf(treasuryWallet));

        balances[devWallet] = _totalSupply * supplyPercentageForDev / 10000; // tokens for DevWallet (vested)
        emit Transfer(address(0), devWallet, balanceOf(devWallet));

    }

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

    function setMarketPairStatus(address account, bool isMarketPair_)
        public
        onlyOwner
    {
        isMarketPair[account] = isMarketPair_;
        emit MarketPairUpdated(account, isMarketPair_);
    }

    function updateTaxes(uint256 newBuyTax, uint256 newSellTax) external onlyOwner { 
        require(newBuyTax <= 1000, "Cannot exceed 10%"); //The maximum buy tax amount can't be set to a value higher than 10%
        require(newSellTax <= 1000, "Cannot exceed 10%"); //The maximum sell tax amount can't be set to a value higher than 10%
        buyTax = newBuyTax;
        sellTax = newSellTax;
        emit TaxesChanged(newBuyTax, newSellTax);
    }

    function updateTaxDistribution(
        uint256 newLpShare,
        uint256 newDevelopmentShare,
        uint256 newAutoBurnShare,
        uint256 newGyoShare
    ) external onlyOwner {
        lpShare = newLpShare;
        developmentShare = newDevelopmentShare;
        autoBurnShare = newAutoBurnShare; 
        gyoShare = newGyoShare;
        emit TaxDistributionChanged(
            newLpShare,
            newDevelopmentShare,
            newAutoBurnShare,
            newGyoShare
        );
    }

    function updateMaxTxAmount(uint256 maxTxAmount_) external onlyOwner { 
        require(maxTxAmount_ >= totalSupply() * 50 / 10000); // max tx amount can't be set to a value lower than 0.5%
        maxTxAmount = maxTxAmount_;
        emit MaxTxAmountChanged(maxTxAmount_);
    }

    function updateWalletLimit(uint256 walletMax_) external onlyOwner {
        require(walletMax_ >= totalSupply() * 1 / 100); // max wallet can't be set to a value lower than 1%
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

    function updateDevelopmentWallet(address developmentWallet_) external onlyOwner {
        require(developmentWallet_ != address(0), "New address cannot be zero address");
        developmentWallet = payable(developmentWallet_);
        emit DevelopmentWalletChanged(developmentWallet_);
    }

    function updateTreasuryWallet(address treasuryWallet_) external onlyOwner {
        require(treasuryWallet_ != address(0), "New address cannot be zero address");
        treasuryWallet = payable(treasuryWallet_);
        emit TreasuryWalletChanged(treasuryWallet_);
    }

    function updateGyoWallet(address gyoWallet_) external onlyOwner {
        require(gyoWallet_ != address(0), "New address cannot be zero address");
        gyoWallet = payable(gyoWallet_);
        emit GyoWalletChanged(gyoWallet_);
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

            if (!isTaxFree && !isMarketPair[sender] && swapEnabled && !isInSwap) {
                uint256 contractTokenBalance = balanceOf(address(this));
                bool overMinimumTokenBalance = contractTokenBalance >=
                    swapThreshold;
                if (overMinimumTokenBalance) {
                    if (swapByLimitOnly) contractTokenBalance = swapThreshold;
                    if(contractTokenBalance > swapThreshold * 20) contractTokenBalance = swapThreshold * 20; 
                    distributeFees(contractTokenBalance);
                }
            }            
            uint256 finalAmount = isTaxFree ? amount : takeFee(sender, recipient, amount);

            if (checkWalletLimit && !isWalletLimitExempt[recipient])
                require((balanceOf(recipient) + finalAmount) <= walletMax);

            _basicTransfer(sender, recipient, finalAmount);
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
    ) internal returns (bool) {
        balances[sender] = balances[sender] - amount;
        balances[recipient] = balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function distributeFees(uint256 contractTokenBalance) private lockTheSwap { 
        uint256 totalSharesWithoutLP = getTotalFeeShare() - lpShare ; //LP share was automatically added to the pool (Spiral method)
        uint256 tokensForBurn = (contractTokenBalance * autoBurnShare) / totalSharesWithoutLP;
        uint256 tokensForGyo = (contractTokenBalance * gyoShare) / totalSharesWithoutLP;
        uint256 tokensForSwap = contractTokenBalance - tokensForBurn - tokensForGyo;

        swapTokensForUSDC(tokensForSwap); //swap USDC for developmentWallet

        //development fees
        uint256 usdcForMarketing = IERC20(USDC).balanceOf(address(this)); 
        if (usdcForMarketing > 0) {
            IERC20(USDC).transfer(developmentWallet, usdcForMarketing); 
        }

        //autoburn fees
        if (autoBurnShare > 0) {
            _basicTransfer(address(this), address(0xdead), tokensForBurn);
        }

        //gyo fees (to be activated later)
         if (gyoShare > 0) {
            _basicTransfer(address(this), gyoWallet, tokensForGyo);
        }
    }

    function swapTokensForUSDC(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> usdc
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDC;

        _approve(address(this), address(dexRouter), tokenAmount); 

        //swap
        dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens( 
            tokenAmount,
            0, 
            path,
            developmentWallet,
            block.timestamp
        );

        emit SwapTokensForUSDC(tokenAmount, path); 
    }

    function getTotalFeeShare() public view returns(uint256){
        return lpShare + developmentShare + autoBurnShare + gyoShare;
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
            // bot penalty
            if(launchBlock + sellBlockAmount > block.number){
                feeAmount = (amount * 9900) / 10000;
            } else {
                feeAmount = (amount * sellTax) / 10000;
            }
        }

        //auto LP (Spiral method)
        if (feeAmount > 0) { 
            _basicTransfer(sender, feeReceiver, feeAmount); // inject fees into the contract    

            if(lpShare > 0){
                uint256 lpFee = (feeAmount * lpShare) / getTotalFeeShare();
                _basicTransfer(feeReceiver, lpPair, lpFee); // re-inject the liquidity shares now held by the contract into the LP
            }
        }
        return amount - feeAmount;
    }

    function launch(uint256 _snipePenaltyBlocks, uint256 _sellPenaltyBlocks) external onlyOwner {
        require(!launched, "Trading is already active, cannot relaunch.");
        require(lpPair != address(0), "Liquidity has not been created yet.");
        
        launchBlock = block.number;
        snipeBlockAmount = _snipePenaltyBlocks;
        sellBlockAmount = _sellPenaltyBlocks;
        launched = true;
    }

    function createLiquidityPool() external onlyOwner returns(bool){ //Create LP pool (require tokens and USDC on the contract)
        require(!launched, "Contract is already launched.");
        require(lpPair == address(0), "Liquidity pool is already created.");
        require(balanceOf(address(this)) > 0, "Must have Tokens on contract to launch"); 
        require(IERC20(USDC).balanceOf(address(this)) > 0, "Must have USDC on contract to launch"); 

        // create pair
        lpPair = IDexFactory(dexRouter.factory()).createPair(address(this), USDC);
        require(lpPair != address(0));
        isMarketPair[address(lpPair)] = true;
        isWalletLimitExempt[address(lpPair)] = true;

        //approve
        _approve(address(this), address(dexRouter), balanceOf(address(this)));
        IERC20(USDC).approve(address(dexRouter), IERC20(USDC).balanceOf(address(this)));

        //add liqu
        dexRouter.addLiquidity(
            address(this),
            USDC,
            balanceOf(address(this)),
            IERC20(USDC).balanceOf(address(this)),
            0, 
            0, 
            address(devWallet),
            block.timestamp
        );
        return true;
    }

    // withdraw ETH if stuck or someone sends to the contract
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function transferForeignToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        require(_token != address(this));
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }
}