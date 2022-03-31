// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract TREASURE is ERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    uint256 public _totalSupply = 1e9 * 1e18; // 1 B tokens
    uint256 public swapTokensAtAmount = 1e6 * 1e18; // 1M = Threshold for swap (0.1%)
    uint256 public maxWalletHoldings = 3e6 * 1e18; // 0.3% max wallet holdings (mutable)
    
    address public marketingAddress;
    uint256 public marketingFee = 4;

    address public treasuryAddress;
    uint256 public treasuryFee = 0;

    uint256 public liquidityBuyFee = 0;
    uint256 public liquiditySellFee = 25;

    address private devAddress;
    address private lpAddress;

    bool public _hasLiqBeenAdded = false;

    uint256 public launchedAt = 0;

    uint256 public swapAndLiquifycount = 0;
    uint256 public snipersCaught = 0;

    mapping(address => bool) private whitelisted;
    mapping(address => bool) public blacklisted;
    bool private swapping;
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event AddToWhitelist(address indexed account, bool isWhitelisted);
    event AddToBlacklist(address indexed account, bool isBlacklisted);
    event MarketingAddressUpdated(
        address indexed newMarketingWallet,
        address indexed oldMarketingWallet
    );
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    receive() external payable {}

    constructor(
        address _marketingAddress,
        address _treasuryAdress,
        address _devAddress,
        address _lpAddress,
        address _uniswapAddress
    ) ERC20("T20Token", "T20") {
        marketingAddress = _marketingAddress;
        treasuryAddress = _treasuryAdress;
        devAddress = _devAddress;
        lpAddress = _lpAddress;

        // Set Uniswap Address
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            address(_uniswapAddress)
        );

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        whitelist(address(this), true);
        whitelist(owner(), true);
        whitelist(marketingAddress, true);
        whitelist(treasuryAddress, true);
        super._mint(owner(), _totalSupply);
    }

    /**
     * ADMIN SETTINGS
     */

    function updateAddresses(address newmarketingAddress, address newLpAddress)
        public
        onlyOwner
    {
        whitelist(newmarketingAddress, true);
        whitelist(newLpAddress, true);
        emit MarketingAddressUpdated(newmarketingAddress, marketingAddress);
        marketingAddress = newmarketingAddress;
        lpAddress = newLpAddress;
    }

    function updateMarketingVariables(
        uint256 _marketingFee,
        uint256 _swapTokensAtAmount,
        uint256 _liquidityBuyFee,
        uint256 _liquiditySellFee,
        uint256 _maxWalletHoldings
    ) public onlyOwner {
        marketingFee = _marketingFee;
        swapTokensAtAmount = _swapTokensAtAmount;
        liquidityBuyFee = _liquidityBuyFee;
        liquiditySellFee = _liquiditySellFee;
        maxWalletHoldings = _maxWalletHoldings;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "TREASURE: The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function swapAndSendDividendsAndLiquidity(uint256 tokens) private {
        uint256 totalFeeBps = (liquiditySellFee.add(liquidityBuyFee)).mul(100).div(2)
            .add(marketingFee.add(treasuryFee).mul(100));

        // Handle Marketing & Treasury Fee
        uint256 marketingTreasuryBps = (marketingFee.add(treasuryFee)).mul(10000).div(totalFeeBps);
        uint256 tokensForMarketingTreasury = tokens.mul(marketingTreasuryBps).div(100);

        //Handle Liquidity Fee
        uint256 tokensForLiquify = tokens.sub(tokensForMarketingTreasury);

        swapTokensForEth(tokensForMarketingTreasury);

        uint256 dividends = address(this).balance;

        (bool successMarketing, ) = address(marketingAddress).call{
            value: address(this).balance.mul(marketingFee).div(marketingFee.add(treasuryFee))
        }("");
        (bool successTreasury, ) = address(treasuryAddress).call{
            value: address(this).balance.mul(treasuryFee).div(marketingFee.add(treasuryFee))
        }("");
        require(successMarketing && successTreasury, "Error Sending tokens");
        emit SendDividends(tokens, dividends);
        swapAndLiquify(tokensForLiquify);
        swapAndLiquifycount = swapAndLiquifycount.add(1);
    }

    function manualSwapandLiquify(uint256 _balance) external onlyOwner {
        swapAndSendDividendsAndLiquidity(_balance);
    }

    function swapAndLiquify(uint256 contractTokenBalance) internal {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half);

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity
        addLiquidity(otherHalf, newBalance);
        initialBalance = address(this).balance;
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!blacklisted[from], "TREASURE: Blocked Transfer");

        // Sniper Protection
        if (!_hasLiqBeenAdded) {
            // If no liquidity yet, allow owner to add liquidity
            _checkLiquidityAdd(from, to);
        } else {
            // if liquidity has already been added.
            if (
                launchedAt > 0 &&
                from == uniswapV2Pair &&
                devAddress != from &&
                devAddress != to
            ) {
                if (block.number - launchedAt < 10) {
                    _blacklist(to, true);
                    snipersCaught++;
                }
            }
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if (
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != marketingAddress &&
            to != marketingAddress
        ) {
            swapping = true;
            swapAndSendDividendsAndLiquidity(swapTokensAtAmount);
            swapping = false;
        }
        bool takeFee = !swapping;
        // if any account is whitelisted account then remove the fee

        if (whitelisted[from] || whitelisted[to]) {
            takeFee = false;
        }

        if (takeFee) {
            if (!automatedMarketMakerPairs[to]) {
                require(
                    balanceOf(address(to)).add(amount) < maxWalletHoldings,
                    "Max Wallet Limit"
                );
            }
            uint256 fees = amount.mul(marketingFee.add(treasuryFee)).div(100);
            if (automatedMarketMakerPairs[from]) {
                fees = fees.add(amount.mul(liquidityBuyFee).div(100));
            } else {
                fees = fees.add(amount.mul(liquiditySellFee).div(100));
            }
            amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
        }
        super._transfer(from, to, amount);
    }

    function _checkLiquidityAdd(address from, address to) private {
        // if liquidity is added by the _liquidityholders set
        // trading enables to true and start the anti sniper timer
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        // require liquidity has been added == false (not added).
        // This is basically only called when owner is adding liquidity.

        if (from == devAddress && to == uniswapV2Pair) {
            _hasLiqBeenAdded = true;
            launchedAt = block.number;
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            lpAddress,
            block.timestamp
        );
    }

    function whitelist(address account, bool isWhitelisted) public onlyOwner {
        whitelisted[account] = isWhitelisted;
        emit AddToWhitelist(account, isWhitelisted);
        (account, isWhitelisted);
    }

    function blacklist(address account, bool isBlacklisted) public onlyOwner {
        _blacklist(account, isBlacklisted);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() public onlyOwner {
        launchedAt = block.number;
        _hasLiqBeenAdded = true;
    }

    /**********/
    /* PRIVATE FUNCTIONS */
    /**********/

    function _blacklist(address account, bool isBlacklisted) private {
        blacklisted[account] = isBlacklisted;
        emit AddToBlacklist(account, isBlacklisted);
        (account, isBlacklisted);
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

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "TREASURE: The Uniswap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "TREASURE: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
}