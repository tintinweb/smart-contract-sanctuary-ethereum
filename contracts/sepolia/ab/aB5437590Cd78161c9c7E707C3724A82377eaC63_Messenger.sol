// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.8.5;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./xcall/libraries/BTPAddress.sol";
import "./xcall/libraries/ParseAddress.sol";
import "./xcall/interfaces/ICallService.sol";
import "./utils/XCallBase.sol";

contract Messenger is XCallBase {
    uint256 private lastRollbackId;

    mapping(uint256 => RollbackData) private rollbacks;

    mapping(string => bool) private authorizedMessengers; // Authorized messenger contracts on other chains
    mapping(string => string) public messengersNID; // networkID => Messenger BTP Address

    mapping(string => string) public receivedMessages; // received messageID => message
    mapping(string => string) public sentMessages; // sent messageID => message
    mapping(address => uint) public sentMessagesCount; // user => count

    event TextMessageReceived(string indexed _from, string indexed _messageID);
    event TextMessageSent(address indexed _from, string indexed _messageID);

    /**
        @param _callServiceAddress Address of x-call service on the current chain
        @param _networkID The network ID of the current chain
     */

    constructor(
        address _callServiceAddress,
        string memory _networkID
    ) {
        initialize(
            _callServiceAddress,
            _networkID
        );
    }

    // public functions

    function sendMessage(
        string memory _to, // address of the recipient (BTP address of Messenger contract on the other chain)
        string memory _message // message to send
    ) public payable {
        uint fee = getXCallFee(_to, true);

        require(msg.value >= fee, "Messenger: insufficient fee");
        require(authorizedMessengers[_to] == true, "Messenger: no bridge found for this network");

        string memory messageId = string(
            abi.encodePacked(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        sentMessagesCount[msg.sender],
                        block.timestamp
                    )
                )
            )
        );

        bytes memory payload = abi.encode("SEND_TEXT_MESSAGE", abi.encode(messageId, _message));
        bytes memory rollbackData = abi.encode("ROLLBACK_TEXT_MESSAGE", abi.encode(messageId));

        _sendXCallMessage(_to, payload, rollbackData);

        sentMessages[messageId] = _message;
        sentMessagesCount[msg.sender]++;

        emit TextMessageSent(msg.sender, messageId);
    }

    function sendArbitraryCall(
        string memory _to,
        bytes memory _data
    ) public payable {
        uint fee = getXCallFee(_to, true);

        string memory destinationNetworkID = BTPAddress.networkAddress(_to);
        string memory messengerAddress = messengersNID[destinationNetworkID];

        require(msg.value >= fee, "Messenger: insufficient fee");

        bytes memory payload = abi.encode("ARBITRARY_CALL", abi.encode(_to, _data));

        _sendXCallMessage(messengerAddress, payload, "");
    }

    // internal functions

    function _processTextMessage(
        string memory _from,
        bytes memory _data
    ) internal {
        (string memory messageID, string memory message) = abi.decode(_data, (string, string));

        receivedMessages[messageID] = message;

        emit TextMessageReceived(_from, messageID);
    }

    function _processArbitraryCall(
        bytes memory _data
    ) internal {
        (string memory destBTP, bytes memory data) = abi.decode(_data, (string, bytes));

        (, string memory destString) = BTPAddress.parseBTPAddress(destBTP);
        address to = ParseAddress.parseAddress(destString, '');
        (bool success, ) = to.call(data);

        require(success, "Messenger: arbitrary call failed");
    }

    function _rollbackTextMessage(
        bytes memory _data
    ) internal {
        string memory messageID = abi.decode(_data, (string));
        delete sentMessages[messageID];
    }

    // X-Call handlers

    function _processXCallRollback(
        bytes memory _data
    ) internal override {
        (string memory method, bytes memory data) = abi.decode(_data, (string, bytes));

        if (compareTo(method, "ROLLBACK_TEXT_MESSAGE")) {
            _rollbackTextMessage(data);
        } else {
            revert("NFTProxy: method not supported");
        }

        emit RollbackDataReceived(callSvcBtpAddr, _data);
    }

    function _processXCallMethod(
        string calldata _from,
        bytes memory _data
    ) internal override {
        (string memory method, bytes memory data) = abi.decode(_data, (string, bytes));

        require(authorizedMessengers[_from] == true, "Messenger: only authorized messengers can call this method");

        if (compareTo(method, "SEND_TEXT_MESSAGE")) {
            _processTextMessage(_from, data);
        } else if (compareTo(method, "ARBITRARY_CALL")) {
            _processArbitraryCall(data);
        } else {
            revert("NFTProxy: method not supported");
        }

        emit MessageReceived(_from, _data);
    }

    // Admin functions

    function authorizeMessenger(
        string memory _BTPaddress
    ) public onlyOwner {
        authorizedMessengers[_BTPaddress] = true;
        string memory nid = BTPAddress.networkAddress(_BTPaddress);
        messengersNID[nid] = _BTPaddress;
    }

    function revokeMessenger(
        string memory _BTPaddress
    ) public onlyOwner {
        authorizedMessengers[_BTPaddress] = false;
        string memory nid = BTPAddress.networkAddress(_BTPaddress);
        delete messengersNID[nid];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.8.5;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../xcall/libraries/BTPAddress.sol";
import "../xcall/interfaces/IFeeManage.sol";
import "../xcall/interfaces/ICallService.sol";
import "../xcall/interfaces/ICallServiceReceiver.sol";

contract XCallBase is ICallServiceReceiver, Initializable, Ownable {
    address public callSvc;

    string public callSvcBtpAddr;
    string public networkID;

    uint256 private lastRollbackId;

    struct RollbackData {
        uint256 id;
        bytes rollbackData;
        uint256 ssn;
    }

    mapping(uint256 => RollbackData) private rollbacks;

    event MessageReceived(string indexed _from, bytes _data);
    event MessageSent(address indexed _from, uint256 indexed _messageId, bytes _data);
    event RollbackDataReceived(string indexed _from, bytes _data);

    receive() external payable {}
    fallback() external payable {}

    modifier onlyCallService() {
        require(msg.sender == callSvc, "NFTProxy: only CallService can call this function");
        _;
    }

    /**
        @notice Initializer. Replaces constructor.
        @dev Callable only once by deployer.
        @param _callServiceAddress Address of x-call service on the current chain
        @param _networkID The network ID of the current chain
     */
    function initialize(
        address _callServiceAddress,
        string memory _networkID
    ) public initializer {
        callSvc = _callServiceAddress;
        networkID = _networkID;
        callSvcBtpAddr = ICallService(callSvc).getBtpAddress();
    }

    function compareTo(
        string memory _base,
        string memory _value
    ) internal pure returns (bool) {
        if (keccak256(abi.encodePacked(_base)) == keccak256(abi.encodePacked(_value))) {
            return true;
        }

        return false;
    }

    function _processXCallRollback(bytes memory _data) internal virtual {
        emit RollbackDataReceived(callSvcBtpAddr, _data);
        revert("NFTProxy: method not supported");
    }

    function _processXCallMethod(
        string calldata _from,
        bytes memory _data
    ) internal virtual {
        emit MessageReceived(_from, _data);
        revert("NFTProxy: method not supported");
    }

    function _processXCallMessage(
        string calldata _from,
        bytes calldata _data
    ) internal {
        if (compareTo(_from, callSvcBtpAddr)) {
            (uint256 rbid, bytes memory encodedRb) = abi.decode(_data, (uint256, bytes));
            RollbackData memory storedRb = rollbacks[rbid];

            require(compareTo(string(encodedRb), string(storedRb.rollbackData)), "NFTProxy: rollback data mismatch");

            _processXCallRollback(encodedRb);

            delete rollbacks[rbid];
            return;
        }

        _processXCallMethod(_from, _data);
    }


    /**
        @notice Sends XCall message to destination chain.
        @param _to The destination BTP address
        @param _data The data needed to be sent
        @param _rollback The rollback data needed to be sent back in case of failure
     */
    function _sendXCallMessage(
        string memory _to,
        bytes memory _data,
        bytes memory _rollback
    ) internal {
        if (_rollback.length > 0) {
            uint fee = getXCallFee(_to, true);
            require(msg.value >= fee, "NFTProxy: insufficient fee");

            uint256 id = ++lastRollbackId;
            bytes memory encodedRd = abi.encode(id, _rollback);

            uint256 sn = ICallService(callSvc).sendCallMessage{value:msg.value}(
                _to,
                _data,
                encodedRd
            );

            rollbacks[id] = RollbackData(id, _rollback, sn);

            emit MessageSent(msg.sender, sn, _data);
        } else {
            uint fee = getXCallFee(_to, false);
            require(msg.value >= fee, "NFTProxy: insufficient fee");

            uint256 sn = ICallService(callSvc).sendCallMessage{value:msg.value}(
                _to,
                _data,
                _rollback
            );

            emit MessageSent(msg.sender, sn, _data);
        }
    }

    /**
        @notice Used for unit testing.
        @dev Only callable from the owner.
        @param _data The mock calldata delivered from the test suite
        (supposed to be as close as handleCallMessage input)
     */
    function testXCall(
        string calldata _from,
        bytes calldata _data
    ) public onlyOwner {
        _processXCallMessage(_from, _data);
    }

    /**
        @notice Handles the call message received from the source chain.
        @dev Only called from the Call Message Service.
        @param _from The BTP address of the caller on the source chain
        @param _data The calldata delivered from the caller
     */
    function handleCallMessage(
        string calldata _from,
        bytes calldata _data
    ) external override onlyCallService {
        _processXCallMessage(_from, _data);
    }

    function getXCallFee(
        string memory _to,
        bool _useCallback
    ) public view returns (uint) {
        string memory destinationNetworkID = BTPAddress.networkAddress(_to);
        return IFeeManage(callSvc).getFee(destinationNetworkID, _useCallback);
    }

    function setCallServiceAdress(
        address _callServiceAddress
    ) public onlyOwner {
        callSvc = _callServiceAddress;
        callSvcBtpAddr = ICallService(callSvc).getBtpAddress();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface ICallService {
    /**
       @notice Get BTP address of Call Service
     */
    function getBtpAddress(
    ) external view returns (
        string memory
    );

    /*======== At the source CALL_BSH ========*/
    /**
       @notice Sends a call message to the contract on the destination chain.
       @param _to The BTP address of the callee on the destination chain
       @param _data The calldata specific to the target contract
       @param _rollback (Optional) The data for restoring the caller state when an error occurred
       @return The serial number of the request
     */
    function sendCallMessage(
        string memory _to,
        bytes memory _data,
        bytes memory _rollback
    ) external payable returns (
        uint256
    );

    /**
       @notice Notifies that the requested call message has been sent.
       @param _from The chain-specific address of the caller
       @param _to The BTP address of the callee on the destination chain
       @param _sn The serial number of the request
       @param _nsn The network serial number of the BTP message
     */
    event CallMessageSent(
        address indexed _from,
        string indexed _to,
        uint256 indexed _sn,
        int256 _nsn
    );

    /**
       @notice Notifies that a response message has arrived for the `_sn` if the request was a two-way message.
       @param _sn The serial number of the previous request
       @param _code The execution result code
                    (0: Success, -1: Unknown generic failure, >=1: User defined error code)
       @param _msg The result message if any
     */
    event ResponseMessage(
        uint256 indexed _sn,
        int _code,
        string _msg
    );

    /**
       @notice Notifies the user that a rollback operation is required for the request '_sn'.
       @param _sn The serial number of the previous request
     */
    event RollbackMessage(
        uint256 indexed _sn
    );

    /**
       @notice Rollbacks the caller state of the request '_sn'.
       @param _sn The serial number of the previous request
     */
    function executeRollback(
        uint256 _sn
    ) external;

    /**
       @notice Notifies that the rollback has been executed.
       @param _sn The serial number for the rollback
       @param _code The execution result code
                    (0: Success, -1: Unknown generic failure)
       @param _msg The result message if any
     */
    event RollbackExecuted(
        uint256 indexed _sn,
        int _code,
        string _msg
    );

    /*======== At the destination CALL_BSH ========*/
    /**
       @notice Notifies the user that a new call message has arrived.
       @param _from The BTP address of the caller on the source chain
       @param _to A string representation of the callee address
       @param _sn The serial number of the request from the source
       @param _reqId The request id of the destination chain
     */
    event CallMessage(
        string indexed _from,
        string indexed _to,
        uint256 indexed _sn,
        uint256 _reqId
    );

    /**
       @notice Executes the requested call message.
       @param _reqId The request id
     */
    function executeCall(
        uint256 _reqId
    ) external;

    /**
       @notice Notifies that the call message has been executed.
       @param _reqId The request id for the call message
       @param _code The execution result code
                    (0: Success, -1: Unknown generic failure)
       @param _msg The result message if any
     */
    event CallExecuted(
        uint256 indexed _reqId,
        int _code,
        string _msg
    );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface ICallServiceReceiver {
    /**
       @notice Handles the call message received from the source chain.
       @dev Only called from the Call Message Service.
       @param _from The BTP address of the caller on the source chain
       @param _data The calldata delivered from the caller
     */
    function handleCallMessage(
        string calldata _from,
        bytes calldata _data
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface IFeeManage {
    /**
       @notice Sets the address of FeeHandler.
               If _addr is null (default), it accrues protocol fees.
               If _addr is a valid address, it transfers accrued fees to the address and
               will also transfer the receiving fees hereafter.
       @dev Only the admin wallet can invoke this.
       @param _addr (Address) The address of FeeHandler
     */
    function setProtocolFeeHandler(
        address _addr
    ) external;

    /**
       @notice Gets the current protocol fee handler address.
       @return (Address) The protocol fee handler address
     */
    function getProtocolFeeHandler(
    ) external view returns (
        address
    );

    /**
       @notice Sets the protocol fee amount.
       @dev Only the admin wallet can invoke this.
       @param _value (Integer) The protocol fee amount in loop
     */
    function setProtocolFee(
        uint256 _value
    ) external;

    /**
       @notice Gets the current protocol fee amount.
       @return (Integer) The protocol fee amount in loop
     */
    function getProtocolFee(
    ) external view returns (
        uint256
    );

    /**
       @notice Gets the fee for delivering a message to the _net.
               If the sender is going to provide rollback data, the _rollback param should set as true.
               The returned fee is the sum of the protocol fee and the relay fee.
       @param _net (String) The destination network address
       @param _rollback (Bool) Indicates whether it provides rollback data
       @return (Integer) the sum of the protocol fee and the relay fee
     */
    function getFee(
        string memory _net,
        bool _rollback
    ) external view returns (
        uint256
    );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

/**
   BTPAddress 'btp://NETWORK_ADDRESS/ACCOUNT_ADDRESS'
*/
library BTPAddress {
    bytes internal constant PREFIX = bytes("btp://");
    string internal constant REVERT = "invalidBTPAddress";
    bytes internal constant DELIMITER = bytes("/");

    /**
       @notice Parse BTP address
       @param _str (String) BTP address
       @return (String) network address
       @return (String) account address
    */
    function parseBTPAddress(
        string memory _str
    ) internal pure returns (
        string memory,
        string memory
    ) {
        uint256 offset = _validate(_str);
        return (_slice(_str, 6, offset),
        _slice(_str, offset+1, bytes(_str).length));
    }

    /**
       @notice Gets network address of BTP address
       @param _str (String) BTP address
       @return (String) network address
    */
    function networkAddress(
        string memory _str
    ) internal pure returns (
        string memory
    ) {
        return _slice(_str, 6, _validate(_str));
    }

    function _validate(
        string memory _str
    ) private pure returns (
        uint256 offset
    ){
        bytes memory _bytes = bytes(_str);

        uint256 i = 0;
        for (; i < 6; i++) {
            if (_bytes[i] != PREFIX[i]) {
                revert(REVERT);
            }
        }
        for (; i < _bytes.length; i++) {
            if (_bytes[i] == DELIMITER[0]) {
                require(i > 6 && i < (_bytes.length -1), REVERT);
                return i;
            }
        }
        revert(REVERT);
    }

    function _slice(
        string memory _str,
        uint256 _from,
        uint256 _to
    ) private pure returns (
        string memory
    ) {
        //If _str is calldata, could use slice
        //        return string(bytes(_str)[_from:_to]);
        bytes memory _bytes = bytes(_str);
        bytes memory _ret = new bytes(_to - _from);
        uint256 j = _from;
        for (uint256 i = 0; i < _ret.length; i++) {
            _ret[i] = _bytes[j++];
        }
        return string(_ret);
    }

    /**
       @notice Create BTP address by network address and account address
       @param _net (String) network address
       @param _addr (String) account address
       @return (String) BTP address
    */
    function btpAddress(
        string memory _net,
        string memory _addr
    ) internal pure returns (
        string memory
    ) {
        return string(abi.encodePacked(PREFIX, _net, DELIMITER, _addr));
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

/*
 * Utility library of inline functions on addresses
 */
library ParseAddress {
    /**
     * @dev Get a checksummed string hex representation of an account address.
     * @param account address The account to get the checksum for.
     * @return The checksummed account string in ASCII format. Note that leading
     * "0x" is not included.
     */
    function toString(address account) internal pure returns (string memory) {
        // call internal function for converting an account to a checksummed string.
        return _toChecksumString(account);
    }

    /**
     * @dev Get a fixed-size array of whether or not each character in an account
     * will be capitalized in the checksum.
     * @param account address The account to get the checksum capitalization
     * information for.
     * @return A fixed-size array of booleans that signify if each character or
     * "nibble" of the hex encoding of the address will be capitalized by the
     * checksum.
     */
    function getChecksumCapitalizedCharacters(address account)
        internal
        pure
        returns (bool[40] memory)
    {
        // call internal function for computing characters capitalized in checksum.
        return _toChecksumCapsFlags(account);
    }

    /**
     * @dev Determine whether a string hex representation of an account address
     * matches the ERC-55 checksum of that address.
     * @param accountChecksum string The checksummed account string in ASCII
     * format. Note that a leading "0x" MUST NOT be included.
     * @return A boolean signifying whether or not the checksum is valid.
     */
    function isChecksumValid(string calldata accountChecksum)
        internal
        pure
        returns (bool)
    {
        // call internal function for validating checksum strings.
        return _isChecksumValid(accountChecksum);
    }

    function _toChecksumString(address account)
        internal
        pure
        returns (string memory asciiString)
    {
        // convert the account argument from address to bytes.
        bytes20 data = bytes20(account);

        // create an in-memory fixed-size bytes array.
        bytes memory asciiBytes = new bytes(40);

        // declare variable types.
        uint8 b;
        uint8 leftNibble;
        uint8 rightNibble;
        bool leftCaps;
        bool rightCaps;
        uint8 asciiOffset;

        // get the capitalized characters in the actual checksum.
        bool[40] memory caps = _toChecksumCapsFlags(account);

        // iterate over bytes, processing left and right nibble in each iteration.
        for (uint256 i = 0; i < data.length; i++) {
            // locate the byte and extract each nibble.
            b = uint8(uint160(data) / (2**(8 * (19 - i))));
            leftNibble = b / 16;
            rightNibble = b - 16 * leftNibble;

            // locate and extract each capitalization status.
            leftCaps = caps[2 * i];
            rightCaps = caps[2 * i + 1];

            // get the offset from nibble value to ascii character for left nibble.
            asciiOffset = _getAsciiOffset(leftNibble, leftCaps);

            // add the converted character to the byte array.
            asciiBytes[2 * i] = bytes1(leftNibble + asciiOffset);

            // get the offset from nibble value to ascii character for right nibble.
            asciiOffset = _getAsciiOffset(rightNibble, rightCaps);

            // add the converted character to the byte array.
            asciiBytes[2 * i + 1] = bytes1(rightNibble + asciiOffset);
        }

        return string(abi.encodePacked("0x", string(asciiBytes)));
    }

    function _toChecksumCapsFlags(address account)
        internal
        pure
        returns (bool[40] memory characterCapitalized)
    {
        // convert the address to bytes.
        bytes20 a = bytes20(account);

        // hash the address (used to calculate checksum).
        bytes32 b = keccak256(abi.encodePacked(_toAsciiString(a)));

        // declare variable types.
        uint8 leftNibbleAddress;
        uint8 rightNibbleAddress;
        uint8 leftNibbleHash;
        uint8 rightNibbleHash;

        // iterate over bytes, processing left and right nibble in each iteration.
        for (uint256 i; i < a.length; i++) {
            // locate the byte and extract each nibble for the address and the hash.
            rightNibbleAddress = uint8(a[i]) % 16;
            leftNibbleAddress = (uint8(a[i]) - rightNibbleAddress) / 16;
            rightNibbleHash = uint8(b[i]) % 16;
            leftNibbleHash = (uint8(b[i]) - rightNibbleHash) / 16;

            characterCapitalized[2 * i] = (leftNibbleAddress > 9 &&
                leftNibbleHash > 7);
            characterCapitalized[2 * i + 1] = (rightNibbleAddress > 9 &&
                rightNibbleHash > 7);
        }
    }

    function _isChecksumValid(string memory provided)
        internal
        pure
        returns (bool ok)
    {
        // convert the provided string into account type.
        address account = _toAddress(provided);

        // return false in the event the account conversion returned null address.
        if (account == address(0)) {
            // ensure that provided address is not also the null address first.
            bytes memory b = bytes(provided);
            for (uint256 i; i < b.length; i++) {
                if (b[i] != hex"30") {
                    return false;
                }
            }
        }

        // get the capitalized characters in the actual checksum.
        string memory actual = _toChecksumString(account);

        // compare provided string to actual checksum string to test for validity.
        return (keccak256(abi.encodePacked(actual)) ==
            keccak256(abi.encodePacked(provided)));
    }

    function _getAsciiOffset(uint8 nibble, bool caps)
        internal
        pure
        returns (uint8 offset)
    {
        // to convert to ascii characters, add 48 to 0-9, 55 to A-F, & 87 to a-f.
        if (nibble < 10) {
            offset = 48;
        } else if (caps) {
            offset = 55;
        } else {
            offset = 87;
        }
    }

    function _toAddress(string memory account)
        internal
        pure
        returns (address accountAddress)
    {
        // convert the account argument from address to bytes.
        bytes memory accountBytes = bytes(account);

        // create a new fixed-size byte array for the ascii bytes of the address.
        bytes memory accountAddressBytes = new bytes(20);

        // declare variable types.
        uint8 b;
        uint8 nibble;
        uint8 asciiOffset;

        // only proceed if the provided string has a length of 40.
        if (accountBytes.length == 40) {
            for (uint256 i; i < 40; i++) {
                // get the byte in question.
                b = uint8(accountBytes[i]);

                // ensure that the byte is a valid ascii character (0-9, A-F, a-f)
                if (b < 48) return address(0);
                if (57 < b && b < 65) return address(0);
                if (70 < b && b < 97) return address(0);
                if (102 < b) return address(0); //bytes(hex"");

                // find the offset from ascii encoding to the nibble representation.
                if (b < 65) {
                    // 0-9
                    asciiOffset = 48;
                } else if (70 < b) {
                    // a-f
                    asciiOffset = 87;
                } else {
                    // A-F
                    asciiOffset = 55;
                }

                // store left nibble on even iterations, then store byte on odd ones.
                if (i % 2 == 0) {
                    nibble = b - asciiOffset;
                } else {
                    accountAddressBytes[(i - 1) / 2] = (
                        bytes1(16 * nibble + (b - asciiOffset))
                    );
                }
            }

            // pack up the fixed-size byte array and cast it to accountAddress.
            bytes memory packed = abi.encodePacked(accountAddressBytes);
            assembly {
                accountAddress := mload(add(packed, 20))
            }
        }
    }

    // based on https://ethereum.stackexchange.com/a/56499/48410
    function _toAsciiString(bytes20 data)
        internal
        pure
        returns (string memory asciiString)
    {
        // create an in-memory fixed-size bytes array.
        bytes memory asciiBytes = new bytes(40);

        // declare variable types.
        uint8 b;
        uint8 leftNibble;
        uint8 rightNibble;

        // iterate over bytes, processing left and right nibble in each iteration.
        for (uint256 i = 0; i < data.length; i++) {
            // locate the byte and extract each nibble.
            b = uint8(uint160(data) / (2**(8 * (19 - i))));
            leftNibble = b / 16;
            rightNibble = b - 16 * leftNibble;

            // to convert to ascii characters, add 48 to 0-9 and 87 to a-f.
            asciiBytes[2 * i] = bytes1(
                leftNibble + (leftNibble < 10 ? 48 : 87)
            );
            asciiBytes[2 * i + 1] = bytes1(
                rightNibble + (rightNibble < 10 ? 48 : 87)
            );
        }

        return string(asciiBytes);
    }

    function parseAddress(
        string memory account,
        string memory revertMsg
    ) internal pure returns (address accountAddress)
    {
        bytes memory accountBytes = bytes(account);
        require(
            accountBytes.length == 42 &&
            accountBytes[0] == bytes1("0") &&
            accountBytes[1] == bytes1("x"),
            revertMsg
        );

        // create a new fixed-size byte array for the ascii bytes of the address.
        bytes memory accountAddressBytes = new bytes(20);

        // declare variable types.
        uint8 b;
        uint8 nibble;
        uint8 asciiOffset;

        for (uint256 i = 0; i < 40; i++) {
            // get the byte in question.
            b = uint8(accountBytes[i + 2]);

            bool isValidASCII = true;
            // ensure that the byte is a valid ascii character (0-9, A-F, a-f)
            if (b < 48) isValidASCII = false;
            if (57 < b && b < 65) isValidASCII = false;
            if (70 < b && b < 97) isValidASCII = false;
            if (102 < b) isValidASCII = false; //bytes(hex"");

            // If string contains invalid ASCII characters, revert()
            if (!isValidASCII) revert(revertMsg);

            // find the offset from ascii encoding to the nibble representation.
            if (b < 65) {
                // 0-9
                asciiOffset = 48;
            } else if (70 < b) {
                // a-f
                asciiOffset = 87;
            } else {
                // A-F
                asciiOffset = 55;
            }

            // store left nibble on even iterations, then store byte on odd ones.
            if (i % 2 == 0) {
                nibble = b - asciiOffset;
            } else {
                accountAddressBytes[(i - 1) / 2] = (
                bytes1(16 * nibble + (b - asciiOffset))
                );
            }
        }

        // pack up the fixed-size byte array and cast it to accountAddress.
        bytes memory packed = abi.encodePacked(accountAddressBytes);
        assembly {
            accountAddress := mload(add(packed, 20))
        }

        // return false in the event the account conversion returned null address.
        if (accountAddress == address(0)) {
            // ensure that provided address is not also the null address first.
            for (uint256 i = 2; i < accountBytes.length; i++)
                require(accountBytes[i] == hex"30", revertMsg);
        }
    }
}