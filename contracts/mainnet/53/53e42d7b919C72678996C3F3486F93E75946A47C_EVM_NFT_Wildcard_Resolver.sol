/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

//SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns(bool);
}


abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns(uint256 balance);

    function ownerOf(uint256 tokenId) external view returns(address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns(address operator);

    function isApprovedForAll(address owner, address operator) external view returns(bool);
}

interface IERC1155 is IERC165 {

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] values
);

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns(uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
    external
    view
    returns(uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns(bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface IBaseRegistrar is IERC721 {
    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event NameMigrated(
    uint256 indexed id,
    address indexed owner,
    uint256 expires
);
    event NameRegistered(
    uint256 indexed id,
    address indexed owner,
    uint256 expires
);
    event NameRenewed(uint256 indexed id, uint256 expires);

    function addController(address controller) external;

    function removeController(address controller) external;

    function setResolver(address resolver) external;

    function nameExpires(uint256 id) external view returns(uint256);

    function available(uint256 id) external view returns(bool);

    function register(
        uint256 id,
        address owner,
        uint256 duration
    ) external returns(uint256);

    function renew(uint256 id, uint256 duration) external returns(uint256);

    function reclaim(uint256 id, address owner) external;
}

interface ENS {

    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    event Transfer(bytes32 indexed node, address owner);

    event NewResolver(bytes32 indexed node, address resolver);

    event NewTTL(bytes32 indexed node, uint64 ttl);

    event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
);

function setRecord(
    bytes32 node,
    address owner,
    address resolver,
    uint64 ttl
) external;

function setSubnodeRecord(
    bytes32 node,
    bytes32 label,
    address owner,
    address resolver,
    uint64 ttl
) external;

function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
) external returns(bytes32);

function setResolver(bytes32 node, address resolver) external;

function setOwner(bytes32 node, address owner) external;

function setTTL(bytes32 node, uint64 ttl) external;

function setApprovalForAll(address operator, bool approved) external;

function owner(bytes32 node) external view returns(address);

function resolver(bytes32 node) external view returns(address);

function ttl(bytes32 node) external view returns(uint64);

function recordExists(bytes32 node) external view returns(bool);

function isApprovedForAll(
    address owner,
    address operator
) external view returns(bool);
}

interface IMulticallable {
    function multicall(
    bytes[] calldata data
) external returns(bytes[] memory results);

function multicallWithNodeCheck(
    bytes32,
    bytes[] calldata data
) external returns(bytes[] memory results);
}

abstract contract Multicallable is IMulticallable, ERC165 {
    function _multicall(
        bytes32 nodehash,
        bytes[] calldata data
    ) internal returns(bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            if (nodehash != bytes32(0)) {
                bytes32 txNamehash = bytes32(data[i][4: 36]);
                require(
                    txNamehash == nodehash,
                    "multicall: All records must have a matching namehash"
                );
            }
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );
            require(success);
            results[i] = result;
        }
        return results;
    }

    function multicallWithNodeCheck(
        bytes32 nodehash,
        bytes[] calldata data
    ) external returns(bytes[] memory results) {
        return _multicall(nodehash, data);
    }

    function multicall(
        bytes[] calldata data
    ) public override returns(bytes[] memory results) {
        return _multicall(bytes32(0), data);
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual override returns(bool) {
        return
        interfaceID == type(IMulticallable).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}



interface IInterfaceResolver {
    event InterfaceChanged(
    bytes32 indexed node,
    bytes4 indexed interfaceID,
    address implementer
);

function interfaceImplementer(
    bytes32 node,
    bytes4 interfaceID
) external view returns(address);
}

interface INameResolver {
    event NameChanged(bytes32 indexed node, string name);

function name(bytes32 node) external view returns(string memory);
}

interface IPubkeyResolver {
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

function pubkey(bytes32 node) external view returns(bytes32 x, bytes32 y);
}

interface IVersionableResolver {
    event VersionChanged(bytes32 indexed node, uint64 newVersion);

function recordVersions(bytes32 node) external view returns(uint64);
}

abstract contract ResolverBase is ERC165, IVersionableResolver {
    mapping(bytes32 => uint64) public recordVersions;

    function isAuthorised(bytes32 node) internal view virtual returns(bool);

    modifier authorised(bytes32 node) {
        require(isAuthorised(node));
        _;
    }

    function clearRecords(bytes32 node) public virtual authorised(node) {
        recordVersions[node]++;
        emit VersionChanged(node, recordVersions[node]);
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual override returns(bool) {
        return
        interfaceID == type(IVersionableResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}

interface IABIResolver {
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);

function ABI(
    bytes32 node,
    uint256 contentTypes
) external view returns(uint256, bytes memory);
}

abstract contract ABIResolver is IABIResolver, ResolverBase {
    mapping(uint64 => mapping(bytes32 => mapping(uint256 => bytes))) versionable_abis;

    function setABI(
        bytes32 node,
        uint256 contentType,
        bytes calldata data
    ) external virtual authorised(node) {

        require(((contentType - 1) & contentType) == 0);

        versionable_abis[recordVersions[node]][node][contentType] = data;
        emit ABIChanged(node, contentType);
    }

    function ABI(
        bytes32 node,
        uint256 contentTypes
    ) external view virtual override returns(uint256, bytes memory) {
        mapping(uint256 => bytes) storage abiset = versionable_abis[
            recordVersions[node]
        ][node];

        for (
            uint256 contentType = 1;
            contentType <= contentTypes;
        contentType <<= 1
        ) {
            if (
                (contentType & contentTypes) != 0 &&
                abiset[contentType].length > 0
            ) {
                return (contentType, abiset[contentType]);
            }
        }

        return (0, bytes(""));
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual override returns(bool) {
        return
        interfaceID == type(IABIResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}

interface IAddrResolver {
    event AddrChanged(bytes32 indexed node, address a);

function addr(bytes32 node) external view returns(address payable);
}

interface IAddressResolver {
    event AddressChanged(
    bytes32 indexed node,
    uint256 coinType,
    bytes newAddress
);

function addr(
    bytes32 node,
    uint256 coinType
) external view returns(bytes memory);
}

abstract contract AddrResolver is
IAddrResolver,
    IAddressResolver,
    ResolverBase
{
    uint256 private constant COIN_TYPE_ETH = 60;

    mapping(uint64 => mapping(bytes32 => mapping(uint256 => bytes))) versionable_addresses;

    function setAddr(
        bytes32 node,
        address a
    ) external virtual authorised(node) {
        setAddr(node, COIN_TYPE_ETH, addressToBytes(a));
    }

    function addr(
        bytes32 node
    ) public view virtual override returns(address payable) {
        bytes memory a = addr(node, COIN_TYPE_ETH);
        if (a.length == 0) {
            return payable(0);
        }
        return bytesToAddress(a);
    }

    function setAddr(
        bytes32 node,
        uint256 coinType,
        bytes memory a
    ) public virtual authorised(node) {
        emit AddressChanged(node, coinType, a);
        if (coinType == COIN_TYPE_ETH) {
            emit AddrChanged(node, bytesToAddress(a));
        }
        versionable_addresses[recordVersions[node]][node][coinType] = a;
    }

    function addr(
        bytes32 node,
        uint256 coinType
    ) public view virtual override returns(bytes memory) {
        return versionable_addresses[recordVersions[node]][node][coinType];
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual override returns(bool) {
        return
        interfaceID == type(IAddrResolver).interfaceId ||
            interfaceID == type(IAddressResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }

    function bytesToAddress(
        bytes memory b
    ) internal pure returns(address payable a) {
        require(b.length == 20);
        assembly {
            a:= div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) internal pure virtual returns(bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }
}

interface IContentHashResolver {
    event ContenthashChanged(bytes32 indexed node, bytes hash);

function contenthash(bytes32 node) external view returns(bytes memory);
}

abstract contract ContentHashResolver is IContentHashResolver, ResolverBase {
    mapping(uint64 => mapping(bytes32 => bytes)) versionable_hashes;

    function setContenthash(
        bytes32 node,
        bytes calldata hash
    ) external virtual authorised(node) {
        versionable_hashes[recordVersions[node]][node] = hash;
        emit ContenthashChanged(node, hash);
    }

    function contenthash(
        bytes32 node
    ) public view virtual override returns(bytes memory) {
        return versionable_hashes[recordVersions[node]][node];
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual override returns(bool) {
        return
        interfaceID == type(IContentHashResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}

abstract contract InterfaceResolver is IInterfaceResolver, AddrResolver {
    mapping(uint64 => mapping(bytes32 => mapping(bytes4 => address))) versionable_interfaces;

    function setInterface(
        bytes32 node,
        bytes4 interfaceID,
        address implementer
    ) external virtual authorised(node) {
        versionable_interfaces[recordVersions[node]][node][
            interfaceID
        ] = implementer;
        emit InterfaceChanged(node, interfaceID, implementer);
    }

    function interfaceImplementer(
        bytes32 node,
        bytes4 interfaceID
    ) external view virtual override returns(address) {
        address implementer = versionable_interfaces[recordVersions[node]][
            node
        ][interfaceID];
        if (implementer != address(0)) {
            return implementer;
        }

        address a = addr(node);
        if (a == address(0)) {
            return address(0);
        }

        (bool success, bytes memory returnData) = a.staticcall(
            abi.encodeWithSignature(
                "supportsInterface(bytes4)",
                type(IERC165).interfaceId
            )
        );
        if (!success || returnData.length < 32 || returnData[31] == 0) {

            return address(0);
        }

        (success, returnData) = a.staticcall(
            abi.encodeWithSignature("supportsInterface(bytes4)", interfaceID)
        );
        if (!success || returnData.length < 32 || returnData[31] == 0) {

            return address(0);
        }

        return a;
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual override returns(bool) {
        return
        interfaceID == type(IInterfaceResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}

abstract contract NameResolver is INameResolver, ResolverBase {
    mapping(uint64 => mapping(bytes32 => string)) versionable_names;

    function setName(
        bytes32 node,
        string calldata newName
    ) external virtual authorised(node) {
        versionable_names[recordVersions[node]][node] = newName;
        emit NameChanged(node, newName);
    }

    function name(
        bytes32 node
    ) external view virtual override returns(string memory) {
        return versionable_names[recordVersions[node]][node];
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual override returns(bool) {
        return
        interfaceID == type(INameResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}

abstract contract PubkeyResolver is IPubkeyResolver, ResolverBase {
    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    mapping(uint64 => mapping(bytes32 => PublicKey)) versionable_pubkeys;

    function setPubkey(
        bytes32 node,
        bytes32 x,
        bytes32 y
    ) external virtual authorised(node) {
        versionable_pubkeys[recordVersions[node]][node] = PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

    function pubkey(
        bytes32 node
    ) external view virtual override returns(bytes32 x, bytes32 y) {
        uint64 currentRecordVersion = recordVersions[node];
        return (
            versionable_pubkeys[currentRecordVersion][node].x,
            versionable_pubkeys[currentRecordVersion][node].y
        );
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual override returns(bool) {
        return
        interfaceID == type(IPubkeyResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}

interface ITextResolver {
    event TextChanged(
    bytes32 indexed node,
    string indexed indexedKey,
    string key,
    string value
);

function text(
    bytes32 node,
    string memory key
) external view returns(string memory);
}

abstract contract TextResolver is ITextResolver, ResolverBase {
    mapping(uint64 => mapping(bytes32 => mapping(string => string))) versionable_texts;

    function setText(
        bytes32 node,
        string calldata key,
        string calldata value
    ) external virtual authorised(node) {
        versionable_texts[recordVersions[node]][node][key] = value;
        emit TextChanged(node, key, key, value);
    }

    function text(
        bytes32 node,
        string memory key
    ) public view virtual override returns(string memory) {
        return versionable_texts[recordVersions[node]][node][key];
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual override returns(bool) {
        return
        interfaceID == type(ITextResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}

interface IReverseRegistrar {
    function setDefaultResolver(address resolver) external;

function claim(address owner) external returns(bytes32);

function claimForAddr(
    address addr,
    address owner,
    address resolver
) external returns(bytes32);

function claimWithResolver(
    address owner,
    address resolver
) external returns(bytes32);

function setName(string memory name) external returns(bytes32);

function setNameForAddr(
    address addr,
    address owner,
    address resolver,
    string memory name
) external returns(bytes32);

function node(address addr) external pure returns(bytes32);
}

contract ReverseClaimer {
    bytes32 constant ADDR_REVERSE_NODE =
        0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    constructor(ENS ens, address claimant) {
        IReverseRegistrar reverseRegistrar = IReverseRegistrar(
        ens.owner(ADDR_REVERSE_NODE)
    );
        reverseRegistrar.claim(claimant);
    }
}

interface IMetadataService {
    function uri(uint256) external view returns (string memory);
}

interface INameWrapperUpgrade {
    function wrapFromUpgrade(
    bytes calldata name,
    address wrappedOwner,
    uint32 fuses,
    uint64 expiry,
    address approved,
    bytes calldata extraData
) external;
}

uint32 constant CANNOT_UNWRAP = 1;
uint32 constant CANNOT_BURN_FUSES = 2;
uint32 constant CANNOT_TRANSFER = 4;
uint32 constant CANNOT_SET_RESOLVER = 8;
uint32 constant CANNOT_SET_TTL = 16;
uint32 constant CANNOT_CREATE_SUBDOMAIN = 32;
uint32 constant CANNOT_APPROVE = 64;

uint32 constant PARENT_CANNOT_CONTROL = 1 << 16;
uint32 constant IS_DOT_ETH = 1 << 17;
uint32 constant CAN_EXTEND_EXPIRY = 1 << 18;
uint32 constant CAN_DO_EVERYTHING = 0;
uint32 constant PARENT_CONTROLLED_FUSES = 0xFFFF0000;

uint32 constant USER_SETTABLE_FUSES = 0xFFFDFFFF;

interface INameWrapper is IERC1155 {
    event NameWrapped(
    bytes32 indexed node,
    bytes name,
    address owner,
    uint32 fuses,
    uint64 expiry
);

    event NameUnwrapped(bytes32 indexed node, address owner);

    event FusesSet(bytes32 indexed node, uint32 fuses);
    event ExpiryExtended(bytes32 indexed node, uint64 expiry);

    function ens() external view returns(ENS);

    function registrar() external view returns(IBaseRegistrar);

    function metadataService() external view returns(IMetadataService);

    function names(bytes32) external view returns(bytes memory);

    function name() external view returns(string memory);

    function upgradeContract() external view returns(INameWrapperUpgrade);

    function supportsInterface(bytes4 interfaceID) external view returns(bool);

    function wrap(
        bytes calldata name,
        address wrappedOwner,
        address resolver
    ) external;

    function wrapETH2LD(
        string calldata label,
        address wrappedOwner,
        uint16 ownerControlledFuses,
        address resolver
    ) external returns(uint64 expires);

    function registerAndWrapETH2LD(
        string calldata label,
        address wrappedOwner,
        uint256 duration,
        address resolver,
        uint16 ownerControlledFuses
    ) external returns(uint256 registrarExpiry);

    function renew(
        uint256 labelHash,
        uint256 duration
    ) external returns(uint256 expires);

    function unwrap(bytes32 node, bytes32 label, address owner) external;

    function unwrapETH2LD(
        bytes32 label,
        address newRegistrant,
        address newController
    ) external;

    function upgrade(bytes calldata name, bytes calldata extraData) external;

    function setFuses(
        bytes32 node,
        uint16 ownerControlledFuses
    ) external returns(uint32 newFuses);

    function setChildFuses(
        bytes32 parentNode,
        bytes32 labelhash,
        uint32 fuses,
        uint64 expiry
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        string calldata label,
        address owner,
        address resolver,
        uint64 ttl,
        uint32 fuses,
        uint64 expiry
    ) external returns(bytes32);

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        string calldata label,
        address newOwner,
        uint32 fuses,
        uint64 expiry
    ) external returns(bytes32);

    function extendExpiry(
        bytes32 node,
        bytes32 labelhash,
        uint64 expiry
    ) external returns(uint64);

    function canModifyName(
        bytes32 node,
        address addr
    ) external view returns(bool);

    function setResolver(bytes32 node, address resolver) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function ownerOf(uint256 id) external view returns(address owner);

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns(address);

    function getData(
        uint256 id
    ) external view returns(address, uint32, uint64);

    function setMetadataService(IMetadataService _metadataService) external;

    function uri(uint256 tokenId) external view returns(string memory);

    function setUpgradeContract(INameWrapperUpgrade _upgradeAddress) external;

    function allFusesBurned(
        bytes32 node,
        uint32 fuseMask
    ) external view returns(bool);

    function isWrapped(bytes32) external view returns(bool);

    function isWrapped(bytes32, bytes32) external view returns(bool);
}


interface IExtendedResolver {
    function resolve(bytes calldata name, bytes calldata data) external view returns(bytes memory);
}

interface nftContract {
    function ownerOf(uint256 tokenId) external view returns(address);
    function tokenURI(uint256 tokenId) external view returns(string memory);
    function name() external view returns(string memory);
}

contract EVM_NFT_Wildcard_Resolver is
    Ownable,
    IExtendedResolver,
    Multicallable,
    ABIResolver,
    AddrResolver,
    ContentHashResolver,
    InterfaceResolver,
    NameResolver,
    PubkeyResolver,
    TextResolver,
    ReverseClaimer
{
    ENS immutable ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    INameWrapper immutable nameWrapper = INameWrapper(0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401);
    address immutable trustedETHController = 0x253553366Da8546fC250F225fe3d25d0C782303b;
    address immutable trustedReverseRegistrar = 0xa58E81fe9b61B5c3fE2AFD33CF304c454AbFc7Cb;

    error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);

    struct linkedaddress {address tokenContract; uint256 chainId;}
    mapping(string => linkedaddress) public addrOf;

    struct urlChainId {string gateway; }
    mapping(uint256 => urlChainId) public gatewayOf;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(address => mapping(bytes32 => mapping(address => bool)))
        private _tokenApprovals;

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event Approved(
        address owner,
        bytes32 indexed node,
        address indexed delegate,
        bool indexed approved
    );

    constructor() ReverseClaimer(ens, msg.sender) {}

    function setApprovalForAll(address operator, bool approved) external {
        require(
            msg.sender != operator,
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(
        address account,
        address operator
    ) public view returns(bool) {
        return _operatorApprovals[account][operator];
    }

    function approve(bytes32 node, address delegate, bool approved) external {
        require(msg.sender != delegate, "Setting delegate status for self");

        _tokenApprovals[msg.sender][node][delegate] = approved;
        emit Approved(msg.sender, node, delegate, approved);
    }

    function isApprovedFor(
        address owner,
        bytes32 node,
        address delegate
    ) public view returns(bool) {
        return _tokenApprovals[owner][node][delegate];
    }

    function isAuthorised(bytes32 node) internal view override returns(bool) {
        if (
            msg.sender == trustedETHController ||
            msg.sender == trustedReverseRegistrar
        ) {
            return true;
        }
        address owner = ens.owner(node);
        if (owner == address(nameWrapper)) {
            owner = nameWrapper.ownerOf(uint256(node));
        }
        return
        owner == msg.sender ||
            isApprovedForAll(owner, msg.sender) ||
            isApprovedFor(owner, node, msg.sender);
    }
    
    function namehash(string memory domain) internal pure returns(bytes32) {
        return namehash(bytes(domain), 0);
    }

    function namehash(bytes memory domain, uint i) internal pure returns(bytes32) {
        if (domain.length <= i)
            return 0x0000000000000000000000000000000000000000000000000000000000000000;

    uint len = LabelLength(domain, i);

        return keccak256(abi.encodePacked(namehash(domain, i + len + 1), keccak(domain, i, len)));
    }

    function LabelLength(bytes memory domain, uint i) private pure returns(uint) {
    uint len;
        while (i + len < domain.length && domain[i + len] != 0x2e) {
            len++;
        }
        return len;
    }

    function keccak(bytes memory data, uint offset, uint len) private pure returns(bytes32 ret) {
        require(offset + len <= data.length);
    assembly {
            ret:= keccak256(add(add(data, 32), offset), len)
        }
    }

    function decodeName(bytes memory input) public pure returns(string memory, string memory) {
    uint pos = 0;
    uint8 labelCount = 0;
    string memory leftLabel = "";
    string memory remainingDomain = "";
        while (pos < input.length) {
        uint8 length = uint8(input[pos]);
            if (length == 0) {
                break;
            }
            require(length > 0 && length <= 63, "Invalid length");
        bytes memory labelBytes = new bytes(length);
            for (uint i = 0; i < length; i++) {
                labelBytes[i] = input[pos + i + 1];
            }
        string memory label = string(labelBytes);
            if (labelCount == 0) {
                leftLabel = label;
            } else {
                if (bytes(remainingDomain).length > 0) {
                    remainingDomain = string(abi.encodePacked(remainingDomain, "."));
                }
                remainingDomain = string(abi.encodePacked(remainingDomain, label));
            }
            labelCount++;
            pos += length + 1;
        }
        return (leftLabel, remainingDomain);
    }

    function decodeData(bytes memory callData) public pure returns(uint256 functionName, bytes32 node, string memory key, uint256 coinType) {
        bytes4 functionSelector;
        assembly {
            functionSelector:= mload(add(callData, 0x20))
        }
        bytes memory callDataWithoutSelector = new bytes(callData.length - 4);
        for (uint256 i = 0; i < callData.length - 4; i++) {
            callDataWithoutSelector[i] = callData[i + 4];
        }
        if (functionSelector == bytes4(keccak256("addr(bytes32)"))) {
            functionName = 1;
            (node) = abi.decode(callDataWithoutSelector, (bytes32));
        } if (functionSelector == bytes4(keccak256("addr(bytes32,uint256)"))) {
            functionName = 2;
            (node, coinType) = abi.decode(callDataWithoutSelector, (bytes32, uint256));
        } if (functionSelector == bytes4(keccak256("contenthash(bytes32)"))) {
            functionName = 3;
            (node) = abi.decode(callDataWithoutSelector, (bytes32));
        } if (functionSelector == bytes4(keccak256("text(bytes32,string)"))) {
            functionName = 4;
            (node, key) = abi.decode(callDataWithoutSelector, (bytes32, string));
        }
    }

    function compare(string memory _a, string memory _b) internal pure returns(int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;

        for (uint i = 0; i < minLength; i++)
        if (a[i] < b[i]) return -1;
        else if (a[i] > b[i]) return 1;
        if (a.length < b.length) return -1;
        else if (a.length > b.length) return 1;
        else
            return 0;
    }

    function equals(string memory _a, string memory _b) internal pure returns(bool) {
        return compare(_a, _b) == 0;
    }

    function toUint(string memory input) public pure returns(uint256) {
        bytes memory inputBytes = bytes(input);
        uint256 result = 0;
        for (uint8 i = 0; i < inputBytes.length; i++) {
            uint8 digit = uint8(inputBytes[i]) - 48; 
            require(digit >= 0 && digit <= 9, "Subdomain must be a valid NFT token ID");
            result = result * 10 + digit;
        }
        return result;
    }

    function toString(address _addr) public pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint8(uint8(value[i + 12]) & 0xf)];
        }
        return string(str);
    }

    event linkENStoNFT (string ENS, uint256 Chain_Id, address NFT_Contract);
    function setLinkedContract(string memory name, uint256 NFTchainId, address nftaddr)
    external
    returns(bool)
    {
        bytes32 node = namehash(name);
        require(isAuthorised(node), "You are not the manager of the ENS name."); 
        addrOf[name].tokenContract = nftaddr;
        addrOf[name].chainId = NFTchainId;
        emit linkENStoNFT(name, NFTchainId, nftaddr);
        return true;
    }

    function ensLinkedTo (string memory ensdomain)
    external view
    returns(address, uint256)
    {
        return (addrOf[ensdomain].tokenContract, addrOf[ensdomain].chainId);
    }

    function managerOf (string memory ensdomain)
    external view
    returns(address)
    {
        bytes32 node = namehash(ensdomain);
        return ens.owner(node);
    }

    function setGateway (uint256 chainId, string memory urlgateway)
    external onlyOwner
    returns(bool)
    {
        gatewayOf[chainId].gateway = urlgateway;
        return true;
    }


    function ccip(bytes calldata response, bytes calldata extraData) external pure returns(bytes memory) {
        return response;
    }


    function resolve(bytes calldata name, bytes calldata data) public view returns(bytes memory) {
        (string memory domain, string memory main) = decodeName(name);
        (uint256 functionName, bytes32 node, string memory key, uint256 coinType) = decodeData(data);
        address resolver = ens.resolver(node);
        uint256 chain = addrOf[main].chainId;
        address nft = addrOf[main].tokenContract;

        if ((chain != 1) && (resolver == address(0x0))) {
            string memory url = gatewayOf[chain].gateway;
            offchainResolve(name, data, url, nft);
        }

        else{

        if (resolver == address(0x0)) {
            nftContract wildcard = nftContract(addrOf[main].tokenContract);
            if (functionName == 1) {
                return abi.encode(wildcard.ownerOf(toUint(domain)));
            }
            if (functionName == 2 && (coinType == 60 || coinType > 2147483648)) {
                return abi.encode(addressToBytes(wildcard.ownerOf(toUint(domain))));
            }
            if (functionName == 4 && equals(key, "avatar") && toUint(domain) >= 0) {
                string memory nftaddr = toString(addrOf[main].tokenContract);
                return abi.encode(abi.encodePacked("eip155:1/erc721:",nftaddr,"/",domain));
            }
            if (functionName == 4 && equals(key, "description") && toUint(domain) >= 0) {
                return abi.encode(wildcard.name());
            }
            if (functionName == 4 && equals(key, "url") && toUint(domain) >= 0) {
                return abi.encode(wildcard.tokenURI(toUint(domain)));
            }


        }

        if (resolver != address(0x0)) {

            if (functionName == 1) {
                return abi.encode(addr(node));
            } 
            if (functionName == 2) {
                return abi.encode(addr(node, coinType));
            } 
            if (functionName == 3) {
                return abi.encode(contenthash(node));
            } 
            if (functionName == 4) {
                return abi.encode(text(node, key));
            }
        } 

        return abi.encode(0x00);
        }
    }

    function offchainResolve(bytes calldata name, bytes calldata data, string memory url, address nft) internal view returns(bytes memory) {
        bytes memory callData = abi.encode(name, data, nft);
        string[] memory urls = new string[](1);
        urls[0] = url;
        revert OffchainLookup(
            address(this),
            urls,
            callData,
            EVM_NFT_Wildcard_Resolver.ccip.selector,
            callData
        );
    }

    function supportsInterface(
        bytes4 interfaceID
    )
    public
    view
    override(
        Multicallable,
        ABIResolver,
        AddrResolver,
        ContentHashResolver,
        InterfaceResolver,
        NameResolver,
        PubkeyResolver,
        TextResolver
    )
    returns(bool)
    {
        return interfaceID == type(IExtendedResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}