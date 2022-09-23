// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

import "./ERC2981/ERC2981.sol";

/// @title FamiliarAdmin
/// @notice NFT implementation-specific restricted functions
/// @dev Logic implementation or base contracts other 
/// @dev than CommonStorage must not declare any state variables
contract FamiliarAdmin is ERC2981 {

    //----------------------- EVENTS -------------------------------------------

    event royaltyUpdated(address indexed beneficiary, uint96 fee, uint256 tokenId);

    //----------------------- VIEW FUNCTIONS -----------------------------------

     /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId;
    }

    //-------------------- MUTATIVE FUNCTIONS ----------------------------------

    /// @notice Sets default royalty information for all tokens
    /// @param _receiver        is royalty beneficiary. Cannot be address 0
    /// @param _feeNumerator    is percentage of sales price to be paid, in basis points
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external {
        _setDefaultRoyalty(_receiver, _feeNumerator);
        emit royaltyUpdated(_receiver, _feeNumerator, 0);
    }

    /// @notice Sets specific royalty information for a specific token ID
    /// @param _tokenId         is id of token to apply royalty information
    /// @param _receiver        is royalty beneficiary. Cannot be address 0
    /// @param _feeNumerator    is percentage of sales price to be paid, in basis points
    function setTokenRoyalty(uint256 _tokenId, address _receiver, uint96 _feeNumerator) external {
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
        emit royaltyUpdated(_receiver, _feeNumerator, _tokenId);
    }

    /// @notice deletes default royalty information.
    function deleteDefaultRoyalty() external {
        _deleteDefaultRoyalty();
        emit royaltyUpdated(address(0), 0, 0);
    }

    /// @notice deletes royalty information for specific token Id.
    /// @param _tokenId     of token to delete royalty information
    function resetTokenRoyalty(uint256 _tokenId) external {
        _resetTokenRoyalty(_tokenId);
        RoyaltyInfo memory royalty = defaultRoyaltyInfo;
        emit royaltyUpdated(royalty.receiver, royalty.royaltyFraction, _tokenId);
    }        
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "../CommonStorage.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 *
 * Custom ERC2981 implementation based on 
 * OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol).
 * Storage pattern for upgradable proxy requires no state variables
 * defined in logic contract.
 */
abstract contract ERC2981 is CommonStorage, IERC2981 {

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

/// @title CommonStorage
/// @notice Defines all state variables to be maintained by proxy and
/// @notice implementation contracts.
abstract contract CommonStorage {

    //------------------ STATE VARIABLES ---------------------------------------
    
    // Maintain IMX integration data
    address internal imx;
    mapping(uint256 => bytes) internal blueprints;

    // Maintain ERC721 NFT and royalty data
    string internal names;
    string internal symbols;
    string internal rootURI;
    mapping(uint256 => address) internal owners;
    mapping(address => uint256) internal balances;
    mapping(uint256 => address) internal tokenApprovals;
    mapping(address => mapping(address => bool)) internal operatorApprovals;
    struct RoyaltyInfo { address receiver; uint96 royaltyFraction; }
    RoyaltyInfo internal defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) internal tokenRoyaltyInfo;

    // Maintain proxy administration and routing data
    address internal admin;
    bool internal initializing;
    mapping(address => bool) internal initialized;
    mapping(address => address) internal callRouting;
    mapping(address => string) internal version;

    // Maintain generic state variables
    // Pattern to allow expansion of state variables in future implementations
    // without risking storage-collision
    mapping(string => address) internal address_;
    mapping(string => uint) internal uint_;
    mapping(string => int) internal int_;
    mapping(string => bytes) internal bytes_;
    mapping(string => string) internal string_;
    mapping(string => bool) internal bool_;
    mapping(string => bytes[]) internal array_;
    mapping(string => mapping(string => bytes[])) internal mapping_;

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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}