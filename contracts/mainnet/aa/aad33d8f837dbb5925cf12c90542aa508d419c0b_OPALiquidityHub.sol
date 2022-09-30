/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// File: erc-20.sol

pragma solidity ^0.8.15;

/*

Contract: Smart Contract for managing OPA fee tokens

The following are the only functions that can be called on the contract that affect the contract:

    function setShares(uint256 distributeShare_, uint256 liquidityShare_, uint256 treasuryShare_) external onlyOwner {
        require(distributeShare + liquidityShare + treasuryShare == 1000);

        require(distributeShare_ >= minShare && distributeShare_ <= maxShare);
        require(liquidityShare_ >= minShare && liquidityShare_ <= maxShare);
        require(treasuryShare_ >= minShare && treasuryShare_ <= maxShare);

        distributeShare = distributeShare_;
        liquidityShare = liquidityShare_;
        treasuryShare = treasuryShare_;

        emit SharesSet(distributeShare_, liquidityShare_, treasuryShare_);
    }

    function setRouter(address router_) external onlyOwner {
        require(router_ != address(router));
        router = IUniswapV2Router(router_);
        emit RouterSet(router_);
    }

    function setOffRampPair(address offRampPairAddress) external onlyOwner {
        require(offRampPair != offRampPairAddress);
        offRampPair = offRampPairAddress;
        emit OffRampPairSet(offRampPairAddress);
    }

    function setBalanceThreshold(uint256 threshold) external onlyOwner {
        require(!balanceThresholdFrozen);
        balanceThreshold = threshold;
        emit BalanceThresholdSet(threshold);
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

    function freezeBalanceThreshold() external onlyOwner {
        require(!balanceThresholdFrozen);
        balanceThresholdFrozen = true;
        emit BalanceThresholdFrozen();
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

interface IopaEcosystemSplitter {
    function takeBalance() external;
}

interface IWETH {
    function withdraw(uint) external;
}

contract OPALiquidityHub is Ownable, ILiquidityHub {

    IUniswapV2Router public router;
    address public offRampPair;

    IERC20 public opa;
    address public liquidityTokenReceiver;
    uint256 public minLiquidityRatioTarget = 5;
    uint256 public maxLiquidityRatioTarget = 99;

    uint256 public liquidityRatioTarget = 15;

    uint256 public minShare = 200;
    uint256 public maxShare = 500;

    uint256 public distributeShare = 300;
    uint256 public liquidityShare = 400;
    uint256 public treasuryShare = 300;

    uint256 public balanceThreshold = 1 ether;

    uint256 public distributeBalance;
    uint256 public treasuryBalance;
    uint256 public liquidityBalance;
    uint256 public opaLiquidityBalance;

    address payable public distributeTarget;
    address payable public treasuryTarget;

    bool public distributeTargetFrozen;
    bool public treasuryTargetFrozen;
    bool public balanceThresholdFrozen;

    event SharesSet(uint256 distributeShare, uint256 liquidityShare, uint256 treasuryShare);
    event OffRampPairSet(address indexed offRampPair);
    event DistributeTargetSet(address indexed oldTarget, address indexed newTarget);
    event TreasuryTargetSet(address indexed oldTarget, address indexed newTarget);
    event LiquidityRatioTargetSet(uint256 liquidityRatioTarget);
    event LiquidityTokenReceiverSet(address indexed oldReciever, address indexed newReceiver);
    event BalanceThresholdSet(uint256 threshold);
    event RouterSet(address router);
    event TreasuryTargetFrozen();
    event DistributeTargetFrozen();
    event BalanceThresholdFrozen();

    constructor(address IopaEcosystemSplitter, address router_) Ownable(address(0x0A4f3A75D3C039B79CDCea816e010890D7d68445)) {
        router = IUniswapV2Router(router_);
        opa = IERC20(opa);

        emit RouterSet(router_);
    }

    receive() external payable {}

    function setShares(uint256 distributeShare_, uint256 liquidityShare_, uint256 treasuryShare_) external onlyOwner {
        require(distributeShare + liquidityShare + treasuryShare == 1000);

        require(distributeShare_ >= minShare && distributeShare_ <= maxShare);
        require(liquidityShare_ >= minShare && liquidityShare_ <= maxShare);
        require(treasuryShare_ >= minShare && treasuryShare_ <= maxShare);

        distributeShare = distributeShare_;
        liquidityShare = liquidityShare_;
        treasuryShare = treasuryShare_;

        emit SharesSet(distributeShare_, liquidityShare_, treasuryShare_);
    }

    function setRouter(address router_) external onlyOwner {
        require(router_ != address(router));
        router = IUniswapV2Router(router_);
        emit RouterSet(router_);
    }

    function setOffRampPair(address offRampPairAddress) external onlyOwner {
        require(offRampPair != offRampPairAddress);
        offRampPair = offRampPairAddress;
        emit OffRampPairSet(offRampPairAddress);
    }

    function setBalanceThreshold(uint256 threshold) external onlyOwner {
        require(!balanceThresholdFrozen);
        balanceThreshold = threshold;
        emit BalanceThresholdSet(threshold);
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

    function freezeBalanceThreshold() external onlyOwner {
        require(!balanceThresholdFrozen);
        balanceThresholdFrozen = true;
        emit BalanceThresholdFrozen();
    }

    function processFees(address tokenAddress) external {
        uint256 startingETHBalance = address(this).balance;

        uint256 tokensToSwap = IERC20(tokenAddress).balanceOf(address(this));

        if (tokenAddress == address(opa)) {
            tokensToSwap -= opaLiquidityBalance;
        }

        if (tokensToSwap > 0) {
            swapTokensForEth(tokenAddress, tokensToSwap);
        }

        uint256 ETHForDistribution = address(this).balance - startingETHBalance;

        distributeBalance += ETHForDistribution * distributeShare / 1000;
        treasuryBalance += ETHForDistribution * treasuryShare / 1000;
        liquidityBalance = address(this).balance - distributeBalance - treasuryBalance;

        if (distributeBalance >= balanceThreshold) {
            sendDistributeBalance();
        }

        if (treasuryBalance >= balanceThreshold) {
            sendTreasuryBalance();
        }

        if (liquidityBalance >= balanceThreshold) {
            buyBackAndAddLiquidity();
        }
    }

    function sendDistributeBalance() public {
        if (distributeTarget == address(0)) {
            return;
        }

        IopaEcosystemSplitter(distributeTarget).takeBalance();

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

    function buyBackAndAddLiquidity() internal {
        uint256 ethForSwap;
        uint256 startingETHBalance = address(this).balance;

        if (opa.balanceOf(offRampPair) > opa.circulatingSupply() * liquidityRatioTarget / 100 ) {
            ethForSwap = liquidityBalance;
            liquidityBalance = 0;
            swapEthForTokens(ethForSwap);
        } else {
            ethForSwap = liquidityBalance;
            liquidityBalance = 0;

            if (opa.balanceOf(address(this)) > 0) {
                addLiquidityETH(opa.balanceOf(address(this)), ethForSwap);
                ethForSwap = ethForSwap - (startingETHBalance - address(this).balance);
            }

            if (ethForSwap > 0) {
                uint256 ethLeft = ethForSwap;
                ethForSwap = ethLeft / 2;
                uint256 ethForLiquidity = ethLeft - ethForSwap;
                swapEthForTokens(ethForSwap);
                addLiquidityETH(opa.balanceOf(address(this)), ethForLiquidity);
            }
        }

        opaLiquidityBalance = opa.balanceOf(address(this));

    }

    function addLiquidityETH(uint256 tokenAmount, uint256 ethAmount) internal {
        opa.approve(address(router), tokenAmount);
        router.addLiquidityETH{value: ethAmount}(
            address(opa),
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

    function swapEthForTokens(uint256 ethAmount) internal {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(opa);
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