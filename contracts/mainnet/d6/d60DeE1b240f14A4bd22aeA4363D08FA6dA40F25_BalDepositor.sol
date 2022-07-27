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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./utils/Interfaces.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title BalDepositor contract
/// @dev Deposit contract for Prime Pools is based on the convex contract crvDepositor.sol
contract BalDepositor is IBalDepositor {
    event FeeManagerChanged(address newFeeManager);
    event LockIncentiveChanged(uint256 newLockIncentive);

    error Unauthorized();
    error InvalidAmount();

    uint256 public constant FEE_DENOMINATOR = 10000;
    uint256 private constant MAXTIME = 365 days;
    uint256 private constant WEEK = 7 days;

    address public immutable wethBal;
    address public immutable veBal;
    address public immutable staker; // VoterProxy smart contract
    address public immutable d2dBal;

    address public feeManager;
    uint256 public lockIncentive = 10; // incentive to users who spend gas to lock bal
    uint256 public incentiveBal;
    uint256 public unlockTime;

    constructor(
        address _wethBal,
        address _veBal,
        address _staker,
        address _d2dBal
    ) {
        wethBal = _wethBal;
        veBal = _veBal;
        staker = _staker;
        d2dBal = _d2dBal;
        feeManager = msg.sender;
    }

    modifier onlyFeeManager() {
        if (msg.sender != feeManager) revert Unauthorized();
        _;
    }

    /// @notice Sets the contracts feeManager variable
    /// @param _feeManager The address of the fee manager
    function setFeeManager(address _feeManager) external onlyFeeManager {
        feeManager = _feeManager;
        emit FeeManagerChanged(_feeManager);
    }

    /// @notice Sets the lock incentive variable
    /// @param _lockIncentive Time to lock tokens
    function setFees(uint256 _lockIncentive) external onlyFeeManager {
        if (_lockIncentive >= 0 && _lockIncentive <= 30) {
            lockIncentive = _lockIncentive;
            emit LockIncentiveChanged(_lockIncentive);
        }
    }

    /// @notice Locks initial Weth/Bal balance in veBal contract via voterProxy contract
    function initialLock() external onlyFeeManager {
        uint256 veBalance = IERC20(veBal).balanceOf(staker);
        if (veBalance == 0) {
            // solhint-disable-next-line
            uint256 unlockAt = block.timestamp + MAXTIME;

            // release old lock if exists
            IVoterProxy(staker).release();
            // create new lock
            uint256 wethBalBalanceStaker = IERC20(wethBal).balanceOf(staker);
            IVoterProxy(staker).createLock(wethBalBalanceStaker, unlockAt);
            unlockTime = (unlockAt / WEEK) * WEEK;
        }
    }

    /// @notice Locks tokens in vBal contract and mints reward tokens to sender
    /// @dev Needed in order to lockFunds on behalf of someone else
    function lockBalancer() external {
        _lockBalancer();

        // mint incentives
        if (incentiveBal > 0) {
            ITokenMinter(d2dBal).mint(msg.sender, incentiveBal);
            incentiveBal = 0;
        }
    }

    /// @notice Deposits entire Weth/Bal balance of caller. Stakes same amount in Rewards contract
    /// @param _stakeAddress The Reward contract address
    /// @param _lock boolean whether depositor wants to lock funds immediately
    function depositAll(bool _lock, address _stakeAddress) external {
        uint256 wethBalBalance = IERC20(wethBal).balanceOf(msg.sender); //This is balancer balance of msg.sender
        deposit(wethBalBalance, _lock, _stakeAddress);
    }

    /// @notice Locks initial balance of Weth/Bal in Voter Proxy. Then stakes `_amount` of Weth/Bal tokens to veBal contract
    /// Mints & stakes d2dBal in Rewards contract on behalf of caller
    /// @dev VoterProxy `staker` is responsible for sending Weth/Bal tokens to veBal contract via _locktoken()
    /// All of the minted d2dBal will be automatically staked to the Rewards contract
    /// @param _amount The amount of tokens user wants to stake
    /// @param _lock boolean whether depositor wants to lock funds immediately
    /// @param _stakeAddress The Reward contract address
    function deposit(
        uint256 _amount,
        bool _lock,
        address _stakeAddress
    ) public {
        if (_amount == 0) {
            revert InvalidAmount();
        }

        if (_lock) {
            // lock immediately, transfer directly to staker to skip an erc20 transfer
            IERC20(wethBal).transferFrom(msg.sender, staker, _amount);
            _lockBalancer();
            if (incentiveBal > 0) {
                // add the incentive tokens here so they can be staked together
                _amount = _amount + incentiveBal;
                incentiveBal = 0;
            }
        } else {
            // move tokens here
            IERC20(wethBal).transferFrom(msg.sender, address(this), _amount);
            // defer lock cost to another user
            uint256 callIncentive = ((_amount * lockIncentive) / FEE_DENOMINATOR);
            _amount = _amount - callIncentive;

            // add to a pool for lock caller
            incentiveBal = incentiveBal + callIncentive;
        }
        // mint here
        ITokenMinter(d2dBal).mint(address(this), _amount);
        // stake for msg.sender
        IERC20(d2dBal).approve(_stakeAddress, _amount);
        IRewards(_stakeAddress).stakeFor(msg.sender, _amount);
    }

    /// @notice Burns D2DBal from some address
    /// @dev Only Controller can call this
    function burnD2DBal(address _from, uint256 _amount) external {
        if (msg.sender != IVoterProxy(staker).operator()) {
            revert Unauthorized();
        }

        ITokenMinter(d2dBal).burn(_from, _amount);
    }

    /// @notice Transfers Weth/Bal from VoterProxy `staker` to veBal contract
    /// @dev VoterProxy `staker` is responsible for transferring Weth/Bal tokens to veBal contract via increaseAmount()
    function _lockBalancer() internal {
        // multiple SLOAD -> MLOAD
        address wethBalMemory = wethBal;
        address stakerMemory = staker;

        uint256 wethBalBalance = IERC20(wethBalMemory).balanceOf(address(this));
        if (wethBalBalance > 0) {
            IERC20(wethBalMemory).transfer(stakerMemory, wethBalBalance);
        }

        uint256 wethBalBalanceStaker = IERC20(wethBalMemory).balanceOf(stakerMemory);
        if (wethBalBalanceStaker == 0) {
            return;
        }

        // increase amount
        IVoterProxy(stakerMemory).increaseAmount(wethBalBalanceStaker);

        // solhint-disable-next-line
        uint256 newUnlockAt = block.timestamp + MAXTIME;
        uint256 unlockInWeeks = (newUnlockAt / WEEK) * WEEK;

        // We always want to have max voting power on each vote
        // Bal voting is a weekly event, and we want to increase time every week
        // solhint-disable-next-line
        if ((unlockInWeeks - unlockTime) > 2) {
            IVoterProxy(stakerMemory).increaseTime(newUnlockAt);
            // solhint-disable-next-line
            unlockTime = newUnlockAt;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBalGauge {
    function deposit(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function withdraw(uint256) external;

    function claim_rewards() external;

    function reward_tokens(uint256) external view returns (address);

    function lp_token() external view returns (address);
}

interface IBalVoteEscrow {
    function create_lock(uint256, uint256) external;

    function increase_amount(uint256) external;

    function increase_unlock_time(uint256) external;

    function withdraw() external;

    function smart_wallet_checker() external view returns (address);

    function balanceOf(address, uint256) external view returns (uint256);

    function balanceOfAt(address, uint256) external view returns (uint256);
}

interface IVoting {
    function vote_for_gauge_weights(address, uint256) external;
}

interface IMinter {
    function mint(address) external;
}

interface IBalDepositor {
    function d2dBal() external view returns (address);

    function wethBal() external view returns (address);

    function burnD2DBal(address _from, uint256 _amount) external;
}

interface IVoterProxy {
    function deposit(address _token, address _gauge) external;

    function withdrawWethBal(address _to) external;

    function wethBal() external view returns (address);

    function depositor() external view returns (address);

    function withdraw(
        address _token,
        address _gauge,
        uint256 _amount
    ) external;

    function withdrawAll(address _token, address _gauge) external;

    function createLock(uint256 _value, uint256 _unlockTime) external;

    function increaseAmount(uint256 _value) external;

    function increaseTime(uint256 _unlockTimestamp) external;

    function release() external;

    function claimBal(address _gauge) external returns (uint256);

    function claimRewards(address _gauge) external;

    function claimFees(address _distroContract, IERC20[] calldata _tokens) external;

    function delegateVotingPower(address _delegateTo) external;

    function clearDelegate() external;

    function voteMultipleGauges(address[] calldata _gauges, uint256[] calldata _weights) external;

    function balanceOfPool(address _gauge) external view returns (uint256);

    function operator() external view returns (address);

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool, bytes memory);
}

interface ISnapshotDelegateRegistry {
    function setDelegate(bytes32 id, address delegate) external;

    function clearDelegate(bytes32 id) external;
}

interface IRewards {
    function stake(address, uint256) external;

    function stakeFor(address, uint256) external;

    function withdraw(address, uint256) external;

    function exit(address) external;

    function getReward(address) external;

    function queueNewRewards(uint256) external;

    function notifyRewardAmount(uint256) external;

    function addExtraReward(address) external;

    function stakingToken() external view returns (address);

    function rewardToken() external view returns (address);

    function earned(address account) external view returns (uint256);
}

interface IStash {
    function processStash() external;

    function claimRewards() external;

    function initialize(
        uint256 _pid,
        address _operator,
        address _gauge,
        address _rewardFactory
    ) external;
}

interface IFeeDistro {
    /**
     * @notice Claims all pending distributions of the provided token for a user.
     * @dev It's not necessary to explicitly checkpoint before calling this function, it will ensure the FeeDistributor
     * is up to date before calculating the amount of tokens to be claimed.
     * @param user - The user on behalf of which to claim.
     * @param token - The ERC20 token address to be claimed.
     * @return The amount of `token` sent to `user` as a result of claiming.
     */
    function claimToken(address user, IERC20 token) external returns (uint256);

    /**
     * @notice Claims a number of tokens on behalf of a user.
     * @dev A version of `claimToken` which supports claiming multiple `tokens` on behalf of `user`.
     * See `claimToken` for more details.
     * @param user - The user on behalf of which to claim.
     * @param tokens - An array of ERC20 token addresses to be claimed.
     * @return An array of the amounts of each token in `tokens` sent to `user` as a result of claiming.
     */
    function claimTokens(address user, IERC20[] calldata tokens) external returns (uint256[] memory);
}

interface ITokenMinter {
    function mint(address, uint256) external;

    function burn(address, uint256) external;
}

interface IBaseRewardsPool {
    function totalSupply() external view returns (uint256);

    function balanceOf(address _account) external view returns (uint256);
}

interface IController {
    /// @notice returns the number of pools
    function poolLength() external returns (uint256);

    /// @notice Deposits an amount of LP token into a specific pool,
    /// mints reward and optionally tokens and  stakes them into the reward contract
    /// @dev Sender must approve LP tokens to Controller smart contract
    /// @param _pid The pool id to deposit lp tokens into
    /// @param _amount The amount of lp tokens to be deposited
    /// @param _stake bool for wheather the tokens should be staked
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external;

    /// @notice Deposits and stakes all LP tokens
    /// @dev Sender must approve LP tokens to Controller smart contract
    /// @param _pid The pool id to deposit lp tokens into
    /// @param _stake bool for wheather the tokens should be staked
    function depositAll(uint256 _pid, bool _stake) external;

    /// @notice Withdraws lp tokens from the pool
    /// @param _pid The pool id to withdraw lp tokens from
    /// @param _amount amount of LP tokens to withdraw
    function withdraw(uint256 _pid, uint256 _amount) external;

    /// @notice Withdraws all of the lp tokens in the pool
    /// @param _pid The pool id to withdraw lp tokens from
    function withdrawAll(uint256 _pid) external;

    /// @notice Withdraws LP tokens and sends them to a specified address
    /// @param _pid The pool id to deposit lp tokens into
    /// @param _amount amount of LP tokens to withdraw
    function withdrawTo(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external;

    /// @notice Withdraws `amount` of unlocked WethBal to controller
    /// @dev WethBal is redeemable by burning equivalent amount of D2D WethBal
    function withdrawUnlockedWethBal() external;

    /// @notice Burns all D2DWethBal from a user, and transfers the equivalent amount of unlocked WethBal tokes
    function redeemWethBal() external;

    /// @notice Claims rewards from a pool and disperses them to the rewards contract
    /// @param _pid the id of the pool where lp tokens are held
    function earmarkRewards(uint256 _pid) external;

    /// @notice Claims rewards from the Balancer's fee distributor contract and transfers the tokens into the rewards contract
    function earmarkFees() external;

    function isShutdown() external view returns (bool);

    function poolInfo(uint256)
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            bool
        );

    function claimRewards(uint256, address) external;

    function owner() external returns (address);
}

interface IRewardFactory {
    function grantRewardStashAccess(address) external;

    function createBalRewards(uint256, address) external returns (address);

    function createTokenRewards(
        address,
        address,
        address
    ) external returns (address);

    function activeRewardCount(address) external view returns (uint256);

    function addActiveReward(address, uint256) external returns (bool);

    function removeActiveReward(address, uint256) external returns (bool);
}

interface IStashFactory {
    function createStash(uint256 _pid, address _gauge) external returns (address);
}

interface ITokenFactory {
    function createDepositToken(address) external returns (address);
}

interface IProxyFactory {
    function clone(address _target) external returns (address);
}

interface IRewardHook {
    function onRewardClaim() external;
}