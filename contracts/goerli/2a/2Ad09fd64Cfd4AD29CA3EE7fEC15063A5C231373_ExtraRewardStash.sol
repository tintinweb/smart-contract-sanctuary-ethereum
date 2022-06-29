// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./utils/Interfaces.sol";

/// @title ExtraRewardStash
contract ExtraRewardStash is IStash {
    error Unauthorized();
    error AlreadyInitialized();

    event RewardHookSet(address newRewardHook);

    uint256 private constant MAX_REWARDS = 8;
    address public immutable bal;

    uint256 public pid;
    address public operator;
    address public gauge;
    address public rewardFactory;
    address public rewardHook; // address to call for reward pulls
    bool public hasBalRewards;

    mapping(address => uint256) public historicalRewards;

    struct TokenInfo {
        address token;
        address rewardAddress;
    }

    // use mapping + array so that we dont have to loop check each time setToken is called
    mapping(address => TokenInfo) public tokenInfo;
    address[] public tokenList;

    constructor(address _bal) {
        bal = _bal;
    }

    function initialize(
        uint256 _pid,
        address _operator,
        address _gauge,
        address _rFactory
    ) external {
        if (gauge != address(0)) {
            revert AlreadyInitialized();
        }
        pid = _pid;
        operator = _operator;
        gauge = _gauge;
        rewardFactory = _rFactory;
    }

    /// @notice Returns the length of the tokenList
    function tokenCount() external view returns (uint256) {
        return tokenList.length;
    }

    /// @notice Claims registered reward tokens
    function claimRewards() external {
        if (msg.sender != operator) {
            revert Unauthorized();
        }
        // this is updateable from v2 gauges now so must check each time.
        checkForNewRewardTokens();

        if (hasBalRewards) {
            // claim rewards on gauge for staker
            // using reward_receiver so all rewards will be moved to this stash
            IController(operator).claimRewards(pid, gauge);
        }

        // hook for reward pulls
        if (rewardHook != address(0)) {
            // solhint-disable-next-line
            try IRewardHook(rewardHook).onRewardClaim() {} catch {}
        }
    }

    /// @notice Checks if the gauge rewards have changed
    function checkForNewRewardTokens() internal {
        for (uint256 i = 0; i < MAX_REWARDS; i++) {
            address token = IBalGauge(gauge).reward_tokens(i);
            if (token == address(0)) {
                break;
            }
            if (!hasBalRewards) {
                hasBalRewards = true;
            }
            setToken(token);
        }
    }

    /// @notice Registers an extra reward token to be handled
    /// @param _token The reward token address
    /// @dev Used for any new incentive that is not directly on curve gauges
    function setExtraReward(address _token) external {
        // owner of booster can set extra rewards
        if (msg.sender != IController(operator).owner()) {
            revert Unauthorized();
        }
        setToken(_token);
    }

    /// @notice Sets the reward hook address
    /// @param _hook The address of the reward hook
    function setRewardHook(address _hook) external {
        // owner of booster can set reward hook
        if (msg.sender != IController(operator).owner()) {
            revert Unauthorized();
        }
        rewardHook = _hook;
        emit RewardHookSet(_hook);
    }

    /// @notice Replaces a token on the token list
    /// @param _token The address of the token
    function setToken(address _token) internal {
        TokenInfo storage t = tokenInfo[_token];

        if (t.token == address(0)) {
            //set token address
            t.token = _token;

            //check if BAL
            if (_token != bal) {
                //create new reward contract (for NON-BAL tokens only)
                (, , , address mainRewardContract, , ) = IController(operator).poolInfo(pid);
                address rewardContract = IRewardFactory(rewardFactory).createTokenRewards(
                    _token,
                    mainRewardContract,
                    address(this)
                );

                t.rewardAddress = rewardContract;
            }
            //add token to list of known rewards
            tokenList.push(_token);
        }
    }

    /// @notice Sends all of the extra rewards to the reward contracts
    function processStash() external {
        if (msg.sender != operator) {
            revert Unauthorized();
        }
        uint256 tCount = tokenList.length;
        for (uint256 i = 0; i < tCount; i++) {
            TokenInfo storage t = tokenInfo[tokenList[i]];
            address token = t.token;
            if (token == address(0)) continue;

            uint256 amount = IERC20(token).balanceOf(address(this));
            if (amount > 0) {
                historicalRewards[token] = historicalRewards[token] + amount;
                if (token == bal) {
                    //if BAL, send back to booster to distribute
                    IERC20(token).transfer(operator, amount);
                    continue;
                }
                //add to reward contract
                address rewards = t.rewardAddress;
                IERC20(token).transfer(rewards, amount);
                IRewards(rewards).queueNewRewards(amount);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

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

interface IWalletChecker {
    function check(address) external view returns (bool);
}

interface IVoting {
    function vote_for_gauge_weights(address, uint256) external;
}

interface IMinter {
    function mint(address) external;
}

interface IVoterProxy {
    function deposit(address _token, address _gauge) external;

    function withdrawWethBal(address, uint256) external;

    function withdraw(IERC20 _asset) external returns (uint256 balance);

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

    function claimFees(address _distroContract, IERC20 _token) external returns (uint256);

    function grantStashAccess(address _stash) external;

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

    /// @notice Withdraws `amount` of unlocked WethBal to treasury
    /// @param _amount amount of tokens to withdraw
    function withdrawUnlockedWethBal(uint256 _amount) external;

    /// @notice Claims rewards from a pool and disperses them to the rewards contract
    /// @param _pid the id of the pool where lp tokens are held
    function earmarkRewards(uint256 _pid) external;

    /// @notice Claims fees from the Balancer's fee distributor contract and transfers the tokens into the rewards contract
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

interface ICrvDeposit {
    function deposit(uint256, bool) external;

    function lockIncentive() external view returns (uint256);
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

interface IPools {
    function addPool(address, address) external returns (bool);

    function forceAddPool(address, address) external returns (bool);

    function shutdownPool(uint256) external returns (bool);

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

    function poolLength() external view returns (uint256);

    function gaugeMap(address) external view returns (bool);

    function setPoolManager(address _poolM) external;
}

interface IVestedEscrow {
    function fund(address[] calldata _recipient, uint256[] calldata _amount) external returns (bool);
}

interface GaugeController {
    function gauge_types(address _addr) external returns (int128);
}

interface LiquidityGauge {
    function integrate_fraction(address _address) external returns (uint256);

    function user_checkpoint(address _address) external returns (bool);
}

interface IProxyFactory {
    function clone(address _target) external returns (address);
}

interface IRewardHook {
    function onRewardClaim() external;
}