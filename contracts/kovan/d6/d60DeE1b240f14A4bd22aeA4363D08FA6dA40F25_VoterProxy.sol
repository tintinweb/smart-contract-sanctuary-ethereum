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
pragma solidity ^0.8.14;

import "./utils/Interfaces.sol";
import "./utils/MathUtil.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title VoterProxy contract
/// @dev based on Convex's VoterProxy smart contract
///      https://etherscan.io/address/0x989AEb4d175e16225E39E87d0D97A3360524AD80#code
contract VoterProxy {
    using MathUtil for uint256;

    event OperatorChanged(address newOperator);
    event DepositorChanged(address newDepositor);
    event OwnerChanged(address newOwner);

    error BadInput();
    error Unauthorized();
    error NeedsShutdown(); // Current operator must be shutdown before changing the operator

    address public immutable mintr;
    address public immutable bal;
    address public immutable veBal;
    address public immutable gaugeController;

    address public owner; // MultiSig
    address public operator; // Controller smart contract
    address public depositor; // BalDepositor smart contract

    mapping(address => bool) private stashAccess; // stash -> canAccess
    mapping(address => bool) private protectedTokens; // token -> protected

    constructor(
        address _mintr,
        address _bal,
        address _veBal,
        address _gaugeController
    ) {
        mintr = _mintr;
        bal = _bal;
        veBal = _veBal;
        gaugeController = _gaugeController;
        owner = msg.sender;
        IERC20(_bal).approve(_veBal, type(uint256).max);
    }

    /// @notice Used to change the owner of the contract
    /// @param _newOwner The new owner of the contract
    function setOwner(address _newOwner) external {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }

    /// @notice Changes the operator of the contract
    /// @dev Only the owner can change the operator
    ///      Current operator must be shutdown before changing the operator
    ///      Or we can set operator to address(0)
    /// @param _operator The new operator of the contract
    function setOperator(address _operator) external {
        if (msg.sender != owner) {
            revert Unauthorized();
        }

        if (operator != address(0) && !IDeposit(operator).isShutdown()) {
            revert NeedsShutdown();
        }
        operator = _operator;
        emit OperatorChanged(_operator);
    }

    /// @notice Changes the depositor of the contract
    /// @dev Only the owner can change the depositor
    /// @param _depositor The new depositor of the contract
    function setDepositor(address _depositor) external {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        depositor = _depositor;
        emit DepositorChanged(_depositor);
    }

    /// @notice Sets `_stash` access to `_status`
    /// @param _stash The address of the stash
    /// @param _status The new access status
    function setStashAccess(address _stash, bool _status)
        external
        returns (bool)
    {
        if (msg.sender != operator) {
            revert Unauthorized();
        }

        if (_stash != address(0)) {
            stashAccess[_stash] = _status;
        }
        return true;
    }

    /// @notice Used to deposit tokens
    /// @param _token The address of the LP token
    /// @param _gauge The gauge to deposit to
    /// @return true if the deposit was successful
    function deposit(address _token, address _gauge) external returns (bool) {
        if (msg.sender != operator) {
            revert Unauthorized();
        }

        if (protectedTokens[_token] == false) {
            protectedTokens[_token] = true;
        }
        if (protectedTokens[_gauge] == false) {
            protectedTokens[_gauge] = true;
        }

        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(_token).approve(_gauge, balance);
            ICurveGauge(_gauge).deposit(balance);
        }

        return true;
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
    /// @param _amount The amount of tokens to withdraw
    /// @return true if the withdrawal was successful
    function withdraw(
        address _token,
        address _gauge,
        uint256 _amount
    ) public returns (bool) {
        if (msg.sender != operator) {
            revert Unauthorized();
        }
        uint256 _balance = IERC20(_token).balanceOf(address(this));

        if (_balance < _amount) {
            ICurveGauge(_gauge).withdraw(_amount - _balance);
        }

        IERC20(_token).transfer(msg.sender, _amount);
        return true;
    }

    /// @notice Used for withdrawing tokens
    /// @dev If this contract doesn't have enough tokens it will withdraw them from gauge
    /// @param _token ERC20 token address
    /// @param _gauge The gauge to withdraw from
    /// @return true if the withdrawal was successful
    function withdrawAll(address _token, address _gauge)
        external
        returns (bool)
    {
        // withdraw has authorization check, so we don't need to check here
        uint256 amount = balanceOfPool(_gauge) +
            (IERC20(_token).balanceOf(address(this)));
        withdraw(_token, _gauge, amount);
        return true;
    }

    /// @notice Locks BAL tokens to veBal
    /// @param _value The amount of BAL tokens to lock
    /// @param _unlockTime Epoch time when tokens unlock, rounded down to whole weeks
    /// @return true if lock was successful
    function createLock(uint256 _value, uint256 _unlockTime)
        external
        returns (bool)
    {
        if (msg.sender != depositor) {
            revert Unauthorized();
        }
        ICurveVoteEscrow(veBal).create_lock(_value, _unlockTime);
        return true;
    }

    /// @notice Increases amount of veBal tokens without modifying the unlock time
    /// @param _value The amount of veBal tokens to increase
    /// @return true if increase was successful
    function increaseAmount(uint256 _value) external returns (bool) {
        if (msg.sender != depositor) {
            revert Unauthorized();
        }
        ICurveVoteEscrow(veBal).increase_amount(_value);
        return true;
    }

    /// @notice Extend the unlock time
    /// @param _value New epoch time for unlocking
    /// @dev return true if the extension was successful
    function increaseTime(uint256 _value) external returns (bool) {
        if (msg.sender != depositor) {
            revert Unauthorized();
        }
        ICurveVoteEscrow(veBal).increase_unlock_time(_value);
        return true;
    }

    /// @notice Redeems veBal tokens
    /// @dev Only possible if the lock has expired
    /// @return true on success
    function release() external returns (bool) {
        if (msg.sender != depositor) {
            revert Unauthorized();
        }
        ICurveVoteEscrow(veBal).withdraw();
        return true;
    }

    function vote(
        uint256 _voteId,
        address _votingAddress,
        bool _support
    ) external returns (bool) {
        if (msg.sender != operator) {
            revert Unauthorized();
        }
        IVoting(_votingAddress).vote(_voteId, _support, false);
        return true;
    }

    /// @notice Votes for gauge weight
    /// @param _gauge The gauge to vote for
    /// @param _weight The weight for a gauge in basis points (units of 0.01%). Minimal is 0.01%. Ignored if 0
    /// @return true on success
    function voteGaugeWeight(address _gauge, uint256 _weight)
        external
        returns (bool)
    {
        if (msg.sender != operator) {
            revert Unauthorized();
        }
        IVoting(gaugeController).vote_for_gauge_weights(_gauge, _weight);
        return true;
    }

    /// @notice Votes for multiple gauge weights
    /// @dev Input arrays must have same length
    /// @param _gauges The gauges to vote for
    /// @param _weights The weights for a gauge in basis points (units of 0.01%). Minimal is 0.01%. Ignored if 0
    function voteMultipleGauges(
        address[] calldata _gauges,
        uint256[] calldata _weights
    ) external returns (bool) {
        if (_gauges.length != _weights.length) {
            revert BadInput();
        }
        if (msg.sender != operator) {
            revert Unauthorized();
        }
        for (uint256 i = 0; i < _gauges.length; i = i.unsafeInc()) {
            IVoting(gaugeController).vote_for_gauge_weights(
                _gauges[i],
                _weights[i]
            );
        }
        return true;
    }

    /// @notice Claims VeBal tokens
    /// @param _gauge The gauge to claim from
    /// @return amount claimed
    function claimBal(address _gauge) external returns (uint256) {
        if (msg.sender != operator) {
            revert Unauthorized();
        }
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
    /// @return true on success
    function claimRewards(address _gauge) external returns (bool) {
        if (msg.sender != operator) {
            revert Unauthorized();
        }
        ICurveGauge(_gauge).claim_rewards();
        return true;
    }

    /// @notice Claims fees
    /// @param _distroContract The distro contract to claim from
    /// @param _token The token to claim from
    /// @return uint256 amaunt claimed
    function claimFees(address _distroContract, address _token)
        external
        returns (uint256)
    {
        if (msg.sender != operator) {
            revert Unauthorized();
        }
        IFeeDistro(_distroContract).claim();
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(operator, _balance);
        return _balance;
    }

    /// @notice Balance of gauge
    /// @param _gauge The gauge to check
    /// @return uint256 balance
    function balanceOfPool(address _gauge) public view returns (uint256) {
        return ICurveGauge(_gauge).balanceOf(address(this));
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
    ) external returns (bool, bytes memory) {
        if (msg.sender != operator) {
            revert Unauthorized();
        }

        // solhint-disable-next-line
        (bool success, bytes memory result) = _to.call{value: _value}(_data);

        return (success, result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ICurveGauge {
    function deposit(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function withdraw(uint256) external;

    function claim_rewards() external;

    function reward_tokens(uint256) external view returns (address); //v2

    function rewarded_token() external view returns (address); //v1

    function lp_token() external view returns (address);
}

interface ICurveVoteEscrow {
    function create_lock(uint256, uint256) external;

    function increase_amount(uint256) external;

    function increase_unlock_time(uint256) external;

    function withdraw() external;

    function smart_wallet_checker() external view returns (address);
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

    function getVote(uint256)
        external
        view
        returns (
            bool,
            bool,
            uint64,
            uint64,
            uint64,
            uint64,
            uint256,
            uint256,
            uint256,
            bytes memory
        );

    function vote_for_gauge_weights(address, uint256) external;
}

interface IMinter {
    function mint(address) external;
}

interface IRegistry {
    function get_registry() external view returns (address);

    function get_address(uint256 _id) external view returns (address);

    function gauge_controller() external view returns (address);

    function get_lp_token(address) external view returns (address);

    function get_gauges(address)
        external
        view
        returns (address[10] memory, uint128[10] memory);
}

interface IStaker {
    function deposit(address, address) external;

    function withdraw(address) external;

    function withdraw(
        address,
        address,
        uint256
    ) external;

    function withdrawAll(address, address) external;

    function createLock(uint256, uint256) external;

    function increaseAmount(uint256) external;

    function increaseTime(uint256) external;

    function release() external;

    function claimCrv(address) external returns (uint256);

    function claimRewards(address) external;

    function claimFees(address, address) external;

    function setStashAccess(address, bool) external;

    function vote(
        uint256,
        address,
        bool
    ) external;

    function voteGaugeWeight(address, uint256) external;

    function balanceOfPool(address) external view returns (uint256);

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
    function claim() external;

    function token() external view returns (address);
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
        uint256 _pid,
        address _gauge,
        address _stash
    ) external returns (address);
}

interface ITokenFactory {
    function CreateDepositToken(address) external returns (address);
}

interface IPools {
    function addPool(address _lptoken, address _gauge) external returns (bool);

    function forceAddPool(address _lptoken, address _gauge)
        external
        returns (bool);

    function shutdownPool(uint256 _pid) external returns (bool);

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
pragma solidity ^0.8.13;

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