// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ArtblocksOracleMessages.sol";
import "./ITraitOracle.sol";
import "./Popcnt.sol";
import "./SignatureChecker.sol";

enum TraitType {
    /// A trait that represents an Art Blocks project, like "Chromie Squiggle"
    /// or "Archetype". Keyed by project ID, a small non-negative integer.
    PROJECT,
    /// A trait that represents a feature within a particular Art Blocks
    /// project, like a specific color palette of Archetype ("Palette: Paddle")
    /// or a specific body type of Algobot ("Bodywork: Wedge"). Keyed by
    /// project ID (a small non-negative integer) and human-readable trait name
    /// (a string).
    FEATURE
}

/// Static information about a project trait (immutable once written).
struct ProjectInfo {
    /// The ERC-721 contract for tokens belonging to this project.
    IERC721 tokenContract;
    /// The integer index of this project: e.g., `0` for "Chromie Squiggle" or
    /// `23` for "Archetype".
    uint32 projectId;
    /// The number of tokens in this project, like `600`.
    uint32 size;
    /// The human-readable name of this project, like "Archetype".
    string name;
}

/// Static information about a feature trait (immutable once written).
struct FeatureInfo {
    /// The ERC-721 contract for tokens belonging to this trait's project.
    IERC721 tokenContract;
    /// The integer index of the project that this feature is a part of: e.g.,
    /// for the "Palette: Paddle" trait on Archetypes, this value is `23`,
    /// which is the ID of the Archetype project.
    uint32 projectId;
    /// The string name of the feature, like "Palette".
    string featureName;
    /// The value of the trait within the feature, like "Paddle".
    string traitValue;
}

/// The current state of a feature trait, updated as more memberships and
/// finalizations are recorded.
struct FeatureMetadata {
    /// The number of distinct token IDs that currently have this trait: i.e.,
    /// the sum of the population counts of `featureMembers[_t][_i]` for each
    /// `_i`.
    uint32 currentSize;
    /// Token indices `0` (inclusive) through `numFinalized` (exclusive),
    /// relative to the start of the project, have their memberships in this
    /// trait finalized.
    uint32 numFinalized;
    /// A hash accumulator of updates to this trait. Initially `0`; updated for
    /// each new message `_msg` by ABI-encoding `(log, _msg.structHash())`,
    /// applying `keccak256`, and truncating the result back to `bytes24`.
    bytes24 log;
}

