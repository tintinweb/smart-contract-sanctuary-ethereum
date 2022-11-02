/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;


// 
interface IAVN {
  event LogQuorumUpdated(uint256[2] quorum);
  event LogValidatorFunctionsAreEnabled(bool status);
  event LogLiftingIsEnabled(bool status);
  event LogLoweringIsEnabled(bool status);
  event LogLowerCallUpdated(bytes2 callId, uint256 numBytes);

  event LogValidatorRegistered(bytes32 indexed t1PublicKeyLHS, bytes32 t1PublicKeyRHS, bytes32 indexed t2PublicKey,
      uint256 indexed t2TransactionId);
  event LogValidatorDeregistered(bytes32 indexed t1PublicKeyLHS, bytes32 t1PublicKeyRHS, bytes32 indexed t2PublicKey,
      uint256 indexed t2TransactionId);
  event LogRootPublished(bytes32 indexed rootHash, uint256 indexed t2TransactionId);

  event LogLifted(address indexed token, address indexed t1Address, bytes32 indexed t2PublicKey, uint256 amount);
  event LogLowered(address indexed token, address indexed t1Address, bytes32 indexed t2PublicKey, uint256 amount);
  event LogGrowth(uint256 indexed amount, uint32 indexed period);

  // Owner only
  function loadValidators(address[] calldata t1Address, bytes32[] calldata t1PublicKeyLHS, bytes32[] calldata t1PublicKeyRHS,
      bytes32[] calldata t2PublicKey) external;
  function setQuorum(uint256[2] memory quorum) external;
  function disableValidatorFunctions() external;
  function enableValidatorFunctions() external;
  function disableLifting() external;
  function enableLifting() external;
  function disableLowering() external;
  function enableLowering() external;
  function updateLowerCall(bytes2 callId, uint256 numBytes) external;
  function triggerGrowth(uint256 amount) external;

  // Validator only
  function registerValidator(bytes memory t1PublicKey, bytes32 t2PublicKey, uint256 t2TransactionId,
      bytes calldata confirmations) external;
  function deregisterValidator(bytes memory t1PublicKey, bytes32 t2PublicKey, uint256 t2TransactionId,
      bytes calldata confirmations) external;
  function publishRoot(bytes32 rootHash, uint256 t2TransactionId, bytes calldata confirmations) external;

  // Public
  function getIsPublishedRootHash(bytes32 rootHash) external view returns (bool);
  function lift(address erc20Address, bytes calldata t2PublicKey, uint256 amount) external;
  function proxyLift(address erc20Address, bytes calldata t2PublicKey, uint256 amount, address approver, uint256 proofNonce,
      bytes calldata proof) external;
  function liftETH(bytes calldata t2PublicKey) external payable;
  function lower(bytes memory leaf, bytes32[] calldata merklePath) external;
  function confirmAvnTransaction(bytes32 leafHash, bytes32[] memory merklePath) external view returns (bool);
}

// 
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

