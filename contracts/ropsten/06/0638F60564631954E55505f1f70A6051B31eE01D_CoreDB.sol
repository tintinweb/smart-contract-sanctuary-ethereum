// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ICoreDB.sol";

abstract contract APP {

    ICoreDB public coreDB;

    mapping(address => bool) public operators;

    modifier onlyCoreDAO {
        require(msg.sender == coreDB.coreDAO(), "Caller is not the CoreDAO");
        _;
    }

    modifier onlyOperator {
        require(operators[msg.sender] , "Caller is not an operator");
        _;
    }

    modifier onlyCoreNFT {
        require(msg.sender == coreDB.coreNFT(), "Caller is not the CoreNFT");
        _;
    }

    modifier onlyCoreRegistrar {
        require(msg.sender == coreDB.coreRegistrar(), "Caller is not the CoreRegistrar");
        _;
    }

    function initApp(address core_db) internal {
        coreDB = ICoreDB(core_db);
    }

    function setCoreDB(address core_db) external onlyCoreDAO {
        coreDB = ICoreDB(core_db);
    }

    function setOperator(address addr, bool flag) external onlyCoreDAO {
        operators[addr] = flag;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ICoreDB {

    struct Node {
        bytes32 parent;
        address owner;
        uint64 expire;
        uint64 ttl;
        uint64 transfer;
        string name;
    }

    // function operators(address addr) external view returns (bool);
    function coreDAO() external view returns (address);
    function coreRegistrar() external view returns (address);
    function coreNFT() external view returns (address);
    function coreSW() external view returns (address);
    // function coreDB() external view returns (address);
    function coreResolver() external view returns (address);
    function coreMeta() external view returns (address, address, address, address, address, address);
    function coreMetaURI() external view returns (string memory);

    function balanceOf(address owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function reverseRecord(address main_address) external view returns (bytes32);

    // function nodeRecord(bytes32 node) external view returns (Node memory);
    function getNodeRecord(bytes32 node) external view returns (Node memory);
    function getOwnerItem(address owner, bytes32 item_key) external view returns (bytes memory);
    function getNodeItem(bytes32 node, bytes32 item_key) external view returns (bytes memory);
    function getNodeOwnerItem(bytes32 node, bytes32 item_key) external view returns (bytes memory);

    function getOwnerItemLength(address owner, bytes32 item_key) external view returns (uint256);
    function getNodeItemLength(bytes32 node, bytes32 item_key) external view returns (uint256);
    function getNodeOwnerItemLength(bytes32 node, bytes32 item_key) external view returns (uint256);

    function setReverse(address main_address, bytes32 node) external;
    function setNodeExpire(bytes32 node, uint64 expire) external;
    function setNodeTTL(bytes32 node, uint64 ttl) external;

    function setNodeItem(bytes32 node, bytes32 item_key, bytes memory item_value) external;
    function setOwnerItem(address owner, bytes32 item_key, bytes memory item_value) external;
    function setNodeItemBatch(bytes32 node, bytes32[] memory item_keys, bytes[] memory item_values) external;
    function setOwnerItemBatch(address owner, bytes32[] memory item_keys, bytes[] memory item_values) external;

    function deleteNodeItem(bytes32 node, bytes32 item_key) external;
    function deleteOwnerItem(address owner, bytes32 item_key) external;
    function deleteNodeItemBatch(bytes32 node, bytes32[] memory item_keys) external;
    function deleteOwnerItemBatch(address owner, bytes32[] memory item_keys) external;

    function isNodeActive(bytes32 node) external view returns (bool);
    function isNodeExisted(bytes32 node) external view returns (bool);

    function createNode(bytes32 parent, bytes32 node, address owner, uint64 expire, uint64 ttl, string memory name) external;
    function transferNodeOwner(bytes32 node, address new_owner) external;
    function clearNode(bytes32 node) external;

    function setTokenApprovals(uint256 token_id, address to) external;
    function setOperatorApprovals(address owner, address operator, bool approved) external;

    function tokenApprovals(uint256 token_id) external view returns (address);
    function operatorApprovals(address owner, address operator) external view returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Common/APP.sol";

contract SensitiveWords is APP {

    // 1, 1024 ETH, 2, 64 ETH, 3, 4 ETH, 4, 0.25 ETH, 5, 0.1 ETH, 6, 0.1 ETH...
    // [email protected], buffalo_163.yae, buffalo#163.eth are not supported, only buffalo-163 supported

    mapping(bytes32 => bool) public sensitiveHash;
    uint8 public minWordLength = 1;
    uint8 public maxWordLength = 255;

    constructor(address core_db) {
        initApp(core_db);
    }

    function setWordLength(uint8 min_len, uint8 max_len) external onlyOperator {
        require(max_len >= min_len, "arguments error");
        minWordLength = min_len;
        maxWordLength = max_len;
    }

    function putSensitiveHashBatch(bytes32[] memory hash_list, bool flag) external onlyOperator {
        for (uint256 i = 0; i < hash_list.length; i++) {
            sensitiveHash[hash_list[i]] = flag;
        }
    }

    function sensitiveWord(string memory word) public view returns (bool) {
        return sensitiveHash[keccak256(abi.encodePacked(word))];
    }

    function digitalOrAlphabet(uint8 character) internal pure returns (bool) {
        return (character >= 0x61 && character <= 0x7a) || (character >= 0x30 && character <= 0x39);
        // a ~ z || 0 ~ 9
    }

    function checkedWord(string memory word) public view returns (bool) {
        bytes memory word_bytes = bytes(word);

        if (word_bytes.length < minWordLength || word_bytes.length > maxWordLength) {
            return false;
        }

        for (uint256 i=0; i < word_bytes.length ; i++) {
            if (!digitalOrAlphabet(uint8(word_bytes[i]))) {
                return false;
            }
        }

        return true;
    }

    function validWord(string memory word) external view returns (bool) {
        return !sensitiveWord(word) && checkedWord(word);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Common/APP.sol";
import "./Common/KeyDefinition.sol";

interface IResolver {
    function getKeyVoiceScore(address main_address_or_owner) external view returns (uint256);
    function getNodeName(bytes32 node) external view returns (string memory);
    function getNodeOwner(bytes32 node) external view returns (address);
}

interface IRegistrar {
    function registerSubnode(
        bytes32 parent,
        address owner,
        uint64 expire,
        uint64 ttl,
        address payment,
        uint256 cost,
        string memory name,
        bytes memory _data
    ) external returns (bytes32);
}

contract SecondLevelRegistrar is KeyDefinition, APP {

    bytes32 public TOP_LEVEL_NODE;
    uint256 public FREE_REGISTRATION_DURATION = 365 days;
    address public platform;
    uint64 public interval = 300;
    uint64 public default_ttl = 0;

    constructor(address core_db, bytes32 top_level_node) {
        initApp(core_db);
        TOP_LEVEL_NODE = top_level_node;
    }

    function register(
        address owner,
        string memory name
    ) external returns (bytes32) {
        uint64 expire = uint64(block.timestamp + FREE_REGISTRATION_DURATION);
        bytes32 node = IRegistrar(coreDB.coreRegistrar()).registerSubnode(TOP_LEVEL_NODE, owner, expire, 0,  address(0), 0, name, "");
        return node;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract KeyDefinition {

    uint256 constant internal KEY_META = 0;
    uint256 constant internal KEY_REGISTRAR = 1;
    uint256 constant internal KEY_RESOLVER = 2;

    uint256 constant internal KEY_NFT_METADATA = 3;
    uint256 constant internal KEY_NFT_METADATA_URI = 4;
    uint256 constant internal KEY_NFT_OBJECT = 5; // NFT Image, Audio, Video...
    uint256 constant internal KEY_NFT_OBJECT_URI = 6;

    uint256 constant internal KEY_EMAIL = 300;
    uint256 constant internal KEY_WEBSITE = 301;
    uint256 constant internal KEY_GITHUB = 302;
    uint256 constant internal KEY_TWITTER = 303;
    uint256 constant internal KEY_INSTAGRAM = 304;
    uint256 constant internal KEY_TELEGRAM = 305;
    uint256 constant internal KEY_TELEPHONE = 306;

    uint256 constant internal KEY_CONTRIBUTION = 1000;
    uint256 constant internal KEY_ENS_INFO = 1001;

    uint256 constant internal KEY_ADDRESS_BTC = 2000;
    uint256 constant internal KEY_ADDRESS_SOL = 2001;
    uint256 constant internal KEY_ADDRESS_ADA = 2002;
    uint256 constant internal KEY_ADDRESS_DOGE = 2003;
    uint256 constant internal KEY_ADDRESS_DOT = 2004;
    uint256 constant internal KEY_ADDRESS_KSM = 2005;

    uint256 constant internal ETH_LIKE_ADDRESS_BEGIN = 6000;
    uint256 constant internal KEY_ADDRESS_ETH = (ETH_LIKE_ADDRESS_BEGIN + 0);
    uint256 constant internal KEY_ADDRESS_ETC = (ETH_LIKE_ADDRESS_BEGIN + 1);
    uint256 constant internal KEY_ADDRESS_YAE = (ETH_LIKE_ADDRESS_BEGIN + 2);
    uint256 constant internal KEY_ADDRESS_MATIC = (ETH_LIKE_ADDRESS_BEGIN + 3); // for Polygon
    uint256 internal ETH_LIKE_ADDRESS_END = KEY_ADDRESS_MATIC;
    uint256 internal KEY_ADDRESS_MAIN = KEY_ADDRESS_ETH;


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./KeyDefinition.sol";
import "./APP.sol";

abstract contract KVStorage is KeyDefinition, APP { // KVS: Key Value Storage

    function abiBytesToAddress(bytes memory bys) public pure returns(address payable ret) {
        require(bys.length == 32 || bys.length == 0, "Data bytes can not be decoded");
        if (bys.length == 32) {
            ret = abi.decode(bys, (address));
        }
        return ret;
    }

    function abiBytesToUint64(bytes memory bys) public pure returns(uint64 ret) {
        require(bys.length == 32 || bys.length == 0, "Data bytes can not be decoded");
        if (bys.length == 32) {
            ret = abi.decode(bys, (uint64));
        }
        return ret;
    }

    function abiBytesToUint256(bytes memory bys) public pure returns(uint256 ret) {
        require(bys.length == 32 || bys.length == 0, "Data bytes can not be decoded");
        if (bys.length == 32) {
            ret = abi.decode(bys, (uint256));
        }
        return ret;
    }

    function abiBytesToString(bytes memory bys) public pure returns(string memory ret) {
        if (bys.length > 0) {
            ret = abi.decode(bys, (string));
        }
        return ret;
    }

    function encodeItemKey(bytes32 node, uint256 item_key) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(node, bytes32(item_key)));
    }

    function encodeNameToNode(bytes32 parent, string memory name) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(parent, keccak256(abi.encodePacked(name))));
    }

    function getNodeOwner(bytes32 node) public view returns (address) {
        return coreDB.getNodeRecord(node).owner;
    }

    function getRegistrar(bytes32 node) public view returns (address) {
        return abiBytesToAddressWithoutTimestamp(coreDB.getNodeItem(node, bytes32(KEY_REGISTRAR)));
    }

    function abiBytesToAddressWithoutTimestamp(bytes memory bys) public pure returns(address payable addr) {
        uint256 num = abiBytesToUint256(bys);
        addr = payable(address(uint160(num >> 96)));
    }

    function setEthLikeAddressEnd(uint256 item_key) external onlyOperator {
        require(item_key > ETH_LIKE_ADDRESS_END && item_key < ETH_LIKE_ADDRESS_END + 10, "Invalid item");
        ETH_LIKE_ADDRESS_END = item_key;
    }

    function setKeyAddressMain(uint256 item_key) external onlyOperator {
        require(item_key >= ETH_LIKE_ADDRESS_BEGIN && item_key <= ETH_LIKE_ADDRESS_END, "Invalid item");
        ETH_LIKE_ADDRESS_END = item_key;
    }

}

// SPDX-License-Identifier: MIT

import "./Common/KVStorage.sol";
import "./Common/APP.sol";
import "./Common/ICoreDB.sol";

pragma solidity ^0.8.9;

contract CoreResolver is KVStorage {

    // name: "alice";
    // name_hash: keccak256(abi.encodePacked("alice"));
    // full_name: "eth", "alice.eth", "foobar.alice.eth";
    // node: keccak256(abi.encodePacked(parent, name_hash));
    // parent: parent node;

    constructor(address core_db) {
        initApp(core_db);
    }

    // full_name[www.alice.eth] => name_array[www,alice,eth]
    function encodeNameArrayToNode(string[] memory name_array) external pure returns (bytes32) {
        bytes32 node = bytes32(0);
        for (uint256 i = name_array.length; i > 0; i--) {
            node = encodeNameToNode(node, name_array[i-1]);
        }
        return node;
    }

    function abiBytesToAddressWithTimestamp(bytes memory bys) public pure returns(address payable addr, uint64 time_stamp) {
        uint256 num = abiBytesToUint256(bys);
        addr = payable(address(uint160(num >> 96)));
        time_stamp = uint64(num & type(uint96).max);
        return (addr, time_stamp);
    }

    function getNodeNameFull(bytes32 node) public view returns (string memory) {
        string memory full_name = coreDB.getNodeRecord(node).name;
        bytes32 parent = coreDB.getNodeRecord(node).parent;
        bytes32 root_node = bytes32(0);
        while (parent != root_node) {
            ICoreDB.Node memory parent_node = coreDB.getNodeRecord(parent);
            full_name = string(abi.encodePacked(full_name, ".", parent_node.name));
            parent = parent_node.parent;
        }
        return full_name;
    }

    function getReverse(address owner) public view returns (bytes32, string memory) {
        bytes32 node = coreDB.reverseRecord(owner);
        require(getNodeOwner(node) == owner, "owner doesn't exist");
        string memory name = getNodeNameFull(node);
        return (node, name);
    }

    function getResolver(bytes32 node) public view returns (address) {
        return abiBytesToAddressWithoutTimestamp(coreDB.getNodeItem(node, bytes32(KEY_RESOLVER)));
    }

    function getGroupMembers(bytes32 node) external view returns (address, address, address) {
        return (getNodeOwner(node), getRegistrar(node), getResolver(node));
    }

    function getNodeName(bytes32 node) public view returns (string memory) {
        return coreDB.getNodeRecord(node).name;
    }

    function getTTL(bytes32 node) external view returns (uint64) {
        return coreDB.getNodeRecord(node).ttl;
    }

    function getTwitter(bytes32 node) external view returns (string memory) {
        address owner = getNodeOwner(node);
        return abiBytesToString(coreDB.getOwnerItem(owner, encodeItemKey(node, KEY_TWITTER)));
    }

    function getInstagram(bytes32 node) external view returns (string memory) {
        address owner = getNodeOwner(node);
        return abiBytesToString(coreDB.getOwnerItem(owner, encodeItemKey(node, KEY_INSTAGRAM)));
    }

    function getContribution(address owner) external view returns (uint256) {
        return abiBytesToUint256(coreDB.getOwnerItem(owner, encodeItemKey(bytes32(0), KEY_CONTRIBUTION)));
    }

    function getNftMetadataURI(bytes32 node) external view returns (string memory) {
        return abiBytesToString(coreDB.getNodeItem(node, bytes32(KEY_NFT_METADATA_URI)));
    }

    // KEY_RESOLVER KEY_REGISTRAR KEY_ADDRESS_MAIN...
    function getAddressItem(bytes32 node, uint256 item_key) external view returns (address) {
        return abiBytesToAddressWithoutTimestamp(coreDB.getNodeOwnerItem(node, encodeItemKey(node, item_key)));
    }

    function getAddressItemWithTimestamp(bytes32 node, uint256 item_key) external view returns (address, uint64) {
        return abiBytesToAddressWithTimestamp(coreDB.getNodeOwnerItem(node, encodeItemKey(node, item_key)));
    }

    function getAddressItemList(bytes32 node, uint256 begin, uint256 end) external view returns (address[] memory) {
        require(end >= begin, "arguments error");
        address[] memory addr_array = new address[](end + 1 - begin);
        for (uint256 item_key = begin; item_key <= end; item_key++) {
            if (item_key == KEY_ADDRESS_MAIN) {
                addr_array[item_key - begin] = getNodeOwner(node);
            }
            addr_array[item_key - begin] = abiBytesToAddressWithoutTimestamp(coreDB.getNodeOwnerItem(node, encodeItemKey(node, item_key)));
        }
        return addr_array;
    }

    function getAddressItemListWithTimestamp(bytes32 node, uint256 begin, uint256 end) external view returns (address[] memory, uint64[] memory) {
        require(end >= begin, "arguments error");
        uint256 i = end + 1 - begin;
        address[] memory addr_array = new address[](i);
        uint64[] memory time_array = new uint64[](i);
        for (uint256 item_key = begin; item_key <= end; item_key++) {
            i = item_key - begin;
            if (item_key == KEY_ADDRESS_MAIN) {
                ICoreDB.Node memory n = coreDB.getNodeRecord(node);
                (addr_array[i], time_array[i]) = (n.owner, n.transfer);
            }
            (addr_array[i], time_array[i]) = abiBytesToAddressWithTimestamp(coreDB.getNodeOwnerItem(node, encodeItemKey(node, item_key)));
        }
        return (addr_array, time_array);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Common/KVStorage.sol";
import "./Common/ICoreDB.sol";

interface ICoreNFT {
    function beforeMint(address to, uint256 tokenId) external;
    function afterMint(address to, uint256 tokenId, bytes memory _data) external;
    function reclaimNFT(address from, address to, uint256 tokenId, bytes memory _data) external;
}

interface ISensitiveWords {
    function sensitiveHash(bytes32 word_hash) external view returns (bool);
    function sensitiveWord(string memory word) external view returns (bool);
    function checkedWord(string memory word) external pure returns (bool);
    function validWord(string memory word) external view returns (bool);
}

contract CoreRegistrar is KVStorage {

    event NodeCreatedOrReclaimed(bytes32 indexed parent, bytes32 indexed node, address indexed owner, uint64 expire, uint64 ttl, address payment, uint256 cost, string name);
    event NodeItemChangedWithValue(bytes32 indexed node, address indexed owner, bytes32 indexed key, bytes value);
    event NodeOwnerItemChangedWithValue(bytes32 indexed node, address indexed owner, bytes32 indexed key, bytes value);
    event NodeExpireUpdated(bytes32 indexed node, address indexed owner, uint64 expire);

    mapping(address => bool) public topLevelRegistrars; // Top Level Domain Registrars
    bool public openForAll;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    constructor(address core_db) {
        initApp(core_db);
        openForAll = true;
    }

    // Require msg.sender is a TeamMember (Owner, Manager, Main_Address, Registrar_Contract)
    modifier onlyGroupMemberAndActive(bytes32 node) {
        require (
            msg.sender == getNodeOwner(node) ||
            msg.sender == getRegistrar(node),
            "caller is not a team member"
        );
        require (coreDB.isNodeActive(node), "invalid node");
        _;
    }

    modifier onlyTopLevelRegistrar() {
        require(topLevelRegistrars[msg.sender], "caller is not verse-registrar");
        _;
    }

    function setOpenForAll(bool flag) external onlyOperator {
        openForAll = flag;
    }

    function setWeb2(bytes32 node, uint256 web2_type, bytes memory web2_info) external onlyTopLevelRegistrar {
        require(web2_type >= KEY_EMAIL && web2_type <= KEY_TELEPHONE, "this web2 type is not supported");
        _setOwnerItem(node, web2_type, web2_info);
    }

    function setWeb3(bytes32 node, uint256 web3_type, bytes memory we3_info) external onlyTopLevelRegistrar {
        require(web3_type >= KEY_CONTRIBUTION && web3_type <= KEY_ENS_INFO, "this web3 type is not supported");
        _setOwnerItem(node, web3_type, we3_info);
    }

    function setTTL(bytes32 node, uint64 ttl) external onlyGroupMemberAndActive(node) {
        coreDB.setNodeTTL(node, ttl);
    }

    function setNftMetadataURI(bytes32 node, string memory uri) external onlyGroupMemberAndActive(node) {
        _setNodeItem(node, bytes32(KEY_NFT_METADATA_URI), abi.encode(uri));
    }

    function _setNodeItem(bytes32 node, bytes32 item_key, bytes memory item_value) private {
        coreDB.setNodeItem(node, item_key, item_value);
        emit NodeItemChangedWithValue(node, getNodeOwner(node), item_key, item_value);
    }

    function _setOwnerItem(bytes32 node, uint256 item_key, bytes memory item_value) private {
        address owner = getNodeOwner(node);
        coreDB.setOwnerItem(owner, encodeItemKey(node, item_key), item_value);
        emit NodeOwnerItemChangedWithValue(node, owner, bytes32(item_key), item_value);
    }

    function _setOwnerAddressItem(bytes32 node, uint256 item_key, address addr) private {
        bytes32 encoded_item_key = encodeItemKey(node, item_key);
        bytes memory encoded_item_value = "";
        address owner = getNodeOwner(node);
        if (addr == address(0)) {
            coreDB.deleteOwnerItem(owner, encoded_item_key);
        } else {
            // Address with Timestamp: |Address(160bit)|Null(32bit)|Timestamp(64bit)|
            encoded_item_value = abi.encode((uint256(uint160(addr)) << 96) + uint64(block.timestamp));
            coreDB.setOwnerItem(owner, encoded_item_key, encoded_item_value);
        }
        emit NodeOwnerItemChangedWithValue(node, owner, bytes32(item_key), encoded_item_value);
    }

    function setRegistrar(bytes32 node, address registrar) external onlyGroupMemberAndActive(node) {
        if (coreDB.getNodeRecord(node).parent == bytes32(0) && node != bytes32(0)) { // Only record Top Level Domain Registrar
            delete topLevelRegistrars[getRegistrar(node)];
            topLevelRegistrars[registrar] = true;
        }
        _setNodeItem(node, bytes32(KEY_REGISTRAR), abi.encode((uint256(uint160(registrar)) << 96) + uint64(block.timestamp)));
    }

    function setResolver(bytes32 node, address resolver) external onlyGroupMemberAndActive(node) {
        _setNodeItem(node, bytes32(KEY_RESOLVER), abi.encode((uint256(uint160(resolver)) << 96) + uint64(block.timestamp)));
    }

    function setReverse(bytes32 node) external { // node == bytes(0) means delete reverse record
        // require(getNodeOwner(node) == msg.sender, "node owner doesn't match");
        coreDB.setReverse(msg.sender, node);
    }

    function setEthLikeAddressList(bytes32 node, uint256[] memory item_keys, address[] memory eth_like_addrs) external onlyGroupMemberAndActive(node) {
        require(item_keys.length == eth_like_addrs.length, "length error");
        for (uint256 i=0; i < item_keys.length; i++) {
            require(
                item_keys[i] >= ETH_LIKE_ADDRESS_BEGIN &&
                item_keys[i] <= ETH_LIKE_ADDRESS_END &&
                item_keys[i] != KEY_ADDRESS_MAIN,
                "item key is not an ethereum-like address"
            );
            _setOwnerAddressItem(node, item_keys[i], eth_like_addrs[i]);
        }
    }

    function registerSubnode(
        bytes32 parent,
        address owner,
        uint64 expire,
        uint64 ttl,
        address payment,
        uint256 cost,
        string memory name,
        bytes memory _data
    ) external nonReentrant() onlyGroupMemberAndActive(parent) returns (bytes32) {

        require(openForAll || topLevelRegistrars[msg.sender], "caller is not a top level registrar");

        address core_sw = coreDB.coreSW();
        if (core_sw != address(0)) {
            require(ISensitiveWords(core_sw).validWord(name), "name is sensitive or not checked");
        }

        bytes32 node = encodeNameToNode(parent, name);
        address nft = coreDB.coreNFT();

        if (!coreDB.isNodeExisted(node)) {
            // ICoreNFT(nft).beforeMint(owner, uint256(node)); // no need to call beforeMint
            coreDB.createNode(parent, node, owner, expire, ttl, name);
            ICoreNFT(nft).afterMint(owner, uint256(node), _data);
        } else if (!coreDB.isNodeActive(node)) {
            ICoreNFT(nft).reclaimNFT(getNodeOwner(node), owner, uint256(node), _data);
            coreDB.setNodeExpire(node, expire);
            coreDB.setNodeTTL(node, ttl);
        } else {
            revert("node is active");
        }

        emit NodeCreatedOrReclaimed(parent, node, owner, expire, ttl, payment, cost, name);

        return node;

    }

    function renewExpire(bytes32 node, uint64 expire) external {
        bytes32 parent = coreDB.getNodeRecord(node).parent;
        require(msg.sender == getRegistrar(parent), "caller is not the registrar of the parent node");
        coreDB.setNodeExpire(node, expire);
        emit NodeExpireUpdated(node, getNodeOwner(node), expire);
    }


}

// NFT transfer require DID-Node not expired for normal case to avoid some frauds; but allow transferring if Msg.sender == CoreRegistrar

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Common/ICoreDB.sol";
import "./Common/APP.sol";

contract CoreDB is ICoreDB, APP {

    // Registrar, Resolver, belong to node-DB without Item-Key-Encode
    // MainAddress, EthAddress, Email..., belong to owner-DB with Item-Key-Encode

    mapping(address => mapping(bytes32 => bytes)) public ownerDB;
    mapping(bytes32 => mapping(bytes32 => bytes)) nodeDB;
    mapping(bytes32 => Node) public nodeRecord;
    mapping(address => bytes32) public reverseRecord;

    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    mapping(uint256 => address) public tokenApprovals; // Mapping from token ID to approved address
    mapping(address => mapping(address => bool)) public operatorApprovals;  // Mapping from owner to operator approvals

    bytes32 constant public rootNode = bytes32(0);

    address public coreDAO ;
    address public coreRegistrar;
    address public coreNFT;
    address public coreSW;
    address public coreResolver;
    string public coreMetaURI;

    event ReverseRecordSet(address indexed main_address, bytes32 indexed node); // node == bytes(0) means delete reverse record

    constructor(address dao) {
        coreDAO = dao;
        coreDB = this;

        nodeRecord[rootNode].parent = rootNode;
        nodeRecord[rootNode].owner = dao;
        nodeRecord[rootNode].transfer = uint64(block.timestamp);
        nodeRecord[rootNode].expire = type(uint64).max;
        nodeRecord[rootNode].ttl = 0;
        nodeRecord[rootNode].name = "";

        balanceOf[dao] = 1;
        totalSupply = 1;
    }

    modifier onlyExisted(bytes32 node) {
        require(isNodeExisted(node) , "node is not existed");
        _;
    }

    function setCoreMetaURI(string memory uri) external onlyCoreDAO {
        coreMetaURI = uri;
    }

    function setCoreDAO(address dao) external onlyCoreDAO {
        coreDAO = dao;
    }

    function setCoreRegistrar(address registrar) public onlyCoreDAO {
        operators[coreRegistrar] = false;
        operators[registrar] = true;
        coreRegistrar = registrar;
    }

    function setCoreNFT(address nft) public onlyCoreDAO {
        operators[coreNFT] = false;
        operators[nft] = true;
        coreNFT = nft;
    }

    function setCoreSW(address sw) external onlyCoreDAO {
        coreSW = sw;
    }

    function setCoreResolver(address resolver) external onlyCoreDAO {
        coreResolver = resolver;
    }

    function setNodeExpire(bytes32 node, uint64 expire) external onlyExisted(node) onlyOperator {
        require(
            nodeRecord[nodeRecord[node].parent].expire >= expire &&
            expire > block.timestamp &&
            expire > nodeRecord[node].expire, "invalid expire"
        );
        nodeRecord[node].expire = expire;
    }

    function setNodeTTL(bytes32 node, uint64 ttl) external onlyExisted(node) onlyOperator {
        nodeRecord[node].ttl = ttl;
    }

    function setReverse(address owner, bytes32 node) onlyExisted(node) external onlyOperator {
        bytes32 current_node = reverseRecord[owner];
        if (current_node != node) {
            if (node != bytes32(0)) {
                require(nodeRecord[node].owner == owner, "node owner doesn't match");
                reverseRecord[owner] = node;
            } else {
                delete reverseRecord[owner];
            }
            emit ReverseRecordSet(owner, node);
        }
    }

    function _setReverse(address owner, bytes32 node) private {
        if (reverseRecord[owner] == bytes32(0) && node != bytes32(0)) {
            reverseRecord[owner] = node;
            emit ReverseRecordSet(owner, node);
        }
    }

    function _deleteReverse(address owner, bytes32 node) private {
        if (reverseRecord[owner] == node && node != bytes32(0)) {
            delete reverseRecord[owner];
            emit ReverseRecordSet(owner, bytes32(0));
        }
    }

    // Register (Mint NFT)
    function createNode(bytes32 parent, bytes32 node, address owner, uint64 expire, uint64 ttl, string memory name) external onlyCoreRegistrar {
        require(!isNodeExisted(node), "invalid node"); // require of expire to make sure parent is active.
        require(nodeRecord[parent].expire >= expire && expire > block.timestamp, "invalid expire");
        require(owner != address(0) , "invalid owner");

        nodeRecord[node].parent = parent;
        nodeRecord[node].owner = owner;
        nodeRecord[node].transfer = uint64(block.timestamp);
        nodeRecord[node].expire = expire;
        nodeRecord[node].ttl = ttl;
        nodeRecord[node].name = name;

        balanceOf[owner] += 1;
        totalSupply += 1;

        _setReverse(owner, node);
    }

    // Burn NFT, only for expired nodes
    function clearNode(bytes32 node) external onlyCoreNFT {
        require(!isNodeActive(node), "node is active");
        address current_owner = nodeRecord[node].owner;
        balanceOf[current_owner] -= 1;
        totalSupply -= 1;
        delete nodeRecord[node];

        _deleteReverse(current_owner, node);
    }

    // Transfer NFT; Reclaim node
    function transferNodeOwner(bytes32 node, address owner) external onlyExisted(node) onlyCoreNFT {
        require(owner != address(0) , "invalid owner"); // Use clearNode instead owner == address(0)
        address current_owner = nodeRecord[node].owner;

        balanceOf[current_owner] -= 1;
        balanceOf[owner] += 1;
        nodeRecord[node].owner = owner;
        nodeRecord[node].transfer = uint64(block.timestamp);

        _deleteReverse(current_owner, node);
        _setReverse(owner, node);
    }

    function setTokenApprovals(uint256 token_id, address to) external onlyExisted(bytes32(token_id)) onlyCoreNFT {
        tokenApprovals[token_id] = to;
    }

    function setOperatorApprovals(address owner, address operator, bool approved) external onlyCoreNFT {
        operatorApprovals[owner][operator] = approved;
    }

    function setNodeItem(bytes32 node, bytes32 item_key, bytes memory item_value) external onlyExisted(node) onlyOperator {
        nodeDB[node][item_key] = item_value;
    }

    function setOwnerItem(address owner, bytes32 item_key, bytes memory item_value) external onlyOperator {
        ownerDB[owner][item_key] = item_value;
    }

    function deleteNodeItem(bytes32 node, bytes32 item_key) external onlyExisted(node) onlyOperator {
        delete nodeDB[node][item_key];
    }

    function deleteOwnerItem(address owner, bytes32 item_key) external onlyOperator {
        delete ownerDB[owner][item_key];
    }

    function setNodeItemBatch(bytes32 node, bytes32[] memory item_keys, bytes[] memory item_values) external onlyExisted(node) onlyOperator {
        require(item_keys.length == item_values.length, "length error");
        for (uint256 i=0; i < item_keys.length; i++) {
            nodeDB[node][item_keys[i]] = item_values[i];
        }
    }

    function deleteNodeItemBatch(bytes32 node, bytes32[] memory item_keys) external onlyExisted(node) onlyOperator {
        for (uint256 i=0; i < item_keys.length; i++) {
            delete nodeDB[node][item_keys[i]];
        }
    }

    function setOwnerItemBatch(address owner, bytes32[] memory item_keys, bytes[] memory item_values) external onlyOperator {
        require(item_keys.length == item_values.length, "length error");
        for (uint256 i=0; i < item_keys.length; i++) {
            ownerDB[owner][item_keys[i]] = item_values[i];
        }
    }

    function deleteOwnerItemBatch(address owner, bytes32[] memory item_keys) external onlyOperator {
        for (uint256 i=0; i < item_keys.length; i++) {
            delete ownerDB[owner][item_keys[i]];
        }
    }

    function isNodeActive(bytes32 node) public view onlyExisted(node) returns (bool) {
        return nodeRecord[node].expire >= block.timestamp;
    }

    function isNodeExisted(bytes32 node) public view returns (bool) {
        return nodeRecord[node].expire > 0;
    }

    function getOwnerItem(address owner, bytes32 item_key) external view returns (bytes memory) {
        return ownerDB[owner][item_key];
    }

    function getOwnerItemLength(address owner, bytes32 item_key) external view returns (uint256) {
        return ownerDB[owner][item_key].length;
    }

    function getNodeItem(bytes32 node, bytes32 item_key) external onlyExisted(node) view returns (bytes memory) {
        return nodeDB[node][item_key];
    }

    function getNodeOwnerItem(bytes32 node, bytes32 item_key) external onlyExisted(node) view returns (bytes memory) {
        return ownerDB[nodeRecord[node].owner][item_key];
    }

    function getNodeItemLength(bytes32 node, bytes32 item_key) external onlyExisted(node) view returns (uint256) {
        return nodeDB[node][item_key].length;
    }

    function getNodeOwnerItemLength(bytes32 node, bytes32 item_key) external onlyExisted(node) view returns (uint256) {
        return ownerDB[nodeRecord[node].owner][item_key].length;
    }

    function getNodeRecord(bytes32 node) external view returns (Node memory) {
        return (nodeRecord[node]);
    }

    function coreMeta() external view returns (address, address, address, address, address, address) {
        return (coreDAO, address(coreDB), coreRegistrar, coreResolver, coreNFT, coreSW);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "./Common/APP.sol";

interface IMetadata {
    function getNftMetadataURI(bytes32 node) external view returns (string memory);
}

contract CoreNFT is IERC721Metadata, APP {

    string public name;
    string public symbol;
    string public baseURI;
    bool public personalURI;

    // mapping(uint256 => address) private _tokenApprovals; // Mapping from token ID to approved address
    // mapping(address => mapping(address => bool)) private _operatorApprovals;  // Mapping from owner to operator approvals

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

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

    constructor(address core_db, string memory nft_name, string memory nft_symbol, string memory base_uri) {
        initApp(core_db);
        name = nft_name;
        symbol = nft_symbol;
        baseURI = base_uri;
    }

    function setName(string calldata new_name) public onlyCoreDAO {
        name = new_name;
    }

    function setSymbol(string calldata new_symbol) public onlyCoreDAO {
        symbol = new_symbol;
    }

    function setBaseURI(string memory base_uri) public onlyOperator {
        baseURI = base_uri;
    }

    function setPersonalURI(bool personal_uri) public onlyOperator {
        personalURI = personal_uri;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        string memory uri = IMetadata(coreDB.coreResolver()).getNftMetadataURI(bytes32(tokenId));
        if (personalURI && bytes(uri).length > 0) {
            return uri;
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, toString(tokenId))) : "";
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = coreDB.getNodeRecord(bytes32(tokenId)).owner;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return coreDB.balanceOf(owner);
    }

    function totalSupply() public view returns (uint256) {
        return coreDB.totalSupply();
    }

    function getApproved(uint256 tokenId) public view  returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return coreDB.tokenApprovals(tokenId); // _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view  returns (bool) {
        return coreDB.operatorApprovals(owner, operator); // _operatorApprovals[owner][operator];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        coreDB.setTokenApprovals(tokenId, to); // _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        require(owner != operator, "ERC721: approve to caller");
        coreDB.setOperatorApprovals(owner, operator, approved); // _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        bytes32 node = bytes32(tokenId);

        address core_registrar = coreDB.coreRegistrar();
        if (_msgSender() != core_registrar) {
            require(coreDB.isNodeActive(node), "The node is not active, only core registrar can transfer it");
        }

        _approve(address(0), tokenId); // Clear approvals from the previous owner

        coreDB.transferNodeOwner(node, to);
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function reclaimNFT(address from, address to, uint256 tokenId, bytes memory _data) external {
        require(_msgSender() == coreDB.coreRegistrar(), "ERC721: caller is not Core UI");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return coreDB.isNodeExisted(bytes32(tokenId));
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function beforeMint(address to, uint256 tokenId) external view onlyCoreRegistrar {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already existed");
    }

    function afterMint(address to, uint256 tokenId, bytes memory _data) external onlyCoreRegistrar {
        _approve(address(0), tokenId); // Clear approvals from the previous owner
        emit Transfer(address(0), to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: mint to non ERC721Receiver implementer");
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: burn caller is not owner nor approved");
        address owner = ownerOf(tokenId);
        _approve(address(0), tokenId); // Clear approvals
        coreDB.clearNode(bytes32(tokenId));
        emit Transfer(owner, address(0), tokenId);
    }


    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (isContract(to)) {
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

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IERC165).interfaceId;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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