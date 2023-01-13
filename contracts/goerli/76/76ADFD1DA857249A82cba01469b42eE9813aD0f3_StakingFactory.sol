pragma solidity ^0.5.17;

import "./standards/IERC20.sol";

import "./Staking.sol";


contract StakingFactory {
    mapping (address => address) internal instances;

    event NewStaking(address indexed instance, address indexed token);

    function existsInstance(IERC20 _token) external view returns (bool) {
        return address(getInstance(_token)) != address(0);
    }

    function getOrCreateInstance(IERC20 _token) external returns (Staking) {
        Staking instance = getInstance(_token);
        return address(instance) != address(0) ? instance : _createInstance(_token);
    }

    function getInstance(IERC20 _token) public view returns (Staking) {
        return Staking(instances[address(_token)]);
    }

    function _createInstance(IERC20 _token) internal returns (Staking) {
        Staking instance = new Staking(_token);
        address tokenAddress = address(_token);
        address instanceAddress = address(instance);
        instances[tokenAddress] = instanceAddress;
        emit NewStaking(instanceAddress, tokenAddress);
        return instance;
    }
}

pragma solidity ^0.5.17;


// Interface for ERC900: https://eips.ethereum.org/EIPS/eip-900, optional History methods
interface IERC900History {
    /**
     * @dev Tell last time a user modified their staked balance
     * @param _user Address to query
     * @return Last block number when address's balance was modified
     */
    function lastStakedFor(address _user) external view returns (uint256);

    /**
     * @dev Tell the total amount of tokens staked for an address at a given block number
     * @param _user Address to query
     * @param _blockNumber Block number
     * @return Total amount of tokens staked for the address at the given block number
     */
    function totalStakedForAt(address _user, uint256 _blockNumber) external view returns (uint256);

    /**
     * @dev Tell the total amount of tokens staked from all addresses at a given block number
     * @param _blockNumber Block number
     * @return Total amount of tokens staked from all addresses at the given block number
     */
    function totalStakedAt(uint256 _blockNumber) external view returns (uint256);
}

pragma solidity ^0.5.17;


// Interface for ERC900: https://eips.ethereum.org/EIPS/eip-900
interface IERC900 {
    event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
    event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

    /**
     * @dev Stake a certain amount of tokens
     * @param _amount Amount of tokens to be staked
     * @param _data Optional data that can be used to add signalling information in more complex staking applications
     */
    function stake(uint256 _amount, bytes calldata _data) external;

    /**
     * @dev Stake a certain amount of tokens to another address
     * @param _user Address to stake tokens to
     * @param _amount Amount of tokens to be staked
     * @param _data Optional data that can be used to add signalling information in more complex staking applications
     */
    function stakeFor(address _user, uint256 _amount, bytes calldata _data) external;

    /**
     * @dev Unstake a certain amount of tokens
     * @param _amount Amount of tokens to be unstaked
     * @param _data Optional data that can be used to add signalling information in more complex staking applications
     */
    function unstake(uint256 _amount, bytes calldata _data) external;

    /**
     * @dev Tell the current total amount of tokens staked for an address
     * @param _addr Address to query
     * @return Current total amount of tokens staked for the address
     */
    function totalStakedFor(address _addr) external view returns (uint256);

    /**
     * @dev Tell the current total amount of tokens staked from all addresses
     * @return Current total amount of tokens staked from all addresses
     */
    function totalStaked() external view returns (uint256);

    /**
     * @dev Tell the address of the staking token
     * @return Address of the staking token
     */
    function token() external view returns (address);

    /*
     * @dev Tell if the optional history functions are implemented
     * @return True if the optional history functions are implemented
     */
    function supportsHistory() external pure returns (bool);
}

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/lib/token/ERC20.sol
// Adapted to use pragma ^0.5.17 and satisfy our linter rules

pragma solidity ^0.5.17;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address _who) external view returns (uint256);

    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// See MiniMe token (https://github.com/Giveth/minime/blob/master/contracts/MiniMeToken.sol)

pragma solidity ^0.5.17;


interface IApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 _amount,
        address _token,
        bytes calldata _data
    ) external;
}

pragma solidity ^0.5.17;


interface ILockable {
    event NewLockManager(address indexed user, address indexed lockManager, bytes data);
    event LockAmountChanged(address indexed user, address indexed lockManager, uint256 amount);
    event LockAllowanceChanged(address indexed user, address indexed lockManager, uint256 allowance);
    event LockManagerRemoved(address indexed user, address indexed lockManager);
    event LockManagerTransferred(address indexed user, address indexed oldLockManager, address indexed newLockManager);

    function allowManager(address _lockManager, uint256 _allowance, bytes calldata _data) external;
    function unlockAndRemoveManager(address _user, address _lockManager) external;
    function increaseLockAllowance(address _lockManager, uint256 _allowance) external;
    function decreaseLockAllowance(address _user, address _lockManager, uint256 _allowance) external;

