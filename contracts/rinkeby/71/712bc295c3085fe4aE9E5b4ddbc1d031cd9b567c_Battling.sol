pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicense

import "./Ownable.sol";
import "./SafeMath.sol";
import "./MathUpgradeable.sol";

import "./BattlingBase.sol";
import "./BattlingExtension.sol";
import "./ERC1155Holder.sol";

import "./IFortunasToken.sol";
import "./IFortunasAssets.sol";
import "./IPancakeFactory.sol";
import "./IPancakeRouter02.sol";
import "./IPancakePair.sol";

contract Battling is BattlingBase, ERC1155Holder {
    using SafeMath for uint256;
    using MathUpgradeable for uint256;

    // BUSD mainnet
    // address public BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    // TODO remove
    address public BUSD;

    // PancakeSwap
    IPancakeRouter02 public pancakeRouter;
    IPancakePair public pancakePair;

    // LP Token for FRTNA-BUSD pair
    IERC20 public LPToken;

    // FRTNA
    IFortunasToken public fortunasToken;

    // Fortunas Multi Token for heroes and cavalry
    IFortunasAssets public fortunasAssets;

    // Contract that handles calculations for Battling
    BattlingExtension public battlingExtension;

    // Treasury wallet
    address public treasuryWallet;

    // Reward wallet
    address public rewardWallet;

    // Initial cost of supplies to send troops to battle
    uint256 public suppliesCost;

    // Initial staked tokens percentage at which battle resets
    uint256 public battleResetPercentage;

    // Each hero's/cavalry's effect on current/total battle APY
    uint256[10] public assetPercentages;

    // Percentage cost of LP for purchasing each hero/cavalry
    uint256[10] public assetPrices;

    // Percentage cost of LP for purchasing a random hero
    uint256 public randomAssetPrice;

    // Percentage chance of losing hero/cavalry in a battle that is being ended or having tokens removed
    uint256 public baseChanceToLoseAssets;

    // mappings

    mapping (address => mapping(uint8 => Battle)) battleForAddress;

    // events

    event UpdatedTreasuryWallet(address indexed newTreasuryWallet, address indexed oldTreasuryWallet);

    event UpdatedRewardWallet(address indexed newRewardWallet, address indexed oldRewardWallet);

    event UpdatedBattleResetPercentage(uint256 newBattleResetPercentage, uint256 oldBattleResetPercentage);

    event EndedBattle(
        address indexed user,
        uint256 battleType,
        uint256 initialTokensStaked,
        uint256 additionalTokens,
        uint256 rewards,
        uint256 passiveRewards,
        uint256 battleStartTime,
        uint256 battleDurationInDays
    );

    event PurchasedAsset(address indexed user, uint256 asset, uint256 amount);

    event LostAsset(address indexed user, uint256 asset, uint256 amount);

    // constructor

    constructor(address _fortunasToken, address _fortunasAssets) {
        // TODO remove
        BUSD = 0x7D9385C733a967793EE14D933212ee44025f1B9d;

        // PancakeRouter02 mainnet
        // IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        // TODO remove
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _addressForPancakePair = IPancakeFactory(_pancakeRouter.factory()).getPair(_fortunasToken, BUSD);

        pancakeRouter = _pancakeRouter;
        pancakePair = IPancakePair(_addressForPancakePair);

        LPToken = IERC20(_addressForPancakePair);

        fortunasToken = IFortunasToken(_fortunasToken);

        fortunasAssets = IFortunasAssets(_fortunasAssets);

        battlingExtension = new BattlingExtension();

        // TODO change
        treasuryWallet = 0x49A61ba8E25FBd58cE9B30E1276c4Eb41dD80a80;

        // TODO change
        rewardWallet = 0x3edCe801a3f1851675e68589844B1b412EAc6B07;

        suppliesCost = 20000;

        battleResetPercentage = 200;

        assetPercentages = [20, 40, 60, 80, 100,
                            101, 102, 103, 104, 105];

        assetPrices = [2500, 5000, 7500, 10000, 12500,
                        2500, 5000, 7500, 10000, 12500];

        randomAssetPrice = 5000;

        baseChanceToLoseAssets = 50;
    }

    // getters and setters

    function getBattleForAddress(address _user, uint8 _battleType) external view returns (Battle memory) {
        return battleForAddress[_user][_battleType];
    }

    function updateTreasuryWallet(address _treasuryWallet) external onlyOwner {
        require(treasuryWallet != _treasuryWallet, "updateTreasuryWallet::TW");
        emit UpdatedTreasuryWallet(_treasuryWallet, treasuryWallet);
        treasuryWallet = _treasuryWallet;
    }

    function updateRewardWallet(address _rewardWallet) external onlyOwner {
        require(rewardWallet != _rewardWallet, "updateRewardWallet::RW");
        emit UpdatedRewardWallet(_rewardWallet, rewardWallet);
        rewardWallet = _rewardWallet;
    }

    function updateBattleResetPercentage(uint256 _battleResetPercentage) external onlyOwner {
        require(battleResetPercentage != _battleResetPercentage, "updateBattleResetPercentage::BRP");
        emit UpdatedBattleResetPercentage(_battleResetPercentage, battleResetPercentage);
        battleResetPercentage = _battleResetPercentage;
    }

    // functions

    function startBattle(
        uint256 _amount,
        uint8 _battleType
    ) external {
        require(_amount >= minStakeAmount[_battleType - 1], "startBattle::MIN");
        require(2 <= _battleType && _battleType <= 6, "startBattle::WBT1");
        require(battleForAddress[msg.sender][_battleType].initialTokensStaked == 0, "startBattle::BAS");

        if (_battleType == 2) {
            LPToken.transferFrom(msg.sender, address(this), _amount);
        }
        else {
            uint256 supplies = _amount.mul(suppliesCost).div(multiplier);
            _amount -= supplies;

            fortunasToken.transferFrom(msg.sender, treasuryWallet, supplies);

            fortunasToken.transferFrom(msg.sender, address(this), _amount);
        }

        battleForAddress[msg.sender][_battleType] = Battle(_battleType, _amount, 0, 0, 0, 0, rewardPercentagesPerCycle[_battleType - 1], toCollectPercentages[_battleType - 1], 0, 0, block.timestamp, 0, 0, 0, 0, 0);
    }

    function sendRations(
        uint256 _rationDays,
        uint8 _battleType
    ) external validBattleType(_battleType) validBattle(_battleType) {
        Battle memory tempBattle = battleForAddress[msg.sender][_battleType];

        require(1 <= _rationDays && _rationDays <= 5, "sendRations::WR1");

        if (tempBattle.rationsDaysTotal != 0) {
            uint256 battleDaysTotal = tempBattle.rationsDaysTotal.add(3);

            uint256 daysWagingBattle;
            if (block.timestamp.sub(tempBattle.battleStartTime).div(oneDayTime) <= 3) {
                daysWagingBattle = 3;
            }
            else {
                daysWagingBattle = block.timestamp.sub(tempBattle.battleStartTime).ceilDiv(oneDayTime);
            }

            uint256 unusedRations = battleDaysTotal.sub(daysWagingBattle);
            uint256 rationsAcceptable = uint256(5).sub(unusedRations);

            require(_rationDays <= rationsAcceptable, "sendRations::WR2");
        }

        tempBattle = battlingExtension.calculateRewards(tempBattle);

        uint256 tempRations = battlingExtension.calculateRations(tempBattle, _rationDays);

        fortunasToken.burn(msg.sender, tempRations);

        tempBattle.rations += tempRations;
        tempBattle.rationsDaysTotal += _rationDays;

        battleForAddress[msg.sender][_battleType] = tempBattle;
    }

    function addTroops(
        uint256 _amountToAdd,
        uint8 _battleType
    ) external validBattleType(_battleType) validBattle(_battleType) {
        Battle memory tempBattle = battleForAddress[msg.sender][_battleType];

        tempBattle = battlingExtension.calculateRewards(tempBattle);

        uint256 supplies = _amountToAdd.mul(suppliesCost).div(multiplier);
        _amountToAdd -= supplies;

        fortunasToken.transferFrom(msg.sender, treasuryWallet, supplies);

        fortunasToken.transferFrom(msg.sender, address(this), _amountToAdd);

        tempBattle.additionalTokens += _amountToAdd;
        if (
            tempBattle.additionalTokens >
            tempBattle.initialTokensStaked.mul(battleResetPercentage).div(100)
        ) {
            tempBattle.currentToCollectPercentage = toCollectPercentages[tempBattle.battleType - 1];

            if (tempBattle.currentToCollectPercentage < 1000) {
                tempBattle.daysAtMaxToCollect = 0;
            }

            if (tempBattle.hero != 0) {
                tempBattle.currentToCollectPercentage += assetPercentages[tempBattle.hero - 1];
            }
        }

        battleForAddress[msg.sender][_battleType] = tempBattle;
    }

    function purchaseAsset(
        uint256 _assetToPurchase
    ) external {
        require(0 <= _assetToPurchase && _assetToPurchase <= 10, "purchaseHero::WA");

        uint256 pricePercentage;
        if (_assetToPurchase == 0) {
            pricePercentage = randomAssetPrice;
            _assetToPurchase = battlingExtension.createAssetRandomness();
        }
        else {
            pricePercentage = assetPrices[_assetToPurchase - 1];
        }

        uint256 reserves;
        if (address(fortunasToken) == pancakePair.token0()) {
            (reserves, , ) = pancakePair.getReserves();
        }
        else {
            (, reserves, ) = pancakePair.getReserves();
        }
        require(reserves > 0, "purchaseAsset::NLP");

        uint256 price = reserves.mul(pricePercentage).roundDiv(multiplier);
        fortunasToken.transferFrom(msg.sender, treasuryWallet, price);

        fortunasAssets.mintWithCheck(msg.sender, _assetToPurchase, 1, "");

        emit PurchasedAsset(
            msg.sender,
            _assetToPurchase,
            fortunasAssets.balanceOf(msg.sender, _assetToPurchase)
        );
    }

    function deployAsset(
        uint256 _assetToDeploy,
        uint8 _battleType
    ) external validBattleType(_battleType) validBattle(_battleType) {
        Battle memory tempBattle = battleForAddress[msg.sender][_battleType];

        require(1 <= _assetToDeploy && _assetToDeploy <= 10, "deployAsset::WA");
        require(fortunasAssets.balanceOf(msg.sender, _assetToDeploy) > 0, "deployAsset::ANO");

        if (_assetToDeploy <= 5) {
            require(tempBattle.hero == 0, "deployAsset::HIB");

            tempBattle = battlingExtension.calculateRewards(tempBattle);

            if (tempBattle.currentToCollectPercentage.add(assetPercentages[_assetToDeploy - 1]) > 1000) {
                tempBattle.currentToCollectPercentage = 1000;
            }
            else {
                tempBattle.currentToCollectPercentage += assetPercentages[_assetToDeploy - 1];
            }

            tempBattle.hero = _assetToDeploy;
        }
        else {
            require(tempBattle.cavalry == 0, "deployAsset::CIB");

            tempBattle = battlingExtension.calculateRewards(tempBattle);

            tempBattle.currentRewardPercentagePerCycle = rewardPercentages[tempBattle.battleType - 1].mul(assetPercentages[_assetToDeploy - 1]).div(100).roundDiv(48);

            tempBattle.cavalry = _assetToDeploy;
        }

        fortunasAssets.safeTransferFromWithCheck(msg.sender, address(this), _assetToDeploy, 1, "");

        battleForAddress[msg.sender][_battleType] = tempBattle;
    }

    function endBattle(
        uint8 _battleType
    ) external {
        Battle memory tempBattle = battleForAddress[msg.sender][_battleType];
        require(2 <= _battleType && _battleType <= 6, "endBattle::WBT1");
        require(tempBattle.initialTokensStaked != 0, "endBattle:WB");
        if (_battleType == 2) {
            uint256 battleEndTime = uint256(30).mul(oneDayTime).add(tempBattle.battleStartTime);
            require(block.timestamp >= battleEndTime, "calculateRewardsForEndBattle::BNE");
        }

        tempBattle = battlingExtension.calculateRewardsForEndBattle(tempBattle);

        if (_battleType == 2) {
            LPToken.transfer(msg.sender, tempBattle.initialTokensStaked);

            uint256 rewardsToReturn = tempBattle.rewards.add(tempBattle.passiveRewards);

            uint256 rewardWalletBalance = fortunasToken.balanceOf(rewardWallet);

            bool isMint = rewardsToReturn > rewardWalletBalance;

            if (isMint) {
                if (rewardWalletBalance != 0) {
                    fortunasToken.transferFrom(rewardWallet, msg.sender, rewardWalletBalance);
                }

                fortunasToken.mint(msg.sender, rewardsToReturn.sub(rewardWalletBalance));
            }
            else {
                fortunasToken.transferFrom(rewardWallet, msg.sender, rewardsToReturn);
            }
        }
        else {
            uint256 tokensToReturn = tempBattle.initialTokensStaked.add(tempBattle.additionalTokens);

            uint256 rewardsToReturn = tempBattle.rewards.add(tempBattle.passiveRewards);

            uint256 rewardWalletBalance = fortunasToken.balanceOf(rewardWallet);

            bool isMint = rewardsToReturn > rewardWalletBalance;

            if (isMint) {
                if (rewardWalletBalance != 0) {
                    fortunasToken.transferFrom(rewardWallet, msg.sender, rewardWalletBalance);
                }

                fortunasToken.mint(msg.sender, rewardsToReturn.sub(rewardWalletBalance));
            }
            else {
                fortunasToken.transferFrom(rewardWallet, msg.sender, rewardsToReturn);
            }

            fortunasToken.transfer(msg.sender, tokensToReturn);

            if (tempBattle.hero != 0 || tempBattle.cavalry != 0) {
                uint256 chanceToLoseAssets = baseChanceToLoseAssets;

                if (tempBattle.battleDaysExpended >= 3) {
                    uint256 daysForDecrease = tempBattle.battleDaysExpended.sub(3);
                    if (daysForDecrease < tempBattle.rationsDaysTotal) {
                        daysForDecrease++;
                    }
                    uint256 chanceDecrease = daysForDecrease.mul(5);
                    chanceToLoseAssets = chanceToLoseAssets.safeSub(chanceDecrease);
                }

                if (chanceToLoseAssets != 0) {
                    tempBattle = _handleLoss(tempBattle, chanceToLoseAssets);
                }

                if (tempBattle.hero != 0) {
                    fortunasAssets.safeTransferFromWithCheck(address(this), msg.sender, tempBattle.hero, 1, "");
                }

                if (tempBattle.cavalry != 0) {
                    fortunasAssets.safeTransferFromWithCheck(address(this), msg.sender, tempBattle.cavalry, 1, "");
                }
            }
        }

        Battle memory emptyBattle;
        battleForAddress[msg.sender][_battleType] = emptyBattle;

        emit EndedBattle(
            msg.sender,
            _battleType,
            tempBattle.initialTokensStaked,
            tempBattle.additionalTokens,
            tempBattle.rewards,
            tempBattle.passiveRewards,
            tempBattle.battleStartTime,
            tempBattle.rationsDaysTotal.add(3)
        );
    }

    function _handleLoss(
        Battle memory _tempBattle,
        uint256 _chanceToLoseAssets
    ) internal returns (Battle memory) {
        bool isHeroLost;
        bool isCavalryLost;

        if (_tempBattle.hero != 0 && _tempBattle.cavalry != 0) {
            isHeroLost = battlingExtension.createRandomness(_chanceToLoseAssets, 100, _tempBattle.hero);
            isCavalryLost = battlingExtension.createRandomness(_chanceToLoseAssets, 100, _tempBattle.cavalry);
        }
        else if (_tempBattle.hero != 0) {
            isHeroLost = battlingExtension.createRandomness(_chanceToLoseAssets, 100, _tempBattle.hero);
        }
        else if (_tempBattle.cavalry != 0) {
            isCavalryLost = battlingExtension.createRandomness(_chanceToLoseAssets, 100, _tempBattle.cavalry);
        }

        if (isHeroLost) {
            fortunasAssets.burnWithCheck(address(this), _tempBattle.hero, 1);

            emit LostAsset(
                msg.sender,
                _tempBattle.hero,
                fortunasAssets.balanceOf(msg.sender, _tempBattle.hero)
            );

            _tempBattle.hero = 0;
        }

        if (isCavalryLost) {
            fortunasAssets.burnWithCheck(address(this), _tempBattle.cavalry, 1);

            emit LostAsset(
                msg.sender,
                _tempBattle.cavalry,
                fortunasAssets.balanceOf(msg.sender, _tempBattle.cavalry)
            );

            _tempBattle.cavalry = 0;
        }

        return _tempBattle;
    }

    function viewAllRewards(
        address _user
    ) external view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        uint256[] memory committedRewards = new uint256[](5);
        uint256[] memory potentialRewards = new uint256[](5);
        uint256[] memory passiveRewards = new uint256[](5);

        Battle memory tempBattle;

        for (uint8 i = 0 ; i < 5 ; i++) {
            tempBattle = battleForAddress[_user][i + 2];
            if (tempBattle.initialTokensStaked != 0) {
                if (
                    i == 0 &&
                    block.timestamp < tempBattle.battleStartTime.add(baseLockTime)
                ) {
                    potentialRewards[i] = battlingExtension.viewLockedRewards(
                        tempBattle.initialTokensStaked,
                        tempBattle.currentRewardPercentagePerCycle,
                        tempBattle.battleStartTime
                    );
                }
                else if (
                    i != 0 &&
                    block.timestamp < tempBattle.battleStartTime.add(baseBattleTime).add(tempBattle.rationsDaysTotal.mul(oneDayTime))
                ) {
                    committedRewards[i] = tempBattle.rewards;

                    tempBattle.currentToCollectPercentage = 1000;
                    tempBattle = battlingExtension.calculateRewards(tempBattle);

                    potentialRewards[i] = tempBattle.rewards.sub(committedRewards[i]);
                }
                else {
                    committedRewards[i] = tempBattle.rewards;

                    tempBattle.currentToCollectPercentage = 1000;
                    tempBattle = battlingExtension.calculateRewardsForEndBattle(tempBattle);

                    potentialRewards[i] = tempBattle.rewards.sub(committedRewards[i]);

                    passiveRewards[i] = tempBattle.passiveRewards;
                }
            }
        }

        return (committedRewards, potentialRewards, passiveRewards);
    }

    // modifiers

    modifier validBattle(uint8 _battleType) {
        _validBattle(_battleType);
        _;
    }

    function _validBattle(uint8 _battleType) internal view {
        Battle memory tempBattle = battleForAddress[msg.sender][_battleType];
        require(tempBattle.initialTokensStaked != 0, "Battling:WB");
        require(block.timestamp <
            tempBattle.battleStartTime.add(baseBattleTime).add(tempBattle.rationsDaysTotal.mul(oneDayTime)), "battling::BE");
    }

    modifier validBattleType(uint8 _battleType) {
        _validBattleType(_battleType);
        _;
    }

    function _validBattleType(uint8 _battleType) internal pure {
        require(3 <= _battleType && _battleType <= 6, "Battling::WBT2");
    }
}

