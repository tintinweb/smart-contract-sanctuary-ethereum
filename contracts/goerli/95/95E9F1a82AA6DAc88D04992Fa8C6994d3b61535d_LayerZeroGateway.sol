// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import { IGateway } from '../interfaces/IGateway.sol';
import { IGatewayClient } from '../interfaces/IGatewayClient.sol';
import { ILayerZeroEndpoint } from './interfaces/ILayerZeroEndpoint.sol';
import { GatewayBase } from '../GatewayBase.sol';
import { SystemVersionId } from '../../SystemVersionId.sol';
import { ZeroAddressError } from '../../Errors.sol';
import '../../helpers/AddressHelper.sol' as AddressHelper;
import '../../helpers/GasReserveHelper.sol' as GasReserveHelper;

/**
 * @title LayerZeroGateway
 * @notice The contract implementing the cross-chain messaging logic specific to LayerZero
 */
contract LayerZeroGateway is SystemVersionId, GatewayBase {
    /**
     * @notice Chain ID pair structure
     * @dev See https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
     * @param standardId The standard EVM chain ID
     * @param layerZeroId The LayerZero chain ID
     */
    struct ChainIdPair {
        uint256 standardId;
        uint16 layerZeroId;
    }

    /**
     * @dev LayerZero endpoint contract reference
     */
    ILayerZeroEndpoint public endpoint;

    /**
     * @dev The correspondence between standard EVM chain IDs and LayerZero chain IDs
     */
    mapping(uint256 /*standardId*/ => uint16 /*layerZeroId*/) public standardToLayerZeroChainId;

    /**
     * @dev The correspondence between LayerZero chain IDs and standard EVM chain IDs
     */
    mapping(uint16 /*layerZeroId*/ => uint256 /*standardId*/) public layerZeroToStandardChainId;

    uint16 private constant ADAPTER_PARAMETERS_VERSION = 1;

    /**
     * @notice Emitted when the cross-chain endpoint contract reference is set
     * @param endpointAddress The address of the cross-chain endpoint contract
     */
    event SetEndpoint(address indexed endpointAddress);

    /**
     * @notice Emitted when a chain ID pair is added or updated
     * @param standardId The standard EVM chain ID
     * @param layerZeroId The LayerZero chain ID
     */
    event SetChainIdPair(uint256 indexed standardId, uint16 indexed layerZeroId);

    /**
     * @notice Emitted when a chain ID pair is removed
     * @param standardId The standard EVM chain ID
     * @param layerZeroId The LayerZero chain ID
     */
    event RemoveChainIdPair(uint256 indexed standardId, uint16 indexed layerZeroId);

    /**
     * @notice Emitted when there is no registered LayerZero chain ID matching the standard EVM chain ID
     */
    error LayerZeroChainIdNotSetError();

    /**
     * @notice Emitted when the caller is not the LayerZero endpoint contract
     */
    error OnlyEndpointError();

    /**
     * @dev Modifier to check if the caller is the LayerZero endpoint contract
     */
    modifier onlyEndpoint() {
        if (msg.sender != address(endpoint)) {
            revert OnlyEndpointError();
        }

        _;
    }

    /**
     * @notice Deploys the LayerZeroGateway contract
     * @param _endpointAddress The cross-chain endpoint address
     * @param _chainIdPairs The correspondence between standard EVM chain IDs and LayerZero chain IDs
     * @param _targetGasReserve The initial gas reserve value for target chain action processing
     * @param _owner The address of the initial owner of the contract
     * @param _managers The addresses of initial managers of the contract
     * @param _addOwnerToManagers The flag to optionally add the owner to the list of managers
     */
    constructor(
        address _endpointAddress,
        ChainIdPair[] memory _chainIdPairs,
        uint256 _targetGasReserve,
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) {
        _setEndpoint(_endpointAddress);

        for (uint256 index; index < _chainIdPairs.length; index++) {
            ChainIdPair memory chainIdPair = _chainIdPairs[index];

            _setChainIdPair(chainIdPair.standardId, chainIdPair.layerZeroId);
        }

        _setTargetGasReserve(_targetGasReserve);

        _initRoles(_owner, _managers, _addOwnerToManagers);
    }

    /**
     * @notice Sets the cross-chain endpoint contract reference
     * @param _endpointAddress The address of the cross-chain endpoint contract
     */
    function setEndpoint(address _endpointAddress) external onlyManager {
        _setEndpoint(_endpointAddress);
    }

    /**
     * @notice Adds or updates registered chain ID pairs
     * @param _chainIdPairs The list of chain ID pairs
     */
    function setChainIdPairs(ChainIdPair[] calldata _chainIdPairs) external onlyManager {
        for (uint256 index; index < _chainIdPairs.length; index++) {
            ChainIdPair calldata chainIdPair = _chainIdPairs[index];

            _setChainIdPair(chainIdPair.standardId, chainIdPair.layerZeroId);
        }
    }

    /**
     * @notice Removes registered chain ID pairs
     * @param _standardChainIds The list of standard EVM chain IDs
     */
    function removeChainIdPairs(uint256[] calldata _standardChainIds) external onlyManager {
        for (uint256 index; index < _standardChainIds.length; index++) {
            uint256 standardId = _standardChainIds[index];

            _removeChainIdPair(standardId);
        }
    }

    /**
     * @notice Send a cross-chain message
     * @dev The settings parameter contains an ABI-encoded uint256 value of the target chain gas
     * @param _targetChainId The message target chain ID
     * @param _message The message content
     * @param _settings The gateway-specific settings
     */
    function sendMessage(
        uint256 _targetChainId,
        bytes calldata _message,
        bytes calldata _settings
    ) external payable onlyClient whenNotPaused {
        address peerAddress = _checkPeerAddress(_targetChainId);

        uint16 targetLayerZeroChainId = standardToLayerZeroChainId[_targetChainId];

        if (targetLayerZeroChainId == 0) {
            revert LayerZeroChainIdNotSetError();
        }

        endpoint.send{ value: msg.value }(
            targetLayerZeroChainId,
            abi.encodePacked(peerAddress, address(this)),
            _message,
            payable(client), // refund address
            address(0), // future parameter
            _getAdapterParameters(_settings)
        );
    }

    /**
     * @notice Receives cross-chain messages
     * @dev The function is called by the cross-chain endpoint
     * @param _srcChainId The message source chain ID
     * @param _srcAddress The message source address
     * @param _payload The message content
     */
    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 /*_nonce*/,
        bytes calldata _payload
    ) external nonReentrant onlyEndpoint {
        if (paused()) {
            emit TargetPausedFailure();

            return;
        }

        if (address(client) == address(0)) {
            emit TargetClientNotSetFailure();

            return;
        }

        uint256 sourceStandardChainId = layerZeroToStandardChainId[_srcChainId];

        // use assembly to extract the address
        address fromAddress;
        assembly {
            fromAddress := mload(add(_srcAddress, 20))
        }

        bool condition = sourceStandardChainId != 0 &&
            fromAddress != address(0) &&
            fromAddress == peerMap[sourceStandardChainId];

        if (!condition) {
            emit TargetFromAddressFailure(sourceStandardChainId, fromAddress);

            return;
        }

        (bool hasGasReserve, uint256 gasAllowed) = GasReserveHelper.checkGasReserve(
            targetGasReserve
        );

        if (!hasGasReserve) {
            emit TargetGasReserveFailure(sourceStandardChainId);

            return;
        }

        try
            client.handleExecutionPayload{ gas: gasAllowed }(sourceStandardChainId, _payload)
        {} catch {
            emit TargetExecutionFailure();
        }
    }

    /**
     * @notice Cross-chain message fee estimation
     * @dev The settings parameter contains an ABI-encoded uint256 value of the target chain gas
     * @param _targetChainId The ID of the target chain
     * @param _message The message content
     * @param _settings The gateway-specific settings
     */
    function messageFee(
        uint256 _targetChainId,
        bytes calldata _message,
        bytes calldata _settings
    ) external view returns (uint256) {
        uint16 targetLayerZeroChainId = standardToLayerZeroChainId[_targetChainId];

        (uint256 nativeFee, ) = endpoint.estimateFees(
            targetLayerZeroChainId,
            address(this),
            _message,
            false,
            _getAdapterParameters(_settings)
        );

        return nativeFee;
    }

    function _setEndpoint(address _endpointAddress) private {
        AddressHelper.requireContract(_endpointAddress);

        endpoint = ILayerZeroEndpoint(_endpointAddress);

        emit SetEndpoint(_endpointAddress);
    }

    function _setChainIdPair(uint256 _standardId, uint16 _layerZeroId) private {
        standardToLayerZeroChainId[_standardId] = _layerZeroId;
        layerZeroToStandardChainId[_layerZeroId] = _standardId;

        emit SetChainIdPair(_standardId, _layerZeroId);
    }

    function _removeChainIdPair(uint256 _standardId) private {
        uint16 layerZeroId = standardToLayerZeroChainId[_standardId];

        delete standardToLayerZeroChainId[_standardId];
        delete layerZeroToStandardChainId[layerZeroId];

        emit RemoveChainIdPair(_standardId, layerZeroId);
    }

    function _getAdapterParameters(bytes calldata _settings) private pure returns (bytes memory) {
        uint256 targetGas = abi.decode(_settings, (uint256));

        return abi.encodePacked(ADAPTER_PARAMETERS_VERSION, targetGas);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ITokenBalance } from './interfaces/ITokenBalance.sol';
