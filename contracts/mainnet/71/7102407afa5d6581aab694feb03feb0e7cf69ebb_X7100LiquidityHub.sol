/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*

 /$$   /$$ /$$$$$$$$       /$$$$$$$$ /$$
| $$  / $$|_____ $$/      | $$_____/|__/
|  $$/ $$/     /$$/       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$
 \  $$$$/     /$$/        | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
  >$$  $$    /$$/         | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
 /$$/\  $$  /$$/          | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
| $$  \ $$ /$$/           | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
|__/  |__/|__/            |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/

Contract: Smart Contract for managing X7100 fee tokens

This liquidity hub is shared by the X7100 series tokens (X7101-X7105).
It uses a simple liquidity balancing algorithm to add liquidity to the least liquified token.
It has been upgraded from the X7000 series to improve the gas for any individual trade.

This contract will NOT be renounced.

The following are the only functions that can be called on the contract that affect the contract:

    function setShares(uint256 distributeShare_, uint256 liquidityShare_, uint256 lendingPoolShare_, uint256 treasuryShare_) external onlyOwner {
        require(distributeShare + liquidityShare + lendingPoolShare + treasuryShare == 1000);

        require(distributeShare_ >= minShare && distributeShare_ <= maxShare);
        require(liquidityShare_ >= minShare && liquidityShare_ <= maxShare);
        require(lendingPoolShare_ >= minShare && lendingPoolShare_ <= maxShare);
        require(treasuryShare_ >= minShare && treasuryShare_ <= maxShare);

        distributeShare = distributeShare_;
        liquidityShare = liquidityShare_;
        lendingPoolShare = lendingPoolShare_;
        treasuryShare = treasuryShare_;

        emit SharesSet(distributeShare_, liquidityShare_, lendingPoolShare_, treasuryShare_);
    }

    function setRouter(address router_) external onlyOwner {
        require(router_ != address(router));
        router = IUniswapV2Router(router_);
        emit RouterSet(router_);
    }

    function setOffRampPair(address tokenAddress, address offRampPairAddress) external onlyOwner {
        require(nativeTokenPairs[tokenAddress] != offRampPairAddress);
        nativeTokenPairs[tokenAddress] = offRampPairAddress;
        emit OffRampPairSet(tokenAddress, offRampPairAddress);
    }

    function setBalanceThreshold(uint256 threshold) external onlyOwner {
        require(!balanceThresholdFrozen);
        balanceThreshold = threshold;
        emit BalanceThresholdSet(threshold);
    }

    function setLiquidityBalanceThreshold(uint256 threshold) external onlyOwner {
        require(!liquidityBalanceThresholdFrozen);
        liquidityBalanceThreshold = threshold;
        emit LiquidityBalanceThresholdSet(threshold);
    }

    function setLiquidityRatioTarget(uint256 liquidityRatioTarget_) external onlyOwner {
        require(liquidityRatioTarget_ != liquidityRatioTarget);
        require(liquidityRatioTarget_ >= minLiquidityRatioTarget && liquidityRatioTarget <= maxLiquidityRatioTarget);
        liquidityRatioTarget = liquidityRatioTarget_;
        emit LiquidityRatioTargetSet(liquidityRatioTarget_);
    }

    function setLiquidityTokenReceiver(address liquidityTokenReceiver_) external onlyOwner {
        require(
            liquidityTokenReceiver_ != address(0)
            && liquidityTokenReceiver_ != address(0x000000000000000000000000000000000000dEaD)
            && liquidityTokenReceiver != liquidityTokenReceiver_
        );

        address oldLiquidityTokenReceiver = liquidityTokenReceiver;
        liquidityTokenReceiver = liquidityTokenReceiver_;
        emit LiquidityTokenReceiverSet(oldLiquidityTokenReceiver, liquidityTokenReceiver_);
    }

    function setDistributionTarget(address target) external onlyOwner {
        require(
            target != address(0)
            && target != address(0x000000000000000000000000000000000000dEaD)
            && distributeTarget != payable(target)
        );
        require(!distributeTargetFrozen);
        address oldTarget = address(distributeTarget);
        distributeTarget = payable(target);
        emit DistributeTargetSet(oldTarget, distributeTarget);
    }

    function setLendingPoolTarget(address target) external onlyOwner {
        require(
            target != address(0) &&
            target != address(0x000000000000000000000000000000000000dEaD)
            && lendingPoolTarget != payable(target)
        );
        require(!lendingPoolTargetFrozen);
        address oldTarget = address(lendingPoolTarget);
        lendingPoolTarget = payable(target);
        emit LendingPoolTargetSet(oldTarget, target);
    }

    function setTreasuryTarget(address target) external onlyOwner {
        require(
            target != address(0)
            && target != address(0x000000000000000000000000000000000000dEaD)
            && treasuryTarget != payable(target)
        );
        require(!treasuryTargetFrozen);
        address oldTarget = address(treasuryTarget);
        treasuryTarget = payable(target);
        emit TreasuryTargetSet(oldTarget, target);
    }

    function freezeTreasuryTarget() external onlyOwner {
        require(!treasuryTargetFrozen);
        treasuryTargetFrozen = true;
        emit TreasuryTargetFrozen();
    }

    function freezeDistributeTarget() external onlyOwner {
        require(!distributeTargetFrozen);
        distributeTargetFrozen = true;
        emit DistributeTargetFrozen();
    }

    function freezeLendingPoolTarget() external onlyOwner {
        require(!lendingPoolTargetFrozen);
        lendingPoolTargetFrozen = true;
        emit LendingPoolTargetFrozen();
    }

    function freezeBalanceThreshold() external onlyOwner {
        require(!balanceThresholdFrozen);
        balanceThresholdFrozen = true;
        emit BalanceThresholdFrozen();
    }

    function freezeLiquidityBalanceThreshold() external onlyOwner {
        require(!liquidityBalanceThresholdFrozen);
        liquidityBalanceThresholdFrozen = true;
        emit LiquidityBalanceThresholdFrozen();
    }