contract ArtblocksOracle is IERC165, ITraitOracle, Ownable {
    using ArtblocksOracleMessages for SetProjectInfoMessage;
    using ArtblocksOracleMessages for SetFeatureInfoMessage;
    using ArtblocksOracleMessages for UpdateTraitMessage;
    using Popcnt for uint256;

    event OracleSignerChanged(address indexed oracleSigner);
    event ProjectInfoSet(
        bytes32 indexed traitId,
        uint32 indexed projectId,
        string name,
        uint32 version,
        uint32 size,
        IERC721 tokenContract
    );
    event FeatureInfoSet(
        bytes32 indexed traitId,
        uint32 indexed projectId,
        // `nameAndValue` is `featureName + ": " + traitValue`, for indexing.
        string indexed nameAndValue,
        string featureName,
        string traitValue,
        uint32 version,
        IERC721 tokenContract
    );
    event TraitUpdated(
        bytes32 indexed traitId,
        uint32 newSize,
        uint32 newNumFinalized,
        bytes24 newLog
    );

    string constant ERR_ALREADY_EXISTS = "ArtblocksOracle: ALREADY_EXISTS";
    string constant ERR_IMMUTABLE = "ArtblocksOracle: IMMUTABLE";
    string constant ERR_INVALID_ARGUMENT = "ArtblocksOracle: INVALID_ARGUMENT";
    string constant ERR_INVALID_STATE = "ArtblocksOracle: INVALID_STATE";
    string constant ERR_UNAUTHORIZED = "ArtblocksOracle: UNAUTHORIZED";

    bytes32 constant TYPEHASH_DOMAIN_SEPARATOR =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    bytes32 constant DOMAIN_SEPARATOR_NAME_HASH = keccak256("ArtblocksOracle");

    /// Art Blocks gives each project a token space of 1 million IDs. Most IDs
    /// in this space are not actually used, but a token's ID floor-divided by
    /// this stride gives the project ID, and the token ID modulo this stride
    /// gives the token index within the project.
    uint256 constant PROJECT_STRIDE = 10**6;

    address public oracleSigner;

    mapping(bytes32 => ProjectInfo) public projectTraitInfo;
    mapping(bytes32 => FeatureInfo) public featureTraitInfo;

    /// Append-only relation on `TraitId * TokenId`, for feature traits only.
    /// (Project trait membership is determined from the token ID itself.)
    ///
    /// Encoded by packing 256 token indices into each word: if a token has
    /// index `_i` in its project (i.e., `_i == _tokenId % PROJECT_STRIDE`),
    /// then the token has trait `_t` iff the `_i % 256`th bit (counting from
    /// the LSB) of `featureMembers[_t][_i / 256]` is `1`.
    mapping(bytes32 => mapping(uint256 => uint256)) featureMembers;
    /// Metadata for each feature trait; see struct definition. Not defined for
    /// project traits.
    mapping(bytes32 => FeatureMetadata) public featureMetadata;

    // EIP-165 interface discovery boilerplate.
    function supportsInterface(bytes4 _interfaceId)
        external
        pure
        override
        returns (bool)
    {
        if (_interfaceId == type(ITraitOracle).interfaceId) return true;
        if (_interfaceId == type(IERC165).interfaceId) return true;
        return false;
    }

    function setOracleSigner(address _oracleSigner) external onlyOwner {
        oracleSigner = _oracleSigner;
        emit OracleSignerChanged(_oracleSigner);
    }

    function _requireOracleSignature(
        bytes32 _structHash,
        bytes memory _signature,
        SignatureKind _kind
    ) internal view {
        address _signer = SignatureChecker.recover(
            _computeDomainSeparator(),
            _structHash,
            _signature,
            _kind
        );
        require(_signer == oracleSigner, ERR_UNAUTHORIZED);
    }

    function _computeDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TYPEHASH_DOMAIN_SEPARATOR,
                    DOMAIN_SEPARATOR_NAME_HASH,
                    block.chainid,
                    address(this)
                )
            );
    }

    function setProjectInfo(
        SetProjectInfoMessage memory _msg,
        bytes memory _signature,
        SignatureKind _signatureKind
    ) external {
        _requireOracleSignature(_msg.structHash(), _signature, _signatureKind);

        // Input fields must be non-empty (but project ID may be 0).
        require(_msg.size > 0, ERR_INVALID_ARGUMENT);
        require(
            _msg.tokenContract != IERC721(address(0)),
            ERR_INVALID_ARGUMENT
        );
        require(!_stringEmpty(_msg.projectName), ERR_INVALID_ARGUMENT);

        // Project must not already exist.
        bytes32 _traitId = projectTraitId(_msg.projectId, _msg.version);
        require(projectTraitInfo[_traitId].size == 0, ERR_ALREADY_EXISTS);

        projectTraitInfo[_traitId] = ProjectInfo({
            projectId: _msg.projectId,
            name: _msg.projectName,
            size: _msg.size,
            tokenContract: _msg.tokenContract
        });
        emit ProjectInfoSet({
            traitId: _traitId,
            projectId: _msg.projectId,
            name: _msg.projectName,
            version: _msg.version,
            size: _msg.size,
            tokenContract: _msg.tokenContract
        });
    }

    function setFeatureInfo(
        SetFeatureInfoMessage memory _msg,
        bytes memory _signature,
        SignatureKind _signatureKind
    ) external {
        _requireOracleSignature(_msg.structHash(), _signature, _signatureKind);

        // Input fields must be non-empty (but project ID may be 0).
        require(
            _msg.tokenContract != IERC721(address(0)),
            ERR_INVALID_ARGUMENT
        );
        require(!_stringEmpty(_msg.featureName), ERR_INVALID_ARGUMENT);
        require(!_stringEmpty(_msg.traitValue), ERR_INVALID_ARGUMENT);

        // Feature must not already exist.
        bytes32 _traitId = featureTraitId(
            _msg.projectId,
            _msg.featureName,
            _msg.traitValue,
            _msg.version
        );
        require(
            featureTraitInfo[_traitId].tokenContract == IERC721(address(0)),
            ERR_ALREADY_EXISTS
        );

        featureTraitInfo[_traitId] = FeatureInfo({
            projectId: _msg.projectId,
            featureName: _msg.featureName,
            traitValue: _msg.traitValue,
            tokenContract: _msg.tokenContract
        });
        emit FeatureInfoSet({
            traitId: _traitId,
            projectId: _msg.projectId,
            nameAndValue: string(abi.encodePacked(_msg.featureName, ": ", _msg.traitValue)),
            featureName: _msg.featureName,
            traitValue: _msg.traitValue,
            version: _msg.version,
            tokenContract: _msg.tokenContract
        });
    }

    function updateTrait(
        UpdateTraitMessage memory _msg,
        bytes memory _signature,
        SignatureKind _signatureKind
    ) external {
        bytes32 _structHash = _msg.structHash();
        _requireOracleSignature(_structHash, _signature, _signatureKind);

        bytes32 _traitId = _msg.traitId;
        // Feature must exist.
        require(
            featureTraitInfo[_traitId].tokenContract != IERC721(address(0)),
            ERR_INVALID_ARGUMENT
        );
        FeatureMetadata memory _oldMetadata = featureMetadata[_traitId];

        // Check whether we're increasing the number of finalized tokens.
        // If so, the current trait log must match the given one.
        uint32 _newNumFinalized = _oldMetadata.numFinalized;
        uint32 _msgNumFinalized = uint32(uint256(_msg.finalization));
        if (_msgNumFinalized > _newNumFinalized) {
            _newNumFinalized = _msgNumFinalized;
            bytes24 _expectedLastLog = bytes24(_msg.finalization);
            require(_oldMetadata.log == _expectedLastLog, ERR_INVALID_STATE);
        }

        // Add any new token memberships.
        uint32 _newSize = _oldMetadata.currentSize;
        for (uint256 _i = 0; _i < _msg.words.length; _i++) {
            TraitMembershipWord memory _word = _msg.words[_i];
            uint256 _wordIndex = _word.wordIndex;

            uint256 _oldWord = featureMembers[_traitId][_wordIndex];
            uint256 _newTokensMask = _word.mask & ~_oldWord;

            // It's an error to update any tokens in this word that are already
            // finalized (i.e., were finalized prior to this message).
            uint256 _errantUpdatesMask = _newTokensMask &
                _finalizedTokensMask(_oldMetadata.numFinalized, _wordIndex);
            require(_errantUpdatesMask == 0, ERR_IMMUTABLE);

            featureMembers[_traitId][_wordIndex] = _oldWord | _newTokensMask;
            _newSize += uint32(_newTokensMask.popcnt());
        }

        // If this message didn't add or finalize any new memberships, we don't
        // want to update the hash log *or* emit an event.
        bool _wasNoop = (_newSize == _oldMetadata.currentSize) &&
            (_newNumFinalized == _oldMetadata.numFinalized);
        if (_wasNoop) return;

        // If we either added or finalized memberships, update the hash log.
        bytes24 _oldLog = _oldMetadata.log;
        bytes24 _newLog = bytes24(keccak256(abi.encode(_oldLog, _structHash)));

        FeatureMetadata memory _newMetadata = FeatureMetadata({
            currentSize: _newSize,
            numFinalized: _newNumFinalized,
            log: _newLog
        });
        featureMetadata[_traitId] = _newMetadata;

        emit TraitUpdated({
            traitId: _traitId,
            newSize: _newSize,
            newNumFinalized: _newNumFinalized,
            newLog: _newLog
        });
    }

    function hasTrait(
        IERC721 _tokenContract,
        uint256 _tokenId,
        bytes calldata _trait
    ) external view override returns (bool) {
        bytes32 _traitId = bytes32(_trait);

        uint8 _discriminant = uint8(uint256(_traitId));
        if (_discriminant == uint8(TraitType.PROJECT)) {
            return _hasProjectTrait(_tokenContract, _tokenId, _traitId);
        } else if (_discriminant == uint8(TraitType.FEATURE)) {
            return _hasFeatureTrait(_tokenContract, _tokenId, _traitId);
        } else {
            revert(ERR_INVALID_ARGUMENT);
        }
    }

    function _hasProjectTrait(
        IERC721 _tokenContract,
        uint256 _tokenId,
        bytes32 _traitId
    ) internal view returns (bool) {
        ProjectInfo storage _info = projectTraitInfo[_traitId];
        IERC721 _projectContract = _info.tokenContract;
        uint256 _projectId = _info.projectId;
        uint256 _projectSize = _info.size;

        if (_tokenContract != _projectContract) return false;
        if (_tokenId / PROJECT_STRIDE != _projectId) return false;
        if (_tokenId % PROJECT_STRIDE >= _projectSize) return false;
        return true;
    }

    function _hasFeatureTrait(
        IERC721 _tokenContract,
        uint256 _tokenId,
        bytes32 _traitId
    ) internal view returns (bool) {
        FeatureInfo storage _info = featureTraitInfo[_traitId];
        IERC721 _traitContract = _info.tokenContract;
        uint256 _projectId = _info.projectId;

        if (_tokenContract != _traitContract) return false;
        if (_tokenId / PROJECT_STRIDE != _projectId) return false;

        uint256 _tokenIndex = _tokenId - (uint256(_projectId) * PROJECT_STRIDE);
        uint256 _wordIndex = _tokenIndex >> 8;
        uint256 _mask = 1 << (_tokenIndex & 0xff);
        return (featureMembers[_traitId][_wordIndex] & _mask) != 0;
    }

    function projectTraitId(uint32 _projectId, uint32 _version)
        public
        pure
        returns (bytes32)
    {
        bytes memory _blob = abi.encode(
            TraitType.PROJECT,
            _projectId,
            _version
        );
        uint256 _hash = uint256(keccak256(_blob));
        return bytes32((_hash & ~uint256(0xff)) | uint256(TraitType.PROJECT));
    }

    function featureTraitId(
        uint32 _projectId,
        string memory _featureName,
        string memory _traitValue,
        uint32 _version
    ) public pure returns (bytes32) {
        bytes memory _blob = abi.encode(
            TraitType.FEATURE,
            _projectId,
            _featureName,
            _traitValue,
            _version
        );
        uint256 _hash = uint256(keccak256(_blob));
        return bytes32((_hash & ~uint256(0xff)) | uint256(TraitType.FEATURE));
    }

    /// Dumb helper to test whether a string is empty, because Solidity doesn't
    /// expose `_s.length` for a string `_s`.
    function _stringEmpty(string memory _s) internal pure returns (bool) {
        return bytes(_s).length == 0;
    }

    /// Given that the first `_numFinalized` tokens for trait `_t` have been
    /// finalized, returns a mask into `featureMembers[_t][_wordIndex]` of
    /// memberships that are finalized and thus not permitted to be updated.
    ///
    /// For instance, if `_numFinalized == 259`, then token indices 0 through 258
    /// (inclusive) have been finalized, so:
    ///
    ///     `_finalizedTokensMask(259, 0) == ~0`
    ///         because all tokens in word 0 have been finalized
    ///         be updated
    ///     `_finalizedTokensMask(259, 1) == (1 << 3) - 1`
    ///         because the first three tokens (256, 257, 258) within this word
    ///         have been finalized, so the result has the low 3 bits set
    ///     `_finalizedTokensMask(259, 2) == 0`
    ///         because no tokens in word 2 (or higher) have been finalized
    function _finalizedTokensMask(uint32 _numFinalized, uint256 _wordIndex)
        internal
        pure
        returns (uint256)
    {
        uint256 _firstTokenInWord = _wordIndex << 8;
        if (_numFinalized < _firstTokenInWord) {
            // Nothing in this word is finalized.
            return 0;
        }
        uint256 _numFinalizedSinceStartOfWord = uint256(_numFinalized) -
            _firstTokenInWord;
        if (_numFinalizedSinceStartOfWord > 0xff) {
            // Everything in this word is finalized.
            return ~uint256(0);
        }
        // Otherwise, between 0 and 255 tokens in this word are finalized; form
        // a mask of their indices.
        //
        // (This subtraction doesn't underflow because the shift produces a
        // nonzero value, given the bounds on `_numFinalizedSinceStartOfWord`.)
        return (1 << _numFinalizedSinceStartOfWord) - 1;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

struct SetProjectInfoMessage {
    uint32 version;
    IERC721 tokenContract;
    uint32 projectId;
    uint32 size;
    string projectName;
}

struct SetFeatureInfoMessage {
    uint32 version;
    IERC721 tokenContract;
    uint32 projectId;
    string featureName;
    string traitValue;
}

struct UpdateTraitMessage {
    bytes32 traitId;
    TraitMembershipWord[] words;
    /// Define `numTokensFinalized` as `uint32(uint256(finalization))`
    /// (the low/last 4 bytes) and `expectedLastLog` as `bytes24(finalization)`
    /// (the high/first 24 bytes).
    ///
    /// If `numTokensFinalized` is greater than the current number of tokens
    /// finalized for this trait, then `expectedLastLog` must equal the
    /// previous value of the hash-update log for this trait (not including the
    /// update from this message), and the number of tokens finalized will be
    /// increased to `numTokensFinalized`. If the last log does not match, the
    /// transaction will be reverted.
    ///
    /// If `numTokensFinalized` is *not* greater than the current number of
    /// finalized tokens, then this field and `expectedLastLog` are ignored
    /// (even if the last log does not match). In particular, they are always
    /// ignored when `numTokensFinalized` is zero or if a message is replayed.
    bytes32 finalization;
}

/// A set of token IDs within a multiple-of-256 block.
struct TraitMembershipWord {
    /// This set describes membership for tokens between `wordIndex * 256`
    /// (inclusive) and `(wordIndex + 1) * 256` (exclusive), with IDs relative
    /// to the start of the project.
    uint256 wordIndex;
    /// A 256-bit mask of tokens such that `mask[_i]` is set if token
    /// `wordIndex * 256 + _i` (relative to the start of the project) is in the
    /// set.
    uint256 mask;
}

library ArtblocksOracleMessages {
    using ArtblocksOracleMessages for TraitMembershipWord;
    using ArtblocksOracleMessages for TraitMembershipWord[];

    bytes32 internal constant TYPEHASH_SET_PROJECT_INFO =
        keccak256(
            "SetProjectInfoMessage(uint32 version,address tokenContract,uint32 projectId,uint32 size,string projectName)"
        );
    bytes32 internal constant TYPEHASH_SET_FEATURE_INFO =
        keccak256(
            "SetFeatureInfoMessage(uint32 version,address tokenContract,uint32 projectId,string featureName,string traitValue)"
        );
    bytes32 internal constant TYPEHASH_UPDATE_TRAIT =
        keccak256(
            "UpdateTraitMessage(bytes32 traitId,TraitMembershipWord[] words,bytes32 finalization)TraitMembershipWord(uint256 wordIndex,uint256 mask)"
        );
    bytes32 internal constant TYPEHASH_TRAIT_MEMBERSHIP_WORD =
        keccak256("TraitMembershipWord(uint256 wordIndex,uint256 mask)");

    function structHash(SetProjectInfoMessage memory _self)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    TYPEHASH_SET_PROJECT_INFO,
                    _self.version,
                    _self.tokenContract,
                    _self.projectId,
                    _self.size,
                    keccak256(abi.encodePacked(_self.projectName))
                )
            );
    }

    function structHash(SetFeatureInfoMessage memory _self)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    TYPEHASH_SET_FEATURE_INFO,
                    _self.version,
                    _self.tokenContract,
                    _self.projectId,
                    keccak256(abi.encodePacked(_self.featureName)),
                    keccak256(abi.encodePacked(_self.traitValue))
                )
            );
    }

    function structHash(UpdateTraitMessage memory _self)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    TYPEHASH_UPDATE_TRAIT,
                    _self.traitId,
                    _self.words.structHash(),
                    _self.finalization
                )
            );
    }

    function structHash(TraitMembershipWord memory _self)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    TYPEHASH_TRAIT_MEMBERSHIP_WORD,
                    _self.wordIndex,
                    _self.mask
                )
            );
    }

    function structHash(TraitMembershipWord[] memory _self)
        internal
        pure
        returns (bytes32)
    {
        bytes32[] memory _structHashes = new bytes32[](_self.length);
        for (uint256 _i = 0; _i < _self.length; _i++) {
            _structHashes[_i] = _self[_i].structHash();
        }
        return keccak256(abi.encodePacked(_structHashes));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITraitOracle {
    /// Queries whether the given NFT has the given trait. The NFT is specified
    /// by token ID only; the token contract is assumed to be known already.
    /// For instance, a trait oracle could be designed for a specific token
    /// contract, or it could call a method on `msg.sender` to determine what
    /// contract to use.
    ///
    /// The interpretation of trait IDs may be domain-specific and is at the
    /// discretion of the trait oracle. For example, an oracle might choose to
    /// encode traits called "Normal" and "Rare" as `0` and `1` respectively,
    /// or as `uint256(keccak256("Normal"))` and `uint256(keccak256("Rare"))`,
    /// or as something else. The trait oracle may expose other domain-specific
    /// methods to describe these traits.
    function hasTrait(
        IERC721 _tokenContract,
        uint256 _tokenId,
        bytes calldata _trait
    ) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Popcnt {
    /// Computes the population count of `_x`: i.e., the number of bits that
    /// are set. Also known as the Hamming weight.
    ///
    /// Implementation is the standard contraction algorithm.
    function popcnt(uint256 _x) internal pure returns (uint256) {
        _x = (_x & MASK_0) + ((_x >> 1) & MASK_0);
        _x = (_x & MASK_1) + ((_x >> 2) & MASK_1);
        _x = (_x & MASK_2) + ((_x >> 4) & MASK_2);
        _x = (_x & MASK_3) + ((_x >> 8) & MASK_3);
        _x = (_x & MASK_4) + ((_x >> 16) & MASK_4);
        _x = (_x & MASK_5) + ((_x >> 32) & MASK_5);
        _x = (_x & MASK_6) + ((_x >> 64) & MASK_6);
        _x = (_x & MASK_7) + ((_x >> 128) & MASK_7);
        return _x;
    }

    /// To compute these constants:
    ///
    /// ```python3
    /// for i in range(8):
    ///     pow = 2 ** i
    ///     bits = ("0" * pow + "1" * pow) * (256 // (2 * pow))
    ///     num = int(bits, 2)
    ///     hexstr = "0x" + hex(num)[2:].zfill(64)
    ///     print("uint256 constant MASK_%s = %s;" % (i, hexstr))
    /// ```
    uint256 constant MASK_0 =
        0x5555555555555555555555555555555555555555555555555555555555555555;
    uint256 constant MASK_1 =
        0x3333333333333333333333333333333333333333333333333333333333333333;
    uint256 constant MASK_2 =
        0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f;
    uint256 constant MASK_3 =
        0x00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff;
    uint256 constant MASK_4 =
        0x0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff;
    uint256 constant MASK_5 =
        0x00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff;
    uint256 constant MASK_6 =
        0x0000000000000000ffffffffffffffff0000000000000000ffffffffffffffff;
    uint256 constant MASK_7 =
        0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

enum SignatureKind {
    /// A message for which authorization is handled specially by the verifying
    /// contract. Signatures with this kind will always be rejected by
    /// `SignatureChecker.recover`; this enum variant exists to let callers
    /// handle other types of authorization, such as pre-authorization in
    /// contract storage or association with `msg.sender`.
    EXTERNAL,
    /// A message that starts with "\x19Ethereum Signed Message[...]", as
    /// implemented by the `personal_sign` JSON-RPC method.
    ETHEREUM_SIGNED_MESSAGE,
    /// A message that starts with "\x19\x01" and follows the EIP-712 typed
    /// data specification.
    EIP_712
}

library SignatureChecker {
    function recover(
        bytes32 _domainSeparator,
        bytes32 _structHash,
        bytes memory _signature,
        SignatureKind _kind
    ) internal pure returns (address) {
        bytes32 _hash;
        if (_kind == SignatureKind.ETHEREUM_SIGNED_MESSAGE) {
            _hash = ECDSA.toEthSignedMessageHash(
                keccak256(abi.encode(_domainSeparator, _structHash))
            );
        } else if (_kind == SignatureKind.EIP_712) {
            _hash = ECDSA.toTypedDataHash(_domainSeparator, _structHash);
        } else {
            revert("SignatureChecker: no signature given");
        }
        return ECDSA.recover(_hash, _signature);
    }
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
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}