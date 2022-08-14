/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// File: contracts\IERC721W.sol

pragma solidity ^0.8.0;

/* Blue chip NFT (BCN) is the NFT that supported ERC721 and world famous.
* BCN's holders can mint new NFT through this protocol.
* The new NFT needs to specify the supported BCN's contract addresses and each address's quantity of mintable.
* The address holding the BCN can mint the same amount of new NFT.
* The tokenId used for each mint will be recorded and cannot be used again.
*/
interface IERC721W{
    event MintByBCN(uint256 indexed tokenId, address indexed to, address indexed bcn, uint256 bcnTokenId);
    
    // Get the length of supported BCN list
    // Returns length: The length of supported BCN list
    function lengthOfSupportedBcn() external view returns(uint256 length);
    
    // Get a list of supported BCN addresses
    // Param index: The index in supported BCN list
    // Returns bcn: The BCN address by the index
    function supportedBcnByIndex(uint256 index) external view returns(address bcn);
    
    // Get whether the BCN is supported
    // Param bcn: The BCN address
    // Returns supported: whether the BCN is supported
    function isBcnSupported(address bcn) external view returns(bool supported);
    
    // Get the number of new NFTs that can be mint by one blue chip NFT
    // Param bcn: The BCN address
    // Return total: The total number of new NFTs that can be mint by the blue chip NFT
    // Return remaining: The remaining number of new NFTs that can be mint by the blue chip NFT
    function mintNumberOfBcn(address bcn) external view returns(uint256 total, uint256 remaining);
    
    // Get whether the tokenId of the BCN is used
    // Param bcn & bcnTokenId: The address and tokenId of BCN to be queried
    // Return used: true means used
    function isTokenMintByBcn(address bcn, uint256 bcnTokenId) external view returns(bool used);
    
    // Mint new nft By BCN
    // Param tokenId: New NFT's tokenIf to be mint
    // Param bcn & bcnTokenId: The address and tokenId of BCN to be queried
    // Requirement: tokenId is not mint
    // Requirement: bcn's bcnTokenId is not use
    // Notice: when the call is successful, record bcnTokenId of bcn is used
    // Notice: when the call is successful, emit MintByBCN event
    // Notice: when the call is successful, update the remaining number of mintable 
    function mintByBcn(uint256 tokenId, address bcn, uint256 bcnTokenId) external;
}

// File: contracts\EnumerableSet.sol

// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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

// File: contracts\ERC721W.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC721{
    function ownerOf(uint256 tokenId) external view returns(address);
}

interface IERC721TokenReceiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) external returns(bytes4);
}

