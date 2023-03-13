/**
 * $REBIRTH - Rebirth From The Ashes
 *
 * Telegram: https://t.me/rebirthfromtheashes
 * Website: https://rebirthfromtheashes.xyz
 */

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.19;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract REBIRTH is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    string private constant _name = "Rebirth From The Ashes";
    string private constant _symbol = "REBIRTH";

    bool private swapping;
    bool public tradingActive = false;

    address public marketingWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    uint256 public buyTotalFees;
    uint256 private buyMarketingFee;
    uint256 private buyLiquidityFee;

    uint256 public sellTotalFees;
    uint256 private sellMarketingFee;
    uint256 private sellLiquidityFee;

    uint256 private tokensForMarketing;
    uint256 private tokensForLiquidity;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) private automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquidity(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

    constructor() ERC20(_name, _symbol) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 totalSupply = 100000000 * 10**decimals();

        maxTransactionAmount = (totalSupply * 2) / 100;
        maxWallet = (totalSupply * 2) / 100;
        swapTokensAtAmount = (totalSupply * 7) / 10000;

        buyMarketingFee = 10;
        buyLiquidityFee = 0;
        buyTotalFees = buyMarketingFee + buyLiquidityFee;

        sellMarketingFee = 20;
        sellLiquidityFee = 0;
        sellTotalFees = sellMarketingFee + sellLiquidityFee;

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        _mint(_msgSender(), totalSupply);
    }

    receive() external payable {}

    function openTrading() external onlyOwner {
        require(tradingActive == false, "The trading has been opened.");
        tradingActive = true;
    }

    function removeLimits() external onlyOwner {
        maxWallet = totalSupply();
        maxTransactionAmount = totalSupply();
    }

    function updateBuyFees(uint256 _marketing, uint256 _liquidity) external onlyOwner {
        buyMarketingFee = _marketing;
        buyLiquidityFee = _liquidity;
        buyTotalFees = buyMarketingFee + buyLiquidityFee;
        require(buyTotalFees <= 5, "Must keep buy total fees at 5% or less.");
    }

    function updateSellFees(uint256 _marketing, uint256 _liquidity) external onlyOwner {
        sellMarketingFee = _marketing;
        sellLiquidityFee = _liquidity;
        sellTotalFees = sellMarketingFee + sellLiquidityFee;
        require(sellTotalFees <= 5, "Must keep sell total fees at 5% or less.");
    }

    function updateMarketingWallet(address _marketingWallet) external onlyOwner {
        marketingWallet = _marketingWallet;
    }

    function excludeFromMaxTransaction(address updAds, bool excluded) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = excluded;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address.");
        require(to != address(0), "ERC20: transfer to the zero address.");
        require(amount > 0, "Transfer amount must be greater than zero.");

        if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping) {
            if (tradingActive == false) {
                require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "TOKEN: Trading is not active.");
            }

            if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                require(amount <= maxTransactionAmount, "TOKEN: Buy transfer amount exceeds the max Tnx amount.");
                require(amount + balanceOf(to) <= maxWallet, "TOKEN: Max wallet exceeded.");
            } else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                require(amount <= maxTransactionAmount, "TOKEN: Sell transfer amount exceeds the max Tnx amount.");
            } else if (!_isExcludedMaxTransactionAmount[to]) {
                require(amount + balanceOf(to) <= maxWallet, "TOKEN: Max wallet exceeded.");
            }
        }

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
        if (canSwap && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = !swapping;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForMarketing += (fees * sellMarketingFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }
        super._transfer(from, to, amount);
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
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            deadAddress,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(totalTokensToSwap);

        uint256 ethForLiquidity = ethBalance - ethForMarketing;

        tokensForLiquidity = 0;
        tokensForMarketing = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquidity(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }

        (success, ) = address(marketingWallet).call{value: address(this).balance}("");
    }
}