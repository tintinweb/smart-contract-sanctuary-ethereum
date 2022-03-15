// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File contracts/interfaces/IDelegateFunction.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

/**
 *   @title Manages the state of an accounts delegation settings.
 *   Allows for various methods of validation as well as enabling
 *   different system functions to be delegated to different accounts
 */
interface IDelegateFunction {
    /// @notice Stores votes and rewards delegation mapping in DelegateFunction
    struct DelegateMapView {
        bytes32 functionId;
        address otherParty;
        bool mustRelinquish;
        bool pending;
    }

    /// @notice Denotes the type of signature being submitted to contracts that support multiple
    enum SignatureType {
        INVALID,
        // Specifically signTypedData_v4
        EIP712,
        // Specifically personal_sign
        ETHSIGN
    }

    struct AllowedFunctionSet {
        bytes32 id;
    }

    struct FunctionsListPayload {
        bytes32[] sets;
        uint256 nonce;
    }

    struct DelegatePayload {
        DelegateMap[] sets;
        uint256 nonce;
    }

    struct DelegateMap {
        bytes32 functionId;
        address otherParty;
        bool mustRelinquish;
    }

    struct Destination {
        address otherParty;
        bool mustRelinquish;
        bool pending;
    }

    struct DelegatedTo {
        address originalParty;
        bytes32 functionId;
    }

    event AllowedFunctionsSet(AllowedFunctionSet[] functions);
    event PendingDelegationAdded(address from, address to, bytes32 functionId, bool mustRelinquish);
    event PendingDelegationRemoved(
        address from,
        address to,
        bytes32 functionId,
        bool mustRelinquish
    );
    event DelegationRemoved(address from, address to, bytes32 functionId, bool mustRelinquish);
    event DelegationRelinquished(address from, address to, bytes32 functionId, bool mustRelinquish);
    event DelegationAccepted(address from, address to, bytes32 functionId, bool mustRelinquish);
    event DelegationRejected(address from, address to, bytes32 functionId, bool mustRelinquish);

    /// @notice Get the current nonce a contract wallet should use
    /// @param account Account to query
    /// @return nonce Nonce that should be used for next call
    function contractWalletNonces(address account) external returns (uint256 nonce);

    /// @notice Get an accounts current delegations
    /// @dev These may be in a pending state
    /// @param from Account that is delegating functions away
    /// @return maps List of delegations in various states of approval
    function getDelegations(address from) external view returns (DelegateMapView[] memory maps);

    /// @notice Get an accounts delegation of a specific function
    /// @dev These may be in a pending state
    /// @param from Account that is the delegation functions away
    /// @return map Delegation info
    function getDelegation(address from, bytes32 functionId)
        external
        view
        returns (DelegateMapView memory map);

    /// @notice Initiate delegation of one or more system functions to different account(s)
    /// @param sets Delegation instructions for the contract to initiate
    function delegate(DelegateMap[] memory sets) external;

    /// @notice Initiate delegation on behalf of a contract that supports ERC1271
    /// @param contractAddress Address of the ERC1271 contract used to verify the given signature
    /// @param delegatePayload Sets of DelegateMap objects
    /// @param signature Signature data
    /// @param signatureType Type of signature used (EIP712|EthSign)
    function delegateWithEIP1271(
        address contractAddress,
        DelegatePayload memory delegatePayload,
        bytes memory signature,
        SignatureType signatureType
    ) external;

    /// @notice Accept one or more delegations from another account
    /// @param incoming Delegation details being accepted
    function acceptDelegation(DelegatedTo[] calldata incoming) external;

    /// @notice Remove one or more delegation that you have previously setup
    function removeDelegation(bytes32[] calldata functionIds) external;

    /// @notice Remove one or more delegations that you have previously setup on behalf of a contract supporting EIP1271
    /// @param contractAddress Address of the ERC1271 contract used to verify the given signature
    /// @param functionsListPayload Sets of FunctionListPayload objects ({sets: bytes32[]})
    /// @param signature Signature data
    /// @param signatureType Type of signature used (EIP712|EthSign)
    function removeDelegationWithEIP1271(
        address contractAddress,
        FunctionsListPayload calldata functionsListPayload,
        bytes memory signature,
        SignatureType signatureType
    ) external;

