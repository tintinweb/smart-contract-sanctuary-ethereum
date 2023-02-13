// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../Interfaces/IPositionToken.sol";
import "../../utils/DataTypes.sol";
import "../lib/Utils.sol";

/// @title NF3 Position Token
/// @author Jack Jin
/// @author Priyam Anand
/// @dev This contract is for position token which reflects the reservation status.

contract PositionToken is Ownable, ERC721URIStorage {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using Utils for *;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum PositionTokenErrorCodes {
        CALLER_NOT_APPROVED,
        TOKEN_NOT_EXISTS,
        INVALID_ADDRESS
    }

    error PositionTokenError(PositionTokenErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emits when the position token has minted.
    /// @param tokenId Position token id
    /// @param dataHash Hash of the data been stored
    /// @param owner Position token owner
    event PositionTokenMinted(uint256 tokenId, bytes32 dataHash, address owner);

    /// @dev Emits when the position token has burnt.
    /// @param tokenId Position token id
    event PositonTokenBurnt(uint256 tokenId);

    /// @dev Emits when new reserve address has set.
    /// @param oldReserveAddress Previous reserve contract address
    /// @param newReserveAddress New reserve contract address
    event ReserveSet(address oldReserveAddress, address newReserveAddress);

    /// @dev Emits when new base uri has set.
    /// @param oldBaseURI Previous base uri
    /// @param newBaseURI New base uri
    event BaseURISet(string oldBaseURI, string newBaseURI);

    /// @dev Emits when the token uri has set.
    /// @param tokenId Token id
    /// @param tokenURI Token uri
    event TokenURISet(uint256 tokenId, string tokenURI);

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice Reserve contract address
    address public reserveAddress;

    /// @notice Position token id
    uint256 public tokenId;

    /// @notice Token base uri
    string public baseURI;

    /// @notice Mapping of position token data hash
    mapping(uint256 => bytes32) public dataHash;

    /// @notice Mapping of reservation starting time
    mapping(uint256 => uint256) public startTime;

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------

    modifier onlyReserve() {
        if (msg.sender != reserveAddress) {
            revert PositionTokenError(
                PositionTokenErrorCodes.CALLER_NOT_APPROVED
            );
        }
        _;
    }

    /* ===== INIT ===== */

    /// @dev Constructor
    constructor() ERC721("Position Token", "PT") {}

    /// -----------------------------------------------------------------------
    /// Reserve actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from IPositionToken
    function mint(Reservation calldata _reservation, address _user)
        external
        onlyReserve
        returns (uint256)
    {
        uint256 _tokenId = ++tokenId;

        bytes32 _dataHash = _reservation
            .reservedAssets
            .getPostitionTokenDataHash(
                _reservation.reserveInfo,
                _reservation.assetOwner
            );

        // Set data hash and starting time of the token reservation.
        dataHash[_tokenId] = _dataHash;

        startTime[_tokenId] = block.timestamp;

        // Mint the token.
        _safeMint(_user, _tokenId);
        setTokenURI(_tokenId);

        emit PositionTokenMinted(_tokenId, _dataHash, _user);

        return _tokenId;
    }

    /// @notice Inherit from IPositionToken
    function burn(uint256 _tokenId) external onlyReserve {
        if (!_exists(tokenId)) {
            revert PositionTokenError(PositionTokenErrorCodes.TOKEN_NOT_EXISTS);
        }

        _burn(_tokenId);

        delete dataHash[_tokenId];

        delete startTime[_tokenId];

        emit PositonTokenBurnt(_tokenId);
    }

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from IPositionToken
    function setReserve(address _reserveAddress) external onlyOwner {
        if (_reserveAddress == address(0)) {
            revert PositionTokenError(PositionTokenErrorCodes.INVALID_ADDRESS);
        }
        emit ReserveSet(reserveAddress, _reserveAddress);

        reserveAddress = _reserveAddress;
    }

    /// @notice Inherit from IPositionToken
    function setBaseURI(string memory _baseURI) external onlyOwner {
        emit BaseURISet(baseURI, _baseURI);

        baseURI = _baseURI;
    }

    /// -----------------------------------------------------------------------
    /// Interal functions
    /// -----------------------------------------------------------------------

    /// @dev Set the position token URI.
    /// @param _tokenId Position token id
    function setTokenURI(uint256 _tokenId) internal {
        string memory uri = string(
            abi.encodePacked(baseURI, Strings.toString(_tokenId))
        );
        _setTokenURI(_tokenId, uri);

        emit TokenURISet(_tokenId, uri);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../../utils/DataTypes.sol";

/// @title NF3 Position Token Interface
/// @author Jack Jin
/// @author Priyam Anand
/// @dev This interface defines the functions related to position token contract.

interface IPositionToken {
    /// -----------------------------------------------------------------------
    /// Storage actions
    /// -----------------------------------------------------------------------

    /// @dev Mint the position token with listing and reserve info.
    /// @param reservation Reservation details of the trade
    /// @param user Buyer address
    function mint(Reservation memory reservation, address user)
        external
        returns (uint256);

    /// @dev Burn the position token.
    /// @param tokenId Position token id
    function burn(uint256 tokenId) external;

    /// -----------------------------------------------------------------------
    /// View actions
    /// -----------------------------------------------------------------------

    /// @dev Get the owner of position token id.
    /// @param tokenId Position token id
    function ownerOf(uint256 tokenId) external view returns (address);

    /// @dev Get the data hash at the given tokenId.
    /// @param tokenId Position tokenId
    function dataHash(uint256 tokenId) external view returns (bytes32);

    /// @dev Get timestamp when the listing was reserved.
    /// @param tokenId Position tokenId
    function startTime(uint256 tokenId) external view returns (uint256);

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @dev Set Reserve contract address.
    /// @param reserveAddress Reserve contract address
    function setReserve(address reserveAddress) external;

    /// @dev Set base uri.
    /// @param baseURI New base uri
    function setBaseURI(string memory baseURI) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @dev Royalties for collection creators and platform fee for platform manager.
///      to[0] is platform owner address.
/// @param to Creators and platform manager address array
/// @param percentage Royalty percentage based on the listed FT
struct Royalty {
    address[] to;
    uint256[] percentage;
}

/// @dev Common Assets type, packing bundle of NFTs and FTs.
/// @param tokens NFT asset address
/// @param tokenIds NFT token id
/// @param paymentTokens FT asset address
/// @param amounts FT token amount
struct Assets {
    address[] tokens;
    uint256[] tokenIds;
    address[] paymentTokens;
    uint256[] amounts;
}

/// @dev Common SwapAssets type, packing Bundle of NFTs and FTs. Notice tokenIds is a 2d array.
///      Each collection address ie. tokens[i] will have an array tokenIds[i] corrosponding to it.
///      This is used to select particular tokenId in corrospoding collection. If tokenIds[i]
///      is empty, this means the entire collection is considered valid.
/// @param tokens NFT asset address
/// @param roots Merkle roots of the criterias. NOTE: bytes32(0) represents the entire collection
/// @param paymentTokens FT asset address
/// @param amounts FT token amount
struct SwapAssets {
    address[] tokens;
    bytes32[] roots;
    address[] paymentTokens;
    uint256[] amounts;
}

/// @dev Common Reserve type, packing data related to reserve listing and reserve offer.
/// @param deposit Assets considered as initial deposit
/// @param remaining Assets considered as due amount
/// @param duration Duration of reserve now swap later
struct ReserveInfo {
    Assets deposit;
    Assets remaining;
    uint256 duration;
}

/// @dev All the reservation details that are stored in the position token
/// @param reservedAssets Assets that were reserved as a part of the reservation
/// @param reservedAssestsRoyalty Royalty offered by the assets owner
/// @param reserveInfo Deposit, remainig and time duriation details of the reservation
/// @param assetOwner Original owner of the reserved assets
struct Reservation {
    Assets reservedAssets;
    Royalty reservedAssetsRoyalty;
    ReserveInfo reserveInfo;
    address assetOwner;
}

/// @dev Listing type, packing the assets being listed, listing parameters, listing owner
///      and users's nonce.
/// @param listingAssets All the assets listed
/// @param directSwaps List of options for direct swap
/// @param reserves List of options for reserve now swap later
/// @param royalty Listing royalty and platform fee info
/// @param timePeriod Time period of listing
/// @param owner Owner's address
/// @param nonce User's nonce
struct Listing {
    Assets listingAssets;
    SwapAssets[] directSwaps;
    ReserveInfo[] reserves;
    Royalty royalty;
    address tradeIntendedFor;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Listing type of special NF3 banner listing
/// @param token address of collection
/// @param tokenId token id being listed
/// @param editions number of tokenIds being distributed
/// @param gateCollectionsRoot merkle root for eligible collections
/// @param timePeriod timePeriod of listing
/// @param owner owner of listing
struct NF3GatedListing {
    address token;
    uint256 tokenId;
    uint256 editions;
    bytes32 gatedCollectionsRoot;
    uint256 timePeriod;
    address owner;
}

/// @dev Swap Offer type info.
/// @param offeringItems Assets being offered
/// @param royalty Swap offer royalty info
/// @param considerationRoot Assets to which this offer is made
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct SwapOffer {
    Assets offeringItems;
    Royalty royalty;
    bytes32 considerationRoot;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Reserve now swap later type offer info.
/// @param reserveDetails Reservation scheme begin offered
/// @param considerationRoot Assets to which this offer is made
/// @param royalty Reserve offer royalty info
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct ReserveOffer {
    ReserveInfo reserveDetails;
    bytes32 considerationRoot;
    Royalty royalty;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Collection offer type info.
/// @param offeringItems Assets being offered
/// @param considerationItems Assets to which this offer is made
/// @param royalty Collection offer royalty info
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct CollectionSwapOffer {
    Assets offeringItems;
    SwapAssets considerationItems;
    Royalty royalty;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Collection Reserve type offer info.
/// @param reserveDetails Reservation scheme begin offered
/// @param considerationItems Assets to which this offer is made
/// @param royalty Reserve offer royalty info
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct CollectionReserveOffer {
    ReserveInfo reserveDetails;
    SwapAssets considerationItems;
    Royalty royalty;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

enum Status {
    AVAILABLE,
    EXHAUSTED
}

enum AssetType {
    INVALID,
    ETH,
    ERC_20,
    ERC_721,
    ERC_1155,
    KITTIES,
    PUNK
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../../utils/DataTypes.sol";
import "../../utils/LoanDataTypes.sol";

/// @title NF3 Utils Library
/// @author Jack Jin
/// @author Priyam Anand
/// @dev This library contains all the pure functions that are used across the system of contracts.

library Utils {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum UtilsErrorCodes {
        INVALID_LISTING_SIGNATURE,
        INVALID_SWAP_OFFER_SIGNATURE,
        INVALID_COLLECTION_OFFER_SIGNATURE,
        INVALID_RESERVE_OFFER_SIGNATURE,
        INVALID_ITEMS,
        ONLY_OWNER,
        OWNER_NOT_ALLOWED,
        INVALID_LOAN_OFFER_SIGNATURE,
        INVALID_COLLECTION_LOAN_OFFER_SIGNATURE,
        INVALID_UPDATE_LOAN_OFFER_SIGNATURE,
        INVALID_COLLECTION_RESERVE_OFFER_SIGNATURE
    }

    error UtilsError(UtilsErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Internal Functions
    /// -----------------------------------------------------------------------

    /* ===== Verify Signatures ===== */

    /// @dev Check the signature if the listing info is valid or not.
    /// @param _listing Listing info
    /// @param _signature Listing signature
    function verifyListingSignature(
        Listing calldata _listing,
        bytes memory _signature
    ) internal pure {
        address owner = getListingSignatureOwner(_listing, _signature);

        if (_listing.owner != owner) {
            revert UtilsError(UtilsErrorCodes.INVALID_LISTING_SIGNATURE);
        }
    }

    /// @dev Check the signature if the swap offer is valid or not.
    /// @param _offer Offer info
    /// @param _signature Offer signature
    function verifySwapOfferSignature(
        SwapOffer calldata _offer,
        bytes memory _signature
    ) internal pure {
        address owner = getSwapOfferSignatureOwner(_offer, _signature);

        if (_offer.owner != owner) {
            revert UtilsError(UtilsErrorCodes.INVALID_SWAP_OFFER_SIGNATURE);
        }
    }

    /// @dev Check the signature if the collection offer is valid or not.
    /// @param _offer Offer info
    /// @param _signature Offer signature
    function verifyCollectionSwapOfferSignature(
        CollectionSwapOffer calldata _offer,
        bytes memory _signature
    ) internal pure {
        address owner = getCollectionSwapOfferOwner(_offer, _signature);

        if (_offer.owner != owner) {
            revert UtilsError(
                UtilsErrorCodes.INVALID_COLLECTION_OFFER_SIGNATURE
            );
        }
    }

    /// @dev Check the signature if the reserve offer is valid or not.
    /// @param _offer Reserve offer info
    /// @param _signature Reserve offer signature
    function verifyReserveOfferSignature(
        ReserveOffer calldata _offer,
        bytes memory _signature
    ) internal pure {
        address owner = getReserveOfferSignatureOwner(_offer, _signature);

        if (_offer.owner != owner) {
            revert UtilsError(UtilsErrorCodes.INVALID_RESERVE_OFFER_SIGNATURE);
        }
    }

    /// @dev Check the signature if the loan offer is valid or not.
    /// @param _loanOffer Loan offer info
    /// @param _signature Loan offer signature
    function verifyLoanOfferSignature(
        LoanOffer calldata _loanOffer,
        bytes memory _signature
    ) internal pure {
        address owner = getLoanOfferOwer(_loanOffer, _signature);

        if (_loanOffer.owner != owner) {
            revert UtilsError(UtilsErrorCodes.INVALID_LOAN_OFFER_SIGNATURE);
        }
    }

    /// @dev Check the signature if the collection loan offer is valid or not.
    /// @param _loanOffer Collection loan offer info
    /// @param _signature Collection loan offer signature
    function verifyCollectionLoanOfferSignature(
        CollectionLoanOffer calldata _loanOffer,
        bytes memory _signature
    ) internal pure {
        address owner = getCollectionLoanOwner(_loanOffer, _signature);

        if (_loanOffer.owner != owner) {
            revert UtilsError(
                UtilsErrorCodes.INVALID_COLLECTION_LOAN_OFFER_SIGNATURE
            );
        }
    }

    function verifyCollectionReserveOfferSignature(
        CollectionReserveOffer calldata _offer,
        bytes memory _signature
    ) internal pure {
        address owner = getCollectionReserveOfferOwner(_offer, _signature);

        if (_offer.owner != owner) {
            revert UtilsError(
                UtilsErrorCodes.INVALID_COLLECTION_RESERVE_OFFER_SIGNATURE
            );
        }
    }

    /// @dev Check the signature if the update loan offer is valid or not.
    /// @param _loanOffer Update loan offer info
    /// @param _signature Update loan offer signature
    function verifyUpdateLoanSignature(
        LoanUpdateOffer calldata _loanOffer,
        bytes memory _signature
    ) internal pure {
        address owner = getUpdateLoanOfferOwner(_loanOffer, _signature);

        if (_loanOffer.owner != owner) {
            revert UtilsError(
                UtilsErrorCodes.INVALID_UPDATE_LOAN_OFFER_SIGNATURE
            );
        }
    }

    /* ===== Verify Assets ===== */

    /// @dev Verify assets1 and assets2 if they are the same.
    /// @param _assets1 First assets
    /// @param _assets2 Second assets
    function verifyAssets(Assets calldata _assets1, Assets calldata _assets2)
        internal
        pure
    {
        if (
            _assets1.paymentTokens.length != _assets2.paymentTokens.length ||
            _assets1.tokens.length != _assets2.tokens.length
        ) revert UtilsError(UtilsErrorCodes.INVALID_ITEMS);

        unchecked {
            uint256 i;
            for (i = 0; i < _assets1.paymentTokens.length; i++) {
                if (
                    _assets1.paymentTokens[i] != _assets2.paymentTokens[i] ||
                    _assets1.amounts[i] != _assets2.amounts[i]
                ) revert UtilsError(UtilsErrorCodes.INVALID_ITEMS);
            }

            for (i = 0; i < _assets1.tokens.length; i++) {
                if (
                    _assets1.tokens[i] != _assets2.tokens[i] ||
                    _assets1.tokenIds[i] != _assets2.tokenIds[i]
                ) revert UtilsError(UtilsErrorCodes.INVALID_ITEMS);
            }
        }
    }

    /// @dev Verify swap assets to be satisfied as the consideration items by the seller.
    /// @param _swapAssets Swap assets
    /// @param _tokens NFT addresses
    /// @param _tokenIds NFT token ids
    /// @param _value Eth value
    /// @return assets Verified swap assets
    function verifySwapAssets(
        SwapAssets memory _swapAssets,
        address[] memory _tokens,
        uint256[] memory _tokenIds,
        bytes32[][] memory _proofs,
        uint256 _value
    ) internal pure returns (Assets memory) {
        uint256 ethAmount;
        uint256 i;

        // check Eth amounts
        for (i = 0; i < _swapAssets.paymentTokens.length; ) {
            if (_swapAssets.paymentTokens[i] == address(0))
                ethAmount += _swapAssets.amounts[i];
            unchecked {
                ++i;
            }
        }
        if (ethAmount > _value) {
            revert UtilsError(UtilsErrorCodes.INVALID_ITEMS);
        }

        unchecked {
            // check compatible NFTs
            for (i = 0; i < _swapAssets.tokens.length; i++) {
                if (
                    _swapAssets.tokens[i] != _tokens[i] ||
                    (!verifyMerkleProof(
                        _swapAssets.roots[i],
                        _proofs[i],
                        keccak256(abi.encodePacked(_tokenIds[i]))
                    ) && _swapAssets.roots[i] != bytes32(0))
                ) {
                    revert UtilsError(UtilsErrorCodes.INVALID_ITEMS);
                }
            }
        }

        return
            Assets(
                _tokens,
                _tokenIds,
                _swapAssets.paymentTokens,
                _swapAssets.amounts
            );
    }

    /// @dev Verify if the passed asset is present in the merkle root passed.
    /// @param _root Merkle root to check in
    /// @param _consideration Consideration assets
    /// @param _proof Merkle proof
    function verifyAssetProof(
        bytes32 _root,
        Assets calldata _consideration,
        bytes32[] calldata _proof
    ) internal pure {
        bytes32 _leaf = addAssets(_consideration, bytes32(0));

        if (!verifyMerkleProof(_root, _proof, _leaf)) {
            revert UtilsError(UtilsErrorCodes.INVALID_ITEMS);
        }
    }

    /* ===== Check Validations ===== */

    /// @dev Check if the ETH amount is valid.
    /// @param _assets Assets
    /// @param _value ETH amount
    function checkEthAmount(Assets memory _assets, uint256 _value)
        internal
        pure
    {
        uint256 ethAmount;

        for (uint256 i = 0; i < _assets.paymentTokens.length; ) {
            if (_assets.paymentTokens[i] == address(0))
                ethAmount += _assets.amounts[i];
            unchecked {
                ++i;
            }
        }
        if (ethAmount > _value) {
            revert UtilsError(UtilsErrorCodes.INVALID_ITEMS);
        }
    }

    /// @dev Check if the function is called by the item owner.
    /// @param _owner Owner address
    /// @param _caller Caller address
    function itemOwnerOnly(address _owner, address _caller) internal pure {
        if (_owner != _caller) {
            revert UtilsError(UtilsErrorCodes.ONLY_OWNER);
        }
    }

    /// @dev Check if the function is not called by the item owner.
    /// @param _owner Owner address
    /// @param _caller Caller address
    function notItemOwner(address _owner, address _caller) internal pure {
        if (_owner == _caller) {
            revert UtilsError(UtilsErrorCodes.OWNER_NOT_ALLOWED);
        }
    }

    /* ===== Get Functions ===== */

    /// @dev Get the hash of data saved in position token.
    /// @param _listingAssets Listing assets
    /// @param _reserveInfo Reserve ino
    /// @param _listingOwner Listing owner
    /// @return hash Hash of the passed data
    function getPostitionTokenDataHash(
        Assets calldata _listingAssets,
        ReserveInfo calldata _reserveInfo,
        address _listingOwner
    ) internal pure returns (bytes32 hash) {
        hash = addAssets(_listingAssets, hash);

        hash = keccak256(
            abi.encodePacked(getReserveHash(_reserveInfo), _listingOwner, hash)
        );
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    /* ===== Get Owner Of Signatures ===== */

    /// @dev Get the signature owner from listing data info and its signature.
    /// @param _listing Listing info
    /// @param _signature Listing signature
    /// @return owner Listing signature owner
    function getListingSignatureOwner(
        Listing calldata _listing,
        bytes memory _signature
    ) internal pure returns (address owner) {
        bytes32 hash = getListingHash(_listing);

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    /// @dev Get the signature owner from the swap offer info and its signature.
    /// @param _offer Swap offer info
    /// @param _signature Swap offer signature
    /// @return owner Swap offer signature owner
    function getSwapOfferSignatureOwner(
        SwapOffer calldata _offer,
        bytes memory _signature
    ) internal pure returns (address owner) {
        bytes32 hash = getSwapOfferHash(_offer);

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    /// @dev Get the signature owner from collection offer info and its signature.
    /// @param _offer Collection offer info
    /// @param _signature Collection offer signature
    /// @return owner Collection offer signature owner
    function getCollectionSwapOfferOwner(
        CollectionSwapOffer calldata _offer,
        bytes memory _signature
    ) internal pure returns (address owner) {
        bytes32 hash = getCollectionSwapOfferHash(_offer);

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    /// @dev Get the signature owner from reserve offer info and its signature.
    /// @param _offer Reserve offer info
    /// @param _signature Reserve offer signature
    /// @return owner Reserve offer signature owner
    function getReserveOfferSignatureOwner(
        ReserveOffer calldata _offer,
        bytes memory _signature
    ) internal pure returns (address owner) {
        bytes32 hash = getReserveOfferHash(_offer);

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    function getCollectionReserveOfferOwner(
        CollectionReserveOffer calldata _offer,
        bytes memory _signature
    ) internal pure returns (address owner) {
        bytes32 hash = getCollectionReserveOfferHash(_offer);

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    /// @dev Get the signature owner from loan offer info and its signature.
    /// @param _loanOffer Loan offer info
    /// @param _signature Loan offer signature
    /// @return owner Signature owner
    function getLoanOfferOwer(
        LoanOffer calldata _loanOffer,
        bytes memory _signature
    ) internal pure returns (address owner) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                _loanOffer.nftCollateralContract,
                _loanOffer.nftCollateralId,
                _loanOffer.owner,
                _loanOffer.nonce,
                _loanOffer.loanPaymentToken,
                _loanOffer.loanPrincipalAmount,
                _loanOffer.maximumRepaymentAmount,
                _loanOffer.loanDuration,
                _loanOffer.loanInterestRate,
                _loanOffer.adminFees,
                _loanOffer.isLoanProrated,
                _loanOffer.isBorrowerTerms
            )
        );

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    /// @dev Get the signature owner from collection loan offer info and its signature.
    /// @param _loanOffer Collection loan offer info
    /// @param _signature Collection loan offer signature
    /// @return owner Signature owner
    function getCollectionLoanOwner(
        CollectionLoanOffer calldata _loanOffer,
        bytes memory _signature
    ) internal pure returns (address owner) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                _loanOffer.nftCollateralContract,
                _loanOffer.nftCollateralIdRoot,
                _loanOffer.owner,
                _loanOffer.nonce,
                _loanOffer.loanPaymentToken,
                _loanOffer.loanPrincipalAmount,
                _loanOffer.maximumRepaymentAmount,
                _loanOffer.loanDuration,
                _loanOffer.loanInterestRate,
                _loanOffer.adminFees,
                _loanOffer.isLoanProrated
            )
        );

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    /// @dev Get the signature owner from update loan offer info and its signature.
    /// @param _loanOffer Update loan offer info
    /// @param _signature Update loan offer signature
    /// @return owner Signature owner
    function getUpdateLoanOfferOwner(
        LoanUpdateOffer calldata _loanOffer,
        bytes memory _signature
    ) internal pure returns (address owner) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                _loanOffer.loanId,
                _loanOffer.maximumRepaymentAmount,
                _loanOffer.loanDuration,
                _loanOffer.loanInterestRate,
                _loanOffer.owner,
                _loanOffer.nonce,
                _loanOffer.isLoanProrated,
                _loanOffer.isBorrowerTerms
            )
        );

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    /* ===== Get Hash ===== */

    /// @dev Get the hash of listing info.
    /// @param _listing Listing info
    /// @return hash Hash of the listing info
    function getListingHash(Listing calldata _listing)
        internal
        pure
        returns (bytes32)
    {
        bytes32 signature;
        uint256 i;

        signature = addAssets(_listing.listingAssets, signature);

        unchecked {
            for (i = 0; i < _listing.directSwaps.length; i++) {
                signature = addSwapAssets(_listing.directSwaps[i], signature);
            }

            for (i = 0; i < _listing.reserves.length; i++) {
                signature = addAssets(_listing.reserves[i].deposit, signature);
                signature = addAssets(
                    _listing.reserves[i].remaining,
                    signature
                );
                signature = keccak256(
                    abi.encodePacked(_listing.reserves[i].duration, signature)
                );
            }
        }

        signature = addRoyalty(_listing.royalty, signature);

        signature = keccak256(
            abi.encodePacked(
                _listing.tradeIntendedFor,
                _listing.timePeriod,
                _listing.owner,
                _listing.nonce,
                signature
            )
        );

        return signature;
    }

    /// @dev Get the hash of the swap offer info.
    /// @param _offer Offer info
    /// @return hash Hash of the offer
    function getSwapOfferHash(SwapOffer calldata _offer)
        internal
        pure
        returns (bytes32)
    {
        bytes32 signature;

        signature = addAssets(_offer.offeringItems, signature);

        signature = addRoyalty(_offer.royalty, signature);

        signature = keccak256(
            abi.encodePacked(
                _offer.considerationRoot,
                _offer.timePeriod,
                _offer.owner,
                _offer.nonce,
                signature
            )
        );

        return signature;
    }

    /// @dev Get the hash of collection offer info.
    /// @param _offer Collection offer info
    /// @return hash Hash of the collection offer info
    function getCollectionSwapOfferHash(CollectionSwapOffer calldata _offer)
        internal
        pure
        returns (bytes32)
    {
        bytes32 signature;

        signature = addAssets(_offer.offeringItems, signature);

        signature = addSwapAssets(_offer.considerationItems, signature);

        signature = addRoyalty(_offer.royalty, signature);

        signature = keccak256(
            abi.encodePacked(
                _offer.timePeriod,
                _offer.owner,
                _offer.nonce,
                signature
            )
        );

        return signature;
    }

    /// @dev Get the hash of reserve offer info.
    /// @param _offer Reserve offer info
    /// @return hash Hash of the reserve offer info
    function getReserveOfferHash(ReserveOffer calldata _offer)
        internal
        pure
        returns (bytes32)
    {
        bytes32 signature;

        signature = getReserveHash(_offer.reserveDetails);

        signature = addRoyalty(_offer.royalty, signature);

        signature = keccak256(
            abi.encodePacked(
                _offer.considerationRoot,
                _offer.timePeriod,
                _offer.owner,
                _offer.nonce,
                signature
            )
        );

        return signature;
    }

    function getCollectionReserveOfferHash(
        CollectionReserveOffer calldata _offer
    ) internal pure returns (bytes32) {
        bytes32 signature;
        signature = getReserveHash(_offer.reserveDetails);
        signature = addSwapAssets(_offer.considerationItems, signature);
        signature = addRoyalty(_offer.royalty, signature);

        signature = keccak256(
            abi.encodePacked(
                _offer.timePeriod,
                _offer.owner,
                _offer.nonce,
                signature
            )
        );

        return signature;
    }

    /// @dev Get the hash of reserve info.
    /// @param _reserve Reserve info
    /// @return hash Hash of the reserve info
    function getReserveHash(ReserveInfo calldata _reserve)
        internal
        pure
        returns (bytes32)
    {
        bytes32 signature;

        signature = addAssets(_reserve.deposit, signature);

        signature = addAssets(_reserve.remaining, signature);

        signature = keccak256(abi.encodePacked(_reserve.duration, signature));

        return signature;
    }

    /// @dev Get the hash of the given pair of hashes.
    /// @param _a First hash
    /// @param _b Second hash
    function getHash(bytes32 _a, bytes32 _b) internal pure returns (bytes32) {
        return _a < _b ? _hash(_a, _b) : _hash(_b, _a);
    }

    /// @dev Hash two bytes32 variables efficiently using assembly
    /// @param a First bytes variable
    /// @param b Second bytes variable
    function _hash(bytes32 a, bytes32 b) internal pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }

    /// @dev Get the final signed hash by appending the prefix to params hash.
    /// @param _messageHash Hash of the params message
    /// @return hash Final signed hash
    function getSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    /* ===== Verify Merkle Proof ===== */

    /// @dev Verify that the given leaf exist in the passed root and has the correct proof.
    /// @param _root Merkle root of the given criterial
    /// @param _proof Merkle proof of the given leaf and root
    /// @param _leaf Hash of the token id to be searched in the root
    /// @return bool Validation of the leaf, root and proof
    function verifyMerkleProof(
        bytes32 _root,
        bytes32[] memory _proof,
        bytes32 _leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = _leaf;

        unchecked {
            for (uint256 i = 0; i < _proof.length; i++) {
                computedHash = getHash(computedHash, _proof[i]);
            }
        }

        return computedHash == _root;
    }

    /* ===== Make Signature Hashes ===== */

    /// @dev Add the hash of type assets to signature.
    /// @param _assets Assets to be added in hash
    /// @param _sig Hash to which assets need to be added
    /// @return hash Hash result
    function addAssets(Assets calldata _assets, bytes32 _sig)
        internal
        pure
        returns (bytes32)
    {
        _sig = addNFTsArray(_assets.tokens, _assets.tokenIds, _sig);
        _sig = addFTsArray(_assets.paymentTokens, _assets.amounts, _sig);

        return _sig;
    }

    /// @dev Add the hash of type swap assets to signature.
    /// @param _assets Assets to be added in hash
    /// @param _sig Hash to which assets need to be added
    /// @return hash Hash result
    function addSwapAssets(SwapAssets calldata _assets, bytes32 _sig)
        internal
        pure
        returns (bytes32)
    {
        _sig = addSwapNFTsArray(_assets.tokens, _assets.roots, _sig);
        _sig = addFTsArray(_assets.paymentTokens, _assets.amounts, _sig);

        return _sig;
    }

    /// @dev Add the hash of type royalty to signature.
    /// @param _royalty Royalty struct
    /// @param _sig Hash to which assets need to be added
    /// @return hash Hash result
    function addRoyalty(Royalty calldata _royalty, bytes32 _sig)
        internal
        pure
        returns (bytes32)
    {
        unchecked {
            for (uint256 i = 0; i < _royalty.to.length; i++) {
                _sig = keccak256(
                    abi.encodePacked(
                        _royalty.to[i],
                        _royalty.percentage[i],
                        _sig
                    )
                );
            }
            return _sig;
        }
    }

    /// @dev Add the hash of NFT information to signature.
    /// @param _tokens Array of nft address to be hashed
    /// @param _tokenIds Array of NFT tokenIds to be hashed
    /// @param _sig Hash to which assets need to be added
    /// @return hash Hash result
    function addNFTsArray(
        address[] memory _tokens,
        uint256[] memory _tokenIds,
        bytes32 _sig
    ) internal pure returns (bytes32) {
        assembly {
            let len := mload(_tokens)
            if eq(eq(len, mload(_tokenIds)), 0) {
                revert(0, 0)
            }

            let fmp := mload(0x40)

            let tokenPtr := add(_tokens, 0x20)
            let idPtr := add(_tokenIds, 0x20)

            for {
                let tokenIdx := tokenPtr
            } lt(tokenIdx, add(tokenPtr, mul(len, 0x20))) {
                tokenIdx := add(tokenIdx, 0x20)
                idPtr := add(idPtr, 0x20)
            } {
                mstore(fmp, mload(tokenIdx))
                mstore(add(fmp, 0x20), mload(idPtr))
                mstore(add(fmp, 0x40), _sig)

                _sig := keccak256(add(fmp, 0xc), 0x54)
            }
        }
        return _sig;
    }

    /// @dev Add the hash of FT information to signature.
    /// @param _paymentTokens Array of FT address to be hashed
    /// @param _amounts Array of FT amounts to be hashed
    /// @param _sig Hash to which assets need to be added
    /// @return hash Hash result
    function addFTsArray(
        address[] memory _paymentTokens,
        uint256[] memory _amounts,
        bytes32 _sig
    ) internal pure returns (bytes32) {
        assembly {
            let len := mload(_paymentTokens)
            if eq(eq(len, mload(_amounts)), 0) {
                revert(0, 0)
            }

            let fmp := mload(0x40)

            let tokenPtr := add(_paymentTokens, 0x20)
            let idPtr := add(_amounts, 0x20)

            for {
                let tokenIdx := tokenPtr
            } lt(tokenIdx, add(tokenPtr, mul(len, 0x20))) {
                tokenIdx := add(tokenIdx, 0x20)
                idPtr := add(idPtr, 0x20)
            } {
                mstore(fmp, mload(tokenIdx))
                mstore(add(fmp, 0x20), mload(idPtr))
                mstore(add(fmp, 0x40), _sig)
                _sig := keccak256(add(fmp, 0xc), 0x54)
            }
        }
        return _sig;
    }

    /// @dev Add the hash of NFT information to signature.
    /// @param _tokens Array of nft address to be hashed
    /// @param _roots Array of valid tokenId's merkle root to be hashed
    /// @param _sig Hash to which assets need to be added
    /// @return hash Hash result
    function addSwapNFTsArray(
        address[] memory _tokens,
        bytes32[] memory _roots,
        bytes32 _sig
    ) internal pure returns (bytes32) {
        assembly {
            let len := mload(_tokens)
            if eq(eq(len, mload(_roots)), 0) {
                revert(0, 0)
            }

            let fmp := mload(0x40)

            let tokenPtr := add(_tokens, 0x20)
            let idPtr := add(_roots, 0x20)

            for {
                let tokenIdx := tokenPtr
            } lt(tokenIdx, add(tokenPtr, mul(len, 0x20))) {
                tokenIdx := add(tokenIdx, 0x20)
                idPtr := add(idPtr, 0x20)
            } {
                mstore(fmp, mload(tokenIdx))
                mstore(add(fmp, 0x20), mload(idPtr))
                mstore(add(fmp, 0x40), _sig)

                _sig := keccak256(add(fmp, 0xc), 0x54)
            }
        }
        return _sig;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
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
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @dev Common loan offer struct to be used both the borrower and lender
///      to propose new offers,
/// @param nftCollateralContract Address of the NFT contract
/// @param nftCollateralId NFT collateral token id
/// @param owner Offer owner address
/// @param nonce Nonce of owner
/// @param loanPaymentToken Address of the loan payment token
/// @param loanPrincipalAmount Principal amount of the loan
/// @param maximumRepaymentAmount Maximum amount to be repayed
/// @param loanDuration Duration of the loan
/// @param loanInterestRate Interest rate of the loan
/// @param adminFees Admin fees in basis points
/// @param isLoanProrated Flag for interest rate type of loan
/// @param isBorrowerTerms Bool value to represent if borrower's terms were accepted.
///        - if this value is true, this mean msg.sender must be the lender.
///        - if this value is false, this means lender's terms were accepted and msg.sender
///          must be the borrower.
struct LoanOffer {
    address nftCollateralContract;
    uint256 nftCollateralId;
    address owner;
    uint256 nonce;
    address loanPaymentToken;
    uint256 loanPrincipalAmount;
    uint256 maximumRepaymentAmount;
    uint256 loanDuration;
    uint256 loanInterestRate;
    uint256 adminFees;
    bool isLoanProrated;
    bool isBorrowerTerms;
}

/// @dev Collection loan offer struct to be used to making collection
///      specific offers and trait level offers.
/// @param nftCollateralContract Address of the NFT contract
/// @param nftCollateralIdRoot Merkle root of the tokenIds for collateral
/// @param owner Offer owner address
/// @param nonce Nonce of owner
/// @param loanPaymentToken Address of the loan payment token
/// @param loanPrincipalAmount Principal amount of the loan
/// @param maximumRepaymentAmount Maximum amount to be repayed
/// @param loanDuration Duration of the loan
/// @param loanInterestRate Interest rate of the loan
/// @param adminFees Admin fees in basis points
/// @param isLoanProrated Flag for interest rate type of loan
struct CollectionLoanOffer {
    address nftCollateralContract;
    bytes32 nftCollateralIdRoot;
    address owner;
    uint256 nonce;
    address loanPaymentToken;
    uint256 loanPrincipalAmount;
    uint256 maximumRepaymentAmount;
    uint256 loanDuration;
    uint256 loanInterestRate;
    uint256 adminFees;
    bool isLoanProrated;
}

/// @dev Update loan offer struct to propose new terms for an ongoing loan.
/// @param loanId Id of the loan, same as promissory tokenId
/// @param maximumRepaymentAmount Maximum amount to be repayed
/// @param loanDuration Duration of the loan
/// @param loanInterestRate Interest rate of the loan
/// @param owner Offer owner address
/// @param nonce Nonce of owner
/// @param isLoanProrated Flag for interest rate type of loan
/// @param isBorrowerTerms Bool value to represent if borrower's terms were accepted.
///        - if this value is true, this mean msg.sender must be the lender.
///        - if this value is false, this means lender's terms were accepted and msg.sender
///          must be the borrower.
struct LoanUpdateOffer {
    uint256 loanId;
    uint256 maximumRepaymentAmount;
    uint256 loanDuration;
    uint256 loanInterestRate;
    address owner;
    uint256 nonce;
    bool isLoanProrated;
    bool isBorrowerTerms;
}

/// @dev Main loan struct that stores the details of an ongoing loan.
///      This struct is used to create hashes and store them in promissory tokens.
/// @param loanId Id of the loan, same as promissory tokenId
/// @param nftCollateralContract Address of the NFT contract
/// @param nftCollateralId TokenId of the NFT collateral
/// @param loanPaymentToken Address of the ERC20 token involved
/// @param loanPrincipalAmount Principal amount of the loan
/// @param maximumRepaymentAmount Maximum amount to be repayed
/// @param loanStartTime Timestamp of when the loan started
/// @param loanDuration Duration of the loan
/// @param loanInterestRate Interest Rate of the loan
/// @param isLoanProrated Flag for interest rate type of loan
struct Loan {
    uint256 loanId;
    address nftCollateralContract;
    uint256 nftCollateralId;
    address loanPaymentToken;
    uint256 loanPrincipalAmount;
    uint256 maximumRepaymentAmount;
    uint256 loanStartTime;
    uint256 loanDuration;
    uint256 loanInterestRate;
    uint256 adminFees;
    bool isLoanProrated;
}