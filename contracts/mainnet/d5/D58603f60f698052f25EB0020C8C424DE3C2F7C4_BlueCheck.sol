// Blue Check
// https://t.me/bluechecketh
// https://twitter.com/BlueCheck_Erc20
// https://bluecheckerc20.com

// SPDX-License-Identifier: MIT                                                                               
pragma solidity 0.8.17;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./SafeMath.sol";

contract BlueCheck is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool private swapping;

    address public operationsWallet;
    
    uint256 public maxWallet;
    
    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    
    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

     // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;
    
    uint256 public constant feeDivisor = 1000;

    uint256 public totalFees;
    uint256 public operationsFee;
    uint256 public liquidityFee;
    
    uint256 public tokensForOperations = 0;
    uint256 public tokensForLiquidity = 0;
    
    uint256 public gasForProcessing = 0;

    uint256 public lpWithdrawRequestTimestamp;
    uint256 public lpWithdrawRequestDuration = 3 days;
    bool public lpWithdrawRequestPending;
    uint256 public lpPercToWithDraw;

    /******************/

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event OperationsWalletUpdated(address indexed newWallet, address indexed oldWallet);

    event MarketingWalletUpdated(address indexed newWallet, address indexed oldWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event RequestedLPWithdraw();
    
    event WithdrewLPForMigration();

    event CanceledLpWithdrawRequest();

    constructor() ERC20("Blue Check", "$BLC") {

        uint256 totalSupply = 100_000_000 * 1e18;

        maxWallet = 2_000_000 * 1e18;

        operationsFee = 40;
        liquidityFee = 10;
        totalFees = operationsFee + liquidityFee;
    	
    	operationsWallet = address(msg.sender); // set as operations wallet

    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    	
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        
        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        _createInitialSupply(address(owner()), totalSupply);
    }

    receive() external payable {

  	}

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        require(!tradingActive, "Cannot re-enable trading");
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
    }
    
    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner(){
        swapEnabled = enabled;
    }
    
    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum > (totalSupply() * 1 / 100)/1e18, "Cannot set maxWallet lower than 1%");
        maxWallet = newNum * (10**18);
    }
    
    function updateFees(uint256 _operationsFee, uint256 _liquidityFee) external onlyOwner {
        operationsFee = _operationsFee;
        liquidityFee = _liquidityFee;
        totalFees = operationsFee + liquidityFee;
        require(totalFees <= 100, "Must keep fees at 10% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "The swap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateOperationsWallet(address newOperationsWallet) external onlyOwner {
        require(newOperationsWallet != address(0), "may not set to 0 address");
        excludeFromFees(newOperationsWallet, true);
        emit OperationsWalletUpdated(newOperationsWallet, operationsWallet);
        operationsWallet = newOperationsWallet;
    }

    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, " gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function isExcludedFromFees(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        if(!tradingActive){
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active yet.");
        }
        
        if(limitsInEffect){
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ){
                // Transfer Delay
                if (transferDelayEnabled){
                    if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)){
                        require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }

                //when buy
                if (automatedMarketMakerPairs[from]) {
                    require(amount + balanceOf(to) <= maxWallet, "Unable to exceed Max Wallet");
                } 
            }
        }

        if( 
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        uint256 fees = 0;
        
        // no taxes on transfers (non buys/sells)
        if(takeFee){
            if (automatedMarketMakerPairs[to] || automatedMarketMakerPairs[from]){
                fees = amount.mul(totalFees).div(feeDivisor);
                tokensForLiquidity += fees * liquidityFee / totalFees;
                tokensForOperations += fees * operationsFee / totalFees;
            }
            
            if(fees > 0){    
                super._transfer(from, address(this), fees);
            }
        	
        	amount -= fees;
        }

        super._transfer(from, to, amount);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );

    }
    
    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForOperations;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}
        
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH); 
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        
        uint256 ethForOperations = ethBalance.mul(tokensForOperations).div(totalTokensToSwap - (tokensForLiquidity/2));
        
        uint256 ethForLiquidity = ethBalance - ethForOperations;
        
        tokensForLiquidity = 0;
        tokensForOperations = 0;
        
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        }
        
        (bool success,) = address(operationsWallet).call{value: address(this).balance}("");
        require(success, "failed to process a tax");
    }

    function withdrawStuckEth() external onlyOwner {
        (bool success,) = address(msg.sender).call{value: address(this).balance}("");
        require(success, "failed to withdraw");
    }

    function requestToWithdrawLP(uint256 percToWithdraw) external onlyOwner {
        require(!lpWithdrawRequestPending, "Cannot request again until first request is over.");
        require(percToWithdraw <= 100 && percToWithdraw > 0, "Need to set between 1-100%");
        lpWithdrawRequestTimestamp = block.timestamp;
        lpWithdrawRequestPending = true;
        lpPercToWithDraw = percToWithdraw;
        emit RequestedLPWithdraw();
    }

    function nextAvailableLpWithdrawDate() public view returns (uint256){
        if(lpWithdrawRequestPending){
            return lpWithdrawRequestTimestamp + lpWithdrawRequestDuration;
        }
        else {
            return 0;  // 0 means no open requests
        }
    }

    function withdrawRequestedLP() external onlyOwner {
        require(block.timestamp >= nextAvailableLpWithdrawDate() && nextAvailableLpWithdrawDate() > 0, "Must request and wait.");
        lpWithdrawRequestTimestamp = 0;
        lpWithdrawRequestPending = false;

        uint256 amtToWithdraw = IERC20(address(uniswapV2Pair)).balanceOf(address(this)) * lpPercToWithDraw / 100;
        
        lpPercToWithDraw = 0;

        IERC20(uniswapV2Pair).transfer(msg.sender, amtToWithdraw);
    }

    function cancelLPWithdrawRequest() external onlyOwner {
        lpWithdrawRequestPending = false;
        lpPercToWithDraw = 0;
        lpWithdrawRequestTimestamp = 0;
        emit CanceledLpWithdrawRequest();
    }
}