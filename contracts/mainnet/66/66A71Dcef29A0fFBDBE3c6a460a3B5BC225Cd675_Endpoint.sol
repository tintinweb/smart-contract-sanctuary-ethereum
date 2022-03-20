// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./interfaces/ILayerZeroReceiver.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "./interfaces/ILayerZeroMessagingLibrary.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract Endpoint is Ownable, ILayerZeroEndpoint {
    uint16 public immutable chainId;

    // installed libraries and reserved versions
    uint16 public constant BLOCK_VERSION = 65535;
    uint16 public constant DEFAULT_VERSION = 0;
    uint16 public latestVersion;
    mapping(uint16 => ILayerZeroMessagingLibrary) public libraryLookup; // version -> ILayerZeroEndpointLibrary

    // default send/receive libraries
    uint16 public defaultSendVersion;
    uint16 public defaultReceiveVersion;
    ILayerZeroMessagingLibrary public defaultSendLibrary;
    address public defaultReceiveLibraryAddress;

    struct LibraryConfig {
        uint16 sendVersion;
        uint16 receiveVersion;
        address receiveLibraryAddress;
        ILayerZeroMessagingLibrary sendLibrary;
    }

    struct StoredPayload {
        uint64 payloadLength;
        address dstAddress;
        bytes32 payloadHash;
    }

    // user app config = [uaAddress]
    mapping(address => LibraryConfig) public uaConfigLookup;
    // inboundNonce = [srcChainId][srcAddress].
    mapping(uint16 => mapping(bytes => uint64)) public inboundNonce;
    // outboundNonce = [dstChainId][srcAddress].
    mapping(uint16 => mapping(address => uint64)) public outboundNonce;
    // storedPayload = [srcChainId][srcAddress]
    mapping(uint16 => mapping(bytes => StoredPayload)) public storedPayload;

    // library versioning events
    event NewLibraryVersionAdded(uint16 version);
    event DefaultSendVersionSet(uint16 version);
    event DefaultReceiveVersionSet(uint16 version);
    event UaSendVersionSet(address ua, uint16 version);
    event UaReceiveVersionSet(address ua, uint16 version);
    event UaForceResumeReceive(uint16 chainId, bytes srcAddress);
    // payload events
    event PayloadCleared(uint16 srcChainId, bytes srcAddress, uint64 nonce, address dstAddress);
    event PayloadStored(uint16 srcChainId, bytes srcAddress, address dstAddress, uint64 nonce, bytes payload, bytes reason);

    constructor(uint16 _chainId) {
        chainId = _chainId;
    }

    //---------------------------------------------------------------------------
    // send and receive nonreentrant lock
    uint8 internal constant _NOT_ENTERED = 1;
    uint8 internal constant _ENTERED = 2;
    uint8 internal _send_entered_state = 1;
    uint8 internal _receive_entered_state = 1;

    modifier sendNonReentrant() {
        require(_send_entered_state == _NOT_ENTERED, "LayerZero: no send reentrancy");
        _send_entered_state = _ENTERED;
        _;
        _send_entered_state = _NOT_ENTERED;
    }
    modifier receiveNonReentrant() {
        require(_receive_entered_state == _NOT_ENTERED, "LayerZero: no receive reentrancy");
        _receive_entered_state = _ENTERED;
        _;
        _receive_entered_state = _NOT_ENTERED;
    }

    // BLOCK_VERSION is also a valid version
    modifier validVersion(uint16 _version) {
        require(_version <= latestVersion || _version == BLOCK_VERSION, "LayerZero: invalid messaging library version");
        _;
    }

    //---------------------------------------------------------------------------
    // User Application Calls - Endpoint Interface

    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable override sendNonReentrant {
        LibraryConfig storage uaConfig = uaConfigLookup[msg.sender];
        uint64 nonce = ++outboundNonce[_dstChainId][msg.sender];
        _getSendLibrary(uaConfig).send{value: msg.value}(msg.sender, nonce, _dstChainId, _destination, _payload, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    //---------------------------------------------------------------------------
    // authenticated Library (msg.sender) Calls to pass through Endpoint to UA (dstAddress)
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external override receiveNonReentrant {
        // assert and increment the nonce. no message shuffling
        require(_nonce == ++inboundNonce[_srcChainId][_srcAddress], "LayerZero: wrong nonce");

        LibraryConfig storage uaConfig = uaConfigLookup[_dstAddress];

        // authentication to prevent cross-version message validation
        // protects against a malicious library from passing arbitrary data
        if (uaConfig.receiveVersion == DEFAULT_VERSION) {
            require(defaultReceiveLibraryAddress == msg.sender, "LayerZero: invalid default library");
        } else {
            require(uaConfig.receiveLibraryAddress == msg.sender, "LayerZero: invalid library");
        }

        // block if any message blocking
        StoredPayload storage sp = storedPayload[_srcChainId][_srcAddress];
        require(sp.payloadHash == bytes32(0), "LayerZero: in message blocking");

        try ILayerZeroReceiver(_dstAddress).lzReceive{gas: _gasLimit}(_srcChainId, _srcAddress, _nonce, _payload) {
            // success, do nothing, end of the message delivery
        } catch (bytes memory reason) {
            // revert nonce if any uncaught errors/exceptions if the ua chooses the blocking mode
            storedPayload[_srcChainId][_srcAddress] = StoredPayload(uint64(_payload.length), _dstAddress, keccak256(_payload));
            emit PayloadStored(_srcChainId, _srcAddress, _dstAddress, _nonce, _payload, reason);
        }
    }

    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external override receiveNonReentrant {
        StoredPayload storage sp = storedPayload[_srcChainId][_srcAddress];
        require(sp.payloadHash != bytes32(0), "LayerZero: no stored payload");
        require(_payload.length == sp.payloadLength && keccak256(_payload) == sp.payloadHash, "LayerZero: invalid payload");

        address dstAddress = sp.dstAddress;
        // empty the storedPayload
        sp.payloadLength = 0;
        sp.dstAddress = address(0);
        sp.payloadHash = bytes32(0);

        uint64 nonce = inboundNonce[_srcChainId][_srcAddress];

        ILayerZeroReceiver(dstAddress).lzReceive(_srcChainId, _srcAddress, nonce, _payload);
        emit PayloadCleared(_srcChainId, _srcAddress, nonce, dstAddress);
    }

    //---------------------------------------------------------------------------
    // Owner Calls, only new library version upgrade (3 steps)

    // note libraryLookup[0] = 0x0, no library implementation
    // LIBRARY UPGRADE step 1: set _newLayerZeroLibraryAddress be the new version
    function newVersion(address _newLayerZeroLibraryAddress) external onlyOwner {
        require(_newLayerZeroLibraryAddress != address(0x0), "LayerZero: new version cannot be zero address");
        require(latestVersion < 65535, "LayerZero: can not add new messaging library");
        latestVersion++;
        libraryLookup[latestVersion] = ILayerZeroMessagingLibrary(_newLayerZeroLibraryAddress);
        emit NewLibraryVersionAdded(latestVersion);
    }

    // LIBRARY UPGRADE step 2: stop sending messages from the old version
    function setDefaultSendVersion(uint16 _newDefaultSendVersion) external onlyOwner validVersion(_newDefaultSendVersion) {
        require(_newDefaultSendVersion != DEFAULT_VERSION, "LayerZero: default send version must > 0");
        defaultSendVersion = _newDefaultSendVersion;
        defaultSendLibrary = libraryLookup[defaultSendVersion];
        emit DefaultSendVersionSet(_newDefaultSendVersion);
    }

    // LIBRARY UPGRADE step 3: stop receiving messages from the old version
    function setDefaultReceiveVersion(uint16 _newDefaultReceiveVersion) external onlyOwner validVersion(_newDefaultReceiveVersion) {
        require(_newDefaultReceiveVersion != DEFAULT_VERSION, "LayerZero: default receive version must > 0");
        defaultReceiveVersion = _newDefaultReceiveVersion;
        defaultReceiveLibraryAddress = address(libraryLookup[defaultReceiveVersion]);
        emit DefaultReceiveVersionSet(_newDefaultReceiveVersion);
    }

    //---------------------------------------------------------------------------
    // User Application Calls - UA set/get Interface

    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external override validVersion(_version) {
        if (_version == DEFAULT_VERSION) {
            require(defaultSendVersion == defaultReceiveVersion, "LayerZero: can not set Config during DEFAULT migration");
            _version = defaultSendVersion;
        }
        require(_version != BLOCK_VERSION, "LayerZero: can not set config for BLOCK_VERSION");
        libraryLookup[_version].setConfig(_chainId, msg.sender, _configType, _config);
    }

    // Migration step 1: set the send version
    // Define what library the UA points too
    function setSendVersion(uint16 _newVersion) external override validVersion(_newVersion) {
        // write into config
        LibraryConfig storage uaConfig = uaConfigLookup[msg.sender];
        uaConfig.sendVersion = _newVersion;
        // the libraryLookup[BLOCK_VERSION || DEFAULT_VERSION] = 0x0
        uaConfig.sendLibrary = libraryLookup[_newVersion];
        emit UaSendVersionSet(msg.sender, _newVersion);
    }

    // Migration step 2: set the receive version
    // after all messages sent from the old version are received
    // the UA can now safely switch to the new receive version
    // it is the UA's responsibility make sure all messages from the old version are processed
    function setReceiveVersion(uint16 _newVersion) external override validVersion(_newVersion) {
        // write into config
        LibraryConfig storage uaConfig = uaConfigLookup[msg.sender];
        uaConfig.receiveVersion = _newVersion;
        // the libraryLookup[BLOCK_VERSION || DEFAULT_VERSION] = 0x0
        uaConfig.receiveLibraryAddress = address(libraryLookup[_newVersion]);
        emit UaReceiveVersionSet(msg.sender, _newVersion);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override {
        StoredPayload storage sp = storedPayload[_srcChainId][_srcAddress];
        // revert if no messages are cached. safeguard malicious UA behaviour
        require(sp.payloadHash != bytes32(0), "LayerZero: no stored payload");
        require(sp.dstAddress == msg.sender, "LayerZero: invalid caller");

        // empty the storedPayload
        sp.payloadLength = 0;
        sp.dstAddress = address(0);
        sp.payloadHash = bytes32(0);

        // emit the event with the new nonce
        emit UaForceResumeReceive(_srcChainId, _srcAddress);
    }

    //---------------------------------------------------------------------------
    // view helper function

    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParams) external view override returns (uint nativeFee, uint zroFee) {
        LibraryConfig storage uaConfig = uaConfigLookup[_userApplication];
        ILayerZeroMessagingLibrary lib = uaConfig.sendVersion == DEFAULT_VERSION ? defaultSendLibrary : uaConfig.sendLibrary;
        return lib.estimateFees(_dstChainId, _userApplication, _payload, _payInZRO, _adapterParams);
    }

    function _getSendLibrary(LibraryConfig storage uaConfig) internal view returns (ILayerZeroMessagingLibrary) {
        if (uaConfig.sendVersion == DEFAULT_VERSION) {
            // check if the in send-blocking upgrade
            require(defaultSendVersion != BLOCK_VERSION, "LayerZero: default in BLOCK_VERSION");
            return defaultSendLibrary;
        } else {
            // check if the in send-blocking upgrade
            require(uaConfig.sendVersion != BLOCK_VERSION, "LayerZero: in BLOCK_VERSION");
            return uaConfig.sendLibrary;
        }
    }

    function getSendLibraryAddress(address _userApplication) external view override returns (address sendLibraryAddress) {
        LibraryConfig storage uaConfig = uaConfigLookup[_userApplication];
        uint16 sendVersion = uaConfig.sendVersion;
        require(sendVersion != BLOCK_VERSION, "LayerZero: send version is BLOCK_VERSION");
        if (sendVersion == DEFAULT_VERSION) {
            require(defaultSendVersion != BLOCK_VERSION, "LayerZero: send version (default) is BLOCK_VERSION");
            sendLibraryAddress = address(defaultSendLibrary);
        } else {
            sendLibraryAddress = address(uaConfig.sendLibrary);
        }
    }

    function getReceiveLibraryAddress(address _userApplication) external view override returns (address receiveLibraryAddress) {
        LibraryConfig storage uaConfig = uaConfigLookup[_userApplication];
        uint16 receiveVersion = uaConfig.receiveVersion;
        require(receiveVersion != BLOCK_VERSION, "LayerZero: receive version is BLOCK_VERSION");
        if (receiveVersion == DEFAULT_VERSION) {
            require(defaultReceiveVersion != BLOCK_VERSION, "LayerZero: receive version (default) is BLOCK_VERSION");
            receiveLibraryAddress = defaultReceiveLibraryAddress;
        } else {
            receiveLibraryAddress = uaConfig.receiveLibraryAddress;
        }
    }

    function isSendingPayload() external view override returns (bool) {
        return _send_entered_state == _ENTERED;
    }

    function isReceivingPayload() external view override returns (bool) {
        return _receive_entered_state == _ENTERED;
    }

    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view override returns (uint64) {
        return inboundNonce[_srcChainId][_srcAddress];
    }

    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view override returns (uint64) {
        return outboundNonce[_dstChainId][_srcAddress];
    }

    function getChainId() external view override returns (uint16) {
        return chainId;
    }

    function getSendVersion(address _userApplication) external view override returns (uint16) {
        LibraryConfig storage uaConfig = uaConfigLookup[_userApplication];
        return uaConfig.sendVersion == DEFAULT_VERSION ? defaultSendVersion : uaConfig.sendVersion;
    }

    function getReceiveVersion(address _userApplication) external view override returns (uint16) {
        LibraryConfig storage uaConfig = uaConfigLookup[_userApplication];
        return uaConfig.receiveVersion == DEFAULT_VERSION ? defaultReceiveVersion : uaConfig.receiveVersion;
    }

    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view override validVersion(_version) returns (bytes memory) {
        if (_version == DEFAULT_VERSION) {
            require(defaultSendVersion == defaultReceiveVersion, "LayerZero: no DEFAULT config while migration");
            _version = defaultSendVersion;
        }
        require(_version != BLOCK_VERSION, "LayerZero: can not get config for BLOCK_VERSION");
        return libraryLookup[_version].getConfig(_chainId, _userApplication, _configType);
    }

    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view override returns (bool) {
        StoredPayload storage sp = storedPayload[_srcChainId][_srcAddress];
        return sp.payloadHash != bytes32(0);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.7.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroMessagingLibrary {
    // send(), messages will be inflight.
    function send(address _userApplication, uint64 _lastNonce, uint16 _chainId, bytes calldata _destination, bytes calldata _payload, address payable refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // estimate native fee at the send side
    function estimateFees(uint16 _chainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    //---------------------------------------------------------------------------
    // setConfig / getConfig are User Application (UA) functions to specify Oracle, Relayer, blockConfirmations, libraryVersion
    function setConfig(uint16 _chainId, address _userApplication, uint _configType, bytes calldata _config) external;

    function getConfig(uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
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
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}