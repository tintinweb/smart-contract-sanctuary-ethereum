pragma solidity ^0.8.17;

// SPDX-License-Identifier: Apache-2.0

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWN0kkOKNWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMWXOo;.  ..;oOXWMMMMMMMMMMMMM
// MMMMMMMMWNKxc'. .';;,.. .'cxKNWMMMMMMMMM
// Kk0NMWXOo;.  .;lkKWNXKkl,.  .;oOXWMMMMMM
// x..;cc'. ..:d0NWWNXXXNWWN0d:.. .,lkKNMMM
// d.    .,lkKNWWXOo;..,;oOXWWNKkl,. ..:xXM
// d.  ,d0XWWN0xc,.       .,lkKNWWXOo;...kW
// d. .dNWMMWKo'             ..:dKWMWNKxd0W
// d.  .cx0NWWN0d:..             cXMMMMMWMM
// x.     .;oOXWWNKkl,..         'kXWMMMMMM
// 0l'.      .,cxKNWWX0kd:.       .,lkKWWMM
// MWXko;.       .:oOXWMWNKxl,.      .'cxXM
// MMMMWX0o.        .,ldkKNWWXOd:.      'kW
// MMMMMMMK;            .':dOXWWN0xc'.  .xW
// KO0NWMMNk:'.             .;xXMMMWKl. .xW
// x..;oOXWWNKkl,.         .,lONWMWKk:. .xW
// 0c.. .,lxKNWWXOd:....':d0XWWN0xc'.   .xW
// WNKkc,....:dOXWWNKOOOKNWWXOo;....,lo:cOW
// MMMMWXOo:....,lkKNWWWNKxc,. ..:dOXWWNNWM
// MMMMMMMWNKxc,. .':ool:.. .,ckKNMMMMMMMMM
// MMMMMMMMMMMWXOo;..   ..:oOXWMMMMMMMMMMMM
// MMMMMMMMMMMMMMWN0xlloxKNWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//
// This contract is property of Syntech
// All rights reserved - 2023

import "./SafeMath.sol";
import "./Address.sol";
import "./RewardsToken.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./IRewardsTracker.sol";

