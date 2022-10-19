// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Common/Meta.sol";

contract AssetsOfDID is Meta {

    mapping(address => bool) public NFT1155;
    mapping(address => bool) public NFT721;
    mapping(address => bool) public FT20;
    address[] public assets; // TODO it is not safe, because of checkAssets becomes longer and longer
    mapping(address => uint256) public indexer;

    constructor(address _db) {
        initApp(_db);
    }

    function setAsset(address asset, uint8 asset_type) public onlyOperator {
        require(asset.code.length > 0, "Asset should be a contract");
        if (asset_type == 0) {
            FT20[asset] = true;
        } else if (asset_type == 1) {
            NFT721[asset] = true;
        } else if (asset_type == 2) {
            NFT1155[asset] = true;
        } else {
            FT20[asset] = false;
            NFT721[asset] = false;
            NFT1155[asset] = false;
            // delete assets[i], move the last one to assets[i]
            uint256 i = indexer[asset];
            if (i > 0) {
                indexer[asset] = 0;
                address last = assets[assets.length - 1];
                assets.pop();
                if (i < assets.length) {
                    assets[i - 1] = last;
                    indexer[last] = i;
                }
            }
            return;
        }
        assets.push(asset);
        indexer[asset] = assets.length;
    }

    // TODO check FT & NFT of a DID-Node, if amount > 0, return false
    function checkAssets(bytes32 node) public view returns (bool) {
        return true;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IMetaDB.sol";

interface ITokenReceiver {
    function receiveFT(address token, address sender, uint256 amount) external;
    function receiveGas(address token, bytes32 sender, uint256 amount) external;
}

abstract contract Meta {

    IMetaDB public metaDB;

    mapping(address => bool) public operators;
    address[] public historyOperators;

    modifier onlyMetaDAO {
        require(msg.sender == metaDB.metaDAO(), "Caller is not the MetaDAO");
        _;
    }

    modifier onlyOperator {
        require(operators[msg.sender] , "Caller is not an operator");
        _;
    }

    modifier onlyMetaNFT {
        require(msg.sender == metaDB.metaNFT(), "Caller is not the MetaNFT");
        _;
    }

    modifier onlyMetaRegistrar {
        require(msg.sender == metaDB.metaRegistrar(), "Caller is not the MetaRegistrar");
        _;
    }

    function initApp(address meta_db) internal {
        metaDB = IMetaDB(meta_db);
    }

    function setMetaDB(address meta_db) external onlyMetaDAO {
        metaDB = IMetaDB(meta_db);
    }

    function setOperator(address addr, bool flag) external onlyMetaDAO {
        operators[addr] = flag;
        if (flag) {
            historyOperators.push(addr);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IMetaDB {

    struct Node {
        bytes32 parent;
        address owner;
        uint64 expire;
        uint64 ttl;
        uint64 transfer;
        string name;
    }

    // function operators(address addr) external view returns (bool);
    function metaDAO() external view returns (address);
    function metaRegistrar() external view returns (address);
    function metaNFT() external view returns (address);
    // function metaDB() external view returns (address);
    function metaResolver() external view returns (address);
    function metaMeta() external view returns (address, address, address, address, address, address);
    function metaURI() external view returns (string memory);
    function metaNameFilter() external view returns (address);

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

    function setReverse(address owner, bytes32 node) external;
    function setNodeExpire(bytes32 node, uint64 expire) external;
    function setNodeTTL(bytes32 node, uint64 ttl) external;
    function emitNodeInfo(bytes32 node) external;

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

import "./Common/Meta.sol";
import "./Common/KeyEnum.sol";

interface IMint {
    function mint(bytes32 node, address recommender) external;
}

interface IRegistrar {
    function activateSubnode(
        bytes32 parent,
        address owner,
        uint64 expire,
        uint64 ttl,
        string memory name,
        bytes memory _data
    ) external returns (bytes32);
}

contract ShellRegistrar is KeyEnum, Meta {

    uint64 public default_ttl = 0;
    uint256 public min_cost = 0.02 ether;
    uint256 public base_cost = 0.1 ether;
    address public field_token;
    address public ledger;
    bytes32 public top_level_node;

    constructor(address _token, address _ledger, address _db, bytes32 _node) {
        initApp(_db);
        top_level_node = _node;
        field_token = _token;
        ledger = _ledger;
    }

    function setCost(uint256 min , uint256 base) external onlyOperator {
        min_cost = min;
        base_cost = base;
    }

    function setFieldToken(address addr) external onlyOperator {
        field_token = addr;
    }

    function setLedger(address addr) external onlyOperator {
        ledger = addr;
    }

    // 1, 1000 ETH, 2, 100 ETH, 3, 10 ETH, 4, 1 ETH, 5, 0.1 ETH, 6, 0.02 ETH...
    function getCost(string memory name) public view returns (uint256 cost) {
        bytes memory name_bytes = bytes(name);
        uint256 len = name_bytes.length;
        if (len >= 6) {
            cost = min_cost;
        } else {
            cost = (10**(5-len)) * base_cost;
        }

        return cost;
    }

    function register(
        address recommender,
        address owner,
        string memory name
    ) external payable returns (bytes32) {
        require(recommender != owner, "Recommender can not be owner");
        uint256 cost = getCost(name);
        require(msg.value >= cost, "Value is not enough");

        uint64 expire = metaDB.getNodeRecord(top_level_node).expire;
        bytes32 node = IRegistrar(metaDB.metaRegistrar()).activateSubnode(top_level_node, owner, expire, 0, name, "");
        IMint(field_token).mint(node, recommender);

        if (msg.value > cost) {
            sendValue(payable(msg.sender), msg.value - cost);
        }
        sendValue(payable(ledger), cost);

        return node;
    }

    function sendValue(address payable recipient, uint256 amount) private {
        require(address(this).balance >= amount, "Insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Unable to send value, recipient may have reverted");
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract KeyEnum {

    uint256 constant internal KEY_META = 0;
    uint256 constant internal KEY_REGISTRAR = 1;
    uint256 constant internal KEY_RESOLVER = 2;

    uint256 constant internal KEY_NFT_METADATA = 3;
    uint256 constant internal KEY_NFT_METADATA_URI = 4;
    uint256 constant internal KEY_NFT_OBJECT = 5; // NFT Image, Audio, Video...
    uint256 constant internal KEY_NFT_OBJECT_URI = 6;
    uint256 constant internal KEY_ALIAS = 7;

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
    uint256 constant internal KEY_ADDRESS_MATIC = (ETH_LIKE_ADDRESS_BEGIN + 2);
    uint256 constant internal KEY_ADDRESS_YAE = (ETH_LIKE_ADDRESS_BEGIN + 3);
    uint256 internal ETH_LIKE_ADDRESS_END = KEY_ADDRESS_YAE;
    uint256 internal KEY_ADDRESS_MAIN = KEY_ADDRESS_ETH;


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./KeyEnum.sol";
import "./Meta.sol";

abstract contract KVS is KeyEnum, Meta { // KVS: Key Value Storage

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
        return metaDB.getNodeRecord(node).owner;
    }

    function getRegistrar(bytes32 node) public view returns (address) {
        return abiBytesToAddressWithoutTimestamp(metaDB.getNodeItem(node, bytes32(KEY_REGISTRAR)));
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

import "./Common/KVS.sol";
import "./Common/Meta.sol";
import "./Common/IMetaDB.sol";

pragma solidity ^0.8.9;

contract MetaResolver is KVS {

    // name: "alice";
    // name_hash: keccak256(abi.encodePacked("alice"));
    // full_name: "eth", "alice.eth", "foobar.alice.eth";
    // node: keccak256(abi.encodePacked(parent, name_hash));
    // parent: parent node;

    constructor(address _db) {
        initApp(_db);
    }

    // full_name[www.alice.eth] => name_array[www,alice,eth]
    function resolve(string[] memory name_array) external view returns (bytes32 node, address owner, uint64 expire, uint64 ttl, uint64 transfer) {
        for (uint256 i = name_array.length; i > 0; i--) {
            node = encodeNameToNode(node, name_array[i-1]);
        }
        IMetaDB.Node memory n = metaDB.getNodeRecord(node);
        return (node, n.owner, n.expire, n.ttl, n.transfer);
    }

    function abiBytesToAddressWithTimestamp(bytes memory bys) public pure returns(address payable addr, uint64 time_stamp) {
        uint256 num = abiBytesToUint256(bys);
        addr = payable(address(uint160(num >> 96)));
        time_stamp = uint64(num & type(uint96).max);
        return (addr, time_stamp);
    }

    function getNodeNameFull(bytes32 node) public view returns (string memory) {
        string memory full_name = metaDB.getNodeRecord(node).name;
        bytes32 parent = metaDB.getNodeRecord(node).parent;
        bytes32 root_node = bytes32(0);
        while (parent != root_node) {
            IMetaDB.Node memory parent_node = metaDB.getNodeRecord(parent);
            full_name = string(abi.encodePacked(full_name, ".", parent_node.name));
            parent = parent_node.parent;
        }
        return full_name;
    }

    function getReverse(address owner) public view returns (bytes32, string memory) {
        bytes32 node = metaDB.reverseRecord(owner);
        require(getNodeOwner(node) == owner, "owner doesn't match node");
        string memory name = getNodeNameFull(node);
        return (node, name);
    }

    function getResolver(bytes32 node) public view returns (address) {
        return abiBytesToAddressWithoutTimestamp(metaDB.getNodeItem(node, bytes32(KEY_RESOLVER)));
    }

    function getCooperators(bytes32 node) external view returns (address, address, address) {
        return (getNodeOwner(node), getRegistrar(node), getResolver(node));
    }

    function getNodeName(bytes32 node) public view returns (string memory) {
        return metaDB.getNodeRecord(node).name;
    }

    function getTTL(bytes32 node) external view returns (uint64) {
        return metaDB.getNodeRecord(node).ttl;
    }

    function getTwitter(bytes32 node) external view returns (string memory) {
        address owner = getNodeOwner(node);
        return abiBytesToString(metaDB.getOwnerItem(owner, encodeItemKey(node, KEY_TWITTER)));
    }

    function getInstagram(bytes32 node) external view returns (string memory) {
        address owner = getNodeOwner(node);
        return abiBytesToString(metaDB.getOwnerItem(owner, encodeItemKey(node, KEY_INSTAGRAM)));
    }

    function getContribution(address owner) external view returns (uint256) {
        return abiBytesToUint256(metaDB.getOwnerItem(owner, encodeItemKey(bytes32(0), KEY_CONTRIBUTION)));
    }

    function getNftMetadataURI(bytes32 node) external view returns (string memory) {
        return abiBytesToString(metaDB.getNodeItem(node, bytes32(KEY_NFT_METADATA_URI)));
    }

    // KEY_RESOLVER KEY_REGISTRAR KEY_ADDRESS_MAIN...
    function getAddressItem(bytes32 node, uint256 item_key) external view returns (address ret) {
        if (item_key == KEY_ADDRESS_MAIN) {
            ret = getNodeOwner(node);
        } else {
            ret = abiBytesToAddressWithoutTimestamp(metaDB.getNodeOwnerItem(node, encodeItemKey(node, item_key)));
        }
    }

    function getAddressItemWithTimestamp(bytes32 node, uint256 item_key) external view returns (address addr, uint64 time) {
        if (item_key == KEY_ADDRESS_MAIN) {
            IMetaDB.Node memory n = metaDB.getNodeRecord(node);
            (addr, time) = (n.owner, n.transfer);
        } else {
            (addr, time) = abiBytesToAddressWithTimestamp(metaDB.getNodeOwnerItem(node, encodeItemKey(node, item_key)));
        }
    }

    function getAddressItemList(bytes32 node, uint256 begin, uint256 end) external view returns (address[] memory) {
        require(end >= begin, "arguments error");
        address[] memory addr_array = new address[](end + 1 - begin);
        for (uint256 item_key = begin; item_key <= end; item_key++) {
            if (item_key == KEY_ADDRESS_MAIN) {
                addr_array[item_key - begin] = getNodeOwner(node);
            } else {
                addr_array[item_key - begin] = abiBytesToAddressWithoutTimestamp(metaDB.getNodeOwnerItem(node, encodeItemKey(node, item_key)));
            }
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
                IMetaDB.Node memory n = metaDB.getNodeRecord(node);
                (addr_array[i], time_array[i]) = (n.owner, n.transfer);
            } else {
                (addr_array[i], time_array[i]) = abiBytesToAddressWithTimestamp(metaDB.getNodeOwnerItem(node, encodeItemKey(node, item_key)));
            }
        }
        return (addr_array, time_array);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Common/KVS.sol";
import "./Common/IMetaDB.sol";

interface ICoreNFT {
    function mint(bytes32 parent, bytes32 node, address owner, uint64 expire, uint64 ttl, string memory _name, bytes memory _data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
}

interface INameFilter {
    function validName(string memory name) external view returns (bool);
}

contract MetaRegistrar is KVS {

    event NodeItemUpdated(bytes32 indexed node, address indexed owner, bytes32 indexed key, bytes value);
    event NodeOwnerItemUpdated(bytes32 indexed node, address indexed owner, bytes32 indexed key, bytes value);

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

    constructor(address _db) {
        initApp(_db);
        openForAll = true;
    }

    // Require msg.sender is a cooperator (Owner, Registrar_Contract)
    modifier onlyCooperatorOfActiveNode(bytes32 node) {
        require (
            msg.sender == getNodeOwner(node) ||
            msg.sender == getRegistrar(node),
            "caller is not a team member"
        );
        require (metaDB.isNodeActive(node), "invalid node");
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

    function setTTL(bytes32 node, uint64 ttl) external onlyCooperatorOfActiveNode(node) {
        metaDB.setNodeTTL(node, ttl);
    }

    function setNftMetadataURI(bytes32 node, string memory uri) external onlyCooperatorOfActiveNode(node) {
        _setNodeItem(node, bytes32(KEY_NFT_METADATA_URI), abi.encode(uri));
    }

    function _setNodeItem(bytes32 node, bytes32 item_key, bytes memory item_value) private {
        metaDB.setNodeItem(node, item_key, item_value);
        emit NodeItemUpdated(node, getNodeOwner(node), item_key, item_value);
    }

    function _setOwnerItem(bytes32 node, uint256 item_key, bytes memory item_value) private {
        address owner = getNodeOwner(node);
        metaDB.setOwnerItem(owner, encodeItemKey(node, item_key), item_value);
        emit NodeOwnerItemUpdated(node, owner, bytes32(item_key), item_value);
    }

    function _setOwnerAddressItem(bytes32 node, uint256 item_key, address addr) private {
        bytes32 encoded_item_key = encodeItemKey(node, item_key);
        bytes memory encoded_item_value = "";
        address owner = getNodeOwner(node);
        if (addr == address(0)) {
            metaDB.deleteOwnerItem(owner, encoded_item_key);
        } else {
            // Address with Timestamp: |Address(160bit)|Null(32bit)|Timestamp(64bit)|
            encoded_item_value = abi.encode((uint256(uint160(addr)) << 96) + uint64(block.timestamp));
            metaDB.setOwnerItem(owner, encoded_item_key, encoded_item_value);
        }
        emit NodeOwnerItemUpdated(node, owner, bytes32(item_key), encoded_item_value);
    }

    function setRegistrar(bytes32 node, address registrar) external onlyCooperatorOfActiveNode(node) {
        if (metaDB.getNodeRecord(node).parent == bytes32(0) && node != bytes32(0)) { // Only record Top Level Domain Registrar
            delete topLevelRegistrars[getRegistrar(node)];
            topLevelRegistrars[registrar] = true;
        }
        _setNodeItem(node, bytes32(KEY_REGISTRAR), abi.encode((uint256(uint160(registrar)) << 96) + uint64(block.timestamp)));
    }

    function setResolver(bytes32 node, address resolver) external onlyCooperatorOfActiveNode(node) {
        _setNodeItem(node, bytes32(KEY_RESOLVER), abi.encode((uint256(uint160(resolver)) << 96) + uint64(block.timestamp)));
    }

    function setReverse(bytes32 node) external { // node == bytes(0) means delete reverse record
        // require(getNodeOwner(node) == msg.sender, "node owner doesn't match");
        metaDB.setReverse(msg.sender, node);
    }

    function setEthLikeAddressList(
        bytes32 node,
        uint256[] memory item_keys,
        address[] memory eth_like_addrs
    ) external onlyCooperatorOfActiveNode(node) {
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

    function activateSubnode(
        bytes32 parent,
        address owner,
        uint64 expire,
        uint64 ttl,
        string memory name,
        bytes memory _data
    ) external nonReentrant() onlyCooperatorOfActiveNode(parent) returns (bytes32) {

        require(openForAll || topLevelRegistrars[msg.sender], "caller is not a top level registrar");

        address filter = metaDB.metaNameFilter();
        if (filter != address(0)) {
            require(INameFilter(filter).validName(name), "name is sensitive or not checked");
        }

        bytes32 node = encodeNameToNode(parent, name);
        address nft = metaDB.metaNFT();

        if (!metaDB.isNodeExisted(node)) {
            ICoreNFT(nft).mint(parent, node, owner, expire, ttl, name, _data);
        } else if (!metaDB.isNodeActive(node)) {
            metaDB.setNodeExpire(node, expire);
            metaDB.setNodeTTL(node, ttl);
            ICoreNFT(nft).safeTransferFrom(getNodeOwner(node), owner, uint256(node), _data);
        } else {
            revert("node is active");
        }

        return node;

    }

    function renewExpire(bytes32 node, uint64 expire) external onlyTopLevelRegistrar {
        bytes32 parent = metaDB.getNodeRecord(node).parent;
        require(msg.sender == getRegistrar(parent), "caller is not the registrar of the parent node");
        metaDB.setNodeExpire(node, expire);
        metaDB.emitNodeInfo(node);
    }

}

// NFT transfer require DID-Node not expired for normal case to avoid some frauds;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Common/IMetaDB.sol";
import "./Common/Meta.sol";

contract MetaDB is IMetaDB, Meta {

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

    string public metaURI;

    address public metaDAO ;
    address public metaRegistrar;
    address public metaNFT;
    address public metaResolver;
    address public metaNameFilter;

    event ReverseRecordSet(address indexed main_address, bytes32 indexed node); // node == bytes(0) means delete reverse record
    event NodeInfoUpdated(bytes32 indexed node, bytes32 parent, address owner, uint64 expire, uint64 ttl, uint64 transfer, string name);
    // event NodeInfoUpdated(bytes32 indexed node, Node info); // Java-web3j can not decode struct in the event

    constructor(address dao) {
        metaDAO = dao;
        metaDB = this;

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

    function setMetaURI(string memory uri) external onlyMetaDAO {
        metaURI = uri;
    }

    function setMetaDAO(address dao) external onlyMetaDAO {
        metaDAO = dao;
    }

    function setMetaRegistrar(address registrar) public onlyMetaDAO {
        operators[metaRegistrar] = false;
        operators[registrar] = true;
        metaRegistrar = registrar;
    }

    function setMetaNFT(address nft) public onlyMetaDAO {
        operators[metaNFT] = false;
        operators[nft] = true;
        metaNFT = nft;
    }

    function setMetaFilter(address filter) external onlyMetaDAO {
        metaNameFilter = filter;
    }

    function setMetaResolver(address resolver) external onlyMetaDAO {
        metaResolver = resolver;
    }

    function _emitNodeInfo(bytes32 node) private {
        Node memory n = nodeRecord[node];
        emit NodeInfoUpdated(node, n.parent, n.owner, n.expire, n.ttl, n.transfer, n.name);
    }

    function emitNodeInfo(bytes32 node) external onlyOperator {
        _emitNodeInfo(node);
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
    function createNode(
        bytes32 parent,
        bytes32 node,
        address owner,
        uint64 expire,
        uint64 ttl,
        string memory name
    ) external onlyMetaNFT {
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

        _emitNodeInfo(node);
    }

    // Burn NFT, only for expired nodes
    function clearNode(bytes32 node) external onlyMetaNFT {
        require(!isNodeActive(node), "node is active");
        address current_owner = nodeRecord[node].owner;
        balanceOf[current_owner] -= 1;
        totalSupply -= 1;
        delete nodeRecord[node];

        _deleteReverse(current_owner, node);

        _emitNodeInfo(node);
    }

    // 1) Transfer NFT, 2)Reclaim node;  // No need of onlyExisted(node), require isNodeActive instead
    function transferNodeOwner(bytes32 node, address owner) external onlyMetaNFT {
        require(isNodeActive(node) && owner != address(0) , "invalid owner");
        address current_owner = nodeRecord[node].owner;

        balanceOf[current_owner] -= 1;
        balanceOf[owner] += 1;
        nodeRecord[node].owner = owner;
        nodeRecord[node].transfer = uint64(block.timestamp);

        _deleteReverse(current_owner, node);
        _setReverse(owner, node);

        _emitNodeInfo(node);
    }

    function setTokenApprovals(uint256 token_id, address to) external onlyExisted(bytes32(token_id)) onlyMetaNFT {
        tokenApprovals[token_id] = to;
    }

    function setOperatorApprovals(address owner, address operator, bool approved) external onlyMetaNFT {
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

    function metaMeta() external view returns (address, address, address, address, address, address) {
        return (metaDAO, address(metaDB), metaRegistrar, metaResolver, metaNFT, metaNameFilter);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "./Common/Meta.sol";

interface IMetadata {
    function getNftMetadataURI(bytes32 node) external view returns (string memory);
}

interface IFieldToken {
    function stakeBalance(bytes32 node) external view returns (uint256);
}

interface IAssetsOfDID {
    function checkAssets(bytes32 node) external view returns (bool);
}

contract MetaNFT is IERC721Metadata, Meta {

    string public name;
    string public symbol;
    string public baseURI;
    bool public personalURI;
    address public fieldToken;
    address public assetsOfDID;

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

    constructor(address _db, string memory _name, string memory _symbol, string memory _uri) {
        initApp(_db);
        name = _name;
        symbol = _symbol;
        baseURI = _uri;
    }

    function setName(string calldata new_name) public onlyMetaDAO {
        name = new_name;
    }

    function setSymbol(string calldata new_symbol) public onlyMetaDAO {
        symbol = new_symbol;
    }

    function setBaseURI(string memory base_uri) public onlyOperator {
        baseURI = base_uri;
    }

    function setPersonalURI(bool personal_uri) public onlyOperator {
        personalURI = personal_uri;
    }

    function setFiledToken(address addr) external onlyOperator {
        fieldToken = addr;
    }

    function setAssetsOfDID(address addr) external onlyOperator {
        assetsOfDID = addr;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        string memory uri = IMetadata(metaDB.metaResolver()).getNftMetadataURI(bytes32(tokenId));
        if (personalURI && bytes(uri).length > 0) {
            return uri;
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, toString(tokenId))) : "";
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = metaDB.getNodeRecord(bytes32(tokenId)).owner;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return metaDB.balanceOf(owner);
    }

    function totalSupply() public view returns (uint256) {
        return metaDB.totalSupply();
    }

    function getApproved(uint256 tokenId) public view  returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return metaDB.tokenApprovals(tokenId); // _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view  returns (bool) {
        return metaDB.operatorApprovals(owner, operator); // _operatorApprovals[owner][operator];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (
            spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender) ||
            _msgSender() == metaDB.metaRegistrar()
        );
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
        metaDB.setTokenApprovals(tokenId, to); // _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        require(owner != operator, "ERC721: approve to caller");
        metaDB.setOperatorApprovals(owner, operator, approved); // _operatorApprovals[owner][operator] = approved;
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
        require(fieldToken == address(0) || IFieldToken(fieldToken).stakeBalance(node) == 0, "ERC721: DID has filed token");
        require(assetsOfDID == address(0) || IAssetsOfDID(assetsOfDID).checkAssets(node), "ERC721: DID has assets");

        _approve(address(0), tokenId); // Clear approvals from the previous owner

        metaDB.transferNodeOwner(node, to);
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return metaDB.isNodeExisted(bytes32(tokenId));
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function mint(
        bytes32 parent,
        bytes32 node,
        address owner,
        uint64 expire,
        uint64 ttl,
        string memory _name,
        bytes memory _data
    ) external onlyMetaRegistrar {
        metaDB.createNode(parent, node, owner, expire, ttl, _name);
        _approve(address(0), uint256(node)); // Clear approvals from the previous owner
        emit Transfer(address(0), owner, uint256(node));
        require(_checkOnERC721Received(address(0), owner, uint256(node), _data), "ERC721: mint to non ERC721Receiver implementer");
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: burn caller is not owner nor approved");
        address owner = ownerOf(tokenId);
        _approve(address(0), tokenId); // Clear approvals
        metaDB.clearNode(bytes32(tokenId));
        emit Transfer(owner, address(0), tokenId);
    }


    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.code.length > 0) { // isContract(to)
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
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

import "./Common/Meta.sol";

contract MetaFilter is Meta {
    // [email protected], alice_163, alice#163, -alice, alice-, are not supported;
    // alice-163, alice-1-6-3 are supported.

    mapping(bytes32 => bool) public targetHashTable;
    uint8 public minLength = 1;
    uint8 public maxLength = 255;

    constructor(address _db) {
        initApp(_db);
    }

    function setNameLength(uint8 min_len, uint8 max_len) external onlyOperator {
        require(max_len >= min_len, "arguments error");
        minLength = min_len;
        maxLength = max_len;
    }

    function setFilteredNameHashList(bytes32[] memory hash_list, bool flag) external onlyOperator {
        for (uint256 i = 0; i < hash_list.length; i++) {
            targetHashTable[hash_list[i]] = flag;
        }
    }

    function filteredName(string memory name) public view returns (bool) {
        return targetHashTable[keccak256(abi.encodePacked(name))];
    }

    function digitalOrAlphabet(uint8 character) internal pure returns (bool) {
        return (character >= 0x61 && character <= 0x7a) || (character >= 0x30 && character <= 0x39) || (character == 0x2d);
        // [a ~ z, 0 ~ 9, -]
    }

    function checkedName(string memory name) public view returns (bool) {
        bytes memory name_bytes = bytes(name);
        uint256 len = name_bytes.length;

        if (len < minLength || len > maxLength || uint8(name_bytes[0]) == 0x2d || uint8(name_bytes[len-1]) == 0x2d) {
            return false;
        }

        for (uint256 i=0; i < len ; i++) {
            if (!digitalOrAlphabet(uint8(name_bytes[i]))) {
                return false;
            }
        }

        return true;
    }

    function validName(string memory name) external view returns (bool) {
        return !filteredName(name) && checkedName(name);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Common/Meta.sol";
import "./Common/LibSignature.sol";

contract Ledger is Meta {

    using LibSignature for bytes32;

    mapping(uint64 => uint256) public income;
    mapping(bytes32 => uint256) public divident;
    uint256 interval = 1 hours;

    event UserDivident(bytes32 indexed node, address indexed owner, uint256 amount, uint256 accumulated);
    event PlatformIncome(address indexed item, uint256 income,  uint256 accumulated);

    constructor(address _db) {
        initApp(_db);
    }

    function today() internal view returns (uint64) {
        return uint64(block.timestamp / (24 hours));
    }

    // Receive Ether and generate a log event
    // fallback () payable external {
    //     emit ReceivedEther(msg.sender, msg.value);
    // }

    // Receive Ether and generate a log event
    receive() external payable {
        uint64 date = today();
        income[date] += msg.value;
        emit PlatformIncome(msg.sender, msg.value, income[date]);
    }

    function sendValue(address payable recipient, uint256 amount) private {
        require(address(this).balance >= amount, "Insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Unable to send value, recipient may have reverted");
    }

    function withdraw(bytes32 node, uint256 amount, bytes memory signature) external {
        verify_signature(node, amount, signature);
        address owner = metaDB.getNodeRecord(node).owner;
        // require(msg.sender == owner, "Msg.sender is not the node owner");
        divident[node] += amount;
        sendValue(payable(owner), amount);
        emit UserDivident(node, owner, amount, divident[node]);
    }

    function verify_signature(bytes32 node, uint256 amount, bytes memory signature) public view {
        bytes memory preimage = abi.encode(block.timestamp / interval, node, amount);
        verify(preimage, signature);
    }

    function verify(bytes memory preimage, bytes memory signature) private view {
        bytes32 hash = keccak256(preimage);
        address signer = hash.recover(signature);
        require(operators[signer], "Invalid signer");
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library LibSignature {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
    {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );

        // If the signature is valid (and not malleable), return the signer address
        // v > 30 is a special case, we need to adjust hash with "\x19Ethereum Signed Message:\n32"
        // and v = v - 4
        address signer;
        if (v > 30) {
            require(
                v - 4 == 27 || v - 4 == 28,
                "ECDSA: invalid signature 'v' value"
            );
            signer = ecrecover(toEthSignedMessageHash(hash), v - 4, r, s);
        } else {
            require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");
            signer = ecrecover(hash, v, r, s);
        }

        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
        keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Common/Meta.sol";

interface IFieldToken {
    function gasBalance(bytes32 node) external view returns (uint256);
    function today() external view returns (uint64);
    function balanceOf(address account) external view returns (uint256);
    function nodeToAddress(bytes32 node) external view returns (address, address);
}

contract GasToken is Meta {

    mapping(bytes32 => mapping(uint64 => uint256)) public inGas;
    mapping(bytes32 => mapping(uint64 => uint256)) public outGas;

    IFieldToken public fieldToken;
    bool public transferOn;

    event Transfer(bytes32 indexed from, bytes32 indexed to, uint256 value);

    constructor(address filed_token, address _db) {
        initApp(_db);
        fieldToken = IFieldToken(filed_token);
    }

    function switchTransfer() public onlyOperator {
        transferOn = !transferOn;
    }

    function batchQuery(bytes32 node) public view returns (uint256 locked, uint256 staked, uint256 free, uint256 gas) {
        (address left, address right) = fieldToken.nodeToAddress(node);
        locked = fieldToken.balanceOf(right);
        staked = fieldToken.balanceOf(left);
        free = fieldToken.balanceOf(metaDB.getNodeRecord(node).owner);
        if (transferOn) {
            gas = balanceOf(node);
        } else {
            gas = fieldToken.gasBalance(node);
        }
        // return (locked, staked, free, gas);
    }

    function today() internal view returns (uint64) {
        return uint64(block.timestamp / (24 hours));
    }

    function balanceOf(bytes32 node) public view returns (uint256) {
        return fieldToken.gasBalance(node) + inGas[node][today()] - outGas[node][today()];
    }

    function transferFrom(bytes32 from, bytes32 to, uint256 amount) external returns (bool) {
        require(transferOn, "Transfer off");
        require(msg.sender == metaDB.getNodeRecord(from).owner, "Msg.sender is not the node owner");
        require(metaDB.isNodeActive(to), "Destination node is not active");
        require(balanceOf(from) >= amount, "Balance is not enough");

        outGas[from][today()] += amount;
        inGas[to][today()] += amount;

        emit Transfer(from, to, amount);

        address owner = metaDB.getNodeRecord(to).owner;
        if(owner.code.length > 0) {
            ITokenReceiver(owner).receiveGas(address(this), from, amount);
        }

        return true;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./Common/Meta.sol";

contract FieldToken is IERC20, IERC20Metadata, Meta {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public receivedOf;
    mapping(bytes32 => uint64) public applyTimestamp;
    mapping(uint64 => uint256) public everydayOfInfra;

    address public community = address(uint160(uint256(
            keccak256(abi.encodePacked(bytes32(0), keccak256(abi.encodePacked("the-community"))))
        )));

    address public infrastructure = address(uint160(uint256(
            keccak256(abi.encodePacked(bytes32(0), keccak256(abi.encodePacked("the-infrastructure"))))
        )));

    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    string public name;
    string public symbol;

    uint64 public constant interval = 24 hours;

    constructor(string memory _name, string memory _symbol, address _db) {
        initApp(_db);
        name = _name;
        symbol = _symbol;
    }

    function gasBalance(bytes32 node) public view returns (uint256) {
        (address left, address right) = nodeToAddress(node);
        return balanceOf[left] + balanceOf[right];
    }

    function stakeBalance(bytes32 node) public view returns (uint256) {
        address left = nodeLeftToAddress(node);
        return balanceOf[left];
    }

    function lockedBalance(bytes32 node) public view returns (uint256) {
        address right = nodeRightToAddress(node);
        return balanceOf[right];
    }

    function today() internal view returns (uint64) {
        return uint64(block.timestamp / (24 hours));
    }

    // Left Part staked for a duration, Right Part locked forever.
    function nodeToAddress(bytes32 node) public view returns (address, address) {
        return (nodeLeftToAddress(node), nodeRightToAddress(node));
    }

    function nodeRightToAddress(bytes32 node) internal view returns (address) {
        require(metaDB.isNodeActive(node), "ERC20: invalid node");
        address account = address(uint160(uint256(node)));
        return account;
    }

    function nodeLeftToAddress(bytes32 node) internal view returns (address) {
        require(metaDB.isNodeActive(node), "ERC20: invalid node");
        address account = address(uint160(uint256(node) >> 96));
        return account;
    }

    function reclaimApply(bytes32 node) external {
        require(msg.sender == metaDB.getNodeRecord(node).owner, "ERC20: msg.sender is not the node owner ");
        require(balanceOf[nodeLeftToAddress(node)] > 0, "ERC20: zero balanceOf");
        require(applyTimestamp[node] == 0, "ERC20: no need to apply again");

        applyTimestamp[node] = uint64(block.timestamp);
    }

    // When transfer / burn / reclaim did-nft (node), remember to check assets of the node
    // If someone intentionally leave some assets for the node, it still can be burned / reclaimed when expired
    function reclaim(bytes32 node, address to, uint256 amount) external {
        require(msg.sender == metaDB.getNodeRecord(node).owner, "ERC20: msg.sender is not the node owner ");
        require(applyTimestamp[node] + 24 hours >= block.timestamp, "ERC20: no need to apply again");

        applyTimestamp[node] = 0;
        _transfer(nodeLeftToAddress(node), to, amount);
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    // Use transfer to stake
    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = balanceOf[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balanceOf");
        unchecked {
            balanceOf[from] = fromBalance - amount;
        }
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);

        // if(to.code.length > 0 && metaDB.reverseRecord(to) != bytes32(0)) {
        //     ITokenReceiver(to).receiveFT(address(this), from, amount);
        // }
    }

    // require(msg.sender == ShellRegistrar, "ERC20: only ShellRegistrar contract can mint");
    function mint(bytes32 node, address recommender) external onlyOperator {
        address member = nodeRightToAddress(node);
        require(member != address(0), "ERC20: mint to the zero address");
        uint256 amount = 100 ether;
        uint256 triple = 300 ether;

        totalSupply += amount;
        balanceOf[member] += amount;
        balanceOf[infrastructure] += amount;
        everydayOfInfra[today()] = balanceOf[infrastructure];
        if (recommender != address(0)) {
            balanceOf[recommender] += (30 ether);
            triple = 270 ether;
            emit Transfer(address(0), recommender, 30 ether);
        }
        balanceOf[community] += triple;

        emit Transfer(address(0), member, amount);
        emit Transfer(address(0), infrastructure, amount);
        emit Transfer(address(0), community, triple);
    }

    // require(msg.sender == community, "ERC20: only Community contract can unlock");
    function unlockCommunityToken(address to, uint256 amount) external onlyOperator {
        require(to != address(0), "ERC20: unlock to the zero address");
        balanceOf[community] -= amount;
        balanceOf[to] += amount;
        emit Transfer(community, to, amount);

        if(to.code.length > 0 && metaDB.reverseRecord(to) != bytes32(0)) {
            ITokenReceiver(to).receiveFT(address(this), community, amount);
        }
    }

    function burn(uint256 amount) public {
        address account = _msgSender();
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = balanceOf[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balanceOf");
        unchecked {
            balanceOf[account] = accountBalance - amount;
        }
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}