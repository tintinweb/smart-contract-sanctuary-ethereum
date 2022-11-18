// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin4/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20Upgradeable as IERC20 } from "@openzeppelin4/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin4/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { PausableUpgradeable as Pausable } from "@openzeppelin4/contracts-upgradeable/security/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable as ReentrancyGuard } from "@openzeppelin4/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { AccessControlUpgradeable as AccessControl } from "@openzeppelin4/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./interfaces/IManager.sol";
import "../interfaces/events/Destinations.sol";
import "../interfaces/events/BalanceUpdateEvent.sol";
import "../interfaces/events/IEventSender.sol";

import "./IAccToke.sol";

contract AccToke is IAccToke, Initializable, Pausable, ReentrancyGuard, IEventSender, AccessControl {
	using SafeERC20 for IERC20;

	// wallet address -> deposit info for user (lock cycle / amount / lockedFor)
	mapping(address => DepositInfo) private _deposits;
	// wallet address -> accToke balance
	mapping(address => uint256) private _balances;
	// wallet address -> details of withdrawal request
	mapping(address => WithdrawalInfo) public requestedWithdrawals;

	// roles
	bytes32 public constant LOCK_FOR_ROLE = keccak256("LOCK_FOR_ROLE");

	IManager public manager;
	IERC20 public toke;
	uint256 public override minLockCycles;
	uint256 public override maxLockCycles;
	uint256 public override maxCap;

	uint256 internal accTotalSupply;

	// implied: deployableLiquidity = underlyer.balanceOf(this) - withheldLiquidity
	uint256 public override withheldLiquidity;

	//////////////////////////
	// L2 Sending Support
	bool public _eventSend;
	Destinations public destinations;
	bytes32 private constant EVENT_TYPE_DEPOSIT = bytes32("Deposit");
	bytes32 private constant EVENT_TYPE_WITHDRAW_REQUEST = bytes32("Withdrawal Request");

	modifier onEventSend() {
		if (_eventSend) {
			_;
		}
	}

	//@custom:oz-upgrades-unsafe-allow constructor
	//solhint-disable-next-line no-empty-blocks
	constructor() {
		_disableInitializers();
	}

	/// @param _manager Address of manager contract
	/// @param _minLockCycles Minimum number of lock cycles
	/// @param _maxLockCycles Maximum number of lock cycles
	/// @param _toke TOKE ERC20 address
	/// @param _maxCap Maximum amount of accToke that can be out there
	function initialize(
		address _manager,
		uint256 _minLockCycles,
		uint256 _maxLockCycles,
		IERC20 _toke,
		uint256 _maxCap
	) external initializer {
		require(_manager != address(0), "INVALID_MANAGER_ADDRESS");
		require(_minLockCycles > 0, "INVALID_MIN_LOCK_CYCLES");
		require(_maxLockCycles > 0, "INVALID_MAX_LOCK_CYCLES");
		require(_maxCap > 0, "INVALID_MAX_CAP");
		require(address(_toke) != address(0), "INVALID_TOKE_ADDRESS");

		__Context_init_unchained();
		__AccessControl_init_unchained();
		__Pausable_init_unchained();
		__ReentrancyGuard_init_unchained();

		// add deployer to default admin role
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setupRole(LOCK_FOR_ROLE, _msgSender());

		manager = IManager(_manager);
		toke = _toke;

		setMaxLockCycles(_maxLockCycles);
		setMinLockCycles(_minLockCycles);
		setMaxCap(_maxCap);
	}

	//////////////////////////////////////////////////
	//												//
	//					LOCKING						//
	//												//
	//////////////////////////////////////////////////

	function lockToke(uint256 tokeAmount, uint256 numOfCycles) external override whenNotPaused nonReentrant {
		_lockToke(msg.sender, tokeAmount, numOfCycles);
	}

	function lockTokeFor(
		uint256 tokeAmount,
		uint256 numOfCycles,
		address account
	) external override whenNotPaused nonReentrant onlyRole(LOCK_FOR_ROLE) {
		_lockToke(account, tokeAmount, numOfCycles);
	}

	/// @dev Private method that targets the lock to specific cycle
	/// @param account Account to lock TOKE for
	/// @param tokeAmount Amount of TOKE to lock up
	/// @param numOfCycles Number of cycles to lock for
	function _lockToke(address account, uint256 tokeAmount, uint256 numOfCycles) internal {
		require(account != address(0) && account != address(this), "INVALID_ACCOUNT");
		require(tokeAmount > 0, "INVALID_TOKE_AMOUNT");
		// check if there's sufficient TOKE to lock up
		require(toke.balanceOf(msg.sender) >= tokeAmount, "INSUFFICIENT_TOKE_BALANCE");
		// check if we're still under the cap
		require(maxCap >= accTotalSupply + tokeAmount, "MAX_CAP_EXCEEDED");

		// check if lock cycle info is valid
		_checkLockCyclesValidity(account, numOfCycles);

		// get current cycle ID (+1 if in rollover currently)
		uint256 currentCycleID = getCurrentCycleID();
		if (manager.getRolloverStatus()) currentCycleID++;

		// transfer toke to us
		toke.safeTransferFrom(msg.sender, address(this), tokeAmount);
		// update total supply
		accTotalSupply += tokeAmount;

		// update balance
		_balances[account] += tokeAmount;

		// save user's deposit info
		DepositInfo storage deposit = _deposits[account];
		deposit.lockDuration = numOfCycles;
		deposit.lockCycle = currentCycleID;

		// L1 event (deltas)
		emit TokeLockedEvent(msg.sender, account, numOfCycles, currentCycleID, tokeAmount);
		// L2 event (final balance)
		encodeAndSendData(EVENT_TYPE_DEPOSIT, account, _getUserVoteBalance(account));
	}

	//////////////////////////////////////////////////
	//												//
	//			Withdraw Requests					//
	//												//
	//////////////////////////////////////////////////

	function requestWithdrawal(uint256 amount) external override nonReentrant {
		// check amount and that there's something to withdraw to begin with
		require(amount > 0, "INVALID_AMOUNT");
		require(amount <= balanceOf(msg.sender), "INSUFFICIENT_BALANCE");

		// check to make sure we can request withdrawal in this cycle to begin with
		_canRequestWithdrawalCheck();

		WithdrawalInfo storage withdrawalInfo = requestedWithdrawals[msg.sender];

		//adjust withheld liquidity by removing the original withheld amount and adding the new amount
		withheldLiquidity = withheldLiquidity - withdrawalInfo.amount + amount;

		withdrawalInfo.amount = amount;
		// set withdrawal cycle: if not rollover then current+1, otherwise current+2
		withdrawalInfo.minCycle = getCurrentCycleID() + (!manager.getRolloverStatus() ? 1 : 2);

		// L1 event (just a record of request)
		emit WithdrawalRequestedEvent(msg.sender, amount);
		// L2 (decrease voting balance)
		encodeAndSendData(EVENT_TYPE_WITHDRAW_REQUEST, msg.sender, _getUserVoteBalance(msg.sender));
	}

	function cancelWithdrawalRequest() external override nonReentrant {
		WithdrawalInfo storage withdrawalInfo = requestedWithdrawals[msg.sender];
		require(withdrawalInfo.amount > 0, "NO_PENDING_WITHDRAWAL_REQUESTS");

		//adjust withheld liquidity by removing this request's withdrawal amount
		withheldLiquidity -= withdrawalInfo.amount;

		delete requestedWithdrawals[msg.sender];

		// L1 signal
		emit WithdrawalRequestCancelledEvent(msg.sender);
		// L2 send increased voting balance
		encodeAndSendData(EVENT_TYPE_WITHDRAW_REQUEST, msg.sender, _getUserVoteBalance(msg.sender));
	}

	//////////////////////////////////////////////////
	//												//
	//					Withdrawal					//
	//												//
	//////////////////////////////////////////////////

	function withdraw(uint256 amount) external override whenNotPaused nonReentrant {
		require(amount > 0, "INVALID_AMOUNT");
		require(amount <= balanceOf(msg.sender), "INSUFFICIENT_BALANCE");

		uint256 allowance = _getMaxWithdrawalAmountAllowed();
		require(amount <= allowance, "AMOUNT_GT_MAX_WITHDRAWAL");

		// decrease withdrawal request
		WithdrawalInfo storage withdrawalInfo = requestedWithdrawals[msg.sender];
		withdrawalInfo.amount -= amount;

		// update balances
		_balances[msg.sender] -= amount;
		accTotalSupply -= amount;
		withheldLiquidity -= amount;

		// if no more balance, wipe out deposit info completely
		if (_balances[msg.sender] == 0) {
			delete _deposits[msg.sender];
		}

		// if request is exhausted, delete it
		if (withdrawalInfo.amount == 0) {
			delete requestedWithdrawals[msg.sender];
		}

		// send toke back to user
		toke.safeTransfer(msg.sender, amount);

		// L1 event
		emit WithdrawalEvent(msg.sender, amount);
		// L2 update: NOTE: not needed! since amount was already taken out when request was made
	}

	//////////////////////////////////////////////////
	//												//
	//			   IERC20 (partial)					//
	//												//
	//////////////////////////////////////////////////

	/// @dev See {IERC20-name}
	function name() external pure override returns (string memory) {
		return "accTOKE";
	}

	/// @dev See {IERC20-symbol}
	function symbol() external pure override returns (string memory) {
		return "accTOKE";
	}

	/// @dev See {IERC20-decimals}
	function decimals() external pure override returns (uint8) {
		return 18;
	}

	/// @dev See {IERC20-totalSupply}
	function totalSupply() external view override returns (uint256) {
		return accTotalSupply;
	}

	/// @dev See {IERC20-balanceOf}
	function balanceOf(address account) public view override returns (uint256 balance) {
		require(account != address(0), "INVALID_ADDRESS");
		return _balances[account];
	}

	//////////////////////////////////////////////////
	//												//
	//			   	  Enumeration					//
	//												//
	//////////////////////////////////////////////////

	/// @dev Presentable info from merged collections
	function getDepositInfo(
		address account
	) external view override returns (uint256 lockCycle, uint256 lockDuration, uint256 amount) {
		return (_deposits[account].lockCycle, _deposits[account].lockDuration, _balances[account]);
	}

	/// @dev added custom getter to avoid issues with directly returning struct
	function getWithdrawalInfo(address account) external view override returns (uint256 minCycle, uint256 amount) {
		return (requestedWithdrawals[account].minCycle, requestedWithdrawals[account].amount);
	}

	//////////////////////////////////////////////////////////
	//														//
	//			   Admin maintenance functions				//
	//														//
	//////////////////////////////////////////////////////////

	function setMinLockCycles(uint256 _minLockCycles) public override onlyRole(DEFAULT_ADMIN_ROLE) {
		require(_minLockCycles > 0 && _minLockCycles <= maxLockCycles, "INVALID_MIN_LOCK_CYCLES");
		minLockCycles = _minLockCycles;

		emit MinLockCyclesSetEvent(minLockCycles);
	}

	function setMaxLockCycles(uint256 _maxLockCycles) public override onlyRole(DEFAULT_ADMIN_ROLE) {
		require(_maxLockCycles >= minLockCycles, "INVALID_MAX_LOCK_CYCLES");
		maxLockCycles = _maxLockCycles;

		emit MaxLockCyclesSetEvent(maxLockCycles);
	}

	function setMaxCap(uint256 _maxCap) public override onlyRole(DEFAULT_ADMIN_ROLE) {
		require(_maxCap <= toke.totalSupply(), "LT_TOKE_SUPPLY");
		maxCap = _maxCap;

		emit MaxCapSetEvent(maxCap);
	}

	//////////////////////////////////////////////////
	//												//
	//		L2 Event Sending Functionality			//
	//												//
	//////////////////////////////////////////////////

	/// @dev Enable/Disable L2 event sending
	function setEventSend(bool _eventSendSet) external override onlyRole(DEFAULT_ADMIN_ROLE) {
		require(destinations.destinationOnL2 != address(0), "DESTINATIONS_NOT_SET");

		_eventSend = _eventSendSet;

		emit EventSendSet(_eventSendSet);
	}

	/// @dev Set L2 destinations
	function setDestinations(
		address _fxStateSender,
		address _destinationOnL2
	) external override onlyRole(DEFAULT_ADMIN_ROLE) {
		require(_fxStateSender != address(0), "INVALID_ADDRESS");
		require(_destinationOnL2 != address(0), "INVALID_ADDRESS");

		destinations.fxStateSender = IFxStateSender(_fxStateSender);
		destinations.destinationOnL2 = _destinationOnL2;

		emit DestinationsSet(_fxStateSender, _destinationOnL2);
	}

	/// @dev Encode and send data to L2
	/// @param _eventSig Event signature: MUST be known and preset in routes prior (otherwise message is ignored)
	/// @param _user Address to send message about
	/// @param _amount Final balance snapshot we're sending
	function encodeAndSendData(bytes32 _eventSig, address _user, uint256 _amount) private onEventSend {
		require(address(destinations.fxStateSender) != address(0), "ADDRESS_NOT_SET");
		require(destinations.destinationOnL2 != address(0), "ADDRESS_NOT_SET");

		bytes memory data = abi.encode(BalanceUpdateEvent(_eventSig, _user, address(this), _amount));

		destinations.fxStateSender.sendMessageToChild(destinations.destinationOnL2, data);
	}

	//////////////////////////////////////////////////
	//												//
	//			Misc Helper Functions				//
	//												//
	//////////////////////////////////////////////////

	function getCurrentCycleID() public view override returns (uint256) {
		return manager.getCurrentCycleIndex();
	}

	function _checkLockCyclesValidity(address account, uint256 lockForCycles) private view {
		// make sure the length of lock is valid
		require(lockForCycles >= minLockCycles && lockForCycles <= maxLockCycles, "INVALID_LOCK_CYCLES");
		// if the user has existing lock, make sure new duration is AT LEAST matching existing lock
		if (_deposits[account].lockDuration > 0) {
			require(lockForCycles >= _deposits[account].lockDuration, "LOCK_LENGTH_MUST_BE_GTE_EXISTING");
		}
	}

	function _canRequestWithdrawalCheck() internal view {
		uint256 currentCycleID = getCurrentCycleID();
		DepositInfo memory deposit = _deposits[msg.sender];
		// must be in correct cycle (past initial lock cycle, and when the lock expires)
		require(
			deposit.lockCycle < currentCycleID && // some time passed
				(currentCycleID - deposit.lockCycle) % deposit.lockDuration == 0, // next cycle after lock expiration
			"INVALID_CYCLE_FOR_WITHDRAWAL_REQUEST"
		);
	}

	/// @dev Check if a) can withdraw b) how much was requested
	function _getMaxWithdrawalAmountAllowed() internal view returns (uint256) {
		// get / check the withdrawal request
		WithdrawalInfo memory withdrawalInfo = requestedWithdrawals[msg.sender];
		require(withdrawalInfo.amount > 0, "NO_WITHDRAWAL_REQUEST");
		require(withdrawalInfo.minCycle <= getCurrentCycleID(), "WITHDRAWAL_NOT_YET_AVAILABLE");

		return withdrawalInfo.amount;
	}

	/// @dev Get user balance: acctoke amount - what's requested for withdraw
	function _getUserVoteBalance(address account) internal view returns (uint256) {
		return _balances[account] - requestedWithdrawals[account].amount;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.9;

import "./interfaces/IERC20NonTransferable.sol";

interface IAccToke is IERC20NonTransferable {
	struct WithdrawalInfo {
		uint256 minCycle;
		uint256 amount;
	}

	struct DepositInfo {
		uint256 lockCycle;
		uint256 lockDuration;
	}

	//////////////////////////
	// Events
	event TokeLockedEvent(
		address indexed tokeSource,
		address indexed account,
		uint256 numCycles,
		uint256 indexed currentCycle,
		uint256 amount
	);
	event WithdrawalRequestedEvent(address indexed account, uint256 amount);
	event WithdrawalRequestCancelledEvent(address indexed account);
	event WithdrawalEvent(address indexed account, uint256 amount);

	event MinLockCyclesSetEvent(uint256 minLockCycles);
	event MaxLockCyclesSetEvent(uint256 maxLockCycles);
	event MaxCapSetEvent(uint256 maxCap);

	//////////////////////////
	// Methods

	/// @notice Lock Toke for `numOfCycles` cycles -> get accToke
	/// @param tokeAmount Amount of TOKE to lock up
	/// @param numOfCycles Number of cycles to lock for
	function lockToke(uint256 tokeAmount, uint256 numOfCycles) external;

	/// @notice Lock Toke for a different account for `numOfCycles` cycles -> that account gets resulting accTOKE
	/// @param tokeAmount Amount of TOKE to lock up
	/// @param numOfCycles Number of cycles to lock for
	/// @param account Account to lock TOKE for
	function lockTokeFor(uint256 tokeAmount, uint256 numOfCycles, address account) external;

	/// @notice Request to withdraw TOKE from accToke
	/// @param amount Amount of accTOKE to return
	function requestWithdrawal(uint256 amount) external;

	/// @notice Cancel pending withdraw request (frees up accToke for rewards/voting)
	function cancelWithdrawalRequest() external;

	/// @notice Withdraw previously requested funds
	/// @param amount Amount of TOKE to withdraw
	function withdraw(uint256 amount) external;

	/// @return Amount of liquidity that should not be deployed for market making (this liquidity is set aside for completing requested withdrawals)
	function withheldLiquidity() external view returns (uint256);

	function minLockCycles() external view returns (uint256);

	function maxLockCycles() external view returns (uint256);

	function maxCap() external view returns (uint256);

	function setMaxCap(uint256 totalAmount) external;

	function setMaxLockCycles(uint256 _maxLockCycles) external;

	function setMinLockCycles(uint256 _minLockCycles) external;

	//////////////////////////////////////////////////
	//												//
	//			   	  Enumeration					//
	//												//
	//////////////////////////////////////////////////

	/// @notice Get current cycle
	function getCurrentCycleID() external view returns (uint256);

	/// @notice Get all the deposit information for a specified account
	/// @param account Account to get deposit info for
	/// @return lockCycle Cycle Index when deposit was made
	/// @return lockDuration Number of cycles deposit is locked for
	/// @return amount Amount of TOKE deposited
	function getDepositInfo(
		address account
	) external view returns (uint256 lockCycle, uint256 lockDuration, uint256 amount);

	/// @notice Get withdrawal request info for a specified account
	/// @param account User to get withdrawal request info for
	/// @return minCycle Minimum cycle ID when withdrawal can be processed
	/// @return amount Amount of TOKE requested for withdrawal
	function getWithdrawalInfo(address account) external view returns (uint256 minCycle, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.9.0;

/**
 *  @title Controls the transition and execution of liquidity deployment cycles.
 *  Accepts instructions that can move assets from the Pools to the Exchanges
 *  and back. Can also move assets to the treasury when appropriate.
 */
interface IManager {
	///@notice Gets current starting block
	///@return uint256 with block number
	function getCurrentCycle() external view returns (uint256);

	///@notice Gets current cycle index
	///@return uint256 current cycle number
	function getCurrentCycleIndex() external view returns (uint256);

	///@notice Gets cycle rollover status, true for rolling false for not
	///@return Bool representing whether cycle is rolling over or not
	function getRolloverStatus() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

import "../../fxPortal/IFxStateSender.sol";

/// @notice Configuration entity for sending events to Governance layer
struct Destinations {
	IFxStateSender fxStateSender;
	address destinationOnL2;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;

import "./Destinations.sol";

interface IEventSender {
	event DestinationsSet(address fxStateSender, address destinationOnL2);
	event EventSendSet(bool eventSendSet);

	/// @notice Configure the Polygon state sender root and destination for messages sent
	/// @param fxStateSender Address of Polygon State Sender Root contract
	/// @param destinationOnL2 Destination address of events sent. Should be our Event Proxy
	function setDestinations(address fxStateSender, address destinationOnL2) external;

	/// @notice Enables or disables the sending of events
	function setEventSend(bool eventSendSet) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/// @notice Event sent to Governance layer when a users balance changes
struct BalanceUpdateEvent {
	bytes32 eventSig;
	address account;
	address token;
	uint256 amount;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
pragma solidity >=0.6.11 <0.9;

interface IERC20NonTransferable {
	function name() external view returns (string memory);

	function symbol() external view returns (string memory);

	function decimals() external view returns (uint8);

	function totalSupply() external view returns (uint256);

	function balanceOf(address _owner) external view returns (uint256 balance);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IFxStateSender {
	function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
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
interface IERC20PermitUpgradeable {
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