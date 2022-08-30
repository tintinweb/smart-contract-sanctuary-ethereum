//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/layerzero/ILayerZeroReceiver.sol";
import "./interfaces/layerzero/ILayerZeroEndpoint.sol";
import "./interfaces/layerzero/IOmniteLayerZeroBridgeSender.sol";
import "./interfaces/ISystemContext.sol";
import "./interfaces/factory/ICreate2BlueprintContractsFactory.sol";
import "./interfaces/ICollectionRegistry.sol";
import "./interfaces/INonNativeWrapperInitializable.sol";
import "./interfaces/IFeeCollector.sol";
import "./interfaces/IInitializable.sol";
import "./interfaces/diamond/ERC721/IERC721MintableFacet.sol";
import "./OmniteBridgeSender.sol";

contract OmniteLayerZeroBridgeSender is
    OmniteBridgeSender,
    IOmniteLayerZeroBridgeSender
{
    using Address for address;

    uint64 public constant MAX_URL_LEN = 512;
    uint64 public constant MAX_CALL_DATA_LEN = 8096;
    uint64 public maxNetworks = 16;

    // required: the LayerZero endpoint which is passed in the constructor
    ILayerZeroEndpoint public endpoint;
    ISystemContext public immutable systemContext;

    uint256 public minGas;

    string public constant ERC721_NON_NATIVE_BLUEPRINT_NAME = "ERC721NonNative";
    string public constant ERC721_NATIVE_BLUEPRINT_NAME = "ERC721Native";
    string public constant ERC721_NON_NATIVE_WRAPPER_BLUEPRINT_NAME =
        "NonNativeWrapper";
    string public constant CROWDSALE_BLUEPRINT_NAME = "SimpleNftCrowdsale";

    constructor(ISystemContext systemContext_) OmniteBridgeSender(0) {
        apiVersion = 0;
        systemContext = systemContext_;
        minGas = 100000;
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

    function setMinGas(uint256 minGas_)
        external
        virtual
        override
        onlyRole(
            systemContext.omniteAccessControl().BRIDGE_DEFAULT_ADMIN_ROLE()
        )
    {
        minGas = minGas_;
    }

    function setMaxNetworks(uint64 maxNetworks_)
        external
        virtual
        override
        onlyRole(
            systemContext.omniteAccessControl().BRIDGE_DEFAULT_ADMIN_ROLE()
        )
    {
        maxNetworks = maxNetworks_;
    }

    function _deployNonNativeWrapper(
        DeployExternalParams memory deployData,
        bytes32 collectionId
    ) internal {
        ICreate2BlueprintContractsFactory factory = ICreate2BlueprintContractsFactory(
                systemContext.getContractAddress(
                    "CREATE_2_BLUEPRINT_CONTRACTS_FACTORY"
                )
            );
        INonNativeWrapperInitializable wrapperBlueprint = INonNativeWrapperInitializable(
                factory.getLatestBlueprint(
                    ERC721_NON_NATIVE_WRAPPER_BLUEPRINT_NAME
                )
            );
        factory.createTokenInstanceByName(
            ERC721_NON_NATIVE_WRAPPER_BLUEPRINT_NAME,
            wrapperBlueprint.encodeInitializer(deployData.originalCollection),
            collectionId,
            deployData.collectionName,
            deployData.owner
        );
        factory.registerOriginalContract(
            collectionId,
            deployData.originalCollection
        );
    }

    function _sendMessageWithValue(SendMessageWithValueParams memory params_)
        internal
    //    nativePayment(params_.refundAddress, params_.value)
    {
        require(params_.gasAmount >= minGas, "Gas limit too little");
        // TODO: check value?

        // solhint-disable-next-line check-send-result
        endpoint.send{value: params_.value}(
            params_.chainId,
            params_.bridge,
            params_.buffer,
            payable(params_.refundAddress),
            address(this),
            abi.encodePacked(uint16(1), uint256(params_.gasAmount))
        );

        emit SendEvent(
            params_.chainId,
            params_.bridge,
            endpoint.getOutboundNonce(params_.chainId, address(this))
        );
    }

    modifier nativePayment(address refundAddress_, uint256 valueSent_) {
        IFeeCollector feeCollector = IFeeCollector(
            systemContext.getContractAddress("FEE_COLLECTOR")
        );
        uint256 currentAmount_ = feeCollector.nativeBalance();
        _;
        // check value after user payment
        uint256 diff_ = feeCollector.nativeBalance() - currentAmount_;

        feeCollector.applyFeeAndRefund(
            diff_,
            msg.value,
            payable(refundAddress_)
        );
    }

    function _sendMessage(
        uint16 chainId_,
        bytes calldata bridge_,
        bytes memory buffer_,
        address refundAddress_,
        uint256 gasAmount_
    ) internal {
        _sendMessageWithValue(
            SendMessageWithValueParams({
                chainId: chainId_,
                bridge: bridge_,
                buffer: buffer_,
                refundAddress: refundAddress_,
                value: msg.value,
                gasAmount: gasAmount_
            })
        );
    }

    function mintOnTargetChain(
        uint16 chainId_,
        bytes calldata bridge_,
        address refundAddress_,
        address owner_,
        uint256 mintId_,
        string calldata tokenUri_,
        uint256 gasAmount_
    ) public payable virtual override {
        ICollectionRegistry registry = ICollectionRegistry(
            systemContext.getContractAddress("COLLECTIONS_REGISTRY")
        );
        bytes32 collectionId_ = registry.collections(msg.sender);

        // solhint-disable-next-line reason-string
        require(
            collectionId_ != bytes32(0),
            "Only collection contract can call"
        );
        require(bytes(tokenUri_).length <= MAX_URL_LEN, "token uri to long");
        _sendMessage(
            chainId_,
            bridge_,
            mintOnTargetChainEncode(collectionId_, owner_, mintId_, tokenUri_),
            refundAddress_,
            gasAmount_
        );
    }

    function moveToTargetChain(
        uint16 chainId_,
        bytes calldata bridge_,
        address refundAddress_,
        address addr_,
        uint256 mintId_,
        string calldata tokenUri_,
        uint256 gasAmount_
    ) public payable virtual override {
        ICollectionRegistry registry = ICollectionRegistry(
            systemContext.getContractAddress("COLLECTIONS_REGISTRY")
        );
        bytes32 collectionId_ = registry.collections(msg.sender);

        // solhint-disable-next-line reason-string
        require(
            collectionId_ != bytes32(0),
            "Only collection contract can call"
        );
        require(bytes(tokenUri_).length <= MAX_URL_LEN, "token uri to long");

        _sendMessage(
            chainId_,
            bridge_,
            mintOnTargetChainEncode(collectionId_, addr_, mintId_, tokenUri_),
            refundAddress_,
            gasAmount_
        );
    }

    function _deployExternalCollection(
        bytes32 collectionId_,
        DeploymentParams[] calldata deploymentParams_,
        DeployExternalParams calldata params
    ) public payable {
        require(
            deploymentParams_.length <= maxNetworks,
            "networks config to long"
        );

        IERC721Metadata orig = IERC721Metadata(params.originalCollection);
        bytes memory ctorParams = abi.encode( // TODO what to do with contractURI_???
            orig.name(),
            orig.symbol(),
            systemContext.multisigWallet()
        );

        ctorParams = abi.encodeWithSelector(
            IInitializable.initialize.selector,
            ctorParams
        );

        uint256 totalValue = msg.value;
        for (uint256 i = 0; i < deploymentParams_.length; i++) {
            totalValue -= deploymentParams_[i].value; // raises exception in case of underflow
            require(
                deploymentParams_[i].chainId != systemContext.chainId(),
                "Cannot deploy locally"
            );
            _sendMessageWithValue(
                SendMessageWithValueParams({
                    chainId: deploymentParams_[i].chainId,
                    bridge: deploymentParams_[i].bridgeAddress,
                    buffer: deployTokenContractEncode(
                        ERC721_NON_NATIVE_BLUEPRINT_NAME,
                        collectionId_,
                        ctorParams,
                        params.collectionName,
                        systemContext.multisigWallet()
                    ),
                    refundAddress: params.refundAddress,
                    value: deploymentParams_[i].value,
                    gasAmount: params.gasAmount
                })
            );
        }
    }

    function deployExternalCollection(
        DeploymentParams[] calldata deploymentParams_,
        DeployExternalParams calldata params
    ) public payable {
        // solhint-disable not-rely-on-time
        bytes32 collectionId_ = keccak256(
            abi.encodePacked(block.timestamp, msg.sender)
        );

        ICollectionRegistry registry = ICollectionRegistry(
            systemContext.getContractAddress("COLLECTIONS_REGISTRY")
        );
        require(
            registry.externalToCollection(params.originalCollection) ==
                bytes32(0),
            "Collection already registered"
        );
        // solhint-disable-next-line reason-string
        require(
            IERC721(params.originalCollection).supportsInterface(
                type(IERC721).interfaceId
            ),
            "Original collection is not ERC721"
        );
        // solhint-disable-next-line reason-string
        require(
            IERC721(params.originalCollection).supportsInterface(
                type(IERC721Metadata).interfaceId
            ),
            "Original collection is not IERC721Metadata"
        );

        _deployNonNativeWrapper(params, collectionId_);

        _deployExternalCollection(collectionId_, deploymentParams_, params);
    }

    function deployExternalCollectionOnNewChains(
        bytes32 collectionId_,
        DeploymentParams[] calldata deploymentParams_,
        DeployExternalParams calldata params
    ) public payable {
        ICollectionRegistry collectionRegistry = ICollectionRegistry(
            systemContext.getContractAddress("COLLECTIONS_REGISTRY")
        );

        require(
            collectionRegistry.externalToCollection(
                params.originalCollection
            ) == collectionId_,
            "Collection not registered yet"
        );

        _deployExternalCollection(collectionId_, deploymentParams_, params);
    }

    function deployNativeCollection(
        DeploymentParams[] calldata deploymentParams_,
        DeployNativeParams calldata params
    ) public payable override {
        require(
            deploymentParams_.length <= maxNetworks,
            "networks config to long"
        );
        bytes32 collectionId_ = keccak256(
            abi.encodePacked(block.timestamp, msg.sender)
        );
        uint256 totalValue = msg.value;
        bool localDeploy = false;
        ICreate2BlueprintContractsFactory factory = ICreate2BlueprintContractsFactory(
                systemContext.getContractAddress(
                    "CREATE_2_BLUEPRINT_CONTRACTS_FACTORY"
                )
            );
        for (uint256 i = 0; i < deploymentParams_.length; i++) {
            totalValue -= deploymentParams_[i].value; // raises exception in case of underflow

            if (deploymentParams_[i].chainId == systemContext.chainId()) {
                factory.createTokenInstanceByName(
                    ERC721_NATIVE_BLUEPRINT_NAME,
                    deploymentParams_[i].ctorParams,
                    collectionId_,
                    params.collectionName,
                    params.owner
                );
                localDeploy = true;
            } else {
                _sendMessageWithValue(
                    SendMessageWithValueParams({
                        chainId: deploymentParams_[i].chainId,
                        bridge: deploymentParams_[i].bridgeAddress,
                        buffer: deployTokenContractEncode(
                            ERC721_NATIVE_BLUEPRINT_NAME,
                            collectionId_,
                            deploymentParams_[i].ctorParams,
                            params.collectionName,
                            params.owner
                        ),
                        refundAddress: params.refundAddress,
                        value: deploymentParams_[i].value,
                        gasAmount: params.gasAmount
                    })
                );
            }
        }
        require(localDeploy, "Local deploy is obligatory");
    }

    function deployNativeCollectionOnNewChains(
        bytes32 collectionId_,
        DeploymentParams[] calldata deploymentParams_,
        DeployNativeParams calldata params
    ) external payable override {
        require(
            deploymentParams_.length <= maxNetworks,
            "networks config to long"
        );
        ICollectionRegistry registry = ICollectionRegistry(
            systemContext.getContractAddress("COLLECTIONS_REGISTRY")
        );
        // solhint-disable-next-line reason-string
        require(
            registry.ownerOf(collectionId_) == msg.sender,
            "Only owner of the collection cab deploy"
        );

        uint256 totalValue = msg.value;

        for (uint256 i = 0; i < deploymentParams_.length; i++) {
            totalValue -= deploymentParams_[i].value; // raises exception in case of underflow

            _sendMessageWithValue(
                SendMessageWithValueParams({
                    chainId: deploymentParams_[i].chainId,
                    bridge: deploymentParams_[i].bridgeAddress,
                    buffer: deployTokenContractEncode(
                        ERC721_NATIVE_BLUEPRINT_NAME,
                        collectionId_,
                        deploymentParams_[i].ctorParams,
                        params.collectionName,
                        params.owner
                    ),
                    refundAddress: params.refundAddress,
                    value: deploymentParams_[i].value,
                    gasAmount: params.gasAmount
                })
            );
        }
    }

    function recoverGasDecode(bytes calldata adapterParams)
        public
        pure
        returns (uint256)
    {
        require(adapterParams.length >= 34, "Decode gas failed");
        bytes memory tmp = adapterParams[2:34];
        return abi.decode(tmp, (uint256));
    }

    function getOutboundNonce() public view returns (uint64) {
        return
            endpoint.getOutboundNonce(systemContext.chainId(), address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

import "./IOmniteLayerZeroBridge.sol";
import "./ILayerZeroEndpoint.sol";
import "./ILayerZeroReceiver.sol";

interface IOmniteLayerZeroBridgeSender is IOmniteLayerZeroBridge {
    struct SendMessageWithValueParams {
        uint16 chainId;
        bytes bridge;
        bytes buffer;
        address refundAddress;
        uint256 value;
        uint256 gasAmount;
    }

    struct DeployExternalParams {
        address originalCollection;
        string collectionName;
        address refundAddress;
        uint256 gasAmount;
        address owner;
    }

    struct DeployNativeParams {
        string collectionName;
        address refundAddress;
        uint256 gasAmount;
        address owner;
    }

    function setEndpoint(ILayerZeroEndpoint endpoint_) external;

    function setMinGas(uint256 minGas_) external;

    function setMaxNetworks(uint64 maxNetworks_) external;

    function mintOnTargetChain(
        uint16 chainId_,
        bytes calldata bridge_,
        address refundAddress_,
        address addr_,
        uint256 mintId_,
        string calldata tokenUri_,
        uint256 gasAmount_
    ) external payable;

    function moveToTargetChain(
        uint16 chainId_,
        bytes calldata bridge_,
        address refundAddress_,
        address addr_,
        uint256 mintId_,
        string calldata tokenUri_,
        uint256 gasAmount_
    ) external payable;

    function deployExternalCollection(
        DeploymentParams[] calldata deploymentParams_,
        DeployExternalParams calldata params
    ) external payable;

    function deployNativeCollection(
        DeploymentParams[] calldata deploymentParams_,
        DeployNativeParams calldata params
    ) external payable;

    function deployNativeCollectionOnNewChains(
        bytes32 collectionId_,
        DeploymentParams[] calldata deploymentParams_,
        DeployNativeParams calldata params
    ) external payable;
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

    function omniteAccessControl() external view returns (OmniteAccessControl);

    function multisigWallet() external view returns (address);
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

interface ICollectionRegistry {
    struct Record {
        address owner;
        address addr;
        string userName;
        string contractName;
        uint16 contractVersion;
    }

    struct RecordWithId {
        address addr;
        string name;
        bytes32 id;
    }

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

interface IFeeCollector {
    function applyFeeAndRefund(
        uint256 diff_,
        uint256 valueReturned_,
        address payable refundAddress_
    ) external;

    function setMinimumFee(uint256 minimumFee_) external;

    function setFeeInPercents(uint256 feeInPercents_) external;

    function nativeBalance() external view returns (uint256);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface IInitializable {
    error AlreadyInitialized();

    function initialize(bytes memory initializerEncoded_) external;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface IERC721MintableFacet {
    function mintTo(address to, uint256 tokenId) external;

    function mintToWithUri(
        address to,
        uint256 tokenId,
        string memory tokenUri
    ) external;

    function moveTo(address to, uint256 tokenId) external;

    function moveToWithUri(
        address to,
        uint256 tokenId,
        string memory tokenUri
    ) external;
}

//SPDX-License-Identifier: Business Source License 1.1

import "./interfaces/IBridge.sol";
import "./interfaces/IApiVersion.sol";
import "./interfaces/diamond/ERC721/IERC721MintableFacet.sol";

pragma solidity ^0.8.9;

abstract contract OmniteBridgeSender is IApiVersion, IBridge {
    uint64 public override apiVersion;

    constructor(uint64 apiVersion_) {
        apiVersion = apiVersion_;
    }

    function deployTokenContractEncode(
        string memory blueprintName_,
        bytes32 collectionId_,
        bytes memory ctorParams_,
        string calldata collectionName_,
        address owner_
    ) public view returns (bytes memory) {
        return
            abi.encode(
                Data({
                    operation: Operation.DEPLOY_TOKEN,
                    apiVersion: apiVersion,
                    rawData: abi.encode(
                        DeployTokenData({
                            blueprintName: blueprintName_,
                            ctorParams: ctorParams_,
                            collectionId: collectionId_,
                            collectionName: collectionName_,
                            owner: owner_
                        })
                    )
                })
            );
    }

    function _encodeERC721Call(
        bytes32 collectionId_,
        address owner_,
        uint256 tokenId_,
        string calldata tokenUri_,
        bytes4 selector
    ) public view virtual returns (bytes memory) {
        return
            abi.encode(
                Data({
                    operation: Operation.CALL,
                    apiVersion: apiVersion,
                    rawData: abi.encode(
                        CallData({
                            collectionId: collectionId_,
                            packedData: abi.encodeWithSelector(
                                selector,
                                owner_,
                                tokenId_,
                                tokenUri_
                            )
                        })
                    )
                })
            );
    }

    function moveToTargetChainEncode(
        bytes32 collectionId_,
        address owner_,
        uint256 mintId_,
        string calldata tokenUri_
    ) public view returns (bytes memory) {
        return
            _encodeERC721Call(
                collectionId_,
                owner_,
                mintId_,
                tokenUri_,
                IERC721MintableFacet.moveToWithUri.selector
            );
    }

    function mintOnTargetChainEncode(
        bytes32 collectionId_,
        address owner_,
        uint256 mintId_,
        string calldata tokenUri_
    ) public view virtual returns (bytes memory) {
        return
            _encodeERC721Call(
                collectionId_,
                owner_,
                mintId_,
                tokenUri_,
                IERC721MintableFacet.mintToWithUri.selector
            );
    }

    function callOnTargetChainEncode(
        bytes32 collectionId_,
        bytes calldata callData_
    ) public view returns (bytes memory) {
        return
            abi.encode(
                Data({
                    operation: Operation.CALL,
                    apiVersion: apiVersion,
                    rawData: abi.encode(
                        CallData({
                            collectionId: collectionId_,
                            packedData: callData_
                        })
                    )
                })
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
        uint64 apiVersion;
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
        return toUint256(_bytes, _start) != 0;
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

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface ICreate2ContractsFactory {
    event NewContractDeployed(
        address indexed contractAddress,
        bytes bytecode,
        bytes constructorParams,
        bytes32 salt
    );

    function deployCreate2WithParams(
        bytes memory bytecode,
        bytes memory constructorParams,
        bytes32 salt
    ) external returns (address);

    function deployCreate2(bytes memory bytecode, bytes32 salt)
        external
        returns (address);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface IApiVersion {
    function apiVersion() external view returns (uint64);
}