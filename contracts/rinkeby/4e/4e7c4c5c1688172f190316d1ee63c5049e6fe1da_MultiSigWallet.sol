/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// File: contracts/utils/Address.sol


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

// File: contracts/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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

// File: contracts/MultiSigWallet.sol


pragma solidity >=0.8.14;


contract MultiSigWallet is Initializable {
  /*
   *  Events
   */
  event Deposit(address indexed sender, uint256 amount, uint256 balance);
  event SubmitTransaction(
    address indexed owner,
    uint256 indexed txIndex,
    address indexed to,
    bytes data
  );
  event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
  event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
  event Execution(uint256 indexed transactionId);
  event ExecutionFailure(uint256 indexed transactionId);
  event OwnerAddition(address indexed owner, string indexed roundId);
  event OwnerRemoval(address indexed owner, string indexed roundId);
  event RequirementChange(uint256 required);

  /*
   *  Constants
   */
  uint256 public constant MAX_OWNER_COUNT = 50;

  /*
   *  Storage
   */
  address[] public owners;
  mapping(address => bool) public isOwner;
  uint256 public numConfirmationsRequired;

  struct Transaction {
    address to;
    bytes data;
    bool executed;
  }

  /// @notice For each transaction, a mapping of owners approving or not the transaction.
  mapping(uint256 => mapping(address => bool)) public confirmations;

  mapping(uint256 => Transaction) public transactions;

  /// @notice The number of transactions that have been submitted to the contract.
  uint256 public transactionCount;

  /*
   *  Modifiers
   */
  modifier onlyWallet() {
    require(msg.sender == address(this));
    _;
  }

  modifier onlyOwner() {
    require(isOwner[msg.sender], "not owner");
    _;
  }

  modifier ownerDoesNotExist(address owner) {
    require(!isOwner[owner]);
    _;
  }

  modifier ownerExists(address owner) {
    require(isOwner[owner]);
    _;
  }

  modifier txExists(uint256 transactionId) {
    require(transactions[transactionId].to != address(0), "tx does not exist");
    _;
  }

  modifier notExecuted(uint256 _txIndex) {
    require(!transactions[_txIndex].executed, "tx already executed");
    _;
  }

  modifier confirmed(uint256 transactionId, address owner) {
    require(confirmations[transactionId][owner]);
    _;
  }

  modifier notConfirmed(uint256 _txIndex) {
    require(!confirmations[_txIndex][msg.sender], "tx already confirmed");
    _;
  }

  modifier notNull(address _address) {
    require(_address != address(0), "Address must not be null");
    _;
  }

  modifier validRequirement(uint256 ownerCount, uint256 _required) {
    require(
      ownerCount <= MAX_OWNER_COUNT &&
        _required <= ownerCount &&
        _required != 0 &&
        ownerCount != 0
    );
    _;
  }

  /// @dev Contract constructor sets initial owners and required number of isConfirmed.
  constructor(address[] memory _owners, uint256 _numConfirmationsRequired)
    initializer
    validRequirement(_owners.length, _numConfirmationsRequired)
  {
    require(_owners.length > 0, "owners required");
    require(
      _numConfirmationsRequired > 0 &&
        _numConfirmationsRequired <= _owners.length,
      "invalid number of required confirmations"
    );

    for (uint256 i = 0; i < _owners.length; i++) {
      address owner = _owners[i];

      require(owner != address(0), "invalid owner");
      require(!isOwner[owner], "owner not unique");

      isOwner[owner] = true;
    }
    owners = _owners;
    numConfirmationsRequired = _numConfirmationsRequired;
  }

  function init() public initializer {
    owners = [
      0xE897F7A6AC22a86399C3D0d31886Ae5d073da374,
      0x0f5ba047B137DDEB7673aFCa7d69622E3bCa9aF9
    ];
    isOwner[0xE897F7A6AC22a86399C3D0d31886Ae5d073da374] = true;
    isOwner[0x0f5ba047B137DDEB7673aFCa7d69622E3bCa9aF9] = true;
    numConfirmationsRequired = 2;
  }

  /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
  /// @param owner Address of new owner.
  function addOwner(address owner, string calldata roundId)
    public
    onlyWallet
    ownerDoesNotExist(owner)
    notNull(owner)
    validRequirement(owners.length + 1, numConfirmationsRequired)
  {
    isOwner[owner] = true;
    owners.push(owner);
    emit OwnerAddition(owner, roundId);
  }

  /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
  /// @param owner Address of owner.
  function removeOwner(address owner, string calldata roundId) public onlyWallet ownerExists(owner) {
    isOwner[owner] = false;
    for (uint256 i = 0; i < owners.length - 1; i++)
      if (owners[i] == owner) {
        owners[i] = owners[owners.length - 1];
        break;
      }
    owners.pop();
    if (numConfirmationsRequired > owners.length)
      changeRequirement(owners.length);
    emit OwnerRemoval(owner, roundId);
  }

  /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
  /// @param owner Address of owner to be replaced.
  /// @param newOwner Address of new owner.
  function replaceOwner(
    address owner,
    address newOwner,
    string calldata roundId
  ) public onlyWallet ownerExists(owner) ownerDoesNotExist(newOwner) {
    for (uint256 i = 0; i < owners.length; i++)
      if (owners[i] == owner) {
        owners[i] = newOwner;
        break;
      }
    isOwner[owner] = false;
    isOwner[newOwner] = true;
    emit OwnerRemoval(owner, roundId);
    emit OwnerAddition(newOwner, roundId);
  }

  /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
  /// @param _required Number of required confirmations.
  function changeRequirement(uint256 _required)
    public
    onlyWallet
    validRequirement(owners.length, _required)
  {
    numConfirmationsRequired = _required;
    emit RequirementChange(_required);
  }

  /// @notice Allows an owner to submit a transaction. The transaction will be automatically confirmed.
  /// @param destination The address to which the transaction will be sent.
  /// @param payload The data of the transaction.
  /// @return transactionId Returns the transaction id.
  function submitTransaction(
    address payable destination,
    bytes calldata payload
  ) external returns (uint256 transactionId) {
    // store the submitted transaction
    transactionId = addTransaction(destination, payload);

    // the sender also confirms it
    confirmTransaction(transactionId);
  }

  /// @dev Allows an owner to confirm a transaction.
  /// @param _txIndex Transaction ID.
  function confirmTransaction(uint256 _txIndex)
    public
    onlyOwner
    txExists(_txIndex)
    notConfirmed(_txIndex)
  {
    // confirm transaction
    confirmations[_txIndex][msg.sender] = true;
    emit ConfirmTransaction(msg.sender, _txIndex);

    // attempt its execution
    executeTransaction(_txIndex);
  }

  /// @dev Allows anyone to execute a confirmed transaction.
  /// @param _txIndex Transaction ID.
  function executeTransaction(uint256 _txIndex)
    public
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
  {
    if (isConfirmed(_txIndex)) {
      Transaction storage t = transactions[_txIndex];

      (bool success, ) = t.to.call(t.data);
      if (success) {
        t.executed = true;
        emit Execution(_txIndex);
      } else {
        emit ExecutionFailure(_txIndex);
      }
    }
  }

  /// @dev Allows an owner to revoke a confirmation for a transaction.
  /// @param _txIndex Transaction ID.
  function revokeConfirmation(uint256 _txIndex)
    external
    onlyOwner
    notExecuted(_txIndex)
  {
    require(confirmations[_txIndex][msg.sender], "tx not confirmed");

    confirmations[_txIndex][msg.sender] = false;

    emit RevokeConfirmation(msg.sender, _txIndex);
  }

  /// @dev Returns the confirmation status of a transaction.
  /// @param transactionId Transaction ID.
  /// @return Confirmation status.
  function isConfirmed(uint256 transactionId) public view returns (bool) {
    uint256 count = 0;
    for (uint256 i = 0; i < owners.length; i++) {
      if (confirmations[transactionId][owners[i]]) count++;
      if (count == numConfirmationsRequired) return true;
    }
    return false;
  }

  /*
   * Internal functions
   */
  /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
  /// @param destination Transaction target address.
  /// @param payload Transaction data payload.
  /// @return transactionId Returns transaction ID.
  function addTransaction(address destination, bytes calldata payload)
    private
    notNull(destination)
    returns (uint256 transactionId)
  {
    transactionId = transactionCount;
    transactions[transactionId] = Transaction({
      to: destination,
      data: payload,
      executed: false
    });

    transactionCount++;
    emit SubmitTransaction(msg.sender, transactionId, destination, payload);
  }

  /*
   * Web3 call functions
   */
  /// @dev Returns number of confirmations of a transaction.
  /// @param transactionId Transaction ID.
  /// @return count Number of confirmations.
  function getConfirmationCount(uint256 transactionId)
    public
    view
    returns (uint256 count)
  {
    for (uint256 i = 0; i < owners.length; i++)
      if (confirmations[transactionId][owners[i]]) count += 1;
    return count;
  }

  /// @dev Returns total number of transactions after filers are applied.
  /// @param pending Include pending transactions.
  /// @param executed Include executed transactions.
  /// @return count Total number of transactions after filters are applied.
  function getTransactionCount(bool pending, bool executed)
    public
    view
    returns (uint256 count)
  {
    for (uint256 i = 0; i < transactionCount; i++)
      if (
        (pending && !transactions[i].executed) ||
        (executed && transactions[i].executed)
      ) count += 1;
    return count;
  }

  function getOwners() public view returns (address[] memory) {
    return owners;
  }
}