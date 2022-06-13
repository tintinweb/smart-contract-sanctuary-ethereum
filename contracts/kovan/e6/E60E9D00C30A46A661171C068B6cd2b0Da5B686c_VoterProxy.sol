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

import "./utils/Interfaces.sol";
import "./utils/MathUtil.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title VoterProxy contract
/// @dev based on Convex's VoterProxy smart contract
///      https://etherscan.io/address/0x989AEb4d175e16225E39E87d0D97A3360524AD80#code
contract VoterProxy is IVoterProxy {
    using MathUtil for uint256;

    event OperatorChanged(address newOperator);
    event DepositorChanged(address newDepositor);
    event OwnerChanged(address newOwner);

    error BadInput();
    error Unauthorized();
    error NeedsShutdown(); // Current operator must be shutdown before changing the operator

    address public immutable mintr;
    address public immutable bal; // Reward token
    address public immutable wethBal; // Staking token
    address public immutable veBal; // veBal
    address public immutable gaugeController;

    address public owner; // MultiSig
    address public operator; // Controller smart contract
    address public depositor; // BalDepositor smart contract

    mapping(address => bool) private stashAccess; // stash -> canAccess
    mapping(address => bool) private protectedTokens; // token -> protected

    constructor(
        address _mintr,
        address _bal,
        address _wethBal,
        address _veBal,
        address _gaugeController
    ) {
        mintr = _mintr;
        bal = _bal;
        wethBal = _wethBal;
        veBal = _veBal;
        gaugeController = _gaugeController;
        owner = msg.sender;
        IERC20(_wethBal).approve(_veBal, type(uint256).max);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyOperator() {
        if (msg.sender != operator) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyDepositor() {
        if (msg.sender != depositor) {
            revert Unauthorized();
        }
        _;
    }

    /// @notice Balance of gauge
    /// @param _gauge The gauge to check
    /// @return uint256 balance
    function balanceOfPool(address _gauge) public view returns (uint256) {
        return IBalGauge(_gauge).balanceOf(address(this));
    }

    /// @notice Used to change the owner of the contract
    /// @param _newOwner The new owner of the contract
    function setOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }

    /// @notice Changes the operator of the contract
    /// @dev Only the owner can change the operator
    ///      Current operator must be shutdown before changing the operator
    ///      Or we can set operator to address(0)
    /// @param _operator The new operator of the contract
    function setOperator(address _operator) external onlyOwner {
        if (operator != address(0) && !IDeposit(operator).isShutdown()) {
            revert NeedsShutdown();
        }
        operator = _operator;
        emit OperatorChanged(_operator);
    }

    /// @notice Changes the depositor of the contract
    /// @dev Only the owner can change the depositor
    /// @param _depositor The new depositor of the contract
    function setDepositor(address _depositor) external onlyOwner {
        depositor = _depositor;
        emit DepositorChanged(_depositor);
    }

    /// @notice Sets `_stash` access to `_status`
    /// @param _stash The address of the stash
    /// @param _status The new access status
    function setStashAccess(address _stash, bool _status)
        external
        onlyOperator
    {
        if (_stash != address(0)) {
            stashAccess[_stash] = _status;
        }
    }

    /// @notice Used to deposit tokens
    /// @param _token The address of the LP token
    /// @param _gauge The gauge to deposit to
    function deposit(address _token, address _gauge) external onlyOperator {
        if (protectedTokens[_token] == false) {
            protectedTokens[_token] = true;
        }
        if (protectedTokens[_gauge] == false) {
            protectedTokens[_gauge] = true;
        }

        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(_token).approve(_gauge, balance);
            IBalGauge(_gauge).deposit(balance);
        }
    }

    /// @notice Used for withdrawing tokens
    /// @dev If this contract doesn't have enough tokens it will withdraw them from gauge
    /// @param _token ERC20 token address
    /// @param _gauge The gauge to withdraw from
    /// @param _amount The amount of tokens to withdraw
    function withdraw(
        address _token,
        address _gauge,
        uint256 _amount
    ) public onlyOperator {
        uint256 _balance = IERC20(_token).balanceOf(address(this));

        if (_balance < _amount) {
            IBalGauge(_gauge).withdraw(_amount - _balance);
        }

        IERC20(_token).transfer(msg.sender, _amount);
    }

    function vote(
        uint256 _voteId,
        address _votingAddress,
        bool _support
    ) external onlyOperator {
        IVoting(_votingAddress).vote(_voteId, _support, false);
    }

    /// @notice Votes for gauge weight
    /// @param _gauge The gauge to vote for
    /// @param _weight The weight for a gauge in basis points (units of 0.01%). Minimal is 0.01%. Ignored if 0
    function voteGaugeWeight(address _gauge, uint256 _weight)
        external
        onlyOperator
    {
        IVoting(gaugeController).vote_for_gauge_weights(_gauge, _weight);
    }

    /// @notice Votes for multiple gauge weights
    /// @dev Input arrays must have same length
    /// @param _gauges The gauges to vote for
    /// @param _weights The weights for a gauge in basis points (units of 0.01%). Minimal is 0.01%. Ignored if 0
    function voteMultipleGauges(
        address[] calldata _gauges,
        uint256[] calldata _weights
    ) external onlyOperator {
        if (_gauges.length != _weights.length) {
            revert BadInput();
        }
        for (uint256 i = 0; i < _gauges.length; i = i.unsafeInc()) {
            IVoting(gaugeController).vote_for_gauge_weights(
                _gauges[i],
                _weights[i]
            );
        }
    }

    /// @notice Claims VeBal tokens
    /// @param _gauge The gauge to claim from
    /// @return amount claimed
    function claimBal(address _gauge) external onlyOperator returns (uint256) {
        uint256 _balance;

        try IMinter(mintr).mint(_gauge) {
            _balance = IERC20(bal).balanceOf(address(this));
            IERC20(bal).transfer(operator, _balance);
            //solhint-disable-next-line
        } catch {}

        return _balance;
    }

    /// @notice Claims rewards
    /// @notice _gauge The gauge to claim from
    function claimRewards(address _gauge) external onlyOperator {
        IBalGauge(_gauge).claim_rewards();
    }

    /// @notice Claims fees
    /// @param _distroContract The distro contract to claim from
    /// @param _token The token to claim from
    /// @return uint256 amaunt claimed
    function claimFees(address _distroContract, IERC20 _token)
        external
        onlyOperator
        returns (uint256)
    {
        IFeeDistro(_distroContract).claimToken(address(this), _token);
        uint256 _balance = _token.balanceOf(address(this));
        _token.transfer(operator, _balance);
        return _balance;
    }

    /// @notice Executes a call to `_to` with calldata `_data`
    /// @param _to The address to call
    /// @param _value The ETH value to send
    /// @param _data calldata
    /// @return The result of the call (bool, result)
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOperator returns (bool, bytes memory) {
        // solhint-disable-next-line
        (bool success, bytes memory result) = _to.call{value: _value}(_data);

        return (success, result);
    }

    /// @notice Locks BAL tokens to veBal
    /// @param _value The amount of BAL tokens to lock
    /// @param _unlockTime Epoch time when tokens unlock, rounded down to whole weeks
    function createLock(uint256 _value, uint256 _unlockTime)
        external
        onlyDepositor
    {
        IBalVoteEscrow(veBal).create_lock(_value, _unlockTime);
    }

    /// @notice Increases amount of veBal tokens without modifying the unlock time
    /// @param _value The amount of veBal tokens to increase
    function increaseAmount(uint256 _value) external onlyDepositor {
        IBalVoteEscrow(veBal).increase_amount(_value);
    }

    /// @notice Extend the unlock time
    /// @param _value New epoch time for unlocking
    function increaseTime(uint256 _value) external onlyDepositor {
        IBalVoteEscrow(veBal).increase_unlock_time(_value);
    }

    /// @notice Redeems veBal tokens
    /// @dev Only possible if the lock has expired
    function release() external onlyDepositor {
        IBalVoteEscrow(veBal).withdraw();
    }

    /// @notice Used for pulling extra incentive reward tokens out
    /// @param _asset ERC20 token address
    /// @return amount of tokens withdrawn
    function withdraw(IERC20 _asset) external returns (uint256) {
        if (!stashAccess[msg.sender]) {
            revert Unauthorized();
        }

        if (protectedTokens[address(_asset)]) {
            return 0;
        }

        uint256 balance = _asset.balanceOf(address(this));
        _asset.transfer(msg.sender, balance);
        return balance;
    }

    /// @notice Used for withdrawing tokens
    /// @dev If this contract doesn't have enough tokens it will withdraw them from gauge
    /// @param _token ERC20 token address
    /// @param _gauge The gauge to withdraw from
    function withdrawAll(address _token, address _gauge) external {
        // withdraw has authorization check, so we don't need to check here
        uint256 amount = balanceOfPool(_gauge) +
            (IERC20(_token).balanceOf(address(this)));
        withdraw(_token, _gauge, amount);
    }

    /// @notice Used for withdrawing wethBal tokens to address
    /// @dev If contract doesn't have asked _amount tokens it will withdraw all tokens
    /// @param _to send to address
    /// @param _gauge The gauge
    /// @param _amount The amount to withdraw
    function withdrawWethBal(
        address _to,
        address _gauge,
        uint256 _amount
    ) public returns (bool) {
        require(msg.sender == operator, "!auth");
        IBalVoteEscrow(veBal).withdraw();
        uint256 _balance = IBalVoteEscrow(veBal).balanceOf(address(this), 0);
        if (_balance < _amount) {
            _amount = _balance;
            IBalVoteEscrow(veBal).withdraw();
        }
        IERC20(wethBal).transfer(_to, _amount);
        return true;
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
    function vote(
        uint256,
        bool,
        bool
    ) external; //voteId, support, executeIfDecided

    function vote_for_gauge_weights(address, uint256) external;
}

interface IMinter {
    function mint(address) external;
}

interface IVoterProxy {
    function deposit(address _token, address _gauge) external;

    function withdrawWethBal(
        address,
        address,
        uint256
    ) external returns (bool);

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

    function claimFees(address _distroContract, IERC20 _token)
        external
        returns (uint256);

    function setStashAccess(address _stash, bool _status) external;

    function vote(
        uint256 _voteId,
        address _votingAddress,
        bool _support
    ) external;

    function voteGaugeWeight(address _gauge, uint256 _weight) external;

    function balanceOfPool(address _gauge) external view returns (uint256);

    function operator() external view returns (address);

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool, bytes memory);
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
    function stashRewards() external returns (bool);

    function processStash() external returns (bool);

    function claimRewards() external returns (bool);

    function initialize(
        uint256 _pid,
        address _operator,
        address _staker,
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
    function claimTokens(address user, IERC20[] calldata tokens)
        external
        returns (uint256[] memory);
}

interface ITokenMinter {
    function mint(address, uint256) external;

    function burn(address, uint256) external;
}

interface IDeposit {
    function isShutdown() external view returns (bool);

    function balanceOf(address _account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

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

    function rewardClaimed(
        uint256,
        address,
        uint256
    ) external;

    function withdrawTo(
        uint256,
        uint256,
        address
    ) external;

    function claimRewards(uint256, address) external returns (bool);

    function rewardArbitrator() external returns (address);

    function setGaugeRedirect(uint256 _pid) external returns (bool);

    function owner() external returns (address);
}

interface ICrvDeposit {
    function deposit(uint256, bool) external;

    function lockIncentive() external view returns (uint256);
}

interface IRewardFactory {
    function setAccess(address, bool) external;

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
    function createStash(
        uint256,
        address,
        address
    ) external returns (address);
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
    function fund(address[] calldata _recipient, uint256[] calldata _amount)
        external
        returns (bool);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

// copied from https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/SafeMath.sol

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUtil {
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @dev Gas optimization for loops that iterate over extra rewards
    /// We know that this can't overflow because we can't interate over big arrays
    function unsafeInc(uint256 x) internal pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }
}