These functions will be passed to DAO governance once the ecosystem stabilizes.

*/

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function circulatingSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswapV2Router {
    function WETH() external returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface ILiquidityHub {
    function processFees(address) external;
}

interface IX7EcosystemSplitter {
    function takeBalance() external;
}

interface IWETH {
    function withdraw(uint) external;
}

contract X7100LiquidityHub is Ownable, ILiquidityHub {

    IUniswapV2Router public router;

    address public liquidityTokenReceiver;

    // This is "equivalent" to 5-99%.
    // There really is only ~20m tokens circulating per (average number)
    // So a 198/200 is a 99 Percent
    uint256 public minLiquidityRatioTarget = 10;
    uint256 public maxLiquidityRatioTarget = 198;

    // For the constellation, the target liquidity is in the ~75% range to create extremely
    // low price slippage for parking of LP providing capital.
    uint256 public liquidityRatioTarget = 150;

    uint256 public minShare = 150;
    uint256 public maxShare = 400;

    uint256 public distributeShare = 300;
    uint256 public liquidityShare = 300;
    uint256 public lendingPoolShare = 250;
    uint256 public treasuryShare = 150;

    uint256 public balanceThreshold = 1 ether;
    uint256 public liquidityBalanceThreshold = 10**16;

    uint256 public distributeBalance;
    uint256 public lendingPoolBalance;
    uint256 public treasuryBalance;
    uint256 public liquidityBalance;
    mapping(address => uint256) public liquidityTokenBalance;

    address payable public distributeTarget;
    address payable public lendingPoolTarget;
    address payable public treasuryTarget;

    bool public distributeTargetFrozen;
    bool public lendingPoolTargetFrozen;
    bool public treasuryTargetFrozen;
    bool public balanceThresholdFrozen;
    bool public liquidityBalanceThresholdFrozen;
    bool public constellationTokensFrozen;

    address public leastLiquidTokenAddress;
    mapping(address => address) public nativeTokenPairs;
    mapping(address => bool) public isConstellationToken;

    event SharesSet(uint256 distributeShare, uint256 liquidityShare, uint256 lendingPoolShare, uint256 treasuryShare);
    event OffRampPairSet(address indexed token, address indexed offRampPair);
    event DistributeTargetSet(address indexed oldTarget, address indexed newTarget);
    event LendingPoolTargetSet(address indexed oldTarget, address indexed newTarget);
    event TreasuryTargetSet(address indexed oldTarget, address indexed newTarget);
    event LiquidityRatioTargetSet(uint256 liquidityRatioTarget);
    event LiquidityTokenReceiverSet(address indexed oldReciever, address indexed newReceiver);
    event BalanceThresholdSet(uint256 threshold);
    event LiquidityBalanceThresholdSet(uint256 threshold);
    event ConstellationTokenSet(address indexed tokenAddress, bool isQuint);
    event RouterSet(address router);
    event TreasuryTargetFrozen();
    event LendingPoolTargetFrozen();
    event DistributeTargetFrozen();
    event BalanceThresholdFrozen();
    event LiquidityBalanceThresholdFrozen();
    event ConstellationTokensFrozen();

    constructor(address router_) Ownable(address(0x7000a09c425ABf5173FF458dF1370C25d1C58105)) {
        router = IUniswapV2Router(router_);
        emit RouterSet(router_);
    }

    receive() external payable {}

    function setShares(uint256 distributeShare_, uint256 liquidityShare_, uint256 lendingPoolShare_, uint256 treasuryShare_) external onlyOwner {
        require(distributeShare + liquidityShare + lendingPoolShare + treasuryShare == 1000);

        require(distributeShare_ >= minShare && distributeShare_ <= maxShare);
        require(liquidityShare_ >= minShare && liquidityShare_ <= maxShare);
        require(lendingPoolShare_ >= minShare && lendingPoolShare_ <= maxShare);
        require(treasuryShare_ >= minShare && treasuryShare_ <= maxShare);

        distributeShare = distributeShare_;
        liquidityShare = liquidityShare_;
        lendingPoolShare = lendingPoolShare_;
        treasuryShare = treasuryShare_;

        emit SharesSet(distributeShare_, liquidityShare_, lendingPoolShare_, treasuryShare_);
    }

    function setRouter(address router_) external onlyOwner {
        require(router_ != address(router));
        router = IUniswapV2Router(router_);
        emit RouterSet(router_);
    }

    function setOffRampPair(address tokenAddress, address offRampPairAddress) external onlyOwner {
        require(nativeTokenPairs[tokenAddress] != offRampPairAddress);
        nativeTokenPairs[tokenAddress] = offRampPairAddress;
        emit OffRampPairSet(tokenAddress, offRampPairAddress);
    }

    function setBalanceThreshold(uint256 threshold) external onlyOwner {
        require(!balanceThresholdFrozen);
        balanceThreshold = threshold;
        emit BalanceThresholdSet(threshold);
    }

    function setLiquidityBalanceThreshold(uint256 threshold) external onlyOwner {
        require(!liquidityBalanceThresholdFrozen);
        liquidityBalanceThreshold = threshold;
        emit LiquidityBalanceThresholdSet(threshold);
    }

    function setLiquidityRatioTarget(uint256 liquidityRatioTarget_) external onlyOwner {
        require(liquidityRatioTarget_ != liquidityRatioTarget);
        require(liquidityRatioTarget_ >= minLiquidityRatioTarget && liquidityRatioTarget <= maxLiquidityRatioTarget);
        liquidityRatioTarget = liquidityRatioTarget_;
        emit LiquidityRatioTargetSet(liquidityRatioTarget_);
    }

    function setLiquidityTokenReceiver(address liquidityTokenReceiver_) external onlyOwner {
        require(
            liquidityTokenReceiver_ != address(0)
            && liquidityTokenReceiver_ != address(0x000000000000000000000000000000000000dEaD)
            && liquidityTokenReceiver != liquidityTokenReceiver_
        );

        address oldLiquidityTokenReceiver = liquidityTokenReceiver;
        liquidityTokenReceiver = liquidityTokenReceiver_;
        emit LiquidityTokenReceiverSet(oldLiquidityTokenReceiver, liquidityTokenReceiver_);
    }

    function setDistributionTarget(address target) external onlyOwner {
        require(
            target != address(0)
            && target != address(0x000000000000000000000000000000000000dEaD)
            && distributeTarget != payable(target)
        );
        require(!distributeTargetFrozen);
        address oldTarget = address(distributeTarget);
        distributeTarget = payable(target);
        emit DistributeTargetSet(oldTarget, distributeTarget);
    }

    function setLendingPoolTarget(address target) external onlyOwner {
        require(
            target != address(0) &&
            target != address(0x000000000000000000000000000000000000dEaD)
            && lendingPoolTarget != payable(target)
        );
        require(!lendingPoolTargetFrozen);
        address oldTarget = address(lendingPoolTarget);
        lendingPoolTarget = payable(target);
        emit LendingPoolTargetSet(oldTarget, target);
    }

    function setConstellationToken(address tokenAddress, bool isQuint) external onlyOwner {
        require(isConstellationToken[tokenAddress] != isQuint);
        isConstellationToken[tokenAddress] = isQuint;
        emit ConstellationTokenSet(tokenAddress, isQuint);
    }

    function setTreasuryTarget(address target) external onlyOwner {
        require(
            target != address(0)
            && target != address(0x000000000000000000000000000000000000dEaD)
            && treasuryTarget != payable(target)
        );
        require(!treasuryTargetFrozen);
        address oldTarget = address(treasuryTarget);
        treasuryTarget = payable(target);
        emit TreasuryTargetSet(oldTarget, target);
    }

    function freezeTreasuryTarget() external onlyOwner {
        require(!treasuryTargetFrozen);
        treasuryTargetFrozen = true;
        emit TreasuryTargetFrozen();
    }

    function freezeDistributeTarget() external onlyOwner {
        require(!distributeTargetFrozen);
        distributeTargetFrozen = true;
        emit DistributeTargetFrozen();
    }

    function freezeLendingPoolTarget() external onlyOwner {
        require(!lendingPoolTargetFrozen);
        lendingPoolTargetFrozen = true;
        emit LendingPoolTargetFrozen();
    }

    function freezeBalanceThreshold() external onlyOwner {
        require(!balanceThresholdFrozen);
        balanceThresholdFrozen = true;
        emit BalanceThresholdFrozen();
    }

    function freezeLiquidityBalanceThreshold() external onlyOwner {
        require(!liquidityBalanceThresholdFrozen);
        liquidityBalanceThresholdFrozen = true;
        emit LiquidityBalanceThresholdFrozen();
    }

    function freezeConstellationTokens() external onlyOwner {
        require(!constellationTokensFrozen);
        constellationTokensFrozen = true;
        emit ConstellationTokensFrozen();
    }

    function processFees(address tokenAddress) external {
        uint256 startingETHBalance = address(this).balance;

        uint256 tokensToSwap = IERC20(tokenAddress).balanceOf(address(this));

        bool processingConstellationToken = isConstellationToken[tokenAddress];

        if (processingConstellationToken) {
            tokensToSwap -= liquidityTokenBalance[tokenAddress];
        }

        if (tokensToSwap > 0) {
            swapTokensForEth(tokenAddress, tokensToSwap);
        }

        if (leastLiquidTokenAddress == address(0) && processingConstellationToken) {
            leastLiquidTokenAddress = tokenAddress;
        } else if (processingConstellationToken && tokenAddress != leastLiquidTokenAddress) {
            uint256 pairETHBalance = IERC20(router.WETH()).balanceOf(nativeTokenPairs[tokenAddress]);
            uint256 leastLiquidTokenPairETHBalance = IERC20(router.WETH()).balanceOf(nativeTokenPairs[leastLiquidTokenAddress]);

            if (pairETHBalance <= leastLiquidTokenPairETHBalance) {
                leastLiquidTokenAddress = tokenAddress;
            }
        }

        uint256 ETHForDistribution = address(this).balance - startingETHBalance;

        distributeBalance += ETHForDistribution * distributeShare / 1000;
        lendingPoolBalance += ETHForDistribution * lendingPoolShare / 1000;
        treasuryBalance += ETHForDistribution * treasuryShare / 1000;
        liquidityBalance = address(this).balance - distributeBalance - lendingPoolBalance - treasuryBalance;

        if (distributeBalance >= balanceThreshold) {
            sendDistributeBalance();
        }

        if (lendingPoolBalance >= balanceThreshold) {
            sendLendingPoolBalance();
        }

        if (treasuryBalance >= balanceThreshold) {
            sendTreasuryBalance();
        }

        if (liquidityBalance >= liquidityBalanceThreshold) {
            buyBackAndAddLiquidity(leastLiquidTokenAddress);
        }
    }

    function sendDistributeBalance() public {
        if (distributeTarget == address(0)) {
            return;
        }

        IX7EcosystemSplitter(distributeTarget).takeBalance();

        uint256 ethToSend = distributeBalance;
        distributeBalance = 0;

        (bool success,) = distributeTarget.call{value: ethToSend}("");

        if (!success) {
            distributeBalance = ethToSend;
        }
    }

    function sendTreasuryBalance() public {
        if (treasuryTarget == address(0)) {
            return;
        }

        uint256 ethToSend = treasuryBalance;
        treasuryBalance = 0;

        (bool success,) = treasuryTarget.call{value: ethToSend}("");

        if (!success) {
            treasuryBalance = ethToSend;
        }
    }

    function sendLendingPoolBalance() public {
        if (lendingPoolTarget == address(0)) {
            return;
        }

        uint256 ethToSend = lendingPoolBalance;
        lendingPoolBalance = 0;

        (bool success,) = lendingPoolTarget.call{value: ethToSend}("");

        if (!success) {
            lendingPoolBalance = ethToSend;
        }
    }

    function buyBackAndAddLiquidity(address tokenAddress) internal {
        uint256 ethForSwap;
        uint256 startingETHBalance = address(this).balance;

        IERC20 token = IERC20(tokenAddress);
        address offRampPair = nativeTokenPairs[tokenAddress];

        if (token.balanceOf(offRampPair) > token.circulatingSupply() * liquidityRatioTarget / 1000 ) {
            ethForSwap = liquidityBalance;
            liquidityBalance = 0;
            swapEthForTokens(tokenAddress, ethForSwap);
        } else {
            ethForSwap = liquidityBalance;
            liquidityBalance = 0;

            if (token.balanceOf(address(this)) > 0) {
                addLiquidityETH(tokenAddress, token.balanceOf(address(this)), ethForSwap);
                ethForSwap = ethForSwap - (startingETHBalance - address(this).balance);
            }

            if (ethForSwap > 0) {
                uint256 ethLeft = ethForSwap;
                ethForSwap = ethLeft / 2;
                uint256 ethForLiquidity = ethLeft - ethForSwap;
                swapEthForTokens(tokenAddress, ethForSwap);
                addLiquidityETH(tokenAddress, token.balanceOf(address(this)), ethForLiquidity);
            }
        }

        liquidityTokenBalance[tokenAddress] = token.balanceOf(address(this));

    }

    function addLiquidityETH(address tokenAddress, uint256 tokenAmount, uint256 ethAmount) internal {
        IERC20(tokenAddress).approve(address(router), tokenAmount);
        router.addLiquidityETH{value: ethAmount}(
            tokenAddress,
            tokenAmount,
            0,
            0,
            liquidityTokenReceiver,
            block.timestamp
        );
    }

    function swapTokensForEth(address tokenAddress, uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = router.WETH();

        IERC20(tokenAddress).approve(address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapEthForTokens(address tokenAddress, uint256 ethAmount) internal {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = tokenAddress;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function rescueWETH() external {
        address wethAddress = router.WETH();
        IWETH(wethAddress).withdraw(IERC20(wethAddress).balanceOf(address(this)));
    }
}