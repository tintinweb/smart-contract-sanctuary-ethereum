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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * This smart contract is for brdging and aggregating WrappedSynthr balance;
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "./lzApp/NonblockingLzApp.sol";
import "./libraries/TransferHelper.sol";
import "./util/EnumerableUint16Set.sol";

abstract contract BaseBridge is Ownable, NonblockingLzApp {
    using EnumerableSet for EnumerableSet.Uint16Set;

    EnumerableSet.Uint16Set internal _supportedChains;

    receive() external payable {}

    function supportedChains() external view returns (uint16[] memory) {
        return _supportedChains.values();
    }

    function addSupportedChain(uint16 _chainId) external onlyOwner {
        require(!_supportedChains.contains(_chainId), "Already added");
        _supportedChains.add(_chainId);
    }

    // function removeSupportedChain(uint16 _chainId) external onlyOwner {
    //     require(_supportedChains.contains(_chainId), "Already removed");
    //     _supportedChains.remove(_chainId);
    // }

    function withdrawAsset(address token, uint amount) external onlyOwner {
        if (token == address(0)) {
            TransferHelper.safeTransferETH(msg.sender, amount);
        } else {
            TransferHelper.safeTransfer(token, msg.sender, amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * This smart contract is for aggregating user's collateral balance;
 */

contract CollateralAggregator {
    mapping(bytes32 => mapping(address => uint)) private _collateralByIssuerAggregation; // collateral currency key => user address => amount

    function collateralByIssuerAggregation(bytes32 collateralKey, address account) external view returns (uint) {
        return _collateralByIssuerAggregation[collateralKey][account];
    }

    function depositCollateral(
        address account,
        uint amount,
        bytes32 collateralKey
    ) internal {
        _collateralByIssuerAggregation[collateralKey][account] += amount;
    }

    function withdrawCollateral(
        address account,
        uint amount,
        bytes32 collateralKey
    ) internal {
        _collateralByIssuerAggregation[collateralKey][account] -= amount;
    }

    // Temporary functions for reuse in dev staging
    function refreshCollateral(
        bytes32 collateralKey,
        address account
    ) external {
        delete _collateralByIssuerAggregation[collateralKey][account];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * This smart contract is for aggregation of debt share
 */

contract DebtShareAggregator {
    uint private _debtShareTotalSupply;
    mapping(address => uint) private __debtShareBalanceOf;

    // event Mint(uint16 indexed srcChainId, address indexed account, uint amount);
    // event Burn(uint16 indexed srcChainId, address indexed account, uint amount);

    function debtShareTotalSupply() external view returns (uint) {
        return _debtShareTotalSupply;
    }

    function debtShareBalanceOf(address account) external view returns (uint) {
        return __debtShareBalanceOf[account];
    }

    function _debtShareBalanceOf(address account) internal view returns (uint) {
        return __debtShareBalanceOf[account];
    }

    function mintDebtShare(address account, uint amount) internal {
        __debtShareBalanceOf[account] += amount;
        _debtShareTotalSupply += amount;
    }

    function burnDebtShare(address account, uint amount) internal {
        __debtShareBalanceOf[account] -= amount;
        _debtShareTotalSupply -= amount;
    }

    function refreshDebtShare(address account) external {
        _debtShareTotalSupply -= __debtShareBalanceOf[account];
        __debtShareBalanceOf[account] = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IExchanger {
    function updateDestinationForExchange(
        address recipient,
        bytes32 destinationKey,
        uint destinationAmount
    ) external;
}

// SPDX-License-Identifier: MIT

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
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint _gasLimit,
        bytes calldata _payload
    ) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
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
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) external;

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
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address _userApplication,
        uint _configType
    ) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint _configType,
        bytes calldata _config
    ) external;

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

pragma solidity ^0.8.0;

interface ISynthrIssuer {
    function synthsByAddress(address synthAddress) external view returns (bytes32);

    function destIssue(
        address account,
        bytes32 synthKey,
        uint synthAmount,
        uint debtShare
    ) external;

    function destBurn(
        address account,
        bytes32 synthKey,
        uint synthAmount,
        uint debtShare
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

library TransferHelper {
    function safeTransfer(
        address token,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeTransfer: transfer failed");
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * This smart contract is for brdging and aggregating liquidation rewards;
 * This LZ UA can be said the aggregated LiquidatorRewards.
 */

contract LiquidatorRewardsAggregator {
    struct AccountRewardsEntry {
        uint128 claimable;
        uint128 entryAccumulatedRewards;
    }

    mapping(bytes32 => uint) public accumulatedRewardsPerShare;
    mapping(bytes32 => mapping(address => AccountRewardsEntry)) public entries; // currency key => account => rewards_entry
    mapping(bytes32 => mapping(address => bool)) public initiated; // currency key => account => initialted

    function updateAccumulatedShare(bytes32 currencyKey, uint _increasedShare) internal {
        accumulatedRewardsPerShare[currencyKey] += _increasedShare;
    }

    function updateEntry(
        bytes32 currencyKey,
        uint _debtShare,
        address _account
    ) internal {
        if (!initiated[currencyKey][_account]) {
            entries[currencyKey][_account].entryAccumulatedRewards = uint128(accumulatedRewardsPerShare[currencyKey]);
            initiated[currencyKey][_account] = true;
        } else {
            entries[currencyKey][_account] = AccountRewardsEntry(uint128(earned(currencyKey, _account, _debtShare)), uint128(accumulatedRewardsPerShare[currencyKey]));
        }
    }

    /**
     * @dev this function is the copied version of LiquidatorReward.sol/earn() function
     */
    function earned(
        bytes32 currencyKey,
        address account,
        uint debtShare
    ) public view returns (uint) {
        AccountRewardsEntry memory entry = entries[currencyKey][account];
        // return
        //     debtShare *
        //         .multiplyDecimal(accumulatedRewardsPerShare.sub(entry.entryAccumulatedRewards))
        //         .add(entry.claimable);
        return (debtShare * (accumulatedRewardsPerShare[currencyKey] - entry.entryAccumulatedRewards)) / (10**27) + entry.claimable;
    }

    function refreshAccumulatedRewardsPerShare(bytes32 key, uint value) external {
        accumulatedRewardsPerShare[key] = value;
    }

    function refreshEntries(
        bytes32 currencyKey,
        address account,
        uint128 claimable,
        uint128 entryAccumulatedRewards
    ) external {
        entries[currencyKey][account] = AccountRewardsEntry(claimable, entryAccumulatedRewards);
    }

    function refreshInitiated(
        bytes32 key,
        address account,
        bool value
    ) external {
        initiated[key][account] = value;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroUserApplicationConfig.sol";
import "../interfaces/ILayerZeroEndpoint.sol";
import "../util/BytesLib.sol";

/*
 * a generic LzReceiver implementation
 */

abstract contract LzApp is Ownable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    using BytesLib for bytes;

    ILayerZeroEndpoint public immutable lzEndpoint;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(uint16 => mapping(uint16 => uint)) public minDstGasLookup;
    address public precrime;

    event SetPrecrime(address precrime);
    event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
    event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);
    event SetMinDstGas(uint16 _dstChainId, uint16 _type, uint _minDstGas);

    constructor(address _endpoint) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public virtual override {
        // lzReceive must be called by the endpoint for security
        require(_msgSender() == address(lzEndpoint), "LzApp: invalid endpoint caller");

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(
            _srcAddress.length == trustedRemote.length && trustedRemote.length > 0 && keccak256(_srcAddress) == keccak256(trustedRemote),
            "LzApp: invalid source sending contract"
        );

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual;

    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        uint _nativeFee
    ) internal virtual {
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
        require(trustedRemote.length != 0, "LzApp: destination chain is not a trusted source");
        lzEndpoint.send{value: _nativeFee}(_dstChainId, trustedRemote, _payload, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function _checkGasLimit(
        uint16 _dstChainId,
        uint16 _type,
        bytes memory _adapterParams,
        uint _extraGas
    ) internal view virtual {
        uint providedGasLimit = _getGasLimit(_adapterParams);
        uint minGasLimit = minDstGasLookup[_dstChainId][_type] + _extraGas;
        require(minGasLimit > 0, "LzApp: minGasLimit not set");
        require(providedGasLimit >= minGasLimit, "LzApp: gas limit is too low");
    }

    function _getGasLimit(bytes memory _adapterParams) internal pure virtual returns (uint gasLimit) {
        require(_adapterParams.length >= 34, "LzApp: invalid adapterParams");
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address,
        uint _configType
    ) external view returns (bytes memory) {
        return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
    }

    // generic config for LayerZero user Application
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint _configType,
        bytes calldata _config
    ) external override onlyOwner {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // _path = abi.encodePacked(remoteAddress, localAddress)
    // this function set the trusted path for the cross-chain communication
    function setTrustedRemote(uint16 _srcChainId, bytes calldata _path) external onlyOwner {
        trustedRemoteLookup[_srcChainId] = _path;
        emit SetTrustedRemote(_srcChainId, _path);
    }

    function setTrustedRemoteAddress(uint16 _remoteChainId, bytes calldata _remoteAddress) external onlyOwner {
        trustedRemoteLookup[_remoteChainId] = abi.encodePacked(_remoteAddress, address(this));
        emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }

    function getTrustedRemoteAddress(uint16 _remoteChainId) external view returns (bytes memory) {
        bytes memory path = trustedRemoteLookup[_remoteChainId];
        require(path.length != 0, "LzApp: no trusted path record");
        return path.slice(0, path.length - 20); // the last 20 bytes should be address(this)
    }

    function setPrecrime(address _precrime) external onlyOwner {
        precrime = _precrime;
        emit SetPrecrime(_precrime);
    }

    function setMinDstGas(
        uint16 _dstChainId,
        uint16 _packetType,
        uint _minGas
    ) external onlyOwner {
        require(_minGas > 0, "LzApp: invalid minGas");
        minDstGasLookup[_dstChainId][_packetType] = _minGas;
        emit SetMinDstGas(_dstChainId, _packetType, _minGas);
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------
    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LzApp.sol";
import "../util/ExcessivelySafeCall.sol";

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzApp is LzApp {
    using ExcessivelySafeCall for address;

    constructor(address _endpoint) LzApp(_endpoint) {}

    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload, bytes _reason);
    event RetryMessageSuccess(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _payloadHash);

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual override {
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(
            gasleft(),
            150,
            abi.encodeWithSelector(this.nonblockingLzReceive.selector, _srcChainId, _srcAddress, _nonce, _payload)
        );
        // try-catch all errors/exceptions
        if (!success) {
            failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload, reason);
        }
    }

    function nonblockingLzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public virtual {
        // only internal transaction
        require(_msgSender() == address(this), "NonblockingLzApp: caller must be LzApp");
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    //@notice override this function
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual;

    function retryMessage(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public payable virtual {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(payloadHash != bytes32(0), "NonblockingLzApp: no stored message");
        require(keccak256(_payload) == payloadHash, "NonblockingLzApp: invalid payload");
        // clear the stored message
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        // execute the message. revert if it fails again
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
        emit RetryMessageSuccess(_srcChainId, _srcAddress, _nonce, payloadHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * This smart contract is for aggregation of reward in escrow
 */

contract RewardEscrowV2Aggregator {
    mapping(bytes32 => uint) private _totalEscrowedBalance; // currencyKey => amount
    mapping(bytes32 => mapping(address => uint)) private _totalEscrowedAccountBalance; // currencyKey => account => amount

    function totalEscrowedBalance(bytes32 currencyKey) external view returns (uint) {
        return _totalEscrowedBalance[currencyKey];
    }

    function escrowedBalanceOf(bytes32 currencyKey, address account) external view returns (uint) {
        return _totalEscrowedAccountBalance[currencyKey][account];
    }

    function append(
        bytes32 currencyKey,
        address account,
        uint amount
    ) internal {
        _append(currencyKey, account, amount);
    }

    function vest(
        bytes32 currencyKey,
        address account,
        uint amount
    ) internal {
        _vest(currencyKey, account, amount);
    }

    function _append(
        bytes32 currencyKey,
        address account,
        uint amount
    ) private {
        _totalEscrowedAccountBalance[currencyKey][account] += amount;
        _totalEscrowedBalance[currencyKey] += amount;
    }

    function _vest(
        bytes32 currencyKey,
        address account,
        uint amount
    ) private {
        _totalEscrowedAccountBalance[currencyKey][account] -= amount;
        _totalEscrowedBalance[currencyKey] -= amount;
    }

    function refreshTotalEscrowedAccountBalance(
        bytes32 key,
        address account
    ) external {
        _totalEscrowedBalance[key]  -= _totalEscrowedAccountBalance[key][account];
        _totalEscrowedAccountBalance[key][account] = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * This smart contract is for aggregation of synth token such as synthUSD
 */

contract SynthAggregator {
    mapping(bytes32 => uint) private _synthTotalSupply; // token => token total supply
    mapping(bytes32 => mapping(address => uint)) _synthBalanceOf; // token => account => token balance

    function synthTotalSupply(bytes32 currencyKey) external view returns (uint) {
        return _synthTotalSupply[currencyKey];
    }

    function synthBalanceOf(bytes32 currencyKey, address account) external view returns (uint) {
        return _synthBalanceOf[currencyKey][account];
    }

    function issueSynth(
        bytes32 currencyKey,
        address account,
        uint amount
    ) internal {
        _synthBalanceOf[currencyKey][account] += amount;
        _synthTotalSupply[currencyKey] += amount;
    }

    function burnSynth(
        bytes32 currencyKey,
        address account,
        uint amount
    ) internal {
        _synthBalanceOf[currencyKey][account] -= amount;
        _synthTotalSupply[currencyKey] -= amount;
    }

    function synthTransferFrom(
        bytes32 currencyKey,
        address from,
        address to,
        uint amount
    ) internal {
        if (from != address(0)) {
            burnSynth(currencyKey, from, amount);
        }

        if (to != address(0)) {
            issueSynth(currencyKey, to, amount);
        }
    }

    function refreshSynthBalanceOf(
        bytes32 key,
        address account
    ) external {
        _synthTotalSupply[key] -= _synthBalanceOf[key][account];
        _synthBalanceOf[key][account] = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BaseBridge.sol";
import "./CollateralAggregator.sol";
import "./DebtShareAggregator.sol";
import "./LiquidatorRewardsAggregator.sol";
import "./RewardEscrowV2Aggregator.sol";
import "./SynthAggregator.sol";
import "./interfaces/ISynthrIssuer.sol";
import "./interfaces/IExchanger.sol";

interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);
}

contract SynthrBridge is BaseBridge, CollateralAggregator, DebtShareAggregator, LiquidatorRewardsAggregator, RewardEscrowV2Aggregator, SynthAggregator {
    using BytesLib for bytes;
    using EnumerableSet for EnumerableSet.Uint16Set;

    address private _synthrAddressResolver;
    address private _exchangeFeeAddress;

    // LZ Packet types
    uint16 private constant PT_SYNTH_MINT = 1; // including depositing collateral
    uint16 private constant PT_WITHDRAW = 2; // withdraw collateral
    uint16 private constant PT_SYNTH_BURN = 3; // burn synth
    uint16 private constant PT_SYNTH_TRANSFER = 4;
    uint16 private constant PT_EXCHANGE = 5;
    uint16 private constant PT_LIQUIDATE = 6;
    uint16 private constant PT_REWARD_ESCROW_APPEND = 7;
    uint16 private constant PT_REWARD_ESCROW_VEST = 8;

    uint[8] private _lzGas = [200000, 200000, 200000, 200000, 200000, 200000, 200000, 200000];

    uint16 private _selfLZChainId;

    // Events
    event SynthMint(
        address indexed account,
        bytes32 indexed collateralKey,
        bytes32 indexed synthKey,
        uint collateralAmount,
        uint synthAmount,
        uint debtShare,
        uint16 srcChainId,
        uint16 destChainId
    );
    event CollateralWithdraw(address indexed account, bytes32 indexed collateralKey, uint amount, uint16 srcChainId);
    event SynthBurn(address indexed account, bytes32 indexed synthKey, uint synthAmount, uint debtShare, uint16 srcChainId);
    event SynthTransfer(bytes32 indexed currencyKey, address indexed from, address indexed to, uint amount, uint16 srcChainId);
    event SynthExchange(
        address indexed sourceAccount,
        bytes32 indexed sourceKey,
        bytes32 indexed destKey,
        uint sourceAmount,
        address destAccount,
        uint destAmount,
        uint fee,
        uint16 srcChainId,
        uint16 destChainId
    );
    event Liquidate(address indexed account, bytes32 indexed collateralKey, uint collateralAmount, uint debtShare, uint notifyAmount, uint16 srcChainId);
    event REAppend(bytes32 indexed currencyKey, address account, uint amount, uint16 srcChainId);
    event Vest(bytes32 indexed currencyKey, address indexed account, uint amount, uint16 srcChainId);

    constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {}

    function initialize(
        address addressResolver,
        address __exchangeFeeAddress,
        uint16 __selfLZChainId
    ) external onlyOwner {
        _synthrAddressResolver = addressResolver;
        _exchangeFeeAddress = __exchangeFeeAddress;
        _selfLZChainId = __selfLZChainId;
    }

    modifier onlySynthr() {
        require(
            msg.sender == IAddressResolver(_synthrAddressResolver).getAddress("Synthetix") ||
                msg.sender == IAddressResolver(_synthrAddressResolver).getAddress("Issuer") ||
                msg.sender == IAddressResolver(_synthrAddressResolver).getAddress("Exchanger") ||
                msg.sender == IAddressResolver(_synthrAddressResolver).getAddress("RewardEscrowV2") ||
                ISynthrIssuer(IAddressResolver(_synthrAddressResolver).getAddress("Issuer")).synthsByAddress(msg.sender) != bytes32(0),
            "SythrBridge: Caller is not allowed."
        );
        _;
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {
        uint16 packetType;
        assembly {
            packetType := mload(add(_payload, 32))
        }

        if (packetType == PT_SYNTH_MINT) {
            (
                ,
                bytes memory accountForCollateralBytes,
                bytes32 _collateralKey,
                uint _collateralAmount,
                bytes32 _synthKey,
                uint _synthAmount,
                uint _debtShare,
                uint16 _destChainId
            ) = abi.decode(_payload, (uint16, bytes, bytes32, uint, bytes32, uint, uint, uint16));

            address _accountForCollateral = accountForCollateralBytes.toAddress(0);

            if (_destChainId == _selfLZChainId) {
                ISynthrIssuer(IAddressResolver(_synthrAddressResolver).getAddress("Issuer")).destIssue(_accountForCollateral, _synthKey, _synthAmount, _debtShare);
            }

            uint16 __srcChainId = _srcChainId;

            _sendMint(_accountForCollateral, _collateralKey, _collateralAmount, _synthKey, _synthAmount, _debtShare, __srcChainId, _destChainId);
        } else if (packetType == PT_WITHDRAW) {
            (, bytes memory accountBytes, bytes32 collateralKey, uint amount) = abi.decode(_payload, (uint16, bytes, bytes32, uint));
            address account = accountBytes.toAddress(0);

            _sendWithdraw(account, collateralKey, amount);
            emit CollateralWithdraw(account, collateralKey, amount, _srcChainId);
        } else if (packetType == PT_SYNTH_BURN) {
            (, bytes memory accountBytes, bytes32 synthKey, uint synthAmount, uint debtShare) = abi.decode(_payload, (uint16, bytes, bytes32, uint, uint));
            address accountForSynth = accountBytes.toAddress(0);

            ISynthrIssuer(IAddressResolver(_synthrAddressResolver).getAddress("Issuer")).destBurn(accountForSynth, synthKey, synthAmount, debtShare);
            _sendBurn(accountForSynth, synthKey, synthAmount, debtShare);
            emit SynthBurn(accountForSynth, synthKey, synthAmount, debtShare, _srcChainId);
        } else if (packetType == PT_SYNTH_TRANSFER) {
            (, bytes32 currencyKey, bytes memory fromBytes, bytes memory toBytes, uint amount) = abi.decode(_payload, (uint16, bytes32, bytes, bytes, uint));
            address from = fromBytes.toAddress(0);
            address to = toBytes.toAddress(0);

            _sendTransferFrom(currencyKey, from, to, amount);
            emit SynthTransfer(currencyKey, from, to, amount, _srcChainId);
        } else if (packetType == PT_EXCHANGE) {
            (
                ,
                bytes memory sourceAccountBytes,
                bytes32 sourceKey,
                uint sourceAmount,
                bytes memory destAccountBytes,
                bytes32 destKey,
                uint destAmount,
                uint fee,
                uint16 destChainId
            ) = abi.decode(_payload, (uint16, bytes, bytes32, uint, bytes, bytes32, uint, uint, uint16));
            address sourceAccount = sourceAccountBytes.toAddress(0);
            address destAccount = destAccountBytes.toAddress(0);

            if (destChainId == _selfLZChainId) {
                IExchanger(IAddressResolver(_synthrAddressResolver).getAddress("Exchanger")).updateDestinationForExchange(destAccount, destKey, destAmount);
            }

            _sendExchange(sourceAccount, sourceKey, sourceAmount, destAccount, destKey, destAmount, fee);

            uint16 __srcChainId = _srcChainId;
            emit SynthExchange(sourceAccount, sourceKey, destKey, sourceAmount, destAccount, destAmount, fee, __srcChainId, destChainId);
        } else if (packetType == PT_LIQUIDATE) {
            (, bytes memory accountBytes, bytes32 collateralKey, uint collateralAmount, uint debtShare, uint notifyAmount) = abi.decode(
                _payload,
                (uint16, bytes, bytes32, uint, uint, uint)
            );

            address account = accountBytes.toAddress(0);
            _sendLiquidate(account, collateralKey, collateralAmount, debtShare, notifyAmount);

            uint16 __srcChainId = _srcChainId;
            emit Liquidate(account, collateralKey, collateralAmount, debtShare, notifyAmount, __srcChainId);
        } else if (packetType == PT_REWARD_ESCROW_APPEND) {
            (, bytes32 currencyKey, bytes memory accountBytes, uint amount) = abi.decode(_payload, (uint16, bytes32, bytes, uint));
            address account = accountBytes.toAddress(0);
            _sendREAppend(currencyKey, account, amount);
            emit REAppend(currencyKey, account, amount, _srcChainId);
        } else if (packetType == PT_REWARD_ESCROW_VEST) {
            (, bytes32 currencyKey, bytes memory accountBytes, uint amount) = abi.decode(_payload, (uint16, bytes32, bytes, uint));
            address account = accountBytes.toAddress(0);
            _sendVest(currencyKey, account, amount);
            emit Vest(currencyKey, account, amount, _srcChainId);
        } else {
            revert("SynthrBridge: unknow packet type");
        }
    }

    // if destChainId equals to zero, it means minting synth on the same chain.
    // note: should update entry for liquidatorRewards whenever calling this function.
    function sendMint(
        address _accountForCollateral,
        bytes32 _collateralKey,
        uint _collateralAmount,
        address,
        bytes32 _synthKey,
        uint _synthAmount,
        uint _debtShare,
        uint16 _destChainId
    ) external onlySynthr {
        _sendMint(_accountForCollateral, _collateralKey, _collateralAmount, _synthKey, _synthAmount, _debtShare, _selfLZChainId, _destChainId);

        // emit SynthMint(_accountForCollateral, _collateralKey, _synthKey, _collateralAmount, _synthAmount, _debtShare, _selfLZChainId, _destChainId);

        // broadcasting message
        bytes memory lzPayload = abi.encode(
            PT_SYNTH_MINT,
            abi.encodePacked(_accountForCollateral),
            _collateralKey,
            _collateralAmount,
            _synthKey,
            _synthAmount,
            _debtShare,
            _destChainId
        );

        _broadcast(lzPayload, PT_SYNTH_MINT);
    }

    function _sendMint(
        address _accountForCollateral,
        bytes32 _collateralKey,
        uint _collateralAmount,
        bytes32 _synthKey,
        uint _synthAmount,
        uint _debtShare,
        uint16 _srcChainId,
        uint16 _destChainId
    ) private {
        // update collateral
        if (_collateralKey != bytes32(0) && _collateralAmount != 0) {
            depositCollateral(_accountForCollateral, _collateralAmount, _collateralKey);
        }

        // update synth, debt share, liquidator reward
        if (_synthKey != bytes32(0) && _synthAmount != 0) {
            issueSynth(_synthKey, _accountForCollateral, _synthAmount);
            mintDebtShare(_accountForCollateral, _debtShare);
            updateEntry(_collateralKey, _debtShareBalanceOf(_accountForCollateral), _accountForCollateral);
        }

        emit SynthMint(_accountForCollateral, _collateralKey, _synthKey, _collateralAmount, _synthAmount, _debtShare, _srcChainId, _destChainId);
    }

    // withdraw
    function sendWithdraw(
        address account,
        bytes32 collateralKey,
        uint amount
    ) external onlySynthr {
        _sendWithdraw(account, collateralKey, amount);
        emit CollateralWithdraw(account, collateralKey, amount, _selfLZChainId);

        bytes memory lzPayload = abi.encode(PT_WITHDRAW, abi.encodePacked(account), collateralKey, amount);

        _broadcast(lzPayload, PT_WITHDRAW);
    }

    function _sendWithdraw(
        address account,
        bytes32 collateralKey,
        uint amount
    ) private {
        withdrawCollateral(account, amount, collateralKey);
    }

    // should call destBurn function of source contract(SynthrGateway.sol) on the dest chains while broadcasting message
    // note: should update entry for liquidatorRewards whenever calling this function.
    function sendBurn(
        address accountForSynth,
        bytes32 synthKey,
        uint synthAmount,
        uint debtShare
    ) external onlySynthr {
        _sendBurn(accountForSynth, synthKey, synthAmount, debtShare);
        emit SynthBurn(accountForSynth, synthKey, synthAmount, debtShare, _selfLZChainId);

        bytes memory lzPayload = abi.encode(PT_SYNTH_BURN, abi.encodePacked(accountForSynth), synthKey, synthAmount, debtShare);
        _broadcast(lzPayload, PT_SYNTH_BURN);
    }

    function _sendBurn(
        address accountForSynth,
        bytes32 synthKey,
        uint synthAmount,
        uint debtShare
    ) private {
        burnSynth(synthKey, accountForSynth, synthAmount);
        burnDebtShare(accountForSynth, debtShare);

        updateEntry(synthKey, _debtShareBalanceOf(accountForSynth), accountForSynth);
    }

    function sendTransferFrom(
        bytes32 currencyKey,
        address from,
        address to,
        uint amount
    ) external onlySynthr {
        _sendTransferFrom(currencyKey, from, to, amount);

        bytes memory lzPayload = abi.encode(PT_SYNTH_TRANSFER, currencyKey, abi.encodePacked(from), abi.encodePacked(to), amount);
        _broadcast(lzPayload, PT_SYNTH_TRANSFER);
        emit SynthTransfer(currencyKey, from, to, amount, _selfLZChainId);
    }

    function _sendTransferFrom(
        bytes32 currencyKey,
        address from,
        address to,
        uint amount
    ) private {
        synthTransferFrom(currencyKey, from, to, amount);
    }

    struct ExchangeArgs {
        address fromAccount;
        address destAccount;
        bytes32 sourceCurrencyKey;
        bytes32 destCurrencyKey;
        uint sourceAmount;
        uint destAmount;
        uint fee;
        uint reclaimed;
        uint refunded;
        uint16 destChainId;
    }

    function sendExchange(ExchangeArgs calldata args) external onlySynthr {
        _sendExchange(
            args.fromAccount,
            args.sourceCurrencyKey,
            args.sourceAmount + args.reclaimed - args.refunded,
            args.destAccount,
            args.destCurrencyKey,
            args.destAmount,
            args.fee
        );

        emit SynthExchange(
            args.fromAccount,
            args.sourceCurrencyKey,
            args.destCurrencyKey,
            args.sourceAmount + args.reclaimed - args.refunded,
            args.destAccount,
            args.destAmount,
            args.fee,
            _selfLZChainId,
            args.destChainId
        );

        bytes memory lzPayload = abi.encode(
            PT_EXCHANGE,
            abi.encodePacked(args.fromAccount),
            args.sourceCurrencyKey,
            args.sourceAmount,
            abi.encodePacked(args.destAccount),
            args.destCurrencyKey,
            args.destAmount,
            args.fee,
            args.destChainId
        );
        _broadcast(lzPayload, PT_EXCHANGE);
    }

    function _sendExchange(
        address sourceAccount,
        bytes32 sourceKey,
        uint sourceAmount,
        address destAccount,
        bytes32 destKey,
        uint destAmount,
        uint fee
    ) private {
        burnSynth(sourceKey, sourceAccount, sourceAmount);
        issueSynth(destKey, destAccount, destAmount);
        issueSynth(bytes32("sUSD"), _exchangeFeeAddress, fee);
    }

    function sendLiquidate(
        address account,
        bytes32 collateralKey,
        uint collateralAmount,
        uint debtShare,
        uint notifyAmount
    ) external {
        _sendLiquidate(account, collateralKey, collateralAmount, debtShare, notifyAmount);
        emit Liquidate(account, collateralKey, collateralAmount, debtShare, notifyAmount, _selfLZChainId);

        bytes memory lzPayload = abi.encode(PT_LIQUIDATE, abi.encodePacked(account), collateralKey, collateralAmount, debtShare, notifyAmount);
        _broadcast(lzPayload, PT_LIQUIDATE);
    }

    function _sendLiquidate(
        address account,
        bytes32 collateralKey,
        uint collateralAmount,
        uint debtShare,
        uint notifyAmount
    ) private {
        uint currentDebtShareBalance = _debtShareBalanceOf(account);

        updateEntry(collateralKey, currentDebtShareBalance, account);

        burnDebtShare(account, debtShare);

        if (currentDebtShareBalance > debtShare) {
            updateAccumulatedShare(collateralKey, notifyAmount / _debtShareBalanceOf(account));
        }

        withdrawCollateral(account, collateralAmount, collateralKey);
    }

    function sendREAppend(
        bytes32 currencyKey,
        address account,
        uint amount
    ) external {
        _sendREAppend(currencyKey, account, amount);
        emit REAppend(currencyKey, account, amount, _selfLZChainId);

        bytes memory lzPayload = abi.encode(PT_REWARD_ESCROW_APPEND, currencyKey, abi.encodePacked(account), amount);
        _broadcast(lzPayload, PT_REWARD_ESCROW_APPEND);
    }

    function sendVest(
        bytes32 currencyKey,
        address account,
        uint amount
    ) external {
        _sendVest(currencyKey, account, amount);
        emit Vest(currencyKey, account, amount, _selfLZChainId);

        bytes memory lzPayload = abi.encode(PT_REWARD_ESCROW_VEST, currencyKey, abi.encodePacked(account), amount);
        _broadcast(lzPayload, PT_REWARD_ESCROW_VEST);
    }

    function _sendREAppend(
        bytes32 currencyKey,
        address account,
        uint amount
    ) private {
        append(currencyKey, account, amount);
    }

    function _sendVest(
        bytes32 currencyKey,
        address account,
        uint amount
    ) private {
        vest(currencyKey, account, amount);
    }

    function _lzAdapterParam(uint16 packetType) internal view returns (bytes memory) {
        uint16 version = 1;
        uint expectedGas;
        if (packetType == PT_SYNTH_MINT) {
            expectedGas = _lzGas[0];
        } else if (packetType == PT_WITHDRAW) {
            expectedGas = _lzGas[1];
        } else if (packetType == PT_SYNTH_BURN) {
            expectedGas = _lzGas[2];
        } else if (packetType == PT_SYNTH_TRANSFER) {
            expectedGas = _lzGas[3];
        } else if (packetType == PT_EXCHANGE) {
            expectedGas = _lzGas[4];
        } else if (packetType == PT_LIQUIDATE) {
            expectedGas = _lzGas[5];
        } else if (packetType == PT_REWARD_ESCROW_APPEND) {
            expectedGas = _lzGas[6];
        } else if (packetType == PT_REWARD_ESCROW_VEST) {
            expectedGas = _lzGas[7];
        }

        return abi.encodePacked(version, expectedGas);
    }

    function _broadcast(bytes memory lzPayload, uint16 packetType) internal {
        uint lzFee;
        bytes memory _adapterParam = _lzAdapterParam(packetType);
        uint length = _supportedChains.length();

        for (uint ii = 0; ii < length; ii++) {
            (lzFee, ) = ILayerZeroEndpoint(lzEndpoint).estimateFees(_supportedChains.at(ii), address(this), lzPayload, false, _adapterParam);
            _lzSend(_supportedChains.at(ii), lzPayload, payable(address(this)), address(0x0), _adapterParam, lzFee);
        }
    }

    // function lzAdapterParam(uint16 packetType) external view returns (bytes memory) {
    //     return _lzAdapterParam(packetType);
    // }

    // gas setting functions
    function setGas(uint packetType, uint newGas) external onlyOwner {
        _lzGas[packetType - 1] = newGas;
    }

    // function getGas(uint packetType) external view returns (uint) {
    //     return _lzGas[packetType - 1];
    // }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(and(fslot, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00), and(mload(mc), mask)))

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint _start,
        uint _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint _start) internal pure returns (uint) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
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
        mapping(bytes32 => uint) _indexes;
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
        uint valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint toDeleteIndex = valueIndex - 1;
            uint lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

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
    function _length(Set storage set) private view returns (uint) {
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
    function _at(Set storage set, uint index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // UintSet

    struct Uint16Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Uint16Set storage set, uint16 value) internal returns (bool) {
        return _add(set._inner, bytes32(uint(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Uint16Set storage set, uint16 value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Uint16Set storage set, uint16 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Uint16Set storage set) internal view returns (uint) {
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
    function at(Uint16Set storage set, uint index) internal view returns (uint16) {
        return uint16(uint(_at(set._inner, index)));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Uint16Set storage set) internal view returns (uint16[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint16[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.7.6;

library ExcessivelySafeCall {
    uint constant LOW_28_MASK = 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
                _gas, // gas
                _target, // recipient
                0, // ether value
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
                _gas, // gas
                _target, // recipient
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(bytes4 _newSelector, bytes memory _buf) internal pure {
        require(_buf.length >= 4);
        uint _mask = LOW_28_MASK;
        assembly {
            // load the first word of
            let _word := mload(add(_buf, 0x20))
            // mask out the top 4 bytes
            // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}