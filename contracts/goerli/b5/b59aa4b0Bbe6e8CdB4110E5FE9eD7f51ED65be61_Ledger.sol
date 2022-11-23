// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IDB {

    struct Node {
        bytes32 parent;
        address owner;
        uint64 expire;
        uint64 ttl;
        uint64 transfer;
        string name;
    }

    function DAO() external view returns (address);
    function editor() external view returns (address);
    function NFT() external view returns (address);
    function resolver() external view returns (address);
    function filter() external view returns (address);

    function balanceOf(address owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function reverseRecord(address main_address) external view returns (bytes32);

    // function nodeRecord(bytes32 node) external view returns (Node memory);
    function getNodeRecord(bytes32 node) external view returns (Node memory);
    function getNodeItem(bytes32 node, bytes32 item_key) external view returns (bytes memory);
    function getNodeOwnerItem(bytes32 node, address owner, bytes32 item_key) external view returns (bytes memory);

    function setReverse(address owner, bytes32 node) external;
    function setNodeTTL(bytes32 node, uint64 ttl, bool emit_event) external;
    function emitNodeInfo(bytes32 node) external;

    function setNodeItem(bytes32 node, bytes32 item_key, bytes memory item_value) external;
    function setNodeOwnerItem(bytes32 node, address owner, bytes32 item_key, bytes memory item_value) external;
    function setNodeItemBatch(bytes32 node, bytes32[] memory item_keys, bytes[] memory item_values) external;
    function setNodeOwnerItemBatch(bytes32 node, address owner, bytes32[] memory item_keys, bytes[] memory item_values) external;

    function isNodeActive(bytes32 node) external view returns (bool);
    function isNodeExisted(bytes32 node) external view returns (bool);

    function transferNodeOwner(bytes32 node, address new_owner) external;
    function clearNode(bytes32 node) external;
    function activateSubnode(bytes32 parent, address owner, uint64 expire, uint64 ttl, string memory name, bytes memory _data) external returns (bytes32);

    function setTokenApprovals(uint256 token_id, address to) external;
    function setOperatorApprovals(address owner, address operator, bool approved) external;

    function tokenApprovals(uint256 token_id) external view returns (address);
    function operatorApprovals(address owner, address operator) external view returns (bool);

}

// SPDX-License-Identifier: MIT

import "./Common/KVS.sol";
import "./Common/Meta.sol";
import "./Common/IDB.sol";

pragma solidity ^0.8.9;