pragma solidity >=0.5.0;
// SPDX-License-Identifier: Unlicense

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;
// SPDX-License-Identifier: Unlicense

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

pragma solidity >=0.5.0;
// SPDX-License-Identifier: Unlicense

interface IPancakeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicense

import "./IERC1155.sol";

interface IFortunasAssets is IERC1155 {

    function mintWithCheck(
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) external;

    function safeTransferFromWithCheck(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) external;

    function burnWithCheck(
        address _from,
        uint256 _tokenId,
        uint256 _amount
    ) external;
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicense

import "./IERC20.sol";

interface IFortunasToken is IERC20 {

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicense

import "./SafeMath.sol";
import "./MathUpgradeable.sol";
import "./ABDKMath64x64.sol";

import "./BattlingBase.sol";

import "./IPancakeFactory.sol";
import "./IPancakeRouter02.sol";
import "./IPancakePair.sol";

contract BattlingExtension is BattlingBase {
    using SafeMath for uint256;
    using MathUpgradeable for uint256;

    // RNG variables

    IPancakeRouter02 public rng_pancakeRouter;
    IPancakeFactory public rng_pancakeFactory;

    // variables

    uint256[5] public rationsPercentages;                   // rations %
    uint256 public rationsIncreasePercentage;               // percentage increase in rations percentages when to collect limit is reached

    // constructor

    constructor() {
        // PancakeRouter02 mainnet
        // IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        // TODO remove
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        IPancakeFactory _pancakeFactory = IPancakeFactory(_pancakeRouter.factory());

        rng_pancakeRouter = _pancakeRouter;
        rng_pancakeFactory = _pancakeFactory;

        rationsPercentages = [2500000, 5000000, 7500000, 10000000, 12500000];
        rationsIncreasePercentage = 125000000;
    }

    // RNG functions

    function createRandomness(uint256 _chance, uint256 _max, uint256 _magic) public view onlyOwner returns (bool) {
        uint256 pairSelector =
            uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, _magic)))
                .mod(rng_pancakeFactory.allPairsLength().safeSub(2));

