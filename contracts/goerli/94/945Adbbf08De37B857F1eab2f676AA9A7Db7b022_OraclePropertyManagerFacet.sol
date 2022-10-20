// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../../generic-diamond/BaseMultiPropertyManager.sol";
import "./OraclePropertyManagerFacetStorage.sol";
import "contracts/allianceblock/oracle/oracle-diamond/HookFacetStorage.sol";
import "contracts/allianceblock/oracle/oracle-diamond/OracleNFTFacetStorage.sol";
import "contracts/allianceblock/oracle/libs/LibRoleManager.sol";

contract OraclePropertyManagerFacet is BaseMultiPropertyManager {
    using BaseMultiPropertyManagerStorage for BaseMultiPropertyManagerStorage.Layout;
    using OraclePropertyManagerFacetStorage for OraclePropertyManagerFacetStorage.Layout;
    using OracleNFTFacetStorage for OracleNFTFacetStorage.Layout;
    using HookFacetStorage for HookFacetStorage.Layout;


    bytes32 constant ORACLE_KEY = 0x00;

    /** DUPLICATE EVENTS FROM CONSUMERS FOR TESTING PURPOSES*/
    event UpdateRequested(bytes32 requestId);
    event UpdateReceived(uint256 timestamp, bytes data);

    event RequestCreated(bytes32 id, address consumer);
    event RequestFulfilled(bytes32 indexed id, bytes data, address consumer);
    event RequestCancelled(bytes32 indexed id, address consumer);

    /**
     * @dev Reverts if the request is already pending
     * @param requestId The request ID for fulfillment
     */
    modifier notPendingRequest(bytes32 requestId) {
        require(OraclePropertyManagerFacetStorage.layout().pendingRequests[requestId].mtid == 0, "Request is already pending");
        _;
    }

    function initialize_OraclePMFacet(
        IMetaNFT _mnft,
        IMetaPropertyRegistry _registry,
        bytes32 _category
    ) external {
        require(!OraclePropertyManagerFacetStorage.layout().initialized, "already initialized");
        OraclePropertyManagerFacetStorage.layout().initialized = true;
        OraclePropertyManagerFacetStorage.layout().requestCount = 1;
        __BaseMultiPropertyManager_init_unchained(_mnft, _registry, _category);
        LibRoleManager.__RoleManager_init_unchained();
    }

    /* ============================================================= Requests management ============================================================ */

    function getPendingRequest(bytes32 requestId) external view returns (OraclePropertyManagerFacetStorage.Request memory) {
        return OraclePropertyManagerFacetStorage.layout().pendingRequests[requestId];
    }

    function getPendingRequestsCount() external view returns (uint256) {
        return OraclePropertyManagerFacetStorage.layout().pendingRequestsCount;
    }

    /**
     * @notice Create a request for a property (consumer Name)
     * @param property_ The property to request (name of the consumer)
     * @param inNFT_ Store the result in a ERC721
     * @dev Function called by the backend service, in response to subscriptions (managed in Subscription Facet)
     */
    function createRequest(
        bytes32 property_,
        bool inNFT_
    ) external {
        IBaseConsumer consumer = IBaseConsumer(OraclePropertyManagerFacetStorage.layout().consumers[property_]);
        require(address(consumer) != address(0), "no consumer for property");

        OraclePropertyManagerFacetStorage.Request memory request;

        uint256 mtid_ = _mnft().getOrMintToken(msg.sender, property_);
       

        // Increment request id
        uint256 nonce = OraclePropertyManagerFacetStorage.layout().requestCount;
        OraclePropertyManagerFacetStorage.layout().requestCount = nonce + 1;

        bytes32 requestId = keccak256(abi.encodePacked(this, nonce));

        request.property = property_;
        request.mtid = mtid_;
        request.inNFT = inNFT_;

        OraclePropertyManagerFacetStorage.layout().types[property_] = consumer.getType(); // Store the type of the property

        OraclePropertyManagerFacetStorage.layout().pendingRequests[requestId] = request;

        OraclePropertyManagerFacetStorage.layout().pendingRequestsCount = OraclePropertyManagerFacetStorage.layout().pendingRequestsCount + 1;

        // Request update to consumer
        IBaseConsumer(OraclePropertyManagerFacetStorage.layout().consumers[property_]).requestUpdate(requestId);

        emit RequestCreated(requestId, OraclePropertyManagerFacetStorage.layout().consumers[property_]);
    }

    // TODO : Batch requests

    /**
     * @notice Fulfill a request
     * @param _requestId The request ID for fulfillment
     * @param _data Response data
     * @dev Function called by the backend service, updated by consumers
     */
    function fulfill(bytes32 _requestId, bytes calldata _data) external {
        uint256 mtid = OraclePropertyManagerFacetStorage.layout().pendingRequests[_requestId].mtid;
        require(mtid != 0, "request not found");

        bytes32 property = OraclePropertyManagerFacetStorage.layout().pendingRequests[_requestId].property;

        require(msg.sender == OraclePropertyManagerFacetStorage.layout().consumers[property], "must be called by good consumer");

        // Store in Mnft
        _mnft().setDataBytes(mtid, property, ORACLE_KEY, _data);

        // Mint an NFT if requested
        if (OraclePropertyManagerFacetStorage.layout().pendingRequests[_requestId].inNFT) {
            if (_mnft().getDataSetLength(mtid, property, 0x0000000000000000000000000000000000000000000000000000000000000001) == 0) {
                _mintNFT(mtid, property);
            }
        }

        uint256 pendingRequestsCount = OraclePropertyManagerFacetStorage.layout().pendingRequestsCount;

        // Decrement pending requests count
        OraclePropertyManagerFacetStorage.layout().pendingRequestsCount = pendingRequestsCount - 1;

        // Delete request from pending
        delete OraclePropertyManagerFacetStorage.layout().pendingRequests[_requestId];

        // Trigger hook
        _onFulfill(mtid, property, _data);

        // Store timestamp of last update
        OraclePropertyManagerFacetStorage.layout().propertyLastUpdate[property] = block.timestamp;

        emit RequestFulfilled(_requestId, _data, msg.sender);
    }

    function cancelRequest(bytes32 _requestId) external {
        uint256 mtid = OraclePropertyManagerFacetStorage.layout().pendingRequests[_requestId].mtid;
        require(mtid != 0, "request not found");

        // Delete request from pending
        delete OraclePropertyManagerFacetStorage.layout().pendingRequests[_requestId];

        emit RequestCancelled(_requestId, msg.sender);
    }

    function isFullfilled(bytes32 _requestId) external view returns (bool) {
        return OraclePropertyManagerFacetStorage.layout().pendingRequests[_requestId].mtid == 0;
    }

    /* ============================================================= Consumers management ============================================================ */

    function addConsumer(IBaseConsumer _consumer) external {
        require(LibRoleManager._isAdmin(msg.sender), "Caller must be admin");

        require(address(_consumer) != address(0), "consumer cannot be zero");

        bytes32 prop = _consumer.getName();

        bytes32[] memory properties = new bytes32[](1);

        properties[0] = prop;

        // Adding the property
        _addProperties(properties);

        OraclePropertyManagerFacetStorage.layout().consumers[prop] = address(_consumer);
    }

    function getConsumer(bytes32 _property) external view returns (address) {
        return OraclePropertyManagerFacetStorage.layout().consumers[_property];
    }

    /* ============================================================= Hooks ============================================================ */

    /**
     * @notice Function called each time a request are fulfilled
     */
    function _onFulfill(
        uint256 mtid,
        bytes32 property,
        bytes memory data_
    ) internal {
        BaseHook b = HookFacetStorage.layout().hooksContracts[property];

        if (address(b) == address(0)) {
            //console.log("No hook registered");
        } else {
            bytes memory data = abi.encodeWithSignature("executeHook(uint256,bytes32,bytes)", mtid, property, data_); //Encode a call to HookFacet.executeHooks()
            (bool success, bytes memory returnData) = address(this).call(data);
            if (!success)
                assembly {
                    revert(add(returnData, 32), returnData) // Reverts with an error message from the returnData
                }
        }
    }

    function _mintNFT(uint256 mtid, bytes32 property) internal {
        bytes memory data = abi.encodeWithSignature("mint(uint256,bytes32)", mtid, property); //Encode a call to OracleNFTFacet.mint()
        (bool success, bytes memory returnData) = address(this).call(data);
        if (!success)
            assembly {
                revert(add(returnData, 32), returnData) // Reverts with an error message from the returnData
            }
    }

    /* ============================================================= Property Manager ============================================================ */

    function _mnft() internal view returns (IMetaNFT) {
        return BaseMultiPropertyManagerStorage.layout().mnft;
    }

    function _category() internal view returns (bytes32) {
        return BaseMultiPropertyManagerStorage.layout().category;
    }

    function _registry() internal view returns (IMetaPropertyRegistry) {
        return BaseMultiPropertyManagerStorage.layout().registry;
    }

    function resolvePropertyTransferConflict(
        bytes32 _prop,
        uint256 fromPid,
        uint256 toPid
    ) public override {
        require(false, "Not implemented");
        //super.resolvePropertyTransferConflict(_prop, fromPid, toPid);
    }
}

