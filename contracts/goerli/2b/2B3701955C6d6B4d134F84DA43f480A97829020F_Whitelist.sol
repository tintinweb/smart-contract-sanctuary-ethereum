// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/IWhitelist.sol";
import "../utils/DataTypes.sol";

/// @title NF3 Vault
/// @author Jack Jin
/// @author Priyam Anand
/// @notice This contract inherits from IWhitelist interface.
/// @dev This contract has all the functions related whitelisting of tokens on NF3 platform

contract Whitelist is Ownable, IWhitelist {
    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice mapping of token addresses and their Types
    mapping(address => AssetType) public types;

    /* ===== INIT ===== */

    /// @dev Constructor
    constructor() {}

    /// -----------------------------------------------------------------------
    /// User Actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from IWhitelist
    function checkAssetsWhitelist(Assets calldata _assets)
        external
        view
        override
    {
        uint256 len = _assets.tokens.length;
        uint256 i;
        // loop through NFTs and check their type
        for (i = 0; i < len; i++) {
            AssetType _type = types[_assets.tokens[i]];
            if (!(_type == AssetType.ERC_721 || _type == AssetType.ERC_1155))
                revert WhitelistError(WhitelistErrorCodes.INVALID_ITEM);
        }

        len = _assets.paymentTokens.length;
        // loop through FTs and check their type
        for (i = 0; i < len; i++) {
            AssetType _type = types[_assets.paymentTokens[i]];
            if (!(_type == AssetType.ERC_20 || _type == AssetType.ETH))
                revert WhitelistError(WhitelistErrorCodes.INVALID_ITEM);
        }
    }

    /// @notice Inherit from IWhitelist
    function getAssetsTypes(Assets calldata _assets)
        external
        view
        override
        returns (AssetType[] memory, AssetType[] memory)
    {
        uint256 len = _assets.tokens.length;
        // loop through NFTs, check their types and store them
        AssetType[] memory nftType = new AssetType[](len);
        uint256 i;
        for (i = 0; i < len; i++) {
            AssetType _type = types[_assets.tokens[i]];
            nftType[i] = _type;
            if (_type == AssetType.INVALID)
                revert WhitelistError(WhitelistErrorCodes.INVALID_ITEM);
        }

        len = _assets.paymentTokens.length;
        // loop through FTs, check their types and store them
        AssetType[] memory ftType = new AssetType[](len);
        for (i = 0; i < len; i++) {
            AssetType _type = types[_assets.paymentTokens[i]];
            ftType[i] = _type;
            if (ftType[i] == AssetType.INVALID)
                revert WhitelistError(WhitelistErrorCodes.INVALID_ITEM);
        }

        return (nftType, ftType);
    }

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from IWhitelist
    function setTokenTypes(
        address[] calldata _tokens,
        AssetType[] calldata _types
    ) external override onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            types[_tokens[i]] = _types[i];
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../../utils/DataTypes.sol";

/// @title NF3 Swap Interface
/// @author Jack Jin
/// @author Priyam Anand
/// @dev This interface defines all the functions related to whitelisting of tokens

interface IWhitelist {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum WhitelistErrorCodes {
        INVALID_ITEM
    }

    error WhitelistError(WhitelistErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emits when new tokens are whitelisted and their types are set
    /// @param tokens addresses of tokens that are whitelisted
    /// @param types type of token set to
    event TokensTypeSet(address[] tokens, AssetType[] types);

    /// -----------------------------------------------------------------------
    /// User Actions
    /// -----------------------------------------------------------------------

    /// @dev Check if all the passed assets are whitelisted
    /// @param assets Assets to check on
    function checkAssetsWhitelist(Assets calldata assets) external view;

    /// @dev Check and return types of assets
    /// @param assets Assets to check on
    /// @return nftType types of nfts sent
    /// @return ftType types of fts sent
    function getAssetsTypes(Assets calldata assets)
        external
        view
        returns (AssetType[] memory, AssetType[] memory);

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @dev Set types of the tokens passed
    /// @param tokens Tokens to set
    /// @param types Types of tokens
    function setTokenTypes(
        address[] calldata tokens,
        AssetType[] calldata types
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

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

/// @dev Listing type, packing the assets being listed, listing parameters, listing owner
///      and users's nonce.
/// @param listingAssets All the assets listed
/// @param directSwaps List of options for direct swap
/// @param reserves List of options for reserve now swap later
/// @param timePeriod Time period of listing
/// @param owner Owner's address
/// @param nonce User's nonce
struct Listing {
    Assets listingAssets;
    SwapAssets[] directSwaps;
    ReserveInfo[] reserves;
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
/// @param considerationRoot Assets to which this offer is made
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct SwapOffer {
    Assets offeringItems;
    bytes32 considerationRoot;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Reserve now swap later type offer info.
/// @param reserveDetails Reservation scheme begin offered
/// @param considerationItems Assets to which this offer is made
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct ReserveOffer {
    ReserveInfo reserveDetails;
    Assets considerationItems;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Collection offer type info.
/// @param offeringItems Assets being offered
/// @param considerationItems Assets to which this offer is made
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct CollectionOffer {
    Assets offeringItems;
    SwapAssets considerationItems;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

enum Status {
    AVAILABLE,
    RESERVED,
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