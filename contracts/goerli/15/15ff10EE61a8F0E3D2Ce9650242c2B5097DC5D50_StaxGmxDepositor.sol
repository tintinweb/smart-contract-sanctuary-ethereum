pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (investments/gmx/StaxGmxDepositor.sol)

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/external/gmx/IGmxRewardRouter.sol";
import "../../interfaces/external/gmx/IGmxRewardTracker.sol";
import "../../interfaces/external/gmx/IGmxRewardDistributor.sol";
import "../../interfaces/external/gmx/IGmxVester.sol";
import "../../interfaces/investments/gmx/IStaxGmxDepositor.sol";

import "../../common/FractionalAmount.sol";
import "../../common/CommonEventsAndErrors.sol";
import "../../common/Executable.sol";
import "../../common/access/Operators.sol";

// import "hardhat/console.sol";

/// @title STAX GMX Depositor
/// @notice The STAX contract responsible for managing GMX/GLP staking and harvesting/compounding rewards.
/// This depositor is kept relatively simple acting as a proxy to GMX.io staking/unstaking/rewards collection/etc,
/// as it would be difficult to upgrade (multiplier points may be burned which would be detrimental to the product).
/// @dev The Owner will be the STAX msig. The Operators will be the StaxGmxManager and StaxGmxLocker/StaxGlpLocker
contract StaxGmxDepositor is IStaxGmxDepositor, Ownable, Operators {
    using SafeERC20 for IERC20;

    // Note: The below contracts are GMX.io contracts which can be found
    // here: https://gmxio.gitbook.io/gmx/contracts

    /// @notice $GMX
    IERC20 public gmxToken;

    /// @notice $esGMX - escrowed GMX
    IERC20 public esGmxToken;

    /// @notice $wrappedNative - wrapped ETH/AVAX
    IERC20 public wrappedNativeToken; 

    /// @notice $bnGMX - otherwise known as multiplier points.
    address public bnGmxAddr;
 
    /// @notice The GMX contract used to claim and compound rewards.
    IGmxRewardRouter public gmxRewardRouter;

    /// @notice The GMX contract which manages the staking of GMX and esGMX, and outputs rewards as esGMX
    IGmxRewardTracker public stakedGmxTracker;

    /// @notice The GMX contract which manages the staking of GMX, esGMX, multiplier points and outputs rewards as wrappedNative (eg ETH/AVAX)
    IGmxRewardTracker public feeGmxTracker;

    /// @notice The GMX contract which manages the staking of GLP, and outputs rewards as esGMX
    IGmxRewardTracker public stakedGlpTracker;

    /// @notice The GMX contract which manages the staking of GLP, and outputs rewards as wrappedNative (eg ETH/AVAX)
    IGmxRewardTracker public feeGlpTracker;

    /// @notice The GMX contract which can transfer staked GLP from one user to another.
    IERC20 public stakedGlp;

    /// @notice The GMX contract which accepts deposits of esGMX to vest into GMX (linearly over 1 year).
    /// This is a separate instance when the esGMX is obtained via staked GLP, vs staked GMX
    IGmxVester public esGmxVester;
 
    /// @notice The GMX contract responsible for adding/removing liquidity in return for GLP ($ERC20 => $GLP)
    address public glpManager;

    event RewardsHarvested(
        uint256 wrappedNativeClaimedFromGmx,
        uint256 wrappedNativeClaimedFromGlp,
        uint256 esGmxClaimedFromGmx,
        uint256 esGmxClaimedFromGlp,
        uint256 esGmxVesting,
        uint256 vestedGmxClaimed
    );

    constructor(address _gmxRewardRouter, address _esGmxVester, address _stakedGlp) {
        initGmxContracts(_gmxRewardRouter, _esGmxVester, _stakedGlp);
    }

    /// @dev In case any of the upstream GMX contracts are upgraded this can be re-initialized.
    function initGmxContracts(address _gmxRewardRouter, address _esGmxVester, address _stakedGlp) public onlyOwner {
        // Copy the required addresses from the GMX Reward Router.
        gmxRewardRouter = IGmxRewardRouter(_gmxRewardRouter);
        gmxToken = IERC20(gmxRewardRouter.gmx());
        esGmxToken = IERC20(gmxRewardRouter.esGmx());
        wrappedNativeToken = IERC20(gmxRewardRouter.weth());
        bnGmxAddr = gmxRewardRouter.bnGmx();
        stakedGmxTracker = IGmxRewardTracker(gmxRewardRouter.stakedGmxTracker());
        feeGmxTracker = IGmxRewardTracker(gmxRewardRouter.feeGmxTracker());
        stakedGlpTracker = IGmxRewardTracker(gmxRewardRouter.stakedGlpTracker());
        feeGlpTracker = IGmxRewardTracker(gmxRewardRouter.feeGlpTracker());
        stakedGlp = IERC20(_stakedGlp);
        esGmxVester = IGmxVester(_esGmxVester);
        glpManager = gmxRewardRouter.glpManager();
    }

    function addOperator(address _address) external override onlyOwner {
        _addOperator(_address);
    }

    function removeOperator(address _address) external override onlyOwner {
        _removeOperator(_address);
    }

    /// @notice Stake $GMX which this contract already holds at GMX.io
    function stakeGmx(uint256 _amount) external override onlyOperators {
        // While the gmxRewardRouter is the contract which we call to stake, $GMX allowance
        // needs to be provided to the stakedGmxTracker as it pulls/stakes the $GMX.
        gmxToken.safeIncreaseAllowance(address(stakedGmxTracker), _amount);
        gmxRewardRouter.stakeGmx(_amount);
    }

    /// @notice Unstake $GMX from GMX.io and transfer tokens to the caller (operator).
    /// @dev This will burn any aggregated multiplier points, so should be avoided where possible.
    function unstakeGmx(uint256 _amount) external override onlyOperators {
        gmxRewardRouter.unstakeGmx(_amount);
        gmxToken.safeTransfer(msg.sender, _amount);
    }

    /// @notice Buy and stake $GLP using GMX's contracts using a whitelisted token. Note: GMX takes fees dependent on the pool constituents.
    function mintAndStakeGlp(uint256 fromAmount, address fromToken, uint256 minUsdg, uint256 minGlp) external onlyOperators returns (uint256) {
        IERC20(fromToken).safeIncreaseAllowance(glpManager, fromAmount);
        return gmxRewardRouter.mintAndStakeGlp(fromToken, fromAmount, minUsdg, minGlp);
    }

    /// @notice Unstake and sell $GLP using GMX's contracts, to a whitelisted token. Note: GMX takes fees dependent on the pool constituents.
    function unstakeAndRedeemGlp(uint256 glpAmount, address toToken, uint256 minOut, address receiver) external onlyOperators returns (uint256) {
        return gmxRewardRouter.unstakeAndRedeemGlp(toToken, glpAmount, minOut, receiver);
    }

    /// @notice Transfer staked $GLP to another receiver. This will unstake from this contract and restake to another user.
    function transferStakedGlp(uint256 glpAmount, address receiver) external onlyOperators {
        stakedGlp.transfer(receiver, glpAmount);
    }

    /// @notice The current wrappedNative and esGMX rewards per second
    /// for STAX's share of the upstream GMX rewards.
    function rewardRates(bool glpTrackerRewards) external override view returns (
        uint256 wrappedNativeTokensPerSec,
        uint256 esGmxTokensPerSec
    ) {
        if (glpTrackerRewards) {
            wrappedNativeTokensPerSec = _rewardsPerSec(feeGlpTracker);
            esGmxTokensPerSec = _rewardsPerSec(stakedGlpTracker);
        } else {
            wrappedNativeTokensPerSec = _rewardsPerSec(feeGmxTracker);
            esGmxTokensPerSec = _rewardsPerSec(stakedGmxTracker);
        }
    }

    /// @notice The amount of $esGMX and $Native (ETH/AVAX) which are claimable by STAX as of now
    /// @dev This is composed of both the staked GMX and staked GLP rewards that this depositor may hold
    function harvestableRewards(bool glpTrackerRewards) external view override returns (
        uint256 wrappedNativeAmount, 
        uint256 esGmxAmount
    ) {
        if (glpTrackerRewards) {
            wrappedNativeAmount = feeGlpTracker.claimable(address(this));
            esGmxAmount = stakedGlpTracker.claimable(address(this));
        } else {
            wrappedNativeAmount = feeGmxTracker.claimable(address(this));
            esGmxAmount = stakedGmxTracker.claimable(address(this));
        }
    }

    /// @notice Harvest all rewards, and apply compounding:
    /// - Claim all wrappedNative and send to staxGmxManager
    /// - Claim all esGMX and:
    ///     - Deposit a portion into vesting (given by `esGmxVestingRate`)
    ///     - Stake the remaining portion
    /// - Claim all GMX from vested esGMX and send to staxGmxManager
    ///     (the manager will re-invest the total GMX claimed across all depositors)
    /// - Stake/compound any multiplier point rewards (aka bnGmx) 
    /// @dev only the StaxGmxManager can call since we need to track and action based on the amounts harvested.
    function harvestRewards(FractionalAmount.Data calldata _esGmxVestingRate) external onlyOperators override returns (
        uint256 wrappedNativeClaimedFromGmx,
        uint256 wrappedNativeClaimedFromGlp,
        uint256 esGmxClaimedFromGmx,
        uint256 esGmxClaimedFromGlp,
        uint256 vestedGmxClaimed
    ) {
        uint256 esGmxVesting;

        // Stack too deep
        {
            // Check balances before/after in order to check how much wrappedNative, esGMX, mult points
            // were rewarded.
            uint256 wrappedNativeBefore = wrappedNativeToken.balanceOf(address(this));
            uint256 esGmxBefore = esGmxToken.balanceOf(address(this));
            // uint256 stakedMultPointsBefore = feeGmxTracker.depositBalances(address(this), bnGmxAddr);

            // In order to calculate how much is from GLP vs GMX, the only option is to
            // call claimable before handleRewards()
            esGmxClaimedFromGlp = stakedGlpTracker.claimable(address(this));
            wrappedNativeClaimedFromGlp = feeGlpTracker.claimable(address(this));

            gmxRewardRouter.handleRewards(
                false, /* _shouldClaimGmx - claims any vested GMX. We do this manually after for less gas */
                false, /* _shouldStakeGmx - The StaxGmxManager will decide where to stake the vested GMX */
                true,  /* _shouldClaimEsGmx - Always claim esGMX rewards */
                false, /* _shouldStakeEsGmx - Manually stake/vest these after */
                true,  /* _shouldStakeMultiplierPoints - Always claim and stake mult point rewards */
                true,  /* _shouldClaimWeth - Always claim weth/wavax rewards */
                false  /* _shouldConvertWethToEth - Never convert to ETH in this contract */
            );

            // Claim any vested esGMX
            vestedGmxClaimed = esGmxVester.claim();

            // Calculate how many rewards were awarded (shame the handleRewards fn doesn't do this for us)
            uint256 totalEsGmxClaimed;
            uint256 totalWrappedNativeClaimed;
            unchecked {
                totalWrappedNativeClaimed = wrappedNativeToken.balanceOf(address(this)) - wrappedNativeBefore;
                wrappedNativeClaimedFromGmx = totalWrappedNativeClaimed > wrappedNativeClaimedFromGlp
                    ? wrappedNativeClaimedFromGmx - wrappedNativeClaimedFromGlp
                    : 0;
                totalEsGmxClaimed = esGmxToken.balanceOf(address(this)) - esGmxBefore;
                esGmxClaimedFromGmx = totalEsGmxClaimed > esGmxClaimedFromGlp
                    ? totalEsGmxClaimed - esGmxClaimedFromGlp
                    : 0;
                // multiplierPointsReinvested = feeGmxTracker.depositBalances(address(this), bnGmxAddr) - stakedMultPointsBefore;
            }

            // Send the wrappedNative rewards back to the caller (staxGmxManager)
            if (totalWrappedNativeClaimed > 0) {
                wrappedNativeToken.safeTransfer(msg.sender, totalWrappedNativeClaimed);
            }

            // Send any vested esGMX (now vested into GMX) -- to 
            if (vestedGmxClaimed > 0) {
                gmxToken.safeTransfer(msg.sender, vestedGmxClaimed);
            }

            // Vest & Stake esGMX
            uint256 esGmxReinvested;
            if (totalEsGmxClaimed > 0) {
                (esGmxVesting, esGmxReinvested) = FractionalAmount.split(_esGmxVestingRate, totalEsGmxClaimed);

                // Vest a portion of esGMX
                if (esGmxVesting > 0) {
                    // There's a limit on how much we are allowed to vest, based on the rewards which
                    // have been earnt.
                    // So use the max(requested, allowed)
                    uint256 maxAllowedToVest = esGmxVester.getMaxVestableAmount(address(this));
                    uint256 alreadyVesting = esGmxVester.getTotalVested(address(this));
                    
                    uint256 remainingAllowedToVest = (maxAllowedToVest > alreadyVesting)
                        ? maxAllowedToVest - alreadyVesting
                        : 0;
                    if (esGmxVesting > remainingAllowedToVest) {
                        esGmxVesting = remainingAllowedToVest;
                        esGmxReinvested = totalEsGmxClaimed-remainingAllowedToVest;                        
                    }

                    // Deposit the amount to vest in the vesting contract.
                    if (esGmxVesting > 0) {
                        esGmxVester.deposit(esGmxVesting);
                    }
                }

                // Stake the remainder.
                if (esGmxReinvested > 0) {
                    gmxRewardRouter.stakeEsGmx(esGmxReinvested);
                }
            }
        }

        // console.log("Actually claimed:", esGmxReinvested+esGmxVesting, wrappedNativeClaimed);

        emit RewardsHarvested(
            wrappedNativeClaimedFromGmx,
            wrappedNativeClaimedFromGlp,
            esGmxClaimedFromGmx,
            esGmxClaimedFromGlp,
            esGmxVesting,
            vestedGmxClaimed
        );

        // emit RewardsHarvested(
        //     wrappedNativeClaimedFromGmx, wrappedNativeClaimedFromGlp, vestedGmxClaimed, esGmxReinvested, 
        //     esGmxVesting, multiplierPointsReinvested
        // );
    }

    /// @notice Pass-through handleRewards() for operators
    /// May be required for manual operations / future automation
    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external onlyOperators {
        gmxRewardRouter.handleRewards(
            _shouldClaimGmx,
            _shouldStakeGmx,
            _shouldClaimEsGmx,
            _shouldStakeEsGmx,
            _shouldStakeMultiplierPoints,
            _shouldClaimWeth,
            _shouldConvertWethToEth
        );
    }

    /// @notice Pass-through deposit esGMX into the vesting contract.
    /// May be required for manual operations / future automation
    function depositIntoEsGmxVesting(address _esGmxVester, uint256 _amount) external onlyOperators {
        IGmxVester(_esGmxVester).deposit(_amount);
    }

    /// @notice Pass-through withdraw from the esGMX vesting contract.
    /// May be required for manual operations / future automation
    /// @dev This can only withdraw the full amount only
    function withdrawFromEsGmxVesting(address _esGmxVester) external onlyOperators {
        IGmxVester(_esGmxVester).withdraw();
    }

    /// @dev STAXs share of the underlying GMX reward distributor's total 
    /// rewards per second
    function _rewardsPerSec(IGmxRewardTracker rewardTracker) internal view returns (uint256) {
        uint256 supply = rewardTracker.totalSupply();
        if (supply == 0) return 0;

        return (
            IGmxRewardDistributor(rewardTracker.distributor()).tokensPerInterval() * 
            rewardTracker.stakedAmounts(address(this)) /
            supply
        );
    }

    /// @notice Owner can recover tokens
    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
        emit CommonEventsAndErrors.TokenRecovered(_to, _token, _amount);
    }

    /// @notice Execute is provided for the operator (StaxGmxManager),
    /// in case there are future operations on the GMX contracts which need to be called which 
    /// aren't explicitly created.
    function execute(address _to, uint256 _value, bytes calldata _data) external onlyOperators returns (bytes memory) {
        return Executable.execute(_to, _value, _data);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/gmx/IGmxRewardRouter.sol)

