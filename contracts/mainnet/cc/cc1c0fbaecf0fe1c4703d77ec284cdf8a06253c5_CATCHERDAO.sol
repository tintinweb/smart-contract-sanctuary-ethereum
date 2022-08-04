// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract CATCHERDAO is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    mapping (address => bool) private _isBlacklisted;
    bool private _swapping;
    uint256 private _liveBlock;

    address private _treasuryWallet;
    
    uint256 public maxTransactionAmount;
    uint256 public maxWallet;

    uint256 public swappedTokens;
    uint256 public swapTokensThreshold;
        
    bool public limitsInEffect = true;
    bool public tradingLive = false;

    uint256 private _treasuryFee = 5;
    uint256 private _liquidityFee = 2;
    uint256 private _tokensForTreasury;
    uint256 private _tokensForLiquidity;

    uint256 public totalFees = _treasuryFee + _liquidityFee;
    
    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) private _automatedMarketMakerPairs;

    // to stop bot spam buys and sells on launch
    mapping(address => uint256) private _holderLastTransferTimestamp;

    constructor() ERC20("Catcher DAO", "CDAO") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        _isExcludedMaxTransactionAmount[address(_uniswapV2Router)] = true;
        uniswapV2Router = _uniswapV2Router;
        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _isExcludedMaxTransactionAmount[address(uniswapV2Pair)] = true;
        _automatedMarketMakerPairs[address(uniswapV2Pair)] = true;
                
        uint256 totalSupply = 1e15 * 1e18;
        
        maxTransactionAmount = totalSupply * 125 / 100000;
        maxWallet = totalSupply * 5 / 1000;
        swapTokensThreshold = totalSupply * 1 / 1000;
        
        _treasuryWallet = address(owner()); // set as fee wallet

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        
        _isExcludedMaxTransactionAmount[owner()] = true;
        _isExcludedMaxTransactionAmount[address(this)] = true;
        _isExcludedMaxTransactionAmount[address(0xdead)] = true;
        
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply / 100 * 80);
        _mint(address(this), totalSupply / 100 * 20);
    }

    /**
    * @dev Once live, can never be switched off
    */
    function startTrading(uint256 number) external onlyOwner {
        tradingLive = true;
        _liveBlock = block.number.add(number);
    }

    /**
    * @dev Remove limits after token is somewhat stable
    */
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    /**
    * @dev Exclude from fee calculation
    */
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }
    
    /**
    * @dev Update token fees (max set to initial fee)
    */
    function updateFees(uint256 treasuryFee, uint256 liquidityFee) external onlyOwner {
        require(treasuryFee.add(liquidityFee) <= 7);

        _treasuryFee = treasuryFee;
        _liquidityFee = liquidityFee;
    }

    /**
    * @dev Update wallet that receives fees and newly added LP
    */
    function updatetreasuryWallet(address newWallet) external onlyOwner {
        _treasuryWallet = newWallet;
    }

    /**
    * @dev Very important function. 
    * Updates the threshold of how many tokens that must be in the contract calculation for fees to be taken
    */
    function updateSwapTokensThreshold(uint256 newThreshold) external onlyOwner returns (bool) {
  	    require(newThreshold >= totalSupply() * 1 / 100000, "Swap threshold cannot be lower than 0.001% total supply.");
  	    require(newThreshold <= totalSupply() * 5 / 1000, "Swap threshold cannot be higher than 0.5% total supply.");
  	    swapTokensThreshold = newThreshold;
  	    return true;
  	}

    /**
    * @dev Check if an address is excluded from the fee calculation
    */
    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    /**
    * @dev Can be used to block certain addresses (mainly for trading bots and sniping bots)
    */
    function blacklist(address[] memory addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            if (addresses[i] != uniswapV2Pair && addresses[i] != address(uniswapV2Router)) {
                _isBlacklisted[addresses[i]] = true;
            }
        }
    }
    
    /**
    * @dev Remove blacklisted addresses
    */
    function removeBlacklist(address[] memory addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            _isBlacklisted[addresses[i]] = false;
        }
    }
    
    /**
    * @dev Check if an address is blacklisted
    */
    function blacklisted(address addr) public view returns (bool) {
        return _isBlacklisted[addr];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlacklisted[from], "You have been blacklisted, you are unable to transfer or swap.");
        
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        // to stop sandwich bots
        if (to != owner() && to != address(uniswapV2Router) && to != address(uniswapV2Pair)){
            require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
            _holderLastTransferTimestamp[tx.origin] = block.number;
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
                if (_liveBlock >= block.number) _isBlacklisted[to] = true;

                // on buy
                if (_automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTransactionAmount, "_transfer:: Buy transfer amount exceeds the maxTransactionAmount.");
                    require(amount + balanceOf(to) <= maxWallet, "_transfer:: Max wallet exceeded");
                }
                
                // on sell
                else if (_automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxTransactionAmount, "_transfer:: Sell transfer amount exceeds the maxTransactionAmount.");
                }
                else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(amount + balanceOf(to) <= maxWallet, "_transfer:: Max wallet exceeded");
                }
            }
        }
        
        if (
            swappedTokens >= swapTokensThreshold &&
            !_swapping &&
            !_automatedMarketMakerPairs[from] &&
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
            (!_automatedMarketMakerPairs[from] && !_automatedMarketMakerPairs[to])
        ) takeFee = false;
        
        uint256 fees = 0;
        if (takeFee) {
            fees = amount.mul(totalFees).div(100);

            _tokensForLiquidity += fees * _liquidityFee / totalFees;
            _tokensForTreasury += fees * _treasuryFee / totalFees;

            // calculate how many tokens to add
        	swappedTokens += fees;
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

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _treasuryWallet,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 _swappedTokens = swappedTokens;
        uint256 totalTokensToSwap = _tokensForLiquidity + _tokensForTreasury;

        if (_swappedTokens == 0) return;
        if (_swappedTokens > swapTokensThreshold) _swappedTokens = swapTokensThreshold;

        uint256 liquidityTokens = _swappedTokens * _tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = _swappedTokens.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        // make sure that swapped tokens are updated
        swappedTokens -= liquidityTokens.add(amountToSwapForETH);

        _swapTokensForEth(amountToSwapForETH);
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForTreasury = ethBalance.mul(_tokensForTreasury).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance - ethForTreasury;

        _tokensForTreasury = 0;
        _tokensForLiquidity = 0;

        payable(_treasuryWallet).transfer(ethForTreasury);

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokens, ethForLiquidity);
        }
    }

    // allow anyone to transfer funds in contract to the treasury wallet
    function withdrawTreasuryFunds() external {
        payable(_treasuryWallet).transfer(address(this).balance);
    }

    receive() external payable {}
}