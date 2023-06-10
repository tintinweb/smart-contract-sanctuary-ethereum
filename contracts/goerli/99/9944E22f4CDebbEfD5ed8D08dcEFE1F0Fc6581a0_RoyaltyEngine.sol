// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

/**
 * @dev Fork of Manifold's RoyaltyEngineV1.sol with:
 * - Upgradeability removed
 * - ERC2981 lookups done first
 * - Function to bulk cache token address royalties
 * - invalidateCachedRoyaltySpec function removed
 * - _getRoyaltyAndSpec converted to an internal function
 */

import {ERC165, IERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";


import {NFTKeyMarketV2Address,INFTKEYMarketplaceRoyalty,ERC721CollectionRoyalty} from "./royalty-auth/INFTKeyMarketplaceRoyalty.sol";

import {IPaintswapRoyalties,PaintSwapRoyaltiesAddress,CollectionRoyaltyInfo} from "./royalty-auth/PaintswapRoyalties.sol";
import {IManifold} from "@manifoldxyz/royalty-registry-solidity/contracts/specs/IManifold.sol";
import {IRaribleV1, IRaribleV2} from "@manifoldxyz/royalty-registry-solidity/contracts/specs/IRarible.sol";
import {IFoundation} from "@manifoldxyz/royalty-registry-solidity/contracts/specs/IFoundation.sol";
import {ISuperRareRegistry} from "@manifoldxyz/royalty-registry-solidity/contracts/specs/ISuperRare.sol";
import {IEIP2981} from "@manifoldxyz/royalty-registry-solidity/contracts/specs/IEIP2981.sol";
import {IZoraOverride} from "@manifoldxyz/royalty-registry-solidity/contracts/specs/IZoraOverride.sol";
import {IArtBlocksOverride} from "@manifoldxyz/royalty-registry-solidity/contracts/specs/IArtBlocksOverride.sol";
import {IKODAV2Override} from "@manifoldxyz/royalty-registry-solidity/contracts/specs/IKODAV2Override.sol";
import {IRoyaltyEngineV1} from "@manifoldxyz/royalty-registry-solidity/contracts/IRoyaltyEngineV1.sol";
import {IRoyaltyRegistry} from "@manifoldxyz/royalty-registry-solidity/contracts/IRoyaltyRegistry.sol";

/**
 * @dev Engine to lookup royalty configurations
 */
contract RoyaltyEngine is ERC165, IRoyaltyEngineV1 {
    // int16 values copied over from the manifold contract.
    // Anything <= NOT_CONFIGURED is considered not configured
    int16 private constant NONE = -1;
    int16 private constant NOT_CONFIGURED = 0;
    int16 private constant MANIFOLD = 1;
    int16 private constant RARIBLEV1 = 2;
    int16 private constant RARIBLEV2 = 3;
    int16 private constant FOUNDATION = 4;
    int16 private constant EIP2981 = 5;
    int16 private constant SUPERRARE = 6;
    int16 private constant ZORA = 7;
    int16 private constant ARTBLOCKS = 8;
    int16 private constant KNOWNORIGINV2 = 9;
    int16 private constant PAINTSWAP = 10;
    int16 private constant NFTKEY = 11;

    mapping(address => int16) _specCache;


    error RoyaltyEngine__InvalidRoyaltyAmount();

    constructor() {

    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IRoyaltyEngineV1).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev View function to get the cached spec of a token
     */
    function getCachedRoyaltySpec(address tokenAddress) public view returns (int16) {
        return _specCache[tokenAddress];
    }

    /**
     * @dev Bulk fetch the specs for multiple tokenAddresses and cache them for cheaper reads later.
     * If a spec is already cached for a token address, it will be invalidated and refetched.
     * There will be a double lookup for the royalty address which is fine because this function won't be
     * called often.
     */
    function bulkCacheSpecs(address[] calldata tokenAddresses, uint256[] calldata tokenIds, uint256[] calldata values)
        public
    {
        uint256 numTokens = tokenAddresses.length;
        for (uint256 i; i < numTokens;) {
            // Invalidate cached value
            address royaltyAddress = tokenAddresses[i];
            delete _specCache[royaltyAddress];

            (, uint256[] memory royaltyAmounts, int16 newSpec,,) =
                _getRoyaltyAndSpec(tokenAddresses[i], tokenIds[i], values[i]);
            _checkAmountsDoesNotExceedValue(values[i], royaltyAmounts);
            _specCache[royaltyAddress] = newSpec;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {IRoyaltyEngineV1-getRoyalty}
     */
    function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value)
        public
        override
        returns (address payable[] memory, uint256[] memory)
    {
        (
            address payable[] memory _recipients,
            uint256[] memory _amounts,
            int16 spec,
            address royaltyAddress,
            bool addToCache
        ) = _getRoyaltyAndSpec(tokenAddress, tokenId, value);
        if (addToCache) _specCache[royaltyAddress] = spec;
        return (_recipients, _amounts);
    }

    /**
     * @dev See {IRoyaltyEngineV1-getRoyaltyView}.
     */
    function getRoyaltyView(address tokenAddress, uint256 tokenId, uint256 value)
        public
        view
        override
        returns (address payable[] memory, uint256[] memory)
    {
        (address payable[] memory _recipients, uint256[] memory _amounts,,,) =
            _getRoyaltyAndSpec(tokenAddress, tokenId, value);
        return (_recipients, _amounts);
    }

    /**
     * @dev Get the royalty and royalty spec for a given token
     *
     * There is a potential DOS attack vector if a malicious contract consumes the gas limit of a txn.
     * We are ok with this because it will just lead to a swap erroring out.
     *
     * returns recipients array, amounts array, royalty spec, royalty address, whether or not to add to cache
     */
    function _getRoyaltyAndSpec(address tokenAddress, uint256 tokenId, uint256 value)
        internal
        view
        returns (
            address payable[] memory recipients,
            uint256[] memory amounts,
            int16 spec,
            address royaltyAddress,
            bool addToCache
        )
    {
        royaltyAddress = tokenAddress;
        spec = _specCache[royaltyAddress];

        if (spec <= NOT_CONFIGURED) {
            // No spec configured yet, so we need to detect the spec
            addToCache = true;

            // Moved 2981 handling to the top because this will be the most prevalent type
            try IEIP2981(royaltyAddress).royaltyInfo(tokenId, value) returns (address recipient, uint256 amount) {
                // Supports EIP2981.  Return amounts
                recipients = new address payable[](1);
                amounts = new uint256[](1);
                recipients[0] = payable(recipient);
                amounts[0] = amount;
                return (recipients, amounts, EIP2981, royaltyAddress, addToCache);
            } catch {}
            try IPaintswapRoyalties(PaintSwapRoyaltiesAddress).getCollectionRoyaltyInfo(tokenAddress) returns (CollectionRoyaltyInfo memory info) {
                recipients = new address payable[](1);
                amounts = new uint256[](1);
                recipients[0] = payable(info.recipient);
                amounts[0] = info.fee;
                return (recipients, amounts, PAINTSWAP, PaintSwapRoyaltiesAddress, addToCache);
            } catch {}
            try INFTKEYMarketplaceRoyalty(NFTKeyMarketV2Address).royalty(tokenAddress) returns (ERC721CollectionRoyalty memory info) {
                recipients = new address payable[](1);
                amounts = new uint256[](1);
                recipients[0] = payable(info.recipient);
                amounts[0] = info.feeFraction;
                return (recipients, amounts, PAINTSWAP, PaintSwapRoyaltiesAddress, addToCache);
            } catch {}

            try IArtBlocksOverride(royaltyAddress).getRoyalties(tokenAddress, tokenId) returns (
                address payable[] memory recipients_, uint256[] memory bps
            ) {
                // Support Art Blocks override
                return (recipients_, _computeAmounts(value, bps), ARTBLOCKS, royaltyAddress, addToCache);
            } catch {}
            try IManifold(royaltyAddress).getRoyalties(tokenId) returns (
                address payable[] memory recipients_, uint256[] memory bps
            ) {
                // Supports manifold interface.  Compute amounts
                return (recipients_, _computeAmounts(value, bps), MANIFOLD, royaltyAddress, addToCache);
            } catch {}
            try IRaribleV1(royaltyAddress).getFeeRecipients(tokenId) returns (address payable[] memory recipients_) {
                // Supports rarible v1 interface. Compute amounts
                recipients_ = IRaribleV1(royaltyAddress).getFeeRecipients(tokenId);
                try IRaribleV1(royaltyAddress).getFeeBps(tokenId) returns (uint256[] memory bps) {
                    return (recipients_, _computeAmounts(value, bps), RARIBLEV1, royaltyAddress, addToCache);
                } catch {}
            } catch {}
            try IFoundation(royaltyAddress).getFees(tokenId) returns (
                address payable[] memory recipients_, uint256[] memory bps
            ) {
                // Supports foundation interface.  Compute amounts
                return (recipients_, _computeAmounts(value, bps), FOUNDATION, royaltyAddress, addToCache);
            } catch {}
            try IZoraOverride(royaltyAddress).convertBidShares(tokenAddress, tokenId) returns (
                address payable[] memory recipients_, uint256[] memory bps
            ) {
                // Support Zora override
                return (recipients_, _computeAmounts(value, bps), ZORA, royaltyAddress, addToCache);
            } catch {}
            try IKODAV2Override(royaltyAddress).getKODAV2RoyaltyInfo(tokenAddress, tokenId, value) returns (
                address payable[] memory _recipients, uint256[] memory _amounts
            ) {
                // Support KODA V2 override
                return (_recipients, _amounts, KNOWNORIGINV2, royaltyAddress, addToCache);
            } catch {}
            // No supported royalties configured
            return (recipients, amounts, NONE, royaltyAddress, addToCache);
        } else {
            // Spec exists, just execute the appropriate one
            addToCache = false;
            if (spec == EIP2981) {
                // EIP2981 spec moved to the top because it will be the most prevalent type
                (address recipient, uint256 amount) = IEIP2981(royaltyAddress).royaltyInfo(tokenId, value);
                recipients = new address payable[](1);
                amounts = new uint256[](1);
                recipients[0] = payable(recipient);
                amounts[0] = amount;
                return (recipients, amounts, spec, royaltyAddress, addToCache);
            } else if (spec == PAINTSWAP) {
                // Paintswap spec
                (CollectionRoyaltyInfo memory info) = IPaintswapRoyalties(PaintSwapRoyaltiesAddress).getCollectionRoyaltyInfo(tokenAddress);
                recipients = new address payable[](1);
                amounts = new uint256[](1);
                recipients[0] = payable(info.recipient);
                amounts[0] = info.fee;
                return (recipients, _computeAmounts(value, amounts), spec, royaltyAddress, addToCache);
            } else if (spec == NFTKEY) {
                 (ERC721CollectionRoyalty memory info)  = INFTKEYMarketplaceRoyalty(NFTKeyMarketV2Address).royalty(tokenAddress);
                recipients = new address payable[](1);
                amounts = new uint256[](1);
                recipients[0] = payable(info.recipient);
                amounts[0] = info.feeFraction;
                return (recipients, _computeAmounts(value, amounts), spec, royaltyAddress, addToCache);
            } else if (spec == MANIFOLD) {
                // Manifold spec
                uint256[] memory bps;
                (recipients, bps) = IManifold(royaltyAddress).getRoyalties(tokenId);
                return (recipients, _computeAmounts(value, bps), spec, royaltyAddress, addToCache);
            } else if (spec == ARTBLOCKS) {
                // Art Blocks spec
                uint256[] memory bps;
                (recipients, bps) = IArtBlocksOverride(royaltyAddress).getRoyalties(tokenAddress, tokenId);
                return (recipients, _computeAmounts(value, bps), spec, royaltyAddress, addToCache);
            } else if (spec == RARIBLEV2) {
                // Rarible v2 spec
                IRaribleV2.Part[] memory royalties;
                royalties = IRaribleV2(royaltyAddress).getRaribleV2Royalties(tokenId);
                recipients = new address payable[](royalties.length);
                amounts = new uint256[](royalties.length);
                uint256 totalAmount;
                for (uint256 i; i < royalties.length;) {
                    recipients[i] = royalties[i].account;
                    amounts[i] = value * royalties[i].value / 10000;
                    totalAmount += amounts[i];
                    unchecked {
                        ++i;
                    }
                }
                return (recipients, amounts, spec, royaltyAddress, addToCache);
            } else if (spec == RARIBLEV1) {
                // Rarible v1 spec
                uint256[] memory bps;
                recipients = IRaribleV1(royaltyAddress).getFeeRecipients(tokenId);
                bps = IRaribleV1(royaltyAddress).getFeeBps(tokenId);
                return (recipients, _computeAmounts(value, bps), spec, royaltyAddress, addToCache);
            } else if (spec == FOUNDATION) {
                // Foundation spec
                uint256[] memory bps;
                (recipients, bps) = IFoundation(royaltyAddress).getFees(tokenId);
                return (recipients, _computeAmounts(value, bps), spec, royaltyAddress, addToCache);
            } else if (spec == ZORA) {
                // Zora spec
                uint256[] memory bps;
                (recipients, bps) = IZoraOverride(royaltyAddress).convertBidShares(tokenAddress, tokenId);
                return (recipients, _computeAmounts(value, bps), spec, royaltyAddress, addToCache);
            } else if (spec == KNOWNORIGINV2) {
                // KnownOrigin.io V2 spec (V3 falls under EIP2981)
                (recipients, amounts) =
                    IKODAV2Override(royaltyAddress).getKODAV2RoyaltyInfo(tokenAddress, tokenId, value);
                return (recipients, amounts, spec, royaltyAddress, addToCache);
            }
        }
    }


    /**
     * Compute royalty amounts
     */
    function _computeAmounts(uint256 value, uint256[] memory bps) private pure returns (uint256[] memory amounts) {
        uint256 numBps = bps.length;
        amounts = new uint256[](numBps);
        uint256 totalAmount;
        for (uint256 i; i < numBps;) {
            amounts[i] = value * bps[i] / 10000;
            totalAmount += amounts[i];
            unchecked {
                ++i;
            }
        }
        return amounts;
    }

    function _checkAmountsDoesNotExceedValue(uint256 saleAmount, uint256[] memory royalties) private pure {
        uint256 numRoyalties = royalties.length;
        uint256 totalRoyalties;
        for (uint256 i; i < numRoyalties;) {
            totalRoyalties += royalties[i];
            unchecked {
                ++i;
            }
        }
        if (totalRoyalties > saleAmount) revert RoyaltyEngine__InvalidRoyaltyAmount();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Lookup engine interface
 */
interface IRoyaltyEngineV1 is IERC165 {
    /**
     * Get the royalty for a given token (address, id) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value)
        external
        returns (address payable[] memory recipients, uint256[] memory amounts);

    /**
     * View only version of getRoyalty
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyaltyView(address tokenAddress, uint256 tokenId, uint256 value)
        external
        view
        returns (address payable[] memory recipients, uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Royalty registry interface
 */
interface IRoyaltyRegistry is IERC165 {
    event RoyaltyOverride(address owner, address tokenAddress, address royaltyAddress);

    /**
     * Override the location of where to look up royalty information for a given token contract.
     * Allows for backwards compatibility and implementation of royalty logic for contracts that did not previously support them.
     *
     * @param tokenAddress    - The token address you wish to override
     * @param royaltyAddress  - The royalty override address
     */
    function setRoyaltyLookupAddress(address tokenAddress, address royaltyAddress) external returns (bool);

    /**
     * Returns royalty address location.  Returns the tokenAddress by default, or the override if it exists
     *
     * @param tokenAddress    - The token address you are looking up the royalty for
     */
    function getRoyaltyLookupAddress(address tokenAddress) external view returns (address);

    /**
     * Returns the token address that an overrideAddress is set for.
     * Note: will not be accurate if the override was created before this function was added.
     *
     * @param overrideAddress - The override address you are looking up the token for
     */
    function getOverrideLookupTokenAddress(address overrideAddress) external view returns (address);

    /**
     * Whether or not the message sender can override the royalty address for the given token address
     *
     * @param tokenAddress    - The token address you are looking up the royalty for
     */
    function overrideAllowed(address tokenAddress) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 *  Interface for an Art Blocks override
 */
interface IArtBlocksOverride {
    /**
     * @dev Get royalites of a token at a given tokenAddress.
     *      Returns array of receivers and basisPoints.
     *
     *  bytes4(keccak256('getRoyalties(address,uint256)')) == 0x9ca7dc7a
     *
     *  => 0x9ca7dc7a = 0x9ca7dc7a
     */
    function getRoyalties(address tokenAddress, uint256 tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * EIP-2981
 */
interface IEIP2981 {
    /**
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     *
     * => 0x2a55205a = 0x2a55205a
     */
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFoundation {
    /*
     *  bytes4(keccak256('getFees(uint256)')) == 0xd5a06d4c
     *
     *  => 0xd5a06d4c = 0xd5a06d4c
     */
    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
}

interface IFoundationTreasuryNode {
    function getFoundationTreasury() external view returns (address payable);
}

interface IFoundationTreasury {
    function isAdmin(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT

/// @author: knownorigin.io

pragma solidity ^0.8.0;

interface IKODAV2 {
    function editionOfTokenId(uint256 _tokenId) external view returns (uint256 _editionNumber);

    function artistCommission(uint256 _editionNumber)
        external
        view
        returns (address _artistAccount, uint256 _artistCommission);

    function editionOptionalCommission(uint256 _editionNumber)
        external
        view
        returns (uint256 _rate, address _recipient);
}

interface IKODAV2Override {
    /// @notice Emitted when the royalties fee changes
    event CreatorRoyaltiesFeeUpdated(uint256 _oldCreatorRoyaltiesFee, uint256 _newCreatorRoyaltiesFee);

    /// @notice For the given KO NFT and token ID, return the addresses and the amounts to pay
    function getKODAV2RoyaltyInfo(address _tokenAddress, uint256 _id, uint256 _amount)
        external
        view
        returns (address payable[] memory, uint256[] memory);

    /// @notice Allows the owner() to update the creator royalties
    function updateCreatorRoyalties(uint256 _creatorRoyaltiesFee) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRaribleV1 {
    /*
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
    function getFeeBps(uint256 id) external view returns (uint256[] memory);
    function getFeeRecipients(uint256 id) external view returns (address payable[] memory);
}

interface IRaribleV2 {
    /*
     *  bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
     */
    struct Part {
        address payable account;
        uint96 value;
    }

    function getRaribleV2Royalties(uint256 id) external view returns (Part[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISuperRareRegistry {
    /**
     * @dev Get the royalty fee percentage for a specific ERC721 contract.
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     * @return uint8 wei royalty fee.
     */
    function getERC721TokenRoyaltyPercentage(address _contractAddress, uint256 _tokenId)
        external
        view
        returns (uint8);

    /**
     * @dev Utililty function to calculate the royalty fee for a token.
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculateRoyaltyFee(address _contractAddress, uint256 _tokenId, uint256 _amount)
        external
        view
        returns (uint256);

    /**
     * @dev Get the token creator which will receive royalties of the given token
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     */
    function tokenCreator(address _contractAddress, uint256 _tokenId) external view returns (address payable);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Paired down version of the Zora Market interface
 */
interface IZoraMarket {
    struct ZoraDecimal {
        uint256 value;
    }

    struct ZoraBidShares {
        // % of sale value that goes to the _previous_ owner of the nft
        ZoraDecimal prevOwner;
        // % of sale value that goes to the original creator of the nft
        ZoraDecimal creator;
        // % of sale value that goes to the seller (current owner) of the nft
        ZoraDecimal owner;
    }

    function bidSharesForToken(uint256 tokenId) external view returns (ZoraBidShares memory);
}

/**
 * Paired down version of the Zora Media interface
 */
interface IZoraMedia {
    /**
     * Auto-generated accessors of public variables
     */
    function marketContract() external view returns (address);
    function previousTokenOwners(uint256 tokenId) external view returns (address);
    function tokenCreators(uint256 tokenId) external view returns (address);

    /**
     * ERC721 function
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

/**
 * Interface for a Zora media override
 */
interface IZoraOverride {
    /**
     * @dev Convert bid share configuration of a Zora Media token into an array of receivers and bps values
     *      Does not support prevOwner and sell-on amounts as that is specific to Zora marketplace implementation
     *      and requires updates on the Zora Media and Marketplace to update the sell-on amounts/previous owner values.
     *      An off-Zora marketplace sale will break the sell-on functionality.
     */
    function convertBidShares(address media, uint256 tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory);
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

// SPDX-License-Identifier: AGPL-3.0-or-later


pragma solidity ^0.8.0;
pragma abicoder v2;

    struct ERC721CollectionRoyalty {
        address recipient;
        uint256 feeFraction;
        address setBy;
    }
interface INFTKEYMarketplaceRoyalty {

    // Who can set: ERC721 owner and NFTKEY owner
    event SetRoyalty(
        address indexed erc721Address,
        address indexed recipient,
        uint256 feeFraction
    );

    /**
     * @dev Royalty fee
     * @param erc721Address to read royalty
     * @return royalty information
     */
    function royalty(address erc721Address)
        external
        view
        returns (ERC721CollectionRoyalty memory);

    /**
     * @dev Royalty fee
     * @param erc721Address to read royalty
     */
    function setRoyalty(
        address erc721Address,
        address recipient,
        uint256 feeFraction
    ) external;
}
address constant NFTKeyMarketV2Address=0x1A7d6ed890b6C284271AD27E7AbE8Fb5211D0739;

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
  struct CollectionRoyaltyInfo {
    address recipient;
    uint16 fee;
  }

interface IPaintswapRoyalties {


  function getCollectionRoyaltyInfo(address _addr) external view returns (CollectionRoyaltyInfo memory) ;
}
address constant PaintSwapRoyaltiesAddress=0x809D88B727c4C7024462d7955777835938F02F3B;