contract Resolver is KVS {

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
        IDB.Node memory n = metaDB.getNodeRecord(node);
        return (node, n.owner, n.expire, n.ttl, n.transfer);
    }

    function abiBytesToAddressTime(bytes memory bys) public pure returns(address payable addr, uint64 time) {
        uint256 num = abiBytesToUint256(bys);
        addr = payable(address(uint160(num >> 96)));
        time = uint64(num & type(uint96).max);
    }

    function getNodeNameFull(bytes32 node) public view returns (string memory) {
        string memory full_name = metaDB.getNodeRecord(node).name;
        bytes32 parent = metaDB.getNodeRecord(node).parent;
        bytes32 root_node = bytes32(0);
        while (parent != root_node) {
            IDB.Node memory parent_node = metaDB.getNodeRecord(parent);
            full_name = string(abi.encodePacked(full_name, ".", parent_node.name));
            parent = parent_node.parent;
        }
        return full_name;
    }

    function getReverse(address owner) public view returns (bytes32, string memory) {
        bytes32 node = metaDB.reverseRecord(owner);
        require(getNodeOwner(node) == owner, "Owner doesn't match node");
        string memory name = getNodeNameFull(node);
        return (node, name);
    }

    function getNodeName(bytes32 node) public view returns (string memory) {
        return metaDB.getNodeRecord(node).name;
    }

    function getTTL(bytes32 node) external view returns (uint64) {
        return metaDB.getNodeRecord(node).ttl;
    }

    function getNftImageURI(bytes32 node) external view returns (string memory) {
        return abiBytesToString(metaDB.getNodeItem(node, bytes32(KEY_NFT_IMAGE_URI)));
    }

    function getNftMetadataURI(bytes32 node) external view returns (string memory) {
        return abiBytesToString(metaDB.getNodeItem(node, bytes32(KEY_NFT_METADATA_URI)));
    }

    function getAddress(bytes32 node, uint256 item_key) external view returns (address ret) {
        if (item_key == KEY_ADDRESS_MAIN) {
            ret = getNodeOwner(node);
        } else {
            ret = abiBytesCutToAddress(metaDB.getNodeOwnerItem(node, address(0), bytes32(item_key)));
        }
    }

    function getAddressTime(bytes32 node, uint256 item_key) external view returns (address addr, uint64 time) {
        if (item_key == KEY_ADDRESS_MAIN) {
            IDB.Node memory n = metaDB.getNodeRecord(node);
            (addr, time) = (n.owner, n.transfer);
        } else {
            (addr, time) = abiBytesToAddressTime(metaDB.getNodeOwnerItem(node, address(0), bytes32(item_key)));
        }
    }

    function getAddressList(bytes32 node, uint256 begin, uint256 end) external view returns (address[] memory) {
        require(end >= begin, "Arguments error");
        address[] memory addr_array = new address[](end + 1 - begin);
        for (uint256 item_key = begin; item_key <= end; item_key++) {
            if (item_key == KEY_ADDRESS_MAIN) {
                addr_array[item_key - begin] = getNodeOwner(node);
            } else {
                addr_array[item_key - begin] = abiBytesCutToAddress(metaDB.getNodeOwnerItem(node, address(0), bytes32(item_key)));
            }
        }
        return addr_array;
    }

    function getAddressTimeList(bytes32 node, uint256 begin, uint256 end) external view returns (address[] memory, uint64[] memory) {
        require(end >= begin, "Arguments error");
        uint256 i = end + 1 - begin;
        address[] memory addr_array = new address[](i);
        uint64[] memory time_array = new uint64[](i);
        for (uint256 item_key = begin; item_key <= end; item_key++) {
            i = item_key - begin;
            if (item_key == KEY_ADDRESS_MAIN) {
                IDB.Node memory n = metaDB.getNodeRecord(node);
                (addr_array[i], time_array[i]) = (n.owner, n.transfer);
            } else {
                (addr_array[i], time_array[i]) = abiBytesToAddressTime(metaDB.getNodeOwnerItem(node, address(0), bytes32(item_key)));
            }
        }
        return (addr_array, time_array);
    }

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

    function encodeNameToNode(bytes32 parent, string memory name) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(parent, keccak256(abi.encodePacked(name))));
    }

    function getNodeOwner(bytes32 node) public view returns (address) {
        return metaDB.getNodeRecord(node).owner;
    }

    function getEditor(bytes32 node) public view returns (address) {
        return abiBytesCutToAddress(metaDB.getNodeItem(node, bytes32(KEY_EDITOR)));
    }

    function abiBytesCutToAddress(bytes memory bys) public pure returns(address payable addr) {
        uint256 num = abiBytesToUint256(bys);
        addr = payable(address(uint160(num >> 96)));
    }

    function setEthLikeAddressEnd(uint256 item_key) external onlyOperator {
        require(item_key > ETH_LIKE_ADDRESS_END && item_key < ETH_LIKE_ADDRESS_END + 10, "Invalid item");
        ETH_LIKE_ADDRESS_END = item_key;
    }

    function setKeyAddressMain(uint256 item_key) external onlyOperator {
        require(item_key >= ETH_LIKE_ADDRESS_BEGIN && item_key <= ETH_LIKE_ADDRESS_END, "Invalid item");
        KEY_ADDRESS_MAIN = item_key;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IDB.sol";

interface ITokenReceiver {
    function receiveFT(address token, address sender, uint256 amount) external;
    function receiveGas(address token, bytes32 sender, uint256 amount) external;
}

abstract contract Meta {

    IDB public metaDB;

    mapping(address => bool) public operators;
    address[] public historyOperators;

    modifier onlyDAO {
        require(msg.sender == metaDB.DAO(), "Caller is not the MetaDAO");
        _;
    }

    modifier onlyOperator {
        require(operators[msg.sender] , "Caller is not an operator");
        _;
    }

    modifier onlyNFT {
        require(msg.sender == metaDB.NFT(), "Caller is not MetaNFT");
        _;
    }

    modifier onlyDB {
        require(msg.sender == address(metaDB), "Caller is not MetaDB");
        _;
    }

    function initApp(address db) internal {
        metaDB = IDB(db);
    }

    function setMetaDB(address db) external onlyDAO {
        metaDB = IDB(db);
    }

    function setOperator(address addr) external onlyDAO {
        bool flag = operators[addr];
        operators[addr] = !flag;
        if (!flag) {
            historyOperators.push(addr);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract KeyEnum {

    uint256 constant internal KEY_GRAFFITI = 0;
    uint256 constant internal KEY_META = 1;
    uint256 constant internal KEY_NFT_METADATA = 2;
    uint256 constant internal KEY_NFT_IMAGE = 3; // Image, Audio, Video...
    uint256 constant internal KEY_NFT_METADATA_URI = 4;
    uint256 constant internal KEY_NFT_IMAGE_URI = 5;
    uint256 constant internal KEY_ALIAS = 6;
    uint256 constant internal KEY_DESCRIPTION = 7;
    uint256 constant internal KEY_ENS_INFO = 8;
    uint256 constant internal KEY_EDITOR = 9;

    uint256 constant internal KEY_IPV4 = 10;
    uint256 constant internal KEY_IPV6 = 11;

    uint256 constant internal KEY_BUSINESS_URL = 1000;
    uint256 constant internal KEY_PERSONAL_URL = 1001;
    uint256 constant internal KEY_EMAIL = 1002;
    uint256 constant internal KEY_GITHUB = 1003;
    uint256 constant internal KEY_TWITTER = 1004;
    uint256 constant internal KEY_INSTAGRAM = 1005;
    uint256 constant internal KEY_TELEGRAM = 1006;
    uint256 constant internal KEY_TELEPHONE = 1007;

    uint256 constant internal KEY_ADDRESS_BTC = 2000;
    uint256 constant internal KEY_ADDRESS_SOL = 2001;
    uint256 constant internal KEY_ADDRESS_ADA = 2002;
    uint256 constant internal KEY_ADDRESS_DOGE = 2003;
    uint256 constant internal KEY_ADDRESS_DOT = 2004;
    uint256 constant internal KEY_ADDRESS_KSM = 2005;

    uint256 constant internal ETH_LIKE_ADDRESS_BEGIN = 3000;
    uint256 constant internal KEY_ADDRESS_ETH = (ETH_LIKE_ADDRESS_BEGIN + 0); // TODO same as owner?
    uint256 constant internal KEY_ADDRESS_ETC = (ETH_LIKE_ADDRESS_BEGIN + 1);
    uint256 constant internal KEY_ADDRESS_MATIC = (ETH_LIKE_ADDRESS_BEGIN + 2);
    uint256 constant internal KEY_ADDRESS_YAE = (ETH_LIKE_ADDRESS_BEGIN + 3);
    uint256 internal ETH_LIKE_ADDRESS_END = KEY_ADDRESS_YAE;
    uint256 internal KEY_ADDRESS_MAIN = KEY_ADDRESS_ETH;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Common/Meta.sol";
// import "./Common/KeyEnum.sol";

interface IMint {
    function mint(bytes32 node, address recommender) external;
}

contract Registrar is Meta {

    uint256 public minCost = 0.02 ether;
    uint256 public baseCost = 0.1 ether;
    uint64 public defaultTTL;
    bytes32 public topLevelNode;
    address public field;
    address public ledger;

    constructor(address _field, address _ledger, address _db, bytes32 _node) {
        initApp(_db);
        topLevelNode = _node;
        field = _field;
        ledger = _ledger;
    }

    function setCost(uint256 min, uint256 base) external onlyOperator {
        minCost = min;
        baseCost = base;
    }

    function setField(address addr) external onlyOperator {
        field = addr;
    }

    function setLedger(address addr) external onlyOperator {
        ledger = addr;
    }

    function setDefaultTTL(uint64 ttl) external onlyOperator {
        defaultTTL = ttl;
    }

    function setTopLevelNode(bytes32 node) external onlyOperator {
        topLevelNode = node;
    }

    // 1, 1000 ETH, 2, 100 ETH, 3, 10 ETH, 4, 1 ETH, 5, 0.1 ETH, 6, 0.02 ETH...
    function getCost(string memory name) public view returns (uint256 cost) {
        uint256 name_len = bytes(name).length;
        if (name_len >= 6) {
            cost = minCost;
        } else {
            cost = (10 ** (5 - name_len)) * baseCost;
        }
        return cost;
    }

    function register(
        address recommender,
        address owner,
        string memory name
    ) external payable returns (bytes32) {
        require(recommender != owner, "Recommender can not be one self");
        uint256 cost = getCost(name);
        require(msg.value >= cost, "Value is not enough");

        bytes32 node = metaDB.activateSubnode(topLevelNode, owner, 0, defaultTTL, name, "");
        IMint(field).mint(node, recommender);

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

contract NFT is IERC721Metadata, Meta {

    string public name;
    string public symbol;
    string public baseURI;
    bool public personalURI;
    address public fieldToken;
    address public assets;

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

    function setName(string calldata new_name) public onlyDAO {
        name = new_name;
    }

    function setSymbol(string calldata new_symbol) public onlyDAO {
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
        assets = addr;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        string memory uri = IMetadata(metaDB.resolver()).getNftMetadataURI(bytes32(tokenId));
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
            spender == address(metaDB)
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
        require(assets == address(0) || IAssetsOfDID(assets).checkAssets(node), "ERC721: DID has assets");

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

    function mint(bytes32 node, address owner, bytes memory _data) external onlyDB {
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

interface ILedger {
    function income(uint64 date) external view returns (uint256);
}

interface IField {
    function balanceOf(address account) external view returns (uint256);
    function infrastructure() external view returns (address);
    function community() external view returns (address);
    function gasBalance(bytes32 node) external view returns (uint256);
    function nodeToAddress(bytes32 node) external view returns (address, address);
}

interface IResolver {
    function resolve(string[] memory name_array) external view returns (bytes32 node, address owner, uint64 expire, uint64 ttl, uint64 transfer);
}

interface INFT {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract Midgard is Meta {

    mapping(bytes32 => address) public registrars;
    uint256 public deployHeight;
    address public field;

    constructor(address _db, address _field) {
        initApp(_db);
        field = _field;
    }

    function setField(address addr) external onlyDAO {
        field = addr;
    }

    function getNodeBaseInfo(string[] memory name_array) external view returns (
        bytes32 node,
        address owner,
        string memory tokenURI,
        string memory nickName,
        address token_contract,
        uint256 threshold
    ) {
        (node, owner, , , ) = IResolver(metaDB.resolver()).resolve(name_array);
        tokenURI = INFT(metaDB.NFT()).tokenURI(uint256(node));
        nickName = "";
        token_contract = metaDB.NFT(); // token_contract = field ? use nft instead !
        threshold = 1;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Common/Meta.sol";

interface ILedger {
    function income(uint64 date) external view returns (uint256);
    function historyTotalIncome() external view returns (uint256);
}

interface IField {
    function balanceOf(address account) external view returns (uint256);
    function infrastructure() external view returns (address);
    function community() external view returns (address);
    function gasBalance(bytes32 node) external view returns (uint256);
    function nodeToAddress(bytes32 node) external view returns (address, address);
}

contract MetaInfo is Meta {

    mapping(bytes32 => address) public registrars;
    uint256 public deployHeight;
    address public ledger;
    address public field;

    event RegistrarSet(bytes32 node, address registrar, string name);
    event DeployHeightSet(address db, uint256 height);
    event LedgerSet(address ledger_addr);
    event FieldSet(address field_addr);

    constructor(address _db, address _ledger, address _field) {
        initApp(_db);
        ledger = _ledger;
        field = _field;
    }

    function setRegistrar(bytes32 node, address addr) external onlyDAO {
        registrars[node] = addr;
        emit RegistrarSet(node, addr, metaDB.getNodeRecord(node).name);
    }

    function setLedger(address addr) external onlyDAO {
        ledger = addr;
        emit LedgerSet(addr);
    }

    function setField(address addr) external onlyDAO {
        field = addr;
        emit FieldSet(addr);
    }

    function setDeployHeight(uint256 height) external onlyDAO {
        deployHeight = height;
        emit DeployHeightSet(address(metaDB), height);
    }

    function getMetaInfo(bytes32[] memory node_list) external view returns (
        address _DB,
        address _DAO,
        address _NFT,
        address _resolver,
        address _filter,
        address _editor,
        address _field,
        address _ledger,
        uint256 _height,
        address[] memory _registrars
    ) {
        _registrars = new address[](node_list.length);
        for (uint256 i = 0; i <= node_list.length; i++) {
            _registrars[i] = registrars[node_list[i]];
        }

        _DB = address(metaDB);
        _DAO = metaDB.DAO();
        _NFT = metaDB.NFT();
        _resolver = metaDB.resolver();
        _filter = metaDB.filter();
        _editor = metaDB.editor();
        _field = field;
        _ledger = ledger;
        _height = deployHeight;
    }

    function today() public view returns (uint64) {
        return uint64(block.timestamp / (24 hours));
    }

    function getStatistics() external view returns (
        uint256 income_yesterday,
        uint256 income_today,
        uint256 income_total,
        uint256 total_nodes,
        uint256 infra_balance,
        uint256 community_balance
    ) {
        income_yesterday = ILedger(ledger).income(today() - 1);
        income_today = ILedger(ledger).income(today());
        income_total = ILedger(ledger).historyTotalIncome();
        total_nodes = metaDB.totalSupply();
        infra_balance = IField(field).balanceOf(IField(field).infrastructure());
        community_balance = IField(field).balanceOf(IField(field).community());
    }

    function getNodeBaseInfo(bytes32 node, bytes32[] memory keys) external view returns (
        uint256 owner_balance,
        uint256 locked_balance,
        uint256 staked_balance,
        uint256 gas_balance,
        bytes[] memory values
    ) {
        (address left, address right) = IField(field).nodeToAddress(node);
        locked_balance = IField(field).balanceOf(right);
        staked_balance = IField(field).balanceOf(left);
        owner_balance = IField(field).balanceOf(metaDB.getNodeRecord(node).owner);
        gas_balance = locked_balance + staked_balance;
        values = new bytes[](keys.length);
        for (uint256 i = 0; i <= keys.length; i++) {
            values[i] = "null"; // TODO keys & values
        }
    }

    function getNodeBaseInfo(bytes32 node) external view returns (
        uint256 owner_balance,
        uint256 locked_balance,
        uint256 staked_balance,
        uint256 gas_balance
    ) {
        (address left, address right) = IField(field).nodeToAddress(node);
        locked_balance = IField(field).balanceOf(right);
        staked_balance = IField(field).balanceOf(left);
        owner_balance = IField(field).balanceOf(metaDB.getNodeRecord(node).owner);
        gas_balance = locked_balance + staked_balance;
    }

    /*

    function getStatisticsOfOwner(address owner, uint64 date) external view returns (
        uint256 field_balance_now,
        uint256 accumulated_reward,
        uint256 accumulated_income,
        uint256 available_income_now,
        bytes32 node,
        uint64 checkin_timestamp,
        string memory full_name
    ) {

    }

    */

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Common/Meta.sol";
import "./Common/LibSignature.sol";

contract Ledger is Meta {

    using LibSignature for bytes32;

    mapping(uint64 => uint256) public income;
    mapping(bytes32 => uint256) public divident;
    mapping(bytes32 => uint64) public latest;
    uint256 public historyTotalIncome;

    event UserDivident(uint256 timestamp, bytes32 indexed node, address indexed owner, uint256 amount, uint256 accumulated);
    event PlatformIncome(uint256 timestamp, address indexed item, uint256 income,  uint256 accumulated);

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
        historyTotalIncome += msg.value;
        emit PlatformIncome(block.timestamp, msg.sender, msg.value, income[date]);
    }

    function sendValue(address payable recipient, uint256 amount) private {
        require(address(this).balance >= amount, "Insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Unable to send value, recipient may have reverted");
    }

    function withdraw(bytes32 node, uint256 amount, bytes memory signature) external {
        address owner = metaDB.getNodeRecord(node).owner;
        require(owner != address(0), "Node is not existed"); // Same as metaDB.isNodeExisted(node)

        (address signer, , uint64 date) = verify_signature(node, amount, signature);
        require(date > latest[node] && operators[signer], "Invalid arguments");
        latest[node] = date;

        divident[node] += amount;
        sendValue(payable(owner), amount);
        emit UserDivident(block.timestamp, node, owner, amount, divident[node]);
    }

    function verify_signature(
        bytes32 node,
        uint256 amount,
        bytes memory signature
    ) public view returns (address signer, bytes32 hash, uint64 date) {
        date = today();
        bytes memory preimage = abi.encode(date, node, amount);
        hash = keccak256(preimage);
        signer = hash.recover(signature);
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

contract Filter is Meta {
    // [email protected], alice_163, alice#163, -alice, alice-, are not supported;
    // alice-163, alice-1-6-3 are supported.

    mapping(bytes32 => bool) public targetHashTable;
    uint8 public minLength = 1;
    uint8 public maxLength = 255;

    constructor(address _db) {
        initApp(_db);
    }

    function setNameLength(uint8 min_len, uint8 max_len) external onlyOperator {
        require(max_len >= min_len, "Arguments error");
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./Common/Meta.sol";

contract Field is IERC20, IERC20Metadata, Meta {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public receivedOf;
    mapping(bytes32 => uint64) public applyTimestamp;
    mapping(uint64 => uint256) public everydayOfInfra;

    //  namehash of did: 0x8a74fc6994ef0554dd9cc95c3391f9cd66152031a0c1feacb835e3890805af5f
    //  namehash of dao: 0xb5f2bbf81da581299d4ff7af60560c0ac854196f5227328d2d0c2bb0df33e553

    address public infrastructure = 0x3391f9cD66152031a0C1FeaCb835e3890805AF5F;
    address public community = 0x60560c0AC854196F5227328d2D0C2Bb0dF33e553;

    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    string public name;
    string public symbol;

    uint64 public constant interval = 24 hours;

    event NodeRecommender(bytes32 indexed node, address indexed recommender);

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
        require(balanceOf[nodeLeftToAddress(node)] > 0, "ERC20: balance is zero");
        require(applyTimestamp[node] == 0, "ERC20: already applied");

        applyTimestamp[node] = uint64(block.timestamp);
    }

    // When transfer / burn / reclaim did-nft (node), remember to check assets of the node
    // If someone intentionally leave some assets for the node, it still can be burned / reclaimed when expired
    function reclaim(bytes32 node, address to, uint256 amount) external {
        require(msg.sender == metaDB.getNodeRecord(node).owner, "ERC20: msg.sender is not the node owner ");
        require(applyTimestamp[node] + 24 hours > block.timestamp, "ERC20: wait at least 24 hours");

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
            emit NodeRecommender(node, recommender);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../Common/Meta.sol";

interface IFieldToken {
    function gasBalance(bytes32 node) external view returns (uint256);
    function today() external view returns (uint64);
    function balanceOf(address account) external view returns (uint256);
    function nodeToAddress(bytes32 node) external view returns (address, address);
}

contract Gas is Meta {

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
        uint64 date = today();
        return fieldToken.gasBalance(node) + inGas[node][date] - outGas[node][date];
    }

    function transferFrom(bytes32 from, bytes32 to, uint256 amount) external returns (bool) {
        require(transferOn, "Transfer off");
        require(msg.sender == metaDB.getNodeRecord(from).owner, "Msg.sender is not the node owner");
        require(metaDB.isNodeActive(to), "Destination node is not active");
        require(balanceOf(from) >= amount, "Balance is not enough");
        require(from != to, "Transfer to self");

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

import "../Common/Meta.sol";

contract Assets is Meta {

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

import "./Common/IDB.sol";
import "./Common/Meta.sol";

interface INFT {
    function mint(bytes32 node, address owner, bytes memory _data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
}

interface IFilter {
    function validName(string memory name) external view returns (bool);
}

contract DB is IDB, Meta {

    // Editor, Registrar, Resolver, belong to node-DB without Item-Key-Encode
    // EthLikeAddress, Email, Twitter, Github..., belong to owner-DB with Item-Key-Encode

    mapping(bytes32 => mapping(bytes32 => bytes)) public hashDB;
    mapping(bytes32 => Node) public nodeRecord;
    mapping(address => bytes32) public reverseRecord;

    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    mapping(uint256 => address) public tokenApprovals; // Mapping from token ID to approved address
    mapping(address => mapping(address => bool)) public operatorApprovals;  // Mapping from owner to operator approvals

    bytes32 constant public ROOT = bytes32(0);

    address public DAO;
    address public NFT;
    address public resolver;
    address public filter;
    address public editor;

    event HashItemUpdated(bytes32 indexed node, address indexed owner, bytes32 indexed item_key, bytes value);

    event ReverseRecordSet(address indexed main_address, bytes32 indexed node); // node == bytes(0) means delete reverse record
    event NodeInfoUpdated(bytes32 indexed node, bytes32 parent, address owner, uint64 expire, uint64 ttl, uint64 transfer, string name);
    // event NodeInfoUpdated(bytes32 indexed node, Node info); // Java-web3j can not decode struct in the event

    constructor(address dao) {
        DAO = dao;
        metaDB = this;
        operators[dao] = true;

        nodeRecord[ROOT].parent = ROOT;
        nodeRecord[ROOT].owner = dao;
        nodeRecord[ROOT].transfer = uint64(block.timestamp);
        nodeRecord[ROOT].expire = type(uint64).max;
        nodeRecord[ROOT].ttl = 0;
        nodeRecord[ROOT].name = "";

        balanceOf[dao] = 1;
        totalSupply = 1;
    }

    modifier onlyExisted(bytes32 node) {
        require(isNodeExisted(node) , "Node is not existed");
        _;
    }

    function setDAO(address addr) external onlyDAO {
        operators[DAO] = false;
        operators[addr] = true;
        DAO = addr;
    }

    function setEditor(address addr) public onlyDAO {
        operators[editor] = false;
        operators[addr] = true;
        editor = addr;
    }

    function setNFT(address addr) public onlyDAO {
        operators[NFT] = false;
        operators[addr] = true;
        NFT = addr;
    }

    function setFilter(address addr) external onlyDAO {
        filter = addr;
    }

    function setResolver(address addr) external onlyDAO {
        resolver = addr;
    }

    function _emitNodeInfo(bytes32 node) private {
        Node memory n = nodeRecord[node];
        emit NodeInfoUpdated(node, n.parent, n.owner, n.expire, n.ttl, n.transfer, n.name);
    }

    function emitNodeInfo(bytes32 node) external onlyOperator {
        _emitNodeInfo(node);
    }

    function setNodeExpire(bytes32 node, uint64 expire, bool emit_event) external onlyExisted(node) onlyOperator {
        require(
            nodeRecord[nodeRecord[node].parent].expire >= expire &&
            expire > block.timestamp &&
            expire > nodeRecord[node].expire, "Invalid expire"
        );
        nodeRecord[node].expire = expire;
        if (emit_event) {
            _emitNodeInfo(node);
        }
    }

    function setNodeTTL(bytes32 node, uint64 ttl, bool emit_event) external onlyExisted(node) onlyOperator {
        nodeRecord[node].ttl = ttl;
        if (emit_event) {
            _emitNodeInfo(node);
        }
    }

    function setReverse(address owner, bytes32 node) onlyExisted(node) external onlyOperator {
        bytes32 current_node = reverseRecord[owner];
        if (current_node != node) {
            if (node != bytes32(0)) {
                require(nodeRecord[node].owner == owner, "Node owner doesn't match");
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
    function createNode(bytes32 parent, bytes32 node, address owner, uint64 expire, uint64 ttl, string memory name) private {
        require(owner != address(0) , "Invalid owner");

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
    function clearNode(bytes32 node) external onlyNFT {
        require(!isNodeActive(node), "Node is active");
        address current_owner = nodeRecord[node].owner;
        balanceOf[current_owner] -= 1;
        totalSupply -= 1;
        delete nodeRecord[node];

        _deleteReverse(current_owner, node);

        _emitNodeInfo(node);
    }

    // 1) Transfer NFT, 2)Reclaim node;  // No need of onlyExisted(node), require isNodeActive instead
    function transferNodeOwner(bytes32 node, address owner) external onlyNFT {
        require(isNodeActive(node) && owner != address(0) , "Invalid owner");
        address current_owner = nodeRecord[node].owner;
        require(current_owner != owner, "Transfer to self");

        balanceOf[current_owner] -= 1;
        balanceOf[owner] += 1;
        nodeRecord[node].owner = owner;
        nodeRecord[node].transfer = uint64(block.timestamp);

        _deleteReverse(current_owner, node);
        _setReverse(owner, node);

        _emitNodeInfo(node);
    }

    function setTokenApprovals(uint256 token_id, address to) external onlyExisted(bytes32(token_id)) onlyNFT {
        tokenApprovals[token_id] = to;
    }

    function setOperatorApprovals(address owner, address operator, bool approved) external onlyNFT {
        operatorApprovals[owner][operator] = approved;
    }

    function encodeNodeOwner(bytes32 node, address owner) public view onlyExisted(node) returns (bytes32, address) {
        if (owner == address(0)) {
            owner = nodeRecord[node].owner;
        }
        return (keccak256(abi.encodePacked(node, owner)), owner);
    }

    function setNodeItem(bytes32 node, bytes32 item_key, bytes memory item_value) external onlyExisted(node) onlyOperator {
        if (item_value.length > 0) {
            hashDB[node][item_key] = item_value;
            emit HashItemUpdated(node, address(0), item_key, item_value);
        } else {
            delete hashDB[node][item_key];
            emit HashItemUpdated(node, address(0), item_key, "");
        }
    }

    function setNodeOwnerItem(bytes32 node, address owner, bytes32 item_key, bytes memory item_value) external onlyOperator {
        bytes32 hash;
        (hash, owner) = encodeNodeOwner(node, owner);
        if (item_value.length > 0) {
            hashDB[hash][item_key] = item_value;
            emit HashItemUpdated(node, owner, item_key, item_value);
        } else {
            delete hashDB[hash][item_key];
            emit HashItemUpdated(node, owner, item_key, "");
        }
    }

    function setNodeItemBatch(bytes32 node, bytes32[] memory item_keys, bytes[] memory item_values) external onlyExisted(node) onlyOperator {
        if (item_keys.length == item_values.length) {
            for (uint256 i=0; i < item_keys.length; i++) {
                hashDB[node][item_keys[i]] = item_values[i];
                emit HashItemUpdated(node, address(0), item_keys[i], item_values[i]);
            }
        } else {
            for (uint256 i=0; i < item_keys.length; i++) {
                delete hashDB[node][item_keys[i]];
                emit HashItemUpdated(node, address(0), item_keys[i], "");
            }
        }
    }

    function setNodeOwnerItemBatch(bytes32 node, address owner, bytes32[] memory item_keys, bytes[] memory item_values) external onlyOperator {
        bytes32 hash;
        (hash, owner) = encodeNodeOwner(node, owner);
        if (item_keys.length == item_values.length) {
            for (uint256 i=0; i < item_keys.length; i++) {
                hashDB[hash][item_keys[i]] = item_values[i];
                emit HashItemUpdated(node, owner, item_keys[i], item_values[i]);
            }
        } else {
            for (uint256 i=0; i < item_keys.length; i++) {
                delete hashDB[hash][item_keys[i]];
                emit HashItemUpdated(node, owner, item_keys[i], "");
            }
        }
    }

    function isNodeActive(bytes32 node) public view returns (bool) {
        return nodeRecord[node].expire >= block.timestamp;
    }

    function isNodeExisted(bytes32 node) public view returns (bool) {
        return nodeRecord[node].expire > 0;
    }

    function getNodeRecord(bytes32 node) external view returns (Node memory) {
        return (nodeRecord[node]);
    }

    function getNodeItem(bytes32 node, bytes32 item_key) external onlyExisted(node) view returns (bytes memory) {
        return hashDB[node][item_key];
    }

    function getNodeOwnerItem(bytes32 node, address owner, bytes32 item_key) external view returns (bytes memory) {
        (bytes32 hash,) = encodeNodeOwner(node, owner);
        return hashDB[hash][item_key];
    }

    function activateSubnode(
        bytes32 parent,
        address owner,
        uint64 expire,
        uint64 ttl,
        string memory name,
        bytes memory _data
    ) external onlyOperator returns (bytes32) {
        Node memory p = nodeRecord[parent];
        if (expire == 0) {
            expire = p.expire;
        }
        require(expire > block.timestamp && p.expire >= expire, "Invalid node");
        require(IFilter(filter).validName(name), "Invalid name");

        bytes32 node = keccak256(abi.encodePacked(parent, keccak256(abi.encodePacked(name)))); // encodeNameToNode(parent, name);
        if (!isNodeExisted(node)) {
            createNode(parent, node, owner, expire, ttl, name);
            INFT(NFT).mint(node, owner, _data);
        } else if (!metaDB.isNodeActive(node)) {
            nodeRecord[node].expire = expire; // setNodeExpire(node, expire);
            nodeRecord[node].ttl = ttl; // setNodeTTL(node, ttl);
            INFT(NFT).safeTransferFrom(nodeRecord[node].owner, owner, uint256(node), _data);
        } else {
            revert("Node is active");
        }

        return node;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Common/KVS.sol";
import "./Common/IDB.sol";

contract Editor is KVS {

    constructor(address _db) {
        initApp(_db);
    }

    // Require msg.sender is a cooperator (Owner, Registrar_Contract)
    modifier onlyCooperatorOfActiveNode(bytes32 node) {
        require (msg.sender == getNodeOwner(node) || msg.sender == getEditor(node), "Caller is not a team member");
        require (metaDB.isNodeActive(node), "Invalid node");
        _;
    }

    function setTTL(bytes32 node, uint64 ttl) external onlyCooperatorOfActiveNode(node) {
        metaDB.setNodeTTL(node, ttl, true);
    }

    function setNftImageURI(bytes32 node, string memory uri) external onlyCooperatorOfActiveNode(node) {
        metaDB.setNodeOwnerItem(node, address(0), bytes32(KEY_NFT_IMAGE_URI), abi.encode(uri));
    }

    function setNftMetadataURI(bytes32 node, string memory uri) external onlyCooperatorOfActiveNode(node) {
        metaDB.setNodeOwnerItem(node, address(0), bytes32(KEY_NFT_METADATA_URI), abi.encode(uri));
    }

    function _setOwnerAddressItem(bytes32 node, bytes32 item_key, address addr) private {
        if (addr == address(0)) {
            metaDB.setNodeOwnerItem(node, address(0), item_key, "");
        } else {
            // Address with Timestamp: |Address(160bit)|Null(32bit)|Timestamp(64bit)|
            bytes memory enc_value = abi.encode((uint256(uint160(addr)) << 96) + uint64(block.timestamp));
            metaDB.setNodeOwnerItem(node, address(0), item_key, enc_value);
        }
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
        require(item_keys.length == eth_like_addrs.length, "Length error");
        for (uint256 i=0; i < item_keys.length; i++) {
            require(
                item_keys[i] >= ETH_LIKE_ADDRESS_BEGIN &&
                item_keys[i] <= ETH_LIKE_ADDRESS_END &&
                item_keys[i] != KEY_ADDRESS_MAIN,
                "ItemKey is not an ethereum-like address"
            );
            _setOwnerAddressItem(node, bytes32(item_keys[i]), eth_like_addrs[i]);
        }
    }

}