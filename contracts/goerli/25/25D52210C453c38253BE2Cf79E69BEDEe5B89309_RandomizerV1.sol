/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

// Sources flattened with hardhat v2.12.6 https://hardhat.org

// SPDX-License-Identifier: MIXED

// File @openzeppelin/contracts/utils/introspection/[email protected]

// License-Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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


// File contracts/v1/interfaces/IERC721MultiCollection.sol

// License-Identifier: MIT
pragma solidity 0.8.17;

/// @title ERC721Multi collection interface
/// @author Particle Collection - valdi.eth
/// @notice Adds public facing and multi collection balanceOf and collectionId to tokenId functions
/// @dev This implements an optional extension of {ERC721} that adds
/// support for multiple collections and enumerability of all the
/// token ids in the contract as well as all token ids owned by each account per collection.
interface IERC721MultiCollection is IERC721 {
    /// @notice Collection ID `_collectionId` added
    event CollectionAdded(uint256 indexed collectionId);

    /// @notice New collections forbidden
    event NewCollectionsForbidden();

    // @dev Determine if a collection exists.
    function collectionExists(uint256 collectionId) external view returns (bool);

    /// @notice Balance for `owner` in `collectionId`
    function balanceOf(address owner, uint256 collectionId) external view returns (uint256);

    /// @notice Get the collection ID for a given token ID
    function tokenIdToCollectionId(uint256 tokenId) external view returns (uint256 collectionId);

    /// @notice returns the total number of collections.
    function numberOfCollections() external view returns (uint256);

    /// @dev Returns the total amount of tokens stored by the contract for `collectionId`.
    function totalSupply(uint256 collectionId) external view returns (uint256);

    /// @dev Returns a token ID owned by `owner` at a given `index` of its token list on `collectionId`.
    /// Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
    function tokenOfOwnerByIndex(address owner, uint256 index, uint256 collectionId) external view returns (uint256);

    /// @notice returns maximum size for collections.
    function MAX_COLLECTION_SIZE() external view returns (uint256);
}


// File contracts/v1/interfaces/IManifold.sol

// License-Identifier: MIT

pragma solidity 0.8.17;

/// @author: manifold.xyz

/**
 * @dev Royalty interface for creator core classes
 */
interface IManifold {

    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     *
     *  bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *
     *  => 0xbb3bafd6 = 0xbb3bafd6
     */
    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
}


// File contracts/v1/interfaces/IPRTCLCollections721V1.sol

// License-Identifier: MIT
pragma solidity 0.8.17;

/// use the Royalty Registry's IManifold interface for token royalties


/// @title Interface for Core ERC721 contract for multiple collections
/// @author Particle Collection - valdi.eth
/// @notice Manages all collections tokens
/// @dev Exposes all public functions and events needed by the Particle Collection's smart contracts
/// @dev Adheres to the ERC721 standard, ERC721MultiCollection extension and Manifold for secondary royalties
interface IPRTCLCollections721V1 is IERC721, IERC721MultiCollection, IManifold {
    /// @notice Collection ID `_collectionId` updated
    event CollectionDataUpdated(uint256 indexed _collectionId);

    /// @notice Collection ID `_collectionId` size updated
    event CollectionSizeUpdated(uint256 indexed _collectionId, uint256 _size);

    /// @notice Collection ID `_collectionId` sold through governance
    event CollectionSold(uint256 indexed _collectionId, address _buyer);

    /// @notice Collection ID `_collectionId` active
    event CollectionActive(uint256 indexed _collectionId);

    /// @notice Collection ID `_collectionId` not active
    event CollectionInactive(uint256 indexed _collectionId);

    /// @notice Collection ID `_collectionId` royalties updated
    event CollectionRoyaltiesUpdated(uint256 indexed _collectionId);

    /// @notice Collection ID `_collectionId` primary split updated
    event CollectionPrimarySplitUpdated(uint256 indexed _collectionId);

    /// @notice Collection ID `_collectionId` fully minted
    event CollectionFullyMinted(uint256 indexed _collectionId);

    /// @notice Updated base uri
    event BaseURIUpdated(string _baseURI);

    /// @notice Royalties addresses updated
    event RoyaltiesAddressesUpdated(address _FJMAddress, address _DAOAddress);

    /// @notice Randomizer contract updated
    event RandomizerUpdated(address _randomizer);

    /// @notice Collection seeds set
    event CollectionSeedsSet(uint256 _collectionId, uint24 _seed1, uint24 _seed2);

    ///
    /// Collection data
    ///

    /// @notice Artist address for collection ID `_collectionId`
    function collectionIdToArtistAddress(uint256 _collectionId) external view returns (address payable);

    /// @notice Get the primary revenue splits for a given collection ID and sale price
    /// @dev Used by minter contract
    function getPrimaryRevenueSplits(uint256 _collectionId, uint256 _price) external view
        returns (
            uint256 FJMRevenue_,
            address payable FJMAddress_,
            uint256 DAORevenue_,
            address payable DAOAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_
        );

    /// @notice Main collection data
    function collectionData(uint256 _collectionId) external view returns (
        uint256 nParticles,
        uint256 maxParticles,
        bool active,
        string memory collectionName,
        bool sold,
        uint24[] memory seeds,
        uint256 setSeedsAfterBlock
    );

    /// @notice Check if the collection can be sold
    /// @dev Used by governance contract
    function collectionCanBeSold(uint256 _collectionId) external view returns (bool);

    /// @notice Get the proceeds for a given collection ID, sale price and number of tokens
    /// @dev Used by governance contract
    function proceeds(uint256 _collectionId, uint256 _salePrice, uint256 _tokens) external view returns (uint256);

    /// @notice Get coordinates within an artwork for a given token ID
    function getCoordinate(uint256 _tokenId) external view returns (uint256);