    /// @notice Reject one or more delegations being sent to you
    /// @param rejections Delegations to reject
    function rejectDelegation(DelegatedTo[] calldata rejections) external;

    /// @notice Remove one or more delegations that you have previously accepted
    function relinquishDelegation(DelegatedTo[] calldata relinquish) external;

    /// @notice Cancel one or more delegations you have setup but that has not yet been accepted
    /// @param functionIds System functions you wish to retain control of
    function cancelPendingDelegation(bytes32[] calldata functionIds) external;

    /// @notice Cancel one or more delegations you have setup on behalf of a contract that supported EIP1271, but that has not yet been accepted
    /// @param contractAddress Address of the ERC1271 contract used to verify the given signature
    /// @param functionsListPayload Sets of FunctionListPayload objects ({sets: bytes32[]})
    /// @param signature Signature data
    /// @param signatureType Type of signature used (EIP712|EthSign)
    function cancelPendingDelegationWithEIP1271(
        address contractAddress,
        FunctionsListPayload calldata functionsListPayload,
        bytes memory signature,
        SignatureType signatureType
    ) external;

    /// @notice Add to the list of system functions that are allowed to be delegated
    /// @param functions New system function ids
    function setAllowedFunctions(AllowedFunctionSet[] calldata functions) external;
}

// File contracts/fxPortal/IFxStateSender.sol

pragma solidity >=0.6.0;

interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

// File contracts/interfaces/events/IEventSender.sol

pragma solidity >=0.6.11;

interface IEventSender {
    event DestinationsSet(address fxStateSender, address destinationOnL2);
    event EventSendSet(bool eventSendSet);

    /// @notice Configuration entity for sending events to Governance layer
    struct Destinations {
        IFxStateSender fxStateSender;
        address destinationOnL2;
    }

    /// @notice Configure the Polygon state sender root and destination for messages sent
    /// @param fxStateSender Address of Polygon State Sender Root contract
    /// @param destinationOnL2 Destination address of events sent. Should be our Event Proxy
    function setDestinations(address fxStateSender, address destinationOnL2) external;

    /// @notice Enables or disables the sending of events
    function setEventSend(bool eventSendSet) external;
}

// File contracts/interfaces/events/EventSender.sol

pragma solidity 0.6.11;

/// @title Base contract for sending events to our Governance layer
abstract contract EventSender is IEventSender {
    bool public eventSend;
    Destinations public destinations;

    modifier onEventSend() {
        // Only send the event when enabled
        if (eventSend) {
            _;
        }
    }

    modifier onlyEventSendControl() {
        // Give the implementing contract control over permissioning
        require(canControlEventSend(), "CANNOT_CONTROL_EVENTS");
        _;
    }

    /// @notice Configure the Polygon state sender root and destination for messages sent
    /// @param fxStateSender Address of Polygon State Sender Root contract
    /// @param destinationOnL2 Destination address of events sent. Should be our Event Proxy
    function setDestinations(address fxStateSender, address destinationOnL2)
        external
        virtual
        override
        onlyEventSendControl
    {
        require(fxStateSender != address(0), "INVALID_FX_ADDRESS");
        require(destinationOnL2 != address(0), "INVALID_DESTINATION_ADDRESS");

        destinations.fxStateSender = IFxStateSender(fxStateSender);
        destinations.destinationOnL2 = destinationOnL2;

        emit DestinationsSet(fxStateSender, destinationOnL2);
    }

    /// @notice Enables or disables the sending of events
    function setEventSend(bool eventSendSet) external virtual override onlyEventSendControl {
        eventSend = eventSendSet;

        emit EventSendSet(eventSendSet);
    }

    /// @notice Determine permissions for controlling event sending
    /// @dev Should not revert, just return false
    function canControlEventSend() internal view virtual returns (bool);

    /// @notice Send event data to Governance layer
    function sendEvent(bytes memory data) internal virtual {
        require(address(destinations.fxStateSender) != address(0), "ADDRESS_NOT_SET");
        require(destinations.destinationOnL2 != address(0), "ADDRESS_NOT_SET");

        destinations.fxStateSender.sendMessageToChild(destinations.destinationOnL2, data);
    }
}

