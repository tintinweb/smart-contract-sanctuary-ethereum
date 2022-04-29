// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

import "./SmartLZBaseVault.sol";

/* solhint-disable */
contract SmartSendVault is SmartLZBaseVault {

    uint32 private _subscriptionFee; // fee charged once on deposit; 1e6
    uint256 public maxPoolSizeLimit;

    address private _usdc;
    address private _triggerServer;
    address private _smartWalletToken;

    uint256 private _depositLimit;
    mapping(address => bool) private _allowList;
    mapping(address => uint64) private nonces; // todo check nonces
    mapping(address => uint256) public _depositAmount;



    modifier onlyTrigger() {
        require(_triggerServer == _msgSender(), "SW_NT"); // Only trigger server allowed to do this
        _;
    }

    event USDCDeposited(address indexed user,
        uint256 usdcAmount,
        uint256 indexed depositAmount,
        uint256 indexed dcMintingAmount);

    event USDCWithdrawn(address indexed user, uint256 usdcAmount);


    function initialize(address _lzEndpoint, uint16 _nativeChainId) initializer public {
        __Ownable_init();

        nativeLZEndpoint = _lzEndpoint;
        nativeChainId = _nativeChainId;

        _depositLimit = 200 * 1e6;
        maxPoolSizeLimit = 10000 * 1e6;
    }


    function deposit(uint256 amount, uint16 dstChainId) external payable {
        require(amount != 0, "SW: zero amount");
         if (dstChainId ==  nativeChainId) {
             _deposit(amount, _msgSender());
         }
         else {
             uint64 nonce = nonces[_msgSender()];
             nonces[_msgSender()] += 1;
             _sendToLZ(amount, _msgSender(), dstChainId, uint16(1));
        }
        emit USDCDeposited(_msgSender(), amount, _depositAmount[_msgSender()], amount);
    }


    function withdraw(uint256 amount, uint16 dstChainId) external payable {
        require(amount != 0, "SW: zero amount");
        if(dstChainId == nativeChainId ) {
            _withdraw(amount, _msgSender());
        }
        else {
            uint64 nonce = nonces[_msgSender()];
            nonces[_msgSender()] += 1;
            _sendToLZ(amount, _msgSender(), dstChainId, uint16(2));
        }
        emit USDCWithdrawn(_msgSender(), amount);
    }


    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64, /*_nonce*/
        bytes memory _payload
    ) external override {
         require(_msgSender() == address(nativeLZEndpoint));
         require(
            _srcAddress.length == remotes[_srcChainId].length && keccak256(_srcAddress) == keccak256(remotes[_srcChainId]),
            "Invalid remote sender address. owner should call setRemote() to enable remote contract"
        );
        (uint256 _amount, address _user, uint16 _flag) = abi.decode(_payload, (uint256, address, uint16));
        //require(_nonce == nonces[_user]); // todo !!!!
        // sentNonces[_msgSender()] += 1;
        if(_flag == 1)  {
             _deposit(_amount, _user);
         }
        if(_flag == 2) {
            _withdraw(_amount, _user);
        }
    }

    fallback() external payable {}

    receive() external payable {}


    function getDeposit(address user) external view returns(uint256) {
        return _depositAmount[user];
    }


    function _deposit(uint256 amount, address sender) internal {
        _depositAmount[sender] += amount;
    }


    function _withdraw(uint256 amount, address sender) internal {
        if (amount >= _depositAmount[sender]) {
            amount = _depositAmount[sender];
        }
        _depositAmount[sender] -= amount;
    }

}
/* solhint-enable */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../integrations/layerzero/ILayerZeroReceiver.sol";
import "../integrations/layerzero/ILayerZeroEndpoint.sol";
import "../integrations/layerzero/ILayerZeroUserApplicationConfig.sol";