interface IGmxRewardRouter {
    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;
    function stakeGmx(uint256 _amount) external;
    function unstakeGmx(uint256 _amount) external;
    function stakeEsGmx(uint256 _amount) external;
    function gmx() external view returns (address);
    function glp() external view returns (address);
    function esGmx() external view returns (address);
    function bnGmx() external view returns (address);
    function weth() external view returns (address);
    function stakedGmxTracker() external view returns (address);
    function feeGmxTracker() external view returns (address);
    function stakedGlpTracker() external view returns (address);
    function feeGlpTracker() external view returns (address);
    function gmxVester() external view returns (address);
    function glpVester() external view returns (address);
    function glpManager() external view returns (address);
    function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external returns (uint256);
    function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/gmx/IGmxRewardTracker.sol)

interface IGmxRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);
    function stakedAmounts(address _account) external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function distributor() external view returns (address);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/gmx/IGmxRewardDistributor.sol)

interface IGmxRewardDistributor {
    function tokensPerInterval() external view returns (uint256);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/gmx/IGmxVester.sol)

interface IGmxVester {
    function deposit(uint256 _amount) external;
    function withdraw() external;
    function claim() external returns (uint256);
    function getMaxVestableAmount(address _account) external view returns (uint256);
    function getTotalVested(address _account) external view returns (uint256);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/gmx/IStaxGmxDepositor.sol)