    function lock(address _user, uint256 _amount) external;
    function unlock(address _user, address _lockManager, uint256 _amount) external;
    function slash(address _user, address _to, uint256 _amount) external;
    function slashAndUnstake(address _user, address _to, uint256 _amount) external;

    function getLock(address _user, address _lockManager) external view returns (uint256 _amount, uint256 _allowance);
    function unlockedBalanceOf(address _user) external view returns (uint256);
    function lockedBalanceOf(address _user) external view returns (uint256);
    function getBalancesOf(address _user) external view returns (uint256 staked, uint256 locked);
    function canUnlock(address _sender, address _user, address _lockManager, uint256 _amount) external view returns (bool);
}

pragma solidity ^0.5.17;


interface ILockManager {
    /**
     * @notice Check if `_user`'s lock by `_lockManager` can be unlocked
     * @param _user Owner of lock
     * @param _amount Amount of locked tokens to unlock
     * @return Whether given user's lock can be unlocked
     */
    function canUnlock(address _user, uint256 _amount) external view returns (bool);
}

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/Uint256Helpers.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity ^0.5.8;


library Uint256Helpers {
    uint256 private constant MAX_UINT8 = uint8(-1);
    uint256 private constant MAX_UINT64 = uint64(-1);

    string private constant ERROR_UINT8_NUMBER_TOO_BIG = "UINT8_NUMBER_TOO_BIG";
    string private constant ERROR_UINT64_NUMBER_TOO_BIG = "UINT64_NUMBER_TOO_BIG";

    function toUint8(uint256 a) internal pure returns (uint8) {
        require(a <= MAX_UINT8, ERROR_UINT8_NUMBER_TOO_BIG);
        return uint8(a);
    }

    function toUint64(uint256 a) internal pure returns (uint64) {
        require(a <= MAX_UINT64, ERROR_UINT64_NUMBER_TOO_BIG);
        return uint64(a);
    }
}

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/TimeHelpers.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity ^0.5.8;

import "./Uint256Helpers.sol";


contract TimeHelpers {
    using Uint256Helpers for uint256;

    /**
    * @dev Returns the current block number.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
    * @dev Returns the current block number, converted to uint64.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber64() internal view returns (uint64) {
        return getBlockNumber().toUint64();
    }

    /**
    * @dev Returns the current timestamp.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp() internal view returns (uint256) {
        return block.timestamp; // solium-disable-line security/no-block-members
    }

    /**
    * @dev Returns the current timestamp, converted to uint64.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp64() internal view returns (uint64) {
        return getTimestamp().toUint64();
    }
}

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/lib/math/SafeMath.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity >=0.4.24 <0.6.0;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    string private constant ERROR_ADD_OVERFLOW = "MATH_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b, ERROR_MUL_OVERFLOW);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/SafeERC20.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity ^0.5.8;

import "../../standards/IERC20.sol";


library SafeERC20 {
    // Before 0.5, solidity has a mismatch between `address.transfer()` and `token.transfer()`:
    // https://github.com/ethereum/solidity/issues/3544
    bytes4 private constant TRANSFER_SELECTOR = 0xa9059cbb;

    /**
    * @dev Same as a standards-compliant ERC20.transfer() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransfer(IERC20 _token, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferCallData = abi.encodeWithSelector(
            TRANSFER_SELECTOR,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), transferCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.transferFrom() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransferFrom(IERC20 _token, address _from, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferFromCallData = abi.encodeWithSelector(
            _token.transferFrom.selector,
            _from,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), transferFromCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.approve() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeApprove(IERC20 _token, address _spender, uint256 _amount) internal returns (bool) {
        bytes memory approveCallData = abi.encodeWithSelector(
            _token.approve.selector,
            _spender,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), approveCallData);
    }

    function invokeAndCheckSuccess(address _addr, bytes memory _calldata) private returns (bool) {
        bool ret;
        assembly {
            let ptr := mload(0x40)    // free memory pointer

            let success := call(
                gas,                  // forward all gas
                _addr,                // address
                0,                    // no value
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
            // Check number of bytes returned from last function call
                switch returndatasize

                // No bytes returned: assume success
                case 0 {
                    ret := 1
                }

                // 32 bytes returned: check if non-zero
                case 0x20 {
                // Only return success if returned data was true
                // Already have output in ptr
                    ret := eq(mload(ptr), 1)
                }

                // Not sure what was returned: don't mark as success
                default { }
            }
        }
        return ret;
    }
}

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/IsContract.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity ^0.5.8;


contract IsContract {
    /*
    * NOTE: this should NEVER be used for authentication
    * (see pitfalls: https://github.com/fergarrui/ethereum-security/tree/master/contracts/extcodesize).
    *
    * This is only intended to be used as a sanity check that an address is actually a contract,
    * RATHER THAN an address not being a contract.
    */
    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly { size := extcodesize(_target) }
        return size > 0;
    }
}

