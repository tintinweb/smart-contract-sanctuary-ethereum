// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@solidstate/contracts/token/ERC721/IERC721.sol";
import "@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol";
import "@solidstate/contracts/introspection/ERC165.sol";
import "@solidstate/contracts/introspection/ERC165Storage.sol";
import "@nexeraprotocol/metanft/contracts/utils/Bytes32Key.sol";
import "@nexeraprotocol/metanft/contracts/utils/Metadata.sol";
import "contracts/generic-diamond/tokens/facets/ERC721Facet.sol";
import "contracts/generic-diamond/libs/LibERC721.sol";
import "contracts/allianceblock/oracle/oracle-diamond/OracleNFTFacetStorage.sol";
import "contracts/allianceblock/oracle/libs/LibRoleManager.sol";
import "contracts/allianceblock/oracle/oracle-diamond/OraclePropertyManagerFacetStorage.sol";
import "contracts/allianceblock/oracle/libs/LibOracle.sol";
import "contracts/allianceblock/oracle/consumers/IBaseConsumer.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

// Must be deployed along with MetaData Library
contract OracleNFTFacet is ERC721Facet {
    using OracleNFTFacetStorage for OracleNFTFacetStorage.Layout;
    using OraclePropertyManagerFacetStorage for OraclePropertyManagerFacetStorage.Layout;

    bytes32 constant ORACLE_KEY = 0x00;

    struct MetadataParams {
        bytes32 property;
        bytes data;
    }

    function initialize_OracleNFTFacet(IMetaNFT mnft) external {
        _initialize_ERC721Facet(mnft, "NexeraOracleTest", "TESTORCL", "");
    }


    /* ============================================================= ERC721 Multi Property ============================================================ */

    function balanceOf(address owner) public view override returns (uint256) {
        return OracleNFTFacetStorage.layout().ownerToProperties[owner].length;
    }

    //TODO 
    //function balanceOfAll(owner);
    //function balanceOfPid(pid, owner);


    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        uint248 tid = Bytes32Key.uint2562uint248(tokenId);
        address owner = OracleNFTFacetStorage.layout().tidToOwner[tid];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;        
    }

    function approve(address to, uint256 tokenId) public payable override {
        require(false, "Not implemented");
    }

        /* ============================================================= Transfers ============================================================ */

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override {
        require(msg.value == 0, "ERC721: transfer must have no value");
        uint248 tid = Bytes32Key.uint2562uint248(tokenId);
        //solhint-disable-next-line max-line-length
        require(LibERC721.isApprovedOrOwner(_msgSender(), tid), "ERC721: transfer caller is not owner nor approved");

        LibERC721.transferTo(from, to, tid);
    }

    function innerTransfer(
        uint256 fromPid,
        uint256 toPid,
        uint248 tid
    ) public override {
        require(false, "Not implemented");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override {
        require(false, "Not implemented");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable override {
        require(false, "Not implemented");
    }

    function mint(uint256 mtid, bytes32 property) public returns (uint248) {
        require(msg.sender == address(this), "only callable by OracleFacet");

        uint248 tid = _generateTokenId();

        address owner = _mnft().ownerOf(mtid);

        _setActiveProperty(property); // Needed for LibERC721 to work with the correct property

        _mintPid(tid, mtid);

        OracleNFTFacetStorage.layout().tidToProperty[tid] = property;
        OracleNFTFacetStorage.layout().tidToMtid[tid] = mtid;
        OracleNFTFacetStorage.layout().ownerToProperties[owner].push(property);
        OracleNFTFacetStorage.layout().tidToOwner[tid] = owner;
        
        _setActiveProperty(""); // Reset to default

        return tid;
    }

    /* ============================================================= Dynamic Metadata ============================================================ */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        uint248 tid = Bytes32Key.uint2562uint248(tokenId);

        uint256 mtid = OracleNFTFacetStorage.layout().tidToMtid[tid];

        bytes32 property = OracleNFTFacetStorage.layout().tidToProperty[tid];
        IBaseConsumer.Type type_ = OraclePropertyManagerFacetStorage.layout().types[property];

        require(LibERC721.exists(tid), "ERC721Metadata: URI query for nonexistent token");
        require((property != bytes32(0) && mtid != 0), "ERC721 Oracle: Token not set");

        // read value for prop
        bytes memory data = _mnft().getDataBytes(mtid, property, ORACLE_KEY);

        MetadataParams memory params = MetadataParams(property, data);
    
        // TODO : handle others types of data
        if (type_ == IBaseConsumer.Type.STRING) {
            return "";
        } else if (type_ == IBaseConsumer.Type.NUMBER) {
            return _computeUintMetadata(params);
        } else if (type_ == IBaseConsumer.Type.ADDRESS) {
            return "";
        } else if (type_ == IBaseConsumer.Type.BOOL) {
            return "";
        } else if (type_ == IBaseConsumer.Type.BYTES32) {
            return "";
        } else if (type_ == IBaseConsumer.Type.BYTES) {
            return "";
        } else {
            return "";
        }
    }


    // TODO : different name and symbol per property ?

    function _generateTokenId() internal virtual returns (uint248) {
        return ++OracleNFTFacetStorage.layout().mintCounter;
    }

    function _computeUintMetadata(MetadataParams memory m) internal view returns (string memory) {
        uint256 value = _sliceUint(m.data, 0);

        uint256 lastUpdated = OraclePropertyManagerFacetStorage.layout().propertyLastUpdate[m.property];

        string memory name = LibOracle.bytes32ToString(m.property);

        Metadata.BaseERC721Properties memory bp;
        Metadata.ExtraProperties memory ep;

        Metadata.StringProperty[] memory sps = new Metadata.StringProperty[](1);
        Metadata.DateProperty[] memory dps = new Metadata.DateProperty[](1);

        bp.name = name;
        bp.description = "This is a Diamond-Based Oracle by Nexera (sdk.nexeraprotocol.com) updating an NFT connected to Pyth price feed";
        bp.image = "https://gateway.pinata.cloud/ipfs/QmVxnPLA2bQzE6PtRfaMg5Uc2LYJuKUYEFgVNVF4AzsXMD";

        sps[0] = Metadata.StringProperty("Price", Strings.toString(value));

        dps[0] = Metadata.DateProperty("Last Updated", int64(uint64(lastUpdated))); // TODO : check the cast

        ep.stringProperties = sps;
        ep.dateProperties = dps;
        ep.integerProperties = new Metadata.IntegerProperty[](0);
        ep.decimalProperties = new Metadata.DecimalProperty[](0);

    
        string memory uri =_generateERC721Metadata(bp, ep);

        /*

        string memory uri = string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Pyth Price Feed", "description":"This is a Diamond-Based Oracle by Nexera (sdk.nexeraprotocol.com) updating an NFT connected to Pyth price feed","image": "https://gateway.pinata.cloud/ipfs/QmVxnPLA2bQzE6PtRfaMg5Uc2LYJuKUYEFgVNVF4AzsXMD", "attributes": ',
                                "[",
                                '{"trait_type":"',
                                name,
                                '",',
                                '"value":"',
                                Strings.toString(value),
                                '"},',
                                '{"display_type":"date",',
                                '"trait_type":"Last Updated",',
                                '"value":',
                                Strings.toString(block.timestamp),
                                '}',
                                "]",
                                "}"
                            )
                        )
                    )
                )
            );
            */
        return uri;
    }

    function _generateERC721Metadata(Metadata.BaseERC721Properties memory bp, Metadata.StringProperty[] memory sps) internal pure returns (string memory) {
        return Metadata.generateERC721Metadata(bp, sps);
    }

    function _generateERC721Metadata(Metadata.BaseERC721Properties memory bp, Metadata.ExtraProperties memory ep) internal pure returns (string memory) {
        return Metadata.generateERC721Metadata(bp, ep);
    }

    // TODO : change
    function _sliceUint(bytes memory bs, uint256 start) internal view returns (uint256) {
        require(bs.length >= start + 32, "slicing out of range");
        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }
        return x;
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

import "@nexeraprotocol/metanft/contracts/interfaces/IMetaNFT.sol";
import "@nexeraprotocol/metanft/contracts/utils/Bytes32Key.sol";
import "./LibERC721Storage.sol";

/// @title Set of functions to use as an ERC721 Property Manager (Property must be set in the Storage)
/// @author AllianceBlock
library LibERC721 {
    using LibERC721Storage for LibERC721Storage.Layout;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed operator, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * A key in Property's Set storage, to store token ids owned by this MetaNFT token
     * Uses a default partition 0x00
     */
    bytes32 internal constant OWNED_TOKENS_PROPERTY_SET_KEY = 0x0000000000000000000000000000000000000000000000000000000000000001;

    /**
     * Used to partition a key space of the global bytes32 storage
     * Under this flag we store the mapping of erc721 token id "owned" by a specific MetaNFT
     * to that MetaNFT id
     */
    uint8 internal constant TOKEN_ID_MAP_GLOBAL_BYTES32_KEY_PARTITION = 0x01;

    /**
     * Used to partition a key space of the propertie global Set storage
     * Under this flag we store the mapping of token owner to a set of approved operators
     */
    uint8 internal constant OPERATOR_GLOBAL_SET_KEY_PARTITION = 0x02;

    /**
     * Used to partition a key space of the propertie's bytes32 storage
     * Under this flag we store the mapping of erc721 token id "owned" by a specific MetaNFT
     * to an approved spender
     */
    uint8 internal constant APPROVED_PROPERTY_BYTES32_KEY_PARTITION = 0x01;

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function exists(uint248 tokenId) internal view returns (bool) {
        return (LibERC721Storage.layout().storedOwners[tokenId] != address(0));
    }

    /* ============================================================= Transfers ============================================================ */

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function mint(address to, uint248 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!exists(tokenId), "ERC721: token already minted");

        setOwner(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     * @dev MetaNFT token id is passed in as a parameter
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     * - `metaNFTId` must be a valid MetaNFT token id
     * Emits a {Transfer} event.
     */
    function mintPid(uint248 tid, uint256 mtid) internal {
        require(!exists(tid), "ERC721: token already minted");
        require(mtid != 0, "ERC721: invalid MetaNFT token id");

        address owner = mnft().ownerOf(mtid);

        setOwnerPid(tid, mtid);
        LibERC721Storage.layout().storedOwners[tid] = owner;

        emit Transfer(address(0), owner, tid);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function burn(uint248 tokenId) internal {
        address owner = getOwnerOrRevert(tokenId);

        // Clear approvals
        approve(address(0), tokenId);

        removeOwner(tokenId, owner);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function transferTo(
        address from,
        address to,
        uint248 tokenId
    ) internal {
        require(getOwnerOrRevert(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        approve(address(0), tokenId);

        transferOwner(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /* ============================================================= NFT Ownership ============================================================ */

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function isApprovedOrOwner(address spender, uint248 tokenId) internal view returns (bool) {
        //require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = getOwnerOrRevert(tokenId);
        return (spender == owner || isOperator(owner, spender) || getApproved(tokenId) == spender);
    }

    function getOwnerOrRevert(uint248 tid) internal view returns (address) {
        return mnft().ownerOf(getOwnerPidOrRevert(tid));
    }

    function setOwner(uint248 tid, address owner) internal {
        uint256 pid = mnft().getOrMintToken(owner, prop());
        setOwnerPid(tid, pid);
        LibERC721Storage.layout().storedOwners[tid] = owner;
    }

    function removeOwner(
        uint248 tid,
        address /*owner*/
    ) internal {
        uint256 pid = getOwnerPidOrRevert(tid);
        removeOwnerPid(tid, pid);
        LibERC721Storage.layout().storedOwners[tid] = address(0);
    }

    function transferOwner(uint248 tid, address to) internal {
        uint256 fromPid = getOwnerPidOrRevert(tid); // It is verified in _transfer() that tid is owned by from
        uint256 toPid = mnft().getOrMintToken(to, prop());
        transferOwnerPid(tid, fromPid, toPid);
        LibERC721Storage.layout().storedOwners[tid] = to;
    }

    /**
     * @dev This function does not care about ERC721PropertyManagerStorage.layout().storedOwners
     */
    function setOwnerPid(uint248 tid, uint256 pid) internal {
        bytes32 tidKey = Bytes32Key.partitionedKeyForUint248(TOKEN_ID_MAP_GLOBAL_BYTES32_KEY_PARTITION, tid);
        mnft().setGlobalDataBytes32(prop(), tidKey, bytes32(pid));
        mnft().setDataSetAddValue(pid, prop(), OWNED_TOKENS_PROPERTY_SET_KEY, Bytes32Key.uint2482bytes32(tid));
    }

    /**
     * @dev This function does not care about ERC721PropertyManagerStorage.layout().storedOwners
     */
    function removeOwnerPid(uint248 tid, uint256 pid) internal {
        bytes32 tidKey = Bytes32Key.partitionedKeyForUint248(TOKEN_ID_MAP_GLOBAL_BYTES32_KEY_PARTITION, tid);
        mnft().setGlobalDataBytes32(prop(), tidKey, bytes32(0));
        mnft().setDataSetRemoveValue(pid, prop(), OWNED_TOKENS_PROPERTY_SET_KEY, Bytes32Key.uint2482bytes32(tid));
    }

    function getOwnerPid(uint248 tid) internal view returns (uint256) {
        bytes32 tidKey = Bytes32Key.partitionedKeyForUint248(TOKEN_ID_MAP_GLOBAL_BYTES32_KEY_PARTITION, tid);
        return uint256(mnft().getGlobalDataBytes32(prop(), tidKey));
    }

    function getOwnerPidOrRevert(uint248 tid) internal view returns (uint256) {
        uint256 pid = getOwnerPid(tid);
        require(pid != 0, "owner query for nonexistent token");
        return pid;
    }

    /**
     * @dev This function does not care about ERC721PropertyManagerStorage.layout().storedOwners
     */
    function transferOwnerPid(
        uint248 tid,
        uint256 from,
        uint256 to
    ) internal {
        bytes32 tidKey = Bytes32Key.partitionedKeyForUint248(TOKEN_ID_MAP_GLOBAL_BYTES32_KEY_PARTITION, tid);
        mnft().setGlobalDataBytes32(prop(), tidKey, bytes32(to));
        mnft().setDataSetRemoveValue(from, prop(), OWNED_TOKENS_PROPERTY_SET_KEY, Bytes32Key.uint2482bytes32(tid));
        mnft().setDataSetAddValue(to, prop(), OWNED_TOKENS_PROPERTY_SET_KEY, Bytes32Key.uint2482bytes32(tid));
    }

    /* ============================================================= Balances ============================================================ */
    function balanceOf(address owner) internal view returns (uint256) {
        require(owner != address(0), "LibERC721: balance query for the zero address");
        uint256 pid = mnft().getToken(owner, prop());
        if (pid == 0) return 0;
        return mnft().getDataSetLength(pid, prop(), OWNED_TOKENS_PROPERTY_SET_KEY);
    }

    function balanceOfPid(uint256 pid) internal view returns (uint256) {
        if (pid == 0) return 0;
        return mnft().getDataSetLength(pid, prop(), OWNED_TOKENS_PROPERTY_SET_KEY);
    }

    function balanceOfAll(address owner) internal view returns (uint256) {
        uint256[] memory pids = mnft().getAllTokensWithProperty(owner, prop());
        if (pids.length == 0) return 0;
        uint256 totalCount;
        for (uint256 i = 0; i < pids.length; i++) {
            totalCount += mnft().getDataSetLength(pids[i], prop(), OWNED_TOKENS_PROPERTY_SET_KEY);
        }
        return totalCount;
    }

    /* ============================================================= Approvals ============================================================ */
    function getApproved(uint248 tid) internal view returns (address) {
        uint256 pid = getOwnerPidOrRevert(tid);

        address pidOwner = mnft().ownerOf(pid);
        if (LibERC721Storage.layout().storedOwners[tid] != pidOwner) return address(0); //This can happen if MetaNFT token was transferred

        bytes32 tidKey = Bytes32Key.partitionedKeyForUint248(APPROVED_PROPERTY_BYTES32_KEY_PARTITION, tid);
        return Bytes32Key.bytes322address(mnft().getDataBytes32(pid, prop(), tidKey));
    }

    function setApproved(uint248 tid, address spender) internal returns (address) {
        uint256 pid = getOwnerPidOrRevert(tid);
        bytes32 tidKey = Bytes32Key.partitionedKeyForUint248(APPROVED_PROPERTY_BYTES32_KEY_PARTITION, tid);

        address pidOwner = mnft().ownerOf(pid);
        LibERC721Storage.layout().storedOwners[tid] = pidOwner;

        mnft().setDataBytes32(pid, prop(), tidKey, Bytes32Key.address2bytes32(spender));
        return pidOwner;
    }

    function isOperator(address owner, address operator) internal view returns (bool) {
        bytes32 ownerKey = Bytes32Key.partitionedKeyForAddress(OPERATOR_GLOBAL_SET_KEY_PARTITION, owner);
        return mnft().getGlobalDataSetContainsValue(prop(), ownerKey, Bytes32Key.address2bytes32(operator));
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function approve(address to, uint248 tokenId) internal {
        emit Approval(setApproved(tokenId, to), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "ERC721: approve to caller");
        setOperator(owner, operator, approved);
        emit ApprovalForAll(owner, operator, approved);
    }

    function setOperator(
        address owner,
        address operator,
        bool isOperator_
    ) internal {
        bytes32 ownerKey = Bytes32Key.partitionedKeyForAddress(OPERATOR_GLOBAL_SET_KEY_PARTITION, owner);
        if (isOperator_) {
            mnft().setGlobalDataSetAddValue(prop(), ownerKey, Bytes32Key.address2bytes32(operator));
        } else {
            mnft().setGlobalDataSetRemoveValue(prop(), ownerKey, Bytes32Key.address2bytes32(operator));
        }
    }

    /* ============================================================= Property Manager ============================================================ */

    function mnft() internal view returns (IMetaNFT) {
        return LibERC721Storage.layout().mnft;
    }

    function prop() internal view returns (bytes32) {
        require(LibERC721Storage.layout().activeProperty != "", "ERC721: property is not active");
        return LibERC721Storage.layout().activeProperty;
    }

    function resolvePropertyTransferConflict(
        bytes32 prop_,
        uint256 fromPid,
        uint256 toPid
    ) internal {
        bytes32[] memory ownedTids = mnft().getDataSetAllValues(fromPid, prop_, OWNED_TOKENS_PROPERTY_SET_KEY);
        for (uint256 i = 0; i < ownedTids.length; i++) {
            uint248 tid = Bytes32Key.bytes322uint248(ownedTids[i]);
            address spender = getApproved(tid); // This will return address(0) if the token was transferred and new owner isn't stored in ERC721PropertyManagerStorage.layout().storedOwners yet
            setOwnerPid(tid, toPid);
            //We don't change ERC721PropertyManagerStorage.layout().storedOwners[tid] here because owner stays the same
            bytes32 tidKey = Bytes32Key.partitionedKeyForUint248(APPROVED_PROPERTY_BYTES32_KEY_PARTITION, tid);
            mnft().setDataBytes32(toPid, prop_, tidKey, Bytes32Key.address2bytes32(spender)); // Copy the approval unless token was previously transferred, in which case we store 0
        }
    }

    /* ============================================================= . ============================================================ */
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

// Here put base functions for backstop hooks
// using bytes => To uint :
//  if above / under / equal to a certain value
// string equals to a certain value ...
import "@nexeraprotocol/metanft/contracts/interfaces/IMetaRestrictions.sol";

library LibOracle {
    struct HookUint {
        UintOperators operator;
        uint256 treshold;
    }

    /**
     * @notice The operators to use for the backstop hooks
     * @param None : 0 // Used to check if a hook is set
     * @param Equal : 1
     * @param NotEqual : 2
     * @param Above : 3
     * @param AboveOrEqual : 4
     * @param Under : 5
     * @param UnderOrEqual : 6
     */
    enum UintOperators {
        None,
        Equal,
        NotEqual,
        Above,
        AboveOrEqual,
        Under,
        UnderOrEqual
    }

    /**
     * @notice Return true if the condition is met
     */
    function conditionReached(HookUint memory hook, bytes memory data_) internal returns (bool) {
        require(data_.length < 32, "invalid data length");

        bytes8 value = convertBytesToBytes8(data_);
        uint256 a = uint256(uint64(value));

        if (hook.operator == UintOperators.Equal) {
            return isEqual(a, hook.treshold);
        } else if (hook.operator == UintOperators.NotEqual) {
            return isNotEqual(a, hook.treshold);
        } else if (hook.operator == UintOperators.Above) {
            return isAbove(a, hook.treshold);
        } else if (hook.operator == UintOperators.AboveOrEqual) {
            return isAboveOrEqual(a, hook.treshold);
        } else if (hook.operator == UintOperators.Under) {
            return isUnder(a, hook.treshold);
        } else if (hook.operator == UintOperators.UnderOrEqual) {
            return isUnderOrEqual(a, hook.treshold);
        } else {
            return false;
        }
    }

    function isEqual(uint256 a, uint256 b) internal pure returns (bool) {
        return a == b;
    }

    function isNotEqual(uint256 a, uint256 b) internal pure returns (bool) {
        return a != b;
    }

    function isAbove(uint256 a, uint256 b) internal pure returns (bool) {
        return a > b;
    }

    function isAboveOrEqual(uint256 a, uint256 b) internal pure returns (bool) {
        return a >= b;
    }

    function isUnder(uint256 a, uint256 b) internal pure returns (bool) {
        return a < b;
    }

    function isUnderOrEqual(uint256 a, uint256 b) internal pure returns (bool) {
        return a <= b;
    }

    function convertBytesToBytes8(bytes memory inBytes) internal returns (bytes8 outBytes8) {
        if (inBytes.length == 0) {
            return 0x0;
        }

        assembly {
            outBytes8 := mload(add(inBytes, 32))
        }
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@nexeraprotocol/metanft/contracts/interfaces/IMetaNFT.sol";
import "@solidstate/contracts/token/ERC721/IERC721.sol";
import "@solidstate/contracts/token/ERC721/IERC721Receiver.sol";
import "@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol";
import "@solidstate/contracts/introspection/ERC165.sol";
import "@solidstate/contracts/introspection/ERC165Storage.sol";
import "../../../utils/AccessControlDiamond.sol";
import "../../libs/LibERC721.sol";
import "./ERC721FacetStorage.sol";

/**
 * @title AllianceBlock Base ERC721 Facet
 * @dev This contract can be used as a Facet for other tokens implementations that needed it
 * @dev Ownership set to Deployer by default using AccessControlDiamond
 * @dev Using LibERC721
 * @dev Extends AccessControlDiamond, IERC721, IERC721Metadata, ERC165
 */
abstract contract ERC721Facet is Context, IERC721, IERC721Metadata, ERC165 {
    using Strings for uint256;
    using Address for address;
    using ERC165Storage for ERC165Storage.Layout;
    using ERC721FacetStorage for ERC721FacetStorage.Layout;
    using LibERC721Storage for LibERC721Storage.Layout;

    function _initialize_ERC721Facet(
        IMetaNFT mnft,
        bytes32 property,
        string memory name_,
        string memory symbol_
    ) internal {
        require(!ERC721FacetStorage.layout().initialized, "already initialized");
        ERC721FacetStorage.layout().initialized = true;
        __ERC721PropertyManager_init(mnft, property, name_, symbol_);
    }

    function __ERC721PropertyManager_init(
        IMetaNFT mnft,
        bytes32 property,
        string memory name_,
        string memory symbol_
    ) internal {
        __ERC721PropertyManager_init_unchained(mnft, property, name_, symbol_);
    }

    function __ERC721PropertyManager_init_unchained(
        IMetaNFT mnft,
        bytes32 property,
        string memory name_,
        string memory symbol_
    ) internal {
        LibERC721Storage.layout().name = name_;
        LibERC721Storage.layout().symbol = symbol_;
        LibERC721Storage.layout().mnft = mnft;
        LibERC721Storage.layout().activeProperty = property;
        ERC165Storage.layout().setSupportedInterface(type(IERC721).interfaceId, true);
    }

    function _mint(address to, uint248 tid) internal {
        LibERC721.mint(to, tid);
    }

    function _mintPid(uint248 tid, uint256 pid) internal {
        LibERC721.mintPid(tid, pid);
    }

    function _burn(uint248 tid) internal {
        LibERC721.burn(tid);
    }

    function _setBaseURI(string calldata uri) internal {
        LibERC721Storage.layout().baseURI = uri;
    }

    function _setActiveProperty(bytes32 property) internal {
        LibERC721Storage.layout().activeProperty = property;
    }

    /* ============================================================= Getter functions ============================================================ */

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        return LibERC721.balanceOf(owner);
    }

    /**
     * @notice Returns the balance for a specific MetaNFT pid
     */
    function balanceOfPid(uint256 pid) public view virtual returns (uint256) {
        return LibERC721.balanceOfPid(pid);
    }

    /**
     * @notice Returns the balance for all MetaNFTs of the owner
     */
    function balanceOfAll(address owner) public view virtual returns (uint256) {
        return LibERC721.balanceOfAll(owner);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        uint248 tid = Bytes32Key.uint2562uint248(tokenId);
        return LibERC721.getOwnerOrRevert(tid);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return LibERC721Storage.layout().name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return LibERC721Storage.layout().symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        uint248 tid = Bytes32Key.uint2562uint248(tokenId);
        require(LibERC721.exists(tid), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view returns (string memory) {
        return LibERC721Storage.layout().baseURI;
    }

    /* ============================================================= Approvals ============================================================ */

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual payable override {
        require(msg.value == 0, "ERC721: approval must have no value");
        uint248 tid = Bytes32Key.uint2562uint248(tokenId);
        address owner = LibERC721.getOwnerOrRevert(tid);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");

        LibERC721.approve(to, tid);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        uint248 tid = Bytes32Key.uint2562uint248(tokenId);
        require(LibERC721.exists(tid), "ERC721: approved query for nonexistent token");

        return LibERC721.getApproved(tid);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        LibERC721.setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return LibERC721.isOperator(owner, operator);
    }

    /* ============================================================= Transfers ============================================================ */

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        require(msg.value == 0, "ERC721: transfer must have no value");
        uint248 tid = Bytes32Key.uint2562uint248(tokenId);
        //solhint-disable-next-line max-line-length
        require(LibERC721.isApprovedOrOwner(_msgSender(), tid), "ERC721: transfer caller is not owner nor approved");

        LibERC721.transferTo(from, to, tid);
    }

    /**
     * @notice Performs a transfer between two MetaNFT of the same owner
     * @param fromPid MetaNFT id where the token is from
     * @param toPid MetaNFT id to send the token
     * @param tid ERC721 Token Id to take
     */
    function innerTransfer(
        uint256 fromPid,
        uint256 toPid,
        uint248 tid
    ) public virtual {
        _innerTransfer(fromPid, toPid, tid);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override {
        require(msg.value == 0, "ERC721: transfer must have no value");
        uint248 tid = Bytes32Key.uint2562uint248(tokenId);
        require(LibERC721.isApprovedOrOwner(_msgSender(), tid), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tid, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint248 tokenId,
        bytes memory _data
    ) internal {
        LibERC721.transferTo(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint248 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint248 tokenId,
        bytes memory _data
    ) internal {
        LibERC721.mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Transfer token between two MetaNFTs of the same owner
     */
    function _innerTransfer(
        uint256 fromPid,
        uint256 toPid,
        uint248 tokenId
    ) internal {
        require(
            (LibERC721.getOwnerOrRevert(tokenId) == _mnft().ownerOf(fromPid) && LibERC721.getOwnerOrRevert(tokenId) == _mnft().ownerOf(toPid)),
            "Account must own the two Mnfts"
        );

        LibERC721.transferOwnerPid(tokenId, fromPid, toPid);
    }

    /* ============================================================= Hooks ============================================================ */

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function beforeTokenTransfer(
        address from,
        address to,
        uint248 tokenId
    ) internal {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function afterTokenTransfer(
        address from,
        address to,
        uint248 tokenId
    ) internal {}

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint248 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /* ============================================================= Property Manager ============================================================ */

    function _mnft() internal view returns (IMetaNFT) {
        return LibERC721.mnft();
    }

    function _prop() internal view returns (bytes32) {
        return LibERC721.prop();
    }

    uint256[50] private __gap;
}

/* ============================================================= . ============================================================ */

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
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
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

library ERC165Storage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC165');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function isSupportedInterface(Layout storage l, bytes4 interfaceId)
        internal
        view
        returns (bool)
    {
        return l.supportedInterfaces[interfaceId];
    }

    function setSupportedInterface(
        Layout storage l,
        bytes4 interfaceId,
        bool status
    ) internal {
        require(interfaceId != 0xffffffff, 'ERC165: invalid interface id');
        l.supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from './IERC165.sol';
import { ERC165Storage } from './ERC165Storage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165 is IERC165 {
    using ERC165Storage for ERC165Storage.Layout;

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return ERC165Storage.layout().isSupportedInterface(interfaceId);
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

library Bytes32Key {
    bytes32 private constant MAX_BYTES32_ADDRESS = bytes32(uint256(type(uint160).max)); // 0x000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    bytes32 private constant MAX_BYTES32_UINT248 = bytes32(uint256(type(uint248).max)); // 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

    // ==== Conversions between common key types ====
    function address2bytes32(address a) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(a)));
    }

    function bytes322address(bytes32 b) internal pure returns (address) {
        require(b & MAX_BYTES32_ADDRESS == b, "bytes32 to address conversion fail");
        return address(uint160(uint256(b)));
    }

    function uint2482bytes32(uint248 v) internal pure returns (bytes32) {
        return bytes32(uint256(v));
    }

    function bytes322uint248(bytes32 v) internal pure returns (uint248) {
        require(v & MAX_BYTES32_UINT248 == v, "bytes32 to uint248 conversion fail");
        return uint248(uint256(v));
    }

    function uint2562uint248(uint256 v) internal pure returns (uint248) {
        require(v <= type(uint248).max, "uint248 conversion fail");
        return uint248(v);
    }

    // ==== Partitioning tools ====

    /**
     * @notice Internal convert address to a partitioned key
     * @param partition Partition
     * @param account Address to convert
     * @return byte32 key
     */
    function partitionedKeyForAddress(uint8 partition, address account) internal pure returns (bytes32) {
        bytes32 p = bytes32(bytes1(partition));
        bytes32 v = bytes32(uint256(uint160(account)));
        return p | v;
    }

    /**
     * @notice Internal convert address to a partitioned key
     * @param partition Partition
     * @param value Value to convert
     * @return byte32 key
     */
    function partitionedKeyForUint248(uint8 partition, uint248 value) internal pure returns (bytes32) {
        bytes32 p = bytes32(bytes1(partition));
        bytes32 v = bytes32(uint256(value));
        return p | v;
    }
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

/**
 * @title ERC721Metadata interface
 */
interface IERC721Metadata {
    /**
     * @notice get token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice get token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@nexeraprotocol/metanft/contracts/interfaces/IMetaNFT.sol";

library LibERC721Storage {
    bytes32 internal constant STORAGE_SLOT = keccak256("allianceblock.MetaNFT.managers.generic-diamond.tokens.LibERC721Storage");

    struct Layout {
        IMetaNFT mnft;
        bytes32 activeProperty;
        string name;
        string symbol;
        string baseURI;
        // Storing this localy to decrease gas usage
        mapping(uint248 => address) storedOwners;
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

import "./IMetaToken.sol";
import "./IMetaTokenMetadata.sol";
import "./IMetaProperties.sol";
import "./IMetaRestrictions.sol";
import "./IMetaGlobalData.sol";

interface IMetaNFT is IMetaToken, IMetaTokenMetadata, IMetaProperties, IMetaRestrictions, IMetaGlobalData {}

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

interface IMetaTokenMetadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function contractURI() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/access/AccessControl.sol

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@solidstate/contracts/introspection/ERC165Storage.sol";
import "./AccessControlDiamondStorage.sol";

abstract contract AccessControlDiamond is Context, IAccessControl {
    using ERC165Storage for ERC165Storage.Layout;
    using AccessControlDiamondStorage for AccessControlDiamondStorage.Layout;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bool public isInit = false;
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    function __AccessControlDiamond_init_unchained() internal {
        require(!isInit, "Already initialize");
        isInit = true;
        ERC165Storage.layout().setSupportedInterface(type(IAccessControl).interfaceId, true);
    }

    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return AccessControlDiamondStorage.layout().hasRole(role, account);
    }

    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return AccessControlDiamondStorage.layout().roleAdmin(role);
    }

    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        AccessControlDiamondStorage.layout().revokeRole(role, account, _msgSender());
    }

    function _grantRole(bytes32 role, address account) internal virtual {
        AccessControlDiamondStorage.layout().grantRole(role, account, _msgSender());
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        AccessControlDiamondStorage.layout().revokeRole(role, account, _msgSender());
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        AccessControlDiamondStorage.layout().setRoleAdmin(role, adminRole);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ERC721FacetStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("allianceblock.MetaNFT.managers.generic-diamond.tokens.ERC721FacetStorage");

    struct Layout {
        bool initialized;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
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

pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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