/* ============================================================= . ============================================================ */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@nexeraprotocol/metanft/contracts/interfaces/IMetaNFT.sol";
import "@nexeraprotocol/metanft/contracts/interfaces/IMetaRestrictions.sol";
import "@nexeraprotocol/metanft/contracts/interfaces/IMetadataGenerator.sol";
import "@nexeraprotocol/metanft/contracts/utils/Metadata.sol";
import "./BaseMultiPropertyManagerStorage.sol";

/**
 * @title Base PropertyManager which handles main tasks of Property Managers
 * @notice  Property Manager contains common methods to assign properties to MetaNFT
 */
contract BaseMultiPropertyManager is IMetadataGenerator {
    using BaseMultiPropertyManagerStorage for BaseMultiPropertyManagerStorage.Layout;

    /**
     * Initialization tasks
     */
    function __BaseMultiPropertyManager_init_unchained(
        IMetaNFT _mnft,
        IMetaPropertyRegistry _registry,
        bytes32 _category
    ) internal virtual {
        require(address(_mnft) != address(0), "_mnft cannot be zero");
        require(address(_registry) != address(0), "_registry cannot be zero");
        // Require : category must be already registered and this contract the manager
        require(_registry.isCategoryManager(_category, address(this)), "category must be registered");

        BaseMultiPropertyManagerStorage.layout().mnft = _mnft;
        BaseMultiPropertyManagerStorage.layout().registry = _registry;
        BaseMultiPropertyManagerStorage.layout().category = _category;

        /* NOTICE */
        /* You should add the below line in a function in your Property Manager */
        /* Call this function after registering your Property Manager */
        // mnft.setOnTransferConflictHook(prop, address(this), this.resolvePropertyTransferConflict.selector);
    }

    /**
     * @notice Adding properties to MetaNFT (in the current category)
     */
    function _addProperties(bytes32[] memory _props) internal virtual {
        BaseMultiPropertyManagerStorage.layout().registry.addCategoryProperty(BaseMultiPropertyManagerStorage.layout().category, _props);

        for (uint256 i = 0; i < _props.length; i++) {
            BaseMultiPropertyManagerStorage.layout().isProperty[_props[i]] = true;
        }
    }

    /**
     * @dev This Hook will be called if during the property transfer process the MetaNFT will find out that both fromPid and toPid have this property.
     * Inside this function you should:
     * - read data stored in the property for fromPid
     * - store that data in the toPid (probably merging it a way suitable for yout business logic)
     * - delete the property on the fromPid (this shows the MetaNFT that conflict is resolved)
     */
    function resolvePropertyTransferConflict(
        bytes32 _prop,
        uint256, /*fromPid*/
        uint256 /*toPid*/
    ) public virtual {
        require(msg.sender == address(BaseMultiPropertyManagerStorage.layout().mnft), "wrong sender");
        require(BaseMultiPropertyManagerStorage.layout().isProperty[_prop], "wrong property");
    }

    // /**
    //  * @dev This Hook will be called (if registered) before transferring the property from fromPid to toPid.
    //  * You can revert here to prevent the transfer
    //  * Don't forget to notifu mnft about this function (in initialization):
    //  * mnft.setBeforePropertyTransferHook(prop, address(this), <your_contract>.beforePropertyTransferHook.selector);
    //  */
    // function beforePropertyTransferHook(bytes32 _prop, uint256 fromPid, uint256 toPid) external virtual {
    //     require(msg.sender == address(mnft), "wrong sender");
    //     require(_prop == prop, "wrong property");
    // }

    /**
     * @dev This function generates Metadata for the property we are managing
     * Should overrive this with some details of the property
     */
    function generateMetadata(
        bytes32 _prop,
        uint256 /*pid*/
    ) public view virtual returns (Metadata.ExtraProperties memory) {
        require(BaseMultiPropertyManagerStorage.layout().isProperty[_prop], "wrong property");
        Metadata.ExtraProperties memory ep;
        return ep;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/utils/AccessControlDiamondStorage.sol";
import "contracts/allianceblock/oracle/libs/LibOracleRoles.sol";

library LibRoleManager {
    using AccessControlDiamondStorage for AccessControlDiamondStorage.Layout;

    function _isDeployer(address caller) internal returns (bool) {
        if (AccessControlDiamondStorage.layout().hasRole(LibOracleRoles.DEFAULT_ADMIN_ROLE, caller)) {
            return true;
        } else {
            return false;
        }
    }

    function _isAdmin(address caller) internal returns (bool) {
        if (
            AccessControlDiamondStorage.layout().hasRole(LibOracleRoles.ADMIN_ROLE, caller) ||
            AccessControlDiamondStorage.layout().hasRole(LibOracleRoles.DEFAULT_ADMIN_ROLE, caller)
        ) {
            return true;
        } else {
            return false;
        }
    }

    function __RoleManager_init_unchained() internal {
        require(!AccessControlDiamondStorage.layout().hasRole(LibOracleRoles.DEFAULT_ADMIN_ROLE, msg.sender), "RoleManager: Already initialized");
        AccessControlDiamondStorage.layout().grantRole(LibOracleRoles.DEFAULT_ADMIN_ROLE, msg.sender, address(this));
    }

    function _grantAdmin(address account) internal {
        require(_isAdmin(msg.sender), "RoleManager: Caller is not an admin");
        AccessControlDiamondStorage.layout().grantRole(LibOracleRoles.ADMIN_ROLE, account, msg.sender);
    }

    function _revokeAdmin(address account) internal {
        require(_isAdmin(msg.sender), "RoleManager: Caller is not an admin");
        AccessControlDiamondStorage.layout().grantRole(LibOracleRoles.ADMIN_ROLE, account, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/allianceblock/oracle/consumers/IBaseConsumer.sol";

library OraclePropertyManagerFacetStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("allianceblock.MetaNFT.managers.allianceblock.oracle.OraclePropertyManagerFacetStorage");

    struct Request {
        bytes32 property;
        uint256 mtid;
        bool inNFT;
        // Duration ?
    }

    struct Layout {
        bool initialized;
        //bytes32 [] properties;  // properties managed by this manager
        uint256 requestCount;
        uint256 pendingRequestsCount;
        mapping(bytes32 => address) consumers; // Properties to consumers address
        mapping(bytes32 => IBaseConsumer.Type) types; // Properties to types
        mapping(bytes32 => Request) pendingRequests; // Ids to request
        mapping(bytes32 => uint256) propertyLastUpdate; // Properties to last update timestamp
    }

    function isExists(bytes32 property) internal view returns (bool) {
        return layout().consumers[property] != address(0);
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/allianceblock/oracle/hooks/BaseHook.sol";

library HookFacetStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("allianceblock.MetaNFT.managers.allianceblock.oracle.HookFacetStorage");

    struct Layout {
        bool initialized;
        mapping(bytes32 => BaseHook) hooksContracts;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library OracleNFTFacetStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("allianceblock.MetaNFT.managers.allianceblock.oracle.OracleNFTFacetStorage");

    struct Layout {
        bool initialized;
        uint248 mintCounter;
        mapping (address => bytes32[]) ownerToProperties;
        mapping (uint248 => address) tidToOwner;
        mapping(uint248 => bytes32) tidToProperty;
        mapping(uint248 => uint256) tidToMtid;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@nexeraprotocol/metanft/contracts/interfaces/IMetaNFT.sol";
import "@nexeraprotocol/metanft/contracts/interfaces/IMetaRestrictions.sol";
import "@nexeraprotocol/metanft/contracts/interfaces/IMetadataGenerator.sol";
import "@nexeraprotocol/metanft/contracts/utils/Metadata.sol";
import "../interfaces/IMetaPropertyRegistry.sol";

library BaseMultiPropertyManagerStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("allianceblock.MetaNFT.managers.generic-diamond.BaseMultiPropertyManagerStorage");

    struct Layout {
        IMetaNFT mnft;
        IMetaPropertyRegistry registry;
        bytes32 category;
        mapping(bytes32 => bool) isProperty;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetaRestrictions {
    struct Restriction {
        bytes32 rtype;
        bytes data;
    }

    function addRestriction(
        uint256 pid,
        bytes32 prop,
        Restriction calldata restr
    ) external returns (uint256 idx);

    function removeRestriction(
        uint256 pid,
        bytes32 prop,
        uint256 ridx
    ) external;

    function removeRestrictions(
        uint256 pid,
        bytes32 prop,
        uint256[] calldata ridxs
    ) external;

    function getRestrictions(uint256 pid, bytes32 prop) external view returns (Restriction[] memory);

    function moveRestrictions(
        uint256 fromPid,
        uint256 toPid,
        bytes32 prop
    ) external returns (uint256[] memory newIdxs);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./StringNumberUtils.sol";

/**
 * @dev Provides functions to generate NFT Metadata
 */
library Metadata {
    //bytes32 internal constant TEMP_STORAGE_SLOT = keccak256("allianceblock.metadata.temporary_extra_properties");

    string private constant URI_PREFIX = "data:application/json;base64,";

    struct BaseERC721Properties {
        string name;
        string description;
        string image;
    }

    struct BaseERC1155Properties {
        string name;
        string description;
        uint8 decimals;
        string image;
    }

    struct StringProperty {
        string name;
        string value;
    }

    struct DateProperty {
        string name;
        int64 value;
    }

    struct IntegerProperty {
        string name;
        int64 value;
    }

    struct DecimalProperty {
        string name;
        int256 value;
        uint8 decimals;
        uint8 precision;
        bool truncate;
    }

    struct ExtraProperties {
        StringProperty[] stringProperties;
        DateProperty[] dateProperties;
        IntegerProperty[] integerProperties;
        DecimalProperty[] decimalProperties;
    }

    function generateERC721Metadata(BaseERC721Properties memory bp, StringProperty[] memory sps) public pure returns (string memory) {
        ExtraProperties memory ep;
        ep.stringProperties = sps;
        ep.dateProperties = new DateProperty[](0);
        ep.integerProperties = new IntegerProperty[](0);
        ep.decimalProperties = new DecimalProperty[](0);
        return uriEncode(encodeERC721Metadata(bp, ep));
    }

    function generateERC721Metadata(BaseERC721Properties memory bp, ExtraProperties memory ep) public pure returns (string memory) {
        return uriEncode(encodeERC721Metadata(bp, ep));
    }

    function emptyExtraProperties() internal pure returns (ExtraProperties memory) {
        ExtraProperties memory ep;
        ep.stringProperties = new StringProperty[](0);
        ep.dateProperties = new DateProperty[](0);
        ep.integerProperties = new IntegerProperty[](0);
        ep.decimalProperties = new DecimalProperty[](0);
        return ep;
    }

    function add(ExtraProperties memory ep, StringProperty memory p) internal pure returns (ExtraProperties memory) {
        StringProperty[] memory npa = new StringProperty[](ep.stringProperties.length + 1);
        for (uint256 i = 0; i < ep.stringProperties.length; i++) {
            npa[i] = ep.stringProperties[i];
        }
        npa[ep.stringProperties.length] = p;
        ep.stringProperties = npa;
        return ep;
    }

    function add(ExtraProperties memory ep, DateProperty memory p) internal pure returns (ExtraProperties memory) {
        DateProperty[] memory npa = new DateProperty[](ep.stringProperties.length + 1);
        for (uint256 i = 0; i < ep.dateProperties.length; i++) {
            npa[i] = ep.dateProperties[i];
        }
        npa[ep.dateProperties.length] = p;
        ep.dateProperties = npa;
        return ep;
    }

    function add(ExtraProperties memory ep, IntegerProperty memory p) internal pure returns (ExtraProperties memory) {
        IntegerProperty[] memory npa = new IntegerProperty[](ep.stringProperties.length + 1);
        for (uint256 i = 0; i < ep.integerProperties.length; i++) {
            npa[i] = ep.integerProperties[i];
        }
        npa[ep.integerProperties.length] = p;
        ep.integerProperties = npa;
        return ep;
    }

    function add(ExtraProperties memory ep, DecimalProperty memory p) internal pure returns (ExtraProperties memory) {
        DecimalProperty[] memory npa = new DecimalProperty[](ep.stringProperties.length + 1);
        for (uint256 i = 0; i < ep.decimalProperties.length; i++) {
            npa[i] = ep.decimalProperties[i];
        }
        npa[ep.decimalProperties.length] = p;
        ep.decimalProperties = npa;
        return ep;
    }

    function merge(ExtraProperties memory ep1, ExtraProperties memory ep2) internal pure returns (ExtraProperties memory rep) {
        uint256 offset;
        rep.stringProperties = new StringProperty[](ep1.stringProperties.length + ep2.stringProperties.length);
        for (uint256 i = 0; i < ep1.stringProperties.length; i++) {
            rep.stringProperties[i] = ep1.stringProperties[i];
        }
        offset = ep1.stringProperties.length;
        for (uint256 i = 0; i < ep2.stringProperties.length; i++) {
            rep.stringProperties[offset + i] = ep2.stringProperties[i];
        }

        rep.dateProperties = new DateProperty[](ep1.dateProperties.length + ep2.dateProperties.length);
        for (uint256 i = 0; i < ep1.dateProperties.length; i++) {
            rep.dateProperties[i] = ep1.dateProperties[i];
        }
        offset = ep1.dateProperties.length;
        for (uint256 i = 0; i < ep2.dateProperties.length; i++) {
            rep.dateProperties[offset + i] = ep2.dateProperties[i];
        }

        rep.integerProperties = new IntegerProperty[](ep1.integerProperties.length + ep2.integerProperties.length);
        for (uint256 i = 0; i < ep1.integerProperties.length; i++) {
            rep.integerProperties[i] = ep1.integerProperties[i];
        }
        offset = ep1.integerProperties.length;
        for (uint256 i = 0; i < ep2.integerProperties.length; i++) {
            rep.integerProperties[offset + i] = ep2.integerProperties[i];
        }

        rep.decimalProperties = new DecimalProperty[](ep1.decimalProperties.length + ep2.decimalProperties.length);
        for (uint256 i = 0; i < ep1.decimalProperties.length; i++) {
            rep.decimalProperties[i] = ep1.decimalProperties[i];
        }
        offset = ep1.decimalProperties.length;
        for (uint256 i = 0; i < ep2.decimalProperties.length; i++) {
            rep.decimalProperties[offset + i] = ep2.decimalProperties[i];
        }
    }

    function uriEncode(string memory metadata) private pure returns (string memory) {
        return string.concat(URI_PREFIX, Base64.encode(bytes(metadata)));
    }

    function encodeERC721Metadata(BaseERC721Properties memory bp, ExtraProperties memory ep) private pure returns (string memory) {
        string memory ap = encodeOpenSeaAttributes(ep);
        return string.concat("{", encodeBaseProperties(bp), ",", '"attributes":[', ap, "]}");
    }

    function encodeBaseProperties(BaseERC721Properties memory bp) private pure returns (string memory) {
        return string.concat('"name":"', bp.name, '",', '"description":"', bp.description, '",', '"image":"', bp.image, '"');
    }

    function encodeOpenSeaAttributes(ExtraProperties memory ep) private pure returns (string memory) {
        uint256 i;
        uint256 p = 1;
        string memory tmp = "";

        for (i = 0; i < ep.stringProperties.length; i++) {
            tmp = string.concat(tmp, toOpenSeaAttribute(ep.stringProperties[i], Strings.toString(p++)));
        }

        if (ep.dateProperties.length > 0 && bytes(tmp).length > 0) tmp = string(abi.encodePacked(tmp, ","));
        for (i = 0; i < ep.dateProperties.length; i++) {
            tmp = string.concat(tmp, toOpenSeaAttribute(ep.dateProperties[i], Strings.toString(p++)));
        }

        if (ep.integerProperties.length > 0 && bytes(tmp).length > 0) tmp = string(abi.encodePacked(tmp, ","));
        for (i = 0; i < ep.integerProperties.length; i++) {
            tmp = string.concat(tmp, toOpenSeaAttribute(ep.integerProperties[i], Strings.toString(p++)));
        }

        if (ep.decimalProperties.length > 0 && bytes(tmp).length > 0) tmp = string(abi.encodePacked(tmp, ","));
        for (i = 0; i < ep.decimalProperties.length; i++) {
            tmp = string.concat(tmp, toOpenSeaAttribute(ep.decimalProperties[i], Strings.toString(p++)));
        }

        return tmp;
    }

    function toOpenSeaAttribute(StringProperty memory v, string memory prefix) private pure returns (string memory) {
        return string.concat('{"trait_type":"', prefix, ': ', v.name, '","value":"', v.value, '"}');
    }

    function toOpenSeaAttribute(IntegerProperty memory v, string memory prefix) private pure returns (string memory) {
        return string.concat('{"trait_type":"', prefix, ': ', v.name, '","value":', StringNumberUtils.fromInt64(v.value), "}");
    }

    function toOpenSeaAttribute(DateProperty memory v, string memory prefix) private pure returns (string memory) {
        return string.concat('{"trait_type":"', prefix, ': ', v.name, '","value":', StringNumberUtils.fromInt64(v.value), ',"display_type":"date"}');
    }

    function toOpenSeaAttribute(DecimalProperty memory v, string memory prefix) private pure returns (string memory) {
        return string.concat('{"trait_type":"', prefix, ': ', v.name, '","value":', StringNumberUtils.fromInt256(v.value, v.decimals, v.precision, v.truncate), "}");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/Metadata.sol";

interface IMetadataGenerator {
    function generateMetadata(bytes32 prop, uint256 pid) external view returns (Metadata.ExtraProperties memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMetaToken.sol";
import "./IMetaTokenMetadata.sol";
import "./IMetaProperties.sol";
import "./IMetaRestrictions.sol";
import "./IMetaGlobalData.sol";

interface IMetaNFT is IMetaToken, IMetaTokenMetadata, IMetaProperties, IMetaRestrictions, IMetaGlobalData {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@nexeraprotocol/metanft/contracts/interfaces/IMetadataGenerator.sol";

interface IMetaPropertyRegistry {
    function getMetadataGenerator(bytes32 property) external view returns (IMetadataGenerator);

    function getCategoryInfoForProperty(bytes32 property) external view returns (bytes32 category, bool splitAllowed);

    function getCategoryInfo(bytes32 category) external view returns (bytes32[] memory properties, bool splitAllowed);

    function isCategoryManager(bytes32 category, address manager) external view returns (bool);

    function isPropertyManager(bytes32 property, address manager) external view returns (bool);

    function addCategoryProperty(bytes32 category, bytes32[] calldata properties) external;

    function isMinter(address manager) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev Provides functions to generate convert numbers to string
 */
library StringNumberUtils {
    function fromInt64(int64 value) internal pure returns (string memory) {
        if (value < 0) {
            uint256 positiveValue = (value == type(int64).min)?
                uint256(uint64(type(int64).max)+1): //special case for type(int64).min which can not be converted to uint64 via muliplication to -1
                uint256(uint64(-1 * value));
            return string(abi.encodePacked("-", Strings.toString(positiveValue)));
        } else {
            return Strings.toString(uint256(uint64(value)));
        }
    }

    function fromInt256(
        int256 value,
        uint8 decimals,
        uint8 precision,
        bool truncate
    ) internal pure returns (string memory) {
        if (value < 0) {
            uint256 positiveValue = (value == type(int256).min)?
                uint256(type(int256).max+1): //special case for type(int64).min which can not be converted to uint64 via muliplication to -1
                uint256(-1 * value);
            return string(abi.encodePacked("-", fromUint256(positiveValue, decimals, precision, truncate)));
        } else {
            return fromUint256(uint256(value), decimals, precision, truncate);
        }
    }

    /**
     * @param value value to convert
     * @param decimals how many decimals the number has
     * @param precision how many decimals we should show (see also truncate)
     * @param truncate if we need to remove zeroes after the last significant digit
     */
    function fromUint256(
        uint256 value,
        uint8 decimals,
        uint8 precision,
        bool truncate
    ) internal pure returns (string memory) {
        require(precision <= decimals, "StringNumberUtils: incorrect precision");
        if (value == 0) return "0";
        
        if(truncate) {
            uint8 counter;
            uint256 countDigits = value;

            while (countDigits != 0) {
                countDigits /= 10;
                counter++;
            }
            value = value/10**(counter-precision);
        }

        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        if (digits <= decimals) {
            digits = decimals + 2; //add "0."
        } else {
            digits = digits + 1; //add "."
        }
        uint256 truncateDecimals = decimals - precision;        
        uint256 bufferLen = digits - truncateDecimals;
        uint256 dotIndex = bufferLen - precision - 1;
        bytes memory buffer = new bytes(bufferLen);
        uint256 index = bufferLen;
        temp = value / 10**truncateDecimals;
        while (temp != 0) {
            index--;
            if (index == dotIndex) {
                buffer[index] = ".";
                index--;
            }
            buffer[index] = bytes1(uint8(48 + (temp % 10)));
            temp /= 10;
        }
        while (index > 0) {
            index--;
            if (index == dotIndex) {
                buffer[index] = ".";
            } else {
                buffer[index] = "0";
            }
        }
        return string(buffer);
        //TODO handle truncate
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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
pragma solidity ^0.8.0;

import "@solidstate/contracts/token/ERC721/IERC721.sol";

interface IMetaToken is IERC721 {
    function mint(address beneficiary) external returns (uint256);

    function claim(uint256 pid) external; //Tokens transfeered to a user are unavialible for getToken/getorMint/getAllTokensWithProperty untill claimed

    function getToken(address beneficiary, bytes32 property) external view returns (uint256);

    function getOrMintToken(address beneficiary, bytes32 property) external returns (uint256);

    function getAllTokensWithProperty(address beneficiary, bytes32 property) external view returns (uint256[] memory);

    /**
     * @notice Joins two NFTs of the same owner
     * @param fromPid Second NFT (properties will be removed from this one)
     * @param toPid Main NFT (properties will be added to this one)
     * @param category Category of the NFT to merge
     */
    function merge(
        uint256 fromPid,
        uint256 toPid,
        bytes32 category
    ) external;

    function merge(
        uint256 fromPid,
        uint256 toPid,
        bytes32[] calldata categories
    ) external;

    /**
     * @notice Splits a MetaNFTs into two
     * @param pid Id of the NFT to split
     * @param category Category of the NFT to split
     * @return newPid Id of the new NFT holding the detached Category
     */
    function split(uint256 pid, bytes32 category) external returns (uint256 newPid);

    function split(uint256 pid, bytes32[] calldata categories) external returns (uint256 newPid);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMetaRestrictions.sol";

interface IMetaProperties {
    function addProperty(
        uint256 pid,
        bytes32 prop,
        IMetaRestrictions.Restriction[] calldata restrictions
    ) external;

    function removeProperty(uint256 pid, bytes32 prop) external;

    function hasProperty(uint256 pid, bytes32 prop) external view returns (bool);

    function hasProperty(address beneficiary, bytes32 prop) external view returns (bool);

    function setBeforePropertyTransferHook(
        bytes32 prop,
        address target,
        bytes4 selector
    ) external;

    function setOnTransferConflictHook(
        bytes32 prop,
        address target,
        bytes4 selector
    ) external;

    function getAllProperties(uint256 pid) external view returns (bytes32[] memory);

    function getAllKeys(uint256 pid, bytes32 prop)
    external view
    returns (
        bytes32[] memory vkeys,
        bytes32[] memory bkeys,
        bytes32[] memory skeys,
        bytes32[] memory mkeys
    );

    function setDataBytes32(
        uint256 pid,
        bytes32 prop,
        bytes32 key,
        bytes32 value
    ) external;

    function getDataBytes32(
        uint256 pid,
        bytes32 prop,
        bytes32 key
    ) external view returns (bytes32);

    function setDataBytes(
        uint256 pid,
        bytes32 prop,
        bytes32 key,
        bytes calldata value
    ) external;

    function getDataBytes(
        uint256 pid,
        bytes32 prop,
        bytes32 key
    ) external view returns (bytes memory);

    function getDataSetContainsValue(
        uint256 pid,
        bytes32 prop,
        bytes32 key,
        bytes32 value
    ) external view returns (bool);

    function getDataSetLength(
        uint256 pid,
        bytes32 prop,
        bytes32 key
    ) external view returns (uint256);

    function getDataSetAllValues(
        uint256 pid,
        bytes32 prop,
        bytes32 key
    ) external view returns (bytes32[] memory);

    function setDataSetAddValue(
        uint256 pid,
        bytes32 prop,
        bytes32 key,
        bytes32 value
    ) external;

    function setDataSetRemoveValue(
        uint256 pid,
        bytes32 prop,
        bytes32 key,
        bytes32 value
    ) external;

    function getDataMapValue(
        uint256 pid,
        bytes32 prop,
        bytes32 key,
        bytes32 vKey
    ) external view returns (bytes32);

    function getDataMapLength(
        uint256 pid,
        bytes32 prop,
        bytes32 key
    ) external view returns (uint256);

    function getDataMapAllEntries(
        uint256 pid,
        bytes32 prop,
        bytes32 key
    ) external view returns (bytes32[] memory, bytes32[] memory);

    function setDataMapSetValue(
        uint256 pid,
        bytes32 prop,
        bytes32 key,
        bytes32 vKey,
        bytes32 vValue
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetaGlobalData {

    function getAllGlobalKeys(bytes32 prop) 
    external view 
    returns (
        bytes32[] memory vkeys,
        bytes32[] memory bkeys,
        bytes32[] memory skeys,
        bytes32[] memory mkeys
    );

    function setGlobalDataBytes32(
        bytes32 prop,
        bytes32 key,
        bytes32 value
    ) external;

    function getGlobalDataBytes32(bytes32 prop, bytes32 key) external view returns (bytes32);

    function setGlobalDataBytes(
        bytes32 prop,
        bytes32 key,
        bytes calldata value
    ) external;

    function getGlobalDataBytes(bytes32 prop, bytes32 key) external view returns (bytes memory);

    function getGlobalDataSetContainsValue(
        bytes32 prop,
        bytes32 key,
        bytes32 value
    ) external view returns (bool);

    function getGlobalDataSetLength(bytes32 prop, bytes32 key) external view returns (uint256);

    function getGlobalDataSetAllValues(bytes32 prop, bytes32 key) external view returns (bytes32[] memory);

    function setGlobalDataSetAddValue(
        bytes32 prop,
        bytes32 key,
        bytes32 value
    ) external;

    function setGlobalDataSetRemoveValue(
        bytes32 prop,
        bytes32 key,
        bytes32 value
    ) external;

    function getGlobalDataMapValue(
        bytes32 prop,
        bytes32 key,
        bytes32 vKey
    ) external view returns (bytes32);

    function getGlobalDataMapLength(bytes32 prop, bytes32 key) external view returns (uint256);

    function getGlobalDataMapAllEntries(bytes32 prop, bytes32 key) external view returns (bytes32[] memory, bytes32[] memory);

    function setGlobalDataMapSetValue(
        bytes32 prop,
        bytes32 key,
        bytes32 vKey,
        bytes32 vValue
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetaTokenMetadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function contractURI() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from '../../introspection/IERC165.sol';
import { IERC721Internal } from './IERC721Internal.sol';

/**
 * @notice ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal, IERC165 {
    /**
     * @notice query the balance of given address
     * @return balance quantity of tokens held
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice query the owner of given token
     * @param tokenId token to query
     * @return owner token owner
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice grant approval to given account to spend token
     * @param operator address to be approved
     * @param tokenId token to approve
     */
    function approve(address operator, uint256 tokenId) external payable;

    /**
     * @notice get approval status for given token
     * @param tokenId token to query
     * @return operator address approved to spend token
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
     * @param operator address to be approved
     * @param status approval status
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return status whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/access/AccessControl.sol
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";

library AccessControlDiamondStorage {
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

    bytes32 internal constant STORAGE_SLOT = keccak256("allianceblock.MetaNFT.utils.AccessControlDiamondStorage");

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct Layout {
        mapping(bytes32 => RoleData) roles;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function hasRole(AccessControlDiamondStorage.RoleData storage roles, address account) internal view returns (bool) {
        return roles.members[account];
    }

    function hasRole(
        Layout storage l,
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return l.roles[role].members[account];
    }

    function roleAdmin(Layout storage l, bytes32 role) internal view returns (bytes32) {
        return l.roles[role].adminRole;
    }

    function setRoleAdmin(
        Layout storage l,
        bytes32 role,
        bytes32 adminRole
    ) internal {
        AccessControlDiamondStorage.RoleData storage roles = l.roles[role];
        bytes32 previousAdminRole = roles.adminRole;
        roles.adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function grantRole(
        Layout storage l,
        bytes32 role,
        address account,
        address msgSender
    ) internal {
        AccessControlDiamondStorage.RoleData storage roles = l.roles[role];
        if (!hasRole(roles, account)) {
            roles.members[account] = true;
            emit RoleGranted(role, account, msgSender);
        }
    }

    function revokeRole(
        Layout storage l,
        bytes32 role,
        address account,
        address msgSender
    ) internal {
        AccessControlDiamondStorage.RoleData storage roles = l.roles[role];
        if (hasRole(roles, account)) {
            roles.members[account] = false;
            emit RoleRevoked(role, account, msgSender);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibOracleRoles {
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00; // Copied from AccessControlDiamond
    bytes32 internal constant ADMIN_ROLE = keccak256("nexera.metanftpm.oracle.admin");
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

pragma solidity ^0.8.0;

interface IBaseConsumer {
    enum Type {
        STRING,
        NUMBER,
        ADDRESS,
        BOOL,
        BYTES32,
        BYTES
    }

    function getType() external view returns (Type);

    function getName() external view returns (bytes32);

    function requestUpdate(bytes32 requestId) external;

    function update(bytes memory _data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Base contract for hooks
 * @dev Hooks are used to execute actions when a response is updated for a property
 */

abstract contract BaseHook is Ownable {
    address oracle;

    constructor(address oracle_) {
        oracle = oracle_;
    }

    /**
     * @notice Check if the hook is triggered, execute the hook if it is
     * @param property_ The property to check the hook for
     * @param value_ The value to check the hook for
     */
    function executeHook(
        bytes32 property_,
        uint256 mtid_,
        bytes memory value_
    ) public virtual {
        require(msg.sender == oracle, "only callable by Oracle");
    }

    /**
     * @notice Add a hook for a property
     * @param property_ The property to add the hook for
     * @param parameters_ The parameters of the hook
     * @dev The format of the parameters is specific to the hook type, and should be documented in the hook contract
     */
    function addHook(bytes32 property_, bytes calldata parameters_) public virtual onlyOwner {}
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