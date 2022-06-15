/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: MIT 
pragma solidity 0.8.14;
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;
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
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
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
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
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
interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
contract ERC165 is IERC165 {
    bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
    mapping(bytes4 => bool) private _supportedInterfaces;
    constructor(){
        _registerInterface(_InterfaceId_ERC165);
    }
    function supportsInterface(bytes4 interfaceId)
        external
        view virtual
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }
    function _registerInterface(bytes4 interfaceId)
        internal
    {
        require(interfaceId != 0xffffffff, "Can't register 0xffffffff");
        _supportedInterfaces[interfaceId] = true;
    }
}
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
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
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    } 
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
library EnumerableMap {
    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }
    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;
        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];
        if (keyIndex != 0) { 
            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;
            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.
            MapEntry storage lastEntry = map._entries[lastIndex];
            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based
            // Delete the slot where the moved entry was stored
            map._entries.pop();
            // Delete the index for the deleted slot
            delete map._indexes[key];
            return true;
        } else {
            return false;
        }
    }
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");
        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }
    // UintToAddressMap
    struct UintToAddressMap {
        Map _inner;
    }
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}
library EnumerableSet {
    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }
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
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) { 
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.
            bytes32 lastvalue = set._values[lastIndex];
            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based
            // Delete the slot where the moved value was stored
            set._values.pop();
            // Delete the index for the deleted slot
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
    // AddressSet
    struct AddressSet {
        Set _inner;
    }
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }
    // UintSet
    struct UintSet {
        Set _inner;
    }
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}
contract ERC721 is Context,ERC165,IERC721,IERC721Metadata,IERC721Enumerable{
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;
    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping(address => EnumerableSet.UintSet) private _holderTokens;
    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;
    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    // Token name
    string private _name;
    // Token symbol
    string private _symbol;
    // Optional mapping for token URIs
    mapping(uint256 => string) internal _tokenURIs;
    // Base URI
    string internal _baseURI;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    constructor(string memory name, string memory symbol){
        _name = name;
        _symbol = symbol;
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0),"ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId,"ERC721: owner query for nonexistent token");
    }
    function name() public view override returns (string memory) {
        return _name;
    }
    function symbol() public view override returns (string memory) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId)public view virtual override returns (string memory){
        require( _exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }
    function tokenOfOwnerByIndex(address owner, uint256 index)public view override returns (uint256){
        return _holderTokens[owner].at(index);
    }
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }
    function tokenByIndex(uint256 index)public view override returns (uint256){
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),"ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId)public view override returns (address){
        require(_exists(tokenId),"ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved)public virtual override{
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address owner, address operator)public view override returns (bool){
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(address from,address to,uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId),"ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from,address to,uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId),"ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    function _safeTransfer(address from,address to,uint256 tokenId,bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data),"ERC721: transfer to non ERC721Receiver implementer");
    }
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId)internal view returns (bool){
        require(_exists(tokenId),"ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }
    function _safeMint(address to,uint256 tokenId,bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data),"ERC721: transfer to non ERC721Receiver implementer");
    }
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _beforeTokenTransfer(address(0), to, tokenId);
        _holderTokens[to].add(tokenId);
        _tokenOwners.set(tokenId, to);
        emit Transfer(address(0), to, tokenId);
    }
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        // Clear approvals
        _approve(address(0), tokenId);
        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
        _holderTokens[owner].remove(tokenId);
        _tokenOwners.remove(tokenId);
        emit Transfer(owner, address(0), tokenId);
    }
    function _transfer(address from,address to,uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from,"ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);
        _tokenOwners.set(tokenId, to);
        emit Transfer(from, to, tokenId);
    }
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)internal virtual{
        require(_exists(tokenId),"ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }
    function _checkOnERC721Received(address from,address to,uint256 tokenId,bytes memory _data) private returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata =to.functionCall(abi.encodeWithSelector(IERC721Receiver(to).onERC721Received.selector,_msgSender(),from,tokenId,_data),
                "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }
    function _beforeTokenTransfer(address from,address to,uint256 tokenId) internal virtual {}
}
interface IERC721TokenURI {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
// ProtocolFeeSettings
// This contract allows an optional fee percentage and recipient to be set for individual modules
contract ProtocolFeeSettings is ERC721 {
    // The address of the contract metadata
    address public metadata;
    // The address of the contract owner
    address public owner;
    // The address of the  Module Manager
    address public minter;

    // The metadata of a module fee setting
    // feeBps The basis points fee
    // feeRecipient The recipient of the fee
    struct FeeSetting {
        uint16 feeBps;
        address feeRecipient;
    }

    // Mapping of modules to fee settings
    /// @dev Module address => FeeSetting
    mapping(address => FeeSetting) public moduleFeeSetting;

    // Ensures only the owner of a module fee NFT can set its fee
    // _module The address of the module
    modifier onlyModuleOwner(address _module) {
        uint256 tokenId = moduleToTokenId(_module);
        require(ownerOf(tokenId) == msg.sender, "onlyModuleOwner");
        _;
    }

    // Emitted when the fee for a module is updated
    // module The address of the module
    // feeRecipient The address of the fee recipient
    // feeBps The basis points of the fee
    event ProtocolFeeUpdated(address indexed module, address feeRecipient, uint16 feeBps);

    // Emitted when the contract metadata is updated
    // newMetadata The address of the new metadata
    event MetadataUpdated(address indexed newMetadata);

    // Emitted when the contract owner is updated
    // newOwner The address of the new owner
    event OwnerUpdated(address indexed newOwner);

    constructor() ERC721("Module Fee Switch", "ZORF") {
        _setOwner(msg.sender);
    }

    // Initialize the Protocol Fee Settings
    // _minter The address that can mint new NFTs (expected ModuleManager address)
    function init(address _minter, address _metadata) external {
        require(msg.sender == owner, "init only owner");
        require(minter == address(0), "init already initialized");
        minter = _minter;
        metadata = _metadata;
    }
    function mint(address _to, address _module) external returns (uint256) {
        require(msg.sender == minter, "mint onlyMinter");
        uint256 tokenId = moduleToTokenId(_module);
        _mint(_to, tokenId);
        return tokenId;
    }
    // Sets fee parameters for a module fee NFT
    // _module The module to apply the fee settings to
    // _feeRecipient The fee recipient address to send fees to
    // _feeBps The bps of transaction value to send to the fee recipient
    function setFeeParams(
        address _module,
        address _feeRecipient,
        uint16 _feeBps
    ) external onlyModuleOwner(_module) {
        require(_feeBps <= 10000, "setFeeParams must set fee <= 100%");
        require(_feeRecipient != address(0) || _feeBps == 0, "setFeeParams fee recipient cannot be 0 address if fee is greater than 0");
        moduleFeeSetting[_module] = FeeSetting(_feeBps, _feeRecipient);
        emit ProtocolFeeUpdated(_module, _feeRecipient, _feeBps);
    }
    // Sets the owner of the contract
    // _owner The address of the owner
    function setOwner(address _owner) external {
        require(msg.sender == owner, "setOwner onlyOwner");
        _setOwner(_owner);
    }
    // Sets the metadata of the contract
    // _metadata The address of the metadata
    function setMetadata(address _metadata) external {
        require(msg.sender == owner, "setMetadata onlyOwner");
        _setMetadata(_metadata);
    }
    // Computes the fee for a given uint256 amount
    // _module The module to compute the fee for
    // _amount The amount to compute the fee for
    // The amount to be paid out to the fee recipient
    function getFeeAmount(address _module, uint256 _amount) external view returns (uint256) {
        return (_amount * moduleFeeSetting[_module].feeBps) / 10000;
    }

    // Returns the module address for a given token ID
    // _tokenId The token ID
    // The module address
    function tokenIdToModule(uint256 _tokenId) public pure returns (address) {
        return address(uint160(_tokenId));
    }

    // Returns the token ID for a given module
    /// @dev We don't worry about losing the top 20 bytes when going from uint256 -> uint160 since we know token ID must have derived from an address
    // _module The module address
    // The token ID
    function moduleToTokenId(address _module) public pure returns (uint256) {
        return uint256(uint160(_module));
    }

    // Returns the token URI for a given token ID
    // _tokenId The token ID
    // The token URI
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(metadata != address(0), "ERC721Metadata: no metadata address");

        return IERC721TokenURI(metadata).tokenURI(_tokenId);
    }

    // Sets the contract metadata in `setMetadata`
    // _metadata The address of the metadata
    function _setMetadata(address _metadata) private {
        metadata = _metadata;

        emit MetadataUpdated(_metadata);
    }

    // Sets the contract owner in `setOwner`
    // _owner The address of the owner
    function _setOwner(address _owner) private {
        owner = _owner;

        emit OwnerUpdated(_owner);
    }
}

// ModuleManager
// This contract allows users to approve registered modules 
contract ModuleManager {
    // The EIP-712 type for a signed approval
    /// @dev keccak256("SignedApproval(address module,address user,bool approved,uint256 deadline,uint256 nonce)")
    bytes32 private constant SIGNED_APPROVAL_TYPEHASH = 0x8413132cc7aa5bd2ce1a1b142a3f09e2baeda86addf4f9a5dacd4679f56e7cec;
    // The EIP-712 domain separator
    bytes32 private immutable EIP_712_DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("USMAN")),
                keccak256(bytes("1")),
                _chainID(),
                address(this)
            )
        );

    // The module fee NFT contract to mint from upon module registration
    ProtocolFeeSettings public immutable moduleFeeToken;
    // The registrar address that can register modules
    address public registrar;
    // Mapping of users and modules to approved status
    /// @dev User address => Module address => Approved
    mapping(address => mapping(address => bool)) public userApprovals;

    // Mapping of modules to registered status
    /// @dev Module address => Registered
    mapping(address => bool) public moduleRegistered;

    // The signature nonces for 3rd party module approvals
    mapping(address => uint256) public sigNonces;

    // Ensures only the registrar can register modules
    modifier onlyRegistrar() {
        require(msg.sender == registrar, "ZMM::onlyRegistrar must be registrar");
        _;
    }

    // Emitted when a user's module approval is updated
    // user The address of the user
    // module The address of the module
    // approved Whether the user added or removed approval
    event ModuleApprovalSet(address indexed user, address indexed module, bool approved);

    // Emitted when a module is registered
    // module The address of the module
    event ModuleRegistered(address indexed module);

    // Emitted when the registrar address is updated
    // newRegistrar The address of the new registrar
    event RegistrarChanged(address indexed newRegistrar);

    // _registrar The initial registrar for the manager
    // _feeToken The module fee token contract to mint from upon module registration
    constructor(address _registrar, address _feeToken) {
        require(_registrar != address(0), "ZMM::must set registrar to non-zero address");
        registrar = _registrar;
        moduleFeeToken = ProtocolFeeSettings(_feeToken);
    }
    // Returns true if the user has approved a given module, false otherwise
    // _user The user to check approvals for
    // _module The module to check approvals for
    // True if the module has been approved by the user, false otherwise
    function isModuleApproved(address _user, address _module) external view returns (bool) {
        return userApprovals[_user][_module];
    }
    // Allows a user to set the approval for a given module
    // _module The module to approve
    // _approved A boolean, whether or not to approve a module
    function setApprovalForModule(address _module, bool _approved) public {
        _setApprovalForModule(_module, msg.sender, _approved);
    }
    // Sets approvals for multiple modules at once
    // _modules The list of module addresses to set approvals for
    // _approved A boolean, whether or not to approve the modules
    function setBatchApprovalForModules(address[] memory _modules, bool _approved) public {
        // Store the number of module addresses provided
        uint256 numModules = _modules.length;
        // Loop through each address
        for (uint256 i = 0; i < numModules; ) {
            // Ensure that it's a registered module and set the approval
            _setApprovalForModule(_modules[i], msg.sender, _approved);
            // Cannot overflow as array length cannot exceed uint256 max
            unchecked {
                ++i;
            }
        }
    }
    // Sets approval for a module given an EIP-712 signature
    // _module The module to approve
    // _user The user to approve the module for
    // _approved A boolean, whether or not to approve a module
    // _deadline The deadline at which point the given signature expires
    // _v The 129th byte and chain ID of the signature
    // _r The first 64 bytes of the signature
    // _s Bytes 64-128 of the signature
    function setApprovalForModuleBySig(
        address _module,
        address _user,
        bool _approved,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        require(_deadline == 0 || _deadline >= block.timestamp, "ZMM::setApprovalForModuleBySig deadline expired");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                EIP_712_DOMAIN_SEPARATOR,
                keccak256(abi.encode(SIGNED_APPROVAL_TYPEHASH, _module, _user, _approved, _deadline, sigNonces[_user]++))
            )
        );
        address recoveredAddress = ecrecover(digest, _v, _r, _s);
        require(recoveredAddress != address(0) && recoveredAddress == _user, "ZMM::setApprovalForModuleBySig invalid signature");
        _setApprovalForModule(_module, _user, _approved);
    }
    // Registers a module
    // _module The address of the module
    function registerModule(address _module) public onlyRegistrar {
        require(!moduleRegistered[_module], "ZMM::registerModule module already registered");
        moduleRegistered[_module] = true;
        moduleFeeToken.mint(registrar, _module);
        emit ModuleRegistered(_module);
    }
    // Sets the registrar for the Module Manager
    // _registrar the address of the new registrar
    function setRegistrar(address _registrar) public onlyRegistrar {
        require(_registrar != address(0), "ZMM::setRegistrar must set registrar to non-zero address");
        registrar = _registrar;
        emit RegistrarChanged(_registrar);
    }
    // Updates a module approval for a user
    // _module The address of the module
    // _user The address of the user
    // _approved Whether the user is adding or removing approval
    function _setApprovalForModule(
        address _module,
        address _user,
        bool _approved
    ) private {
        require(moduleRegistered[_module], "ZMM::must be registered module");
        userApprovals[_user][_module] = _approved;
        emit ModuleApprovalSet(msg.sender, _module, _approved);
    }
    // The EIP-155 chain id
    function _chainID() private view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }
}