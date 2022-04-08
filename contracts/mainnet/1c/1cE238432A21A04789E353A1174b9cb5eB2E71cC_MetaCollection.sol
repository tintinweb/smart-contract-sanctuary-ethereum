// SPDX-License-Identifier: CONSTANTLY WANTS TO MAKE THE WORLD BEAUTIFUL

// ███╗   ███╗███████╗████████╗ █████╗  ██████╗ ██████╗ ██╗     ██╗     ███████╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗
// ████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██╔════╝██╔═══██╗██║     ██║     ██╔════╝██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║
// ██╔████╔██║█████╗     ██║   ███████║██║     ██║   ██║██║     ██║     █████╗  ██║        ██║   ██║██║   ██║██╔██╗ ██║
// ██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║     ██║   ██║██║     ██║     ██╔══╝  ██║        ██║   ██║██║   ██║██║╚██╗██║
// ██║ ╚═╝ ██║███████╗   ██║   ██║  ██║╚██████╗╚██████╔╝███████╗███████╗███████╗╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║
// ╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
                                                                                                                                         
// EXPERIMENTAL/CONCEPTUAL CRYPTOART METACOLLECTION by Berk aka Princess Camel aka Guerrilla Pimp Minion Bastard 
// THIS CONTRACT HOLDS DATA FOR HUNDREDELEVEN METADATA. 
// BERK WILL CONTRIBUTE TO METACOLLECTION WITH NEW COLLECTIONS.
// OWNERS OF HUNDREDELEVEN NFTS WILL BE ABLE TO CHANGE THEIR ACTIVE METADATA BETWEEN EXISTING COLLECTIONS, ANY TIME THEY WANT
// https://hundredeleven.art

// @berkozdemir

pragma solidity ^0.8.0;

