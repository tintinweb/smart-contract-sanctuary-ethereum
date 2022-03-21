// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
 
interface GardenCenterFactory{

    function altOwner(address collection) external view returns(address);
    function collectionOwner(address owner, address collection) external view returns(bool);
}

interface GardenCenterOwnershipToken{

    function collectionExists(address collection) external view returns(bool);
    function tokenIdToCollection(uint256 tokenId) external view returns(address);
    function collectionToTokenId(address collection) external view returns(uint256);
}

/**
* This is a Garden Center from Rarity.Garden that allows gas efficient trading for a specific collection.
* Please read the "collection" property for which collection this instance has been created.
*
* Site:    https://rarity.garden/
* Discord: https://discord.gg/Ur8XGaurSd
* Twitter: https://t.me/raritygarden
*/
contract GardenCenter
{

    using Strings for uint256;

    struct Listing{
        uint32 price;
        address owner;
    }

    bool public initialized;
    uint16 public rate;
    address public owner;
    address public ownershipToken;
    address public collection;
    address public factory;
    mapping(uint256 => Listing) public listings;

    event Sale(address indexed _seller, address indexed _buyer, uint256 indexed _tokenId, uint256 _price);
    event Offer(address indexed _seller, uint256 indexed _tokenId, uint256 _price);
    event Removed(address indexed _owner, uint256 indexed _tokenId);

    constructor(address _collection)  {

        require(!initialized, "already initialized.");

        collection = _collection;
        owner = msg.sender;
        initialized = true;
        rate = 50;
        ownershipToken = 0xdD96c5C111294eC1C1883f171CCaF7F48b5EE4a8;
    }

    function construct(address _collection, address _sender) external {

        require(!initialized, "init: already initialized.");

        collection = _collection;
        owner = _sender;
        initialized = true;
        rate = 50;
        factory = msg.sender;
        ownershipToken = 0xdD96c5C111294eC1C1883f171CCaF7F48b5EE4a8;
    }

    function transferOwnership(address _newOwner) external{

        require(msg.sender == ownershipToken, "transferOwnership: not the ownership token");

        owner = _newOwner;
    }

    function updateRate(uint16 _rate) external{

        address _sender = msg.sender;

        require(IERC721(0x13fD344E39C30187D627e68075d6E9201163DF33).balanceOf(_sender) != 0, "updateRate: not an RG unicorn holder.");
        require(_rate <= 2500, "updateRate: max. 25% fee allowed.");
    
        address _ownershipToken = ownershipToken;
        address _collection = collection;

        bool exists = GardenCenterOwnershipToken(_ownershipToken).collectionExists(_collection);
        uint256 tokenId = GardenCenterOwnershipToken(_ownershipToken).collectionToTokenId(_collection);

        require(exists && IERC721(_ownershipToken).ownerOf(tokenId) == _sender, "updateRate: no ownership token");

        address _owner = GardenCenterFactory(factory).altOwner(_collection);

        try GardenCenterFactory(factory).collectionOwner(_sender, _collection) returns(bool isOwner){

            if(isOwner){

                _owner = _sender;
            }

        }catch{}

        require(_owner == _sender && owner == _sender, "updateRate: not the collection owner");

        rate = _rate;
    }

    receive() external payable {

        string memory _string = msg.value.toString();
        _string = fillZeros( _string );
        string memory _input = reverse( _string );
        string memory _flag = getSlice( _input, 14, 1 );

         if( strCmp( _flag, "0" ) ){

            string memory _slice = getSlice( _input, 1, 14 );
            string memory _inputOffer = reverse( _slice );

            string memory _tokenIdStr = getSlice( _inputOffer, 2, 5 );
            uint256 tokenId = toUint( _tokenIdStr );

            require(msg.sender == IERC721(collection).ownerOf(tokenId), "receive: not the owner.");

            _inputOffer = getSlice( _inputOffer, 7, 8 );
            uint256 price = toUint( _inputOffer );

            require(price != 0, "receive: price must be larger than zero.");

            listings[tokenId] = Listing( uint32(price), msg.sender );

            emit Offer(msg.sender, tokenId, price * 10**14);
        }
        else if( strCmp( _flag, "1" ) ){

            uint16 _rate = rate;
            string memory _slice = getSlice( _input, 9, 5 );
            _slice = reverse( _slice );
            uint256 tokenId = toUint( _slice );
            address _ownerOf = IERC721(collection).ownerOf(tokenId);
            Listing memory listing = listings[tokenId];

            require(listing.owner != address(0) && listing.owner == _ownerOf, "receive: invalid listing.");

            uint256 _price = listing.price;

            require(_price != 0, "receive: token not for sale.");

            _price *= 10**14;
            _slice = getSlice( _input, 15, bytes(_input).length - 14 );
            _slice = reverse( _slice );

            uint256 _value = toUint( _slice );
            _value *= 10**14;
            
            require(_value == _price, "receive: please send the exact value.");

            delete listings[tokenId];

            emit Sale(_ownerOf, msg.sender, tokenId, _price);

            uint256 _fee = _value;
            _fee *= 10**18;
            _fee /= 100;
            _fee *= _rate;
            _fee /= 10**20;

            (bool success,) = payable(_ownerOf).call{value:_value - _fee}("");
            require(success, "receive: eth transfer failed.");

            (success,) = payable(owner).call{value:_fee}("");
            require(success, "receive: owner fee transfer failed.");

            IERC721(collection).safeTransferFrom(_ownerOf, msg.sender, tokenId);

        } 
        else if( strCmp( _flag, "2" ) ){

            string memory _slice = getSlice( _input, 9, 5 );
            string memory _tokenIdStr = reverse( _slice );
            uint256 tokenId = toUint( _tokenIdStr );

            require(msg.sender == IERC721(collection).ownerOf(tokenId), "receive: not the owner.");

            delete listings[tokenId];

            emit Removed(msg.sender, tokenId);
        }
        else
        {
            revert();
        }
    }

    function getSlice(string memory source, uint startPos, uint numChars) internal pure returns (string memory) {
       uint ustartPos = uint(startPos -1);
       uint _numChars = uint(numChars);

        bytes memory sourcebytes = bytes(source);
       if (_numChars==0) {
           _numChars = ((sourcebytes.length - ustartPos) + 1);
       }
      
      bytes memory result = new bytes(_numChars);     

      for (uint i = 0; i<_numChars; i++) {
          result[i] = sourcebytes[i + ustartPos];
      }
      return string(result); 
    }

    function strCmp(string memory s1, string memory s2) internal pure returns (bool)
    {
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function fillZeros(string memory _str) internal pure returns(string memory) {

        bytes memory str = bytes(_str);

        if(str.length >= 18){

            return _str;
        }

        uint256 size = 18 - str.length;
        string memory tmp = new string(str.length + size);
        bytes memory _new = bytes(tmp);

        for(uint i = 0; i < size; i++) {

            _new[i] = "0";
        }

        for(uint i = 0; i < str.length; i++) {

            _new[i + size] = str[i];
        }

        return string(_new);
    }

    function reverse(string memory _str) internal pure returns(string memory) {
        bytes memory str = bytes(_str);
        string memory tmp = new string(str.length);
        bytes memory _reverse = bytes(tmp);

        for(uint i = 0; i < str.length; i++) {
            _reverse[str.length - i - 1] = str[i];
        }
        return string(_reverse);
    }

    function toUint(string memory numString) internal pure returns(uint) {
        uint val = 0;
        bytes   memory stringBytes = bytes(numString);
        bool leading = true;
        for (uint  i =  0; i<stringBytes.length; i++) {
            uint exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
            uint jval = uval - uint(0x30);
            uint _val =  (uint(jval) * (10**(exp-1))); 
            if(_val == 0 && leading){
                continue;
            } else if( _val != 0 && leading ){
                leading = false;
            }
            val += _val;
        }
      return val;
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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