    ///
    /// Collection interactions
    ///

    /// @notice Mark a collection as sold
    /// @dev Only callable by the governance role
    function markCollectionSold(uint256 _collectionId, address _buyer) external;
    
    /// @notice Mint a new token.
    /// Used by minter contract and BE infrastructure when handling fiat payments
    /// @dev Only callable by the minter role
    function mint(address _to, uint256 _collectionId, uint24 _amount) external returns (uint256 tokenId);

    /// @notice Burn tokensToRedeem tokens owned by `owner` in collection `_collectionId`
    /// Used when redeeming tokens for sale proceeds
    /// @dev Only callable by the governance role
    function burn(address owner, uint256 collectionId, uint256 tokensToRedeem) external returns (uint256 tokensBurnt);

    /// @notice Set the random prime seeds for a given collection ID, used to calculate token coordinates
    /// @dev Only callable by the Randomizer contract
    function setCollectionSeeds(uint256 _collectionId, uint24[2] calldata _seeds) external;
}


// File contracts/v1/interfaces/IRandomizerV1.sol

// License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Interface for the Randomizer contract version 1
/// @author Particle Collection - valdi.eth
/// @notice Sets the random prime seeds for the collection on the core ERC721 contract
interface IRandomizerV1 {
    /// @notice Sets random prime seeds for the collection
    /// @dev Only callable by the core ERC721 contract
    function setCollectionSeeds(uint256 _collectionId) external;
}


// File contracts/v1/RandomizerV1.sol

// License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;


/**
 * @title RandomizerV1
 * @notice Smart contract only used by Particle's Core ERC-721 contract to set seeds for coordinate pseudo-randomization.
 * Called only once, when the last token for a collection is minted.
 * @dev Uses a list of prime numbers to avoid collisions between tokens within the same collection.
 * @dev Based on Artblock's BasicRandomizerV2 contract: https://github.com/ArtBlocks/artblocks-contracts/blob/main/contracts/BasicRandomizerV2.sol
 *
 * Modifications to the original design:
 * - Removed ownership
 * - Added prime coordinate calculation to avoid collisions between tokens within the same collection
 * - To guarantee no collisions, all possible prime numbers used must be above the maximum number of tokens in a collection (1 million)
 * - Added block difficulty to randomness calculation
 */
contract RandomizerV1 is IRandomizerV1 {
    // Core ERC721 contract
    IPRTCLCollections721V1 public immutable collectionsContract;

    uint24[] private _primes = [1000099,1000117,1000121,1000133,1000151,1000159,1000171,1000183,1000187,1000193,1000199,1000211,1000213,1000231,1000249,1000253,1000273,1000289,1000291,1000303,1000313,1000333,1000357,1000367,1000381,1000393,1000397,1000403,1000409,1000423,1000427,1000429,1000453,1000457,1000507,1000537,1000541,1000547,1000577,1000579,1000589,1000609,1000619,1000621,1000639,1000651,1000667,1000669,1000679,1000691,1000697,1000721,1000723,1000763,1000777,1000793,1000829,1000847,1000849,1000859,1000861,1000889,1000907,1000919,1000921,1000931,1000969,1000973,1000981,1000999,1001003,1001017,1001023,1001027,1001041,1001069,1001081,1001087,1001089,1001093,1001107,1001123,1001153,1001159,1001173,1001177,1001191,1001197,1001219,1001237,1001267,1001279,1001291,1001303,1001311,1001321,1001323,1001327,1001347,1001353,1001369,1001381,1001387,1001389,1001401,1001411,1001431,1001447,1001459,1001467,1001491,1001501,1001527,1001531,1001549,1001551,1001563,1001569,1001587,1001593,1001621,1001629,1001639,1001659,1001669,1001683,1001687,1001713,1001723,1001743,1001783,1001797,1001801,1001807,1001809,1001821,1001831,1001839,1001911,1001933,1001941,1001947,1001953,1001977,1001981,1001983,1001989,1002017,1002049,1002061,1002073,1002077,1002083,1002091,1002101,1002109,1002121,1002143,1002149,1002151,1002173,1002191,1002227,1002241,1002247,1002257,1002259,1002263,1002289,1002299,1002341,1002343,1002347,1002349,1002359,1002361,1002377,1002403,1002427,1002433,1002451,1002457,1002467,1002481,1002487,1002493,1002503,1002511,1002517,1002523,1002527,1002553,1002569,1002577,1002583,1002619,1002623,1002647,1002653,1002679];

    constructor(IPRTCLCollections721V1 _collectionsContract) {
        collectionsContract = _collectionsContract;
    }

    /// @notice Sets random prime seeds for the collection
    /// @dev Only callable by the core ERC721 contract
    function setCollectionSeeds(uint256 _collectionId) external {
        require(msg.sender == address(collectionsContract), "Only collections contract may call");
        uint256 index1 = _getIndex(block.number, _collectionId);
        uint256 index2 = _getIndex(block.number - 1, _collectionId);

        collectionsContract.setCollectionSeeds(_collectionId, [_primes[index1], _primes[index2]]);
    }

    /// @notice Get a random index based on the block number, collection ID, blockhash, timestamp and difficulty.
    function _getIndex(uint256 blockNumber, uint256 _collectionId) private view returns(uint256) {
        uint256 time = block.timestamp;
        // Source of randomness after beacon chain upgrade
        // See https://eips.ethereum.org/EIPS/eip-4399
        uint256 randomness = block.difficulty;
        return uint256(keccak256(
            abi.encodePacked(
                _collectionId,
                blockNumber,
                blockhash(blockNumber - 1),
                time,
                (time % 200) + 1,
                randomness
            )
        )) % _primes.length;
    }
}