// File contracts/interfaces/IERC1271.sol

// Based on OpenZeppelin Contracts v4.4.0 (interfaces/IERC1271.sol)

pragma solidity 0.6.11;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue);
}

// File @openzeppelin/contracts/cryptography/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

pragma solidity >=0.6.2 <0.8.0;

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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
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
        return
            functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// File @openzeppelin/contracts-upgradeable/proxy/[email protected]

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

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
        require(
            _initializing || _isConstructor() || !_initialized,
            "Initializable: contract is already initialized"
        );

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

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/access/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

    uint256[49] private __gap;
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// File @openzeppelin/contracts-upgradeable/math/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File contracts/delegation/DelegateFunction.sol

pragma solidity 0.6.11;

// solhint-disable var-name-mixedcase
contract DelegateFunction is
    IDelegateFunction,
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    EventSender
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    using SafeMathUpgradeable for uint256;
    using ECDSA for bytes32;

    bytes4 public constant EIP1271_MAGICVALUE = 0x1626ba7e;

    string public constant EIP191_HEADER = "\x19\x01";

    bytes32 public immutable EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 public immutable DELEGATE_PAYLOAD_TYPEHASH =
        keccak256(
            "DelegatePayload(uint256 nonce,DelegateMap[] sets)DelegateMap(bytes32 functionId,address otherParty,bool mustRelinquish)"
        );

    bytes32 public immutable DELEGATE_MAP_TYPEHASH =
        keccak256("DelegateMap(bytes32 functionId,address otherParty,bool mustRelinquish)");

    bytes32 public immutable FUNCTIONS_LIST_PAYLOAD_TYPEHASH =
        keccak256("FunctionsListPayload(uint256 nonce,bytes32[] sets)");

    /// @notice Event sent to Governance layer when a user has enabled delegation for voting or rewards
    struct DelegationEnabled {
        bytes32 eventSig;
        address from;
        address to;
        bytes32 functionId;
    }

    /// @notice Event sent to Governance layer when a user has disabled their delegation for voting or rewards
    struct DelegationDisabled {
        bytes32 eventSig;
        address from;
        address to;
        bytes32 functionId;
    }

    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private CACHED_EIP712_DOMAIN_SEPARATOR;
    uint256 private CACHED_CHAIN_ID;

    bytes32 public constant DOMAIN_NAME = keccak256("Tokemak Delegate Function");
    bytes32 public constant DOMAIN_VERSION = keccak256("1");

    /// @dev Stores the users next valid vote nonce
    mapping(address => uint256) public override contractWalletNonces;

    EnumerableSetUpgradeable.Bytes32Set private allowedFunctions;

    //from => functionId => (otherParty, mustRelinquish, functionId)
    mapping(address => mapping(bytes32 => Destination)) private delegations;

    // account => functionId => number of delegations
    mapping(address => mapping(bytes32 => uint256)) public numDelegationsTo;

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();

        CACHED_CHAIN_ID = _getChainID();
        CACHED_EIP712_DOMAIN_SEPARATOR = _buildDomainSeparator();
    }

    function getDelegations(address from)
        external
        view
        override
        returns (DelegateMapView[] memory maps)
    {
        uint256 numOfFunctions = allowedFunctions.length();
        maps = new DelegateMapView[](numOfFunctions);
        for (uint256 ix = 0; ix < numOfFunctions; ix++) {
            bytes32 functionId = allowedFunctions.at(ix);
            Destination memory existingDestination = delegations[from][functionId];
            if (existingDestination.otherParty != address(0)) {
                maps[ix] = DelegateMapView({
                    functionId: functionId,
                    otherParty: existingDestination.otherParty,
                    mustRelinquish: existingDestination.mustRelinquish,
                    pending: existingDestination.pending
                });
            }
        }
    }

    function getDelegation(address from, bytes32 functionId)
        external
        view
        override
        returns (DelegateMapView memory map)
    {
        Destination memory existingDestination = delegations[from][functionId];
        map = DelegateMapView({
            functionId: functionId,
            otherParty: existingDestination.otherParty,
            mustRelinquish: existingDestination.mustRelinquish,
            pending: existingDestination.pending
        });
    }

    function delegate(DelegateMap[] memory sets) external override whenNotPaused {
        _delegate(msg.sender, sets);
    }

    function delegateWithEIP1271(
        address contractAddress,
        DelegatePayload memory delegatePayload,
        bytes memory signature,
        SignatureType signatureType
    ) external override whenNotPaused {
        bytes32 delegatePayloadHash = _hashDelegate(delegatePayload, signatureType);
        _verifyNonce(contractAddress, delegatePayload.nonce);

        _verifyIERC1271Signature(contractAddress, delegatePayloadHash, signature);

        _delegate(contractAddress, delegatePayload.sets);
    }

    function acceptDelegation(DelegatedTo[] calldata incoming) external override whenNotPaused {
        uint256 length = incoming.length;
        require(length > 0, "NO_DATA");

        for (uint256 ix = 0; ix < length; ix++) {
            DelegatedTo calldata deleg = incoming[ix];
            Destination storage destination = delegations[deleg.originalParty][deleg.functionId];
            require(destination.otherParty == msg.sender, "NOT_ASSIGNED");
            require(destination.pending, "ALREADY_ACCEPTED");
            require(
                delegations[msg.sender][deleg.functionId].otherParty == address(0),
                "ALREADY_DELEGATOR"
            );

            destination.pending = false;
            numDelegationsTo[destination.otherParty][deleg.functionId] = numDelegationsTo[
                destination.otherParty
            ][deleg.functionId].add(1);

            bytes memory data = abi.encode(
                DelegationEnabled({
                    eventSig: "DelegationEnabled",
                    from: deleg.originalParty,
                    to: msg.sender,
                    functionId: deleg.functionId
                })
            );

            sendEvent(data);

            emit DelegationAccepted(
                deleg.originalParty,
                msg.sender,
                deleg.functionId,
                destination.mustRelinquish
            );
        }
    }

    function removeDelegationWithEIP1271(
        address contractAddress,
        FunctionsListPayload calldata functionsListPayload,
        bytes memory signature,
        SignatureType signatureType
    ) external override whenNotPaused {
        bytes32 functionsListPayloadHash = _hashFunctionsList(functionsListPayload, signatureType);

        _verifyNonce(contractAddress, functionsListPayload.nonce);

        _verifyIERC1271Signature(contractAddress, functionsListPayloadHash, signature);

        _removeDelegations(contractAddress, functionsListPayload.sets);
    }

    function removeDelegation(bytes32[] calldata functionIds) external override whenNotPaused {
        _removeDelegations(msg.sender, functionIds);
    }

    function rejectDelegation(DelegatedTo[] calldata rejections) external override whenNotPaused {
        uint256 length = rejections.length;
        require(length > 0, "NO_DATA");

        for (uint256 ix = 0; ix < length; ix++) {
            DelegatedTo memory pending = rejections[ix];
            _rejectDelegation(msg.sender, pending);
        }
    }

    function relinquishDelegation(DelegatedTo[] calldata relinquish)
        external
        override
        whenNotPaused
    {
        uint256 length = relinquish.length;
        require(length > 0, "NO_DATA");

        for (uint256 ix = 0; ix < length; ix++) {
            _relinquishDelegation(msg.sender, relinquish[ix]);
        }
    }

    function cancelPendingDelegation(bytes32[] calldata functionIds)
        external
        override
        whenNotPaused
    {
        _cancelPendingDelegations(msg.sender, functionIds);
    }

    function cancelPendingDelegationWithEIP1271(
        address contractAddress,
        FunctionsListPayload calldata functionsListPayload,
        bytes memory signature,
        SignatureType signatureType
    ) external override whenNotPaused {
        bytes32 functionsListPayloadHash = _hashFunctionsList(functionsListPayload, signatureType);

        _verifyNonce(contractAddress, functionsListPayload.nonce);

        _verifyIERC1271Signature(contractAddress, functionsListPayloadHash, signature);

        _cancelPendingDelegations(contractAddress, functionsListPayload.sets);
    }

    function setAllowedFunctions(AllowedFunctionSet[] calldata functions)
        external
        override
        onlyOwner
    {
        uint256 length = functions.length;
        require(functions.length > 0, "NO_DATA");

        for (uint256 ix = 0; ix < length; ix++) {
            require(allowedFunctions.add(functions[ix].id), "ADD_FAIL");
        }

        emit AllowedFunctionsSet(functions);
    }

    function canControlEventSend() internal view override returns (bool) {
        return msg.sender == owner();
    }

    function _delegate(address from, DelegateMap[] memory sets) internal {
        uint256 length = sets.length;
        require(length > 0, "NO_DATA");

        for (uint256 ix = 0; ix < length; ix++) {
            DelegateMap memory set = sets[ix];

            require(allowedFunctions.contains(set.functionId), "INVALID_FUNCTION");
            require(set.otherParty != address(0), "INVALID_DESTINATION");
            require(set.otherParty != from, "NO_SELF");
            require(numDelegationsTo[from][set.functionId] == 0, "ALREADY_DELEGATEE");

            //Remove any existing delegation
            Destination memory existingDestination = delegations[from][set.functionId];
            if (existingDestination.otherParty != address(0)) {
                _removeDelegation(from, set.functionId, existingDestination);
            }

            delegations[from][set.functionId] = Destination({
                otherParty: set.otherParty,
                mustRelinquish: set.mustRelinquish,
                pending: true
            });

            emit PendingDelegationAdded(from, set.otherParty, set.functionId, set.mustRelinquish);
        }
    }

    function _rejectDelegation(address to, DelegatedTo memory pending) private {
        Destination memory existingDestination = delegations[pending.originalParty][
            pending.functionId
        ];
        require(existingDestination.otherParty != address(0), "NOT_SETUP");
        require(existingDestination.otherParty == to, "NOT_OTHER_PARTIES");
        require(existingDestination.pending, "ALREADY_ACCEPTED");

        delete delegations[pending.originalParty][pending.functionId];

        emit DelegationRejected(
            pending.originalParty,
            to,
            pending.functionId,
            existingDestination.mustRelinquish
        );
    }

    function _removeDelegations(address from, bytes32[] calldata functionIds) private {
        uint256 length = functionIds.length;
        require(length > 0, "NO_DATA");

        for (uint256 ix = 0; ix < length; ix++) {
            Destination memory existingDestination = delegations[from][functionIds[ix]];
            _removeDelegation(from, functionIds[ix], existingDestination);
        }
    }

    function _removeDelegation(
        address from,
        bytes32 functionId,
        Destination memory existingDestination
    ) private {
        require(existingDestination.otherParty != address(0), "NOT_SETUP");
        require(!existingDestination.mustRelinquish, "EXISTING_MUST_RELINQUISH");

        delete delegations[from][functionId];

        if (existingDestination.pending) {
            emit PendingDelegationRemoved(
                from,
                existingDestination.otherParty,
                functionId,
                existingDestination.mustRelinquish
            );
        } else {
            numDelegationsTo[existingDestination.otherParty][functionId] = numDelegationsTo[
                existingDestination.otherParty
            ][functionId].sub(1);
            _sendDisabledEvent(from, existingDestination.otherParty, functionId);

            emit DelegationRemoved(
                from,
                existingDestination.otherParty,
                functionId,
                existingDestination.mustRelinquish
            );
        }
    }

    function _relinquishDelegation(address to, DelegatedTo calldata relinquish) private {
        Destination memory existingDestination = delegations[relinquish.originalParty][
            relinquish.functionId
        ];
        require(existingDestination.otherParty != address(0), "NOT_SETUP");
        require(existingDestination.otherParty == to, "NOT_OTHER_PARTIES");
        require(!existingDestination.pending, "NOT_YET_ACCEPTED");

        numDelegationsTo[existingDestination.otherParty][relinquish.functionId] = numDelegationsTo[
            existingDestination.otherParty
        ][relinquish.functionId].sub(1);
        delete delegations[relinquish.originalParty][relinquish.functionId];

        _sendDisabledEvent(relinquish.originalParty, to, relinquish.functionId);

        emit DelegationRelinquished(
            relinquish.originalParty,
            to,
            relinquish.functionId,
            existingDestination.mustRelinquish
        );
    }

    function _sendDisabledEvent(
        address from,
        address to,
        bytes32 functionId
    ) private {
        bytes memory data = abi.encode(
            DelegationDisabled({
                eventSig: "DelegationDisabled",
                from: from,
                to: to,
                functionId: functionId
            })
        );

        sendEvent(data);
    }

    function _cancelPendingDelegations(address from, bytes32[] calldata functionIds) private {
        uint256 length = functionIds.length;
        require(length > 0, "NO_DATA");

        for (uint256 ix = 0; ix < length; ix++) {
            _cancelPendingDelegation(from, functionIds[ix]);
        }
    }

    function _cancelPendingDelegation(address from, bytes32 functionId) private {
        require(allowedFunctions.contains(functionId), "INVALID_FUNCTION");

        Destination memory existingDestination = delegations[from][functionId];
        require(existingDestination.otherParty != address(0), "NO_PENDING");
        require(existingDestination.pending, "NOT_PENDING");

        delete delegations[from][functionId];

        emit PendingDelegationRemoved(
            from,
            existingDestination.otherParty,
            functionId,
            existingDestination.mustRelinquish
        );
    }

    function _hashDelegate(DelegatePayload memory delegatePayload, SignatureType signatureType)
        private
        view
        returns (bytes32)
    {
        bytes32 x = keccak256(
            abi.encodePacked(
                EIP191_HEADER,
                _domainSeparatorV4(),
                _hashDelegatePayload(delegatePayload)
            )
        );

        if (signatureType == SignatureType.ETHSIGN) {
            x = x.toEthSignedMessageHash();
        }

        return x;
    }

    function _hashDelegatePayload(DelegatePayload memory delegatePayload)
        private
        view
        returns (bytes32)
    {
        bytes32[] memory encodedSets = new bytes32[](delegatePayload.sets.length);
        for (uint256 ix = 0; ix < delegatePayload.sets.length; ix++) {
            encodedSets[ix] = _hashDelegateMap(delegatePayload.sets[ix]);
        }

        return
            keccak256(
                abi.encode(
                    DELEGATE_PAYLOAD_TYPEHASH,
                    delegatePayload.nonce,
                    keccak256(abi.encodePacked(encodedSets))
                )
            );
    }

    function _hashDelegateMap(DelegateMap memory delegateMap) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    DELEGATE_MAP_TYPEHASH,
                    delegateMap.functionId,
                    delegateMap.otherParty,
                    delegateMap.mustRelinquish
                )
            );
    }

    function _hashFunctionsList(
        FunctionsListPayload calldata functionsListPayload,
        SignatureType signatureType
    ) private view returns (bytes32) {
        bytes32 x = keccak256(
            abi.encodePacked(
                EIP191_HEADER,
                _domainSeparatorV4(),
                keccak256(
                    abi.encode(
                        FUNCTIONS_LIST_PAYLOAD_TYPEHASH,
                        functionsListPayload.nonce,
                        keccak256(abi.encodePacked(functionsListPayload.sets))
                    )
                )
            )
        );

        if (signatureType == SignatureType.ETHSIGN) {
            x = x.toEthSignedMessageHash();
        }

        return x;
    }

    function _verifyIERC1271Signature(
        address contractAddress,
        bytes32 payloadHash,
        bytes memory signature
    ) private view {
        try IERC1271(contractAddress).isValidSignature(payloadHash, signature) returns (
            bytes4 result
        ) {
            require(result == EIP1271_MAGICVALUE, "INVALID_SIGNATURE");
        } catch {
            revert("INVALID_SIGNATURE_VALIDATION");
        }
    }

    function _verifyNonce(address account, uint256 nonce) private {
        require(contractWalletNonces[account] == nonce, "INVALID_NONCE");
        // Ensure the message cannot be replayed
        contractWalletNonces[account] = nonce.add(1);
    }

    function _getChainID() private pure returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (_getChainID() == CACHED_CHAIN_ID) {
            return CACHED_EIP712_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    DOMAIN_NAME,
                    DOMAIN_VERSION,
                    _getChainID(),
                    address(this)
                )
            );
    }
}