contract SynergyDAO is RewardsToken {
    using SafeMath for uint256;
    using Address for address;
    
    // Supply, limits and fees
    uint256 private constant REWARDS_TRACKER_IDENTIFIER = 2;
    uint256 private constant TOTAL_SUPPLY = 100000000000000 * (10**9);

    uint256 public maxTxAmount = TOTAL_SUPPLY.mul(20).div(1000); // 2%
    uint256 public maxWalletSize = TOTAL_SUPPLY.mul(20).div(1000); // 2%

    uint256 private platformFee = 100; //  1%
    uint256 private _previousPlatformFee = platformFee;

    uint256 public devFee = 300; // 3%
    uint256 public sellDevFee = 300; // 3%
    uint256 private _previousDevFee = devFee;
    
    uint256 public rewardsFee = 400; // 4%
    uint256 public sellRewardsFee = 400; // 4%
    uint256 private _previousRewardsFee = rewardsFee;

    uint256 public liquidityFee = 200; // 2%
    uint256 public sellLiquidityFee = 400; // 4%
    uint256 private _previousLiquidityFee = liquidityFee;

    uint256 public launchSellFee = 1500; // 15%
    uint256 private _previousLaunchSellFee = launchSellFee;

    address payable private _platformWalletAddress =
        payable(0x4b15a453B0a89Ef57eFfccbc1ff74e11DCFae7DF);
    address payable private _devWalletAddress =
        payable(0xE18CF66cb533E623BF7fb1Ea708e34021684E350);

    uint256 public launchSellFeeDeadline = 0;

    IRewardsTracker private _rewardsTracker;

    // Fallback to generic transfer. On by default
    bool public useGenericTransfer = true;

    // Prepared for launch
    bool private preparedForLaunch = false;
    
    // Exclusions
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMaxTx;
    
    // Token -> ETH swap support
    IUniswapV2Router public uniswapV2Router;
    address public uniswapV2Pair;

    bool currentlySwapping;
    bool public swapAndRedirectEthFeesEnabled = true;

    uint256 private minTokensBeforeSwap = 1000000000 * 10**9;

    // Events and modifiers
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndRedirectEthFeesUpdated(bool enabled);
    event OnSwapAndRedirectEthFees(
        uint256 tokensSwapped,
        uint256 ethToDevWallet
    );
    event MaxTxAmountUpdated(uint256 maxTxAmount);
    event MaxWalletSizeUpdated(uint256 maxWalletSize);
    event GenericTransferChanged(bool useGenericTransfer);
    event ExcludeFromFees(address wallet);
    event IncludeInFees(address wallet);
    event DevWalletUpdated(address newDevWallet);
    event RewardsTrackerUpdated(address newRewardsTracker);
    event RouterUpdated(address newRouterAddress);
    event FeesChanged(
        uint256 newDevFee,
        uint256 newSellDevFee,
        uint256 newRewardsFee,
        uint256 newSellRewardsFee,
        uint256 newLiquidtyFee,
        uint256 newSellLiquidityFee
    );
    event LaunchFeeUpdated(uint256 newLaunchSellFee);

    modifier lockTheSwap() {
        currentlySwapping = true;
        _;
        currentlySwapping = false;
    }

    constructor() ERC20("Synergy DAO", "SYN") {
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        // mint supply
        _mint(owner(), TOTAL_SUPPLY);

        // exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        // internal exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        
        // exclude from rewards
        excludeFromRewards(address(this));
        excludeFromRewards(address(0xdead));
        excludeFromRewards(uniswapV2Pair);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // launch preparation
        require(preparedForLaunch || _msgSender() == owner(), "Contract has not been prepared for launch and user is not owner");

        // fallback implementation
        if (useGenericTransfer) {
            super._transfer(from, to, amount);
            return;
        }

        if(to != uniswapV2Pair) {
            require(balanceOf(to) + amount < maxWalletSize, "Balance exceeds max wallet size");
        }

        if (
            !_isExcludedFromMaxTx[from] &&
            !_isExcludedFromMaxTx[to] // by default false
        ) {
            require(
                amount <= maxTxAmount,
                "Transfer amount exceeds the maxTxAmount"
            );
        }

        // sell fees
        uint256 baseRewardsFee = rewardsFee;
        uint256 baseDevFee = devFee;
        uint256 baseLiquidityFee = liquidityFee;
        if (to == uniswapV2Pair) {
            devFee = sellDevFee;
            rewardsFee = sellRewardsFee;
            liquidityFee = sellLiquidityFee;

            if (launchSellFeeDeadline >= block.timestamp) {
                devFee = devFee.add(launchSellFee);
            }
        }

        // start swap to ETH
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= minTokensBeforeSwap;
        if (
            overMinTokenBalance &&
            !currentlySwapping &&
            from != uniswapV2Pair &&
            swapAndRedirectEthFeesEnabled
        ) {
            // add dev fee
            swapAndRedirectEthFees(contractTokenBalance);
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            removeAllFee();
        }

        (uint256 tTransferAmount, uint256 tFee) = _getValues(amount);
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(tTransferAmount);

        _takeFee(tFee);

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            restoreAllFee();
        }

        // restore fees
        devFee = baseDevFee;
        rewardsFee = baseRewardsFee;
        liquidityFee = baseLiquidityFee;

        emit Transfer(from, to, tTransferAmount);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _getValues(uint256 tAmount)
        private
        view
        returns (uint256, uint256)
    {
        uint256 tFee = calculateFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _takeFee(uint256 fee) private {
        _balances[address(this)] = _balances[address(this)].add(fee);
    }

    function calculateFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        uint256 totalFee = devFee.add(rewardsFee).add(liquidityFee).add(platformFee);
        return _amount.mul(totalFee).div(10000);
    }

    function removeAllFee() private {
        if (devFee == 0 && rewardsFee == 0 && platformFee == 0 && liquidityFee == 0) return;

        _previousPlatformFee = platformFee;
        _previousDevFee = devFee;
        _previousRewardsFee = rewardsFee;
        _previousLiquidityFee = liquidityFee;

        platformFee = 0;
        devFee = 0;
        rewardsFee = 0;
        liquidityFee = 0;
    }

    function restoreAllFee() private {
        platformFee = _previousPlatformFee;
        devFee = _previousDevFee;
        rewardsFee = _previousRewardsFee;
        liquidityFee = _previousLiquidityFee;
    }

    function swapAndRedirectEthFees(uint256 contractTokenBalance)
        private
        lockTheSwap
    {
        uint256 totalRedirectFee = devFee.add(rewardsFee).add(liquidityFee).add(platformFee);
        if (totalRedirectFee == 0) return;
        
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the fee events include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // add liquidity
        uint256 liquidityTokenBalance = contractTokenBalance.mul(liquidityFee).div(totalRedirectFee);

        // split the liquidity balance into halves
        uint256 halfLiquidity = liquidityTokenBalance.div(2);

        // swap tokens for ETH
        uint256 adjustedTokenBalance = contractTokenBalance.sub(halfLiquidity);
        swapTokensForEth(adjustedTokenBalance);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        if (newBalance > 0) {
            // send to liquidity 
            uint256 liquidityEthBalance = newBalance.mul(liquidityFee.div(2)).div(totalRedirectFee);
            addLiquidity(halfLiquidity, liquidityEthBalance);

            // send to platform wallet
            uint256 platformBalance = newBalance.mul(platformFee).div(totalRedirectFee);
            sendEthToWallet(_platformWalletAddress, platformBalance);

            //
            // send to rewards wallet
            //
            uint256 rewardsBalance = newBalance.mul(rewardsFee).div(totalRedirectFee);
            if (rewardsBalance > 0 && address(_rewardsTracker) != address(0)) {
                try _rewardsTracker.addAllocation{value: rewardsBalance}(REWARDS_TRACKER_IDENTIFIER) {} catch {}
            }
            
            //
            // send to dev wallet
            //
            uint256 devBalance = newBalance.mul(devFee).div(totalRedirectFee);
            sendEthToWallet(_devWalletAddress, devBalance);

            emit OnSwapAndRedirectEthFees(contractTokenBalance, newBalance);
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount} (
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function sendEthToWallet(address wallet, uint256 amount) private {
        if (amount > 0) {
            payable(wallet).transfer(amount);
        }
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

    function prepareForLaunch() external onlyOwner {
        require(!preparedForLaunch, "Already prepared for launch");

        // ready for launch
        preparedForLaunch = true;

        // sell penalty for the time specified below
        launchSellFeeDeadline = block.timestamp + 2 days;
    }

    function setUseGenericTransfer(bool genericTransfer) external onlyOwner {
        useGenericTransfer = genericTransfer;
        emit GenericTransferChanged(genericTransfer);
    }
    
    // for 0.5% input 5, for 1% input 10
    function setMaxTxPercent(uint256 newMaxTx) external onlyOwner {
        require(newMaxTx >= 5, "Max TX should be above 0.5%");
        maxTxAmount = TOTAL_SUPPLY.mul(newMaxTx).div(1000);
        emit MaxTxAmountUpdated(maxTxAmount);
    }

    // for 0.5% input 5, for 1% input 10
    function setMaxWalletSize(uint256 newMaxWallet) public onlyOwner {
        require(newMaxWallet >= 1, "Max wallet size should be above 0.1%");
        maxWalletSize = TOTAL_SUPPLY.mul(newMaxWallet).div(1000);
        emit MaxWalletSizeUpdated(maxWalletSize);
    }
    
    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFees(account);
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludeInFees(account);
    }

    function setFees(
        uint256 newDevFee,
        uint256 newSellDevFee,
        uint256 newRewardsFee,
        uint256 newSellRewardsFee,
        uint256 newLiquidtyFee,
        uint256 newSellLiquidityFee
    ) external onlyOwner {
        require(
            newDevFee <= 1000 &&
            newSellDevFee <= 1000 &&
            newRewardsFee <= 1000 &&
            newSellRewardsFee <= 1000 &&
            newLiquidtyFee <= 1000 &&
            newSellLiquidityFee <= 1000,
            "Fees exceed maximum allowed value"
        );
        devFee = newDevFee;
        sellDevFee = newSellDevFee;
        rewardsFee = newRewardsFee;
        sellRewardsFee = newSellRewardsFee;
        liquidityFee = newLiquidtyFee;
        sellLiquidityFee = newSellLiquidityFee;
        emit FeesChanged(newDevFee, newSellDevFee, newRewardsFee, newSellRewardsFee, newLiquidtyFee, newSellLiquidityFee);
    }

    function setLaunchSellFee(uint256 newLaunchSellFee) external onlyOwner {
        require(newLaunchSellFee <= 2500, "Maximum launch sell fee is 25%");
        launchSellFee = newLaunchSellFee;
        emit LaunchFeeUpdated(newLaunchSellFee);
    }

    function setDevWallet(address payable newDevWallet)
        external
        onlyOwner
    {
        _devWalletAddress = newDevWallet;
        emit DevWalletUpdated(newDevWallet);
    }
    
    function setRewardsTracker(address payable newRewardsTracker)
        external
        onlyOwner
    {
        _rewardsTracker = IRewardsTracker(newRewardsTracker);
        emit RewardsTrackerUpdated(newRewardsTracker);
    }

    function setRouterAddress(address newRouter) external onlyOwner {
        IUniswapV2Router _newUniswapRouter = IUniswapV2Router(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_newUniswapRouter.factory())
            .createPair(address(this), _newUniswapRouter.WETH());
        uniswapV2Router = _newUniswapRouter;
        emit RouterUpdated(newRouter);
    }

    function setSwapAndRedirectEthFeesEnabled(bool enabled) external onlyOwner {
        swapAndRedirectEthFeesEnabled = enabled;
        emit SwapAndRedirectEthFeesUpdated(enabled);
    }

    function setMinTokensBeforeSwap(uint256 minTokens) external onlyOwner {
        minTokensBeforeSwap = minTokens * 10**9;
        emit MinTokensBeforeSwapUpdated(minTokens);
    }
    
    // emergency claim functions
    function manualSwap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualSend() external onlyOwner {
        uint256 contractEthBalance = address(this).balance;
        sendEthToWallet(_devWalletAddress, contractEthBalance);
    }
}