//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./interfaces.sol";

import "./registrant.sol";
import "./metadata.sol";
import "./resolver.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";

contract SubdomainController is Ownable, IERC721, ERC165, IERC721Metadata{

    iRegistrant public Registrant;
    iMetadata public MetadataProvider;
    iResolver public Resolver;

    mapping(uint256 => string) public IdToLabelMap;
    mapping(uint256 => bytes32) public IdToHashMap;
    mapping(bytes32 => uint256) public HashToIdMap;
    mapping(bytes32 => mapping(string => string)) public texts;




    ENS private ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e); 

    string public DOMAIN_LABEL = "boulder";
    bytes32 public domainHash;

    constructor () {
        Registrant = new Registrant_v1();
        MetadataProvider = new Metadata_v1();
        Resolver = new Resolver_v1(this);

        Ownable(address(Registrant)).transferOwnership(msg.sender);

        domainHash = getDomainHash();        
    }

    function getIdFromHash(bytes32 _hash) external view returns(uint256) {
        return HashToIdMap[_hash];
    }

    function getText(bytes32 node, string calldata key) external view returns(string memory){
        return texts[node][key];
    }


    function setEns(address _addr) public onlyOwner {
        ens = ENS(_addr);
    }

    function setResolver(address _addr) public onlyOwner {
        Resolver = iResolver(_addr);
    }

    function setRegistrant(address _addr) public onlyOwner {
        Registrant = iRegistrant(_addr);
    }

    function setMetadata(address _addr) public onlyOwner {
        MetadataProvider = iMetadata(_addr);
    }

    function transferResolverOwnership(address _addr) public onlyOwner{
        Ownable(address(Resolver)).transferOwnership(_addr);
    }

    function transferRegistrantOwnership(address _addr) public onlyOwner{
        Ownable(address(Registrant)).transferOwnership(_addr);
    }

    function transferMetadataOwnership(address _addr) public onlyOwner{
        Ownable(address(MetadataProvider)).transferOwnership(_addr);
    }

   function addr(bytes32 nodeID) public view returns (address) {
        return address(uint160(HashToIdMap[nodeID]));
    }

    function deleteDomain(string memory _label) external onlyOwner {

    }

    function transferDomain(string memory _label, address _addr) external onlyOwner {

    }

    function getLabelFromId(uint256 _id) external view returns (string memory) {
        return IdToLabelMap[_id];
    }

    function getHashFromId(uint256 _id) external view returns (bytes32) {
        return IdToHashMap[_id];
    }    

    function setText(bytes32 node, string calldata key, string calldata value) external onlyOwner{
        require(keccak256(abi.encodePacked(value)) != keccak256("avatar"), "cannot set avatar");
        texts[node][key] = value;
    }

    function registerDomain(address _addr, string calldata _label) public {
        require(Registrant.canRegister(_addr, _label), "failed registration check");
        require(IdToHashMap[uint160(_addr)] == 0x0, "address already registered sub-domain");
        
        bytes32 encoded_label = keccak256(abi.encodePacked(_label));       
        bytes32 big_hash = keccak256(abi.encodePacked(domainHash, encoded_label));

        require(!ens.recordExists(big_hash) || owner() == msg.sender, "sub-domain already exists");

        uint160 id = uint160(_addr);
        IdToHashMap[id] = big_hash;
        IdToLabelMap[id] = _label;
        HashToIdMap[big_hash] = id;

        ens.setSubnodeRecord(domainHash, encoded_label, owner(), address(this), 0);
        emit Transfer(address(0), msg.sender, uint160(_addr));
    }

    function text(bytes32 node, string calldata key) external view returns (string memory){
        return Resolver.text(node, key);
    }

    //this is the correct method for creating a 2 level ENS namehash
    function getDomainHash() private view returns (bytes32 namehash) {
            namehash = 0x0;
            namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked('eth'))));
            namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked(DOMAIN_LABEL))));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(false, "cannot be transferred");
    }

    function tokenURI(uint256 tokenId) external view returns (string memory)
    {
        require(IdToHashMap[tokenId] != 0x0, "sub-domain does not exist");
        return MetadataProvider.metadata(string(abi.encodePacked(IdToLabelMap[tokenId], ".", DOMAIN_LABEL, ".eth")));
    }

    function symbol() external pure returns (string memory){
        return "ENS";
    }

    function name() external view returns (string memory){
        return string(abi.encodePacked(DOMAIN_LABEL, ".eth"));
    }

    function setApprovalForAll(address operator, bool _approved) external{
        require(false, "cannot be transferred");
    }

    function getApproved(uint256 tokenId) external view returns (address operator){
        require(false, "cannot be transferred");
        return address(0);
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool){
        return false;
    }

    function approve(address to, uint256 tokenId) external{
        require(false, "cannot be transferred");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
        require(false, "cannot be transferred");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) public {
        require(false, "cannot be transferred");
    }

    function ownerOf(uint256 tokenId) public view returns (address _owner) {
        require(IdToHashMap[uint160(tokenId)] != 0x0, "sub-domain does not exist");
        return address(uint160(tokenId));
    }

    function balanceOf(address owner) external view returns (uint256 balance){
        return IdToHashMap[uint160(owner)] == 0x0 ? 0 : 1;
    }



}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