        address addressForPancakePair1 = rng_pancakeFactory.allPairs(pairSelector);
        address addressForPancakePair2 = rng_pancakeFactory.allPairs(pairSelector + 1);

        uint256 a = IPancakePair(addressForPancakePair1).price0CumulativeLast();
        uint256 b = IPancakePair(addressForPancakePair1).price1CumulativeLast();

        uint256 c = IPancakePair(addressForPancakePair2).price0CumulativeLast();

        uint256 randomChance =
            uint256(keccak256(abi.encodePacked(a, b, c, _magic))).mod(_max).add(1);

        return randomChance <= _chance;
    }

    function createToCollectRandomness(uint256 _max, uint256 _magic) public view onlyOwner returns (uint256) {
        uint256 pairSelector =
            uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, _magic)))
                .mod(rng_pancakeFactory.allPairsLength().safeSub(2));

        address addressForPancakePair1 = rng_pancakeFactory.allPairs(pairSelector);
        address addressForPancakePair2 = rng_pancakeFactory.allPairs(pairSelector + 1);

        uint256 a = IPancakePair(addressForPancakePair1).price0CumulativeLast();
        uint256 b = IPancakePair(addressForPancakePair1).price1CumulativeLast();

        uint256 c = IPancakePair(addressForPancakePair2).price0CumulativeLast();

        uint256 randomChance =
            uint256(keccak256(abi.encodePacked(a, b, c, _magic))).mod(_max).add(1);

        return randomChance;
    }

    function createAssetRandomness() external view onlyOwner returns (uint256) {
        uint256 pairSelector =
            uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin)))
                .mod(rng_pancakeFactory.allPairsLength().safeSub(3));

        address addressForPancakePair1 = rng_pancakeFactory.allPairs(pairSelector);
        address addressForPancakePair2 = rng_pancakeFactory.allPairs(pairSelector + 1);
        address addressForPancakePair3 = rng_pancakeFactory.allPairs(pairSelector + 2);

        uint256 a = IPancakePair(addressForPancakePair1).price0CumulativeLast();
        uint256 b = IPancakePair(addressForPancakePair1).price1CumulativeLast();
        (uint256 c, , ) = IPancakePair(addressForPancakePair1).getReserves();

        uint256 d = IPancakePair(addressForPancakePair2).price0CumulativeLast();
        uint256 e = IPancakePair(addressForPancakePair2).price1CumulativeLast();
        (uint256 f, , ) = IPancakePair(addressForPancakePair2).getReserves();

        uint256 g = IPancakePair(addressForPancakePair3).price0CumulativeLast();
        uint256 h = IPancakePair(addressForPancakePair3).price1CumulativeLast();
        (uint256 i, , ) = IPancakePair(addressForPancakePair3).getReserves();

        uint256 randomChance =
            uint256(keccak256(abi.encodePacked(a, b, c, d, e, f, g, h, i, block.timestamp))).mod(100).add(1);

        uint256 result;

        if (randomChance <= 50) {
            result = 1;
        }
        else if (50 < randomChance && randomChance <= 75) {
            result = 2;
        }
        else if (75 < randomChance && randomChance <= 90) {
            result = 3;
        }
        else if (90 < randomChance && randomChance <= 99) {
            result = 4;
        }
        else if (randomChance == 100) {
            result = 5;
        }

        return result;
    }

    // functions

    function _determineRewardCycles(
        uint256 _currentToCollectPercentage,
        uint256 _numberOfCycles,
        bool _isStatic
    ) internal view returns (uint256, uint256, uint256) {
        uint256 daysAtMaxToCollect;
        uint256 numberOfWins;

        if (_numberOfCycles <= uint256(1000).sub(_currentToCollectPercentage).div(50).add(2)) {
            bool result;

            for (uint256 i = 0 ; i < _numberOfCycles ; i++) {
                result = createRandomness(_currentToCollectPercentage, 1000, i);

                if (result) {
                    numberOfWins++;
                }
            }

            return (_currentToCollectPercentage, daysAtMaxToCollect, numberOfWins);
        }

        if (_isStatic) {
            uint256 magic;

            uint256 max = 100;
            if (_currentToCollectPercentage >= 950) {
                max = uint256(999).sub(_currentToCollectPercentage);
                max *= 2;
            }
            uint256 randomNumber1 = _currentToCollectPercentage.sub(createToCollectRandomness(max, magic));
            uint256 randomNumber2 = _currentToCollectPercentage.add(createToCollectRandomness(max, magic + 1));

            uint256 result = randomNumber1.add(randomNumber2).roundDiv(2);

            numberOfWins = _numberOfCycles.mul(result).div(1000);
        }
        else {
            uint256 numberOfDays = _numberOfCycles.div(48);
            for (uint256 i = 0 ; i < numberOfDays ; i++) {
                if (_currentToCollectPercentage != 1000) {
                    _currentToCollectPercentage += toCollectIncreasePerDay;
                }

                if (_currentToCollectPercentage == 1000) {
                    daysAtMaxToCollect = numberOfDays.sub(i);
                    numberOfWins += daysAtMaxToCollect.mul(48);
                    break;
                }

                uint256 max = 100;
                if (_currentToCollectPercentage >= 950) {
                    max = uint256(999).sub(_currentToCollectPercentage);
                    max *= 2;
                }
                uint256 randomNumber1 = _currentToCollectPercentage.sub(createToCollectRandomness(max, i));
                uint256 randomNumber2 = _currentToCollectPercentage.add(createToCollectRandomness(max, i + 1));

                uint256 result = randomNumber1.add(randomNumber2).roundDiv(2);

                numberOfWins += uint256(48).mul(result).div(1000);
            }
        }

        return (_currentToCollectPercentage, daysAtMaxToCollect, numberOfWins);
    }

    function calculateRations(
        Battle memory _tempBattle,
        uint256 _rationDays
    ) external view onlyOwner returns (uint256) {
        uint256 tempTotalTokens = _tempBattle.initialTokensStaked.add(_tempBattle.additionalTokens).add(_tempBattle.rewards);
        uint256 tempRationsPercentage = rationsPercentages[_rationDays - 1];
        uint256 tempRations;

        if (_tempBattle.currentToCollectPercentage == 1000) {
            uint256 ratio = rationsIncreasePercentage.mul(10 ** 18).div(multiplierForRations);

            tempRationsPercentage += _compound(
                tempRationsPercentage,
                ratio,
                _tempBattle.daysAtMaxToCollect
            );
        }

        tempRations = tempTotalTokens.mul(tempRationsPercentage).div(multiplierForRations);

        return tempRations;
    }

    function calculateRewards(Battle memory _tempBattle) public view onlyOwner returns (Battle memory) {
        uint256 tempTotalTokens = _tempBattle.initialTokensStaked.add(_tempBattle.additionalTokens).add(_tempBattle.rewards);

        uint256 daysWagingBattle = block.timestamp.sub(_tempBattle.battleStartTime).div(oneDayTime);

        uint256 ratio = _tempBattle.currentRewardPercentagePerCycle.mul(10 ** 18).div(multiplierForReward);

        uint256 daysForReward;
        uint256 cyclesForReward;
        uint256 compoundReward;

        uint256 cyclesToComplete = block.timestamp.sub(_tempBattle.battleDaysExpended.mul(oneDayTime).add(_tempBattle.battleStartTime)).div(rewardTime);

        if (
            cyclesToComplete > _tempBattle.cyclesCompleted &&
            _tempBattle.cyclesRemaining != 0
        ) {
            _tempBattle = _completeRemainingCycles(_tempBattle);
        }

        if (daysWagingBattle.sub(_tempBattle.battleDaysExpended) != 0) {
            if (daysWagingBattle < 3) {
                daysForReward = daysWagingBattle.sub(_tempBattle.battleDaysExpended);

                cyclesForReward = daysForReward.mul(48);

                if (_tempBattle.currentToCollectPercentage != 1000) {
                    (, , cyclesForReward) = _determineRewardCycles(
                        _tempBattle.currentToCollectPercentage,
                        daysForReward.mul(48),
                        true
                    );
                }

                compoundReward = _compound(
                    tempTotalTokens,
                    ratio,
                    cyclesForReward
                );
                _tempBattle.rewards += compoundReward;
            }
            else if (
                daysWagingBattle >= 3 &&
                daysWagingBattle < _tempBattle.rationsDaysTotal.add(3) &&
                _tempBattle.rationsDaysTotal > 0
            ) {
                if (_tempBattle.battleDaysExpended < 3) {
                    daysForReward = uint256(3).sub(_tempBattle.battleDaysExpended);

                    cyclesForReward = daysForReward.mul(48);

                    if (_tempBattle.currentToCollectPercentage != 1000) {
                        (, , cyclesForReward) = _determineRewardCycles(
                            _tempBattle.currentToCollectPercentage,
                            daysForReward.mul(48),
                            true
                        );
                    }

                    compoundReward = _compound(
                        tempTotalTokens,
                        ratio,
                        cyclesForReward
                    );
                    _tempBattle.rewards += compoundReward;
                    tempTotalTokens += compoundReward;

                    _tempBattle.battleDaysExpended = 3;
                }

                daysForReward = daysWagingBattle.sub(_tempBattle.battleDaysExpended);

                bool continueBattle = daysForReward != 0;

                if (continueBattle) {
                    cyclesForReward = daysForReward.mul(48);

                    if (_tempBattle.currentToCollectPercentage != 1000) {
                        uint256 daysAtMaxToCollect;
                        (_tempBattle.currentToCollectPercentage, daysAtMaxToCollect, cyclesForReward) = _determineRewardCycles(
                            _tempBattle.currentToCollectPercentage,
                            daysForReward.mul(48),
                            false
                        );

                        if (daysAtMaxToCollect != 0) {
                            _tempBattle.daysAtMaxToCollect += daysAtMaxToCollect;
                        }
                    }
                    else {
                        _tempBattle.daysAtMaxToCollect += daysForReward;
                    }

                    compoundReward = _compound(
                        tempTotalTokens,
                        ratio,
                        cyclesForReward
                    );
                    _tempBattle.rewards += compoundReward;
                    tempTotalTokens += compoundReward;
                }
            }

            _tempBattle.battleDaysExpended = daysWagingBattle;
        }

        cyclesToComplete = block.timestamp.sub(_tempBattle.battleDaysExpended.mul(oneDayTime).add(_tempBattle.battleStartTime)).div(rewardTime);

        if (
            cyclesToComplete > 0 &&
            _tempBattle.cyclesCompleted == 0
        ) {
            _tempBattle = _completeCycles(_tempBattle);
        }

        require(
            block.timestamp <
            _tempBattle.battleStartTime.add(baseBattleTime).add(_tempBattle.rationsDaysTotal.mul(oneDayTime)),
            "calculateRewards::BE"
        );

        return _tempBattle;
    }

    function _completeRemainingCycles(Battle memory _tempBattle) internal view returns (Battle memory) {
        uint256 tempTotalTokens = _tempBattle.initialTokensStaked.add(_tempBattle.additionalTokens).add(_tempBattle.rewards);

        uint256 ratio = _tempBattle.currentRewardPercentagePerCycle.mul(10 ** 18).div(multiplierForReward);

        uint256 cyclesToComplete = block.timestamp.sub(_tempBattle.battleDaysExpended.mul(oneDayTime).add(_tempBattle.battleStartTime)).div(rewardTime);
        if (cyclesToComplete >= 48) {
            cyclesToComplete = _tempBattle.cyclesRemaining;
            _tempBattle.cyclesCompleted = 0;
            _tempBattle.cyclesRemaining = 0;
            _tempBattle.battleDaysExpended++;
        }
        else {
            cyclesToComplete = cyclesToComplete.sub(_tempBattle.cyclesCompleted);
            _tempBattle.cyclesCompleted += cyclesToComplete;
            _tempBattle.cyclesRemaining -= cyclesToComplete;
        }
        uint256 cyclesForReward = cyclesToComplete;

        if (_tempBattle.currentToCollectPercentage != 1000) {
            (, , cyclesForReward) = _determineRewardCycles(
                _tempBattle.currentToCollectPercentage,
                cyclesToComplete,
                true
            );
        }

        _tempBattle.rewards += _compound(
            tempTotalTokens,
            ratio,
            cyclesForReward
        );

        return _tempBattle;
    }

    function _completeCycles(Battle memory _tempBattle) internal view returns (Battle memory) {
        uint256 tempTotalTokens = _tempBattle.initialTokensStaked.add(_tempBattle.additionalTokens).add(_tempBattle.rewards);

        uint256 ratio = _tempBattle.currentRewardPercentagePerCycle.mul(10 ** 18).div(multiplierForReward);

        uint256 cyclesToComplete = block.timestamp.sub(_tempBattle.battleDaysExpended.mul(oneDayTime).add(_tempBattle.battleStartTime)).div(rewardTime);
        uint256 cyclesForReward = cyclesToComplete;

        if (_tempBattle.battleDaysExpended >= 3 && _tempBattle.currentToCollectPercentage != 1000) {
            _tempBattle.currentToCollectPercentage += toCollectIncreasePerDay;
        }

        if (_tempBattle.currentToCollectPercentage != 1000) {
            (, , cyclesForReward) = _determineRewardCycles(
                _tempBattle.currentToCollectPercentage,
                cyclesToComplete,
                true
            );
        }
        else {
            _tempBattle.daysAtMaxToCollect++;
        }

        _tempBattle.rewards += _compound(
            tempTotalTokens,
            ratio,
            cyclesForReward
        );

        _tempBattle.cyclesCompleted = cyclesToComplete;
        _tempBattle.cyclesRemaining = uint256(48).sub(cyclesToComplete);

        return _tempBattle;
    }

    function calculateRewardsForEndBattle(Battle memory _tempBattle) external view onlyOwner returns (Battle memory) {
        uint256 battleEndTime;
        if (_tempBattle.battleType != 2) {
            battleEndTime = _tempBattle.battleStartTime.add(baseBattleTime).add(_tempBattle.rationsDaysTotal.mul(oneDayTime));
        }
        else {
            battleEndTime = _tempBattle.battleStartTime.add(baseLockTime);
        }

        if (block.timestamp < battleEndTime && _tempBattle.battleType != 2) {
            _tempBattle = calculateRewards(_tempBattle);
        }
        else {
            uint256 tempTotalTokens = _tempBattle.initialTokensStaked.add(_tempBattle.additionalTokens).add(_tempBattle.rewards);

            uint256 daysWagingBattle = _tempBattle.rationsDaysTotal.add(3);
            uint256 daysForReward = daysWagingBattle.sub(_tempBattle.battleDaysExpended);

            uint256 ratio = _tempBattle.currentRewardPercentagePerCycle.mul(10 ** 18).div(multiplierForReward);

            uint256 cyclesForReward;
            uint256 compoundReward;

            if (_tempBattle.battleType == 2) {
                compoundReward = _compound(
                    tempTotalTokens,
                    ratio,
                    1440
                );
                _tempBattle.rewards += compoundReward;
            }
            else {
                cyclesForReward = block.timestamp.sub(_tempBattle.battleDaysExpended.mul(oneDayTime).add(_tempBattle.battleStartTime)).div(rewardTime);

                if (
                    cyclesForReward > _tempBattle.cyclesCompleted &&
                    _tempBattle.cyclesRemaining != 0
                ) {
                    _tempBattle = _completeRemainingCycles(_tempBattle);
                }

                if (_tempBattle.battleDaysExpended < 3) {
                    daysForReward = uint256(3).sub(_tempBattle.battleDaysExpended);

                    cyclesForReward = daysForReward.mul(48);

                    if (_tempBattle.currentToCollectPercentage != 1000) {
                        (, , cyclesForReward) = _determineRewardCycles(
                            _tempBattle.currentToCollectPercentage,
                            daysForReward.mul(48),
                            true
                        );
                    }

                    compoundReward = _compound(
                        tempTotalTokens,
                        ratio,
                        cyclesForReward
                    );
                    _tempBattle.rewards += compoundReward;
                    tempTotalTokens += compoundReward;

                    _tempBattle.battleDaysExpended = 3;
                }

                daysForReward = daysWagingBattle.sub(_tempBattle.battleDaysExpended);

                bool continueBattle = daysForReward != 0;

                if (continueBattle) {
                    cyclesForReward = daysForReward.mul(48);

                    if (_tempBattle.currentToCollectPercentage != 1000) {
                        (_tempBattle.currentToCollectPercentage, , cyclesForReward) = _determineRewardCycles(
                            _tempBattle.currentToCollectPercentage,
                            daysForReward.mul(48),
                            false
                        );
                    }

                    compoundReward = _compound(
                        tempTotalTokens,
                        ratio,
                        cyclesForReward
                    );
                    _tempBattle.rewards += compoundReward;
                    tempTotalTokens += compoundReward;
                }
            }

            _tempBattle.battleDaysExpended = daysWagingBattle;

            cyclesForReward = block.timestamp.sub(battleEndTime).div(rewardTime);

            ratio = rewardPercentagesPerCycle[0].mul(10 ** 18).div(multiplierForReward);

            _tempBattle.passiveRewards = _compound(
                tempTotalTokens,
                ratio,
                cyclesForReward
            );
        }

        return _tempBattle;
    }

    function viewLockedRewards(
        uint256 _initialTokensStaked,
        uint256 _currentRewardPercentagePerCycle,
        uint256 _battleStartTime
    ) external view onlyOwner returns (uint256) {
        uint256 cyclesForReward = block.timestamp.sub(_battleStartTime).div(rewardTime);

        uint256 ratio = _currentRewardPercentagePerCycle.mul(10 ** 18).div(multiplierForReward);

        uint256 compoundReward = _compound(
            _initialTokensStaked,
            ratio,
            cyclesForReward
        );

        return compoundReward;
    }

    function _compound(uint256 _principal, uint256 _ratio, uint256 _exponent) internal pure returns (uint256) {
        if (_exponent == 0) {
            return 0;
        }

        uint256 accruedReward = ABDKMath64x64.mulu(ABDKMath64x64.pow(ABDKMath64x64.add(ABDKMath64x64.fromUInt(1), ABDKMath64x64.divu(_ratio,10**18)), _exponent), _principal);

        return accruedReward.sub(_principal);
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicense

import "./Ownable.sol";
import "./MathUpgradeable.sol";

abstract contract BattlingBase is Ownable {
    using MathUpgradeable for uint256;

    // variables

    uint256 public rewardTime;                              // 30 minutes in seconds
    uint256 public oneDayTime;                              // 1 day in seconds
    uint256 public baseBattleTime;                          // 3 days in seconds
    uint256 public baseLockTime;                            // 30 days in seconds

    uint256 public multiplier;
    uint256 public multiplierForRations;
    uint256 public multiplierForReward;

    uint256[6] public toCollectPercentages;                 // chance to win for every iteration
    uint256 public toCollectIncreasePerDay;                 // increase in chance to win for every ration day

    uint256[6] public rewardPercentages;                    // reward percentage per day
    uint256[6] public rewardPercentagesPerCycle;            // reward percentage per reward iteration
    uint256[6] public minStakeAmount;                       // minimum stake amount to be able to receive rewards

    // structs

    struct Battle {
        uint8 battleType;
        uint256 initialTokensStaked;
        uint256 additionalTokens;
        uint256 rewards;
        uint256 rations;
        uint256 passiveRewards;
        uint256 currentRewardPercentagePerCycle;
        uint256 currentToCollectPercentage;
        uint256 cyclesCompleted;
        uint256 cyclesRemaining;
        uint256 battleStartTime;
        uint256 battleDaysExpended;
        uint256 rationsDaysTotal;
        uint256 hero;
        uint256 cavalry;
        uint256 daysAtMaxToCollect;
    }

    // constructor

    constructor() {
        rewardTime = 1800;
        oneDayTime = 86400;
        baseBattleTime = 259200;
        baseLockTime = 2592000;

        multiplier = 10 ** 6;
        multiplierForRations = 10 ** 9;
        multiplierForReward = 10 ** 9;

        toCollectPercentages = [1000, 1000, 750, 500, 200, 100];
        toCollectIncreasePerDay = 5;

        rewardPercentages = [2500000, 5000000, 10000000, 12500000, 20000000, 25000000];
        _setRewards();
    }

    // setters

    function _setRewards() internal {
        for (uint256 i = 0 ; i < 6 ; i++) {
            rewardPercentagesPerCycle[i] = rewardPercentages[i].roundDiv(48);
            minStakeAmount[i] = multiplierForReward.ceilDiv(rewardPercentagesPerCycle[i]);
        }
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }

    /**
     * @dev Returns the current rounding of the division of two numbers.
     *
     * This differs from standard division with `/` in that it can round up and
     * down depending on the floating point.
     */
    function roundDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result = a * 10 / b;
        if (result % 10 >= 5) {
            result = a / b + 1;
        }
        else {
            result = a / b;
        }

        return result;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers and returns zero if
     * overflow occurs
     */
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b > a) return 0;
            return a - b;
        }
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicense

library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicense

import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "./IERC1155Receiver.sol";
import "./ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}