abstract contract SmartLZBaseVault is OwnableUpgradeable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {

    uint16  public nativeChainId;
    address  public nativeLZEndpoint;
    mapping(uint16 => bytes) public remotes; // list of strategy

    function setRemote(uint16 _chainId, bytes calldata _remoteAddress) external onlyOwner {
        require(remotes[_chainId].length == 0, "The remote address has already been set for the chainId!");
        remotes[_chainId] = _remoteAddress;
    }


    function setConfig(uint16,/*_version*/uint16 _chainId, uint _configType, bytes calldata _config) external override {
        ILayerZeroEndpoint(nativeLZEndpoint).setConfig(ILayerZeroEndpoint(nativeLZEndpoint).getSendVersion(address(this)),
                                                                                                            _chainId,
                                                                                                            _configType,
                                                                                                            _config);
    }


    function setSendVersion(uint16 version) external override {
        ILayerZeroEndpoint(nativeLZEndpoint).setSendVersion(version);
    }


    function setReceiveVersion(uint16 version) external override {
        ILayerZeroEndpoint(nativeLZEndpoint).setReceiveVersion(version);
    }


    // set the inbound block confirmations
    function setInboundConfirmations(uint16 remoteChainId, uint16 confirmations) external onlyOwner {
        ILayerZeroEndpoint(nativeLZEndpoint).setConfig(
            ILayerZeroEndpoint(nativeLZEndpoint).getSendVersion(address(this)),
            remoteChainId,
            2, // CONFIG_TYPE_INBOUND_BLOCK_CONFIRMATIONS
            abi.encode(confirmations)
        );
    }


    // set outbound block confirmations
    function setOutboundConfirmations(uint16 remoteChainId, uint16 confirmations) external onlyOwner {
        ILayerZeroEndpoint(nativeLZEndpoint).setConfig(
            ILayerZeroEndpoint(nativeLZEndpoint).getSendVersion(address(this)),
            remoteChainId,
            5, // CONFIG_TYPE_OUTBOUND_BLOCK_CONFIRMATIONS
            abi.encode(confirmations)
        );
    }


    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override {
        ILayerZeroEndpoint(nativeLZEndpoint).forceResumeReceive(_srcChainId, _srcAddress);
    }


    function getConfig(uint16, /*_dstChainId*/uint16 _chainId, address, uint _configType) external view returns (bytes memory) {
        return ILayerZeroEndpoint(nativeLZEndpoint).getConfig(ILayerZeroEndpoint(nativeLZEndpoint).getSendVersion(address(this)),
            _chainId,
            address(this),
            _configType);
    }


    function getSendVersion() external view returns (uint16) {
        return ILayerZeroEndpoint(nativeLZEndpoint).getSendVersion(address(this));
    }


    function getReceiveVersion() external view returns (uint16) {
        return ILayerZeroEndpoint(nativeLZEndpoint).getReceiveVersion(address(this));
    }


    function getFeeForTransaction(uint16 _dstChainId, bytes calldata _payload) external view returns(uint256) {
        uint16 version = 1;
        bytes memory _adapterParams = abi.encodePacked(version);
        (uint nativeFee,) =  ILayerZeroEndpoint(nativeLZEndpoint).estimateFees(_dstChainId,
            address(this),
            _payload,
            false,
            _adapterParams);
        return nativeFee;
    }


    function addressToBytes(address a) public pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
        }
    }


    function _sendToLZ(uint256 amount, address user, uint16 dstChainID, uint16 flag) internal {
        uint16 version = 1;
        uint gasAmountForDst = 500000; // todo
        bytes memory _adapterParams = abi.encodePacked(
            version,
            gasAmountForDst
        );
        bytes memory payload = abi.encode(amount, user, flag);

        ILayerZeroEndpoint(nativeLZEndpoint).send{value: msg.value}(dstChainID,
                                                                    remotes[dstChainID],
                                                                    payload,
                                                                    payable(msg.sender),
                                                                    address(0x0),
                                                                    _adapterParams);
    }


    function _generatePayload(uint256 amount, address user, uint16 flag) internal view returns(bytes memory) {
        return abi.encode(amount, user, flag);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}