interface iResolver {

    function text(bytes32 _node, string calldata _key) external view returns (string memory);

}

interface iRegistrant {

    function canRegister(address _addr, string calldata _label) external view returns(bool);

}

interface iMetadata {
    
    function metadata(string calldata _name) external view returns(string memory);

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./interfaces.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Registrant_v1 is iRegistrant, Ownable {

    mapping(address => bool) public WhiteList; 
    address DeployingAddress;

    constructor() {
        DeployingAddress = msg.sender;
    }
    
    function canRegister(address _addr, string calldata _label) external view returns(bool) {
        require(msg.sender == DeployingAddress, "not authorised");
        return tx.origin == owner() || WhiteList[_addr];
    }
    
    function addAddress(address _addr) external onlyOwner {
        WhiteList[_addr] = true;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import './interfaces.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Metadata_v1 is iMetadata {

string image = "QmQv5EcyuGn9MBFiN7YjjdkHNEScfC6cYK4C4xVaxsuYik";


function metadata(string calldata _name) external view returns(string memory){

    return string(abi.encodePacked('data:application/json;utf8,{"name": "',_name,'","description": "None-transferable boulder.eth sub-domain","image":"ipfs://', image, '"}'));
}

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./interfaces.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./controller.sol";

contract Resolver_v1 is iResolver {

    using Strings for uint256;

    SubdomainController controller;



    constructor(SubdomainController _controller) {
        controller = _controller;
    }



    function text(bytes32 node, string calldata key) external view returns (string memory) {
        uint256 token_id = controller.getIdFromHash(node);
        require(token_id > 0 && controller.getHashFromId(token_id) != 0x0, "Invalid address");
        if(keccak256(abi.encodePacked(key)) == keccak256("avatar")){

            return string(abi.encodePacked("eip155:1/erc721:", addressToString(address(controller)), "/", token_id.toString()));            
        }
        else{
            return controller.getText(node, key);
        }
    }

    //<helper-functions>
    function addressToString(address _addr) private pure returns(string memory) {
    bytes32 value = bytes32(uint256(uint160(_addr)));
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(42);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < 20; i++) {
        str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
        str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
    return string(str);
    }

}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

pragma solidity >=0.8.4;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external virtual returns(bytes32);
    function setResolver(bytes32 node, address resolver) external virtual;
    function setOwner(bytes32 node, address owner) external virtual;
    function setTTL(bytes32 node, uint64 ttl) external virtual;
    function setApprovalForAll(address operator, bool approved) external virtual;
    function owner(bytes32 node) external virtual view returns (address);
    function resolver(bytes32 node) external virtual view returns (address);
    function ttl(bytes32 node) external virtual view returns (uint64);
    function recordExists(bytes32 node) external virtual view returns (bool);
    function isApprovedForAll(address owner, address operator) external virtual view returns (bool);
}

// SPDX-License-Identifier: MIT

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
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT

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