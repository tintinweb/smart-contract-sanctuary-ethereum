// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IERC721Principal.sol";
import "./IERC721Surrogate.sol";

contract ERC721Surrogate is Ownable, IERC721Surrogate {
  using Strings for uint256;

  error NotSupported();

  struct Token {
    address principal;
    address surrogate;
    bool isSet;
  }

  IERC721Principal public PRINCIPAL;

  string internal _tokenURIPrefix = "https://pspices.foolprooflabs.io/metadata/?tokenId=";
  string internal _tokenURISuffix = "";
  mapping( address => int256 ) internal _balances;
  mapping( uint256 => Token ) internal _tokens;


  constructor( IERC721Principal _principal )
    Ownable(){
    PRINCIPAL = _principal;
  }


  //IERC721Surrogate :: nonpayable
  function setSurrogate( uint256 tokenId, address surrogateOwner ) public {
    address principalOwner = PRINCIPAL.ownerOf( tokenId );
    require( principalOwner == msg.sender, "ERC721Surrogate: caller is not owner" );

    if( surrogateOwner == principalOwner || surrogateOwner == address(0) ){
      _unsetSurrogate( tokenId, principalOwner );
    }
    else{
      _setSurrogate( tokenId, principalOwner, surrogateOwner );
    }
  }

  function setSurrogates( uint256[] calldata tokenIds, address[] calldata surrogates ) external {
    for( uint256 i; i < tokenIds.length; ++i ){
      setSurrogate( tokenIds[i], surrogates[i] );
    }
  }


  function syncSurrogate( uint256 tokenId ) public {
    address principalOwner = PRINCIPAL.ownerOf( tokenId );
    if( _tokens[ tokenId ].principal != principalOwner ){
      _unsetSurrogate( tokenId, principalOwner );
    }
  }

  function syncSurrogates( uint256[] calldata tokenIds ) external {
    for( uint256 i; i < tokenIds.length; ++i ){
      syncSurrogate( tokenIds[i] );
    }
  }


  function unsetSurrogate( uint256 tokenId ) public {
    address principalOwner = PRINCIPAL.ownerOf( tokenId );
    require( principalOwner == msg.sender, "ERC721Surrogate: caller is not owner" );
    _unsetSurrogate( tokenId, principalOwner );
  }

  function unsetSurrogates( uint256[] calldata tokenIds ) external {
    for( uint256 i; i < tokenIds.length; ++i ){
      unsetSurrogate( tokenIds[i] );
    }
  }


  //ERC721 :: nonpayable
  function approve(address, uint256) external pure override{
    revert NotSupported();
  }

  function safeTransferFrom( address, address to, uint256 tokenId ) external {
    setSurrogate( tokenId, to );
  }

  function safeTransferFrom( address, address to, uint256 tokenId, bytes calldata ) external {
    setSurrogate( tokenId, to );
  }

  function setBaseURI(string calldata _newPrefix, string calldata _newSuffix) external onlyOwner{
    _tokenURIPrefix = _newPrefix;
    _tokenURISuffix = _newSuffix;
  }

  function transferFrom( address, address to, uint256 tokenId ) external {
    setSurrogate( tokenId, to );
  }


  //ERC721 :: nonpayable :: not implemented
  function setApprovalForAll(address, bool) external pure {
    revert NotSupported();
  }


  //ERC721 :: view
  function balanceOf(address account) external view override returns(uint256){
    int256 balance = int256(PRINCIPAL.balanceOf(account)) + _balances[ account ];
    if( balance < 0 )
      return 0;
    else
      return uint256(balance);
  }

  function getApproved(uint256 tokenId) external view override returns(address){
    return PRINCIPAL.ownerOf( tokenId );
  }

  function isApprovedForAll(address, address) external pure override returns(bool){
    return false;
  }

  function name() external view override returns (string memory){
    return PRINCIPAL.name();
  }

  function ownerOf( uint256 tokenId ) external view override returns (address){
    address principalOwner = PRINCIPAL.ownerOf( tokenId );
    Token memory token = _tokens[ tokenId ];
    if( token.principal == principalOwner && token.isSet )
      return token.surrogate;
    else
      return principalOwner;
  }

  function supportsInterface(bytes4 interfaceId) external pure override returns(bool){
    return interfaceId == type(IERC165).interfaceId
      || interfaceId == type(IERC721).interfaceId
      || interfaceId == type(IERC721Metadata).interfaceId;
  }

  function symbol() external view override returns (string memory){
    return PRINCIPAL.symbol();
  }

  function tokenURI( uint256 tokenId ) external view override returns (string memory) {
    //require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }

  function totalSupply() external view returns (uint256){
    return PRINCIPAL.totalSupply();
  }


  //internal
  function _setSurrogate( uint256 tokenId, address principalOwner, address surrogateOwner ) internal {
    Token memory prev = _tokens[ tokenId ];
    if(prev.principal != principalOwner){
      if(prev.principal != address(0))
        ++_balances[prev.principal];
      
      --_balances[principalOwner];
    }

    if(prev.surrogate != surrogateOwner){
      if(prev.surrogate != address(0))
        --_balances[prev.surrogate];
      
      ++_balances[surrogateOwner];
    }

    _tokens[ tokenId ] = Token( principalOwner, surrogateOwner, true );
  }

  function _unsetSurrogate( uint256 tokenId, address principalOwner ) internal {
    Token memory prev = _tokens[ tokenId ];
    if(prev.isSet){
      --_balances[prev.surrogate];
      ++_balances[prev.principal];
    }

    _tokens[ tokenId ] = Token( principalOwner, principalOwner, false );
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IERC721Principal is IERC721Enumerable, IERC721Metadata {
  function owner() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IERC721Surrogate is IERC721Metadata {
  //IERC721Metadata
  function balanceOf(address owner) external view returns (uint256 balance);
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function tokenURI(uint256 tokenId) external view returns (string memory);

  //IERC721Surrogate
  function setSurrogate( uint tokenId, address surrogate ) external;
  function setSurrogates( uint[] calldata tokenIds, address[] calldata surrogates ) external;

  function syncSurrogate( uint tokenId ) external;
  function syncSurrogates( uint[] calldata tokenIds ) external;

  function unsetSurrogate( uint tokenId ) external;
  function unsetSurrogates( uint[] calldata tokenIds ) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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