interface IHandleExternal {
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function contractURI() external view returns (string memory);
}

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract MetaCollection is Ownable {

    using Strings for uint256;

    address public HundredElevenContract;

    struct Collection {
        string name;
        bool isExternal;
        address externalContract;
        string uri;
    }

    Collection[] public collections;
    mapping (uint => uint) public idToCollection;

    event tokenMetadataChanged(uint tokenId, uint collection);
    event collectionEdit(uint _index, string _name, bool _isExternal, address _address, string _uri);

    function setHundredElevenAddress(address _address) public onlyOwner {
        HundredElevenContract = _address;
    }

    function addCollection(string memory _name, bool _isExternal, address _address, string memory _uri) public onlyOwner {
        collections.push( Collection(_name,_isExternal,_address,_uri) );
        emit collectionEdit(collections.length - 1,_name,_isExternal,_address,_uri);
    }
    function editCollection(uint _index, string memory _name, bool _isExternal, address _address, string memory _uri) public onlyOwner {
        collections[_index] = Collection(_name,_isExternal,_address,_uri);
        emit collectionEdit(_index,_name,_isExternal,_address,_uri);
    }

    function collectionTotal() public view returns (uint) {
        return collections.length;
    }

    function getCollectionInfo(uint _collection) public view returns (string memory) {
        require(_collection < collections.length, "choose a valid collection!");
        Collection memory collection = collections[_collection];

        return
            collection.isExternal
                ? IHandleExternal(collection.externalContract).contractURI()
                : string(abi.encodePacked(collection.uri, "info"));
    }
    
    function getCollectionInfoAll() public view returns (string[] memory) {
        string[] memory _metadataGroup = new string[](collections.length);

        for (uint i = 0; i < collections.length; i++) {
            Collection memory _collection = collections[i];
            _collection.isExternal
                ? _metadataGroup[i] = IHandleExternal(_collection.externalContract).contractURI()
                : _metadataGroup[i] = string(abi.encodePacked(_collection.uri, "info"));
        }

        return _metadataGroup;
    }


    function getCollections() public view returns (Collection[] memory) {
        return collections;
    }

    function getIdToCollectionMulti(uint256[] memory _ids) public view returns(uint256[] memory) {
        uint256[] memory indexes = new uint256[](_ids.length);
        for (uint256 i = 0; i < indexes.length; i++) {
            indexes[i] = idToCollection[_ids[i]];
        }
        return indexes;
    }

    // THIS IS THE FUNCTION NFT CONTRACT CALL TOKENURI FOR
    // IF IT IS NOT EXTERNAL - BASEURI + TOKENID
    // IF IT IS EXTERNAL - FUNCTION CALL (TOKENURI)
    function getMetadata(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        Collection memory _collection = collections[idToCollection[tokenId]];

        return
            _collection.isExternal
                ? IHandleExternal(_collection.externalContract).tokenURI(tokenId)
                : string(abi.encodePacked(_collection.uri, tokenId.toString()));
        
    }

    // 
    function getMetadataOfIdForCollection(uint256 tokenId, uint256 collection)
        external
        view
        returns (string memory)
    {
        require(collection < collections.length, "choose a valid collection!");
        Collection memory _collection = collections[collection];

        return
            _collection.isExternal
                ? IHandleExternal(_collection.externalContract).tokenURI(tokenId)
                : string(abi.encodePacked(_collection.uri, tokenId.toString()));
    
        
    }

    function getMetadataOfIdForAllCollections(uint256 tokenId)
        external
        view
        returns (string[] memory)
    {
        string[] memory _metadataGroup = new string[](collections.length);

        for (uint i = 0; i < collections.length; i++) {
            Collection memory _collection = collections[i];
            _collection.isExternal
                ? _metadataGroup[i] = IHandleExternal(_collection.externalContract).tokenURI(tokenId)
                : _metadataGroup[i] = string(abi.encodePacked(_collection.uri, tokenId.toString()));
        }

        return _metadataGroup;
        
    }

    // OWNER OF NFTS CAN CHANGE THE METADATA OF THEIR TOKEN WITHIN EXISTING COLLECTIONS
    function changeMetadataForToken(uint[] memory tokenIds, uint[] memory _collections) public {
        // require(tokenIds.length == )
        for (uint i = 0 ; i < tokenIds.length; i++) {
            uint collection = _collections[i];
            require(collection < collections.length, "choose a valid collection!");
            uint tokenId = tokenIds[i];
            require(IERC721(HundredElevenContract).ownerOf(tokenId) == msg.sender, "Caller is not the owner");
            idToCollection[tokenId] = collection;
            emit tokenMetadataChanged(tokenId, collection);
        }
        
    }

  

    constructor(address _MetaChess) {
        addCollection("NUMZ",false,address(0),"https://berk.mypinata.cloud/ipfs/QmWWsyCUwQ6jKieUQk8gEgafCRxQsR4A8MFaTiHvs7KsyG/");
        addCollection("FreqBae",false,address(0),"https://berk.mypinata.cloud/ipfs/QmQK5WD6hcmZ5CD7oXNzN7gQ5X7YMBeCejmYbxTCi8eKLz/");
        addCollection("ri-se[t]",false,address(0),"https://berk.mypinata.cloud/ipfs/QmQkMgcqUyaNJVK551mFmDtfGhXGaoeF111s13gig7X9i5/");
        addCollection("ATAKOI",false,address(0),"https://berk.mypinata.cloud/ipfs/QmPY9pTNru8SvcgrQJVgrwnhGBZaPNa26HwepG4jHnTQPA/");
        addCollection("MELLOLOVE",false,address(0),"https://berk.mypinata.cloud/ipfs/QmYgSwobV6qSRVw6dwCcv7iXq4QXe7oTde5YdMpLwzP8cQ/");
        addCollection("MetaChess",true,_MetaChess,"");

        for (uint i=1; i <= 111; i++) {
            idToCollection[i] = i % 6;
        }

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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