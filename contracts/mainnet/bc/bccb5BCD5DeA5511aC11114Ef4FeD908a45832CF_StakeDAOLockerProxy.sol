// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "./interfaces/IStakeDAOGauge.sol";
import "./interfaces/IStakeDAOLockerProxy.sol";
import "./interfaces/IStakeDAOMultiMerkleStash.sol";
import "../../interfaces/ISnapshotDelegateRegistry.sol";

/// @title StakeDaoLockerProxy
/// @notice This contract is the main entry for stake tokens in StakeDAO.
contract StakeDAOLockerProxy is OwnableUpgradeable, IStakeDAOLockerProxy {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @notice Emitted when the operator for gauge is updated.
  /// @param _gauge The address of gauge updated.
  /// @param _operator The address of operator updated.
  event UpdateOperator(address _gauge, address _operator);

  /// @notice Emitted when the status of executor is updated.
  /// @param _executor The address of executor updated.
  /// @param _status The status of executor updated.
  event UpdateExecutor(address _executor, bool _status);

  /// @notice Emitted when claimer for sdCRV bribe rewards is update.
  /// @param _claimer The address of claimer updated.
  event UpdateClaimer(address _claimer);

  /// @dev The address of StakeDAO MultiMerkleStash contract.
  address private constant MULTI_MERKLE_STASH = 0x03E34b085C52985F6a5D27243F20C84bDdc01Db4;

  /// @notice Mapping from gauge address to operator address.
  mapping(address => address) public operators;

  /// @notice Whether the address is an executor.
  mapping(address => bool) public executors;

  /// @notice The address of sdCRV bribe rewards claimer.
  address public claimer;

  /// @notice The sdCRV bribe claim status for token => merkleRoot mapping.
  mapping(address => mapping(address => bool)) public claimed;

  modifier onlyOperator(address _gauge) {
    require(operators[_gauge] == msg.sender, "not operator");
    _;
  }

  modifier onlyExecutor() {
    require(executors[msg.sender], "not executor");
    _;
  }

  /********************************** Constructor **********************************/

  function initialize() external initializer {
    OwnableUpgradeable.__Ownable_init();
  }

  /********************************** Mutated Functions **********************************/

  /// @inheritdoc IStakeDAOLockerProxy
  function deposit(address _gauge, address _token) external override onlyOperator(_gauge) returns (uint256 _amount) {
    _amount = IERC20Upgradeable(_token).balanceOf(address(this));
    if (_amount > 0) {
      IERC20Upgradeable(_token).safeApprove(_gauge, 0);
      IERC20Upgradeable(_token).safeApprove(_gauge, _amount);
      // deposit without claiming rewards
      IStakeDAOGauge(_gauge).deposit(_amount);
    }
  }

  /// @inheritdoc IStakeDAOLockerProxy
  function withdraw(
    address _gauge,
    address _token,
    uint256 _amount,
    address _recipient
  ) external override onlyOperator(_gauge) {
    uint256 _balance = IERC20Upgradeable(_token).balanceOf(address(this));
    if (_balance < _amount) {
      // withdraw without claiming rewards
      IStakeDAOGauge(_gauge).withdraw(_amount - _balance);
    }
    IERC20Upgradeable(_token).safeTransfer(_recipient, _amount);
  }

  /// @inheritdoc IStakeDAOLockerProxy
  function claimRewards(address _gauge, address[] calldata _tokens)
    external
    override
    onlyOperator(_gauge)
    returns (uint256[] memory _amounts)
  {
    uint256 _length = _tokens.length;
    _amounts = new uint256[](_length);
    // record balances before to make sure only claimed delta tokens will be transfered.
    for (uint256 i = 0; i < _length; i++) {
      _amounts[i] = IERC20Upgradeable(_tokens[i]).balanceOf(address(this));
    }
    // This will claim all rewards including SDT.
    IStakeDAOGauge(_gauge).claim_rewards();
    for (uint256 i = 0; i < _length; i++) {
      _amounts[i] = IERC20Upgradeable(_tokens[i]).balanceOf(address(this)) - _amounts[i];
      if (_amounts[i] > 0) {
        IERC20Upgradeable(_tokens[i]).safeTransfer(msg.sender, _amounts[i]);
      }
    }
  }

  /// @inheritdoc IStakeDAOLockerProxy
  function claimBribeRewards(IStakeDAOMultiMerkleStash.claimParam[] memory _claims, address _recipient)
    external
    override
  {
    require(msg.sender == claimer, "only bribe claimer");
    uint256 _length = _claims.length;
    // 1. claim bribe rewards from StakeDAOMultiMerkleStash
    for (uint256 i = 0; i < _length; i++) {
      // in case someone has claimed the reward for this contract, we can still call this function to process reward.
      if (!IStakeDAOMultiMerkleStash(MULTI_MERKLE_STASH).isClaimed(_claims[i].token, _claims[i].index)) {
        IStakeDAOMultiMerkleStash(MULTI_MERKLE_STASH).claim(
          _claims[i].token,
          _claims[i].index,
          address(this),
          _claims[i].amount,
          _claims[i].merkleProof
        );
      }
    }

    // 2. transfer bribe rewards to _recipient
    for (uint256 i = 0; i < _length; i++) {
      address _token = _claims[i].token;
      address _root = IStakeDAOMultiMerkleStash(MULTI_MERKLE_STASH).merkleRoot(_token);
      require(!claimed[_token][_root], "bribe rewards claimed");

      IERC20Upgradeable(_token).safeTransfer(_recipient, _claims[i].amount);
      claimed[_token][_root] = true;
    }
  }

  /// @notice External function to execute anycall.
  /// @param _to The address of target contract to call.
  /// @param _value The value passed to the target contract.
  /// @param _data The calldata pseed to the target contract.
  function execute(
    address _to,
    uint256 _value,
    bytes calldata _data
  ) external onlyExecutor returns (bool, bytes memory) {
    // solhint-disable avoid-low-level-calls
    (bool success, bytes memory result) = _to.call{ value: _value }(_data);
    return (success, result);
  }

  /********************************** Restricted Functions **********************************/

  /// @notice Update the operator for StakeDAO gauge.
  /// @param _gauge The address of gauge to update.
  /// @param _operator The address of operator to update.
  function updateOperator(address _gauge, address _operator) external onlyOwner {
    operators[_gauge] = _operator;

    emit UpdateOperator(_gauge, _operator);
  }

  /// @notice Update the executor.
  /// @param _executor The address of executor to update.
  /// @param _status The status of executor to update.
  function updateExecutor(address _executor, bool _status) external onlyOwner {
    executors[_executor] = _status;

    emit UpdateExecutor(_executor, _status);
  }

  /// @notice Update the claimer for StakeDAO sdCRV bribe rewards.
  /// @param _claimer The address of claimer to update.
  function updateClaimer(address _claimer) external onlyOwner {
    claimer = _claimer;

    emit UpdateClaimer(_claimer);
  }

  /// @dev delegate sdCRV voting power.
  /// @param _registry The address of Snapshot Delegate Registry.
  /// @param _id The id for which the delegate should be set.
  /// @param _delegate The address of the delegate.
  function delegate(
    address _registry,
    bytes32 _id,
    address _delegate
  ) external onlyOwner {
    ISnapshotDelegateRegistry(_registry).setDelegate(_id, _delegate);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface ISnapshotDelegateRegistry {
  function setDelegate(bytes32 id, address delegate) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable func-name-mixedcase

interface IStakeDAOGauge {
  function deposit(uint256) external;

  function balanceOf(address) external view returns (uint256);

  function withdraw(uint256) external;

  function claim_rewards() external;

  function reward_tokens(uint256) external view returns (address); //v2

  function rewarded_token() external view returns (address); //v1

  function reward_count() external view returns (uint256);

  function staking_token() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

interface IStakeDAOMultiMerkleStash {
  // solhint-disable-next-line contract-name-camelcase
  struct claimParam {
    address token;
    uint256 index;
    uint256 amount;
    bytes32[] merkleProof;
  }

  function isClaimed(address token, uint256 index) external view returns (bool);

  function merkleRoot(address token) external returns (address);

  function claim(
    address token,
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external;

  function claimMulti(address account, claimParam[] calldata claims) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IStakeDAOMultiMerkleStash.sol";

interface IStakeDAOLockerProxy {
  /// @notice Deposit staked token to StakeDAO gauge.
  /// @dev The caller should make sure the token is already transfered to the contract.
  /// @param _gauge The address of gauge.
  /// @param _token The address token to deposit.
  /// @return _amount The amount of token deposited. This can be used for cross validation.
  function deposit(address _gauge, address _token) external returns (uint256 _amount);

  /// @notice Withdraw staked token from StakeDAO gauge.
  /// @param _gauge The address of gauge.
  /// @param _token The address token to withdraw.
  /// @param _amount The amount of token to withdraw.
  /// @param _recipient The address of recipient who will receive the staked token.
  function withdraw(
    address _gauge,
    address _token,
    uint256 _amount,
    address _recipient
  ) external;

  /// @notice Claim pending rewards from StakeDAO gauge.
  /// @dev Be careful that the StakeDAO gauge supports `claim_rewards_for`. Currently,
  /// it is fine since only owner can call the function through `ClaimRewards` contract.
  /// @param _gauge The address of gauge to claim.
  /// @param _tokens The list of reward tokens to claim.
  /// @return _amounts The list of amount of rewards claim for corresponding tokens.
  function claimRewards(address _gauge, address[] calldata _tokens) external returns (uint256[] memory _amounts);

  /// @notice Claim bribe rewards for sdCRV.
  /// @param _claims The claim parameters passing to StakeDAOMultiMerkleStash contract.
  /// @param _recipient The address of recipient who will receive the bribe rewards.
  function claimBribeRewards(IStakeDAOMultiMerkleStash.claimParam[] memory _claims, address _recipient) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

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
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}