pragma solidity ^0.5.17;


/**
* @title Checkpointing - Library to handle a historic set of numeric values
*/
library Checkpointing {
    uint256 private constant MAX_UINT192 = uint256(uint192(-1));

    string private constant ERROR_VALUE_TOO_BIG = "CHECKPOINT_VALUE_TOO_BIG";
    string private constant ERROR_CANNOT_ADD_PAST_VALUE = "CHECKPOINT_CANNOT_ADD_PAST_VALUE";

    /**
     * @dev To specify a value at a given point in time, we need to store two values:
     *      - `time`: unit-time value to denote the first time when a value was registered
     *      - `value`: a positive numeric value to registered at a given point in time
     *
     *      Note that `time` does not need to refer necessarily to a timestamp value, any time unit could be used
     *      for it like block numbers, terms, etc.
     */
    struct Checkpoint {
        uint64 time;
        uint192 value;
    }

    /**
     * @dev A history simply denotes a list of checkpoints
     */
    struct History {
        Checkpoint[] history;
    }

    /**
     * @dev Add a new value to a history for a given point in time. This function does not allow to add values previous
     *      to the latest registered value, if the value willing to add corresponds to the latest registered value, it
     *      will be updated.
     * @param self Checkpoints history to be altered
     * @param _time Point in time to register the given value
     * @param _value Numeric value to be registered at the given point in time
     */
    function add(History storage self, uint64 _time, uint256 _value) internal {
        require(_value <= MAX_UINT192, ERROR_VALUE_TOO_BIG);
        _add192(self, _time, uint192(_value));
    }

    /**
     * TODO
     */
    function lastUpdate(History storage self) internal view returns (uint256) {
        uint256 length = self.history.length;

        if (length > 0) {
            return uint256(self.history[length - 1].time);
        }

        return 0;
    }

    /**
     * @dev Fetch the latest registered value of history, it will return zero if there was no value registered
     * @param self Checkpoints history to be queried
     */
    function getLast(History storage self) internal view returns (uint256) {
        uint256 length = self.history.length;
        if (length > 0) {
            return uint256(self.history[length - 1].value);
        }

        return 0;
    }

    /**
     * @dev Fetch the most recent registered past value of a history based on a given point in time that is not known
     *      how recent it is beforehand. It will return zero if there is no registered value or if given time is
     *      previous to the first registered value.
     *      It uses a binary search.
     * @param self Checkpoints history to be queried
     * @param _time Point in time to query the most recent registered past value of
     */
    function get(History storage self, uint64 _time) internal view returns (uint256) {
        return _binarySearch(self, _time);
    }

    /**
     * @dev Private function to add a new value to a history for a given point in time. This function does not allow to
     *      add values previous to the latest registered value, if the value willing to add corresponds to the latest
     *      registered value, it will be updated.
     * @param self Checkpoints history to be altered
     * @param _time Point in time to register the given value
     * @param _value Numeric value to be registered at the given point in time
     */
    function _add192(History storage self, uint64 _time, uint192 _value) private {
        uint256 length = self.history.length;
        if (length == 0) {
            // If there was no value registered, we can insert it to the history directly.
            self.history.push(Checkpoint(_time, _value));
        } else {
            Checkpoint storage currentCheckpoint = self.history[length - 1];
            uint256 currentCheckpointTime = uint256(currentCheckpoint.time);

            if (_time > currentCheckpointTime) {
                // If the given point in time is after the latest registered value,
                // we can insert it to the history directly.
                self.history.push(Checkpoint(_time, _value));
            } else if (_time == currentCheckpointTime) {
                currentCheckpoint.value = _value;
            } else { // ensure list ordering
                // The given point cannot be before latest value, as past data cannot be changed
                revert(ERROR_CANNOT_ADD_PAST_VALUE);
            }
        }
    }

    /**
     * @dev Private function to execute a binary search to find the most recent registered past value of a history based on
     *      a given point in time. It will return zero if there is no registered value or if given time is previous to
     *      the first registered value. Note that this function will be more suitable when don't know how recent the
     *      time used to index may be.
     * @param self Checkpoints history to be queried
     * @param _time Point in time to query the most recent registered past value of
     */
    function _binarySearch(History storage self, uint64 _time) private view returns (uint256) {
        // If there was no value registered for the given history return simply zero
        uint256 length = self.history.length;
        if (length == 0) {
            return 0;
        }

        // If the requested time is equal to or after the time of the latest registered value, return latest value
        uint256 lastIndex = length - 1;
        Checkpoint storage lastCheckpoint = self.history[lastIndex];
        if (_time >= lastCheckpoint.time) {
            return uint256(lastCheckpoint.value);
        }

        // If the requested time is previous to the first registered value, return zero to denote missing checkpoint
        if (length == 1 || _time < self.history[0].time) {
            return 0;
        }

        // Execute a binary search between the checkpointed times of the history
        uint256 low = 0;
        uint256 high = lastIndex - 1;

        while (high > low) {
            // No need for SafeMath: for this to overflow array size should be ~2^255
            uint256 mid = (high + low + 1) / 2;
            Checkpoint storage checkpoint = self.history[mid];
            uint64 midTime = checkpoint.time;

            if (_time > midTime) {
                low = mid;
            } else if (_time < midTime) {
                // No need for SafeMath: high > low >= 0 => high >= 1 => mid >= 1
                high = mid - 1;
            } else {
                return uint256(checkpoint.value);
            }
        }

        return uint256(self.history[low].value);
    }
}