contract ERC721W is IERC721W{
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed _owner, address indexed operator, uint256 indexed tokenId);
    event ApprovalForAll(address indexed _owner, address indexed operator, bool approved);
    
    address public owner;
    string public name;
    string public symbol;
    string private uri;
    uint256 public totalSupply;
    mapping(address => EnumerableSet.UintSet) private _userTokenIds;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    EnumerableSet.AddressSet private _supportedBcns;
    mapping(address => uint256) private _supplyOfBcn;
    mapping(address => uint256) private _remaingOfBcn;
    mapping(address => mapping(uint256 => bool)) private _isTokenMintByBcn;
    
    modifier onlyOwner(){
        require(msg.sender == owner, "ERC721:onlyOwner");
        _;
    }
    
    constructor(string memory _name, string memory _symbol, string memory _uri){
        name = _name;
        symbol = _symbol;
        uri = _uri;
        owner = msg.sender;
    }
    
    function setOwner(address _owner) external onlyOwner{
        owner = _owner;
    }
    
    function setURI(string memory _uri) external onlyOwner{
        uri = _uri;
    }
    
    function supportsInterface(bytes4 id) external pure returns (bool){
        return id == 0x01ffc9a7 || id == 0x80ac58cd || id == 0x5b5e139f || id == 0x780e9d63;
    }
    
    function _toString(uint256 value) internal pure returns(string memory){
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
    
    function tokenURI(uint256 tokenId) external view returns (string memory){
        return string(abi.encodePacked(uri, _toString(tokenId)));
    }
    
    function tokenByIndex(uint256 index) external pure returns (uint256){
        return index;
    }
    
    function tokenOfOwnerByIndex(address _owner, uint256 index) external view returns (uint256){
        return _userTokenIds[_owner].at(index);
    }
    
    function balanceOf(address _owner) external view returns (uint256){
        return _userTokenIds[_owner].length();
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public{
        require(from != address(0) && to != address(0) && from != to, "ERC721:invalid address");
        require(ownerOf[tokenId] == from, "ERC721:not owner");
        require(msg.sender == from || isApprovedForAll[from][msg.sender] || getApproved[tokenId] == msg.sender, "ERC721:onlyOwnerOrApproved");
        if(getApproved[tokenId] != address(0)){
            delete getApproved[tokenId];
        }
        _userTokenIds[from].remove(tokenId);
        _userTokenIds[to].add(tokenId);
        ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public{
        transferFrom(from, to, tokenId);
        if(to.code.length > 0){
            require(IERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) == IERC721TokenReceiver.onERC721Received.selector, "ERC721:not safe");
        }
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) external{
        safeTransferFrom(from, to, tokenId, "0x");
    }
    
    function approve(address to, uint256 tokenId) external{
        address _owner = ownerOf[tokenId];
        require(_owner != address(0), "ERC721:token not exists");
        require(msg.sender == _owner || isApprovedForAll[_owner][msg.sender], "ERC721:notOwnerOrApproved");
        getApproved[tokenId] = to;
        emit Approval(_owner, to, tokenId);
    }
    
    function setApprovalForAll(address operator, bool approved) external{
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function _mint(address to) internal {
        _userTokenIds[to].add(totalSupply);
        ownerOf[totalSupply] = to;
        emit Transfer(address(0), to, totalSupply++);
    }
    
    function lengthOfSupportedBcn() external override view returns(uint256 length){
        return _supportedBcns.length();
    }
    
    function supportedBcnByIndex(uint256 index) external override view returns(address bcn){
        return _supportedBcns.at(index);
    }
    
    function mintNumberOfBcn(address bcn) external override view returns(uint256 total, uint256 remaining){
        return (_supplyOfBcn[bcn], _remaingOfBcn[bcn]);
    }
    
    function isBcnSupported(address bcn) external override view returns(bool supported){
        return _supportedBcns.contains(bcn);
    }
    
    function isTokenMintByBcn(address bcn, uint256 bcnTokenId) external override view returns(bool used){
        used = _isTokenMintByBcn[bcn][bcnTokenId];
    }
    
    function mintByBcn(uint256 tokenId, address bcn, uint256 bcnTokenId) external override{
        address to = IERC721(bcn).ownerOf(bcnTokenId);
        require(to != address(0), "ERC721W:bcnTokenId not exists");
        require(!_isTokenMintByBcn[bcn][bcnTokenId], "ERC721W:bcnTokenId is used");
        require(_supportedBcns.contains(bcn), "ERC721W:not supported bcn");
        _isTokenMintByBcn[bcn][bcnTokenId] = true;
        _remaingOfBcn[bcn]--;
        emit MintByBCN(totalSupply, to, bcn, bcnTokenId);
        _mint(to);
    }
    
    function enableBcn(address bcn, bool enable) external onlyOwner{
        if(enable){
            require(_supportedBcns.add(bcn), "ERC721W:alread enable");
        }else{
            require(_supportedBcns.remove(bcn), "ERC721W:alread disable");
        }
    }
    
    function setBcn(address bcn, uint256 quantity, bool minus) external onlyOwner{
        if(minus){
            _supplyOfBcn[bcn] -= quantity;
            _remaingOfBcn[bcn] -= quantity;
        }else{
            _supplyOfBcn[bcn] += quantity;
            _remaingOfBcn[bcn] += quantity;
        }
    }
}