import "../../../common/FractionalAmount.sol";

interface IStaxGmxDepositor {
    function rewardRates(bool glpTrackerRewards) external view returns (uint256 wrappedNativeTokensPerSec, uint256 esGmxTokensPerSec);
    function harvestableRewards(bool glpTrackerRewards) external view returns (
        uint256 wrappedNativeAmount, 
        uint256 esGmxAmount
    );
    function harvestRewards(FractionalAmount.Data calldata _esGmxVestingRate) external returns (
        uint256 wrappedNativeClaimedFromGmx,
        uint256 wrappedNativeClaimedFromGlp,
        uint256 esGmxClaimedFromGmx,
        uint256 esGmxClaimedFromGlp,
        uint256 vestedGmxClaimed
    );

    function stakeGmx(uint256 _amount) external;
    function unstakeGmx(uint256 _maxAmount) external;

    function mintAndStakeGlp(
        uint256 fromAmount,
        address fromToken,
        uint256 minUsdg,
        uint256 minGlp
    ) external returns (uint256);
    function unstakeAndRedeemGlp(
        uint256 glpAmount, 
        address toToken, 
        uint256 minOut, 
        address receiver
    ) external returns (uint256);
    function transferStakedGlp(uint256 glpAmount, address receiver) external;
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (common/FractionalAmount.sol)

import "./CommonEventsAndErrors.sol";

/// @notice Utilities to operate on fractional amounts of an input
/// - eg to calculate the split of rewards for fees.
library FractionalAmount {
    struct Data {
        uint128 numerator;
        uint128 denominator;
    }

    /// @notice Helper to set the storage value with safety checks.
    function set(Data storage self, uint128 _numerator, uint128 _denominator) internal {
        if (_denominator == 0 || _numerator > _denominator) revert CommonEventsAndErrors.InvalidParam();
        self.numerator = _numerator;
        self.denominator = _denominator;
    }

    /// @notice Split an amount into two parts based on a fractional ratio
    /// eg: 333/1000 (33.3%) can be used to split an input amount of 600 into: (199, 401).
    /// @dev The numerator amount is truncated if necessary
    function split(Data storage self, uint256 inputAmount) internal view returns (uint256 numeratorAmount, uint256 denominatorAmount) {
        if (self.numerator == 0) {
            return (0, inputAmount);
        }
        unchecked {
            numeratorAmount = (inputAmount * self.numerator) / self.denominator;
            denominatorAmount = inputAmount - numeratorAmount;
        }
    }

    /// @notice Split an amount into two parts based on a fractional ratio
    /// eg: 333/1000 (33.3%) can be used to split an input amount of 600 into: (199, 401).
    /// @dev Overloaded version of the above, using calldata/pure to avoid a copy from storage in some scenarios
    function split(Data calldata self, uint256 inputAmount) internal pure returns (uint256 numeratorAmount, uint256 denominatorAmount) {
        if (self.numerator == 0 || self.denominator == 0) {
            return (0, inputAmount);
        }
        unchecked {
            numeratorAmount = (inputAmount * self.numerator) / self.denominator;
            denominatorAmount = inputAmount - numeratorAmount;
        }
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (common/CommonEventsAndErrors.sol)

/// @notice A collection of common errors thrown within the STAX contracts
library CommonEventsAndErrors {
    error InsufficientBalance(address token, uint256 required, uint256 balance);
    error InvalidToken(address token);
    error InvalidParam();
    error InvalidAddress(address addr);
    error OnlyOwner(address caller);
    error OnlyOwnerOrOperators(address caller);
    error ExpectedNonZero();

    event TokenRecovered(address indexed to, address indexed token, uint256 amount);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (common/Executable.sol)

/// @notice An inlined library function to add a generic execute() function to contracts.
/// @dev As this is a powerful funciton, care and consideration needs to be taken when 
///      adding into contracts, and on who can call.
library Executable {
    error UnknownFailure();

    /// @notice Call a function on another contract, where the msg.sender will be this contract
    /// @param _to The address of the contract to call
    /// @param _value Any eth to send
    /// @param _data The encoded function selector and args.
    /// @dev If the underlying function reverts, this willl revert where the underlying revert message will bubble up.
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = _to.call{value: _value}(_data);
        
        if (success) {
            return returndata;
        } else if (returndata.length > 0) {
            // Look for revert reason and bubble it up if present
            // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L232
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert UnknownFailure();
        }
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (common/access/Operators.sol)

/// @notice Inherit to add an Operator role which multiple addreses can be granted.
/// @dev Derived classes to implement addOperator() and removeOperator()
abstract contract Operators {
    /// @notice A set of addresses which are approved to run operations.
    mapping(address => bool) public operators;

    event AddedOperator(address indexed account);
    event RemovedOperator(address indexed account);

    error OnlyOperators(address caller);

    function _addOperator(address _account) internal {
        operators[_account] = true;
        emit AddedOperator(_account);
    }

    /// @notice Grant `_account` the operator role
    /// @dev Derived classes to implement and add protection on who can call
    function addOperator(address _account) external virtual;

    function _removeOperator(address _account) internal {
        delete operators[_account];
        emit RemovedOperator(_account);
    }

    /// @notice Revoke the operator role from `_account`
    /// @dev Derived classes to implement and add protection on who can call
    function removeOperator(address _account) external virtual;

    modifier onlyOperators() {
        if (!operators[msg.sender]) revert OnlyOperators(msg.sender);
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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