pragma solidity 0.5.17;

import "./lib/Checkpointing.sol";
import "./lib/os/IsContract.sol";
import "./lib/os/SafeMath.sol";
import "./lib/os/SafeERC20.sol";
import "./lib/os/TimeHelpers.sol";

import "./locking/ILockable.sol";
import "./locking/ILockManager.sol";

import "./standards/IERC900.sol";
import "./standards/IERC900History.sol";
import "./standards/IApproveAndCallFallBack.sol";


contract Staking is IERC900, IERC900History, ILockable, IApproveAndCallFallBack, IsContract, TimeHelpers {
    using Checkpointing for Checkpointing.History;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 private constant MAX_UINT64 = uint256(uint64(-1));

    string private constant ERROR_TOKEN_NOT_CONTRACT = "STAKING_TOKEN_NOT_CONTRACT";
    string private constant ERROR_AMOUNT_ZERO = "STAKING_AMOUNT_ZERO";
    string private constant ERROR_TOKEN_TRANSFER = "STAKING_TOKEN_TRANSFER_FAIL";
    string private constant ERROR_TOKEN_DEPOSIT = "STAKING_TOKEN_DEPOSIT_FAIL";
    string private constant ERROR_WRONG_TOKEN = "STAKING_WRONG_TOKEN";
    string private constant ERROR_NOT_ENOUGH_BALANCE = "STAKING_NOT_ENOUGH_BALANCE";
    string private constant ERROR_NOT_ENOUGH_ALLOWANCE = "STAKING_NOT_ENOUGH_ALLOWANCE";
    string private constant ERROR_ALLOWANCE_ZERO = "STAKING_ALLOWANCE_ZERO";
    string private constant ERROR_LOCK_ALREADY_EXISTS = "STAKING_LOCK_ALREADY_EXISTS";
    string private constant ERROR_LOCK_DOES_NOT_EXIST = "STAKING_LOCK_DOES_NOT_EXIST";
    string private constant ERROR_NOT_ENOUGH_LOCK = "STAKING_NOT_ENOUGH_LOCK";
    string private constant ERROR_CANNOT_UNLOCK = "STAKING_CANNOT_UNLOCK";
    string private constant ERROR_CANNOT_CHANGE_ALLOWANCE = "STAKING_CANNOT_CHANGE_ALLOWANCE";
    string private constant ERROR_BLOCKNUMBER_TOO_BIG = "STAKING_BLOCKNUMBER_TOO_BIG";

    event StakeTransferred(address indexed from, address indexed to, uint256 amount);

    struct Lock {
        uint256 amount;
        uint256 allowance; // A lock is considered active when its allowance is greater than zero, and the allowance is always greater than or equal to amount
    }

    struct Account {
        mapping (address => Lock) locks; // Mapping of lock manager => lock info
        uint256 totalLocked;
        Checkpointing.History stakedHistory;
    }

    IERC20 public token;
    mapping (address => Account) internal accounts;
    Checkpointing.History internal totalStakedHistory;

    /**
     * @notice Initialize Staking app with token `_token`
     * @param _token ERC20 token used for staking
     */
    constructor(IERC20 _token) public {
        require(isContract(address(_token)), ERROR_TOKEN_NOT_CONTRACT);
        token = _token;
    }

    /**
     * @notice Stake `@tokenAmount(self.token(): address, _amount)`
     * @dev Callable only by a user
     * @param _amount Amount of tokens to be staked
     * @param _data Optional data emitted with the Staked event, to add signalling information in more complex staking applications
     */
    function stake(uint256 _amount, bytes calldata _data) external {
        _stakeFor(msg.sender, msg.sender, _amount, _data);
    }

    /**
     * @notice Stake `@tokenAmount(self.token(): address, _amount)` for `_user`
     * @dev Callable only by a user
     * @param _user Address to stake tokens to
     * @param _amount Amount of tokens to be staked
     * @param _data Optional data emitted with the Staked event, to add signalling information in more complex staking applications
     */
    function stakeFor(address _user, uint256 _amount, bytes calldata _data) external {
        _stakeFor(msg.sender, _user, _amount, _data);
    }

    /**
     * @notice Unstake `@tokenAmount(self.token(): address, _amount)`
     * @dev Callable only by a user
     * @param _amount Amount of tokens to be unstaked
     * @param _data Optional data emitted with the Unstaked event, to add signalling information in more complex staking applications
     */
    function unstake(uint256 _amount, bytes calldata _data) external {
        // _unstake() expects the caller to do this check
        require(_amount > 0, ERROR_AMOUNT_ZERO);

        _unstake(msg.sender, _amount, _data);
    }

    /**
     * @notice Allow `_lockManager` to lock up to `@tokenAmount(self.token(): address, _allowance)` of your staked balance
     * @dev Callable only by a user.
     *      This creates a new lock, so this manager cannot have an existing lock in place for the caller.
     * @param _lockManager Lock manager
     * @param _allowance Amount of tokens the manager will be allowed to lock
     * @param _data Optional, arbitrary data to be submitted to the manager
     */
    function allowManager(address _lockManager, uint256 _allowance, bytes calldata _data) external {
        _allowManager(_lockManager, _allowance, _data);
    }

    /**
     * @notice Increase allowance of lock manager `_lockManager` by `@tokenAmount(self.token(): address, _allowance)`
     * @dev Callable only by a user
     * @param _lockManager Lock manager
     * @param _allowance Amount to increase allowance by
     */
    function increaseLockAllowance(address _lockManager, uint256 _allowance) external {
        Lock storage lock_ = accounts[msg.sender].locks[_lockManager];
        require(lock_.allowance > 0, ERROR_LOCK_DOES_NOT_EXIST);

        _increaseLockAllowance(_lockManager, lock_, _allowance);
    }

    /**
     * @notice Decrease allowance of lock manager `_lockManager` by `@tokenAmount(self.token(): address, _allowance)`
     * @dev Callable only by the user or lock manager.
     *      Cannot completely remove the allowance to the lock manager (and deactivate the lock).
     * @param _user Owner of the locked tokens
     * @param _lockManager Lock manager
     * @param _allowance Amount to decrease allowance by
     */
    function decreaseLockAllowance(address _user, address _lockManager, uint256 _allowance) external {
        require(msg.sender == _user || msg.sender == _lockManager, ERROR_CANNOT_CHANGE_ALLOWANCE);
        require(_allowance > 0, ERROR_AMOUNT_ZERO);

        Lock storage lock_ = accounts[_user].locks[_lockManager];
        uint256 newAllowance = lock_.allowance.sub(_allowance);
        require(newAllowance >= lock_.amount, ERROR_NOT_ENOUGH_ALLOWANCE);
        // unlockAndRemoveManager() must be used for this:
        require(newAllowance > 0, ERROR_ALLOWANCE_ZERO);

        lock_.allowance = newAllowance;

        emit LockAllowanceChanged(_user, _lockManager, newAllowance);
    }

    /**
     * @notice Lock `@tokenAmount(self.token(): address, _amount)` to lock manager `msg.sender`
     * @dev Callable only by an allowed lock manager
     * @param _user Owner of the locked tokens
     * @param _amount Amount of tokens to lock
     */
    function lock(address _user, uint256 _amount) external {
        require(_amount > 0, ERROR_AMOUNT_ZERO);

        // check enough unlocked tokens are available
        require(_amount <= _unlockedBalanceOf(_user), ERROR_NOT_ENOUGH_BALANCE);

        Account storage account = accounts[_user];
        Lock storage lock_ = account.locks[msg.sender];

        uint256 newAmount = lock_.amount.add(_amount);
        // check allowance is enough, it also means that lock exists, as newAmount is greater than zero
        require(newAmount <= lock_.allowance, ERROR_NOT_ENOUGH_ALLOWANCE);

        lock_.amount = newAmount;

        // update total
        account.totalLocked = account.totalLocked.add(_amount);

        emit LockAmountChanged(_user, msg.sender, newAmount);
    }

    /**
     * @notice Unlock `@tokenAmount(self.token(): address, _amount)` from lock manager `_lockManager`
     * @dev Callable only by the user or lock manager. If called by the user, checks with the lock manager whether the request should be allowed.
     * @param _user Owner of the locked tokens
     * @param _lockManager Lock manager
     * @param _amount Amount of tokens to unlock
     */
    function unlock(address _user, address _lockManager, uint256 _amount) external {
        // _unlockUnsafe() expects the caller to do this check
        require(_amount > 0, ERROR_AMOUNT_ZERO);

        require(_canUnlockUnsafe(msg.sender, _user, _lockManager, _amount), ERROR_CANNOT_UNLOCK);

        _unlockUnsafe(_user, _lockManager, _amount);
    }

    /**
     * @notice Unlock all tokens from lock manager `_lockManager` and remove them as a manager
     * @dev Callable only by the user or lock manager. If called by the user, checks with the lock manager whether the request should be allowed.
     * @param _user Owner of the locked tokens
     * @param _lockManager Lock manager
     */
    function unlockAndRemoveManager(address _user, address _lockManager) external {
        require(_canUnlockUnsafe(msg.sender, _user, _lockManager, 0), ERROR_CANNOT_UNLOCK);

        Account storage account = accounts[_user];
        Lock storage lock_ = account.locks[_lockManager];

        uint256 amount = lock_.amount;
        // update total
        account.totalLocked = account.totalLocked.sub(amount);

        emit LockAmountChanged(_user, _lockManager, 0);
        emit LockManagerRemoved(_user, _lockManager);

        delete account.locks[_lockManager];
    }

    /**
     * @notice Slash `@tokenAmount(self.token(): address, _amount)` from `_from`'s locked balance to `_to`'s staked balance
     * @dev Callable only by a lock manager
     * @param _from Owner of the locked tokens
     * @param _to Recipient
     * @param _amount Amount of tokens to be transferred via slashing
     */
    function slash(address _from, address _to, uint256 _amount) external {
        _unlockUnsafe(_from, msg.sender, _amount);
        _transfer(_from, _to, _amount);
    }

    /**
     * @notice Slash `@tokenAmount(self.token(): address, _amount)` from `_from`'s locked balance  directly to `_to`'s balance
     * @dev Callable only by a lock manager
     * @param _from Owner of the locked tokens
     * @param _to Recipient
     * @param _amount Amount of tokens to be transferred via slashing
     */
    function slashAndUnstake(address _from, address _to, uint256 _amount) external {
        _unlockUnsafe(_from, msg.sender, _amount);
        _transferAndUnstake(_from, _to, _amount);
    }

    /**
     * @notice Slash `@tokenAmount(self.token(): address, _slashAmount)` from `_from`'s locked balance to `_to`'s staked balance, and leave an additional `@tokenAmount(self.token(): address, _unlockAmount)` unlocked for `_from`
     * @dev Callable only by a lock manager
     * @param _from Owner of the locked tokens
     * @param _to Recipient
     * @param _unlockAmount Amount of tokens to be left unlocked
     * @param _slashAmount Amount of tokens to be transferred via slashing
     */
    function slashAndUnlock(
        address _from,
        address _to,
        uint256 _unlockAmount,
        uint256 _slashAmount
    )
        external
    {
        _unlockUnsafe(_from, msg.sender, _unlockAmount.add(_slashAmount));
        _transfer(_from, _to, _slashAmount);
    }

    /**
     * @notice Transfer `@tokenAmount(self.token(): address, _amount)` to `_to`’s staked balance
     * @dev Callable only by a user
     * @param _to Recipient
     * @param _amount Amount of tokens to be transferred
     */
    function transfer(address _to, uint256 _amount) external {
        _transfer(msg.sender, _to, _amount);
    }

    /**
     * @notice Transfer `@tokenAmount(self.token(): address, _amount)` directly to `_to`’s balance
     * @dev Callable only by a user
     * @param _to Recipient
     * @param _amount Amount of tokens to be transferred
     */
    function transferAndUnstake(address _to, uint256 _amount) external {
        _transferAndUnstake(msg.sender, _to, _amount);
    }

    /**
    /**
     * @dev ApproveAndCallFallBack compliance.
     *      Stakes the approved tokens for the user, allowing users to stake their tokens in a single transaction.
     *      Callable only by the staking token.
     * @param _from Account approving tokens
     * @param _amount Amount of tokens being approved
     * @param _token Token being approved, should be the caller
     * @param _data Optional data emitted with the Staked event, to add signalling information in more complex staking applications
     */
    function receiveApproval(address _from, uint256 _amount, address _token, bytes calldata _data) external {
        require(_token == msg.sender && _token == address(token), ERROR_WRONG_TOKEN);

        _stakeFor(_from, _from, _amount, _data);
    }

    /**
     * @dev Tell whether the history methods are supported
     * @return Always true
     */
    function supportsHistory() external pure returns (bool) {
        return true;
    }

    /**
     * @dev Tell the last time `_user` modified their staked balance
     * @param _user Address
     * @return Last block number the account's staked balance was modified. 0 if it has never been modified.
     */
    function lastStakedFor(address _user) external view returns (uint256) {
        return accounts[_user].stakedHistory.lastUpdate();
    }

    /**
     * @dev Tell the current locked balance for `_user`
     * @param _user Address
     * @return Amount of locked tokens owned by the requested account across all locks
     */
    function lockedBalanceOf(address _user) external view returns (uint256) {
        return _lockedBalanceOf(_user);
    }

    /**
     * @dev Tell details of `_user`'s lock managed by `_lockManager`
     * @param _user Address
     * @param _lockManager Lock manager
     * @return Amount of locked tokens
     * @return Amount of tokens that lock manager is allowed to lock
     */
    function getLock(address _user, address _lockManager)
        external
        view
        returns (
            uint256 amount,
            uint256 allowance
        )
    {
        Lock storage lock_ = accounts[_user].locks[_lockManager];
        amount = lock_.amount;
        allowance = lock_.allowance;
    }

    /**
     * @dev Tell the current staked and locked balances for `_user`
     * @param _user Address
     * @return Staked balance
     * @return Locked balance
     */
    function getBalancesOf(address _user) external view returns (uint256 staked, uint256 locked) {
        staked = _totalStakedFor(_user);
        locked = _lockedBalanceOf(_user);
    }

    /**
     * @dev Tell the current staked balance for `_user`
     * @param _user Address
     * @return Staked balance
     */
    function totalStakedFor(address _user) external view returns (uint256) {
        return _totalStakedFor(_user);
    }

    /**
     * @dev Tell the total staked balance from all users
     * @return The total amount of staked tokens from all users
     */
    function totalStaked() external view returns (uint256) {
        return _totalStaked();
    }

    /**
     * @dev Tell the staked balance for `_user` at block number `_blockNumber`
     * @param _user Address
     * @param _blockNumber Block height
     * @return Staked balance at the given block number
     */
    function totalStakedForAt(address _user, uint256 _blockNumber) external view returns (uint256) {
        require(_blockNumber <= MAX_UINT64, ERROR_BLOCKNUMBER_TOO_BIG);

        return accounts[_user].stakedHistory.get(uint64(_blockNumber));
    }

    /**
     * @dev Tell the total staked balance from all users at block number `_blockNumber`
     * @param _blockNumber Block height
     * @return The total amount of staked tokens from all users at the given block number
     */
    function totalStakedAt(uint256 _blockNumber) external view returns (uint256) {
        require(_blockNumber <= MAX_UINT64, ERROR_BLOCKNUMBER_TOO_BIG);

        return totalStakedHistory.get(uint64(_blockNumber));
    }

    /**
     * @dev Tell the portion of `user`'s staked balance that can be immediately withdrawn
     * @param _user Address
     * @return Amount of tokens available to be withdrawn
     */
    function unlockedBalanceOf(address _user) external view returns (uint256) {
        return _unlockedBalanceOf(_user);
    }

    /**
     * @dev Check if `_sender` can unlock `@tokenAmount(self.token(): address, _amount)` from `_user`'s lock managed by `_lockManager`
     * @param _sender Address that would try to unlock tokens
     * @param _user Owner of lock
     * @param _lockManager Lock manager
     * @param _amount Amount of locked tokens to unlock. If zero, the full locked amount.
     * @return Whether sender is allowed to unlock tokens from the given lock
     */
    function canUnlock(address _sender, address _user, address _lockManager, uint256 _amount) external view returns (bool) {
        return _canUnlockUnsafe(_sender, _user, _lockManager, _amount);
    }

    function _stakeFor(address _from, address _user, uint256 _amount, bytes memory _data) internal {
        // staking 0 tokens is invalid
        require(_amount > 0, ERROR_AMOUNT_ZERO);

        // checkpoint updated staking balance
        uint256 newStake = _modifyStakeBalance(_user, _amount, true);

        // checkpoint total supply
        _modifyTotalStaked(_amount, true);

        // pull tokens into Staking contract
        require(token.safeTransferFrom(_from, address(this), _amount), ERROR_TOKEN_DEPOSIT);

        emit Staked(_user, _amount, newStake, _data);
    }

    /**
     * @dev Assumes the caller has already checked _amount > 0
     */
    function _unstake(address _from, uint256 _amount, bytes memory _data) internal {
        // checkpoint updated staking balance
        uint256 newStake = _modifyStakeBalance(_from, _amount, false);

        // checkpoint total supply
        _modifyTotalStaked(_amount, false);

        // transfer tokens
        require(token.safeTransfer(_from, _amount), ERROR_TOKEN_TRANSFER);

        emit Unstaked(_from, _amount, newStake, _data);
    }

    function _modifyStakeBalance(address _user, uint256 _by, bool _increase) internal returns (uint256) {
        uint256 currentStake = _totalStakedFor(_user);

        uint256 newStake;
        if (_increase) {
            newStake = currentStake.add(_by);
        } else {
            require(_by <= _unlockedBalanceOf(_user), ERROR_NOT_ENOUGH_BALANCE);
            newStake = currentStake.sub(_by);
        }

        // add new value to account history
        accounts[_user].stakedHistory.add(getBlockNumber64(), newStake);

        return newStake;
    }

    function _modifyTotalStaked(uint256 _by, bool _increase) internal {
        uint256 currentStake = _totalStaked();

        uint256 newStake;
        if (_increase) {
            newStake = currentStake.add(_by);
        } else {
            newStake = currentStake.sub(_by);
        }

        // add new value to total history
        totalStakedHistory.add(getBlockNumber64(), newStake);
    }

    function _allowManager(address _lockManager, uint256 _allowance, bytes memory _data) internal {
        Lock storage lock_ = accounts[msg.sender].locks[_lockManager];
        // ensure lock doesn't exist yet
        require(lock_.allowance == 0, ERROR_LOCK_ALREADY_EXISTS);

        emit NewLockManager(msg.sender, _lockManager, _data);

        _increaseLockAllowance(_lockManager, lock_, _allowance);
    }

    function _increaseLockAllowance(address _lockManager, Lock storage _lock, uint256 _allowance) internal {
        require(_allowance > 0, ERROR_AMOUNT_ZERO);

        uint256 newAllowance = _lock.allowance.add(_allowance);
        _lock.allowance = newAllowance;

        emit LockAllowanceChanged(msg.sender, _lockManager, newAllowance);
    }

    /**
     * @dev Assumes `canUnlock` passes, i.e., either sender is the lock manager or it’s the owner,
     *      and the lock manager allows to unlock.
     */
    function _unlockUnsafe(address _user, address _lockManager, uint256 _amount) internal {
        Account storage account = accounts[_user];
        Lock storage lock_ = account.locks[_lockManager];

        uint256 lockAmount = lock_.amount;
        require(lockAmount >= _amount, ERROR_NOT_ENOUGH_LOCK);

        // update lock amount
        // No need for SafeMath: checked just above
        uint256 newAmount = lockAmount - _amount;
        lock_.amount = newAmount;

        // update total
        account.totalLocked = account.totalLocked.sub(_amount);

        emit LockAmountChanged(_user, _lockManager, newAmount);
    }

    function _transfer(address _from, address _to, uint256 _amount) internal {
        // transferring 0 staked tokens is invalid
        require(_amount > 0, ERROR_AMOUNT_ZERO);

        // update stakes
        _modifyStakeBalance(_from, _amount, false);
        _modifyStakeBalance(_to, _amount, true);

        emit StakeTransferred(_from, _to, _amount);
    }

    /**
     * @dev This is similar to a `_transfer()` followed by a `_unstake()`, but optimized to avoid spurious SSTOREs on modifying _to's checkpointed balance
     */
    function _transferAndUnstake(address _from, address _to, uint256 _amount) internal {
        // transferring 0 staked tokens is invalid
        require(_amount > 0, ERROR_AMOUNT_ZERO);

        // update stake
        uint256 newStake = _modifyStakeBalance(_from, _amount, false);

        // checkpoint total supply
        _modifyTotalStaked(_amount, false);

        emit Unstaked(_from, _amount, newStake, new bytes(0));

        // transfer tokens
        require(token.safeTransfer(_to, _amount), ERROR_TOKEN_TRANSFER);
    }

    function _totalStakedFor(address _user) internal view returns (uint256) {
        // we assume it's not possible to stake in the future
        return accounts[_user].stakedHistory.getLast();
    }

    function _totalStaked() internal view returns (uint256) {
        // we assume it's not possible to stake in the future
        return totalStakedHistory.getLast();
    }

    function _unlockedBalanceOf(address _user) internal view returns (uint256) {
        return _totalStakedFor(_user).sub(_lockedBalanceOf(_user));
    }

    function _lockedBalanceOf(address _user) internal view returns (uint256) {
        return accounts[_user].totalLocked;
    }

    /**
     * @dev If calling this from a state modifying function trying to unlock tokens, make sure the first parameter is `msg.sender`.
     * @param _sender Address that would try to unlock tokens
     * @param _user Owner of lock
     * @param _lockManager Lock manager
     * @param _amount Amount of locked tokens to unlock. If zero, the full locked amount.
     * @return Whether sender is allowed to unlock tokens from the given lock
     */
    function _canUnlockUnsafe(address _sender, address _user, address _lockManager, uint256 _amount) internal view returns (bool) {
        Lock storage lock_ = accounts[_user].locks[_lockManager];
        require(lock_.allowance > 0, ERROR_LOCK_DOES_NOT_EXIST);
        require(lock_.amount >= _amount, ERROR_NOT_ENOUGH_LOCK);

        uint256 amount = _amount == 0 ? lock_.amount : _amount;

        // If the sender is the lock manager, unlocking is allowed
        if (_sender == _lockManager) {
            return true;
        }

        // If the sender is neither the lock manager nor the owner, unlocking is not allowed
        if (_sender != _user) {
            return false;
        }

        // The sender must be the user
        // Allow unlocking if the amount of locked tokens for the user has already been decreased to 0
        if (amount == 0) {
            return true;
        }

        // Otherwise, check whether the lock manager allows unlocking
        return ILockManager(_lockManager).canUnlock(_user, amount);
    }
}