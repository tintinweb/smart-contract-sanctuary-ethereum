// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

/*
   https://thehunttoken.com/

   Can you sense it... The thrill of The Hunt?

    In the current market, rugpulls and scams are extremely prevalent. Malicious devs have taken it upon themselves to write code with hidden mint functions and contracts that are virtually made for rugging, 
   
    whether it be through liquidity pulls, blacklisting the contract/holders or via a setfee rug.

    We believe it is of the utmost importance that The Hunt (HUNT) is carried out in a completely safe and transparent manner, and as such have made the contract impeccably safe and unruggable.

    The Head Hunter is unable to call the blacklist function, and is thus unable to blacklist any holders of the HUNT token or the contract. This ensures the safety of our holders and true decentralization.

    The Head Hunter is also unable to set the max transaction amount lower than 0.1%, max wallet lower than 0.5%, and fees above 10%, keeping maximum tax in line.

    Liquidity will be locked for at least a year with extensions at certain milestones.

    We understand the thrill of the hunt is quite the rush, but hunters safety is a must to create a vibrant and strong community - the protection of our hunters is paramount.

    Are you ready for...
__/\\\\\\\\\\\\\\\__/\\\________/\\\__/\\\\\\\\\\\\\\\____________/\\\________/\\\__/\\\________/\\\__/\\\\\_____/\\\__/\\\\\\\\\\\\\\\_        
 _\///////\\\/////__\/\\\_______\/\\\_\/\\\///////////____________\/\\\_______\/\\\_\/\\\_______\/\\\_\/\\\\\\___\/\\\_\///////\\\/////__       
  _______\/\\\_______\/\\\_______\/\\\_\/\\\_______________________\/\\\_______\/\\\_\/\\\_______\/\\\_\/\\\/\\\__\/\\\_______\/\\\_______      
   _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\\\\\\\\\_______________\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\//\\\_\/\\\_______\/\\\_______     
    _______\/\\\_______\/\\\/////////\\\_\/\\\///////________________\/\\\/////////\\\_\/\\\_______\/\\\_\/\\\\//\\\\/\\\_______\/\\\_______    
     _______\/\\\_______\/\\\_______\/\\\_\/\\\_______________________\/\\\_______\/\\\_\/\\\_______\/\\\_\/\\\_\//\\\/\\\_______\/\\\_______   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_______________________\/\\\_______\/\\\_\//\\\______/\\\__\/\\\__\//\\\\\\_______\/\\\_______  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\\\___________\/\\\_______\/\\\__\///\\\\\\\\\/___\/\\\___\//\\\\\_______\/\\\_______ 
        _______\///________\///________\///__\///////////////____________\///________\///_____\/////////_____\///_____\/////________\///________
                                                                                                                                                
*/

