// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import {XAppConnectionClient} from './optics/xapp-contracts/XAppConnectionClient.sol';
import {Router} from './optics/xapp-contracts/Router.sol';
import './ToucanCrosschainMessengerStorage.sol';

contract ToucanCrosschainMessenger is ToucanCrosschainMessengerStorage, Router {
    // ============ Events ============

    event BridgeRequestReceived(
        uint32 indexed originDomain,
        uint32 toDomain,
        address indexed bridger,
        address indexed token,
        uint256 amount,
        bytes32 requesthash
    );
    event BridgeRequestSent(
        uint32 originDomain,
        uint32 indexed toDomain,
        address indexed bridger,
        address indexed token,
        uint256 amount,
        uint256 nonce,
        bytes32 requesthash
    );

    // ============ Constructor ============

    constructor(address _xAppConnectionManager) {
        __XAppConnectionClient_initialize(_xAppConnectionManager);
    }

    // ============ Handle message functions ============

    /**
     * @notice Receive messages sent via Optics from other remote xApp Routers;
     * parse the contents of the message and enact the message's effects on the local chain
     * @dev Called by an Optics Replica contract while processing a message sent via Optics
     * @param _origin The domain the message is coming from
     * @param _sender The address the message is coming from
     * @param _message The message in the form of raw bytes
     */
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external override onlyReplica onlyRemoteRouter(_origin, _sender) {
        // route message to appropriate _handle function
        // based on what type of message is encoded
        (
            address bridger,
            address token,
            uint256 amount,
            uint32 toDomain,
            bytes32 requestHash
        ) = abi.decode(_message, (address, address, uint256, uint32, bytes32));
        require(
            requests[requestHash].requestType ==
                BridgeRequestType.NOT_REGISTERED,
            'Bridge Request Executed'
        );
        requests[requestHash] = BridgeRequest(
            false,
            BridgeRequestType.RECEIVED
        );
        emit BridgeRequestReceived(
            _origin,
            toDomain,
            bridger,
            token,
            amount,
            requestHash
        );
    }

    // ============ Dispatch message functions ============

    /**
     * @notice Send a message of "Type A" to a remote xApp Router via Optics;
     * this message is called to take some action in the cross-chain context
     * @param _destinationDomain The domain to send the message to
     */
    function sendMessage(
        uint32 _destinationDomain,
        address _token,
        uint256 _amount
    ) external {
        // get the xApp Router at the destinationDomain
        bytes32 _remoteRouterAddress = _mustHaveRemote(_destinationDomain);
        uint256 currentNonce = nonce[msg.sender]++;
        bytes32 requestHash = _generateRequestHash(
            _destinationDomain,
            msg.sender,
            _token,
            _amount,
            currentNonce
        );
        // encode a message to send to the remote xApp Router
        requests[requestHash] = BridgeRequest(false, BridgeRequestType.SENT);
        bytes memory _outboundMessage = abi.encode(
            msg.sender,
            _token,
            _amount,
            _destinationDomain,
            requestHash
        );
        // send the message to the xApp Router
        _home().dispatch(
            _destinationDomain,
            _remoteRouterAddress,
            _outboundMessage
        );
        emit BridgeRequestSent(
            _localDomain(),
            _destinationDomain,
            msg.sender,
            _token,
            _amount,
            currentNonce,
            requestHash
        );
    }

    function _generateRequestHash(
        uint32 _destinationDomain,
        address _account,
        address _token,
        uint256 _amount,
        uint256 _nonce
    ) internal view returns (bytes32 _requestHash) {
        return
            keccak256(
                abi.encodePacked(
                    DOMAIN_SEPARATOR,
                    _destinationDomain,
                    _account,
                    _token,
                    _amount,
                    _nonce
                )
            );
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

// ============ External Imports ============
import {IHome} from '../interfaces/IHome.sol';
import {IXAppConnectionManager} from '../interfaces/IXAppConnectionManager.sol';
import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

abstract contract XAppConnectionClient is OwnableUpgradeable {
    // ============ Mutable Storage ============

    IXAppConnectionManager public xAppConnectionManager;
    uint256[49] private __GAP; // gap for upgrade safety

    // ============ Modifiers ============

    /**
     * @notice Only accept messages from an Optics Replica contract
     */
    modifier onlyReplica() {
        require(_isReplica(msg.sender), '!replica');
        _;
    }

    // ======== Initializer =========

    function __XAppConnectionClient_initialize(address _xAppConnectionManager)
        internal
        initializer
    {
        xAppConnectionManager = IXAppConnectionManager(_xAppConnectionManager);
        __Ownable_init();
    }

    // ============ External functions ============

    /**
     * @notice Modify the contract the xApp uses to validate Replica contracts
     * @param _xAppConnectionManager The address of the xAppConnectionManager contract
     */
    function setXAppConnectionManager(address _xAppConnectionManager)
        external
        onlyOwner
    {
        xAppConnectionManager = IXAppConnectionManager(_xAppConnectionManager);
    }

    // ============ Internal functions ============

    /**
     * @notice Get the local Home contract from the xAppConnectionManager
     * @return The local Home contract
     */
    function _home() internal view returns (IHome) {
        return xAppConnectionManager.home();
    }

    /**
     * @notice Determine whether _potentialReplcia is an enrolled Replica from the xAppConnectionManager
     * @return True if _potentialReplica is an enrolled Replica
     */
    function _isReplica(address _potentialReplica)
        internal
        view
        returns (bool)
    {
        return xAppConnectionManager.isReplica(_potentialReplica);
    }

    /**
     * @notice Get the local domain from the xAppConnectionManager
     * @return The local domain
     */
    function _localDomain() internal view virtual returns (uint32) {
        return xAppConnectionManager.localDomain();
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

// ============ Internal Imports ============
import {XAppConnectionClient} from './XAppConnectionClient.sol';
// ============ External Imports ============
import {IMessageRecipient} from '../interfaces/IMessageRecipient.sol';

abstract contract Router is XAppConnectionClient, IMessageRecipient {
    // ============ Mutable Storage ============

    mapping(uint32 => bytes32) public remotes;
    uint256[49] private __GAP; // gap for upgrade safety

    // ============ Modifiers ============

    /**
     * @notice Only accept messages from a remote Router contract
     * @param _origin The domain the message is coming from
     * @param _router The address the message is coming from
     */
    modifier onlyRemoteRouter(uint32 _origin, bytes32 _router) {
        require(_isRemoteRouter(_origin, _router), '!remote router');
        _;
    }

    // ============ External functions ============

    /**
     * @notice Register the address of a Router contract for the same xApp on a remote chain
     * @param _domain The domain of the remote xApp Router
     * @param _router The address of the remote xApp Router
     */
    function enrollRemoteRouter(uint32 _domain, bytes32 _router)
        external
        onlyOwner
    {
        remotes[_domain] = _router;
    }

    // ============ Virtual functions ============

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes memory _message
    ) external virtual override;

    // ============ Internal functions ============
    /**
     * @notice Return true if the given domain / router is the address of a remote xApp Router
     * @param _domain The domain of the potential remote xApp Router
     * @param _router The address of the potential remote xApp Router
     */
    function _isRemoteRouter(uint32 _domain, bytes32 _router)
        internal
        view
        returns (bool)
    {
        return remotes[_domain] == _router;
    }

    /**
     * @notice Assert that the given domain has a xApp Router registered and return its address
     * @param _domain The domain of the chain for which to get the xApp Router
     * @return _remote The address of the remote xApp Router on _domain
     */
    function _mustHaveRemote(uint32 _domain)
        internal
        view
        returns (bytes32 _remote)
    {
        _remote = remotes[_domain];
        require(_remote != bytes32(0), '!remote');
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import {XAppConnectionClient} from './optics/xapp-contracts/XAppConnectionClient.sol';
import {Router} from './optics/xapp-contracts/Router.sol';

/// @dev Separate storage contract to improve upgrade safety
contract ToucanCrosschainMessengerStorage {
    enum BridgeRequestType {
        NOT_REGISTERED, // 0
        SENT, // 1
        RECEIVED // 2
    }

    string public constant VERSION = '0.1.0';
    bytes32 public immutable DOMAIN_SEPARATOR;

    struct BridgeRequest {
        bool isReverted;
        BridgeRequestType requestType;
    }
    mapping(bytes32 => BridgeRequest) public requests;
    mapping(address => uint256) public nonce;

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    'EIP712Domain(string name, string version,uint256 chainId)'
                ),
                'ToucanCrosschainMessengerStorage',
                VERSION,
                chainId
            )
        );
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

interface IHome {
    /**
     * @notice Dispatch the message it to the destination domain & recipient
     * @dev Format the message, insert its hash into Merkle tree,
     * enqueue the new Merkle root, and emit `Dispatch` event with message information.
     * @param _destinationDomain Domain of destination chain
     * @param _recipientAddress Address of recipient on destination chain as bytes32
     * @param _messageBody Raw bytes content of message
     */
    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes memory _messageBody
    ) external;

    /**
     * @notice Hash of Home domain concatenated with "OPTICS"
     */
    function homeDomainHash() external view returns (bytes32);

    /**
     * @notice retunrs available nonce for the domain
     */
    function nonces(uint32 _domain) external view returns (uint32);

    /**
     * @notice retunrs Maximum bytes per message
     */
    function MAX_MESSAGE_BODY_BYTES() external view returns (uint256);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import '../interfaces/IHome.sol';

interface IXAppConnectionManager {
    /**
     * @notice Query local domain from Home
     * @return local domain
     */
    function localDomain() external view returns (uint32);

    // ============ Public Functions ============

    /**
     * @notice Returns Home contract
     * @return IHome home contract
     */
    function home() external view returns (IHome);

    /**
     * @notice Check whether _replica is enrolled
     * @param _replica the replica to get domain id of
     * @return domain domain id
     */
    function replicaToDomain(address _replica) external view returns (uint32);

    /**
     * @notice Check whether _replica is enrolled
     * @param _domain the domain to check replica for
     * @return replica replica address
     */
    function domainToReplica(uint32 _domain) external view returns (address);

    /**
     * @notice Check whether _replica is enrolled
     * @param _replica the replica to check for enrollment
     * @return TRUE iff _replica is enrolled
     */
    function isReplica(address _replica) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
    uint256[49] private __gap;
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

interface IMessageRecipient {
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes memory _message
    ) external;
}