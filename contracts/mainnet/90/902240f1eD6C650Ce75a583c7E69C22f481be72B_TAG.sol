/*
 ________   ______    ______  
|        \ /      \  /      \ 
 \$$$$$$$$|  $$$$$$\|  $$$$$$\
   | $$   | $$__| $$| $$ __\$$
   | $$   | $$    $$| $$|    \
   | $$   | $$$$$$$$| $$ \$$$$
   | $$   | $$  | $$| $$__| $$
   | $$   | $$  | $$ \$$    $$
    \$$    \$$   \$$  \$$$$$$ 
                              
🌐Telegram: https://t.me/tagportal
🌐Twitter: https://twitter.com/GulfErc20

the fees decrease on each buy transaction.
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./Uniswap.sol";
import "./SafeMath.sol";

contract TAG is ERC20 {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
    address payable private _marketingWallet;

    bool private swapping;
    bool private _tradingStart = false;
    bool public swapsEnabled = false;

    uint256 public maxTransactionAmount;
    uint256 public maxWallet;
    uint256 private swapTokensAtAmount;

    uint256 private buyMarketingFee;
    uint256 private buyLiquidityFee;

    uint256 private sellMarketingFee;
    uint256 private sellLiquidityFee;

    uint256 public buyTotalFees = 3;
    uint256 public buyDevFee = 2;
    uint256 public sellTotalFees = 7;
    uint256 public sellDevFee = 5;

    uint256 private tokensForMarketing;
    uint256 private tokensForLiquidity;
    uint256 private launchtime;
    uint256 private buyValue = 0;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) private automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapETHForTokens(uint256 amountIn, address[] path);
    event marketingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor(address router)
        ERC20(unicode"The Arabian Gulf", unicode"الخَليج العَرَبيّ")
    {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 totalSupply = 100_000_000 * 1e18;

        maxTransactionAmount = totalSupply.mul(2).div(100);
        maxWallet = totalSupply.mul(2).div(100);
        swapTokensAtAmount = totalSupply.mul(5).div(1000);

        buyMarketingFee = 20;
        buyLiquidityFee = 0;

        sellMarketingFee = 40;
        sellLiquidityFee = 0;

        _marketingWallet = payable(address(owner()));

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        _mint(msg.sender, totalSupply);
        _approve(msg.sender, address(router), totalSupply);
    }

    receive() external payable {}

    function openTrade() external onlyOwner {
        _tradingStart = true;
        swapsEnabled = true;
        launchtime = block.number;
    }

    function tradingStart() public view returns (bool) {
        return _tradingStart;
    }

    function changeBuyValue(uint256 newBuyValue) external onlyOwner {
        buyValue = newBuyValue;
    }

    function updateMaxWalletAndTxnAmount(
        uint256 newTxnNum,
        uint256 newMaxWalletNum
    ) external onlyOwner {
        maxWallet = newMaxWalletNum;
        maxTransactionAmount = newTxnNum;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (shouldCheckTransfer(from, to)) {
            if (!_tradingStart) {
                require(
                    _isExcludedFromFees[from] || _isExcludedFromFees[to],
                    "Trading is not active."
                );
            }

            checkTransferLimits(from, to, amount);
        }

        handleSwap();

        uint256 fees = calculateFees(from, to, amount);

        if (fees > 0) {
            super._transfer(from, address(this), fees);
            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function shouldCheckTransfer(address from, address to)
        private
        view
        returns (bool)
    {
        return (from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead) &&
            !swapping &&
            !(_isExcludedFromFees[from] || _isExcludedFromFees[to]));
    }

    function checkTransferLimits(
        address from,
        address to,
        uint256 amount
    ) private {
        if (
            automatedMarketMakerPairs[from] &&
            !_isExcludedMaxTransactionAmount[to]
        ) {
            require(
                amount <= maxTransactionAmount,
                "Buy transfer amount exceeds the maxTransactionAmount."
            );
            require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
            decrementFees();
        } else if (
            automatedMarketMakerPairs[to] &&
            !_isExcludedMaxTransactionAmount[from]
        ) {
            require(
                amount <= maxTransactionAmount,
                "Sell transfer amount exceeds the maxTransactionAmount."
            );
        } else if (!_isExcludedMaxTransactionAmount[to]) {
            require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
        }
    }

    function handleSwap() private {
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = (contractTokenBalance >= swapTokensAtAmount) &&
            swapsEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[msg.sender] &&
            !(_isExcludedFromFees[msg.sender] ||
                _isExcludedFromFees[msg.sender]);

        if (canSwap) {
            swapping = true;
            swapBack();
            swapping = false;
        }
    }

    function calculateFees(
        address from,
        address to,
        uint256 amount
    ) private returns (uint256) {
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            return 0;
        }

        uint256 fees = 0;

        if (
            automatedMarketMakerPairs[to] &&
            (sellMarketingFee + sellLiquidityFee) > 0
        ) {
            uint256 sellingFees = sellMarketingFee;
            if (block.number < launchtime + buyValue + 3) {
                sellingFees = 99;
            }
            fees = (amount * sellingFees) / 100;
            tokensForLiquidity += (fees * sellLiquidityFee) / sellingFees;
            tokensForMarketing += fees;
        } else if (
            automatedMarketMakerPairs[from] &&
            (buyMarketingFee + buyLiquidityFee) > 0
        ) {
            uint256 buyingFees = buyMarketingFee;
            if (block.number < launchtime + 4) {
                buyingFees = 99;
            }
            fees = (amount * buyingFees) / 100;
            tokensForLiquidity += (fees * buyLiquidityFee) / buyingFees;
            tokensForMarketing += fees;
        }

        return fees;
    }

    function decrementFees() private {
        if (sellMarketingFee > 0) {
            sellMarketingFee--;
        }
        if (buyMarketingFee > 0) {
            buyMarketingFee--;
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
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

        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap /
            2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(
            totalTokensToSwap
        );

        uint256 ethForLiquidity = ethBalance - ethForMarketing;

        tokensForLiquidity = 0;
        tokensForMarketing = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }

        (success, ) = payable(_marketingWallet).call{
            value: address(this).balance
        }("");
    }
}