import { ManagerRole } from './roles/ManagerRole.sol';
import './helpers/TransferHelper.sol' as TransferHelper;
import './Constants.sol' as Constants;

/**
 * @title BalanceManagement
 * @notice Base contract for the withdrawal of tokens, except for reserved ones
 */
abstract contract BalanceManagement is ManagerRole {
    /**
     * @notice Emitted when the specified token is reserved
     */
    error ReservedTokenError();

    /**
     * @notice Performs the withdrawal of tokens, except for reserved ones
     * @dev Use the "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" address for the native token
     * @param _tokenAddress The address of the token
     * @param _tokenAmount The amount of the token
     */
    function cleanup(address _tokenAddress, uint256 _tokenAmount) external onlyManager {
        if (isReservedToken(_tokenAddress)) {
            revert ReservedTokenError();
        }

        if (_tokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            TransferHelper.safeTransferNative(msg.sender, _tokenAmount);
        } else {
            TransferHelper.safeTransfer(_tokenAddress, msg.sender, _tokenAmount);
        }
    }

    /**
     * @notice Getter of the token balance of the current contract
     * @dev Use the "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" address for the native token
     * @param _tokenAddress The address of the token
     * @return The token balance of the current contract
     */
    function tokenBalance(address _tokenAddress) public view returns (uint256) {
        if (_tokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            return address(this).balance;
        } else {
            return ITokenBalance(_tokenAddress).balanceOf(address(this));
        }
    }

    /**
     * @notice Getter of the reserved token flag
     * @dev Override to add reserved token addresses
     * @param _tokenAddress The address of the token
     * @return The reserved token flag
     */
    function isReservedToken(address _tokenAddress) public view virtual returns (bool) {
        // The function returns false by default.
        // The explicit return statement is omitted to avoid the unused parameter warning.
        // See https://github.com/ethereum/solidity/issues/5295
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @dev The default token decimals value
 */
uint256 constant DECIMALS_DEFAULT = 18;

/**
 * @dev The maximum uint256 value for swap amount limit settings
 */
uint256 constant INFINITY = type(uint256).max;

/**
 * @dev The default limit of account list size
 */
uint256 constant LIST_SIZE_LIMIT_DEFAULT = 100;

/**
 * @dev The limit of swap router list size
 */
uint256 constant LIST_SIZE_LIMIT_ROUTERS = 200;

/**
 * @dev The factor for percentage settings. Example: 100 is 0.1%
 */
uint256 constant MILLIPERCENT_FACTOR = 100_000;

/**
 * @dev The de facto standard address to denote the native token
 */
address constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import { IGateway } from './interfaces/IGateway.sol';
import { IGatewayClient } from './interfaces/IGatewayClient.sol';
import { BalanceManagement } from '../BalanceManagement.sol';
import { Pausable } from '../Pausable.sol';
import { TargetGasReserve } from './TargetGasReserve.sol';
import { ZeroAddressError } from '../Errors.sol';
import '../helpers/AddressHelper.sol' as AddressHelper;
import '../Constants.sol' as Constants;
import '../DataStructures.sol' as DataStructures;

/**
 * @title GatewayBase
 * @notice Base contract that implements the cross-chain gateway logic
 */
abstract contract GatewayBase is
    Pausable,
    ReentrancyGuard,
    TargetGasReserve,
    BalanceManagement,
    IGateway
{
    /**
     * @dev Gateway client contract reference
     */
    IGatewayClient public client;

    /**
     * @dev Registered peer gateway addresses by the chain ID
     */
    mapping(uint256 /*peerChainId*/ => address /*peerAddress*/) public peerMap;

    /**
     * @dev Registered peer gateway chain IDs
     */
    uint256[] public peerChainIdList;

    /**
     * @dev Registered peer gateway chain ID indices
     */
    mapping(uint256 /*peerChainId*/ => DataStructures.OptionalValue /*peerChainIdIndex*/)
        public peerChainIdIndexMap;

    /**
     * @notice Emitted when the gateway client contract reference is set
     * @param clientAddress The gateway client contract address
     */
    event SetClient(address indexed clientAddress);

    /**
     * @notice Emitted when a registered peer gateway contract address is added or updated
     * @param chainId The chain ID of the registered peer gateway
     * @param peerAddress The address of the registered peer gateway contract
     */
    event SetPeer(uint256 indexed chainId, address indexed peerAddress);

    /**
     * @notice Emitted when a registered peer gateway contract address is removed
     * @param chainId The chain ID of the registered peer gateway
     */
    event RemovePeer(uint256 indexed chainId);

    /**
     * @notice Emitted when the target chain gateway is paused
     */
    event TargetPausedFailure();

    /**
     * @notice Emitted when the target chain gateway client contract is not set
     */
    event TargetClientNotSetFailure();

    /**
     * @notice Emitted when the message source address does not match the registered peer gateway on the target chain
     * @param sourceChainId The ID of the message source chain
     * @param sourceChainId The address of the message source
     */
    event TargetFromAddressFailure(uint256 indexed sourceChainId, address indexed fromAddress);

    /**
     * @notice Emitted when the gas reserve on the target chain does not allow further action processing
     * @param sourceChainId The ID of the message source chain
     */
    event TargetGasReserveFailure(uint256 indexed sourceChainId);

    /**
     * @notice Emitted when the gateway client execution on the target chain fails
     */
    event TargetExecutionFailure();

    /**
     * @notice Emitted when the caller is not the gateway client contract
     */
    error OnlyClientError();

    /**
     * @notice Emitted when the peer config address for the current chain does not match the current contract
     */
    error PeerAddressMismatchError();

    /**
     * @notice Emitted when the peer gateway address for the specified chain is not set
     */
    error PeerNotSetError();

    /**
     * @notice Emitted when the chain ID is not set
     */
    error ZeroChainIdError();

    /**
     * @dev Modifier to check if the caller is the gateway client contract
     */
    modifier onlyClient() {
        if (msg.sender != address(client)) {
            revert OnlyClientError();
        }

        _;
    }

    /**
     * @notice Sets the gateway client contract reference
     * @param _clientAddress The gateway client contract address
     */
    function setClient(address payable _clientAddress) external virtual onlyManager {
        AddressHelper.requireContract(_clientAddress);

        client = IGatewayClient(_clientAddress);

        emit SetClient(_clientAddress);
    }

    /**
     * @notice Adds or updates registered peer gateways
     * @param _peers Chain IDs and addresses of peer gateways
     */
    function setPeers(
        DataStructures.KeyToAddressValue[] calldata _peers
    ) external virtual onlyManager {
        for (uint256 index; index < _peers.length; index++) {
            DataStructures.KeyToAddressValue calldata item = _peers[index];

            uint256 chainId = item.key;
            address peerAddress = item.value;

            // Allow the same configuration on multiple chains
            if (chainId == block.chainid) {
                if (peerAddress != address(this)) {
                    revert PeerAddressMismatchError();
                }
            } else {
                _setPeer(chainId, peerAddress);
            }
        }
    }

    /**
     * @notice Removes registered peer gateways
     * @param _chainIds Peer gateway chain IDs
     */
    function removePeers(uint256[] calldata _chainIds) external virtual onlyManager {
        for (uint256 index; index < _chainIds.length; index++) {
            uint256 chainId = _chainIds[index];

            // Allow the same configuration on multiple chains
            if (chainId != block.chainid) {
                _removePeer(chainId);
            }
        }
    }

    /**
     * @notice Getter of the peer gateway count
     * @return The peer gateway count
     */
    function peerCount() external view virtual returns (uint256) {
        return peerChainIdList.length;
    }

    /**
     * @notice Getter of the complete list of the peer gateway chain IDs
     * @return The complete list of the peer gateway chain IDs
     */
    function fullPeerChainIdList() external view virtual returns (uint256[] memory) {
        return peerChainIdList;
    }

    function _setPeer(uint256 _chainId, address _peerAddress) internal virtual {
        if (_chainId == 0) {
            revert ZeroChainIdError();
        }

        if (_peerAddress == address(0)) {
            revert ZeroAddressError();
        }

        DataStructures.combinedMapSet(
            peerMap,
            peerChainIdList,
            peerChainIdIndexMap,
            _chainId,
            _peerAddress,
            Constants.LIST_SIZE_LIMIT_DEFAULT
        );

        emit SetPeer(_chainId, _peerAddress);
    }

    function _removePeer(uint256 _chainId) internal virtual {
        if (_chainId == 0) {
            revert ZeroChainIdError();
        }

        DataStructures.combinedMapRemove(peerMap, peerChainIdList, peerChainIdIndexMap, _chainId);

        emit RemovePeer(_chainId);
    }

    function _checkPeerAddress(uint256 _chainId) internal virtual returns (address) {
        address peerAddress = peerMap[_chainId];

        if (peerAddress == address(0)) {
            revert PeerNotSetError();
        }

        return peerAddress;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title IGateway
 * @notice Cross-chain gateway interface
 */
interface IGateway {
    /**
     * @notice Send a cross-chain message
     * @param _targetChainId The message target chain ID
     * @param _message The message content
     * @param _settings The gateway-specific settings
     */
    function sendMessage(
        uint256 _targetChainId,
        bytes calldata _message,
        bytes calldata _settings
    ) external payable;

    /**
     * @notice Cross-chain message fee estimation
     * @param _targetChainId The ID of the target chain
     * @param _message The message content
     * @param _settings The gateway-specific settings
     */
    function messageFee(
        uint256 _targetChainId,
        bytes calldata _message,
        bytes calldata _settings
    ) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title IGatewayClient
 * @notice Cross-chain gateway client interface
 */
interface IGatewayClient {
    /**
     * @notice Cross-chain message handler on the target chain
     * @dev The function is called by cross-chain gateways
     * @param _messageSourceChainId The ID of the message source chain
     * @param _payloadData The content of the cross-chain message
     */
    function handleExecutionPayload(
        uint256 _messageSourceChainId,
        bytes calldata _payloadData
    ) external;

    /**
     * @notice The standard "receive" function
     */
    receive() external payable;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title ILayerZeroEndpoint
 * @notice LayerZero endpoint interface
 */
interface ILayerZeroEndpoint {
    /**
     * @notice Send a cross-chain message
     * @param _dstChainId The destination chain identifier
     * @param _destination Remote address concatenated with local address packed into 40 bytes
     * @param _payload The message content
     * @param _refundAddress Refund the additional amount to this address
     * @param _zroPaymentAddress The address of the ZRO token holder who would pay for the transaction
     * @param _adapterParam Parameters for the adapter service
     */
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParam
    ) external payable;

    /**
     * @notice Cross-chain message fee estimation
     * @param _dstChainId The destination chain identifier
     * @param _userApplication The application address on the source chain
     * @param _payload The message content
     * @param _payInZRO If false, the user application pays the protocol fee in the native token
     * @param _adapterParam Parameters for the adapter service
     * @return nativeFee The native token fee for the message
     * @return zroFee The ZRO token fee for the message
     */
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ManagerRole } from '../roles/ManagerRole.sol';

/**
 * @title TargetGasReserve
 * @notice Base contract that implements the gas reserve logic for the target chain actions
 */
abstract contract TargetGasReserve is ManagerRole {
    /**
     * @dev The target chain gas reserve value
     */
    uint256 public targetGasReserve;

    /**
     * @notice Emitted when the target chain gas reserve value is set
     * @param gasReserve The target chain gas reserve value
     */
    event SetTargetGasReserve(uint256 gasReserve);

    /**
     * @notice Sets the target chain gas reserve value
     * @param _gasReserve The target chain gas reserve value
     */
    function setTargetGasReserve(uint256 _gasReserve) external onlyManager {
        _setTargetGasReserve(_gasReserve);
    }

    function _setTargetGasReserve(uint256 _gasReserve) internal virtual {
        targetGasReserve = _gasReserve;

        emit SetTargetGasReserve(_gasReserve);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Optional value structure
 * @dev Is used in mappings to allow zero values
 * @param isSet Value presence flag
 * @param value Numeric value
 */
struct OptionalValue {
    bool isSet;
    uint256 value;
}

/**
 * @notice Key-to-value structure
 * @dev Is used as an array parameter item to perform multiple key-value settings
 * @param key Numeric key
 * @param value Numeric value
 */
struct KeyToValue {
    uint256 key;
    uint256 value;
}

/**
 * @notice Key-to-value structure for address values
 * @dev Is used as an array parameter item to perform multiple key-value settings with address values
 * @param key Numeric key
 * @param value Address value
 */
struct KeyToAddressValue {
    uint256 key;
    address value;
}

/**
 * @notice Address-to-flag structure
 * @dev Is used as an array parameter item to perform multiple settings
 * @param account Account address
 * @param flag Flag value
 */
struct AccountToFlag {
    address account;
    bool flag;
}

/**
 * @notice Emitted when a list exceeds the size limit
 */
error ListSizeLimitError();

/**
 * @notice Sets or updates a value in a combined map (a mapping with a key list and key index mapping)
 * @param _map The mapping reference
 * @param _keyList The key list reference
 * @param _keyIndexMap The key list index mapping reference
 * @param _key The numeric key
 * @param _value The address value
 * @param _sizeLimit The map and list size limit
 * @return isNewKey True if the key was just added, otherwise false
 */
function combinedMapSet(
    mapping(uint256 => address) storage _map,
    uint256[] storage _keyList,
    mapping(uint256 => OptionalValue) storage _keyIndexMap,
    uint256 _key,
    address _value,
    uint256 _sizeLimit
) returns (bool isNewKey) {
    isNewKey = !_keyIndexMap[_key].isSet;

    if (isNewKey) {
        uniqueListAdd(_keyList, _keyIndexMap, _key, _sizeLimit);
    }

    _map[_key] = _value;
}

/**
 * @notice Removes a value from a combined map (a mapping with a key list and key index mapping)
 * @param _map The mapping reference
 * @param _keyList The key list reference
 * @param _keyIndexMap The key list index mapping reference
 * @param _key The numeric key
 * @return isChanged True if the combined map was changed, otherwise false
 */
function combinedMapRemove(
    mapping(uint256 => address) storage _map,
    uint256[] storage _keyList,
    mapping(uint256 => OptionalValue) storage _keyIndexMap,
    uint256 _key
) returns (bool isChanged) {
    isChanged = _keyIndexMap[_key].isSet;

    if (isChanged) {
        delete _map[_key];
        uniqueListRemove(_keyList, _keyIndexMap, _key);
    }
}

/**
 * @notice Adds a value to a unique value list (a list with value index mapping)
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The numeric value
 * @param _sizeLimit The list size limit
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueListAdd(
    uint256[] storage _list,
    mapping(uint256 => OptionalValue) storage _indexMap,
    uint256 _value,
    uint256 _sizeLimit
) returns (bool isChanged) {
    isChanged = !_indexMap[_value].isSet;

    if (isChanged) {
        if (_list.length >= _sizeLimit) {
            revert ListSizeLimitError();
        }

        _indexMap[_value] = OptionalValue(true, _list.length);
        _list.push(_value);
    }
}

/**
 * @notice Removes a value from a unique value list (a list with value index mapping)
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The numeric value
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueListRemove(
    uint256[] storage _list,
    mapping(uint256 => OptionalValue) storage _indexMap,
    uint256 _value
) returns (bool isChanged) {
    OptionalValue storage indexItem = _indexMap[_value];

    isChanged = indexItem.isSet;

    if (isChanged) {
        uint256 itemIndex = indexItem.value;
        uint256 lastIndex = _list.length - 1;

        if (itemIndex != lastIndex) {
            uint256 lastValue = _list[lastIndex];
            _list[itemIndex] = lastValue;
            _indexMap[lastValue].value = itemIndex;
        }

        _list.pop();
        delete _indexMap[_value];
    }
}

/**
 * @notice Adds a value to a unique address value list (a list with value index mapping)
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The address value
 * @param _sizeLimit The list size limit
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueAddressListAdd(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value,
    uint256 _sizeLimit
) returns (bool isChanged) {
    isChanged = !_indexMap[_value].isSet;

    if (isChanged) {
        if (_list.length >= _sizeLimit) {
            revert ListSizeLimitError();
        }

        _indexMap[_value] = OptionalValue(true, _list.length);
        _list.push(_value);
    }
}

/**
 * @notice Removes a value from a unique address value list (a list with value index mapping)
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The address value
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueAddressListRemove(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value
) returns (bool isChanged) {
    OptionalValue storage indexItem = _indexMap[_value];

    isChanged = indexItem.isSet;

    if (isChanged) {
        uint256 itemIndex = indexItem.value;
        uint256 lastIndex = _list.length - 1;

        if (itemIndex != lastIndex) {
            address lastValue = _list[lastIndex];
            _list[itemIndex] = lastValue;
            _indexMap[lastValue].value = itemIndex;
        }

        _list.pop();
        delete _indexMap[_value];
    }
}

/**
 * @notice Adds or removes a value to/from a unique address value list (a list with value index mapping)
 * @dev The list size limit is checked on items adding only
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The address value
 * @param _flag The value inclusion flag
 * @param _sizeLimit The list size limit
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueAddressListUpdate(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value,
    bool _flag,
    uint256 _sizeLimit
) returns (bool isChanged) {
    return
        _flag
            ? uniqueAddressListAdd(_list, _indexMap, _value, _sizeLimit)
            : uniqueAddressListRemove(_list, _indexMap, _value);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Emitted when an attempt to burn a token fails
 */
error TokenBurnError();

/**
 * @notice Emitted when an attempt to mint a token fails
 */
error TokenMintError();

/**
 * @notice Emitted when a zero address is specified where it is not allowed
 */
error ZeroAddressError();

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Emitted when the account is not a contract
 * @param account The account address
 */
error NonContractAddressError(address account);

/**
 * @notice Function to check if the account is a contract
 * @return The account contract status flag
 */
function isContract(address _account) view returns (bool) {
    return _account.code.length > 0;
}

/**
 * @notice Function to require an account to be a contract
 */
function requireContract(address _account) view {
    if (!isContract(_account)) {
        revert NonContractAddressError(_account);
    }
}

/**
 * @notice Function to require an account to be a contract or a zero address
 */
function requireContractOrZeroAddress(address _account) view {
    if (_account != address(0)) {
        requireContract(_account);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Function to check if the available gas matches the specified gas reserve value
 * @param _gasReserve Gas reserve value
 * @return hasGasReserve Flag of gas reserve availability
 * @return gasAllowed The remaining gas quantity taking the reserve into account
 */
function checkGasReserve(
    uint256 _gasReserve
) view returns (bool hasGasReserve, uint256 gasAllowed) {
    uint256 gasLeft = gasleft();

    hasGasReserve = gasLeft >= _gasReserve;
    gasAllowed = hasGasReserve ? gasLeft - _gasReserve : 0;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Emitted when an approval action fails
 */
error SafeApproveError();

/**
 * @notice Emitted when a transfer action fails
 */
error SafeTransferError();

/**
 * @notice Emitted when a transferFrom action fails
 */
error SafeTransferFromError();

/**
 * @notice Emitted when a transfer of the native token fails
 */
error SafeTransferNativeError();

/**
 * @notice Safely approve the token to the account
 * @param _token The token address
 * @param _to The token approval recipient address
 * @param _value The token approval amount
 */
function safeApprove(address _token, address _to, uint256 _value) {
    // 0x095ea7b3 is the selector for "approve(address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0x095ea7b3, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeApproveError();
    }
}

/**
 * @notice Safely transfer the token to the account
 * @param _token The token address
 * @param _to The token transfer recipient address
 * @param _value The token transfer amount
 */
function safeTransfer(address _token, address _to, uint256 _value) {
    // 0xa9059cbb is the selector for "transfer(address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0xa9059cbb, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeTransferError();
    }
}

/**
 * @notice Safely transfer the token between the accounts
 * @param _token The token address
 * @param _from The token transfer source address
 * @param _to The token transfer recipient address
 * @param _value The token transfer amount
 */
function safeTransferFrom(address _token, address _from, address _to, uint256 _value) {
    // 0x23b872dd is the selector for "transferFrom(address,address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0x23b872dd, _from, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeTransferFromError();
    }
}

/**
 * @notice Safely transfer the native token to the account
 * @param _to The native token transfer recipient address
 * @param _value The native token transfer amount
 */
function safeTransferNative(address _to, uint256 _value) {
    (bool success, ) = _to.call{ value: _value }(new bytes(0));

    if (!success) {
        revert SafeTransferNativeError();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title ITokenBalance
 * @notice Token balance interface
 */
interface ITokenBalance {
    /**
     * @notice Getter of the token balance by the account
     * @param _account The account address
     * @return Token balance
     */
    function balanceOf(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { Pausable as PausableBase } from '@openzeppelin/contracts/security/Pausable.sol';
import { ManagerRole } from './roles/ManagerRole.sol';

/**
 * @title Pausable
 * @notice Base contract that implements the emergency pause mechanism
 */
abstract contract Pausable is PausableBase, ManagerRole {
    /**
     * @notice Enter pause state
     */
    function pause() external onlyManager whenNotPaused {
        _pause();
    }

    /**
     * @notice Exit pause state
     */
    function unpause() external onlyManager whenPaused {
        _unpause();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { RoleBearers } from './RoleBearers.sol';

/**
 * @title ManagerRole
 * @notice Base contract that implements the Manager role.
 * The manager role is a high-permission role for core team members only.
 * Managers can set vaults and routers addresses, fees, cross-chain protocols,
 * and other parameters for Interchain (cross-chain) swaps and single-network swaps.
 * Please note, the manager role is unique for every contract,
 * hence different addresses may be assigned as managers for different contracts.
 */
abstract contract ManagerRole is Ownable, RoleBearers {
    bytes32 private constant ROLE_KEY = keccak256('Manager');

    /**
     * @notice Emitted when the Manager role status for the account is updated
     * @param account The account address
     * @param value The Manager role status flag
     */
    event SetManager(address indexed account, bool indexed value);

    /**
     * @notice Emitted when the Manager role status for the account is renounced
     * @param account The account address
     */
    event RenounceManagerRole(address indexed account);

    /**
     * @notice Emitted when the caller is not a Manager role bearer
     */
    error OnlyManagerError();

    /**
     * @dev Modifier to check if the caller is a Manager role bearer
     */
    modifier onlyManager() {
        if (!isManager(msg.sender)) {
            revert OnlyManagerError();
        }

        _;
    }

    /**
     * @notice Updates the Manager role status for the account
     * @param _account The account address
     * @param _value The Manager role status flag
     */
    function setManager(address _account, bool _value) public onlyOwner {
        _setRoleBearer(ROLE_KEY, _account, _value);

        emit SetManager(_account, _value);
    }

    /**
     * @notice Renounces the Manager role
     */
    function renounceManagerRole() external onlyManager {
        _setRoleBearer(ROLE_KEY, msg.sender, false);

        emit RenounceManagerRole(msg.sender);
    }

    /**
     * @notice Getter of the Manager role bearer count
     * @return The Manager role bearer count
     */
    function managerCount() external view returns (uint256) {
        return _roleBearerCount(ROLE_KEY);
    }

    /**
     * @notice Getter of the complete list of the Manager role bearers
     * @return The complete list of the Manager role bearers
     */
    function fullManagerList() external view returns (address[] memory) {
        return _fullRoleBearerList(ROLE_KEY);
    }

    /**
     * @notice Getter of the Manager role bearer status
     * @param _account The account address
     */
    function isManager(address _account) public view returns (bool) {
        return _isRoleBearer(ROLE_KEY, _account);
    }

    function _initRoles(
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) internal {
        address ownerAddress = _owner == address(0) ? msg.sender : _owner;

        for (uint256 index; index < _managers.length; index++) {
            setManager(_managers[index], true);
        }

        if (_addOwnerToManagers && !isManager(ownerAddress)) {
            setManager(ownerAddress, true);
        }

        if (ownerAddress != msg.sender) {
            transferOwnership(ownerAddress);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import '../Constants.sol' as Constants;
import '../DataStructures.sol' as DataStructures;

/**
 * @title RoleBearers
 * @notice Base contract that implements role-based access control
 * @dev A custom implementation providing full role bearer lists
 */
abstract contract RoleBearers {
    mapping(bytes32 /*roleKey*/ => address[] /*roleBearers*/) private roleBearerTable;
    mapping(bytes32 /*roleKey*/ => mapping(address /*account*/ => DataStructures.OptionalValue /*status*/))
        private roleBearerIndexTable;

    function _setRoleBearer(bytes32 _roleKey, address _account, bool _value) internal {
        DataStructures.uniqueAddressListUpdate(
            roleBearerTable[_roleKey],
            roleBearerIndexTable[_roleKey],
            _account,
            _value,
            Constants.LIST_SIZE_LIMIT_DEFAULT
        );
    }

    function _isRoleBearer(bytes32 _roleKey, address _account) internal view returns (bool) {
        return roleBearerIndexTable[_roleKey][_account].isSet;
    }

    function _roleBearerCount(bytes32 _roleKey) internal view returns (uint256) {
        return roleBearerTable[_roleKey].length;
    }

    function _fullRoleBearerList(bytes32 _roleKey) internal view returns (address[] memory) {
        return roleBearerTable[_roleKey];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title SystemVersionId
 * @notice Base contract providing the system version identifier
 */
abstract contract SystemVersionId {
    /**
     * @dev The system version identifier
     */
    uint256 public constant SYSTEM_VERSION_ID = uint256(keccak256('Testnet - Initial B'));
}