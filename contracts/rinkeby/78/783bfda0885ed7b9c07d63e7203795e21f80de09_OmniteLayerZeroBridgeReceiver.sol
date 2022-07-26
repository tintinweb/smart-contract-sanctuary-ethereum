//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/layerzero/IOmniteLayerZeroBridgeReceiver.sol";
import "./interfaces/ISystemContext.sol";
import "./interfaces/factory/ICreate2BlueprintContractsFactory.sol";
import "./CollectionsRegistry.sol";
import "./interfaces/INonNativeWrapperInitializable.sol";
import "./interfaces/IBridge.sol";

contract OmniteLayerZeroBridgeReceiver is IOmniteLayerZeroBridgeReceiver {
    using Address for address;

    // required: the LayerZero endpoint which is passed in the constructor
    ILayerZeroEndpoint public endpoint;
    ISystemContext public immutable systemContext;

    uint256 public apiVersion;

    constructor(ISystemContext systemContext_) {
        apiVersion = 0;
        systemContext = systemContext_;
    }

    modifier onlyRole(bytes32 role_) {
        systemContext.omniteAccessControl().checkRole(role_, msg.sender);
        _;
    }

    function setEndpoint(ILayerZeroEndpoint endpoint_)
        external
        virtual
        override
        onlyRole(
            systemContext.omniteAccessControl().BRIDGE_DEFAULT_ADMIN_ROLE()
        )
    {
        endpoint = endpoint_;
    }

    function _handleCall(
        CallData memory callData,
        uint16 srcChainId,
        bytes memory fromAddress,
        uint64 nonce
    ) internal returns (bytes memory) {
        ICollectionRegistry registry = ICollectionRegistry(
            systemContext.getContractAddress("COLLECTIONS_REGISTRY")
        );
        address target = registry.addressOf(callData.collectionId);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = target.call(
            callData.packedData
        );
        if (success) {
            emit CallSuccess(
                srcChainId,
                fromAddress,
                nonce,
                target,
                returnData,
                0
            );
        } else {
            emit CallFailed(
                srcChainId,
                fromAddress,
                nonce,
                target,
                0,
                _getRevertMsg(returnData)
            );
        }
        return returnData;
    }

    function _handleMultiCall(
        MultiCallData memory multiCallData,
        uint16 srcChainId,
        bytes memory fromAddress,
        uint64 nonce
    ) internal returns (bytes[] memory) {
        bytes[] memory multipleReturnData = new bytes[](10);
        for (
            uint256 i = 0;
            i < multiCallData.destinationContracts.length;
            i++
        ) {
            address target = multiCallData.destinationContracts[i];
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returnData) = target.call(
                multiCallData.packedData[i]
            );
            if (success) {
                emit CallSuccess(
                    srcChainId,
                    fromAddress,
                    nonce,
                    target,
                    returnData,
                    uint16(i)
                );
                multipleReturnData[i] = returnData;
            } else {
                emit CallFailed(
                    srcChainId,
                    fromAddress,
                    nonce,
                    target,
                    uint16(i),
                    _getRevertMsg(returnData)
                );
                break;
            }
        }
        return multipleReturnData;
    }

    function _handleDeployToken(
        DeployTokenData memory deployData,
        uint16 srcChainId,
        bytes memory fromAddress,
        uint64 nonce
    ) internal {
        ICreate2BlueprintContractsFactory factory = ICreate2BlueprintContractsFactory(
                systemContext.getContractAddress(
                    "CREATE_2_BLUEPRINT_CONTRACTS_FACTORY"
                )
            );
        bytes memory rawCallData = abi.encodeWithSelector(
            factory.createTokenInstanceByName.selector,
            deployData.blueprintName,
            deployData.ctorParams,
            deployData.collectionId,
            deployData.collectionName,
            deployData.owner
        );

        _handleDeployInternal(rawCallData, srcChainId, fromAddress, nonce);
    }

    function _handleDeployCrowdsale(
        DeployCrowdsaleData memory deployData,
        uint16 srcChainId,
        bytes memory fromAddress,
        uint64 nonce
    ) internal {
        ICreate2BlueprintContractsFactory factory = ICreate2BlueprintContractsFactory(
                systemContext.getContractAddress(
                    "CREATE_2_BLUEPRINT_CONTRACTS_FACTORY"
                )
            );
        bytes memory rawCallData = abi.encodeWithSelector(
            factory.createSimpleContractInstanceByName.selector,
            deployData.blueprintName,
            deployData.ctorParams,
            deployData.collectionId
        );
        _handleDeployInternal(rawCallData, srcChainId, fromAddress, nonce);
    }

    function _handleDeployInternal(
        bytes memory rawCallData,
        uint16 srcChainId,
        bytes memory fromAddress,
        uint64 nonce
    ) internal returns (address) {
        ICreate2BlueprintContractsFactory factory = ICreate2BlueprintContractsFactory(
                systemContext.getContractAddress(
                    "CREATE_2_BLUEPRINT_CONTRACTS_FACTORY"
                )
            );
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = address(factory).call(
            rawCallData
        );
        address deployedContract = abi.decode(returnData, (address));
        if (success) {
            emit ContractDeployed(
                srcChainId,
                fromAddress,
                nonce,
                deployedContract
            );
        } else {
            emit ContractNotDeployed(
                srcChainId,
                fromAddress,
                nonce,
                _getRevertMsg(returnData)
            );
        }
        return deployedContract;
    }

    function _handleUndefined(
        Data memory data,
        uint16 srcChainId,
        bytes memory fromAddress,
        uint64 nonce
    ) internal {
        // some handler that error happened
        emit UndefinedCall(
            srcChainId,
            fromAddress,
            nonce,
            data.operation,
            data.apiVersion,
            data.rawData
        );
    }

    function _handleAll(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal {
        Data memory data = abi.decode(_payload, (Data));

        emit ReceiveEvent(_srcChainId, _fromAddress, _nonce, data.operation);
        if (data.operation == Operation.CALL) {
            CallData memory callData = abi.decode(data.rawData, (CallData));
            _handleCall(callData, _srcChainId, _fromAddress, _nonce);
        } else if (data.operation == Operation.DEPLOY_TOKEN) {
            DeployTokenData memory deployData = abi.decode(
                data.rawData,
                (DeployTokenData)
            );
            _handleDeployToken(deployData, _srcChainId, _fromAddress, _nonce);
        } else if (data.operation == Operation.DEPLOY_CROWDSALE) {
            DeployCrowdsaleData memory deployData = abi.decode(
                data.rawData,
                (DeployCrowdsaleData)
            );
            _handleDeployCrowdsale(
                deployData,
                _srcChainId,
                _fromAddress,
                _nonce
            );
        } else if (data.operation == Operation.MULTI_CALL) {
            MultiCallData memory callData = abi.decode(
                data.rawData,
                (MultiCallData)
            );
            _handleMultiCall(callData, _srcChainId, _fromAddress, _nonce);
        } else {
            _handleUndefined(data, _srcChainId, _fromAddress, _nonce);
        }
    }

    function handleAll(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external virtual override {
        require(msg.sender == address(this), "Not self");
        _handleAll(_srcChainId, _fromAddress, _nonce, _payload);
    }

    function handleAllEstimate(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external virtual override {
        uint256 startGas = gasleft();
        _handleAll(_srcChainId, _fromAddress, _nonce, _payload);
        require(false, Strings.toString(startGas - gasleft()));
    }

    function estimateLzReceiveGas(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external returns (string memory) {
        bool success;
        bytes memory revertMsg;
        // solhint-disable-next-line avoid-low-level-calls
        (success, revertMsg) = address(this).call(
            abi.encodeWithSelector(
                this.handleAllEstimate.selector,
                _srcChainId,
                _fromAddress,
                _nonce,
                _payload
            )
        );

        return _getRevertMsg(revertMsg);
    }

    // overrides lzReceive function in ILayerZeroReceiver.
    // automatically invoked on the receiving chain after the source chain calls endpoint.send(...)
    function lzReceive(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external override {
        // solhint-disable-next-line reason-string
        require(msg.sender == address(endpoint));
        if (systemContext.chainId() < 10000) {
            systemContext.omniteAccessControl().checkRoleBytes(
                systemContext.omniteAccessControl().BRIDGE_ROLE(),
                _fromAddress
            );
        }
        bool success;
        bytes memory revertMsg;

        // solhint-disable-next-line avoid-low-level-calls
        (success, revertMsg) = address(this).call(
            abi.encodeWithSelector(
                this.handleAll.selector,
                _srcChainId,
                _fromAddress,
                _nonce,
                _payload
            )
        );
    }

    function _getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Tx reverted silently";
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
        // All that remains is the revert string
    }

    function forceResume(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        virtual
        override
        onlyRole(
            systemContext.omniteAccessControl().BRIDGE_DEFAULT_ADMIN_ROLE()
        )
    {
        endpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "./IOmniteLayerZeroBridge.sol";
import "./ILayerZeroReceiver.sol";
import "./ILayerZeroEndpoint.sol";
import "../IGrantRoleWithSignature.sol";

interface IOmniteLayerZeroBridgeReceiver is
    IOmniteLayerZeroBridge,
    ILayerZeroReceiver
{
    struct DeployNativeParams {
        string collectionName;
        address refundAddress;
        uint256 gasAmount;
        address owner;
    }

    struct DeployExternalParams {
        address originalCollection;
        string collectionName;
        address refundAddress;
        uint256 gasAmount;
        address owner;
        bytes ctorParams;
    }

    struct SendMessageWithValueParams {
        uint16 chainId;
        bytes bridge;
        bytes buffer;
        address refundAddress;
        uint256 value;
        uint256 gasAmount;
    }

    function setEndpoint(ILayerZeroEndpoint endpoint_) external;

    function forceResume(uint16 _srcChainId, bytes calldata _srcAddress)
        external;

    function handleAllEstimate(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external;

    function handleAll(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../acl/OmniteAccessControl.sol";

interface ISystemContext {
    event ContractRegistered(string indexed name, address addr);
    event ContractUpdated(
        string indexed name,
        address lastAddr,
        address newAddr
    );
    event ContractRemoved(string indexed name);

    error ContractAlreadyRegistered(string name, address addr);
    error ContractNotRegistered(string name);

    function getContractAddress(string calldata _contractName)
        external
        view
        returns (address);

    function registerContract(string calldata _contractName, address _addr)
        external;

    function overrideContract(string calldata _contractName, address _addr)
        external;

    function removeContract(string calldata _contractName) external;

    function contractRegistered(string calldata _contractName)
        external
        returns (bool);

    function setAccessControlList(OmniteAccessControl accessControlList_)
        external;

    function contractUriBase() external view returns (string memory);

    function chainId() external view returns (uint16);

    function chainName() external view returns (string memory);

    function omniteAccessControl() external returns (OmniteAccessControl);

    function multisigWallet() external returns (address);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "./ICreate2ContractsFactory.sol";

interface ICreate2BlueprintContractsFactory is ICreate2ContractsFactory {
    event NewBlueprintRegistered(
        address indexed blueprintAddress,
        string blueprintName
    );
    event NewBlueprintVersionRegistered(
        address indexed blueprintAddress,
        string blueprintName,
        uint16 version
    );

    event NewProxyDeployed(string indexed blueprintName, address proxyAddress);

    function registerNewBlueprint(
        address blueprintAddress,
        string memory blueprintName,
        bool isNative
    ) external;

    function registerNewBlueprintVersion(
        address blueprintAddress,
        string memory blueprintName,
        uint16 version,
        bool forceUpdate
    ) external;

    function deregisterLatestBlueprint(string memory name, bool forceUpdate)
        external;

    function blueprintExists(string memory name) external view returns (bool);

    function getBeaconProxyCreationCode() external pure returns (bytes memory);

    function createTokenInstanceByName(
        string memory blueprintName,
        bytes memory initParams,
        bytes32 collectionId,
        string calldata name,
        address owner
    ) external returns (address);

    function createSimpleContractInstanceByName(
        string memory blueprintName,
        bytes memory initParams,
        bytes32 salt
    ) external returns (address);

    function registerOriginalContract(
        bytes32 collectionId,
        address originalAddress
    ) external;

    function getLatestBlueprint(string calldata blueprintName_)
        external
        view
        returns (address);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/ICollectionRegistry.sol";
import "./interfaces/ISystemContext.sol";

contract CollectionsRegistry is ICollectionRegistry {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct Record {
        address owner;
        address addr;
        string userName;
        string contractName;
        uint16 contractVersion;
    }

    // mapping from collectionId into collection address
    mapping(bytes32 => Record) public records;
    // mapping from address into collection id
    mapping(address => bytes32) public _collections;
    // allows to iterate over records
    mapping(address => EnumerableSet.Bytes32Set) internal userCollections;
    // mapping for non-native original addresses to collection IDs;
    mapping(address => bytes32) public _externalToCollection;

    ISystemContext public systemContext;

    constructor(ISystemContext systemContext_) {
        systemContext = systemContext_;
    }

    function collections(address addr)
        external
        view
        virtual
        override
        returns (bytes32)
    {
        return _collections[addr];
    }

    function externalToCollection(address addr)
        external
        view
        virtual
        override
        returns (bytes32)
    {
        return _externalToCollection[addr];
    }

    modifier onlyRole(bytes32 role_) {
        systemContext.omniteAccessControl().checkRole(role_, msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyRecordOwner(bytes32 collectionId_) {
        // solhint-disable-next-line reason-string
        require(
            records[collectionId_].owner == msg.sender,
            "Ownable: caller is not the record owner"
        );
        _;
    }

    modifier onlyFactoryRole() {
        OmniteAccessControl acl = systemContext.omniteAccessControl();
        acl.checkRole(acl.CONTRACT_FACTORY_ROLE(), msg.sender);
        _;
    }

    /**
     * @dev Adds a new record for a collection.
     * @param collectionId_ The new collection to set.
     * @param owner_ The address of the owner.
     * @param collectionAddress_ The address of the collection contract.
     */
    function registerCollection(
        bytes32 collectionId_,
        string calldata userName_,
        address owner_,
        address collectionAddress_,
        string calldata contractName_,
        uint16 contractVersion_
    ) external virtual override onlyFactoryRole {
        require(!recordExists(collectionId_), "Collection already exists");
        require(
            _collections[collectionAddress_] == bytes32(0x0),
            "Address already in collection"
        );
        _setOwner(collectionId_, owner_);
        _setAddress(collectionId_, collectionAddress_);
        records[collectionId_].userName = userName_;
        records[collectionId_].contractName = contractName_;
        records[collectionId_].contractVersion = contractVersion_;
        _collections[collectionAddress_] = collectionId_;
        emit NewCollection(
            collectionId_,
            userName_,
            owner_,
            collectionAddress_,
            contractName_,
            contractVersion_
        );
    }

    /**
     * @dev Registers mapping from non-native address into collection.
     * @param collectionId_ Id of existing collection.
     * @param originalAddress_ The address of the original NFT contract.
     */
    function registerOriginalAddress(
        bytes32 collectionId_,
        address originalAddress_
    ) external virtual override onlyFactoryRole {
        // solhint-disable-next-line reason-string
        require(
            _externalToCollection[originalAddress_] == bytes32(0),
            "External collection already registered"
        );
        _externalToCollection[originalAddress_] = collectionId_;
    }

    /**
     * @dev Transfers ownership of a collection to a new address. May only be called by the current owner of the node.
     * @param collectionId_ The collection to transfer ownership of.
     * @param owner_ The address of the new owner.
     */
    function setOwner(bytes32 collectionId_, address owner_)
        external
        virtual
        override
        onlyRecordOwner(collectionId_)
    {
        _setOwner(collectionId_, owner_);
        emit TransferOwnership(collectionId_, owner_);
    }

    /**
     * @dev Returns the address that owns the specified node.
     * @param collectionId_ The specified node.
     * @return address of the owner.
     */
    function ownerOf(bytes32 collectionId_)
        external
        view
        virtual
        override
        returns (address)
    {
        address addr = records[collectionId_].owner;
        if (addr == address(this)) {
            return address(0x0);
        }

        return addr;
    }

    /**
     * @dev Returns the collection address for the specified collection.
     * @param collectionId_ The specified collection.
     * @return address of the collection.
     */
    function addressOf(bytes32 collectionId_)
        external
        view
        virtual
        override
        returns (address)
    {
        return records[collectionId_].addr;
    }

    /**
     * @dev Returns whether a record has been imported to the registry.
     * @param collectionId_ The specified node.
     * @return Bool if record exists.
     */
    function recordExists(bytes32 collectionId_)
        public
        view
        virtual
        override
        returns (bool)
    {
        return records[collectionId_].owner != address(0x0);
    }

    struct RecordWithId {
        address addr;
        string name;
        bytes32 id;
    }

    /**
     * @dev Returns a list of owned user collections.
     * @param userAddress_ The specified user.
     * @return A list of RecordWithId
     */
    function listCollectionsPerOwner(address userAddress_)
        external
        view
        returns (RecordWithId[] memory)
    {
        bytes32[] memory _collectionIds = userCollections[userAddress_]
            .values();
        RecordWithId[] memory _recordsResult = new RecordWithId[](
            _collectionIds.length
        );
        for (uint256 i = 0; i < _collectionIds.length; i++) {
            _recordsResult[i].addr = records[_collectionIds[i]].addr;
            _recordsResult[i].name = records[_collectionIds[i]].userName;
            _recordsResult[i].id = _collectionIds[i];
        }
        return _recordsResult;
    }

    function getCollectionIds(address[] memory collectionAddresses_)
        external
        view
        returns (bytes32[] memory)
    {
        bytes32[] memory _collectionIds = new bytes32[](
            collectionAddresses_.length
        );
        for (uint256 i = 0; i < _collectionIds.length; i++) {
            _collectionIds[i] = _collections[collectionAddresses_[i]];
            if (_collectionIds[i] == bytes32(0)) {
                _collectionIds[i] = _externalToCollection[
                    collectionAddresses_[i]
                ];
            }
        }

        return _collectionIds;
    }

    function _setOwner(bytes32 collectionId_, address owner_) internal virtual {
        address prevOwner = records[collectionId_].owner;
        if (prevOwner != address(0x0)) {
            userCollections[prevOwner].remove(collectionId_);
        }

        userCollections[owner_].add(collectionId_);
        records[collectionId_].owner = owner_;
    }

    function _setAddress(bytes32 collectionId_, address collectionAddress_)
        internal
    {
        records[collectionId_].addr = collectionAddress_;
    }

    function getRecord(bytes32 collectionId_)
        public
        view
        returns (Record memory)
    {
        return records[collectionId_];
    }

    function setSystemContext(ISystemContext systemContext_)
        public
        onlyRole(
            systemContext
                .omniteAccessControl()
                .COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE()
        )
    {
        systemContext = systemContext_;
    }

    function updateRecord(Record calldata record_, bytes32 collectionId_)
        public
        onlyRole(
            systemContext
                .omniteAccessControl()
                .COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE()
        )
    {
        records[collectionId_] = record_;
    }

    function updateCollection(address addr_, bytes32 collectionId_)
        public
        onlyRole(
            systemContext
                .omniteAccessControl()
                .COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE()
        )
    {
        _collections[addr_] = collectionId_;
    }

    function updateExternalToCollection(address addr_, bytes32 collectionId_)
        public
        onlyRole(
            systemContext
                .omniteAccessControl()
                .COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE()
        )
    {
        _externalToCollection[addr_] = collectionId_;
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface INonNativeWrapperInitializable {
    function encodeInitializer(address originalContract_)
        external
        pure
        returns (bytes memory);

    function decodeInitializer_NonNativeWrapper(
        bytes memory initializerEncoded_
    ) external pure returns (address originalContract_);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface IBridge {
    enum Operation {
        CALL,
        DEPLOY_TOKEN,
        DEPLOY_CROWDSALE,
        MULTI_CALL,
        ERC721_BRIDGE
    }

    struct Data {
        Operation operation;
        uint256 apiVersion;
        bytes rawData;
    }

    struct CallData {
        bytes32 collectionId;
        bytes packedData;
    }

    struct MultiCallData {
        address[] destinationContracts;
        bytes[] packedData;
    }

    struct DeployTokenData {
        string blueprintName;
        bytes ctorParams;
        bytes32 collectionId;
        string collectionName;
        address owner;
    }

    struct DeployCrowdsaleData {
        string blueprintName;
        bytes ctorParams;
        bytes32 collectionId;
        address owner;
        GrantRoleParams grantRoleParams;
    }

    struct GrantRoleParams {
        bytes grantRoleWithSignature;
        address roleReceiver;
        bytes32 role;
        uint256 signedAt;
        address signer;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../IBridge.sol";

interface IOmniteLayerZeroBridge is IBridge {
    event SendEvent(uint16 destChainId, bytes destBridge, uint64 nonce);
    event ReceiveEvent(
        uint16 chainId,
        bytes fromAddress,
        uint64 nonce,
        Operation operation
    );
    event CallSuccess(
        uint16 indexed chainId,
        bytes indexed fromAddress,
        uint64 indexed nonce,
        address calledContract,
        bytes returnData,
        uint16 index
    );
    event CallFailed(
        uint16 indexed chainId,
        bytes indexed fromAddress,
        uint64 indexed nonce,
        address calledContract,
        uint16 index,
        string error
    );
    event ContractDeployed(
        uint16 indexed chainId,
        bytes indexed fromAddress,
        uint64 indexed nonce,
        address newContract
    );
    event ContractNotDeployed(
        uint16 indexed chainId,
        bytes indexed fromAddress,
        uint64 indexed nonce,
        string error
    );
    event UndefinedCall(
        uint16 indexed chainId,
        bytes indexed fromAddress,
        uint64 indexed nonce,
        Operation operation,
        uint256 apiVersion,
        bytes rawData
    );

    struct DeploymentParams {
        uint16 chainId;
        bytes bridgeAddress;
        uint256 value;
        bytes ctorParams;
        address originalContractAddress;
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface ILayerZeroReceiver {
    // the method which your contract needs to implement to receive messages
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface ILayerZeroEndpoint {
    // the send() method which sends a bytes payload to a another chain
    function send(
        uint16 _chainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable refundAddress,
        address _zroPaymentAddress,
        bytes calldata txParameters
    ) external payable;

    function estimateFees(
        uint16 chainId,
        address userApplication,
        bytes calldata payload,
        bool payInZRO,
        bytes calldata adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    function getInboundNonce(uint16 _chainId, bytes calldata _srcAddress)
        external
        view
        returns (uint64);

    function getOutboundNonce(uint16 _chainId, address _srcAddress)
        external
        view
        returns (uint64);

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface IGrantRoleWithSignature {
    function grantRoleWithSignature(
        address roleReceiver,
        bytes32 role,
        uint256 signedAt,
        address signer,
        bytes memory signature
    ) external;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../interfaces/accessControlList/IAccessControlBytes.sol";
import "../utils/ContextBytes.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../libraries/BytesLib.sol";

abstract contract OmniteAccessControl is
    IAccessControlBytes,
    ERC165,
    ContextBytes
{
    bytes32 public constant CONTROL_LIST_ADMIN_ROLE =
        keccak256("CONTROL_LIST_ADMIN_ROLE");
    bytes32 public constant BRIDGE_DEFAULT_ADMIN_ROLE =
        keccak256("BRIDGE_DEFAULT_ADMIN_ROLE");
    bytes32 public constant SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE =
        keccak256("SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE");
    bytes32 public constant FEE_COLLECTOR_DEFAULT_ADMIN_ROLE =
        keccak256("FEE_COLLECTOR_DEFAULT_ADMIN_ROLE");
    bytes32 public constant COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE =
        keccak256("COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE");
    bytes32 public constant TOKEN_UNLOCK_ROLE = keccak256("TOKEN_UNLOCK_ROLE");
    bytes32 public constant TOKEN_DEFAULT_ADMIN_ROLE =
        keccak256("TOKEN_DEFAULT_ADMIN_ROLE");

    bytes32 public constant SYSTEM_CONTEXT_ROLE =
        keccak256("SYSTEM_CONTEXT_ROLE");
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    bytes32 public constant CONTRACT_FACTORY_ROLE =
        keccak256("CONTRACT_FACTORY_ROLE");
    bytes32 public constant COLLECTION_REGISTRY_ROLE =
        keccak256("COLLECTION_REGISTRY_ROLE");
    bytes32 public constant ACCESS_CONTROL_ROLE =
        keccak256("ACCESS_CONTROL_ROLE");
    bytes32 public constant OWNER_VERIFIER_ROLE =
        keccak256("OWNER_VERIFIER_ROLE");
    bytes32 public constant OMNITE_TOKEN_ROLE = keccak256("OMNITE_TOKEN_ROLE");

    bytes32 public constant FEE_COLLECTOR_ROLE =
        keccak256("FEE_COLLECTOR_ROLE");
    bytes32 public constant NATIVE_TOKEN_ROLE = keccak256("NATIVE_TOKEN_ROLE");
    bytes32 public constant NON_NATIVE_TOKEN_ROLE =
        keccak256("NON_NATIVE_TOKEN_ROLE");

    bytes32 public constant FACETS_REGISTRY_EDITOR_ROLE =
        keccak256("FACETS_REGISTRY_EDITOR_ROLE");

    bytes32 public constant FACETS_REGISTRY_EDITOR_DEFAULT_ADMIN_ROLE =
        keccak256("FACETS_REGISTRY_EDITOR_ROLE");

    struct RoleData {
        mapping(bytes => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSenderBytes());
        _;
    }

    function checkRole(bytes32 role, address account)
        external
        view
        virtual
        override
    {
        return _checkRole(role, toBytes(account));
    }

    function checkRoleBytes(bytes32 role, bytes memory account) external view {
        return _checkRole(role, account);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return hasRoleBytes(role, toBytes(account));
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRoleBytes(bytes32 role, bytes memory account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    function toBytes(address a) public pure returns (bytes memory) {
        return abi.encodePacked(a);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, bytes memory account) internal view {
        if (!hasRoleBytes(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "OmniteAccessControl: account ",
                        toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function toHexString(bytes memory account)
        internal
        pure
        returns (string memory)
    {
        if (account.length == 20) {
            // all eth based addresses
            return
                Strings.toHexString(
                    uint256(uint160(BytesLib.toAddress(account, 0)))
                );
        } else if (account.length <= 32) {
            // most of other addresses if not all of them
            return Strings.toHexString(uint256(BytesLib.toBytes32(account, 0)));
        }
        return string(account); // not supported, just return raw bytes (shouldn't happen)
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGrantedBytes}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRoleBytes(bytes32 role, bytes memory account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRoleBytes(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from bytes `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevokedBytes} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRoleBytes(bytes32 role, bytes memory account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRoleBytes(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        // solhint-disable-next-line reason-string
        require(
            keccak256(toBytes(account)) == keccak256(_msgSenderBytes()),
            "OmniteAccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[toBytes(account)] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _grantRoleBytes(bytes32 role, bytes memory account) private {
        if (!hasRoleBytes(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGrantedBytes(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[toBytes(account)] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    function _revokeRoleBytes(bytes32 role, bytes memory account) private {
        if (hasRoleBytes(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevokedBytes(role, account, _msgSender());
        }
    }

    function bytesToAddress(bytes memory bys)
        public
        pure
        returns (address addr)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function grantNativeTokenRole(address addr) external {
        grantRole(NATIVE_TOKEN_ROLE, addr);
    }

    function grantNonNativeTokenRole(address addr) external {
        grantRole(NON_NATIVE_TOKEN_ROLE, addr);
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole)
        external
        onlyRole(CONTROL_LIST_ADMIN_ROLE)
    {
        _setRoleAdmin(role, adminRole);
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlBytes is IAccessControl {
    /**
     * @dev Emitted when bytes `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGrantedBytes(
        bytes32 indexed role,
        bytes indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when bytes `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevokedBytes(
        bytes32 indexed role,
        bytes indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRoleBytes(bytes32 role, bytes memory account)
        external
        view
        returns (bool);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGrantedBytes}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRoleBytes(bytes32 role, bytes memory account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevokedBytes} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRoleBytes(bytes32 role, bytes memory account) external;

    function checkRole(bytes32 role, address account) external view;
}

//SPDX-License-Identifier: Business Source License 1.1

import "@openzeppelin/contracts/utils/Context.sol";

pragma solidity ^0.8.9;

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
contract ContextBytes is Context {
    function _msgSenderBytes() internal view virtual returns (bytes memory) {
        return abi.encodePacked(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.0 <0.9.0;

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;
        // solhint-disable-next-line no-inline-assembly
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

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
    {
        // solhint-disable-next-line no-inline-assembly
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
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
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

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

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
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;
        // solhint-disable-next-line no-inline-assembly
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
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
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

    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address)
    {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint8)
    {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toBool(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (bool)
    {
        return toUint8(_bytes, _start) == 0;
    }

    function toUint16(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint16)
    {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint32)
    {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint64)
    {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint96)
    {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint128)
    {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint256)
    {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (bytes32)
    {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bool)
    {
        bool success = true;
        // solhint-disable-next-line no-inline-assembly
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

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
        view
        returns (bool)
    {
        bool success = true;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
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
                        // solhint-disable-next-line no-empty-blocks
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface ICreate2ContractsFactory {
    function deployCreate2WithParams(
        bytes memory bytecode,
        bytes memory constructorParams,
        bytes32 salt
    ) external returns (address);

    function deployCreate2(bytes memory bytecode, bytes32 salt)
        external
        returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface ICollectionRegistry {
    // Logged when new record is created.
    event NewCollection(
        bytes32 indexed collectionId,
        string name,
        address owner,
        address addr,
        string contractName,
        uint16 contractVersion
    );

    // Logged when the owner of a node transfers ownership to a new account.
    event TransferOwnership(bytes32 indexed collectionId, address owner);

    // Logged when the resolver for a node changes.
    event NewAddress(bytes32 indexed collectionId, address addr);

    function registerCollection(
        bytes32 collectionId_,
        string calldata name_,
        address owner_,
        address collectionAddress_,
        string calldata contractName_,
        uint16 contractVersion_
    ) external;

    function registerOriginalAddress(
        bytes32 collectionId_,
        address originalAddress_
    ) external;

    function setOwner(bytes32 collectionId_, address owner_) external;

    function ownerOf(bytes32 collectionId_) external view returns (address);

    function addressOf(bytes32 collectionId_) external view returns (address);

    function recordExists(bytes32 collectionId_) external view returns (bool);

    function collections(address addr) external view returns (bytes32);

    function externalToCollection(address addr) external view returns (bytes32);
}