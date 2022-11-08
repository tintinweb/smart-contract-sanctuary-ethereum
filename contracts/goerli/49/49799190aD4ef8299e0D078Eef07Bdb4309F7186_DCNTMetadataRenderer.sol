// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 ______   _______  _______  _______  _       _________
(  __  \ (  ____ \(  ____ \(  ____ \( (    /|\__   __/
| (  \  )| (    \/| (    \/| (    \/|  \  ( |   ) (
| |   ) || (__    | |      | (__    |   \ | |   | |
| |   | ||  __)   | |      |  __)   | (\ \) |   | |
| |   ) || (      | |      | (      | | \   |   | |
| (__/  )| (____/\| (____/\| (____/\| )  \  |   | |
(______/ (_______/(_______/(_______/|/    )_)   )_(

*/

/// ============ Imports ============
import "./interfaces/IMetadataRenderer.sol";
import {MusicMetadata} from "./utils/MusicMetadata.sol";
import {Credits} from "./utils/Credits.sol";
import {ISharedNFTLogic} from "./interfaces/ISharedNFTLogic.sol";
import "erc721a/contracts/IERC721A.sol";

/// @notice DCNTMetadataRenderer for editions support
contract DCNTMetadataRenderer is IMetadataRenderer, MusicMetadata, Credits {
  /// @notice Reference to Shared NFT logic library
  ISharedNFTLogic public immutable sharedNFTLogic;

  /// @notice Constructor for library
  /// @param _sharedNFTLogic reference to shared NFT logic library
  constructor(ISharedNFTLogic _sharedNFTLogic) {
    sharedNFTLogic = _sharedNFTLogic;
  }

  /// @notice Default initializer for edition data from a specific contract
  /// @param data data to init with
  function initializeWithData(bytes memory data) external {
    // data format: description, imageURI, animationURI
    (
      string memory description,
      string memory imageURI,
      string memory animationURI
    ) = abi.decode(data, (string, string, string));

    songMetadatas[msg.sender].songPublishingData.description = description;
    songMetadatas[msg.sender].song.audio.losslessAudio = animationURI;
    songMetadatas[msg.sender].song.artwork.artworkUri = imageURI;

    emit EditionInitialized({
      target: msg.sender,
      description: description,
      imageURI: imageURI,
      animationURI: animationURI
    });
  }

  /// @notice Update everything in 1 transaction.
  /// @param target target for contract to update metadata for
  /// @param _songMetadata song metadata
  /// @param _projectMetadata project metadata
  /// @param _tags tags
  /// @param _credits credits for the track
  function bulkUpdate(
    address target,
    SongMetadata memory _songMetadata,
    ProjectMetadata memory _projectMetadata,
    string[] memory _tags,
    Credit[] calldata _credits
  ) external requireSenderAdmin(target) {
    songMetadatas[target] = _songMetadata;
    projectMetadatas[target] = _projectMetadata;
    updateTags(target, _tags);
    updateCredits(target, _credits);

    emit SongUpdated({
      target: target,
      sender: msg.sender,
      songMetadata: _songMetadata,
      projectMetadata: _projectMetadata,
      tags: _tags,
      credits: _credits
    });
  }

  /// @notice Contract URI information getter
  /// @return contract uri (if set)
  function contractURI() external view override returns (string memory) {
    address target = msg.sender;
    bytes memory imageSpace = bytes("");
    if (bytes(songMetadatas[target].song.artwork.artworkUri).length > 0) {
      imageSpace = abi.encodePacked(
        '", "image": "',
        songMetadatas[target].song.artwork.artworkUri
      );
    }
    bool isMusicNft = bytes(
      songMetadatas[target].song.audio.songDetails.audioQuantitative.audioMimeType
    ).length > 0;
    string memory name = isMusicNft
      ? songMetadatas[target].songPublishingData.title
      : IERC721A(target).name();
    return
      string(
        sharedNFTLogic.encodeMetadataJSON(
          abi.encodePacked(
            '{"name": "',
            name,
            '", "description": "',
            songMetadatas[target].songPublishingData.description,
            imageSpace,
            '"}'
          )
        )
      );
  }

  /// @notice Token URI information getter
  /// @param tokenId to get uri for
  /// @return contract uri (if set)
  function tokenURI(uint256 tokenId)
    external
    view
    override
    returns (string memory)
  {
    address target = msg.sender;

    return tokenURITarget(tokenId, target);
  }

  /// @notice Token URI information getter
  /// @param tokenId to get uri for
  /// @return contract uri (if set)
  function tokenURITarget(uint256 tokenId, address target)
    public
    view
    returns (string memory)
  {
    return
      sharedNFTLogic.createMetadataEdition({
        name: IERC721A(target).name(),
        tokenOfEdition: tokenId,
        songMetadata: songMetadatas[target],
        projectMetadata: projectMetadatas[target],
        credits: credits[target],
        tags: trackTags[target]
      });
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetadataRenderer {
  function tokenURI(uint256) external view returns (string memory);

  function contractURI() external view returns (string memory);

  function initializeWithData(bytes memory initData) external;

  /// @notice Storage for token edition information
  struct TokenEditionInfo {
    string description;
    string imageURI;
    string animationURI;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 ______   _______  _______  _______  _       _________
(  __  \ (  ____ \(  ____ \(  ____ \( (    /|\__   __/
| (  \  )| (    \/| (    \/| (    \/|  \  ( |   ) (
| |   ) || (__    | |      | (__    |   \ | |   | |
| |   | ||  __)   | |      |  __)   | (\ \) |   | |
| |   ) || (      | |      | (      | | \   |   | |
| (__/  )| (____/\| (____/\| (____/\| )  \  |   | |
(______/ (_______/(_______/(_______/|/    )_)   )_(

*/

/// ============ Imports ============
import {IOnChainMetadata} from "../interfaces/IOnChainMetadata.sol";
import {MetadataRenderAdminCheck} from "./MetadataRenderAdminCheck.sol";

contract MusicMetadata is MetadataRenderAdminCheck, IOnChainMetadata {
  mapping(address => SongMetadata) public songMetadatas;
  mapping(address => ProjectMetadata) public projectMetadatas;
  mapping(address => string[]) internal trackTags;

  /// @notice Update media URIs
  /// @param target target for contract to update metadata for
  /// @param imageURI new image uri address
  /// @param animationURI new animation uri address
  function updateMediaURIs(
    address target,
    string memory imageURI,
    string memory animationURI
  ) external requireSenderAdmin(target) {
    songMetadatas[target].song.artwork.artworkUri = imageURI;
    songMetadatas[target].song.audio.losslessAudio = animationURI;
    emit MediaURIsUpdated({
      target: target,
      sender: msg.sender,
      imageURI: imageURI,
      animationURI: animationURI
    });
  }

  /// @notice Admin function to update description
  /// @param target target description
  /// @param newDescription new description
  function updateDescription(address target, string memory newDescription)
    external
    requireSenderAdmin(target)
  {
    songMetadatas[target].songPublishingData.description = newDescription;

    emit DescriptionUpdated({
      target: target,
      sender: msg.sender,
      newDescription: newDescription
    });
  }

  /// @notice Admin function to update description
  /// @param target target description
  /// @param tags The tags of the track
  function updateTags(address target, string[] memory tags)
    public
    requireSenderAdmin(target)
  {
    trackTags[target] = tags;

    emit TagsUpdated({target: target, sender: msg.sender, tags: tags});
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 ______   _______  _______  _______  _       _________
(  __  \ (  ____ \(  ____ \(  ____ \( (    /|\__   __/
| (  \  )| (    \/| (    \/| (    \/|  \  ( |   ) (
| |   ) || (__    | |      | (__    |   \ | |   | |
| |   | ||  __)   | |      |  __)   | (\ \) |   | |
| |   ) || (      | |      | (      | | \   |   | |
| (__/  )| (____/\| (____/\| (____/\| )  \  |   | |
(______/ (_______/(_______/(_______/|/    )_)   )_(

*/

/// ============ Imports ============
import {IOnChainMetadata} from "../interfaces/IOnChainMetadata.sol";
import {MetadataRenderAdminCheck} from "./MetadataRenderAdminCheck.sol";

contract Credits is MetadataRenderAdminCheck, IOnChainMetadata {
  /// @notice Array of credits
  mapping(address => Credit[]) internal credits;

  /// @notice Admin function to update description
  /// @param target target description
  /// @param _credits credits for the track
  function updateCredits(address target, Credit[] calldata _credits)
    public
    requireSenderAdmin(target)
  {
    delete credits[target];

    for (uint256 i = 0; i < _credits.length; i++) {
      credits[target].push(
        Credit(_credits[i].name, _credits[i].collaboratorType)
      );
    }

    emit CreditsUpdated({
      target: target,
      sender: msg.sender,
      credits: _credits
    });
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 ______   _______  _______  _______  _       _________
(  __  \ (  ____ \(  ____ \(  ____ \( (    /|\__   __/
| (  \  )| (    \/| (    \/| (    \/|  \  ( |   ) (
| |   ) || (__    | |      | (__    |   \ | |   | |
| |   | ||  __)   | |      |  __)   | (\ \) |   | |
| |   ) || (      | |      | (      | | \   |   | |
| (__/  )| (____/\| (____/\| (____/\| )  \  |   | |
(______/ (_______/(_______/(_______/|/    )_)   )_(

*/

/// ============ Imports ============
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IOnChainMetadata.sol";

/// Shared NFT logic for rendering metadata associated with editions
/// @dev Can safely be used for generic base64Encode and numberToString functions
contract ISharedNFTLogic is IOnChainMetadata {
  /// Generate edition metadata from storage information as base64-json blob
  /// Combines the media data and metadata
  /// @param name the token name
  /// @param tokenOfEdition Token ID for specific token
  /// @param songMetadata song metadata
  /// @param projectMetadata project metadata
  /// @param credits The credits of the track
  /// @param tags The tags of the track
  function createMetadataEdition(
    string memory name,
    uint256 tokenOfEdition,
    SongMetadata memory songMetadata,
    ProjectMetadata memory projectMetadata,
    Credit[] memory credits,
    string[] memory tags
  ) external pure returns (string memory) {}

  /// Encodes the argument json bytes into base64-data uri format
  /// @param json Raw json to base64 and turn into a data-uri
  function encodeMetadataJSON(bytes memory json)
    public
    pure
    returns (string memory)
  {}
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOnChainMetadata {
  /// @notice Lyrics updated for this edition
  event SongUpdated(
    address target,
    address sender,
    SongMetadata songMetadata,
    ProjectMetadata projectMetadata,
    string[] tags,
    Credit[] credits
  );

  /// @notice AudioQuantitativeUpdated updated for this edition
  /// @dev admin function indexer feedback
  event AudioQuantitativeUpdated(
    address indexed target,
    address sender,
    string key,
    uint256 bpm,
    uint256 duration,
    string audioMimeType,
    uint256 trackNumber
  );

  /// @notice AudioQualitative updated for this edition
  /// @dev admin function indexer feedback
  event AudioQualitativeUpdated(
    address indexed target,
    address sender,
    string license,
    string externalUrl,
    string isrc,
    string genre
  );

  /// @notice Lyrics updated for this edition
  event LyricsUpdated(
    address target,
    address sender,
    string lyrics,
    string lyricsNft
  );

  /// @notice Artwork updated for this edition
  /// @dev admin function indexer feedback
  event ArtworkUpdated(
    address indexed target,
    address sender,
    string artworkUri,
    string artworkMimeType,
    string artworkNft
  );

  /// @notice Visualizer updated for this edition
  /// @dev admin function indexer feedback
  event VisualizerUpdated(
    address indexed target,
    address sender,
    string artworkUri,
    string artworkMimeType,
    string artworkNft
  );

  /// @notice ProjectMetadata updated for this edition
  /// @dev admin function indexer feedback
  event ProjectArtworkUpdated(
    address indexed target,
    address sender,
    string artworkUri,
    string artworkMimeType,
    string artworkNft
  );

  /// @notice Tags updated for this edition
  /// @dev admin function indexer feedback
  event TagsUpdated(address indexed target, address sender, string[] tags);

  /// @notice Credit updated for this edition
  /// @dev admin function indexer feedback
  event CreditsUpdated(
    address indexed target,
    address sender,
    Credit[] credits
  );

  /// @notice ProjectMetadata updated for this edition
  /// @dev admin function indexer feedback
  event ProjectPublishingDataUpdated(
    address indexed target,
    address sender,
    string title,
    string description,
    string recordLabel,
    string publisher,
    string locationCreated,
    string releaseDate,
    string projectType,
    string upc
  );

  /// @notice PublishingData updated for this edition
  /// @dev admin function indexer feedback
  event PublishingDataUpdated(
    address indexed target,
    address sender,
    string title,
    string description,
    string recordLabel,
    string publisher,
    string locationCreated,
    string releaseDate
  );

  /// @notice losslessAudio updated for this edition
  /// @dev admin function indexer feedback
  event LosslessAudioUpdated(
    address indexed target,
    address sender,
    string losslessAudio
  );

  /// @notice Description updated for this edition
  /// @dev admin function indexer feedback
  event DescriptionUpdated(
    address indexed target,
    address sender,
    string newDescription
  );

  /// @notice Artist updated for this edition
  /// @dev admin function indexer feedback
  event ArtistUpdated(address indexed target, address sender, string newArtist);

  /// @notice Event for updated Media URIs
  event MediaURIsUpdated(
    address indexed target,
    address sender,
    string imageURI,
    string animationURI
  );

  /// @notice Event for a new edition initialized
  /// @dev admin function indexer feedback
  event EditionInitialized(
    address indexed target,
    string description,
    string imageURI,
    string animationURI
  );

  /// @notice Storage for SongMetadata
  struct SongMetadata {
    SongContent song;
    PublishingData songPublishingData;
  }

  /// @notice Storage for SongContent
  struct SongContent {
    Audio audio;
    Artwork artwork;
    Artwork visualizer;
  }

  /// @notice Storage for SongDetails
  struct SongDetails {
    string artistName;
    AudioQuantitative audioQuantitative;
    AudioQualitative audioQualitative;
  }

  /// @notice Storage for Audio
  struct Audio {
    string losslessAudio; // ipfs://{cid} or arweave
    SongDetails songDetails;
    Lyrics lyrics;
  }

  /// @notice Storage for AudioQuantitative
  struct AudioQuantitative {
    string key; // C / A# / etc
    uint256 bpm; // 120 / 60 / 100
    uint256 duration; // 240 / 60 / 120
    string audioMimeType; // audio/wav
    uint256 trackNumber; // 1
  }

  /// @notice Storage for AudioQualitative
  struct AudioQualitative {
    string license; // CC0
    string externalUrl; // Link to your project website
    string isrc; // CC-XXX-YY-NNNNN
    string genre; // Rock / Pop / Metal / Hip-Hop / Electronic / Classical / Jazz / Folk / Reggae / Other
  }

  /// @notice Storage for Artwork
  struct Artwork {
    string artworkUri; // The uri of the artwork (ipfs://<CID>)
    string artworkMimeType; // The mime type of the artwork
    string artworkNft; // The NFT of the artwork (caip19)
  }

  /// @notice Storage for Lyrics
  struct Lyrics {
    string lyrics;
    string lyricsNft;
  }

  /// @notice Storage for PublishingData
  struct PublishingData {
    string title;
    string description;
    string recordLabel; // Sony / Universal / etc
    string publisher; // Sony / Universal / etc
    string locationCreated;
    string releaseDate; // 2020-01-01
  }

  /// @notice Storage for ProjectMetadata
  struct ProjectMetadata {
    PublishingData publishingData;
    Artwork artwork;
    string projectType; // Single / EP / Album
    string upc; // 03600029145
  }

  /// @notice Storage for Credit
  struct Credit {
    string name;
    string collaboratorType;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MetadataRenderAdminCheck {
  error Access_OnlyAdmin();

  /// @notice Modifier to require the sender to be an admin
  /// @param target address that the user wants to modify
  modifier requireSenderAdmin(address target) {
    if (target != msg.sender && Ownable(target).owner() != msg.sender) {
      revert Access_OnlyAdmin();
    }

    _;
  }
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