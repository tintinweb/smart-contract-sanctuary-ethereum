// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

/*

    * Tribe DAO * 

*/

contract TribeDAO is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    mapping (address => bool) private _isBanished;
    bool private _swapping;
    uint256 private _liveBlock;

    address private treasuryWallet;
    
    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;
        
    bool public limitsInEffect = true;
    bool public tradingLive = false;
    
    // anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastBuyTimestamp;

    uint256 private _treasuryFee = 2;    
    uint256 private _tokensForTreasury;
    
    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) private automatedMarketMakerPairs;

    constructor() ERC20("Tribe DAO", "TRIBE") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;
        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
                
        uint256 totalSupply = 6666666666666 * 1e18;
        
        maxTransactionAmount = totalSupply * 25 / 10000;
        maxWallet = totalSupply * 5 / 1000;
        swapTokensAtAmount = totalSupply * 1 / 1000;
        
        treasuryWallet = address(owner()); // set as fee wallet

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
        tradingLive = true;
        _liveBlock = block.number.add(2);
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
    }
    
    function updatetreasuryWallet(address newWallet) external onlyOwner {
        treasuryWallet = newWallet;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    function banish(address[] memory addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            if (addresses[i] != uniswapV2Pair && addresses[i] != address(uniswapV2Router)) {
                _isBanished[addresses[i]] = true;
            }
        }
    }
    
    function unbanish(address[] memory addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            _isBanished[addresses[i]] = false;
        }
    }
    
    function banished(address addr) public view returns (bool) {
        return _isBanished[addr];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBanished[from], "You have been banished, you are unable to transfer or swap.");
        
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        // all to secure a smooth launch
        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !_swapping
            ) {
                if (!tradingLive) require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "_transfer:: Trading is not active.");
                if (block.number <= _liveBlock) _isBanished[to] = true;
                
                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.  
                if (to != owner() && to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                    require(_holderLastBuyTimestamp[tx.origin] < block.timestamp, "_transfer:: Transfer Delay enabled.  Only one purchase per minute allowed.");
                }
                 
                // wen buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTransactionAmount, "_transfer:: Buy transfer amount exceeds the maxTransactionAmount.");
                    require(amount + balanceOf(to) <= maxWallet, "_transfer:: Max wallet exceeded");
                }
                
                // wen sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxTransactionAmount, "_transfer:: Sell transfer amount exceeds the maxTransactionAmount.");
                }
                else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(amount + balanceOf(to) <= maxWallet, "_transfer:: Max wallet exceeded");
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

        // if any addy belongs to _isExcludedFromFee or isn't a swap then remove the fee
        if (
            _isExcludedFromFees[from] || 
            _isExcludedFromFees[to] || 
            (!automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to])
        ) takeFee = false;
        
        uint256 fees = 0;
        if (takeFee) {
            if (limitsInEffect) {
                fees = amount.mul(99).div(100); // good luck snipers :)
            } else {

                 // let's try to f*ck the sandwich bots
                if (automatedMarketMakerPairs[to] && _holderLastBuyTimestamp[tx.origin] > block.timestamp) {
                    fees = amount.mul(49).div(100);
                } else {
                    fees = amount.mul(_treasuryFee).div(100);
                }
            }

            _tokensForTreasury += fees;
            _holderLastBuyTimestamp[tx.origin] = block.timestamp.add(1 minutes);
            
            if (fees > 0) super._transfer(from, address(this), fees);
        	
        	amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
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

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        
        if (contractBalance == 0) return;
        if (contractBalance > swapTokensAtAmount) contractBalance = swapTokensAtAmount;
                
        uint256 initialETHBalance = address(this).balance;

        _swapTokensForEth(contractBalance); 
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        _tokensForTreasury = 0;

        payable(treasuryWallet).transfer(ethBalance);
    }

    function sendTreasury() external {
        payable(treasuryWallet).transfer(address(this).balance);
    }

    receive() external payable {}
}