// 
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC777/IERC777.sol)
/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Emitted when `amount` tokens are created by `operator` and assigned to `to`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` is made operator for `tokenHolder`
     */
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when `operator` is revoked its operator status for `tokenHolder`
     */
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
}

// 
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC777.sol)

// 
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)
/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// 
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC777Recipient.sol)

// 
// OpenZeppelin Contracts (last updated v4.6.0) (utils/introspection/IERC1820Registry.sol)
/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);

    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}

// 
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1820Registry.sol)

// 
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)
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

// 
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)
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

// 
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)
/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// 
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)
/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// 
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)
/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// 
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)
/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// 
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)
/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

// 
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// 
contract AVN is IAVN, IERC777Recipient, Initializable, UUPSUpgradeable, OwnableUpgradeable {
  // Universal address as defined in Registry Contract Address section of https://eips.ethereum.org/EIPS/eip-1820
  IERC1820Registry constant internal ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
  // keccak256("ERC777Token")
  bytes32 constant internal ERC777_TOKEN_HASH = 0xac7fbab5f54a3ca8194167523c6753bfeb96a445279294b6125b68cce2177054;
  // keccak256("ERC777TokensRecipient")
  bytes32 constant internal ERC777_TOKENS_RECIPIENT_HASH = 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;
  uint256 constant internal SIGNATURE_LENGTH = 65;
  uint256 constant internal LIFT_LIMIT = type(uint128).max;
  address constant internal PSEUDO_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  mapping (uint256 => bool) public isRegisteredValidator;
  mapping (uint256 => bool) public isActiveValidator;
  mapping (address => uint256) public t1AddressToId;
  mapping (bytes32 => uint256) public t2PublicKeyToId;
  mapping (uint256 => address) public idToT1Address;
  mapping (uint256 => bytes32) public idToT2PublicKey;
  mapping (bytes2 => uint256) public numBytesToLowerData;
  mapping (bytes32 => bool) public isPublishedRootHash;
  mapping (uint256 => bool) public isUsedT2TransactionId;
  mapping (bytes32 => bool) public hasLowered;
  mapping (bytes32 => bool) public hasLifted;

  uint256[2] public quorum;
  uint256 public numActiveValidators;
  uint256 public nextValidatorId;
  uint32 public growthPeriod;
  address public coreToken;
  address internal priorInstance;
  bool public validatorFunctionsAreEnabled;
  bool public liftingIsEnabled;
  bool public loweringIsEnabled;
  bool public newValue;

  function initialize(address _coreToken, address _priorInstance)
    public
    initializer
  {
    require(_coreToken != address(0), "Core token not specified");
    __Ownable_init();
    coreToken = _coreToken;
    priorInstance = _priorInstance; // We allow address(0) for no prior instance
    ERC1820_REGISTRY.setInterfaceImplementer(address(this), ERC777_TOKENS_RECIPIENT_HASH, address(this));
    // TODO: Set the lower IDs correctly
    numBytesToLowerData[0x2d00] = 133; // callID (2 bytes) + proof (2 prefix + 32 relayer + 32 signer + 1 prefix + 64 signature)
    numBytesToLowerData[0x2700] = 133; // callID (2 bytes) + proof (2 prefix + 32 relayer + 32 signer + 1 prefix + 64 signature)
    numBytesToLowerData[0x2702] = 2;   // callID (2 bytes)
    validatorFunctionsAreEnabled = true;
    liftingIsEnabled = true;
    loweringIsEnabled = true;
    nextValidatorId = 1;
    growthPeriod = 1;
    quorum[0] = 2;
    quorum[1] = 3;
  }

  modifier onlyWhenLiftingIsEnabled() {
    require(liftingIsEnabled, "Lifting currently disabled");
    _;
  }

  modifier onlyWhenValidatorFunctionsAreEnabled() {
    require(validatorFunctionsAreEnabled, "Function currently disabled");
    _;
  }

  function setNewValue() public {
    newValue = true;
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}

  function loadValidators(address[] calldata t1Address, bytes32[] calldata t1PublicKeyLHS, bytes32[] calldata t1PublicKeyRHS,
      bytes32[] calldata t2PublicKey)
    onlyOwner
    external
  {
    require(t1Address.length == t1PublicKeyLHS.length && t1PublicKeyLHS.length == t1PublicKeyRHS.length
        && t1PublicKeyRHS.length == t2PublicKey.length, "Validator keys missing");

    bytes memory t1PublicKey;

    for (uint256 i; i < t1Address.length; i++) {
      require(t1AddressToId[t1Address[i]] == 0, "T1Address already in use");
      require(t2PublicKeyToId[t2PublicKey[i]] == 0, "T2PublicKey already in use");
      t1PublicKey = abi.encodePacked(t1PublicKeyLHS[i], t1PublicKeyRHS[i]);
      require(address(uint160(uint256(keccak256(t1PublicKey)))) == t1Address[i], "T1 account mismatch");
      idToT1Address[nextValidatorId] = t1Address[i];
      idToT2PublicKey[nextValidatorId] = t2PublicKey[i];
      t1AddressToId[t1Address[i]] = nextValidatorId;
      t2PublicKeyToId[t2PublicKey[i]] = nextValidatorId;
      isRegisteredValidator[nextValidatorId] = true;
      isActiveValidator[nextValidatorId] = true;
      numActiveValidators++;
      nextValidatorId++;
    }
  }

  function setQuorum(uint256[2] memory _quorum)
    onlyOwner
    public
  {
    require(_quorum[1] != 0, "Invalid: div by zero");
    require(_quorum[0] <= _quorum[1], "Invalid: above 100%");
    quorum = _quorum;
    emit LogQuorumUpdated(quorum);
  }

  function disableValidatorFunctions()
    onlyOwner
    external
  {
    validatorFunctionsAreEnabled = false;
    emit LogValidatorFunctionsAreEnabled(false);
  }

  function enableValidatorFunctions()
    onlyOwner
    external
  {
    validatorFunctionsAreEnabled = true;
    emit LogValidatorFunctionsAreEnabled(true);
  }

  function disableLifting()
    onlyOwner
    external
  {
    liftingIsEnabled = false;
    emit LogLiftingIsEnabled(false);
  }

  function enableLifting()
    onlyOwner
    external
  {
    liftingIsEnabled = true;
    emit LogLiftingIsEnabled(true);
  }

  function disableLowering()
    onlyOwner
    external
  {
    loweringIsEnabled = false;
    emit LogLoweringIsEnabled(false);
  }

  function enableLowering()
    onlyOwner
    external
  {
    loweringIsEnabled = true;
    emit LogLoweringIsEnabled(true);
  }

  function updateLowerCall(bytes2 callId, uint256 numBytes)
    onlyOwner
    external
  {
    numBytesToLowerData[callId] = numBytes;
    emit LogLowerCallUpdated(callId, numBytes);
  }

  receive() payable external {
    require(msg.sender == priorInstance, "Cannot accept ETH unless lifting");
  }

  function triggerGrowth(uint256 amount)
    onlyOwner
    external
  {
    require(amount > 0, "Cannot trigger zero growth");
    assert(IERC20(coreToken).transferFrom(owner(), address(this), amount));
    uint256 newBalance = IERC20(coreToken).balanceOf(address(this));
    require(newBalance <= LIFT_LIMIT, "Exceeds limit");
    emit LogGrowth(amount, growthPeriod++);
  }

  function registerValidator(bytes memory t1PublicKey, bytes32 t2PublicKey, uint256 t2TransactionId,
      bytes calldata confirmations)
    onlyWhenValidatorFunctionsAreEnabled
    external
  {
    require(t1PublicKey.length == 64, "T1 public key must be 64 bytes");
    address t1Address = address(uint160(uint256(keccak256(t1PublicKey))));
    uint256 id = t1AddressToId[t1Address];
    require(isRegisteredValidator[id] == false, "Validator is already registered");

    // The order of the elements is the reverse of the deregisterValidatorHash
    bytes32 registerValidatorHash = keccak256(abi.encodePacked(t1PublicKey, t2PublicKey));
    verifyConfirmations(toConfirmationHash(registerValidatorHash, t2TransactionId), confirmations);
    doStoreT2TransactionId(t2TransactionId);

    if (id == 0) {
      require(t2PublicKeyToId[t2PublicKey] == 0, "T2 public key already in use");
      id = nextValidatorId;
      idToT1Address[id] = t1Address;
      t1AddressToId[t1Address] = id;
      idToT2PublicKey[id] = t2PublicKey;
      t2PublicKeyToId[t2PublicKey] = id;
      nextValidatorId++;
    } else {
      require(idToT2PublicKey[id] == t2PublicKey, "Cannot change T2 public key");
    }

    isRegisteredValidator[id] = true;

    bytes32 t1PublicKeyLHS;
    bytes32 t1PublicKeyRHS;
    assembly {
      t1PublicKeyLHS := mload(add(t1PublicKey, 0x20))
      t1PublicKeyRHS := mload(add(t1PublicKey, 0x40))
    }

    emit LogValidatorRegistered(t1PublicKeyLHS, t1PublicKeyRHS, t2PublicKey, t2TransactionId);
  }

  function deregisterValidator(bytes memory t1PublicKey, bytes32 t2PublicKey, uint256 t2TransactionId,
      bytes calldata confirmations)
    onlyWhenValidatorFunctionsAreEnabled
    external
  {
    uint256 id = t2PublicKeyToId[t2PublicKey];
    require(isRegisteredValidator[id], "Validator is not registered");

    // The order of the elements is the reverse of the registerValidatorHash
    bytes32 deregisterValidatorHash = keccak256(abi.encodePacked(t2PublicKey, t1PublicKey));
    verifyConfirmations(toConfirmationHash(deregisterValidatorHash, t2TransactionId), confirmations);
    doStoreT2TransactionId(t2TransactionId);

    isRegisteredValidator[id] = false;
    isActiveValidator[id] = false;
    numActiveValidators--;

    bytes32 t1PublicKeyLHS;
    bytes32 t1PublicKeyRHS;
    assembly {
      t1PublicKeyLHS := mload(add(t1PublicKey, 0x20))
      t1PublicKeyRHS := mload(add(t1PublicKey, 0x40))
    }

    emit LogValidatorDeregistered(t1PublicKeyLHS, t1PublicKeyRHS, t2PublicKey, t2TransactionId);
  }

  function publishRoot(bytes32 rootHash, uint256 t2TransactionId, bytes calldata confirmations)
    onlyWhenValidatorFunctionsAreEnabled
    external
  {
    verifyConfirmations(toConfirmationHash(rootHash, t2TransactionId), confirmations);
    doStoreT2TransactionId(t2TransactionId);
    require(isPublishedRootHash[rootHash] == false, "Root already exists");
    isPublishedRootHash[rootHash] = true;
    emit LogRootPublished(rootHash, t2TransactionId);
  }

  function getIsPublishedRootHash(bytes32 rootHash)
    external
    view
    returns (bool)
  {
    return isPublishedRootHash[rootHash];
  }

  function lift(address erc20Address, bytes calldata t2PublicKey, uint256 amount)
    onlyWhenLiftingIsEnabled
    external
  {
    doLift(erc20Address, msg.sender, t2PublicKey, amount);
  }

  function proxyLift(address erc20Address, bytes calldata t2PublicKey, uint256 amount, address approver, uint256 proofNonce,
      bytes calldata proof)
    onlyWhenLiftingIsEnabled
    external
  {
    if (msg.sender != approver) {
      bytes32 proofHash = keccak256(proof);
      require(hasLifted[proofHash] == false, "Lift proof already used");
      hasLifted[proofHash] = true;
      bytes32 msgHash = keccak256(abi.encodePacked(erc20Address, t2PublicKey, amount, proofNonce));
      address signer = recoverSigner(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash)), proof);
      require(signer == approver, "Lift proof invalid");
    }
    doLift(erc20Address, approver, t2PublicKey, amount);
  }

  function liftETH(bytes calldata t2PublicKey)
    payable
    onlyWhenLiftingIsEnabled
    external
  {
    bytes32 checkedT2PublicKey = checkT2PublicKey(t2PublicKey);
    require(msg.value > 0, "Cannot lift zero ETH");
    emit LogLifted(PSEUDO_ETH_ADDRESS, msg.sender, checkedT2PublicKey, msg.value);
  }

  // ERC-777 automatic lifting
  function tokensReceived(address /* operator */, address from, address to, uint256 amount, bytes calldata data,
      bytes calldata /* operatorData */)
    onlyWhenLiftingIsEnabled
    external
  {
    if (from == priorInstance) return; // recovering funds so we don't lift here
    if (data.length == 0 && from == owner() && msg.sender == address(coreToken)) return; // growth action so we don't lift here
    require(to == address(this), "Tokens must be sent to this contract");
    require(amount > 0, "Cannot lift zero ERC777 tokens");
    bytes32 checkedT2PublicKey = checkT2PublicKey(data);
    require(ERC1820_REGISTRY.getInterfaceImplementer(msg.sender, ERC777_TOKEN_HASH) == msg.sender, "Token must be registered");
    IERC777 erc777Contract = IERC777(msg.sender);
    require(erc777Contract.balanceOf(address(this)) <= LIFT_LIMIT, "Exceeds ERC777 lift limit");
    emit LogLifted(msg.sender, from, checkedT2PublicKey, amount);
  }

  function lower(bytes memory leaf, bytes32[] calldata merklePath)
    external
  {
    require(loweringIsEnabled, "Lowering currently disabled");
    bytes32 leafHash = keccak256(leaf);
    require(confirmAvnTransaction(leafHash, merklePath), "Leaf or path invalid");
    require(hasLowered[leafHash] == false, "Already lowered");
    hasLowered[leafHash] = true;

    uint256 ptr;
    ptr += getCompactIntegerByteSize(leaf[ptr]); // add number of bytes encoding the leaf length
    require(uint8(leaf[ptr]) & 128 != 0, "Unsigned transaction"); // bitwise version check to ensure leaf is signed transaction
    ptr += 99; // version (1 byte) + multiAddress type (1 byte) + sender (32 bytes) + curve type (1 byte) + signature (64 bytes)
    ptr += leaf[ptr] == 0x00 ? 1 : 2; // add number of era bytes (immortal is 1, otherwise 2)
    ptr += getCompactIntegerByteSize(leaf[ptr]); // add number of bytes encoding the nonce
    ptr += getCompactIntegerByteSize(leaf[ptr]); // add number of bytes encoding the tip
    ptr += 32; // account for the first 32 EVM bytes holding the leaf's length

    bytes2 callId;

    assembly {
      callId := mload(add(leaf, ptr))
    }

    require(numBytesToLowerData[callId] != 0, "Not a lower leaf");
    ptr += numBytesToLowerData[callId];
    bytes32 t2PublicKey;
    address token;
    uint128 amount;
    address t1Address;

    assembly {
      t2PublicKey := mload(add(leaf, ptr)) // load next 32 bytes into 32 byte type starting at ptr
      token := mload(add(add(leaf, 20), ptr)) // load leftmost 20 of next 32 bytes into 20 byte type starting at ptr + 20
      amount := mload(add(add(leaf, 36), ptr)) // load leftmost 16 of next 32 bytes into 16 byte type starting at ptr + 20 + 16
      t1Address := mload(add(add(leaf, 56), ptr)) // load leftmost 20 of next 32 bytes type starting at ptr + 20 + 16 + 20
    }

    // amount was encoded in little endian so we need to reverse to big endian:
    amount = ((amount & 0xFF00FF00FF00FF00FF00FF00FF00FF00) >> 8) | ((amount & 0x00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
    amount = ((amount & 0xFFFF0000FFFF0000FFFF0000FFFF0000) >> 16) | ((amount & 0x0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
    amount = ((amount & 0xFFFFFFFF00000000FFFFFFFF00000000) >> 32) | ((amount & 0x00000000FFFFFFFF00000000FFFFFFFF) << 32);
    amount = (amount >> 64) | (amount << 64);

    if (token == PSEUDO_ETH_ADDRESS) {
      (bool success, ) = payable(t1Address).call{value: amount}("");
      require(success, "ETH transfer failed");
    } else if (ERC1820_REGISTRY.getInterfaceImplementer(token, ERC777_TOKEN_HASH) == token) {
      IERC777(token).send(t1Address, amount, "");
    } else {
      assert(IERC20(token).transfer(t1Address, amount));
    }

    emit LogLowered(token, t1Address, t2PublicKey, amount);
  }

  function confirmAvnTransaction(bytes32 leafHash, bytes32[] memory merklePath)
    public
    view
    returns (bool)
  {
    bytes32 rootHash = leafHash;

    for (uint256 i; i < merklePath.length; i++) {
      bytes32 node = merklePath[i];
      if (rootHash < node)
        rootHash = keccak256(abi.encode(rootHash, node));
      else
        rootHash = keccak256(abi.encode(node, rootHash));
    }

    return isPublishedRootHash[rootHash];
  }

  // reference: https://docs.substrate.io/v3/advanced/scale-codec/#compactgeneral-integers
  function getCompactIntegerByteSize(bytes1 checkByte)
    private
    pure
    returns (uint256 byteLength)
  {
    uint8 mode = uint8(checkByte) & 3; // the 2 least significant bits encode the byte mode so we do a bitwise AND on them

    if (mode == 0) { // single-byte mode
      byteLength = 1;
    } else if (mode == 1) { // two-byte mode
      byteLength = 2;
    } else if (mode == 2) { // four-byte mode
      byteLength = 4;
    } else {
      byteLength = uint8(checkByte >> 2) + 5; // upper 6 bits + 4 are the number of bytes following + 1 for the checkbyte itself
    }
  }

  function toConfirmationHash(bytes32 data, uint256 t2TransactionId)
    private
    view
    returns (bytes32)
  {
    return keccak256(abi.encode(data, t2TransactionId, idToT2PublicKey[t1AddressToId[msg.sender]]));
  }

  function verifyConfirmations(bytes32 msgHash, bytes memory confirmations)
    private
  {
    bytes32 ethSignedPrefixMsgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
    uint256 numConfirmations = confirmations.length / SIGNATURE_LENGTH;
    uint256 requiredConfirmations = numActiveValidators * quorum[0] / quorum[1] + 1;
    uint256 validConfirmations;
    uint256 id;
    bytes32 r;
    bytes32 s;
    uint8 v;
    bool[] memory confirmed = new bool[](nextValidatorId);

    for (uint256 i; i < numConfirmations; i++) {
      assembly {
        let offset := mul(i, SIGNATURE_LENGTH)
        r := mload(add(confirmations, add(0x20, offset)))
        s := mload(add(confirmations, add(0x40, offset)))
        v := byte(0, mload(add(confirmations, add(0x60, offset))))
      }
      if (v < 27) v += 27;
      if (v != 27 && v != 28 || uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
        continue;
      } else {
        id = t1AddressToId[ecrecover(ethSignedPrefixMsgHash, v, r, s)];

        if (isActiveValidator[id] == false) {
          if (isRegisteredValidator[id]) {
            // Here we activate any previously registered but as yet unactivated validators
            isActiveValidator[id] = true;
            numActiveValidators++;
            validConfirmations++;
            confirmed[id] = true;
          }
        } else if (confirmed[id] == false) {
          validConfirmations++;
          confirmed[id] = true;
        }
      }
      if (validConfirmations == requiredConfirmations) break;
    }

    require(validConfirmations == requiredConfirmations, "Invalid confirmations");
  }

  function doStoreT2TransactionId(uint256 t2TransactionId)
    private
  {
    require(isUsedT2TransactionId[t2TransactionId] == false, "T2 transaction must be unique");
    isUsedT2TransactionId[t2TransactionId] = true;
  }

  function doLift(address erc20Address, address approver, bytes memory t2PublicKey, uint256 amount)
    private
  {
    require(ERC1820_REGISTRY.getInterfaceImplementer(erc20Address, ERC777_TOKEN_HASH) == address(0), "ERC20 lift only");
    require(amount > 0, "Cannot lift zero ERC20 tokens");
    bytes32 checkedT2PublicKey = checkT2PublicKey(t2PublicKey);
    IERC20 erc20Contract = IERC20(erc20Address);
    uint256 currentBalance = erc20Contract.balanceOf(address(this));
    assert(erc20Contract.transferFrom(approver, address(this), amount));
    uint256 newBalance = erc20Contract.balanceOf(address(this));
    require(newBalance <= LIFT_LIMIT, "Exceeds ERC20 lift limit");
    emit LogLifted(erc20Address, approver, checkedT2PublicKey, newBalance - currentBalance);
  }

  function checkT2PublicKey(bytes memory t2PublicKey)
    private
    pure
    returns (bytes32 checkedT2PublicKey)
  {
    require(t2PublicKey.length == 32, "Bad T2 public key");
    checkedT2PublicKey = bytes32(t2PublicKey);
  }

  function recoverSigner(bytes32 hash, bytes memory signature)
    private
    pure
    returns (address)
  {
    if (signature.length != 65) return address(0);

    bytes32 r;
    bytes32 s;
    uint8 v;

    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) return address(0);
    if (v < 27) v += 27;
    if (v != 27 && v != 28) return address(0);

    return ecrecover(hash, v, r, s);
  }
}