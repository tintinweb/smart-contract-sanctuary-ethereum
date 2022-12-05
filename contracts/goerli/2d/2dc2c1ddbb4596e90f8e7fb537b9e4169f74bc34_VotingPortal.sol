// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {CrossChainUtils} from 'ghost-crosschain-infra/contracts/CrossChainUtils.sol';

library CrossChainMandateUtils {
  enum AccessControl {
    Level_null, // to not use 0
    Level_1, // LEVEL_1 - short executor before, listing assets, changes of assets params, updates of the protocol etc
    Level_2 // LEVEL_2 - long executor before, mandate provider updates
  }
  // should fit into uint256 imo
  struct Payload {
    // our own id for the chain, rationality is optimize the space, because chainId by the standard can be uint256,
    //TODO: the limit of enum is 256, should we care about it, or we will never reach this point?
    CrossChainUtils.Chains chain;
    AccessControl accessLevel;
    address mandateProvider; // address which holds the logic to execute after success proposal voting
    uint40 payloadId; // number of the payload placed to mandateProvider, max is: ~10¹²
    uint40 __RESERVED; // reserved for some future needs
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library CrossChainUtils {
  enum Chains {
    Null_network, // to not use 0
    EthMainnet,
    Polygon,
    Avalanche,
    Harmony,
    Arbitrum,
    Fantom,
    Optimism,
    Goerli,
    AvalancheFuji,
    OptimismGoerli,
    PolygonMumbai,
    ArbitrumGoerli,
    FantomTestnet,
    HarmonyTestnet
  }
}

pragma solidity ^0.8.0;

import '../CrossChainUtils.sol';

/// @dev interface needed by the portals on the receiving side to be able to receive bridged messages
interface IBaseReceiverPortal {
  /**
   * @dev method called by CrossChainManager when a message has been confirmed
   * @param originSender address of the sender of the bridged message
   * @param originChainId id of the chain where the message originated
   * @param message bytes bridged containing the desired information
   */
  function receiveCrossChainMessage(
    address originSender,
    CrossChainUtils.Chains originChainId,
    bytes memory message
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {CrossChainUtils} from '../CrossChainUtils.sol';

interface ICrossChainForwarder {
  /**
   * @dev object storing the connected pair of bridge adapters, on current and destination chain
   * @param destinationBridgeAdapter address of the bridge adapter on the destination chain
   * @param currentChainBridgeAdapter address of the bridge adapter deployed on current network
   */
  struct ChainIdBridgeConfig {
    address destinationBridgeAdapter;
    address currentChainBridgeAdapter;
  }

  /**
   * @dev object with the necessary information to remove bridge adapters
   * @param bridgeAdapter address of the bridge adapter to remove
   * @param chainIds array of chain ids where the bridge adapter connects
   */
  struct BridgeAdapterToDisable {
    address bridgeAdapter;
    CrossChainUtils.Chains[] chainIds;
  }

  /**
   * @dev object storing the pair bridgeAdapter (current deployed chain) destination chain bridge adapter configuration
   * @param currentChainBridgeAdapter address of the bridge adapter deployed on current chain
   * @param destinationBridgeAdapter address of the bridge adapter on the destination chain
   * @param dstChainId id of the destination chain using our own nomenclature
   */
  struct BridgeAdapterConfigInput {
    address currentChainBridgeAdapter;
    address destinationBridgeAdapter;
    CrossChainUtils.Chains destinationChainId;
  }

  /**
   * @dev emitted when a bridge adapter failed to send a message
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter that failed (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param destinationChainId id of destination chain
   * @param message bytes intended to be bridged
   * @param returndata bytes with error information
   */
  event AdapterFailed(
    CrossChainUtils.Chains indexed destinationChainId,
    address indexed bridgeAdapter,
    address indexed destinationBridgeAdapter,
    bytes message,
    bytes returndata
  );

  /**
   * @dev emitted when a message is successfully forwarded through a bridge adapter
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter that failed (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param destinationChainId id of destination chain
   * @param message bytes intended to be bridged
   */
  event MessageForwarded(
    CrossChainUtils.Chains indexed destinationChainId,
    address indexed bridgeAdapter,
    address indexed destinationBridgeAdapter,
    bytes message
  );

  /**
   * @dev emitted when a bridge adapter has been added to the allowed list
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter added (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param allowed boolean indicating if the bridge adapter is allowed or disallowed
   */
  event BridgeAdapterUpdated(
    CrossChainUtils.Chains indexed destinationChainId,
    address indexed bridgeAdapter,
    address destinationBridgeAdapter,
    bool indexed allowed
  );

  /**
   * @dev emitted when a sender has been updated
   * @param sender address of the updated sender
   * @param isApproved boolean that indicates if the sender has been approved or removed
   */
  event SenderUpdated(address indexed sender, bool indexed isApproved);

  /// @dev method to get the current sent message nonce
  function currentNonce() external view returns (uint256);

  /**
   * @dev method to check if a message has been previously forwarded.
   * @param destinationChainId id of the destination chain where the message needs to be bridged
   * @param origin address where the message originates from
   * @param destination address where the message is intended for
   * @param message bytes that need to be bridged
   */
  function isMessageForwarded(
    CrossChainUtils.Chains destinationChainId,
    address origin,
    address destination,
    bytes memory message
  ) external view returns (bool);

  /**
   * @dev method called to initiate message forwarding to other networks.
   * @param destinationChainId id of the destination chain where the message needs to be bridged
   * @param destination address where the message is intended for
   * @param gasLimit gas cost on receiving side of the message
   * @param message bytes that need to be bridged
   */
  function forwardMessage(
    CrossChainUtils.Chains destinationChainId,
    address destination,
    uint256 gasLimit,
    bytes memory message
  ) external;

  /**
   * @dev method called to re forward a previously sent message.
   * @param destinationChainId id of the destination chain where the message needs to be bridged
   * @param origin address where the message originates from
   * @param destination address where the message is intended for
   * @param gasLimit gas cost on receiving side of the message
   * @param message bytes that need to be bridged
   */
  function retryMessage(
    CrossChainUtils.Chains destinationChainId,
    address origin,
    address destination,
    uint256 gasLimit,
    bytes memory message
  ) external;

  /**
   * @dev method to enable bridge adapters
   * @param bridgeAdapters array of new bridge adapter configurations
   */
  function enableBridgeAdapters(
    BridgeAdapterConfigInput[] memory bridgeAdapters
  ) external;

  /**
   * @dev method to disable bridge adapters
   * @param bridgeAdapters array of bridge adapter addresses to disable
   */
  function disableBridgeAdapters(
    BridgeAdapterToDisable[] memory bridgeAdapters
  ) external;

  /**
   * @dev method to remove sender addresses
   * @param senders list of addresses to remove
   */
  function removeSenders(address[] memory senders) external;

  /**
   * @dev method to approve new sender addresses
   * @param senders list of addresses to approve
   */
  function approveSenders(address[] memory senders) external;

  /**
   * @dev method to get all the bridge adapters of a chain
   * @param chainId id of the chain we want to get the adateprs from
   * @return an array of chain configurations where the bridge adapter can communicate
   */
  function getBridgeAdaptersByChain(
    CrossChainUtils.Chains chainId
  ) external view returns (ChainIdBridgeConfig[] memory);

  /**
   * @dev method to get if a sender is approved
   * @param sender address that we want to check if approved
   */
  function isSenderApproved(address sender) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ICrossChainForwarder.sol';
import './ICrossChainReceiver.sol';

interface ICrossChainManager is ICrossChainForwarder, ICrossChainReceiver {
  /**
   * @dev method called to initialize the proxy
   * @param owner address of the owner of the cross chain manager
   * @param guardian address of the guardian of the cross chain manager
   * @param clEmergencyOracle address of the chainlink emergency oracle
   * @param initialRequiredConfirmations number of confirmations the messages need to be accepted as valid
   * @param receiverBridgeAdaptersToAllow array of addresses of the bridge adapters that can receive messages
   * @param forwarderBridgeAdaptersToEnable array specifying for every bridgeAdapter, the destinations it can have
   * @param sendersToApprove array of addresses to allow as forwarders
   */
  function initialize(
    address owner,
    address guardian,
    address clEmergencyOracle,
    uint256 initialRequiredConfirmations,
    address[] memory receiverBridgeAdaptersToAllow,
    BridgeAdapterConfigInput[] memory forwarderBridgeAdaptersToEnable,
    address[] memory sendersToApprove
  ) external;

  /**
   * @dev method called to rescue tokens sent erroneously to the contract. Only callable by owner
   * @param erc20Token address of the token to rescue
   * @param to address to send the tokens
   * @param amount of tokens to rescue
   */
  function emergencyTokenTransfer(
    address erc20Token,
    address to,
    uint256 amount
  ) external;

  /**
   * @dev method called to rescue ether sent erroneously to the contract. Only callable by owner
   * @param to address to send the eth
   * @param amount of eth to rescue
   */
  function emergencyEtherTransfer(address to, uint256 amount) external;

  /**
  * @dev method to check if there is a new emergency state, indicated by chainlink emergency oracle.
         This method is callable by anyone as a new emergency will be determined by the oracle, and this way
         it will be easier / faster to enter into emergency.
  */
  function solveEmergency(
    uint256 newConfirmations,
    uint120 newValidityTimestamp,
    address[] memory receiverBridgeAdaptersToAllow,
    address[] memory receiverBridgeAdaptersToDisallow,
    address[] memory sendersToApprove,
    address[] memory sendersToRemove,
    BridgeAdapterConfigInput[] memory forwarderBridgeAdaptersToEnable,
    BridgeAdapterToDisable[] memory forwarderBridgeAdaptersToDisable
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {CrossChainUtils} from '../CrossChainUtils.sol';

interface ICrossChainReceiver {
  /**
   * @dev object that stores the internal information of the message
   * @param confirmations number of times that this message has been bridged
   * @param bridgedByAdapterNonce stores the nonce of when the message has been bridged by a determined bridge adapter
   * @param delivered boolean indicating if the bridged message has been delivered to the destination
   */
  struct InternalBridgedMessageStateWithoutAdapters {
    uint120 confirmations;
    uint120 firstBridgedAt;
    bool delivered;
  }
  /**
   * @dev object that stores the internal information of the message
   * @param confirmations number of times that this message has been bridged
   * @param bridgedByAdapterNonce stores the nonce of when the message has been bridged by a determined bridge adapter
   * @param delivered boolean indicating if the bridged message has been delivered to the destination
   * @param bridgedByAdapter list of bridge adapters that have bridged the message
   */
  struct InternalBridgedMessage {
    uint120 confirmations;
    uint120 firstBridgedAt;
    bool delivered;
    mapping(address => bool) bridgedByAdapter;
  }

  /**
   * @dev emitted when a message has reached the necessary number of confirmations
   * @param msgDestination address of consumer of the message
   * @param msgOrigin address where the message originated
   * @param message bytes confirmed
   */
  event MessageConfirmed(
    address indexed msgDestination,
    address indexed msgOrigin,
    bytes message
  );

  /**
   * @dev emitted when a message has been received successfully
   * @param internalId message id assigned on the manager, used for internal purposes: hash(to, from, message)
   * @param bridgeAdapter address of the bridge adapter who received the message (deployed on current network)
   * @param msgDestination address of consumer of the message
   * @param msgOrigin address where the message originated (CrossChainManager on origin chain)
   * @param message bytes bridged
   * @param confirmations number of current confirmations for this message
   */
  event MessageReceived(
    bytes32 internalId,
    address indexed bridgeAdapter,
    address indexed msgDestination,
    address indexed msgOrigin,
    bytes message,
    uint256 confirmations
  );

  /**
   * @dev emitted when a bridge adapter gets disallowed
   * @param brigeAdapter address of the disallowed bridge adapter
   * @param allowed boolean indicating if the bridge adapter has been allowed or disallowed
   */
  event ReceiverBridgeAdaptersUpdated(
    address indexed brigeAdapter,
    bool indexed allowed
  );

  /**
   * @dev emitted when number of confirmations needed to validate a message changes
   * @param newConfirmations number of new confirmations needed for a message to be valid
   */
  event ConfirmationsUpdated(uint256 newConfirmations);

  /**
   * @dev emitted when a new timestamp for invalidations gets set
   * @param invalidTimestamp timestamp to invalidate previous messages
   */
  event NewInvalidation(uint256 invalidTimestamp);

  /// @dev method to get the needed confirmations for a message to be accepted as valid
  function requiredConfirmations() external view returns (uint256);

  /// @dev method to get the timestamp from where the messages will be valid
  function validityTimestamp() external view returns (uint120);

  /**
   * @dev method to get if a bridge adapter is allowed
   * @param bridgeAdapter address of the brige adapter to check
   * @return boolean indicating if brige adapter is allowed
   */
  function isReceiverBridgeAdapterAllowed(address bridgeAdapter)
    external
    view
    returns (bool);

  /**
   * @dev  method to get the internal message information
   * @param internalId hash(originChain + payload) identifying the message internally
   * @return number of confirmations of internal message identified by internalId and the updated timestamp
   */
  function getInternalMessageState(bytes32 internalId)
    external
    view
    returns (InternalBridgedMessageStateWithoutAdapters memory);

  /**
   * @dev method to get if message has been received by bridge adapter
   * @param internalId id of the message as stored internally
   * @param bridgeAdapter address of the bridge adapter to check if it has bridged the message
   * return array of addresses
   */
  function isInternalMessageReceivedByAdapter(
    bytes32 internalId,
    address bridgeAdapter
  ) external view returns (bool);

  /**
   * @dev method to set a new timestamp from where the messages will be valid.
   * @param newValidityTimestamp timestamp where all the previous unconfirmed messages must be invalidated.
   */
  function updateMessagesValidityTimestamp(uint120 newValidityTimestamp)
    external;

  /**
   * @dev method to update the number of confirmations necessary for the messages to be accepted as valid
   * @param newConfirmations new number of needed confirmations
   */
  function updateConfirmations(uint256 newConfirmations) external;

  /**
   * @dev method that registers a received message, updates the confirmations, and sets it as valid if number
   of confirmations has been reached.
   * @param payload bytes of the payload, containing the information to operate with it
   */
  function receiveCrossChainMessage(
    bytes memory payload,
    CrossChainUtils.Chains originChainId
  ) external;

  /**
   * @dev method to add bridge adapters to the allowed list
   * @param bridgeAdapters array of new bridge adapter configurations
   */
  function allowReceiverBridgeAdapters(address[] memory bridgeAdapters)
    external;

  /**
   * @dev method to remove bridge adapters from the allowed list
   * @param bridgeAdapters array of bridge adapter addresses to remove from the allow list
   */
  function disallowReceiverBridgeAdapters(address[] memory bridgeAdapters)
    external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import {IWithGuardian} from './interfaces/IWithGuardian.sol';
import {Ownable} from '../oz-common/Ownable.sol';

abstract contract OwnableWithGuardian is Ownable, IWithGuardian {
  address private _guardian;

  constructor() {
    _updateGuardian(_msgSender());
  }

  modifier onlyGuardian() {
    _checkGuardian();
    _;
  }

  modifier onlyOwnerOrGuardian() {
    _checkOwnerOrGuardian();
    _;
  }

  function guardian() public view override returns (address) {
    return _guardian;
  }

  /// @inheritdoc IWithGuardian
  function updateGuardian(address newGuardian) external override onlyGuardian {
    _updateGuardian(newGuardian);
  }

  /**
   * @dev method to update the guardian
   * @param newGuardian the new guardian address
   */
  function _updateGuardian(address newGuardian) internal {
    address oldGuardian = _guardian;
    _guardian = newGuardian;
    emit GuardianUpdated(oldGuardian, newGuardian);
  }

  function _checkGuardian() internal view {
    require(guardian() == _msgSender(), 'ONLY_BY_GUARDIAN');
  }

  function _checkOwnerOrGuardian() internal view {
    require(_msgSender() == owner() || _msgSender() == guardian(), 'ONLY_BY_OWNER_OR_GUARDIAN');
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IWithGuardian {
  /**
   * @dev Event emitted when guardian gets updated
   * @param oldGuardian address of previous guardian
   * @param newGuardian address of the new guardian
   */
  event GuardianUpdated(address oldGuardian, address newGuardian);

  /**
   * @dev get guardian address;
   */
  function guardian() external view returns (address);

  /**
   * @dev method to update the guardian
   * @param newGuardian the new guardian address
   */
  function updateGuardian(address newGuardian) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
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
    return functionCallWithValue(target, data, 0, 'Address: low-level call failed');
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
    return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
    require(address(this).balance >= value, 'Address: insufficient balance for call');
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    return functionStaticCall(target, data, 'Address: low-level static call failed');
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
    return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
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
        require(isContract(target), 'Address: call to non-contract');
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

pragma solidity ^0.8.0;

import './Context.sol';

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
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
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

/**
 * @dev OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)
 * From https://github.com/OpenZeppelin/openzeppelin-contracts/tree/8b778fa20d6d76340c5fac1ed66c80273f05b95a
 *
 * BGD Labs adaptations:
 * - Added a constructor disabling initialization for implementation contracts
 * - Linting
 */

pragma solidity ^0.8.2;

import '../oz-common/Address.sol';

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
   * @dev OPINIONATED. Generally is not a good practise to allow initialization of implementations
   */
  constructor() {
    _disableInitializers();
  }

  /**
   * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
   * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
   */
  modifier initializer() {
    bool isTopLevelCall = !_initializing;
    require(
      (isTopLevelCall && _initialized < 1) ||
        (!Address.isContract(address(this)) && _initialized == 1),
      'Initializable: contract is already initialized'
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
    require(
      !_initializing && _initialized < version,
      'Initializable: contract is already initialized'
    );
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
    require(_initializing, 'Initializable: contract is not initializing');
    _;
  }

  /**
   * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
   * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
   * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
   * through proxies.
   */
  function _disableInitializers() internal virtual {
    require(!_initializing, 'Initializable: contract is initializing');
    if (_initialized < type(uint8).max) {
      _initialized = type(uint8).max;
      emit Initialized(type(uint8).max);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from 'solidity-utils/contracts/transparent-proxy/Initializable.sol';
import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';
import {IGovernanceCore, IL1VotingStrategy, CrossChainMandateUtils, CrossChainUtils} from '../interfaces/IGovernanceCore.sol';
import {IVotingPortal} from '../interfaces/IVotingPortal.sol';

abstract contract GovernanceCore is
  IGovernanceCore,
  Initializable,
  OwnableWithGuardian
{
  /// @inheritdoc IGovernanceCore
  uint256 public constant PRECISION_DIVIDER = 1 ether;

  /// @inheritdoc IGovernanceCore
  uint256 public immutable COOLDOWN_PERIOD;
  /// @inheritdoc IGovernanceCore
  uint256 public constant PROPOSAL_EXPIRATION_TIME = 30 days;

  IL1VotingStrategy internal _votingStrategy;

  // TODO: should proposal count start from last proposal on gov v2?
  uint256 public _proposalsCount;

  /// @dev (votingPortal => approved) list of approved voting portals
  mapping(address => bool) internal _votingPortals;

  /// @dev (proposalId => Proposal) mapping to store the information of a proposal. indexed by proposalId
  mapping(uint256 => Proposal) internal _proposals;

  /// @dev (accessLevel => VotingConfig) mapping storing the different voting configurations. Indexed by
  ///      access level (level 1, level 2)
  mapping(CrossChainMandateUtils.AccessControl => VotingConfig)
    internal _votingConfigs;

  /// @inheritdoc IGovernanceCore
  string public constant NAME = 'Aave Governance v3';

  constructor(uint256 coolDownPeriod) {
    COOLDOWN_PERIOD = coolDownPeriod;
  }

  /// @inheritdoc IGovernanceCore
  function initialize(
    address owner,
    address guardian,
    IL1VotingStrategy votingStrategy,
    SetVotingConfigInput[] calldata votingConfigs,
    address[] calldata votingPortals
  ) external initializer {
    _transferOwnership(owner);
    _updateGuardian(guardian);
    _setVotingStrategy(votingStrategy);
    _setVotingConfigs(votingConfigs);
    _updateVotingPortals(votingPortals, true);
  }

  /// @inheritdoc IGovernanceCore
  function getVotingStrategy() external view returns (IL1VotingStrategy) {
    return _votingStrategy;
  }

  /// @inheritdoc IGovernanceCore
  function getProposalsCount() external view returns (uint256) {
    return _proposalsCount;
  }

  /// @inheritdoc IGovernanceCore
  function isVotingPortalApproved(address votingPortal)
    external
    view
    returns (bool)
  {
    return _votingPortals[votingPortal];
  }

  /// @inheritdoc IGovernanceCore
  function addVotingPortals(address[] memory votingPortals) external onlyOwner {
    _updateVotingPortals(votingPortals, true);
  }

  /// @inheritdoc IGovernanceCore
  function removeVotingPortals(address[] memory votingPortals)
    external
    onlyOwner
  {
    _updateVotingPortals(votingPortals, false);
  }

  /// @inheritdoc IGovernanceCore
  function createProposal(
    CrossChainMandateUtils.Payload[] calldata payloads,
    CrossChainMandateUtils.AccessControl accessLevel,
    address votingPortal,
    bytes32 ipfsHash
  ) external returns (uint256) {
    require(payloads.length != 0, 'AT_LEAST_ONE_PAYLOAD');

    require(_votingPortals[votingPortal], 'VOTING_PORTAL_NOT_APPROVED');

    VotingConfig memory votingConfig = _votingConfigs[accessLevel];
    address proposalCreator = msg.sender;

    require(votingConfig.isActive, 'VOTING_CONFIG_IS_NOT_ACTIVATED');
    require(
      _isPropositionPowerEnough(
        _votingConfigs[accessLevel],
        _votingStrategy.getFullPropositionPower(proposalCreator)
      ),
      'PROPOSITION_POWER_IS_TOO_LOW'
    );

    uint256 proposalId = _proposalsCount++;
    Proposal storage proposal = _proposals[proposalId];
    for (uint256 i = 0; i < payloads.length; i++) {
      require(
        payloads[i].accessLevel <= accessLevel,
        'REQUESTED_ACCESS_LEVEL_IS_TOO_LOW'
      );
      proposal.payloads.push(payloads[i]);
    }
    proposal.state = State.Created;
    proposal.creator = proposalCreator;
    proposal.accessLevel = accessLevel;
    proposal.votingPortal = votingPortal;
    proposal.votingDuration = votingConfig.votingDuration;
    proposal.creationTime = uint40(block.timestamp);
    proposal.ipfsHash = ipfsHash;

    emit ProposalCreated(
      proposalId,
      proposalCreator,
      accessLevel,
      votingConfig.votingDuration,
      ipfsHash
    );

    return proposalId;
  }

  function activateVoting(uint256 proposalId) external {
    Proposal storage proposal = _proposals[proposalId];
    VotingConfig memory votingConfig = _votingConfigs[proposal.accessLevel];

    uint40 proposalCreationTime = proposal.creationTime;
    bytes32 blockHash = blockhash(block.number - 1);
    uint256 snapshotBlockNumber = block.number - 1;

    require(
      _getProposalState(proposal) == State.Created,
      'NOT_IN_CREATED_STATE'
    );
    require(
      block.timestamp - proposalCreationTime >
        votingConfig.coolDownBeforeVotingStart,
      'COOLDOWN_PERIOD_NOT_PASSED'
    );

    proposal.votingActivationTime = uint40(block.timestamp);
    proposal.snapshotBlockHash = blockHash;
    proposal.hashBlockNumber = snapshotBlockNumber; // TODO: change naming to snapshotBlockNumber

    IVotingPortal(proposal.votingPortal).forwardMessage(
      proposalId,
      blockHash,
      proposal.votingDuration
    );
    emit VotingActivated(proposalId, blockHash, snapshotBlockNumber);
  }

  /// @inheritdoc IGovernanceCore
  function queueProposal(
    uint256 proposalId,
    uint128 forVotes,
    uint128 againstVotes
  ) external {
    Proposal storage proposal = _proposals[proposalId];
    address votingPortal = proposal.votingPortal;

    // only the accepted portal for this proposal can queue it
    require(
      msg.sender == votingPortal && _votingPortals[votingPortal],
      'CALLER_NOT_A_VALID_VOTING_PORTAL'
    );

    require(
      _getProposalState(proposal) == State.Created,
      'NOT_IN_A_CREATED_STATE'
    );

    VotingConfig memory votingConfig = _votingConfigs[proposal.accessLevel];
    require(votingConfig.isActive, 'VOTING_CONFIG_IS_NOT_ACTIVE');

    proposal.forVotes = forVotes;
    proposal.againstVotes = againstVotes;

    if (
      _isPropositionPowerEnough(
        votingConfig,
        _votingStrategy.getFullPropositionPower(proposal.creator)
      ) &&
      _isPassingQuorum(votingConfig, forVotes, againstVotes) &&
      _isPassingDifferential(votingConfig, forVotes, againstVotes)
    ) {
      proposal.queuingTime = uint40(block.timestamp);
      proposal.state = State.Queued;
      emit ProposalQueued(proposalId, forVotes, againstVotes);
    } else {
      proposal.state = State.Failed;
      emit ProposalFailed(proposalId, forVotes, againstVotes);
    }
  }

  /// @inheritdoc IGovernanceCore
  function executeProposal(uint256 proposalId) external {
    Proposal storage proposal = _proposals[proposalId];
    require(
      _getProposalState(proposal) == State.Queued,
      'NOT_IN_A_QUEUED_STATE'
    );
    require(
      block.timestamp > proposal.queuingTime + COOLDOWN_PERIOD,
      'STILL_IN_COOLDOWN_PERIOD'
    );

    for (uint256 i = 0; i < proposal.payloads.length; i++) {
      CrossChainMandateUtils.Payload memory payload = proposal.payloads[i];

      _executePortal(payload);

      emit PayloadSent(
        proposalId,
        payload.payloadId,
        payload.mandateProvider,
        payload.chain,
        i,
        proposal.payloads.length
      );
    }

    proposal.state = State.Executed;
    emit ProposalExecuted(proposalId);
  }

  /// @inheritdoc IGovernanceCore
  function cancelProposal(uint256 proposalId) external {
    Proposal storage proposal = _proposals[proposalId];
    State proposalState = _getProposalState(proposal);
    address proposalCreator = proposal.creator;

    require(
      proposalState != State.Null &&
        uint256(proposalState) < uint256(State.Executed),
      'PROPOSAL_ALREADY_EXECUTED'
    );
    if (
      proposalCreator != msg.sender &&
      _isPropositionPowerEnough(
        _votingConfigs[proposal.accessLevel],
        _votingStrategy.getFullPropositionPower(proposalCreator)
      )
    ) {
      _checkGuardian();
    }

    proposal.state = State.Cancelled;
    proposal.cancelTimestamp = uint40(block.timestamp);
    emit ProposalCanceled(proposalId);
  }

  /// @inheritdoc IGovernanceCore
  function setVotingConfigs(SetVotingConfigInput[] calldata votingConfigs)
    external
    onlyOwner
  {
    _setVotingConfigs(votingConfigs);
  }

  /// @inheritdoc IGovernanceCore
  function setVotingStrategy(IL1VotingStrategy votingStrategy)
    external
    onlyOwner
  {
    _setVotingStrategy(votingStrategy);
  }

  /// @inheritdoc IGovernanceCore
  function getProposal(uint256 proposalId)
    external
    view
    returns (Proposal memory)
  {
    Proposal memory proposal = _proposals[proposalId];
    proposal.state = _getProposalState(_proposals[proposalId]);
    return proposal;
  }

  /// @inheritdoc IGovernanceCore
  function getVotingConfig(CrossChainMandateUtils.AccessControl accessLevel)
    external
    view
    returns (VotingConfig memory)
  {
    return _votingConfigs[accessLevel];
  }

  /**
   * @dev method to override that should be in charge of sending payload for execution
   * @param payload object containing the information necessary for execution
   */
  function _executePortal(CrossChainMandateUtils.Payload memory payload)
    internal
    virtual;

  /**
   * @dev method to set the voting configuration for a determined access level
   * @param votingConfigs object containing configuration for an access level
   */
  function _setVotingConfigs(SetVotingConfigInput[] memory votingConfigs)
    internal
  {
    VotingConfig memory votingConfig;
    for (uint256 i = 0; i < votingConfigs.length; i++) {
      votingConfig = VotingConfig({
        isActive: votingConfigs[i].isActive,
        coolDownBeforeVotingStart: votingConfigs[i].coolDownBeforeVotingStart,
        votingDuration: votingConfigs[i].votingDuration,
        quorum: _normalize(votingConfigs[i].quorum),
        differential: _normalize(votingConfigs[i].differential),
        minPropositionPower: _normalize(votingConfigs[i].minPropositionPower)
      });
      _votingConfigs[votingConfigs[i].accessLevel] = votingConfig;

      emit VotingConfigUpdated(
        votingConfigs[i].accessLevel,
        votingConfig.isActive,
        votingConfig.votingDuration,
        votingConfig.coolDownBeforeVotingStart,
        votingConfig.quorum,
        votingConfig.differential,
        votingConfig.minPropositionPower
      );
    }
  }

  /**
   * @dev method to set a new _votingStrategy contract
   * @param votingStrategy address of the new contract containing the voting a voting strategy
   */
  function _setVotingStrategy(IL1VotingStrategy votingStrategy) internal {
    _votingStrategy = votingStrategy;

    emit VotingStrategyUpdated(address(votingStrategy));
  }

  /**
   * @dev method to know if proposition power is bigger than the minimum expected for the voting configuration set
         for this access level
   * @param votingConfig voting configuration from a specific access level, where to check the minimum proposition power
   * @param propositionPower power to check against the voting config minimum
   * @return boolean indicating if power is bigger than minimum
   */
  function _isPropositionPowerEnough(
    IGovernanceCore.VotingConfig memory votingConfig,
    uint256 propositionPower
  ) internal pure returns (bool) {
    return
      propositionPower > votingConfig.minPropositionPower * PRECISION_DIVIDER;
  }

  /**
   * @dev method to know if a vote is passing the quorum set in the vote configuration
   * @param votingConfig configuration of this voting, set by access level
   * @param forVotes votes in favor of passing the proposal
   * @param againstVotes votes against passing the proposal
   * @return boolean indicating the passing of the quorum
   */
  function _isPassingQuorum(
    VotingConfig memory votingConfig,
    uint256 forVotes,
    uint256 againstVotes
  ) internal pure returns (bool) {
    return forVotes + againstVotes > votingConfig.quorum * PRECISION_DIVIDER;
  }

  /**
   * @dev method to know if the votes pass the differential set by the voting configuration
   * @param votingConfig configuration of this voting, set by access level
   * @param forVotes votes in favor of passing the proposal
   * @param againstVotes votes against passing the proposal
   * @return boolean indicating the passing of the differential
   */
  function _isPassingDifferential(
    VotingConfig memory votingConfig,
    uint256 forVotes,
    uint256 againstVotes
  ) internal pure returns (bool) {
    return
      forVotes >= againstVotes &&
      forVotes - againstVotes > votingConfig.differential * PRECISION_DIVIDER;
  }

  /**
   * @dev method to get the current state of a proposal
   * @param proposal object with all pertinent proposal information
   * @return current state of the proposal
   */
  function _getProposalState(Proposal storage proposal)
    internal
    view
    returns (State)
  {
    State state = proposal.state;
    // @dev small shortcut
    if (
      state == IGovernanceCore.State.Null ||
      state >= IGovernanceCore.State.Executed
    ) {
      return state;
    }

    uint256 expirationTime = proposal.creationTime + PROPOSAL_EXPIRATION_TIME;
    if (
      block.timestamp > expirationTime ||
      (state == IGovernanceCore.State.Created &&
        block.timestamp + _votingConfigs[proposal.accessLevel].votingDuration >
        expirationTime)
    ) {
      return State.Expired;
    }

    return state;
  }

  /**
   * @dev method to remove specified decimals from a value, as to normalize it.
   * @param value number to remove decimals from
   * @return normalized value
   */
  function _normalize(uint256 value) internal pure returns (uint56) {
    uint256 normalizedValue = value / PRECISION_DIVIDER;
    require(normalizedValue < type(uint56).max, 'VALUE_IS_BIGGER_THEN_UINT56');
    return uint56(normalizedValue);
  }

  /**
   * @dev method that approves or disapproves voting machines
   * @param votingPortals list of voting portal addresses
   * @param state boolean indicating if the list is for approval or disapproval of the voting portal addresses
   */
  function _updateVotingPortals(address[] memory votingPortals, bool state)
    internal
  {
    for (uint256 i = 0; i < votingPortals.length; i++) {
      address votingPortal = votingPortals[i];
      _votingPortals[votingPortal] = state;

      emit VotingPortalUpdated(votingPortal, state);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {ICrossChainManager} from 'ghost-crosschain-infra/contracts/interfaces/ICrossChainManager.sol';
// TODO: should we be using IGovernanceCore or IGovernance(and then if so, it should be inheriting IGovernanceCore)
import {IGovernanceCore} from './GovernanceCore.sol';
import {IVotingPortal, CrossChainUtils, IBaseReceiverPortal} from '../interfaces/IVotingPortal.sol';

/**
 * @title SameChainMessageRegistry
 * @author BGD Labs
 * @dev Contract with the knowledge on how to initialize and get votes, from a vote that happened on a different or same chain.
 */
contract VotingPortal is IVotingPortal {
  address public immutable CROSS_CHAIN_MANAGER;
  address public immutable GOVERNANCE;
  address public immutable VOTING_MACHINE;
  uint256 public immutable GAS_LIMIT;
  CrossChainUtils.Chains public immutable VOTING_MACHINE_CHAIN_ID;

  /**
   * @param crossChainManager address of current network message manager (cross chain manager or same chain manager)
   */
  constructor(
    address crossChainManager,
    address governance,
    address votingMachine,
    uint256 gasLimit,
    CrossChainUtils.Chains votingMachineChainId
  ) {
    CROSS_CHAIN_MANAGER = crossChainManager;
    GOVERNANCE = governance;
    VOTING_MACHINE = votingMachine;
    GAS_LIMIT = gasLimit;
    VOTING_MACHINE_CHAIN_ID = votingMachineChainId;
  }

  /// @inheritdoc IBaseReceiverPortal
  /// @dev pushes the voting result and queues the proposal identified by proposalId
  function receiveCrossChainMessage(
    address originSender,
    CrossChainUtils.Chains originChainId,
    bytes memory message
  ) external {
    require(
      msg.sender == CROSS_CHAIN_MANAGER &&
        originSender == VOTING_MACHINE &&
        originChainId == VOTING_MACHINE_CHAIN_ID,
      'WRONG_MESSAGE_ORIGIN'
    );

    (uint256 proposalId, uint128 forVotes, uint128 againstVotes) = abi.decode(
      message,
      (uint256, uint128, uint128)
    );

    IGovernanceCore(GOVERNANCE).queueProposal(
      proposalId,
      forVotes,
      againstVotes
    );
  }

  // TODO: we will need to add this portal to allowed forwarders in cross chain manager
  // for it to work
  function forwardMessage(
    uint256 proposalId,
    bytes32 blockHash,
    uint24 votingDuration
  ) external {
    require(msg.sender == GOVERNANCE, 'CALLER_NOT_GOVERNANCE');

    bytes memory message = abi.encode(proposalId, blockHash, votingDuration);

    ICrossChainManager(CROSS_CHAIN_MANAGER).forwardMessage(
      VOTING_MACHINE_CHAIN_ID,
      VOTING_MACHINE,
      GAS_LIMIT,
      message
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CrossChainMandateUtils} from 'aave-crosschain-mandates/contracts/CrossChainMandateUtils.sol';
import {CrossChainUtils} from 'ghost-crosschain-infra/contracts/CrossChainUtils.sol';
import {IL1VotingStrategy} from './IL1VotingStrategy.sol';

interface IGovernanceCore {
  // TODO: think about what we expect in config, maybe we want in receive normal units with 18 decimals, and reduce decimals inside
  // from another side uint56 is ~10^16, which means that nobody will be able even to pass 10^18
  /**
   * @dev Object storing the vote configuration for a specific access level
   * @param isActive boolean indicating if this configuration should be used
   * @param coolDownBeforeVotingStart number of seconds indicating how much time should pass before proposal will be moved to vote
   * @param votingDuration number of seconds indicating the duration of a vote
   * @param quorum minimum number of votes needed for a proposal to pass.
            FOR VOTES + AGAINST VOTES > QUORUM
            we consider that this param in case of AAVE don't need decimal places
   * @param differential number of for votes that need to be bigger than against votes to pass a proposal.
            FOR VOTES - AGAINST VOTES > DIFFERENTIAL
            we consider that this param in case of AAVE don't need decimal places
   * @param minPropositionPower the minimum needed power to create a proposal.
            we consider that this param in case of AAVE don't need decimal places
   */
  struct VotingConfig {
    bool isActive;
    uint24 coolDownBeforeVotingStart;
    uint24 votingDuration;
    uint56 quorum;
    uint56 differential;
    uint56 minPropositionPower;
  }

  /**
   * @dev object storing the input parameters of a voting configuration
   * @param accessLevel number of access level needed to execute a proposal in this settings
   * @param isActive boolean indicating if this configuration should be used
   * @param votingDuration number of seconds indicating the duration of a vote
   * @param quorum minimum number of votes needed for a proposal to pass.
            FOR VOTES + AGAINST VOTES > QUORUM
            in normal units with 18 decimals
   * @param differential number of for votes that need to be bigger than against votes to pass a proposal.
            FOR VOTES - AGAINST VOTES > DIFFERENTIAL
            in normal units with 18 decimals
   * @param minPropositionPower the minimum needed power to create a proposal.
            in normal units with 18 decimals
   */
  struct SetVotingConfigInput {
    CrossChainMandateUtils.AccessControl accessLevel;
    bool isActive;
    uint24 coolDownBeforeVotingStart;
    uint24 votingDuration;
    uint256 quorum;
    uint256 differential;
    uint256 minPropositionPower;
  }

  /**
   * @dev enum storing the different states of a proposal
   */
  enum State {
    Null, // proposal does not exists
    Created, // created, waiting for a cooldown to initiate the balances snapshot
    Active, // balances snapshot set, voting in progress
    Queued, // voting results submitted, but proposal is under grace period when guardian can cancel it
    Executed, // results sent to the execution chain(s)
    Failed, // voting was not successful
    Cancelled, // got cancelled by guardian, or because proposition power of creator dropped below allowed minimum
    Expired
  }

  /**
   * @dev object storing all the information of a proposal including the different states in time that can have
   * @param votingDuration number of seconds indicating the duration of a vote. max is: 16'777'216 (ie 194.18 days)
   * @param creationTime timestamp in seconds of when the proposal was created. max is: 1.099511628×10¹² (ie 34'865 years)
   * @param snapshotBlockHash blockHash of when the proposal was created, as to be able to get the correct balances on this specific block
   * @param accessLevel minimum level needed to be able to execute this proposal
   * @param state current state of the proposal
   * @param creator address of the creator of the proposal
   * @param payloads list of objects containing the payload information necessary for execution
   * @param queuingTime timestamp in seconds of when the proposal was queued
   * @param cancelTimestamp timestamp in seconds of when the proposal was canceled
   * @param votingPortal address of the votingPortal used to communicate with the voting chain
   * @param ipfsHash ipfs has containing the proposal metadata information
   * @param forVotes number of votes in favor of the proposal
   * @param againstVotes number of votes against the proposal
   * @param hashBlockNumber block number used to take the block hash from. Proposal creation block number - 1
   */
  struct Proposal {
    uint24 votingDuration;
    uint40 creationTime;
    uint40 votingActivationTime;
    bytes32 snapshotBlockHash;
    CrossChainMandateUtils.AccessControl accessLevel; // should be needed only on "execution chain", should fit into uint256 imo
    State state;
    uint40 queuingTime;
    uint40 cancelTimestamp;
    bytes32 ipfsHash;
    uint128 forVotes;
    uint128 againstVotes;
    address votingPortal;
    address creator;
    uint256 hashBlockNumber;
    CrossChainMandateUtils.Payload[] payloads; // should be needed only on "execution chain", should fit into uint256 imo
  }

  /**
   * @dev emitted when votingStrategy got updated
   * @param newVotingStrategy address of the new votingStrategy
   **/
  event VotingStrategyUpdated(address indexed newVotingStrategy);

  /**
   * @dev emitted when one of the _votingConfigs got updated
   * @param accessLevel minimum level needed to be able to execute this proposal
   * @param isActive is this voting configuration active or not
   * @param votingDuration duration of the voting period in seconds
   * @param quorum min amount of votes needed to pass a proposal
   * @param differential minimal difference between you and no votes for proposal to pass
   * @param minPropositionPower minimal proposition power of a user to be able to create proposal
   **/
  event VotingConfigUpdated(
    CrossChainMandateUtils.AccessControl indexed accessLevel,
    bool indexed isActive,
    uint24 votingDuration,
    uint24 coolDownBeforeVotingStart,
    uint256 quorum,
    uint256 differential,
    uint256 minPropositionPower
  );

  /**
   * @dev
   * @param proposalId id of the proposal
   * @param creator address of the creator of the proposal
   * @param accessLevel minimum level needed to be able to execute this proposal
   * @param votingDuration duration of the voting period in seconds
   * @param ipfsHash ipfs has containing the proposal metadata information
   */
  event ProposalCreated(
    uint256 indexed proposalId,
    address indexed creator,
    CrossChainMandateUtils.AccessControl indexed accessLevel,
    uint24 votingDuration,
    bytes32 ipfsHash
  );
  /**
   * @dev
   * @param proposalId id of the proposal
   * @param snapshotBlockHash blockHash of when the proposal was created, as to be able to get the correct balances on this specific block
   * @param snapshotBlockNumber number of the block when the proposal was created
   */
  event VotingActivated(
    uint256 indexed proposalId,
    bytes32 snapshotBlockHash,
    uint256 snapshotBlockNumber
  );

  /**
   * @dev emitted when proposal change state to Queued
   * @param proposalId id of the proposal
   * @param votesFor votes for proposal
   * @param votesAgainst votes against proposal
   **/
  event ProposalQueued(
    uint256 indexed proposalId,
    uint128 votesFor,
    uint128 votesAgainst
  );

  /**
   * @dev emitted when proposal change state to Executed
   * @param proposalId id of the proposal
   **/
  event ProposalExecuted(uint256 indexed proposalId);

  /**
   * @dev emitted when proposal change state to Canceled
   * @param proposalId id of the proposal
   **/
  event ProposalCanceled(uint256 indexed proposalId);

  /**
   * @dev emitted when proposal change state to Failed
   * @param proposalId id of the proposal
   * @param votesFor votes for proposal
   * @param votesAgainst votes against proposal
   **/
  event ProposalFailed(
    uint256 indexed proposalId,
    uint128 votesFor,
    uint128 votesAgainst
  );

  /**
   * @dev emitted when a voting machine gets updated
   * @param votingPortal address of the voting portal updated
   * @param approved boolean indicating if a voting portal has been added or removed
   */
  event VotingPortalUpdated(
    address indexed votingPortal,
    bool indexed approved
  );

  /**
   * @dev emitted when a payload is successfully sent to the execution chain
   * @param proposalId id of the proposal containing the payload sent for execution
   * @param payloadId id of the payload sent for execution
   * @param mandateProvider address of the mandate provider on the execution chain
   * @param chainId id of the execution chain
   * @param payloadNumberOnProposal number of payload sent for execution, from the number of payloads contained in proposal
   * @param numberOfPayloadsOnProposal number of payloads that are in the proposal
   */
  event PayloadSent(
    uint256 indexed proposalId,
    uint40 payloadId,
    address indexed mandateProvider,
    CrossChainUtils.Chains indexed chainId,
    uint256 payloadNumberOnProposal,
    uint256 numberOfPayloadsOnProposal
  );

  /**
   * @dev method to initialize governance v3
   * @param owner address of the new owner of governance
   * @param guardian address of the new guardian of governance
   * @param votingStrategy address of the governance chain voting strategy with the logic of weighted powers
   * @param votingConfigs objects containing the information of different voting configurations depending on access level
   * @param votingPortals objects containing the information of different voting machines depending on chain id
   */
  function initialize(
    address owner,
    address guardian,
    IL1VotingStrategy votingStrategy,
    SetVotingConfigInput[] calldata votingConfigs,
    address[] calldata votingPortals
  ) external;

  /**
   * @dev method to approve new voting machines
   * @param votingPortals array of voting portal addresses to approve
   */
  function addVotingPortals(address[] memory votingPortals) external;

  /**
   * @dev method to disapprove voting machines, as to not make them usable any more.
   * @param votingPortals list of addresses of the voting machines that are no longer valid
   */
  function removeVotingPortals(address[] memory votingPortals) external;

  /**
   * @dev creates a proposal, with configuration specified in VotingConfig corresponding to the accessLevel
   * @param payloads which user propose to vote for
   * @param accessLevel which maximum access level this proposal requires
   * @param votingPortal address of the contract which will bootstrap voting, and provide results in the end
   * @param ipfsHash ipfs hash of a document with proposal description
   * @return created proposal ID
   **/
  function createProposal(
    CrossChainMandateUtils.Payload[] calldata payloads,
    CrossChainMandateUtils.AccessControl accessLevel,
    address votingPortal,
    bytes32 ipfsHash
  ) external returns (uint256);

  /**
   * @dev executes a proposal, can be called by anyone if proposal in Queued state
   * @dev and passed more then COOLDOWN_PERIOD seconds after proposal entered this state
   * @param proposalId id of the proposal
   **/
  function executeProposal(uint256 proposalId) external;

  /**
   * @dev cancels a proposal, can be initiated by guardian,
   * @dev or if proposition power of proposal creator will go below minPropositionPower specified in VotingConfig
   * @param proposalId id of the proposal
   **/
  function cancelProposal(uint256 proposalId) external;

  /**
   * @dev method to set a new votingStrategy contract
   * @param newVotingStrategy address of the new contract containing the voting a voting strategy
   */

  function setVotingStrategy(IL1VotingStrategy newVotingStrategy) external;

  /**
   * @dev method to set the voting configuration for a determined access level
   * @param votingConfigs object containing configuration for an access level
   */
  function setVotingConfigs(SetVotingConfigInput[] calldata votingConfigs)
    external;

  /**
   * @dev method to get the voting configuration from an access level
   * @param accessLevel level for which to get the configuration of a vote
   */
  function getVotingConfig(CrossChainMandateUtils.AccessControl accessLevel)
    external
    view
    returns (VotingConfig memory);

  /// @dev gets the address of the current network message manager (cross chain manager or same chain manager)
  function CROSS_CHAIN_MANAGER() external view returns (address);

  /**
   * @dev method to get the cool down period between queuing and execution
   * @return time in seconds
   */
  function COOLDOWN_PERIOD() external view returns (uint256);

  /**
   * @dev method to get the precision divider used to remove unneeded decimals
   * @return decimals of 1 ether (18)
   */
  function PRECISION_DIVIDER() external view returns (uint256);

  /**
   * @dev method to get the expiration time from creation from which the proposal will be invalid
   * @return time in seconds
   */
  function PROPOSAL_EXPIRATION_TIME() external view returns (uint256);

  /**
   * @dev method to get the name of the contract
   * @return name string
   */
  function NAME() external view returns (string memory);

  /**
   * @dev method to get the proposal identified by passed id
   * @param proposalId id of the proposal to get the information of
   * @return proposal object containing all the information
   */
  function getProposal(uint256 proposalId)
    external
    view
    returns (Proposal memory);

  /**
   * @dev address of the current voting strategy to use on the governance
   * @return address of the voting strategy
   */
  function getVotingStrategy() external view returns (IL1VotingStrategy);

  /**
   * @dev proposals counter.
   * @return the current number proposals created
   */
  function getProposalsCount() external view returns (uint256);

  /**
   * @dev method to get a voting machine for chain id
   * @param votingPortal address of the voting portal to check if approved
   */
  function isVotingPortalApproved(address votingPortal)
    external
    view
    returns (bool);

  /**
   * @dev method to queue a proposal for execution
   * @param proposalId the id of the proposal to queue
   * @param forVotes number of votes in favor of the proposal
   * @param againstVotes number of votes against of the proposal
   */
  function queueProposal(
    uint256 proposalId,
    uint128 forVotes,
    uint128 againstVotes
  ) external;

  /**
   * @dev method to send proposal to votingMachine
   * @param proposalId id of the proposal to start the voting on
   */
  function activateVoting(uint256 proposalId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IL1VotingStrategy {
  /**
   * @dev method to get the full weighted voting power of an user
   * @param user address where we want to get the power from
   */
  function getFullVotingPower(address user) external view returns (uint256);

  /**
   * @dev method to get the full weighted proposal power of an user
   * @param user address where we want to get the power from
   */
  function getFullPropositionPower(address user)
    external
    view
    returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CrossChainUtils} from 'ghost-crosschain-infra/contracts/CrossChainUtils.sol';
import {IBaseReceiverPortal} from 'ghost-crosschain-infra/contracts/interfaces/IBaseReceiverPortal.sol';

interface IVotingPortal is IBaseReceiverPortal {
  /// @dev get the chain id where the voting machine which is connected to, is deployed
  function VOTING_MACHINE_CHAIN_ID()
    external
    view
    returns (CrossChainUtils.Chains);

  /// @dev gets the address of the voting machine on the destination network
  function VOTING_MACHINE() external view returns (address);

  /// @dev gets the address of the connected governance
  function GOVERNANCE() external view returns (address);

  /// @dev gets the address of the current network message manager (cross chain manager or same chain manager)
  function CROSS_CHAIN_MANAGER() external view returns (address);

  /// @dev gas limit to be used on receiving side of bridging voting configurations
  function GAS_LIMIT() external view returns (uint256);

  function forwardMessage(
    uint256 proposalId,
    bytes32 blockHash,
    uint24 votingDuration
  ) external;
}