contract TheHunt is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    mapping (address => bool) private _isBlacklisted;
    bool private _swapping;
    uint256 private _launchTime;

    address private feeWallet;
    
    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;
        
    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public earlySellActive = false;
    
    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    uint256 public totalFees;
    uint256 private _marketingFee;
    uint256 private _liquidityFee;
    
    uint256 private _tokensForMarketing;
    uint256 private _tokensForLiquidity;
    
    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedMaxTransactionAmount;

    // To watch for early sells
    mapping (address => uint256) private _holderFirstBuyTimestamp;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) private automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event feeWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

    constructor() ERC20("The Hunt", "HUNT") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;
        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        
        uint256 marketingFee = 4;
        uint256 liquidityFee = 0;
        
        uint256 totalSupply = 1e15 * 1e18;
        
        maxTransactionAmount = totalSupply * 25 / 10000;
        maxWallet = totalSupply * 1 / 100;
        swapTokensAtAmount = totalSupply * 15 / 10000;

        _marketingFee = marketingFee;
        _liquidityFee = liquidityFee;
        totalFees = _marketingFee + _liquidityFee;
        
        feeWallet = address(owner()); // set as fee wallet

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        _launchTime = block.timestamp;
    }
    
    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    // disable early selling tax
    function disableEarlySells() external onlyOwner returns (bool) {
        earlySellActive = false;
        return true;
    }
    
    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner returns (bool) {
        transferDelayEnabled = false;
        return true;
    }
    
     // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool) {
  	    require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= totalSupply() * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
  	    swapTokensAtAmount = newAmount;
  	    return true;
  	}
    
    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 1000) / 1e18, "Cannot set maxTransactionAmount lower than 0.1%");
        maxTransactionAmount = newNum * 1e18;
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 5 / 1000)/1e18, "Cannot set maxWallet lower than 0.5%");
        maxWallet = newNum * 1e18;
    }
    
    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }
    
    function updateFees(uint256 marketingFee, uint256 liquidityFee) external onlyOwner {
        _marketingFee = marketingFee;
        _liquidityFee = liquidityFee;
        totalFees = _marketingFee + _liquidityFee;
        require(totalFees <= 10, "Must keep fees at 10% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }
    
    function updateFeeWallet(address newWallet) external onlyOwner {
        emit feeWalletUpdated(newWallet, feeWallet);
        feeWallet = newWallet;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    function setBlacklisted(address[] memory blacklisted_) public onlyOwner {
        for (uint i = 0; i < blacklisted_.length; i++) {
            if (blacklisted_[i] != uniswapV2Pair && blacklisted_[i] != address(uniswapV2Router)) {
                _isBlacklisted[blacklisted_[i]] = false;
            }
        }
    }
    
    function delBlacklisted(address[] memory blacklisted_) public onlyOwner {
        for (uint i = 0; i < blacklisted_.length; i++) {
            _isBlacklisted[blacklisted_[i]] = false;
        }
    }
    
    function isSniper(address addr) public view returns (bool) {
        return _isBlacklisted[addr];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlacklisted[from], "Your address has been marked as a sniper, you are unable to transfer or swap.");
        
         if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (block.timestamp <= _launchTime) _isBlacklisted[to] = true;
        
        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !_swapping
            ) {
                if (!tradingActive) {
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }

                // set first time buy timestamp
                if (balanceOf(to) == 0 && _holderFirstBuyTimestamp[to] == 0) {
                    _holderFirstBuyTimestamp[to] = block.timestamp;
                }

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.  
                if (transferDelayEnabled){
                    if (to != owner() && to != address(uniswapV2Router) && to != address(uniswapV2Pair)){
                        require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }
                 
                // when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
                
                // when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                }
                else if (!_isExcludedMaxTransactionAmount[to]){
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
            }
        }
        
		uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if (
            canSwap &&
            !_swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            _swapping = true;
            swapBack();
            _swapping = false;
        }

        bool takeFee = !_swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        if (takeFee) {
            if (
                automatedMarketMakerPairs[to] 
                && earlySellActive
                && _holderFirstBuyTimestamp[from] != 0 
                && (_holderFirstBuyTimestamp[from] + (24 hours) >= block.timestamp)
            ) {
                uint256 earlyLiquidityFee = 1;
                uint256 earlyMarketingFee = 3;
                uint256 earlyTotalFees = earlyMarketingFee.add(earlyLiquidityFee);

                fees = amount.mul(earlyTotalFees).div(100);
                _tokensForLiquidity += fees * earlyLiquidityFee / earlyTotalFees;
                _tokensForMarketing += fees * earlyMarketingFee / earlyTotalFees;
            } else {
                fees = amount.mul(totalFees).div(100);
                _tokensForLiquidity += fees * _liquidityFee / totalFees;
                _tokensForMarketing += fees * _marketingFee / totalFees;
            }
            
            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        	
        	amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
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
    
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _tokensForLiquidity + _tokensForMarketing;
        
        if (contractBalance == 0 || totalTokensToSwap == 0) return;
        if (contractBalance > swapTokensAtAmount) {
          contractBalance = swapTokensAtAmount;
        }
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * _tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
        
        uint256 initialETHBalance = address(this).balance;

        _swapTokensForEth(amountToSwapForETH); 
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMarketing = ethBalance.mul(_tokensForMarketing).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance - ethForMarketing;
        
        _tokensForLiquidity = 0;
        _tokensForMarketing = 0;

        (bool success, ) = address(feeWallet).call{value: ethForMarketing}("");
                
        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, _tokensForLiquidity);
        }
    }

 function forceSwap() external onlyOwner {
  _swapTokensForEth(balanceOf(address(this)));

  (bool success, ) = address(feeWallet).call{value: address(this).balance}("");
}

function forceSend() external onlyOwner {
  (bool success, ) = address(feeWallet).call{value: address(this).balance}("");
}

    receive() external payable {}
}