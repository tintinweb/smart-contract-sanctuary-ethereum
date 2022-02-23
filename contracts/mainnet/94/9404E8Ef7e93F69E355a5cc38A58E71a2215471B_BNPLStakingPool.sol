// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {IMintableBurnableTokenUpgradeable} from "../../ERC20/interfaces/IMintableBurnableTokenUpgradeable.sol";
import {IBankNodeManager} from "../../Management/interfaces/IBankNodeManager.sol";

import {IBNPLBankNode} from "../interfaces/IBNPLBankNode.sol";
import {IBNPLNodeStakingPool} from "../interfaces/IBNPLNodeStakingPool.sol";

import {UserTokenLockup} from "./UserTokenLockup.sol";
import {BNPLKYCStore} from "../../Management/BNPLKYCStore.sol";

import {BankNodeUtils} from "../lib/BankNodeUtils.sol";
import {TransferHelper} from "../../Utils/TransferHelper.sol";
import {PRBMathUD60x18} from "../../Utils/Math/PRBMathUD60x18.sol";

/// @title BNPL StakingPool contract
///
/// @notice
/// - Features:
///   **Stake BNPL**
///   **Unstake BNPL**
///   **Lock BNPL**
///   **Unlock BNPL**
///   **Decommission a bank node**
///   **Donate BNPL**
///   **Redeem AAVE**
///   **Claim AAVE rewards**
///   **Cool down AAVE**
///
/// @author BNPL
contract BNPLStakingPool is
    Initializable,
    ReentrancyGuardUpgradeable,
    AccessControlEnumerableUpgradeable,
    UserTokenLockup,
    IBNPLNodeStakingPool
{
    using PRBMathUD60x18 for uint256;
    /// @dev Emitted when user `user` is stakes `bnplStakeAmount` of BNPL tokens while receiving `poolTokensMinted` of pool tokens
    event Stake(address indexed user, uint256 bnplStakeAmount, uint256 poolTokensMinted);

    /// @dev Emitted when user `user` is unstakes `unstakeAmount` of liquidity while receiving `bnplTokensReturned` of BNPL tokens
    event Unstake(address indexed user, uint256 bnplUnstakeAmount, uint256 poolTokensBurned);

    /// @dev Emitted when user `user` donates `donationAmount` of base liquidity tokens to the pool
    event Donation(address indexed user, uint256 donationAmount);

    /// @dev Emitted when user `user` bonds `bondAmount` of base liquidity tokens to the pool
    event Bond(address indexed user, uint256 bondAmount);

    /// @dev Emitted when user `user` unbonds `unbondAmount` of base liquidity tokens to the pool
    event Unbond(address indexed user, uint256 unbondAmount);

    /// @dev Emitted when user `recipient` donates `donationAmount` of base liquidity tokens to the pool
    event Slash(address indexed recipient, uint256 slashAmount);

    uint32 public constant BNPL_STAKER_NEEDS_KYC = 1 << 3;

    bytes32 public constant SLASHER_ROLE = keccak256("SLASHER_ROLE");
    bytes32 public constant NODE_REWARDS_MANAGER_ROLE = keccak256("NODE_REWARDS_MANAGER_ROLE");

    /// @dev BNPL token contract
    IERC20 public BASE_LIQUIDITY_TOKEN;

    /// @dev Pool BNPL token contract
    IMintableBurnableTokenUpgradeable public POOL_LIQUIDITY_TOKEN;

    /// @dev BNPL bank node contract
    IBNPLBankNode public bankNode;

    /// @dev BNPL bank node manager contract
    IBankNodeManager public bankNodeManager;

    /// @notice Total assets value
    uint256 public override baseTokenBalance;

    /// @notice Cumulative value of bonded tokens
    uint256 public override tokensBondedAllTime;

    /// @notice Pool BNPL token effective supply
    uint256 public override poolTokenEffectiveSupply;

    /// @notice Pool BNPL token balance
    uint256 public override virtualPoolTokensCount;

    /// @notice Cumulative value of donated tokens
    uint256 public totalDonatedAllTime;

    /// @notice Cumulative value of shashed tokens
    uint256 public totalSlashedAllTime;

    /// @notice The BNPL KYC store contract
    BNPLKYCStore public bnplKYCStore;

    /// @notice The corresponding id in the BNPL KYC store
    uint32 public kycDomainId;

    /// @dev StakingPool contract is created and initialized by the BankNodeManager contract
    ///
    /// - This contract is called through the proxy.
    ///
    /// @param bnplToken BNPL token address
    /// @param poolBNPLToken pool BNPL token address
    /// @param bankNodeContract BankNode contract address associated with stakingPool
    /// @param bankNodeManagerContract BankNodeManager contract address
    /// @param tokenBonder The address of the BankNode creator
    /// @param tokensToBond The amount of BNPL bound by the BankNode creator (initial liquidity amount)
    /// @param bnplKYCStore_ KYC store contract address
    /// @param kycDomainId_ KYC store domain id
    function initialize(
        address bnplToken,
        address poolBNPLToken,
        address bankNodeContract,
        address bankNodeManagerContract,
        address tokenBonder,
        uint256 tokensToBond,
        BNPLKYCStore bnplKYCStore_,
        uint32 kycDomainId_
    ) external override initializer nonReentrant {
        require(bnplToken != address(0), "bnplToken cannot be 0");
        require(poolBNPLToken != address(0), "poolBNPLToken cannot be 0");
        require(bankNodeContract != address(0), "slasherAdmin cannot be 0");
        require(tokenBonder != address(0), "tokenBonder cannot be 0");
        require(tokensToBond > 0, "tokensToBond cannot be 0");

        __ReentrancyGuard_init_unchained();
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();

        BASE_LIQUIDITY_TOKEN = IERC20(bnplToken);
        POOL_LIQUIDITY_TOKEN = IMintableBurnableTokenUpgradeable(poolBNPLToken);

        bankNode = IBNPLBankNode(bankNodeContract);
        bankNodeManager = IBankNodeManager(bankNodeManagerContract);

        _setupRole(SLASHER_ROLE, bankNodeContract);
        _setupRole(NODE_REWARDS_MANAGER_ROLE, tokenBonder);

        require(BASE_LIQUIDITY_TOKEN.balanceOf(address(this)) >= tokensToBond, "tokens to bond not sent");
        baseTokenBalance = tokensToBond;
        tokensBondedAllTime = tokensToBond;
        poolTokenEffectiveSupply = tokensToBond;
        virtualPoolTokensCount = tokensToBond;
        bnplKYCStore = bnplKYCStore_;
        kycDomainId = kycDomainId_;
        POOL_LIQUIDITY_TOKEN.mint(address(this), tokensToBond);
        emit Bond(tokenBonder, tokensToBond);
    }

    /// @notice Returns pool tokens circulating
    /// @return poolTokensCirculating
    function poolTokensCirculating() external view override returns (uint256) {
        return poolTokenEffectiveSupply - POOL_LIQUIDITY_TOKEN.balanceOf(address(this));
    }

    /// @notice Returns unstake lockup period
    /// @return unstakeLockupPeriod
    function getUnstakeLockupPeriod() public pure override returns (uint256) {
        return 7 days;
    }

    /// @notice Returns pool total assets value
    /// @return poolTotalAssetsValue
    function getPoolTotalAssetsValue() public view override returns (uint256) {
        return baseTokenBalance;
    }

    /// @notice Returns whether the BankNode has been decommissioned
    ///
    /// - When the liquidity tokens amount of the BankNode is less than minimum BankNode bonded amount, it is decommissioned
    ///
    /// @return isNodeDecomissioning
    function isNodeDecomissioning() public view override returns (bool) {
        return
            getPoolWithdrawConversion(POOL_LIQUIDITY_TOKEN.balanceOf(address(this))) <
            ((bankNodeManager.minimumBankNodeBondedAmount() * 75) / 100);
    }

    /// @notice Returns pool deposit conversion
    ///
    /// @param depositAmount The deposit tokens amount
    /// @return poolDepositConversion
    function getPoolDepositConversion(uint256 depositAmount) public view returns (uint256) {
        uint256 poolTotalAssetsValue = getPoolTotalAssetsValue();
        return (depositAmount * poolTokenEffectiveSupply) / (poolTotalAssetsValue > 0 ? poolTotalAssetsValue : 1);
    }

    /// @notice Returns pool withdraw conversion
    ///
    /// @param withdrawAmount The withdraw tokens amount
    /// @return poolWithdrawConversion
    function getPoolWithdrawConversion(uint256 withdrawAmount) public view override returns (uint256) {
        return
            (withdrawAmount * getPoolTotalAssetsValue()) /
            (poolTokenEffectiveSupply > 0 ? poolTokenEffectiveSupply : 1);
    }

    /// @dev issue `amount` amount of unlocked tokens to user `user`
    /// @return baseTokensOut
    function _issueUnlockedTokensToUser(address user, uint256 amount) internal override returns (uint256) {
        require(
            amount != 0 && amount <= poolTokenEffectiveSupply,
            "poolTokenAmount cannot be 0 or more than circulating"
        );

        require(poolTokenEffectiveSupply != 0, "poolTokenEffectiveSupply must not be 0");
        require(getPoolTotalAssetsValue() != 0, "total asset value must not be 0");

        uint256 baseTokensOut = getPoolWithdrawConversion(amount);
        poolTokenEffectiveSupply -= amount;
        require(baseTokenBalance >= baseTokensOut, "base tokens balance must be >= out");
        baseTokenBalance -= baseTokensOut;
        TransferHelper.safeTransfer(address(BASE_LIQUIDITY_TOKEN), user, baseTokensOut);
        emit Unstake(user, baseTokensOut, amount);
        return baseTokensOut;
    }

    /// @dev Remove liquidity tokens from the liquidity pool and lock these tokens for `unstakeLockupPeriod` duration
    function _removeLiquidityAndLock(
        address user,
        uint256 poolTokensToConsume,
        uint256 unstakeLockupPeriod
    ) internal returns (uint256) {
        require(unstakeLockupPeriod != 0, "lockup period cannot be 0");
        require(user != address(this) && user != address(0), "invalid user");

        require(
            poolTokensToConsume > 0 && poolTokensToConsume <= poolTokenEffectiveSupply,
            "poolTokenAmount cannot be 0 or more than circulating"
        );

        require(poolTokenEffectiveSupply != 0, "poolTokenEffectiveSupply must not be 0");
        POOL_LIQUIDITY_TOKEN.burnFrom(user, poolTokensToConsume);
        _createTokenLockup(user, poolTokensToConsume, uint64(block.timestamp + unstakeLockupPeriod), true);
        return 0;
    }

    /// @dev Mint `mintAmount` amount pool token to `user` address
    function _mintPoolTokensForUser(address user, uint256 mintAmount) private {
        require(user != address(0), "user cannot be null");

        require(mintAmount != 0, "mint amount cannot be 0");
        uint256 newMintTokensCirculating = poolTokenEffectiveSupply + mintAmount;
        poolTokenEffectiveSupply = newMintTokensCirculating;
        POOL_LIQUIDITY_TOKEN.mint(user, mintAmount);
        require(poolTokenEffectiveSupply == newMintTokensCirculating);
    }

    /// @dev Handle donate tokens
    function _processDonation(
        address sender,
        uint256 depositAmount,
        bool countedIntoTotal
    ) private {
        require(sender != address(this) && sender != address(0), "invalid sender");
        require(depositAmount != 0, "depositAmount cannot be 0");

        require(poolTokenEffectiveSupply != 0, "poolTokenEffectiveSupply must not be 0");
        TransferHelper.safeTransferFrom(address(BASE_LIQUIDITY_TOKEN), sender, address(this), depositAmount);
        baseTokenBalance += depositAmount;
        if (countedIntoTotal) {
            totalDonatedAllTime += depositAmount;
        }
        emit Donation(sender, depositAmount);
    }

    /// @dev Handle bond tokens
    function _processBondTokens(address sender, uint256 depositAmount) private {
        require(sender != address(this) && sender != address(0), "invalid sender");
        require(depositAmount != 0, "depositAmount cannot be 0");

        require(poolTokenEffectiveSupply != 0, "poolTokenEffectiveSupply must not be 0");
        TransferHelper.safeTransferFrom(address(BASE_LIQUIDITY_TOKEN), sender, address(this), depositAmount);
        uint256 selfMint = getPoolDepositConversion(depositAmount);
        _mintPoolTokensForUser(address(this), selfMint);
        virtualPoolTokensCount += selfMint;
        baseTokenBalance += depositAmount;
        tokensBondedAllTime += depositAmount;
        emit Bond(sender, depositAmount);
    }

    /// @dev Handle unbond tokens
    function _processUnbondTokens(address sender) private {
        require(sender != address(this) && sender != address(0), "invalid sender");
        require(bankNode.onGoingLoanCount() == 0, "Cannot unbond, there are ongoing loans");

        uint256 pTokens = POOL_LIQUIDITY_TOKEN.balanceOf(address(this));
        uint256 totalBonded = getPoolWithdrawConversion(pTokens);
        require(totalBonded != 0, "Insufficient bonded amount");

        TransferHelper.safeTransfer(address(BASE_LIQUIDITY_TOKEN), sender, totalBonded);
        POOL_LIQUIDITY_TOKEN.burn(pTokens);

        poolTokenEffectiveSupply -= pTokens;
        virtualPoolTokensCount -= pTokens;
        baseTokenBalance -= totalBonded;

        emit Unbond(sender, totalBonded);
    }

    /// @dev This function is called when poolTokenEffectiveSupply is zero
    ///
    /// @param user The address of user
    /// @param depositAmount Deposit tokens amount
    /// @return poolTokensOut The output pool token amount
    function _setupLiquidityFirst(address user, uint256 depositAmount) private returns (uint256) {
        require(user != address(this) && user != address(0), "invalid user");
        require(depositAmount != 0, "depositAmount cannot be 0");

        require(poolTokenEffectiveSupply == 0, "poolTokenEffectiveSupply must be 0");
        uint256 totalAssetValue = getPoolTotalAssetsValue();

        TransferHelper.safeTransferFrom(address(BASE_LIQUIDITY_TOKEN), user, address(this), depositAmount);

        require(poolTokenEffectiveSupply == 0, "poolTokenEffectiveSupply must be 0");
        require(getPoolTotalAssetsValue() == totalAssetValue, "total asset value must not change");

        baseTokenBalance += depositAmount;
        uint256 newTotalAssetValue = getPoolTotalAssetsValue();
        require(newTotalAssetValue != 0 && newTotalAssetValue >= depositAmount);
        uint256 poolTokensOut = newTotalAssetValue;
        _mintPoolTokensForUser(user, poolTokensOut);
        emit Stake(user, depositAmount, poolTokensOut);
        return poolTokensOut;
    }

    /// @dev This function is called when poolTokenEffectiveSupply great than zero
    ///
    /// @param user The address of user
    /// @param depositAmount Deposit tokens amount
    /// @return poolTokensOut The output pool token amount
    function _addLiquidityNormal(address user, uint256 depositAmount) private returns (uint256) {
        require(user != address(this) && user != address(0), "invalid user");
        require(depositAmount != 0, "depositAmount cannot be 0");

        require(poolTokenEffectiveSupply != 0, "poolTokenEffectiveSupply must not be 0");
        require(getPoolTotalAssetsValue() != 0, "total asset value must not be 0");

        TransferHelper.safeTransferFrom(address(BASE_LIQUIDITY_TOKEN), user, address(this), depositAmount);
        require(poolTokenEffectiveSupply != 0, "poolTokenEffectiveSupply cannot be 0");

        uint256 totalAssetValue = getPoolTotalAssetsValue();
        require(totalAssetValue != 0, "total asset value cannot be 0");
        uint256 poolTokensOut = getPoolDepositConversion(depositAmount);

        baseTokenBalance += depositAmount;
        _mintPoolTokensForUser(user, poolTokensOut);
        emit Stake(user, depositAmount, poolTokensOut);
        return poolTokensOut;
    }

    /// @dev Add liquidity tokens to liquidity pools
    ///
    /// @param user The address of user
    /// @param depositAmount Deposit tokens amount
    /// @return poolTokensOut The output pool token amount
    function _addLiquidity(address user, uint256 depositAmount) private returns (uint256) {
        require(user != address(this) && user != address(0), "invalid user");
        require(!isNodeDecomissioning(), "BankNode bonded amount is less than 75% of the minimum");

        require(depositAmount != 0, "depositAmount cannot be 0");
        if (poolTokenEffectiveSupply == 0) {
            return _setupLiquidityFirst(user, depositAmount);
        } else {
            return _addLiquidityNormal(user, depositAmount);
        }
    }

    /// @dev Remove liquidity tokens from the liquidity pool
    function _removeLiquidityNoLockup(address user, uint256 poolTokensToConsume) private returns (uint256) {
        require(user != address(this) && user != address(0), "invalid user");

        require(
            poolTokensToConsume != 0 && poolTokensToConsume <= poolTokenEffectiveSupply,
            "poolTokenAmount cannot be 0 or more than circulating"
        );

        require(poolTokenEffectiveSupply != 0, "poolTokenEffectiveSupply must not be 0");
        require(getPoolTotalAssetsValue() != 0, "total asset value must not be 0");

        uint256 baseTokensOut = getPoolWithdrawConversion(poolTokensToConsume);
        poolTokenEffectiveSupply -= poolTokensToConsume;
        require(baseTokenBalance >= baseTokensOut, "base tokens balance must be >= out");
        TransferHelper.safeTransferFrom(address(POOL_LIQUIDITY_TOKEN), user, address(this), poolTokensToConsume);
        require(baseTokenBalance >= baseTokensOut, "base tokens balance must be >= out");
        baseTokenBalance -= baseTokensOut;
        TransferHelper.safeTransfer(address(BASE_LIQUIDITY_TOKEN), user, baseTokensOut);
        emit Unstake(user, baseTokensOut, poolTokensToConsume);
        return baseTokensOut;
    }

    /// @dev Remove liquidity tokens from liquidity pools
    function _removeLiquidity(address user, uint256 poolTokensToConsume) internal returns (uint256) {
        require(poolTokensToConsume != 0, "poolTokensToConsume cannot be 0");
        uint256 unstakeLockupPeriod = getUnstakeLockupPeriod();
        if (unstakeLockupPeriod == 0) {
            return _removeLiquidityNoLockup(user, poolTokensToConsume);
        } else {
            return _removeLiquidityAndLock(user, poolTokensToConsume, unstakeLockupPeriod);
        }
    }

    /// @notice Allows a user to donate `donateAmount` of BNPL to the pool (user must first approve)
    /// @param donateAmount The donate amount of BNPL
    function donate(uint256 donateAmount) external override nonReentrant {
        require(donateAmount != 0, "donateAmount cannot be 0");
        _processDonation(msg.sender, donateAmount, true);
    }

    /// @notice Allows a user to donate `donateAmount` of BNPL to the pool (not conted in total) (user must first approve)
    /// @param donateAmount The donate amount of BNPL
    function donateNotCountedInTotal(uint256 donateAmount) external override nonReentrant {
        require(donateAmount != 0, "donateAmount cannot be 0");
        _processDonation(msg.sender, donateAmount, false);
    }

    /// @notice Allows a user to bond `bondAmount` of BNPL to the pool (user must first approve)
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "NODE_REWARDS_MANAGER_ROLE"
    ///
    /// @param bondAmount The bond amount of BNPL
    function bondTokens(uint256 bondAmount) external override nonReentrant onlyRole(NODE_REWARDS_MANAGER_ROLE) {
        require(bondAmount != 0, "bondAmount cannot be 0");
        _processBondTokens(msg.sender, bondAmount);
    }

    /// @notice Allows a user to unbond BNPL from the pool
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "NODE_REWARDS_MANAGER_ROLE"
    ///
    function unbondTokens() external override nonReentrant onlyRole(NODE_REWARDS_MANAGER_ROLE) {
        _processUnbondTokens(msg.sender);
    }

    /// @notice Allows a user to stake `stakeAmount` of BNPL to the pool (user must first approve)
    /// @param stakeAmount Stake token amount
    function stakeTokens(uint256 stakeAmount) external override nonReentrant {
        require(
            bnplKYCStore.checkUserBasicBitwiseMode(kycDomainId, msg.sender, BNPL_STAKER_NEEDS_KYC) == 1,
            "borrower needs kyc"
        );
        require(stakeAmount != 0, "stakeAmount cannot be 0");
        _addLiquidity(msg.sender, stakeAmount);
    }

    /// @notice Allows a user to unstake `unstakeAmount` of BNPL from the pool (puts it into a lock up for a 7 day cool down period)
    /// @param unstakeAmount Unstake token amount
    function unstakeTokens(uint256 unstakeAmount) external override nonReentrant {
        require(unstakeAmount != 0, "unstakeAmount cannot be 0");
        _removeLiquidity(msg.sender, unstakeAmount);
    }

    /// @dev Handle slash
    function _slash(uint256 slashAmount, address recipient) private {
        require(slashAmount < getPoolTotalAssetsValue(), "cannot slash more than the pool balance");
        baseTokenBalance -= slashAmount;
        totalSlashedAllTime += slashAmount;
        TransferHelper.safeTransfer(address(BASE_LIQUIDITY_TOKEN), recipient, slashAmount);
        emit Slash(recipient, slashAmount);
    }

    /// @notice Allows an authenticated contract/user (in this case, only BNPLBankNode) to slash `slashAmount` of BNPL from the pool
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "SLASHER_ROLE"
    ///
    /// @param slashAmount The slash amount
    function slash(uint256 slashAmount) external override onlyRole(SLASHER_ROLE) nonReentrant {
        _slash(slashAmount, msg.sender);
    }

    /// @notice Claim node owner pool BNPL token rewards
    /// @return rewards Claimed reward pool token amount
    function getNodeOwnerPoolTokenRewards() public view override returns (uint256) {
        uint256 equivalentPoolTokens = getPoolDepositConversion(tokensBondedAllTime);
        uint256 ownerPoolTokens = POOL_LIQUIDITY_TOKEN.balanceOf(address(this));
        if (ownerPoolTokens > equivalentPoolTokens) {
            return ownerPoolTokens - equivalentPoolTokens;
        }
        return 0;
    }

    /// @notice Claim node owner BNPL token rewards
    /// @return rewards Claimed reward BNPL token amount
    function getNodeOwnerBNPLRewards() external view override returns (uint256) {
        uint256 rewardsAmount = getNodeOwnerPoolTokenRewards();
        if (rewardsAmount != 0) {
            return getPoolWithdrawConversion(rewardsAmount);
        }
        return 0;
    }

    /// @notice Claim node owner pool token rewards to address `to`
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "NODE_REWARDS_MANAGER_ROLE"
    ///
    /// @param to Address to receive rewards
    function claimNodeOwnerPoolTokenRewards(address to)
        external
        override
        onlyRole(NODE_REWARDS_MANAGER_ROLE)
        nonReentrant
    {
        uint256 poolTokenRewards = getNodeOwnerPoolTokenRewards();
        require(poolTokenRewards > 0, "cannot claim 0 rewards");
        virtualPoolTokensCount -= poolTokenRewards;
        POOL_LIQUIDITY_TOKEN.transfer(to, poolTokenRewards);
    }

    /// @notice Calculates the amount of BNPL to slash from the pool given a Bank Node loss of `nodeLoss`
    /// with a previous balance of `prevNodeBalance` and the current pool balance containing `poolBalance` BNPL.
    ///
    /// @param prevNodeBalance The bank node previous balance
    /// @param nodeLoss The bank node loss
    /// @param poolBalance The bank node current pool balance
    /// @return SlashAmount Calculated slash amount
    function calculateSlashAmount(
        uint256 prevNodeBalance,
        uint256 nodeLoss,
        uint256 poolBalance
    ) external pure returns (uint256) {
        uint256 slashRatio = (nodeLoss * PRBMathUD60x18.scale()).div(prevNodeBalance * PRBMathUD60x18.scale());
        return (poolBalance * slashRatio) / PRBMathUD60x18.scale();
    }

    /// @notice Claim the next token lockup vault they have locked up in the contract.
    ///
    /// @param user The address of user
    /// @return claimTokenLockup claim token lockup amount
    function claimTokenLockup(address user) external nonReentrant returns (uint256) {
        return _claimNextTokenLockup(user);
    }

    /// @notice Claim the next token lockup vaults they have locked up in the contract.
    ///
    /// @param user The address of user
    /// @param maxNumberOfClaims The max number of claims
    /// @return claimTokenNextNLockups claim token amount next N lockups
    function claimTokenNextNLockups(address user, uint32 maxNumberOfClaims) external nonReentrant returns (uint256) {
        return _claimUpToNextNTokenLockups(user, maxNumberOfClaims);
    }

    /// @notice Allows rewards manager to unlock lending token interest.
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "NODE_REWARDS_MANAGER_ROLE"
    ///
    /// - Distribute dividends can only be done after unlocking the lending token interest
    function unlockLendingTokenInterest() external onlyRole(NODE_REWARDS_MANAGER_ROLE) nonReentrant {
        bankNode.rewardToken().cooldown();
    }

    /// @notice Distribute dividends with token interest
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "NODE_REWARDS_MANAGER_ROLE"
    ///
    function distributeDividends() external onlyRole(NODE_REWARDS_MANAGER_ROLE) nonReentrant {
        bankNode.rewardToken().claimRewards(address(this), type(uint256).max);

        uint256 rewardTokenAmount = IERC20(address(bankNode.rewardToken())).balanceOf(address(this));
        require(rewardTokenAmount > 0, "rewardTokenAmount must be > 0");

        TransferHelper.safeApprove(address(bankNode.rewardToken()), address(bankNode.rewardToken()), rewardTokenAmount);
        bankNode.rewardToken().redeem(address(this), rewardTokenAmount);

        IERC20 swapToken = IERC20(bankNode.rewardToken().REWARD_TOKEN());

        uint256 donateAmount = bankNode.bnplSwapMarket().swapExactTokensForTokens(
            swapToken.balanceOf(address(this)),
            0,
            BankNodeUtils.getSwapExactTokensPath(address(swapToken), address(BASE_LIQUIDITY_TOKEN)),
            address(this),
            block.timestamp
        )[2];
        require(donateAmount > 0, "swap amount must be > 0");

        TransferHelper.safeApprove(address(BASE_LIQUIDITY_TOKEN), address(this), donateAmount);
        _processDonation(msg.sender, donateAmount, false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {IGenericMintableTo} from "./IGenericMintableTo.sol";
import {IGenericBurnableFrom} from "./IGenericBurnableFrom.sol";

/**
 * @dev Interface of the IMintableTokenUpgradeable standard
 */
interface IMintableTokenUpgradeable is IGenericMintableTo, IERC20Upgradeable {

}

/**
 * @dev Interface of the IMintableBurnableTokenUpgradeable standard
 */
interface IMintableBurnableTokenUpgradeable is IMintableTokenUpgradeable, IGenericBurnableFrom {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBNPLProtocolConfig} from "../../ProtocolDeploy/interfaces/IBNPLProtocolConfig.sol";

import {BNPLKYCStore} from "../BNPLKYCStore.sol";
import {BankNodeLendingRewards} from "../../Rewards/PlatformRewards/BankNodeLendingRewards.sol";

/// @title BNPL BankNodeManager contract
///
/// @notice
/// - Features:
///     **Create a bank node**
///     **Add lendable token**
///     **Set minimum BankNode bonded amount**
///     **Set loan overdue grace period**
///
/// @author BNPL
interface IBankNodeManager {
    struct LendableToken {
        address tokenContract;
        address swapMarket;
        uint24 swapMarketPoolFee;
        uint8 decimals;
        uint256 valueMultiplier;
        uint16 unusedFundsLendingMode;
        address unusedFundsLendingContract;
        address unusedFundsLendingToken;
        address unusedFundsIncentivesController;
        string symbol;
        string poolSymbol;
    }

    struct BankNode {
        address bankNodeContract;
        address bankNodeToken;
        address bnplStakingPoolContract;
        address bnplStakingPoolToken;
        address lendableToken;
        address creator;
        uint32 id;
        uint64 createdAt;
        uint256 createBlock;
        string nodeName;
        string website;
        string configUrl;
    }

    struct BankNodeDetail {
        uint256 totalAssetsValueBankNode;
        uint256 totalAssetsValueStakingPool;
        uint256 tokensCirculatingBankNode;
        uint256 tokensCirculatingStakingPool;
        uint256 totalLiquidAssetsValue;
        uint256 baseTokenBalanceBankNode;
        uint256 baseTokenBalanceStakingPool;
        uint256 accountsReceivableFromLoans;
        uint256 virtualPoolTokensCount;
        address baseLiquidityToken;
        address poolLiquidityToken;
        bool isNodeDecomissioning;
        uint256 nodeOperatorBalance;
        uint256 loanRequestIndex;
        uint256 loanIndex;
        uint256 valueOfUnusedFundsLendingDeposits;
        uint256 totalLossAllTime;
        uint256 onGoingLoanCount;
        uint256 totalTokensLocked;
        uint256 getUnstakeLockupPeriod;
        uint256 tokensBondedAllTime;
        uint256 poolTokenEffectiveSupply;
        uint256 nodeTotalStaked;
        uint256 nodeBondedBalance;
        uint256 nodeOwnerBNPLRewards;
        uint256 nodeOwnerPoolTokenRewards;
    }

    struct BankNodeData {
        BankNode data;
        BankNodeDetail detail;
    }

    struct CreateBankNodeContractsInput {
        uint32 bankNodeId;
        address operatorAdmin;
        address operator;
        address lendableTokenAddress;
    }

    struct CreateBankNodeContractsOutput {
        address bankNodeContract;
        address bankNodeToken;
        address bnplStakingPoolContract;
        address bnplStakingPoolToken;
    }

    /// @notice Get whether the banknode exists
    ///
    /// @param bankNodeId The bank node id
    /// @return BankNodeIdExists Returns `0` when it does not exist, otherwise returns `1`
    function bankNodeIdExists(uint32 bankNodeId) external view returns (uint256);

    /// @notice Get the contract address of the specified bank node
    ///
    /// @param bankNodeId The bank node id
    /// @return BankNodeContract The contract address of the node
    function getBankNodeContract(uint32 bankNodeId) external view returns (address);

    /// @notice Get the lending pool token contract (ERC20) address of the specified bank node
    ///
    /// @param bankNodeId Bank node id
    /// @return BankNodeToken The lending pool token contract (ERC20) address of the node
    function getBankNodeToken(uint32 bankNodeId) external view returns (address);

    /// @notice Get the staking pool contract address of the specified bank node
    ///
    /// @param bankNodeId The bank node id
    /// @return BankNodeStakingPoolContract The staking pool contract address of the node
    function getBankNodeStakingPoolContract(uint32 bankNodeId) external view returns (address);

    /// @notice Get the staking pool token contract (ERC20) address of the specified bank node
    ///
    /// @param bankNodeId The bank node id
    /// @return BankNodeStakingPoolToken The staking pool token contract (ERC20) address of the node
    function getBankNodeStakingPoolToken(uint32 bankNodeId) external view returns (address);

    /// @notice Get the lendable token contract (ERC20) address of the specified bank node
    ///
    /// @param bankNodeId The bank node id
    /// @return BankNodeLendableToken The lendable token contract (ERC20) address of the node
    function getBankNodeLendableToken(uint32 bankNodeId) external view returns (address);

    /// @notice Get all bank nodes loan statistic
    ///
    /// @return totalAmountOfAllActiveLoans uint256 Total amount of all activeLoans
    /// @return totalAmountOfAllLoans uint256 Total amount of all loans
    function getBankNodeLoansStatistic()
        external
        view
        returns (uint256 totalAmountOfAllActiveLoans, uint256 totalAmountOfAllLoans);

    /// @notice Get BNPL KYC store contract
    ///
    /// @return BNPLKYCStore BNPL KYC store contract
    function bnplKYCStore() external view returns (BNPLKYCStore);

    /// @dev This contract is called through the proxy.
    ///
    /// @param _protocolConfig BNPLProtocolConfig contract address
    /// @param _configurator BNPL contract platform configurator address
    /// @param _minimumBankNodeBondedAmount The minimum BankNode bonded amount required to create the bankNode
    /// @param _loanOverdueGracePeriod Loan overdue grace period (secs)
    /// @param _bankNodeLendingRewards BankNodeLendingRewards contract address
    /// @param _bnplKYCStore BNPLKYCStore contract address
    function initialize(
        IBNPLProtocolConfig _protocolConfig,
        address _configurator,
        uint256 _minimumBankNodeBondedAmount,
        uint256 _loanOverdueGracePeriod,
        BankNodeLendingRewards _bankNodeLendingRewards,
        BNPLKYCStore _bnplKYCStore
    ) external;

    /// @notice Get whether lendable tokens are enabled
    ///
    /// @param lendableTokenAddress The lendable token contract (ERC20) address
    /// @return enabledLendableTokens Returns `0` when it does not exist, otherwise returns `1`
    function enabledLendableTokens(address lendableTokenAddress) external view returns (uint8);

    /// @notice Get lendable token data
    ///
    /// @param lendableTokenAddress The lendable token contract (ERC20) address
    /// @return tokenContract The lendable token contract (ERC20) address
    /// @return swapMarket The configured swap market contract address (ex. SushiSwap Router)
    /// @return swapMarketPoolFee The configured swap market fee
    /// @return decimals The decimals for lendable tokens
    /// @return valueMultiplier `USD_VALUE = amount * valueMultiplier / 10 ** 18`
    /// @return unusedFundsLendingMode lending mode (1)
    /// @return unusedFundsLendingContract (ex. AAVE lending pool contract address)
    /// @return unusedFundsLendingToken (ex. AAVE tokens contract address)
    /// @return unusedFundsIncentivesController (ex. AAVE incentives controller contract address)
    /// @return symbol The lendable token symbol
    /// @return poolSymbol The pool lendable token symbol
    function lendableTokens(address lendableTokenAddress)
        external
        view
        returns (
            address tokenContract,
            address swapMarket,
            uint24 swapMarketPoolFee,
            uint8 decimals,
            uint256 valueMultiplier, //USD_VALUE = amount * valueMultiplier / 10**18
            uint16 unusedFundsLendingMode,
            address unusedFundsLendingContract,
            address unusedFundsLendingToken,
            address unusedFundsIncentivesController,
            string calldata symbol,
            string calldata poolSymbol
        );

    /// @notice Get bank node data according to the specified id
    ///
    /// @param bankNodeId The bank node id
    /// @return bankNodeContract The bank node contract address
    /// @return bankNodeToken The bank node token contract (ERC20) address
    /// @return bnplStakingPoolContract The bank node staking pool contract address
    /// @return bnplStakingPoolToken The bank node staking pool token contract (ERC20) address
    /// @return lendableToken The bank node lendable token contract (ERC20) address
    /// @return creator The bank node creator address
    /// @return id The bank node id
    /// @return createdAt The creation time of the bank node
    /// @return createBlock The creation block of the bank node
    /// @return nodeName The name of the bank node
    /// @return website The website of the bank node
    /// @return configUrl The config url of the bank node
    function bankNodes(uint32 bankNodeId)
        external
        view
        returns (
            address bankNodeContract,
            address bankNodeToken,
            address bnplStakingPoolContract,
            address bnplStakingPoolToken,
            address lendableToken,
            address creator,
            uint32 id,
            uint64 createdAt,
            uint256 createBlock,
            string calldata nodeName,
            string calldata website,
            string calldata configUrl
        );

    /// @notice Get bank node id with bank node address
    /// @return bankNodeId Bank node id
    function bankNodeAddressToId(address bankNodeAddressTo) external view returns (uint32);

    /// @notice Get BNPL platform protocol config contract
    /// @return minimumBankNodeBondedAmount BNPL protocol config contract
    function minimumBankNodeBondedAmount() external view returns (uint256);

    /// @notice Get the loan overdue grace period currently configured on the platform
    /// @return loanOverdueGracePeriod loan overdue grace period (secs)
    function loanOverdueGracePeriod() external view returns (uint256);

    /// @notice Get the current total number of platform bank nodes
    /// @return bankNodeCount Number of platform bank nodes
    function bankNodeCount() external view returns (uint32);

    /// @notice Get BNPL token contract
    /// @return bnplToken BNPL token contract
    function bnplToken() external view returns (IERC20);

    /// @notice Get bank node lending rewards contract
    /// @return bankNodeLendingRewards Bank node lending rewards contract
    function bankNodeLendingRewards() external view returns (BankNodeLendingRewards);

    /// @notice Get BNPL platform protocol config contract
    /// @return protocolConfig BNPL protocol config contract
    function protocolConfig() external view returns (IBNPLProtocolConfig);

    /// @notice Get bank node details list (pagination supported)
    ///
    /// @param start Where to start getting bank node
    /// @param count How many bank nodes to get
    /// @param reverse Whether to return the list in reverse order
    /// @return BankNodeList bank node details array
    /// @return BankNodeCount bank node count
    function getBankNodeList(
        uint32 start,
        uint32 count,
        bool reverse
    ) external view returns (BankNodeData[] memory, uint32);

    /// @notice Get bank node data with `bankNode` address
    ///
    /// @param bankNode bank node contract address
    /// @return bank node detail struct
    function getBankNodeDetail(address bankNode) external view returns (BankNodeDetail memory);

    /// @dev Add support for a new ERC20 token to be used as lendable tokens for new bank nodes
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "CONFIGURE_NODE_MANAGER_ROLE"
    ///
    /// @param _lendableToken LendableToken configuration structure.
    /// @param enabled `0` or `1`, Whether to enable (cannot be used to create bank node after disable)
    ///
    /// **`_lendableToken` parameters:**
    ///
    /// ```solidity
    /// address tokenContract The lendable token contract (ERC20) address
    /// address swapMarket The configured swap market contract address (ex. SushiSwap Router)
    /// uint24 swapMarketPoolFee The configured swap market fee
    /// uint8 decimals The decimals for lendable tokens
    /// uint256 valueMultiplier `USD_VALUE = amount * valueMultiplier / 10 ** 18`
    /// uint16 unusedFundsLendingMode lending mode (1)
    /// address unusedFundsLendingContract (ex. AAVE lending pool contract address)
    /// address unusedFundsLendingToken (ex. AAVE tokens contract address)
    /// address unusedFundsIncentivesController (ex. AAVE incentives controller contract address)
    /// string symbol The lendable token symbol
    /// string poolSymbol The pool lendable token symbol
    /// ```
    function addLendableToken(LendableToken calldata _lendableToken, uint8 enabled) external;

    /// @dev Enable/Disable support for ERC20 tokens to be used as lendable tokens for new bank nodes (does not effect existing nodes)
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "CONFIGURE_NODE_MANAGER_ROLE"
    ///
    /// @param tokenContract lendable token contract address
    /// @param enabled `0` or `1`, Whether to enable (cannot be used to create bank node after disable)
    function setLendableTokenStatus(address tokenContract, uint8 enabled) external;

    /// @dev Set the minimum BNPL to bond per node
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "CONFIGURE_NODE_MANAGER_ROLE"
    ///
    /// @param _minimumBankNodeBondedAmount minium bank node bonded amount
    function setMinimumBankNodeBondedAmount(uint256 _minimumBankNodeBondedAmount) external;

    /// @dev Set the loan overdue grace period per node
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "CONFIGURE_NODE_MANAGER_ROLE"
    ///
    /// @param _loanOverdueGracePeriod loan overdue grace period (secs)
    function setLoanOverdueGracePeriod(uint256 _loanOverdueGracePeriod) external;

    /// @notice Creates a new bonded bank node
    ///
    /// @dev
    /// - Steps:
    ///    1) Create bank node proxy contract
    ///    2) Create staking pool proxy contract
    ///    3) Create staking pool ERC20 token
    ///    4) Create bank node ERC20 token
    ///    5) Initialize bank node proxy contract
    ///    6) Bond tokens
    ///    7) Initialize staking pool proxy contract
    ///    8) Settings
    ///
    /// @param operator The node operator who will be assigned the permissions of bank node admin for the newly created bank node
    /// @param tokensToBond The number of BNPL tokens to bond for the node
    /// @param lendableTokenAddress Which lendable token will be lent to borrowers for this bank node (ex. the address of USDT's erc20 smart contract)
    /// @param nodeName The official name of the bank node
    /// @param website The official website of the bank node
    /// @param configUrl The bank node config file url
    /// @param nodePublicKey KYC public key
    /// @param kycMode KYC mode
    /// @return BankNodeId bank node id
    function createBondedBankNode(
        address operator,
        uint256 tokensToBond,
        address lendableTokenAddress,
        string calldata nodeName,
        string calldata website,
        string calldata configUrl,
        address nodePublicKey,
        uint32 kycMode
    ) external returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IStakedToken} from "../../Aave/interfaces/IStakedToken.sol";
import {IAaveLendingPool} from "../../Aave/interfaces/IAaveLendingPool.sol";
import {IAaveIncentivesController} from "../../Aave/interfaces/IAaveIncentivesController.sol";

import {IMintableBurnableTokenUpgradeable} from "../../ERC20/interfaces/IMintableBurnableTokenUpgradeable.sol";
import {IBNPLSwapMarket} from "../../SwapMarket/interfaces/IBNPLSwapMarket.sol";
import {IBankNodeManager} from "../../Management/interfaces/IBankNodeManager.sol";

import {BNPLKYCStore} from "../../Management/BNPLKYCStore.sol";
import {IBNPLNodeStakingPool} from "./IBNPLNodeStakingPool.sol";

/// @dev Interface of the IBNPLBankNode standard
/// @author BNPL
interface IBankNodeInitializableV1 {
    struct BankNodeInitializeArgsV1 {
        uint32 bankNodeId; // The id of bank node
        uint24 bnplSwapMarketPoolFee; // The configured swap market fee
        address bankNodeManager; // The address of bank node manager
        address operatorAdmin; // The admin with `OPERATOR_ADMIN_ROLE` role
        address operator; // The admin with `OPERATOR_ROLE` role
        address bnplToken; // BNPL token address
        address bnplSwapMarket; // The swap market contract (ex. Sushiswap Router)
        uint16 unusedFundsLendingMode; // Lending mode (1)
        address unusedFundsLendingContract; // Lending contract (ex. AAVE lending pool)
        address unusedFundsLendingToken; // (ex. aTokens)
        address unusedFundsIncentivesController; // (ex. AAVE incentives controller)
        address nodeStakingPool; // The staking pool of bank node
        address baseLiquidityToken; // Liquidity token contract (ex. USDT)
        address poolLiquidityToken; // Pool liquidity token contract (ex. Pool USDT)
        address nodePublicKey; // Bank node KYC public key
        uint32 kycMode; // kycMode Bank node KYC mode
    }

    /// @dev BankNode contract is created and initialized by the BankNodeManager contract
    ///
    /// - This contract is called through the proxy.
    ///
    /// @param bankNodeInitConfig BankNode configuration (passed in by BankNodeManager contract)
    ///
    /// `BankNodeInitializeArgsV1` paramerter structure:
    ///
    /// ```solidity
    /// uint32 bankNodeId // The id of bank node
    /// uint24 bnplSwapMarketPoolFee // The configured swap market fee
    /// address bankNodeManager // The address of bank node manager
    /// address operatorAdmin // The admin with `OPERATOR_ADMIN_ROLE` role
    /// address operator // The admin with `OPERATOR_ROLE` role
    /// uint256 bnplToken // BNPL token address
    /// address bnplSwapMarket // The swap market contract (ex. Sushiswap Router)
    /// uint16 unusedFundsLendingMode // Lending mode (1)
    /// address unusedFundsLendingContract // Lending contract (ex. AAVE lending pool)
    /// address unusedFundsLendingToken // (ex. AAVE aTokens)
    /// address unusedFundsIncentivesController // (ex. AAVE incentives controller)
    /// address nodeStakingPool // The staking pool of bank node
    /// address baseLiquidityToken // Liquidity token contract (ex. USDT)
    /// address poolLiquidityToken // Pool liquidity token contract (ex. Pool USDT)
    /// address nodePublicKey // Bank node KYC public key
    /// uint32 // kycMode Bank node KYC mode
    /// ```
    function initialize(BankNodeInitializeArgsV1 calldata bankNodeInitConfig) external;
}

/**
 * @dev Interface of the IBNPLBankNode standard
 */
interface IBNPLBankNode is IBankNodeInitializableV1 {
    struct Loan {
        address borrower;
        uint256 loanAmount;
        uint64 totalLoanDuration;
        uint32 numberOfPayments;
        uint64 loanStartedAt;
        uint32 numberOfPaymentsMade;
        uint256 amountPerPayment;
        uint256 interestRatePerPayment;
        uint256 totalAmountPaid;
        uint256 remainingBalance;
        uint8 status; // 0 = ongoing, 1 = completed, 2 = overdue, 3 = written off
        uint64 statusUpdatedAt;
        uint256 loanRequestId;
    }

    /// @dev Get lending mode (1)
    /// @return lendingMode
    function unusedFundsLendingMode() external view returns (uint16);

    /// @notice AAVE lending pool contract address
    /// @return AaveLendingPool
    function unusedFundsLendingContract() external view returns (IAaveLendingPool);

    /// @notice AAVE tokens contract
    /// @return LendingToken
    function unusedFundsLendingToken() external view returns (IERC20);

    /// @notice AAVE incentives controller contract
    /// @return AaveIncentivesController
    function unusedFundsIncentivesController() external view returns (IAaveIncentivesController);

    /// @notice The configured lendable token swap market contract (ex. SushiSwap Router)
    /// @return BNPLSwapMarket
    function bnplSwapMarket() external view returns (IBNPLSwapMarket);

    /// @notice The configured swap market fee
    /// @return bnplSwapMarketPoolFee
    function bnplSwapMarketPoolFee() external view returns (uint24);

    /// @notice The id of bank node
    /// @return bankNodeId
    function bankNodeId() external view returns (uint32);

    /// @notice Returns total assets value of bank node
    /// @return poolTotalAssetsValue
    function getPoolTotalAssetsValue() external view returns (uint256);

    /// @notice Returns total liquidity assets value of bank node (Exclude `accountsReceivableFromLoans`)
    /// @return poolTotalLiquidAssetsValue
    function getPoolTotalLiquidAssetsValue() external view returns (uint256);

    /// @notice The staking pool proxy contract
    /// @return BNPLNodeStakingPool
    function nodeStakingPool() external view returns (IBNPLNodeStakingPool);

    /// @notice The bank node manager proxy contract
    /// @return BankNodeManager
    function bankNodeManager() external view returns (IBankNodeManager);

    /// @notice Liquidity token (ex. USDT) balance of this
    /// @return baseTokenBalance
    function baseTokenBalance() external view returns (uint256);

    /// @notice Returns `unusedFundsLendingToken` (ex. AAVE aTokens) balance of this
    /// @return unusedFundsLendingTokenBalance AAVE aTokens balance of this
    function getValueOfUnusedFundsLendingDeposits() external view returns (uint256);

    /// @notice The balance of bank node admin
    /// @return nodeOperatorBalance
    function nodeOperatorBalance() external view returns (uint256);

    /// @notice Accounts receivable from loans
    /// @return accountsReceivableFromLoans
    function accountsReceivableFromLoans() external view returns (uint256);

    /// @notice Pool liquidity tokens (ex. Pool USDT) circulating
    /// @return poolTokensCirculating
    function poolTokensCirculating() external view returns (uint256);

    /// @notice Current loan request index (pending)
    /// @return loanRequestIndex
    function loanRequestIndex() external view returns (uint256);

    /// @notice Number of loans in progress
    /// @return onGoingLoanCount
    function onGoingLoanCount() external view returns (uint256);

    /// @notice Current loan index (approved)
    /// @return loanIndex
    function loanIndex() external view returns (uint256);

    /// @notice The total amount of all activated loans
    /// @return totalAmountOfActiveLoans
    function totalAmountOfActiveLoans() external view returns (uint256);

    /// @notice The total amount of all loans
    /// @return totalAmountOfLoans
    function totalAmountOfLoans() external view returns (uint256);

    /// @notice Liquidity token contract (ex. USDT)
    /// @return baseLiquidityToken
    function baseLiquidityToken() external view returns (IERC20);

    /// @notice Pool liquidity token contract (ex. Pool USDT)
    /// @return poolLiquidityToken
    function poolLiquidityToken() external view returns (IMintableBurnableTokenUpgradeable);

    /// @notice [Loan id] => [Interest paid for]
    ///
    /// @param loanId The id of loan
    /// @return interestPaidForLoan
    function interestPaidForLoan(uint256 loanId) external view returns (uint256);

    /// @notice The total loss amount of bank node
    /// @return totalLossAllTime
    function totalLossAllTime() external view returns (uint256);

    /// @notice Cumulative value of donate amounts
    /// @return totalDonatedAllTime
    function totalDonatedAllTime() external view returns (uint256);

    /// @notice The total amount of net earnings
    /// @return netEarnings
    function netEarnings() external view returns (uint256);

    /// @notice The total number of loans defaulted
    /// @return totalLoansDefaulted
    function totalLoansDefaulted() external view returns (uint256);

    /// @notice Get bank node KYC public key
    /// @return nodeKycPublicKey
    function nodePublicKey() external view returns (address);

    /// @notice Get bank node KYC mode
    /// @return kycMode
    function kycMode() external view returns (uint256);

    /// @notice The corresponding id in the BNPL KYC store
    /// @return kycDomainId
    function kycDomainId() external view returns (uint32);

    /// @notice The BNPL KYC store contract
    /// @return bnplKYCStore
    function bnplKYCStore() external view returns (BNPLKYCStore);

    /// @notice [Loan request id] => [Loan request]
    /// @param _loanRequestId The id of loan request
    function loanRequests(uint256 _loanRequestId)
        external
        view
        returns (
            address borrower,
            uint256 loanAmount,
            uint64 totalLoanDuration,
            uint32 numberOfPayments,
            uint256 amountPerPayment,
            uint256 interestRatePerPayment,
            uint8 status, // 0 = under review, 1 = rejected, 2 = cancelled, 3 = *unused for now*, 4 = approved
            uint64 statusUpdatedAt,
            address statusModifiedBy,
            uint256 interestRate,
            uint256 loanId,
            uint8 messageType, // 0 = plain text, 1 = encrypted with the public key
            string memory message,
            string memory uuid
        );

    /// @notice [Loan id] => [Loan]
    /// @param _loanId The id of loan
    function loans(uint256 _loanId)
        external
        view
        returns (
            address borrower,
            uint256 loanAmount,
            uint64 totalLoanDuration,
            uint32 numberOfPayments,
            uint64 loanStartedAt,
            uint32 numberOfPaymentsMade,
            uint256 amountPerPayment,
            uint256 interestRatePerPayment,
            uint256 totalAmountPaid,
            uint256 remainingBalance,
            uint8 status, // 0 = ongoing, 1 = completed, 2 = overdue, 3 = written off
            uint64 statusUpdatedAt,
            uint256 loanRequestId
        );

    /// @notice Donate `depositAmount` liquidity tokens to bankNode
    /// @param depositAmount Amount of user deposit to liquidity pool
    function donate(uint256 depositAmount) external;

    /// @notice Allow users to add liquidity tokens to liquidity pools.
    /// @dev The user will be issued an equal number of pool tokens
    ///
    /// @param depositAmount Amount of user deposit to liquidity pool
    function addLiquidity(uint256 depositAmount) external;

    /// @notice Allow users to remove liquidity tokens from liquidity pools.
    /// @dev Users need to replace liquidity tokens with the same amount of pool tokens
    ///
    /// @param poolTokensToConsume Amount of user removes from the liquidity pool
    function removeLiquidity(uint256 poolTokensToConsume) external;

    /// @notice Allows users to request a loan from the bank node
    ///
    /// @param loanAmount The loan amount
    /// @param totalLoanDuration The total loan duration (secs)
    /// @param numberOfPayments The number of payments
    /// @param interestRatePerPayment The interest rate per payment
    /// @param messageType 0 = plain text, 1 = encrypted with the public key
    /// @param message Writing detailed messages may increase loan approval rates
    /// @param uuid The `LoanRequested` event contains this uuid for easy identification
    function requestLoan(
        uint256 loanAmount,
        uint64 totalLoanDuration,
        uint32 numberOfPayments,
        uint256 interestRatePerPayment,
        uint8 messageType,
        string memory message,
        string memory uuid
    ) external;

    /// @notice Deny a loan request with id `loanRequestId`
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "OPERATOR_ROLE"
    ///
    /// @param loanRequestId The id of loan request
    function denyLoanRequest(uint256 loanRequestId) external;

    /// @notice Approve a loan request with id `loanRequestId`
    /// - This also sends the lending token requested to the borrower
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "OPERATOR_ROLE"
    ///
    /// @param loanRequestId The id of loan request
    function approveLoanRequest(uint256 loanRequestId) external;

    /// @notice Make a loan payment for loan with id `loanId`
    /// - This method will call the swap contract, so `minTokenOut` is required
    ///
    /// @param loanId The id of loan
    /// @param minTokenOut The minimum output token of swap, if the swap result is less than this value, it will fail
    function makeLoanPayment(uint256 loanId, uint256 minTokenOut) external;

    /// @notice Allows users report a loan with id `loanId` as being overdue
    /// - This method will call the swap contract, so `minTokenOut` is required
    ///
    /// @param loanId The id of loan
    /// @param minTokenOut The minimum output token of swap, if the swap result is less than this value, it will fail
    function reportOverdueLoan(uint256 loanId, uint256 minTokenOut) external;

    /// @notice Withdraw `amount` of balance to an address
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "OPERATOR_ROLE"
    ///
    /// @param amount Withdraw amount
    /// @param to Receiving address
    function withdrawNodeOperatorBalance(uint256 amount, address to) external;

    /// @notice Change kyc settings of bank node
    /// - Including `setKYCDomainMode` and `setKYCDomainPublicKey`
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "OPERATOR_ROLE"
    ///
    /// @param kycMode_ KYC mode
    /// @param nodePublicKey_ Bank node KYC public key
    function setKYCSettings(uint256 kycMode_, address nodePublicKey_) external;

    /// @notice Set KYC mode for specified kycdomain
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "OPERATOR_ROLE"
    ///
    /// @param domain KYC domain
    /// @param mode KYC mode
    function setKYCDomainMode(uint32 domain, uint256 mode) external;

    /// @notice Returns incentives controller reward token (ex. stkAAVE)
    /// @return stakedAAVE
    function rewardToken() external view returns (IStakedToken);

    /// @notice Get reward token (stkAAVE) unclaimed rewards balance of bank node
    /// @return rewardsBalance
    function getRewardsBalance() external view returns (uint256);

    /// @notice Get reward token (stkAAVE) cool down start time of staking pool
    /// @return cooldownStartTimestamp
    function getCooldownStartTimestamp() external view returns (uint256);

    /// @notice Get reward token (stkAAVE) rewards balance of staking pool
    /// @return stakedTokenRewardsBalance
    function getStakedTokenRewardsBalance() external view returns (uint256);

    /// @notice Get reward token (stkAAVE) balance of staking pool
    /// @return stakedTokenBalance
    function getStakedTokenBalance() external view returns (uint256);

    /// @notice Claim lending token interest
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "OPERATOR_ROLE"
    ///
    /// @return lendingTokenInterest
    function claimLendingTokenInterest() external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BNPLKYCStore} from "../../Management/BNPLKYCStore.sol";
import {IUserTokenLockup} from "./IUserTokenLockup.sol";

/// @dev Interface of the IBankNodeStakingPoolInitializableV1 standard
/// @author BNPL
interface IBankNodeStakingPoolInitializableV1 {
    /// @dev StakingPool contract is created and initialized by the BankNodeManager contract
    ///
    /// - This contract is called through the proxy.
    ///
    /// @param bnplToken BNPL token address
    /// @param poolBNPLToken pool BNPL token address
    /// @param bankNodeContract BankNode contract address associated with stakingPool
    /// @param bankNodeManagerContract BankNodeManager contract address
    /// @param tokenBonder The address of the BankNode creator
    /// @param tokensToBond The amount of BNPL bound by the BankNode creator (initial liquidity amount)
    /// @param bnplKYCStore_ KYC store contract address
    /// @param kycDomainId_ KYC store domain id
    function initialize(
        address bnplToken,
        address poolBNPLToken,
        address bankNodeContract,
        address bankNodeManagerContract,
        address tokenBonder,
        uint256 tokensToBond,
        BNPLKYCStore bnplKYCStore_,
        uint32 kycDomainId_
    ) external;
}

/**
 * @dev Interface of the IBankNode standard
 */
interface IBNPLNodeStakingPool is IBankNodeStakingPoolInitializableV1, IUserTokenLockup {
    /// @notice Allows a user to donate `donateAmount` of BNPL to the pool (user must first approve)
    /// @param donateAmount The donate amount of BNPL
    function donate(uint256 donateAmount) external;

    /// @notice Allows a user to donate `donateAmount` of BNPL to the pool (not conted in total) (user must first approve)
    /// @param donateAmount The donate amount of BNPL
    function donateNotCountedInTotal(uint256 donateAmount) external;

    /// @notice Allows a user to bond `bondAmount` of BNPL to the pool (user must first approve)
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "NODE_REWARDS_MANAGER_ROLE"
    ///
    /// @param bondAmount The bond amount of BNPL
    function bondTokens(uint256 bondAmount) external;

    /// @notice Allows a user to unbond BNPL from the pool
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "NODE_REWARDS_MANAGER_ROLE"
    ///
    function unbondTokens() external;

    /// @notice Allows a user to stake `stakeAmount` of BNPL to the pool (user must first approve)
    /// @param stakeAmount Stake token amount
    function stakeTokens(uint256 stakeAmount) external;

    /// @notice Allows a user to unstake `unstakeAmount` of BNPL from the pool (puts it into a lock up for a 7 day cool down period)
    /// @param unstakeAmount Unstake token amount
    function unstakeTokens(uint256 unstakeAmount) external;

    /// @notice Allows an authenticated contract/user (in this case, only BNPLBankNode) to slash `slashAmount` of BNPL from the pool
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "SLASHER_ROLE"
    ///
    /// @param slashAmount The slash amount
    function slash(uint256 slashAmount) external;

    /// @notice Returns pool total assets value
    /// @return poolTotalAssetsValue
    function getPoolTotalAssetsValue() external view returns (uint256);

    /// @notice Returns pool withdraw conversion
    ///
    /// @param withdrawAmount The withdraw tokens amount
    /// @return poolWithdrawConversion
    function getPoolWithdrawConversion(uint256 withdrawAmount) external view returns (uint256);

    /// @notice Pool BNPL token balance
    /// @return virtualPoolTokensCount
    function virtualPoolTokensCount() external view returns (uint256);

    /// @notice Total assets value
    /// @return baseTokenBalance
    function baseTokenBalance() external view returns (uint256);

    /// @notice Returns unstake lockup period
    /// @return unstakeLockupPeriod
    function getUnstakeLockupPeriod() external pure returns (uint256);

    /// @notice Cumulative value of bonded tokens
    /// @return tokensBondedAllTime
    function tokensBondedAllTime() external view returns (uint256);

    /// @notice Pool BNPL token effective supply
    /// @return poolTokenEffectiveSupply
    function poolTokenEffectiveSupply() external view returns (uint256);

    /// @notice Claim node owner BNPL token rewards
    /// @return rewards Claimed reward BNPL token amount
    function getNodeOwnerBNPLRewards() external view returns (uint256);

    /// @notice Claim node owner pool BNPL token rewards
    /// @return rewards Claimed reward pool token amount
    function getNodeOwnerPoolTokenRewards() external view returns (uint256);

    /// @notice Returns pool tokens circulating
    /// @return poolTokensCirculating
    function poolTokensCirculating() external view returns (uint256);

    /// @notice Returns whether the BankNode has been decommissioned
    ///
    /// - When the liquidity tokens amount of the BankNode is less than minimum BankNode bonded amount, it is decommissioned
    ///
    /// @return isNodeDecomissioning
    function isNodeDecomissioning() external view returns (bool);

    /// @notice Claim node owner pool token rewards to address `to`
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "NODE_REWARDS_MANAGER_ROLE"
    ///
    /// @param to Address to receive rewards
    function claimNodeOwnerPoolTokenRewards(address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IUserTokenLockup} from "../interfaces/IUserTokenLockup.sol";

contract UserTokenLockup is Initializable, IUserTokenLockup {
    /// @dev Emitted when user `user` creates a lockup with an index of `vaultIndex` containing `amount` of tokens which can be claimed on `unlockDate`
    event LockupCreated(address indexed user, uint32 vaultIndex, uint256 amount, uint64 unlockDate);

    /// @dev Emitted when user `user` claims a lockup with an index of `vaultIndex` containing `amount` of tokens
    event LockupClaimed(address indexed user, uint256 amount, uint32 vaultIndex);

    /// @notice Tokens locked amount
    uint256 public override totalTokensLocked;

    /// @dev [user address] => [lockup status: Encoded(tokensLocked, currentVaultIndex, numberOfActiveVaults)]
    mapping(address => uint256) public encodedLockupStatuses;

    /// @dev [user token lockup key: Encoded(user address, vaultIndex)] => [token lockup value: Encoded(tokenAmount, unlockDate)]
    mapping(uint256 => uint256) public encodedTokenLockups;

    function _UserTokenLockup_init_unchained() internal initializer {}

    /// @dev Get current block timestamp
    /// @return blockTimestamp
    function _getTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @dev Should override this function
    function _issueUnlockedTokensToUser(
        address, /*user*/
        uint256 /*amount*/
    ) internal virtual returns (uint256) {
        require(false, "you must override this function");
        return 0;
    }

    /// @notice Encode user lockup status
    ///
    /// @param tokensLocked Tokens locked amount
    /// @param currentVaultIndex The current vault index
    /// @param numberOfActiveVaults The number of activeVaults
    /// @return userLockupStatus Encoded user lockup status
    function createUserLockupStatus(
        uint256 tokensLocked,
        uint32 currentVaultIndex,
        uint32 numberOfActiveVaults
    ) internal pure returns (uint256) {
        return (tokensLocked << 64) | (uint256(currentVaultIndex) << 32) | uint256(numberOfActiveVaults);
    }

    /// @notice Decode an encoded user lockup status
    ///
    /// @param lockupStatus Encoded user lockup status
    /// @return tokensLocked
    /// @return currentVaultIndex
    /// @return numberOfActiveVaults
    function decodeUserLockupStatus(uint256 lockupStatus)
        internal
        pure
        returns (
            uint256 tokensLocked,
            uint32 currentVaultIndex,
            uint32 numberOfActiveVaults
        )
    {
        tokensLocked = lockupStatus >> 64;
        currentVaultIndex = uint32((lockupStatus >> 32) & 0xffffffff);
        numberOfActiveVaults = uint32(lockupStatus & 0xffffffff);
    }

    function createTokenLockupKey(address user, uint32 vaultIndex) internal pure returns (uint256) {
        return (uint256(uint160(user)) << 32) | uint256(vaultIndex);
    }

    function decodeTokenLockupKey(uint256 tokenLockupKey) internal pure returns (address user, uint32 vaultIndex) {
        vaultIndex = uint32(tokenLockupKey & 0xffffffff);
        user = address(uint160(tokenLockupKey >> 32));
    }

    function createTokenLockupValue(uint256 tokenAmount, uint64 unlockDate) internal pure returns (uint256) {
        return (uint256(unlockDate) << 192) | tokenAmount;
    }

    function decodeTokenLockupValue(uint256 tokenLockupValue)
        internal
        pure
        returns (uint256 tokenAmount, uint64 unlockDate)
    {
        tokenAmount = tokenLockupValue & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        unlockDate = uint32(tokenLockupValue >> 192);
    }

    /// @notice Get user lockup status with address `user`
    ///
    /// @param user The address of user
    /// @return tokensLocked
    /// @return currentVaultIndex
    /// @return numberOfActiveVaults
    function userLockupStatus(address user)
        public
        view
        returns (
            uint256 tokensLocked,
            uint32 currentVaultIndex,
            uint32 numberOfActiveVaults
        )
    {
        return decodeUserLockupStatus(encodedLockupStatuses[user]);
    }

    /// @notice Get user lockup data
    ///
    /// @param user The address of user
    /// @param vaultIndex vault index
    /// @return tokenAmount
    /// @return unlockDate
    function getTokenLockup(address user, uint32 vaultIndex)
        public
        view
        returns (uint256 tokenAmount, uint64 unlockDate)
    {
        return decodeTokenLockupValue(encodedTokenLockups[createTokenLockupKey(user, vaultIndex)]);
    }

    /// @notice Get next token lockup for user
    ///
    /// @param user The address of user
    /// @return tokenAmount
    /// @return unlockDate
    /// @return vaultIndex
    function getNextTokenLockupForUser(address user)
        external
        view
        returns (
            uint256 tokenAmount,
            uint64 unlockDate,
            uint32 vaultIndex
        )
    {
        (, uint32 currentVaultIndex, ) = userLockupStatus(user);
        vaultIndex = currentVaultIndex;
        (tokenAmount, unlockDate) = getTokenLockup(user, currentVaultIndex);
    }

    function _createTokenLockup(
        address user,
        uint256 amount,
        uint64 unlockDate,
        bool allowAddToFutureVault
    ) internal returns (uint256) {
        require(amount > 0, "amount must be > 0");
        require(user != address(0), "cannot create a lockup for a null user");
        require(unlockDate > block.timestamp, "cannot create a lockup that expires now or in the past!");

        (uint256 tokensLocked, uint32 currentVaultIndex, uint32 numberOfActiveVaults) = userLockupStatus(user);
        require(
            amount < (0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - tokensLocked),
            "cannot store this many tokens in the locked contract at once!"
        );
        tokensLocked += amount;
        uint64 futureDate;

        if (
            numberOfActiveVaults != 0 &&
            currentVaultIndex != 0 &&
            (futureDate = uint64(encodedTokenLockups[createTokenLockupKey(user, currentVaultIndex)] >> 192)) >=
            unlockDate
        ) {
            require(
                allowAddToFutureVault || futureDate == unlockDate,
                "allowAddToFutureVault must be enabled to add to future vaults"
            );
            // if the current vault's date is later than our unlockDate, add the value to it
            amount +=
                encodedTokenLockups[createTokenLockupKey(user, currentVaultIndex)] &
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            unlockDate = futureDate;
        } else {
            currentVaultIndex += 1;
            numberOfActiveVaults += 1;
        }

        totalTokensLocked += amount;

        encodedLockupStatuses[user] = createUserLockupStatus(tokensLocked, currentVaultIndex, numberOfActiveVaults);

        encodedTokenLockups[createTokenLockupKey(user, currentVaultIndex)] = createTokenLockupValue(amount, unlockDate);

        return currentVaultIndex;
    }

    /// @dev Claim next token lockup
    function _claimNextTokenLockup(address user) internal returns (uint256) {
        require(user != address(0), "cannot claim for null user");
        (uint256 tokensLocked, uint32 currentVaultIndex, uint32 numberOfActiveVaults) = userLockupStatus(user);
        currentVaultIndex = currentVaultIndex + 1 - numberOfActiveVaults;

        require(tokensLocked > 0 && numberOfActiveVaults > 0 && currentVaultIndex > 0, "user has no tokens locked up!");
        (uint256 tokenAmount, uint64 unlockDate) = getTokenLockup(user, currentVaultIndex);
        require(tokenAmount > 0 && unlockDate <= _getTime(), "cannot claim tokens that have not matured yet!");
        numberOfActiveVaults -= 1;
        encodedLockupStatuses[user] = createUserLockupStatus(
            tokensLocked - tokenAmount,
            numberOfActiveVaults == 0 ? currentVaultIndex : (currentVaultIndex + 1),
            numberOfActiveVaults
        );
        require(totalTokensLocked >= tokenAmount, "not enough tokens locked in the contract!");
        totalTokensLocked -= tokenAmount;
        _issueUnlockedTokensToUser(user, tokenAmount);
        return tokenAmount;
    }

    /// @dev Claim up to next `N` token lockups
    function _claimUpToNextNTokenLockups(address user, uint32 maxNumberOfClaims) internal returns (uint256) {
        require(user != address(0), "cannot claim for null user");
        require(maxNumberOfClaims > 0, "cannot claim 0 lockups");
        (uint256 tokensLocked, uint32 currentVaultIndex, uint32 numberOfActiveVaults) = userLockupStatus(user);
        currentVaultIndex = currentVaultIndex + 1 - numberOfActiveVaults;

        require(tokensLocked > 0 && numberOfActiveVaults > 0 && currentVaultIndex > 0, "user has no tokens locked up!");
        uint256 curTimeShifted = _getTime() << 192;
        uint32 maxVaultIndex = (maxNumberOfClaims > numberOfActiveVaults ? numberOfActiveVaults : maxNumberOfClaims) +
            currentVaultIndex;
        uint256 userShifted = uint256(uint160(user)) << 32;
        uint256 totalAmountToClaim = 0;
        uint256 nextCandiate;

        while (
            currentVaultIndex < maxVaultIndex &&
            (nextCandiate = encodedTokenLockups[userShifted | uint256(currentVaultIndex)]) < curTimeShifted
        ) {
            totalAmountToClaim += nextCandiate & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            currentVaultIndex++;
            numberOfActiveVaults--;
        }
        require(totalAmountToClaim > 0 && currentVaultIndex > 1, "cannot claim nothing!");
        require(totalAmountToClaim <= tokensLocked, "cannot claim more than total locked!");
        if (numberOfActiveVaults == 0) {
            currentVaultIndex--;
        }

        encodedLockupStatuses[user] = createUserLockupStatus(
            tokensLocked - totalAmountToClaim,
            currentVaultIndex,
            numberOfActiveVaults
        );
        require(totalTokensLocked >= totalAmountToClaim, "not enough tokens locked in the contract!");
        totalTokensLocked -= totalAmountToClaim;
        _issueUnlockedTokensToUser(user, totalAmountToClaim);
        return totalAmountToClaim;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

/// @title BNPL KYC store contract.
///
/// @notice
/// - Features:
///   **Create and store KYC status**
///   **Create a KYC bank node**
///   **Change the KYC mode**
///   **Check the KYC status**
///   **Approve or reject the applicant**
///
/// @author BNPL
contract BNPLKYCStore is Initializable, ReentrancyGuardUpgradeable {
    using ECDSAUpgradeable for bytes32;

    /// @dev [Domain id] => [KYC public key]
    mapping(uint32 => address) public publicKeys;

    /// @dev [encode(Domain, User)] => [Permissions]
    mapping(uint256 => uint32) public domainPermissions;

    /// @dev [encode(Domain, User)] => [KYC status]
    mapping(uint256 => uint32) public userKycStatuses;

    /// @dev [Proof hash] => [Use status]
    mapping(bytes32 => uint8) public proofUsed;

    /// @dev [Domain id] => [KYC mode]
    mapping(uint32 => uint256) public domainKycMode;

    uint32 public constant PROOF_MAGIC = 0xfc203827;
    uint32 public constant DOMAIN_ADMIN_PERM = 0xffff;

    /// @notice The current number of domains in the KYC store
    uint32 public domainCount;

    /// @dev Encode KYC domain and user address into a uint256
    ///
    /// @param domain The domain id
    /// @param user The address of user
    /// @return KYCUserDomainKey Encoded user domain key
    function encodeKYCUserDomainKey(uint32 domain, address user) internal pure returns (uint256) {
        return (uint256(uint160(user)) << 32) | uint256(domain);
    }

    /// @dev Can only be operated by domain admin
    modifier onlyDomainAdmin(uint32 domain) {
        require(
            domainPermissions[encodeKYCUserDomainKey(domain, msg.sender)] == DOMAIN_ADMIN_PERM,
            "User must be an admin for this domain to perform this action"
        );
        _;
    }

    /// @notice Get domain permissions with domain id and user address
    ///
    /// @param domain The domain id
    /// @param user The address of user
    /// @return DomainPermissions User's domain permissions
    function getDomainPermissions(uint32 domain, address user) external view returns (uint32) {
        return domainPermissions[encodeKYCUserDomainKey(domain, user)];
    }

    /// @dev Set domain permissions with domain id and user address
    function _setDomainPermissions(
        uint32 domain,
        address user,
        uint32 permissions
    ) internal {
        domainPermissions[encodeKYCUserDomainKey(domain, user)] = permissions;
    }

    /// @notice Get user's kyc status under domain
    ///
    /// @param domain The domain id
    /// @param user The address of user
    /// @return KYCStatusUser User's KYC status
    function getKYCStatusUser(uint32 domain, address user) public view returns (uint32) {
        return userKycStatuses[encodeKYCUserDomainKey(domain, user)];
    }

    /// @dev Verify that the operation and signature are valid
    function _verifyProof(
        uint32 domain,
        address user,
        uint32 status,
        uint256 nonce,
        bytes calldata signature
    ) internal {
        require(domain != 0 && domain <= domainCount, "invalid domain");
        require(publicKeys[domain] != address(0), "this domain is disabled");
        bytes32 proofHash = getKYCSignatureHash(domain, user, status, nonce);
        require(proofHash.toEthSignedMessageHash().recover(signature) == publicKeys[domain], "invalid signature");
        require(proofUsed[proofHash] == 0, "proof already used");
        proofUsed[proofHash] = 1;
    }

    /// @dev Set KYC status for user
    function _setKYCStatusUser(
        uint32 domain,
        address user,
        uint32 status
    ) internal {
        userKycStatuses[encodeKYCUserDomainKey(domain, user)] = status;
    }

    /// @dev Bitwise OR the user's KYC status
    function _orKYCStatusUser(
        uint32 domain,
        address user,
        uint32 status
    ) internal {
        userKycStatuses[encodeKYCUserDomainKey(domain, user)] |= status;
    }

    /// @notice Create a new KYC store domain
    ///
    /// @param admin The address of domain admin
    /// @param publicKey The KYC domain publicKey
    /// @param kycMode The KYC mode
    /// @return DomainId The new KYC domain id
    function createNewKYCDomain(
        address admin,
        address publicKey,
        uint256 kycMode
    ) external returns (uint32) {
        require(admin != address(0), "cannot create a kyc domain with an empty user");
        uint32 id = domainCount + 1;
        domainCount = id;
        _setDomainPermissions(id, admin, DOMAIN_ADMIN_PERM);
        publicKeys[id] = publicKey;
        domainKycMode[id] = kycMode;
        return id;
    }

    /// @notice Set KYC domain public key for domain
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Domain admin
    ///
    /// @param domain The KYC domain id
    /// @param newPublicKey New KYC domain publickey
    function setKYCDomainPublicKey(uint32 domain, address newPublicKey) external onlyDomainAdmin(domain) {
        publicKeys[domain] = newPublicKey;
    }

    /// @notice Set KYC mode for domain
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Domain admin
    ///
    /// @param domain The KYC domain id
    /// @param mode The KYC mode
    function setKYCDomainMode(uint32 domain, uint256 mode) external onlyDomainAdmin(domain) {
        domainKycMode[domain] = mode;
    }

    /// @notice Check the KYC mode of the user under the specified domain
    ///
    /// @param domain The KYC domain id
    /// @param user The address of user
    /// @param mode The KYC mode
    /// @return result Return `1` if valid
    function checkUserBasicBitwiseMode(
        uint32 domain,
        address user,
        uint256 mode
    ) external view returns (uint256) {
        require(domain != 0 && domain <= domainCount, "invalid domain");
        require(
            user != address(0) && ((domainKycMode[domain] & mode) == 0 || (mode & getKYCStatusUser(domain, user) != 0)),
            "invalid user permissions"
        );
        return 1;
    }

    /// @notice Allow domain admin to set KYC status for user
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Domain admin
    ///
    /// @param domain The KYC domain id
    /// @param user The address of user
    /// @param status The status number
    function setKYCStatusUser(
        uint32 domain,
        address user,
        uint32 status
    ) external onlyDomainAdmin(domain) {
        _setKYCStatusUser(domain, user, status);
    }

    /// @notice Returns KYC signature (encoded data)
    ///
    /// @param domain The KYC domain id
    /// @param user The address of user
    /// @param status The status number
    /// @param nonce The nonce
    /// @return KYCSignaturePayload The KYC signature (encoded data)
    function getKYCSignaturePayload(
        uint32 domain,
        address user,
        uint32 status,
        uint256 nonce
    ) public pure returns (bytes memory) {
        return (
            abi.encode(
                ((uint256(PROOF_MAGIC) << 224) |
                    (uint256(uint160(user)) << 64) |
                    (uint256(domain) << 32) |
                    uint256(status)),
                nonce
            )
        );
    }

    /// @notice Returns KYC signature (keccak256 hash)
    ///
    /// @param domain The KYC domain id
    /// @param user The address of user
    /// @param status The status number
    /// @param nonce The nonce
    /// @return KYCSignatureHash The KYC signature (keccak256 hash)
    function getKYCSignatureHash(
        uint32 domain,
        address user,
        uint32 status,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(getKYCSignaturePayload(domain, user, status, nonce));
    }

    /// @notice Bitwise OR the user's KYC status
    ///
    /// - SIGNATURE REQUIRED:
    ///     Domain admin
    ///
    /// @param domain The KYC domain id
    /// @param user The address of user
    /// @param status The status number to bitwise OR
    /// @param nonce The nonce
    /// @param signature The domain admin signature (proof)
    function orKYCStatusWithProof(
        uint32 domain,
        address user,
        uint32 status,
        uint256 nonce,
        bytes calldata signature
    ) external {
        _verifyProof(domain, user, status, nonce, signature);
        _orKYCStatusUser(domain, user, status);
    }

    /// @notice Clear KYC status for user
    ///
    /// - SIGNATURE REQUIRED:
    ///     Domain admin
    ///
    /// @param domain The KYC domain id
    /// @param user The address of user
    /// @param nonce The nonce
    /// @param signature The domain admin signature (proof)
    function clearKYCStatusWithProof(
        uint32 domain,
        address user,
        uint256 nonce,
        bytes calldata signature
    ) external {
        _verifyProof(domain, user, 1, nonce, signature);
        _setKYCStatusUser(domain, user, 1);
    }

    /// @dev This contract is called through the proxy.
    function initialize() external initializer nonReentrant {
        __ReentrancyGuard_init_unchained();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PRBMathUD60x18} from "../../Utils/Math/PRBMathUD60x18.sol";

/// @dev BNPL bank node mathematical calculation tools
/// @author BNPL
library BankNodeUtils {
    using PRBMathUD60x18 for uint256;

    /// @notice The wETH contract address (ERC20 tradable version of ETH)
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice Calculate slash amount
    ///
    /// @param prevNodeBalance Previous bank node balance
    /// @param nodeLoss The loss amount of bank node
    /// @param poolBalance The staking pool balance of bank node
    /// @return slashAmount
    function calculateSlashAmount(
        uint256 prevNodeBalance,
        uint256 nodeLoss,
        uint256 poolBalance
    ) internal pure returns (uint256) {
        uint256 slashRatio = (nodeLoss * PRBMathUD60x18.scale()).div(prevNodeBalance * PRBMathUD60x18.scale());
        return (poolBalance * slashRatio) / PRBMathUD60x18.scale();
    }

    /// @notice Calculate monthly interest payment
    ///
    /// @param loanAmount Amount of loan
    /// @param interestAmount Interest rate per payment
    /// @param numberOfPayments The number of payments
    /// @param currentMonth Number of payments made
    /// @return monthlyInterestPayment
    function getMonthlyInterestPayment(
        uint256 loanAmount,
        uint256 interestAmount,
        uint256 numberOfPayments,
        uint256 currentMonth
    ) internal pure returns (uint256) {
        return
            (loanAmount *
                getPrincipleForMonth(interestAmount, numberOfPayments, currentMonth - 1).mul(interestAmount)) /
            PRBMathUD60x18.scale();
    }

    /// @notice Calculate principle for month
    ///
    /// @param interestAmount Interest rate per payment
    /// @param numberOfPayments The number of payments
    /// @param currentMonth Number of payments made
    /// @return principleForMonth
    function getPrincipleForMonth(
        uint256 interestAmount,
        uint256 numberOfPayments,
        uint256 currentMonth
    ) internal pure returns (uint256) {
        uint256 ip1m = (PRBMathUD60x18.scale() + interestAmount).pow(currentMonth);
        uint256 right = getPaymentMultiplier(interestAmount, numberOfPayments).mul(
            (ip1m - PRBMathUD60x18.scale()).div(interestAmount)
        );
        return ip1m - right;
    }

    /// @notice Calculate monthly payment
    ///
    /// @param loanAmount Amount of loan
    /// @param interestAmount Interest rate per payment
    /// @param numberOfPayments The number of payments
    /// @return monthlyPayment
    function getMonthlyPayment(
        uint256 loanAmount,
        uint256 interestAmount,
        uint256 numberOfPayments
    ) internal pure returns (uint256) {
        return (loanAmount * getPaymentMultiplier(interestAmount, numberOfPayments)) / PRBMathUD60x18.scale();
    }

    /// @notice Calculate payment multiplier
    ///
    /// @param interestAmount Interest rate per payment
    /// @param numberOfPayments The number of payments
    /// @return paymentMultiplier
    function getPaymentMultiplier(uint256 interestAmount, uint256 numberOfPayments) internal pure returns (uint256) {
        uint256 ip1n = (PRBMathUD60x18.scale() + interestAmount).pow(numberOfPayments);
        uint256 result = interestAmount.mul(ip1n).div((ip1n - PRBMathUD60x18.scale()));
        return result;
    }

    /// @dev Sushiswap exact tokens path (join wETH in the middle)
    ///
    /// @param tokenIn input token address
    /// @param tokenOut output token address
    /// @return swapExactTokensPath
    function getSwapExactTokensPath(address tokenIn, address tokenOut) internal pure returns (address[] memory) {
        address[] memory path = new address[](3);
        path[0] = address(tokenIn);
        path[1] = WETH;
        path[2] = address(tokenOut);
        return path;
    }

    /// @dev Returns the smallest of two numbers.
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("approve(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("transfer(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.0;

import "./PRBMathCommon.sol";

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math. It works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 = 115792089237316195423570985008687907853269984665640564039457000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an usigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        require(x <= MAX_WHOLE_UD60x18);
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - y cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMathCommon.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
        result = 2718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 88722839111672999628.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 128e18.
        require(x < 88722839111672999628);

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 128e18 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2**128 doesn't fit within the 128.128-bit format used internally in this function.
        require(x < 128e18);

        unchecked {
            // Convert x to the 128.128-bit fixed-point format.
            uint256 x128x128 = (x << 128) / SCALE;

            // Pass x to the PRBMathCommon.exp2 function, which uses the 128.128-bit fixed-point number representation.
            result = PRBMathCommon.exp2(x128x128);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            require(xy / x == y);

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMathCommon.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding towards zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked { result = (log2(x) * SCALE) / LOG2_E; }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        require(x >= SCALE);

        // Note that the "mul" in this block is the assembly mul operation, not the "mul" function defined in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked { result = (log2(x) * SCALE) / 332192809488736234; }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last digit, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        require(x >= SCALE);
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMathCommon.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMathCommon.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMathCommon.mulDivFixedPoint(x, y);
    }

    /// @notice Retrieves PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3141592653589793238;
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = mul(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = mul(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// Caveats:
    /// - The maximum fixed-point number permitted is 115792089237316195423570985008687907853269.984665640564039458.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        require(x < 115792089237316195423570985008687907853269984665640564039458);
        unchecked {
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMathCommon.sqrt(x * SCALE);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenericMintableTo {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenericBurnableFrom {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBankNodeManager} from "../../Management/interfaces/IBankNodeManager.sol";
import {BNPLKYCStore} from "../../Management/BNPLKYCStore.sol";

/// @title BNPL Protocol configuration contract
///
/// @notice
/// - Include:
///     **Network Info**
///     **BNPL token contracts**
///     **BNPL UpBeacon contracts**
///     **BNPL BankNodeManager contract**
///
/// @author BNPL
interface IBNPLProtocolConfig {
    /// @notice Returns blockchain network id
    /// @return networkId blockchain network id
    function networkId() external view returns (uint64);

    /// @notice Returns blockchain network name
    /// @return networkName blockchain network name
    function networkName() external view returns (string memory);

    /// @notice Returns BNPL token address
    /// @return bnplToken BNPL token contract
    function bnplToken() external view returns (IERC20);

    /// @notice Returns bank node manager upBeacon contract
    /// @return upBeaconBankNodeManager bank node manager upBeacon contract
    function upBeaconBankNodeManager() external view returns (UpgradeableBeacon);

    /// @notice Returns bank node upBeacon contract
    /// @return upBeaconBankNode bank node upBeacon contract
    function upBeaconBankNode() external view returns (UpgradeableBeacon);

    /// @notice Returns bank node lending pool token upBeacon contract
    /// @return upBeaconBankNodeLendingPoolToken bank node lending pool token upBeacon contract
    function upBeaconBankNodeLendingPoolToken() external view returns (UpgradeableBeacon);

    /// @notice Returns bank node staking pool upBeacon contract
    /// @return upBeaconBankNodeStakingPool bank node staking pool upBeacon contract
    function upBeaconBankNodeStakingPool() external view returns (UpgradeableBeacon);

    /// @notice Returns bank node staking pool token upBeacon contract
    /// @return upBeaconBankNodeStakingPoolToken bank node staking pool token upBeacon contract
    function upBeaconBankNodeStakingPoolToken() external view returns (UpgradeableBeacon);

    /// @notice Returns bank node lending rewards upBeacon contract
    /// @return upBeaconBankNodeLendingRewards bank node lending rewards upBeacon contract
    function upBeaconBankNodeLendingRewards() external view returns (UpgradeableBeacon);

    /// @notice Returns BNPL KYC store upBeacon contract
    /// @return upBeaconBNPLKYCStore BNPL KYC store upBeacon contract
    function upBeaconBNPLKYCStore() external view returns (UpgradeableBeacon);

    /// @notice Returns BankNodeManager contract
    /// @return bankNodeManager BankNodeManager contract
    function bankNodeManager() external view returns (IBankNodeManager);
}

// SPDX-License-Identifier: MIT

/* Borrowed heavily from Synthetix

* MIT License
* ===========
*
* Copyright (c) 2021 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBankNodeManager} from "../../Management/interfaces/IBankNodeManager.sol";

import {BankNodeRewardSystem} from "./BankNodeRewardSystem.sol";

/// @title BNPL bank node lending rewards contract
///
/// @notice
/// - Features:
///     - Users:
///       **Stake**
///       **Withdraw**
///       **GetReward**
///     - Manager:
///       **SetRewardsDuration**
///     - Distributor:
///       **distribute BNPL tokens to BankNodes**
///
/// @author BNPL
contract BankNodeLendingRewards is Initializable, BankNodeRewardSystem {
    using SafeERC20 for IERC20;

    /// @dev This contract is called through the proxy.
    ///
    /// @param _defaultRewardsDuration The default reward duration (secs)
    /// @param _rewardsToken The address of the BNPL token
    /// @param _bankNodeManager The address of the BankNodeManagerProxy
    /// @param distributorAdmin The address of the distributor admin
    /// @param managerAdmin The address of the manager admin
    function initialize(
        uint256 _defaultRewardsDuration,
        address _rewardsToken,
        address _bankNodeManager,
        address distributorAdmin,
        address managerAdmin
    ) external initializer {
        __ReentrancyGuard_init_unchained();
        __Context_init_unchained();
        __Pausable_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        rewardsToken = IERC20(_rewardsToken);
        bankNodeManager = IBankNodeManager(_bankNodeManager);
        defaultRewardsDuration = _defaultRewardsDuration;

        _setupRole(REWARDS_DISTRIBUTOR_ROLE, _bankNodeManager);
        _setupRole(REWARDS_DISTRIBUTOR_ROLE, distributorAdmin);
        _setupRole(REWARDS_DISTRIBUTOR_ADMIN_ROLE, distributorAdmin);
        _setRoleAdmin(REWARDS_DISTRIBUTOR_ROLE, REWARDS_DISTRIBUTOR_ADMIN_ROLE);

        _setupRole(REWARDS_MANAGER, _bankNodeManager);
        _setupRole(REWARDS_MANAGER, managerAdmin);
        _setupRole(REWARDS_MANAGER_ROLE_ADMIN, managerAdmin);
        _setRoleAdmin(REWARDS_MANAGER, REWARDS_MANAGER_ROLE_ADMIN);
    }

    /// @dev Get the amount of tokens staked by the node
    function _bnplTokensStakedToBankNode(uint32 bankNodeId) internal view returns (uint256) {
        return
            rewardsToken.balanceOf(
                _ensureContractAddressNot0(bankNodeManager.getBankNodeStakingPoolContract(bankNodeId))
            );
    }

    /// @notice Get the amount of rewards that can be allocated by all bank nodes
    ///
    /// @param amount The distribute BNPL tokens amount
    /// @return bnplTokensPerNode BNPL tokens amount per node
    function getBNPLTokenDistribution(uint256 amount) external view returns (uint256[] memory) {
        uint32 nodeCount = bankNodeManager.bankNodeCount();
        uint256[] memory bnplTokensPerNode = new uint256[](nodeCount);
        uint32 i = 0;
        uint256 amt = 0;
        uint256 total = 0;
        while (i < nodeCount) {
            amt = rewardsToken.balanceOf(
                _ensureContractAddressNot0(bankNodeManager.getBankNodeStakingPoolContract(i + 1))
            );
            bnplTokensPerNode[i] = amt;
            total += amt;
            i += 1;
        }
        i = 0;
        while (i < nodeCount) {
            bnplTokensPerNode[i] = (bnplTokensPerNode[i] * amount) / total;
            i += 1;
        }
        return bnplTokensPerNode;
    }

    /// @notice Distribute rewards to all bank nodes (Method 1)
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "REWARDS_DISTRIBUTOR_ROLE"
    ///
    /// @param amount The distribute BNPL tokens amount
    /// @return total Total Rewards
    function distributeBNPLTokensToBankNodes(uint256 amount)
        external
        onlyRole(REWARDS_DISTRIBUTOR_ROLE)
        returns (uint256)
    {
        require(amount > 0, "cannot send 0");
        rewardsToken.safeTransferFrom(msg.sender, address(this), amount);
        uint32 nodeCount = bankNodeManager.bankNodeCount();
        uint256[] memory bnplTokensPerNode = new uint256[](nodeCount);
        uint32 i = 0;
        uint256 amt = 0;
        uint256 total = 0;
        while (i < nodeCount) {
            if (getPoolLiquidityTokensStakedInRewards(i + 1) != 0) {
                amt = rewardsToken.balanceOf(
                    _ensureContractAddressNot0(bankNodeManager.getBankNodeStakingPoolContract(i + 1))
                );
                bnplTokensPerNode[i] = amt;
                total += amt;
            }
            i += 1;
        }
        i = 0;
        while (i < nodeCount) {
            amt = (bnplTokensPerNode[i] * amount) / total;
            if (amt != 0) {
                _notifyRewardAmount(i + 1, amt);
            }
            i += 1;
        }
        return total;
    }

    /// @notice Distribute rewards to all bank nodes (Method 2)
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "REWARDS_DISTRIBUTOR_ROLE"
    ///
    /// @param amount The distribute BNPL tokens amount
    /// @return total Total Rewards
    function distributeBNPLTokensToBankNodes2(uint256 amount)
        external
        onlyRole(REWARDS_DISTRIBUTOR_ROLE)
        returns (uint256)
    {
        uint32 nodeCount = bankNodeManager.bankNodeCount();
        uint32 i = 0;
        uint256 amt = 0;
        uint256 total = 0;
        while (i < nodeCount) {
            total += rewardsToken.balanceOf(
                _ensureContractAddressNot0(bankNodeManager.getBankNodeStakingPoolContract(i + 1))
            );
            i += 1;
        }
        i = 0;
        while (i < nodeCount) {
            amt =
                (rewardsToken.balanceOf(
                    _ensureContractAddressNot0(bankNodeManager.getBankNodeStakingPoolContract(i + 1))
                ) * amount) /
                total;
            if (amt != 0) {
                _notifyRewardAmount(i + 1, amt);
            }
            i += 1;
        }
        return total;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../../access/Ownable.sol";
import "../../utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

/* Borrowed heavily from Synthetix

* MIT License
* ===========
*
* Copyright (c) 2021 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBankNodeManager} from "../../Management/interfaces/IBankNodeManager.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title BNPL bank node lending reward system contract
///
/// @dev This contract is inherited by the `BankNodeLendingRewards` contract
/// @notice
/// - Users:
///   **Stake**
///   **Withdraw**
///   **GetReward**
/// - Manager:
///   **SetRewardsDuration**
/// - Distributor:
///   **distribute BNPL tokens to BankNodes**
///
/// @author BNPL
contract BankNodeRewardSystem is
    Initializable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 public constant REWARDS_DISTRIBUTOR_ROLE = keccak256("REWARDS_DISTRIBUTOR_ROLE");
    bytes32 public constant REWARDS_DISTRIBUTOR_ADMIN_ROLE = keccak256("REWARDS_DISTRIBUTOR_ADMIN_ROLE");

    bytes32 public constant REWARDS_MANAGER = keccak256("REWARDS_MANAGER_ROLE");
    bytes32 public constant REWARDS_MANAGER_ROLE_ADMIN = keccak256("REWARDS_MANAGER_ROLE_ADMIN");

    /// @notice [Bank node id] => [Previous rewards period]
    mapping(uint32 => uint256) public periodFinish;

    /// @notice [Bank node id] => [Reward rate]
    mapping(uint32 => uint256) public rewardRate;

    /// @notice [Bank node id] => [Rewards duration]
    mapping(uint32 => uint256) public rewardsDuration;

    /// @notice [Bank node id] => [Rewards last update time]
    mapping(uint32 => uint256) public lastUpdateTime;

    /// @notice [Bank node id] => [Reward per token stored]
    mapping(uint32 => uint256) public rewardPerTokenStored;

    /// @notice [Encoded user bank node key (user, bankNodeId)] => [Reward per token paid]
    mapping(uint256 => uint256) public userRewardPerTokenPaid;

    /// @notice [Encoded user bank node key (user, bankNodeId)] => [Rewards amount]
    mapping(uint256 => uint256) public rewards;

    /// @notice [Bank node id] => [Stake amount]
    mapping(uint32 => uint256) public _totalSupply;

    /// @notice [Encoded user bank node key (user, bankNodeId)] => [Staked balance]
    mapping(uint256 => uint256) private _balances;

    /// @notice BNPL bank node manager contract
    IBankNodeManager public bankNodeManager;

    /// @notice Rewards token contract
    IERC20 public rewardsToken;

    /// @notice Default rewards duration (secs)
    uint256 public defaultRewardsDuration;

    /// @dev Encode user address and bank node id into a uint256.
    ///
    /// @param user The address of user
    /// @param bankNodeId The id of the bank node
    /// @return encodedUserBankNodeKey The encoded user bank node key.
    function encodeUserBankNodeKey(address user, uint32 bankNodeId) public pure returns (uint256) {
        return (uint256(uint160(user)) << 32) | uint256(bankNodeId);
    }

    /// @dev Decode user bank node key to user address and bank node id.
    ///
    /// @param stakingVaultKey The user bank node key
    /// @return user The address of user
    /// @return bankNodeId The id of the bank node
    function decodeUserBankNodeKey(uint256 stakingVaultKey) external pure returns (address user, uint32 bankNodeId) {
        bankNodeId = uint32(stakingVaultKey & 0xffffffff);
        user = address(uint160(stakingVaultKey >> 32));
    }

    /// @dev Encode amount and depositTime into a uint256.
    ///
    /// @param amount An uint256 amount
    /// @param depositTime An uint40 deposit time
    /// @return encodedVaultValue The encoded vault value
    function encodeVaultValue(uint256 amount, uint40 depositTime) external pure returns (uint256) {
        require(
            amount <= 0xffffffffffffffffffffffffffffffffffffffffffffffffffffff,
            "cannot encode amount larger than 2^216-1"
        );
        return (amount << 40) | uint256(depositTime);
    }

    /// @notice Decode vault value to amount and depositTime
    ///
    /// @param vaultValue The encoded vault value
    /// @return amount An `uint256` amount
    /// @return depositTime An `uint40` deposit time
    function decodeVaultValue(uint256 vaultValue) external pure returns (uint256 amount, uint40 depositTime) {
        depositTime = uint40(vaultValue & 0xffffffffff);
        amount = vaultValue >> 40;
    }

    /// @dev Ensure the given address not zero and return it as IERC20
    /// @return ERC20Token
    function _ensureAddressIERC20Not0(address tokenAddress) internal pure returns (IERC20) {
        require(tokenAddress != address(0), "invalid token address!");
        return IERC20(tokenAddress);
    }

    /// @dev Ensure the given address not zero
    /// @return Address
    function _ensureContractAddressNot0(address contractAddress) internal pure returns (address) {
        require(contractAddress != address(0), "invalid token address!");
        return contractAddress;
    }

    /// @dev Get the lending pool token contract (ERC20) address of the specified bank node
    ///
    /// @param bankNodeId The id of the bank node
    /// @return BankNodeTokenContract The lending pool token contract (ERC20)
    function getStakingTokenForBankNode(uint32 bankNodeId) internal view returns (IERC20) {
        return _ensureAddressIERC20Not0(bankNodeManager.getBankNodeToken(bankNodeId));
    }

    /// @notice Get the lending pool token amount in rewards of the specified bank node
    ///
    /// @param bankNodeId The id of the bank node
    /// @return BankNodeTokenBalanceInRewards The lending pool token balance in rewards
    function getPoolLiquidityTokensStakedInRewards(uint32 bankNodeId) public view returns (uint256) {
        return getStakingTokenForBankNode(bankNodeId).balanceOf(address(this));
    }

    /// @dev Returns the input `amount`
    function getInternalValueForStakedTokenAmount(uint256 amount) internal pure returns (uint256) {
        return amount;
    }

    /// @dev Returns the input `amount`
    function getStakedTokenAmountForInternalValue(uint256 amount) internal pure returns (uint256) {
        return amount;
    }

    /// @notice Get the stake amount of the specified bank node
    ///
    /// @param bankNodeId The id of the bank node
    /// @return TotalSupply The stake amount
    function totalSupply(uint32 bankNodeId) external view returns (uint256) {
        return getStakedTokenAmountForInternalValue(_totalSupply[bankNodeId]);
    }

    /// @notice Get the user's staked balance under the specified bank node
    ///
    /// @param account User address
    /// @param bankNodeId The id of the bank node
    /// @return StakedBalance User's staked balance
    function balanceOf(address account, uint32 bankNodeId) external view returns (uint256) {
        return getStakedTokenAmountForInternalValue(_balances[encodeUserBankNodeKey(account, bankNodeId)]);
    }

    /// @notice Get the last time reward applicable of the specified bank node
    ///
    /// @param bankNodeId The id of the bank node
    /// @return lastTimeRewardApplicable The last time reward applicable
    function lastTimeRewardApplicable(uint32 bankNodeId) public view returns (uint256) {
        return block.timestamp < periodFinish[bankNodeId] ? block.timestamp : periodFinish[bankNodeId];
    }

    /// @notice Get reward amount with bank node id
    ///
    /// @param bankNodeId The id of the bank node
    /// @return rewardPerToken Reward per token amount
    function rewardPerToken(uint32 bankNodeId) public view returns (uint256) {
        if (_totalSupply[bankNodeId] == 0) {
            return rewardPerTokenStored[bankNodeId];
        }
        return
            rewardPerTokenStored[bankNodeId].add(
                lastTimeRewardApplicable(bankNodeId)
                    .sub(lastUpdateTime[bankNodeId])
                    .mul(rewardRate[bankNodeId])
                    .mul(1e18)
                    .div(_totalSupply[bankNodeId])
            );
    }

    /// @notice Get the benefits earned by users in the bank node
    ///
    /// @param account The user address
    /// @param bankNodeId The id of the bank node
    /// @return Earnd Benefits earned by users in the bank node
    function earned(address account, uint32 bankNodeId) public view returns (uint256) {
        uint256 key = encodeUserBankNodeKey(account, bankNodeId);
        return
            ((_balances[key] * (rewardPerToken(bankNodeId) - (userRewardPerTokenPaid[key]))) / 1e18) + (rewards[key]);
    }

    /// @notice Get bank node reward for duration
    ///
    /// @param bankNodeId The id of the bank node
    /// @return RewardForDuration Bank node reward for duration
    function getRewardForDuration(uint32 bankNodeId) external view returns (uint256) {
        return rewardRate[bankNodeId] * rewardsDuration[bankNodeId];
    }

    /// @notice Stake `tokenAmount` tokens to specified bank node
    ///
    /// @param bankNodeId The id of the bank node to stake
    /// @param tokenAmount The amount to be staked
    function stake(uint32 bankNodeId, uint256 tokenAmount)
        external
        nonReentrant
        whenNotPaused
        updateReward(msg.sender, bankNodeId)
    {
        require(tokenAmount > 0, "Cannot stake 0");
        uint256 amount = getInternalValueForStakedTokenAmount(tokenAmount);
        require(amount > 0, "Cannot stake 0");
        require(getStakedTokenAmountForInternalValue(amount) == tokenAmount, "token amount too high!");
        _totalSupply[bankNodeId] += amount;
        _balances[encodeUserBankNodeKey(msg.sender, bankNodeId)] += amount;
        getStakingTokenForBankNode(bankNodeId).safeTransferFrom(msg.sender, address(this), tokenAmount);
        emit Staked(msg.sender, bankNodeId, tokenAmount);
    }

    /// @notice Withdraw `tokenAmount` tokens from specified bank node
    ///
    /// @param bankNodeId The id of the bank node to withdraw
    /// @param tokenAmount The amount to be withdrawn
    function withdraw(uint32 bankNodeId, uint256 tokenAmount) public nonReentrant updateReward(msg.sender, bankNodeId) {
        require(tokenAmount > 0, "Cannot withdraw 0");
        uint256 amount = getInternalValueForStakedTokenAmount(tokenAmount);
        require(amount > 0, "Cannot withdraw 0");
        require(getStakedTokenAmountForInternalValue(amount) == tokenAmount, "token amount too high!");

        _totalSupply[bankNodeId] -= amount;
        _balances[encodeUserBankNodeKey(msg.sender, bankNodeId)] -= amount;
        getStakingTokenForBankNode(bankNodeId).safeTransfer(msg.sender, tokenAmount);
        emit Withdrawn(msg.sender, bankNodeId, tokenAmount);
    }

    /// @notice Get reward from specified bank node.
    /// @param bankNodeId The id of the bank node
    function getReward(uint32 bankNodeId) public nonReentrant updateReward(msg.sender, bankNodeId) {
        uint256 reward = rewards[encodeUserBankNodeKey(msg.sender, bankNodeId)];

        if (reward > 0) {
            rewards[encodeUserBankNodeKey(msg.sender, bankNodeId)] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, bankNodeId, reward);
        }
    }

    /// @notice Withdraw tokens and get reward from specified bank node.
    /// @param bankNodeId The id of the bank node
    function exit(uint32 bankNodeId) external {
        withdraw(
            bankNodeId,
            getStakedTokenAmountForInternalValue(_balances[encodeUserBankNodeKey(msg.sender, bankNodeId)])
        );
        getReward(bankNodeId);
    }

    /// @dev Update the reward and emit the `RewardAdded` event
    function _notifyRewardAmount(uint32 bankNodeId, uint256 reward) internal updateReward(address(0), bankNodeId) {
        if (rewardsDuration[bankNodeId] == 0) {
            rewardsDuration[bankNodeId] = defaultRewardsDuration;
        }
        if (block.timestamp >= periodFinish[bankNodeId]) {
            rewardRate[bankNodeId] = reward / (rewardsDuration[bankNodeId]);
        } else {
            uint256 remaining = periodFinish[bankNodeId] - (block.timestamp);
            uint256 leftover = remaining * (rewardRate[bankNodeId]);
            rewardRate[bankNodeId] = (reward + leftover) / (rewardsDuration[bankNodeId]);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(rewardRate[bankNodeId] <= (balance / rewardsDuration[bankNodeId]), "Provided reward too high");

        lastUpdateTime[bankNodeId] = block.timestamp;
        periodFinish[bankNodeId] = block.timestamp + (rewardsDuration[bankNodeId]);
        emit RewardAdded(bankNodeId, reward);
    }

    /// @notice Update the reward and emit the `RewardAdded` event
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "REWARDS_DISTRIBUTOR_ROLE"
    ///
    /// @param bankNodeId The id of the bank node
    /// @param reward The reward amount
    function notifyRewardAmount(uint32 bankNodeId, uint256 reward) external onlyRole(REWARDS_DISTRIBUTOR_ROLE) {
        _notifyRewardAmount(bankNodeId, reward);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    /* function recoverERC20(address tokenAddress, uint256 tokenAmount) external {
        require(tokenAddress != address(stakingToken[]), "Cannot withdraw the staking token");
        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }*/

    /// @notice Set reward duration for a bank node
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "REWARDS_MANAGER"
    ///
    /// @param bankNodeId The id of the bank node
    /// @param _rewardsDuration New reward duration (secs)
    function setRewardsDuration(uint32 bankNodeId, uint256 _rewardsDuration) external onlyRole(REWARDS_MANAGER) {
        require(
            block.timestamp > periodFinish[bankNodeId],
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration[bankNodeId] = _rewardsDuration;
        emit RewardsDurationUpdated(bankNodeId, rewardsDuration[bankNodeId]);
    }

    /// @dev Update user bank node reward
    modifier updateReward(address account, uint32 bankNodeId) {
        if (rewardsDuration[bankNodeId] == 0) {
            rewardsDuration[bankNodeId] = defaultRewardsDuration;
        }
        rewardPerTokenStored[bankNodeId] = rewardPerToken(bankNodeId);
        lastUpdateTime[bankNodeId] = lastTimeRewardApplicable(bankNodeId);
        if (account != address(0)) {
            uint256 key = encodeUserBankNodeKey(msg.sender, bankNodeId);
            rewards[key] = earned(msg.sender, bankNodeId);
            userRewardPerTokenPaid[key] = rewardPerTokenStored[bankNodeId];
        }
        _;
    }

    /// @dev Emitted when `_notifyRewardAmount` is called.
    ///
    /// @param bankNodeId The id of the bank node
    /// @param reward The reward amount
    event RewardAdded(uint32 indexed bankNodeId, uint256 reward);

    /// @dev Emitted when user `user` stake `tokenAmount` to specified `bankNodeId` bank node.
    ///
    /// @param user The user address
    /// @param bankNodeId The id of the bank node
    /// @param amount The staked amount
    event Staked(address indexed user, uint32 indexed bankNodeId, uint256 amount);

    /// @dev Emitted when user `user` withdraw `amount` of BNPL tokens from `bankNodeId` bank node.
    ///
    /// @param user The user address
    /// @param bankNodeId The id of the bank node
    /// @param amount The withdrawn amount
    event Withdrawn(address indexed user, uint32 indexed bankNodeId, uint256 amount);

    /// @dev Emitted when user `user` calls `getReward`.
    ///
    /// @param user The user address
    /// @param bankNodeId The id of the bank node
    /// @param reward The reward amount
    event RewardPaid(address indexed user, uint32 indexed bankNodeId, uint256 reward);

    /// @dev Emitted when `setRewardsDuration` is called.
    ///
    /// @param bankNodeId The id of the bank node
    /// @param newDuration The new reward duration
    event RewardsDurationUpdated(uint32 indexed bankNodeId, uint256 newDuration);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IStakedToken {
    function stake(address to, uint256 amount) external;

    function redeem(address to, uint256 amount) external;

    function cooldown() external;

    function claimRewards(address to, uint256 amount) external;

    function REWARD_TOKEN() external view returns (address);

    function stakersCooldowns(address staker) external view returns (uint256);

    function getTotalRewardsBalance(address staker) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAaveLendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import {IAaveDistributionManager} from "./IAaveDistributionManager.sol";

interface IAaveIncentivesController is IAaveDistributionManager {
    event RewardsAccrued(address indexed user, uint256 amount);

    event RewardsClaimed(address indexed user, address indexed to, address indexed claimer, uint256 amount);

    event ClaimerSet(address indexed user, address indexed claimer);

    /**
     * @dev Whitelists an address to claim the rewards on behalf of another address
     * @param user The address of the user
     * @param claimer The address of the claimer
     */
    function setClaimer(address user, address claimer) external;

    /**
     * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
     * @param user The address of the user
     * @return The claimer address
     */
    function getClaimer(address user) external view returns (address);

    /**
     * @dev Configure assets for a certain rewards emission
     * @param assets The assets to incentivize
     * @param emissionsPerSecond The emission for each asset
     */
    function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond) external;

    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param asset The address of the user
     * @param userBalance The balance of the user of the asset in the lending pool
     * @param totalSupply The total supply of the asset in the lending pool
     **/
    function handleAction(
        address asset,
        uint256 userBalance,
        uint256 totalSupply
    ) external;

    /**
     * @dev Returns the total of rewards of an user, already accrued + not yet accrued
     * @param user The address of the user
     * @return The rewards
     **/
    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

    /**
     * @dev Claims reward for an user to the desired address, on all the assets of the lending pool, accumulating the pending rewards
     * @param amount Amount of rewards to claim
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards. The caller must
     * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
     * @param amount Amount of rewards to claim
     * @param user Address to check and claim rewards
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewardsOnBehalf(
        address[] calldata assets,
        uint256 amount,
        address user,
        address to
    ) external returns (uint256);

    /**
     * @dev Claims reward for msg.sender, on all the assets of the lending pool, accumulating the pending rewards
     * @param amount Amount of rewards to claim
     * @return Rewards claimed
     **/
    function claimRewardsToSelf(address[] calldata assets, uint256 amount) external returns (uint256);

    /**
     * @dev returns the unclaimed rewards of the user
     * @param user the address of the user
     * @return the unclaimed user rewards
     */
    function getUserUnclaimedRewards(address user) external view returns (uint256);

    /**
     * @dev for backward compatibility with previous implementation of the Incentives controller
     */
    function REWARD_TOKEN() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the IBNPLSwapMarket standard
 */
interface IBNPLSwapMarket {
    /// @title Router token swapping functionality
    /// @notice Functions for swapping tokens via Uniswap V3
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @return amounts The amount of the received token
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import {DistributionTypes} from "../lib/DistributionTypes.sol";

interface IAaveDistributionManager {
    event AssetConfigUpdated(address indexed asset, uint256 emission);
    event AssetIndexUpdated(address indexed asset, uint256 index);
    event UserIndexUpdated(address indexed user, address indexed asset, uint256 index);
    event DistributionEndUpdated(uint256 newDistributionEnd);

    /**
     * @dev Sets the end date for the distribution
     * @param distributionEnd The end date timestamp
     **/
    function setDistributionEnd(uint256 distributionEnd) external;

    /**
     * @dev Gets the end date for the distribution
     * @return The end of the distribution
     **/
    function getDistributionEnd() external view returns (uint256);

    /**
     * @dev for backwards compatibility with the previous DistributionManager used
     * @return The end of the distribution
     **/
    function DISTRIBUTION_END() external view returns (uint256);

    /**
     * @dev Returns the data of an user on a distribution
     * @param user Address of the user
     * @param asset The address of the reference asset of the distribution
     * @return The new index
     **/
    function getUserAssetData(address user, address asset) external view returns (uint256);

    /**
     * @dev Returns the configuration of the distribution for a certain asset
     * @param asset The address of the reference asset of the distribution
     * @return The asset index, the emission per second and the last updated timestamp
     **/
    function getAssetData(address asset)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

library DistributionTypes {
    struct AssetConfigInput {
        uint104 emissionPerSecond;
        uint256 totalStaked;
        address underlyingAsset;
    }

    struct UserStakeInput {
        address underlyingAsset;
        uint256 stakedByUser;
        uint256 totalStaked;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Interface of the IUserTokenLockup standard
interface IUserTokenLockup {
    /// @notice Tokens locked amount
    /// @return totalTokensLocked
    function totalTokensLocked() external view returns (uint256);
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.0;

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
// representation. When it does not, it is annonated in the function's NatSpec documentation.
library PRBMathCommon {
    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE = 78156646155174841979727994598816262306175212592076161876661508869554232690281;

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Uses 128.128-bit fixed-point numbers - it is the most efficient way.
    /// @param x The exponent as an unsigned 128.128-bit fixed-point number.
    /// @return result The result as an unsigned 60x18 decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 128.128-bit fixed-point format. We need to use uint256 because the intermediary
            // may get very close to 2^256, which doesn't fit in int256.
            result = 0x80000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^127 and all magic factors are less than 2^129.
            if (x & 0x80000000000000000000000000000000 > 0) result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
            if (x & 0x40000000000000000000000000000000 > 0) result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDED) >> 128;
            if (x & 0x20000000000000000000000000000000 > 0) result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A7920) >> 128;
            if (x & 0x10000000000000000000000000000000 > 0) result = (result * 0x10B5586CF9890F6298B92B71842A98364) >> 128;
            if (x & 0x8000000000000000000000000000000 > 0) result = (result * 0x1059B0D31585743AE7C548EB68CA417FE) >> 128;
            if (x & 0x4000000000000000000000000000000 > 0) result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE9) >> 128;
            if (x & 0x2000000000000000000000000000000 > 0) result = (result * 0x10163DA9FB33356D84A66AE336DCDFA40) >> 128;
            if (x & 0x1000000000000000000000000000000 > 0) result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9544) >> 128;
            if (x & 0x800000000000000000000000000000 > 0) result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679C) >> 128;
            if (x & 0x400000000000000000000000000000 > 0) result = (result * 0x1002C605E2E8CEC506D21BFC89A23A011) >> 128;
            if (x & 0x200000000000000000000000000000 > 0) result = (result * 0x100162F3904051FA128BCA9C55C31E5E0) >> 128;
            if (x & 0x100000000000000000000000000000 > 0) result = (result * 0x1000B175EFFDC76BA38E31671CA939726) >> 128;
            if (x & 0x80000000000000000000000000000 > 0) result = (result * 0x100058BA01FB9F96D6CACD4B180917C3E) >> 128;
            if (x & 0x40000000000000000000000000000 > 0) result = (result * 0x10002C5CC37DA9491D0985C348C68E7B4) >> 128;
            if (x & 0x20000000000000000000000000000 > 0) result = (result * 0x1000162E525EE054754457D5995292027) >> 128;
            if (x & 0x10000000000000000000000000000 > 0) result = (result * 0x10000B17255775C040618BF4A4ADE83FD) >> 128;
            if (x & 0x8000000000000000000000000000 > 0) result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAC) >> 128;
            if (x & 0x4000000000000000000000000000 > 0) result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7CA) >> 128;
            if (x & 0x2000000000000000000000000000 > 0) result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
            if (x & 0x1000000000000000000000000000 > 0) result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
            if (x & 0x800000000000000000000000000 > 0) result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1629) >> 128;
            if (x & 0x400000000000000000000000000 > 0) result = (result * 0x1000002C5C863B73F016468F6BAC5CA2C) >> 128;
            if (x & 0x200000000000000000000000000 > 0) result = (result * 0x100000162E430E5A18F6119E3C02282A6) >> 128;
            if (x & 0x100000000000000000000000000 > 0) result = (result * 0x1000000B1721835514B86E6D96EFD1BFF) >> 128;
            if (x & 0x80000000000000000000000000 > 0) result = (result * 0x100000058B90C0B48C6BE5DF846C5B2F0) >> 128;
            if (x & 0x40000000000000000000000000 > 0) result = (result * 0x10000002C5C8601CC6B9E94213C72737B) >> 128;
            if (x & 0x20000000000000000000000000 > 0) result = (result * 0x1000000162E42FFF037DF38AA2B219F07) >> 128;
            if (x & 0x10000000000000000000000000 > 0) result = (result * 0x10000000B17217FBA9C739AA5819F44FA) >> 128;
            if (x & 0x8000000000000000000000000 > 0) result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC824) >> 128;
            if (x & 0x4000000000000000000000000 > 0) result = (result * 0x100000002C5C85FE31F35A6A30DA1BE51) >> 128;
            if (x & 0x2000000000000000000000000 > 0) result = (result * 0x10000000162E42FF0999CE3541B9FFFD0) >> 128;
            if (x & 0x1000000000000000000000000 > 0) result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
            if (x & 0x800000000000000000000000 > 0) result = (result * 0x10000000058B90BFBF8479BD5A81B51AE) >> 128;
            if (x & 0x400000000000000000000000 > 0) result = (result * 0x1000000002C5C85FDF84BD62AE30A74CD) >> 128;
            if (x & 0x200000000000000000000000 > 0) result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
            if (x & 0x100000000000000000000000 > 0) result = (result * 0x1000000000B17217F7D5A7716BBA4A9AF) >> 128;
            if (x & 0x80000000000000000000000 > 0) result = (result * 0x100000000058B90BFBE9DDBAC5E109CCF) >> 128;
            if (x & 0x40000000000000000000000 > 0) result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0E) >> 128;
            if (x & 0x20000000000000000000000 > 0) result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
            if (x & 0x10000000000000000000000 > 0) result = (result * 0x10000000000B17217F7D20CF927C8E94D) >> 128;
            if (x & 0x8000000000000000000000 > 0) result = (result * 0x1000000000058B90BFBE8F71CB4E4B33E) >> 128;
            if (x & 0x4000000000000000000000 > 0) result = (result * 0x100000000002C5C85FDF477B662B26946) >> 128;
            if (x & 0x2000000000000000000000 > 0) result = (result * 0x10000000000162E42FEFA3AE53369388D) >> 128;
            if (x & 0x1000000000000000000000 > 0) result = (result * 0x100000000000B17217F7D1D351A389D41) >> 128;
            if (x & 0x800000000000000000000 > 0) result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDF) >> 128;
            if (x & 0x400000000000000000000 > 0) result = (result * 0x1000000000002C5C85FDF4741BEA6E77F) >> 128;
            if (x & 0x200000000000000000000 > 0) result = (result * 0x100000000000162E42FEFA39FE95583C3) >> 128;
            if (x & 0x100000000000000000000 > 0) result = (result * 0x1000000000000B17217F7D1CFB72B45E3) >> 128;
            if (x & 0x80000000000000000000 > 0) result = (result * 0x100000000000058B90BFBE8E7CC35C3F2) >> 128;
            if (x & 0x40000000000000000000 > 0) result = (result * 0x10000000000002C5C85FDF473E242EA39) >> 128;
            if (x & 0x20000000000000000000 > 0) result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
            if (x & 0x10000000000000000000 > 0) result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
            if (x & 0x8000000000000000000 > 0) result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
            if (x & 0x4000000000000000000 > 0) result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
            if (x & 0x2000000000000000000 > 0) result = (result * 0x10000000000000162E42FEFA39EF44D92) >> 128;
            if (x & 0x1000000000000000000 > 0) result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
            if (x & 0x800000000000000000 > 0) result = (result * 0x10000000000000058B90BFBE8E7BCE545) >> 128;
            if (x & 0x400000000000000000 > 0) result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
            if (x & 0x200000000000000000 > 0) result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
            if (x & 0x100000000000000000 > 0) result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
            if (x & 0x80000000000000000 > 0) result = (result * 0x100000000000000058B90BFBE8E7BCD6E) >> 128;
            if (x & 0x40000000000000000 > 0) result = (result * 0x10000000000000002C5C85FDF473DE6B3) >> 128;
            if (x & 0x20000000000000000 > 0) result = (result * 0x1000000000000000162E42FEFA39EF359) >> 128;
            if (x & 0x10000000000000000 > 0) result = (result * 0x10000000000000000B17217F7D1CF79AC) >> 128;

            // Multiply the result by the integer part 2^n + 1. We have to shift by one bit extra because we have already divided
            // by two when we set the result equal to 0.5 above.
            result = result << ((x >> 128) + 1);

            // Convert the result to the signed 60.18-decimal fixed-point format.
            result = PRBMathCommon.mulDiv(result, 1e18, 2**128);
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2**256 and mod 2**256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256. Also prevents denominator == 0.
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2**256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2**256. Now that denominator is an odd number, it has an inverse modulo 2**256 such
            // that denominator * inv = 1 mod 2**256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inverse = (3 * denominator) ^ 2;

            // Now use Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2**8
            inverse *= 2 - denominator * inverse; // inverse mod 2**16
            inverse *= 2 - denominator * inverse; // inverse mod 2**32
            inverse *= 2 - denominator * inverse; // inverse mod 2**64
            inverse *= 2 - denominator * inverse; // inverse mod 2**128
            inverse *= 2 - denominator * inverse; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2**256. Since the precoditions guarantee that the outcome is
            // less than 2**256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMathCommon.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two queations:
    ///     1) x * y = type(uint256).max * SCALE
    ///     2) (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        require(SCALE > prod1);

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Calculate the square root of the perfect square of a power of two that is the closest to x.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}