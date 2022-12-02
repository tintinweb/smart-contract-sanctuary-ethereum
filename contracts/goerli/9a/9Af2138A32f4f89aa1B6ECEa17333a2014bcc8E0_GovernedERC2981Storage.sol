// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { ERC165 } from './ERC165.sol';
import { StorageBase } from './StorageBase.sol';

import { IERC165 } from './interfaces/IERC165.sol';
import { IGovernedERC2981 } from './interfaces/IGovernedERC2981.sol';
import { IGovernedContract } from './interfaces/IGovernedContract.sol';
import { IGovernedERC2981Storage } from './interfaces/IGovernedERC2981Storage.sol';

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
 */
contract GovernedERC2981Storage is StorageBase, IGovernedERC2981Storage {

    RoyaltyInfo private _defaultRoyaltyInfo;

    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    function getDefaultRoyaltyInfo() external view override returns (address, uint96) {
        return(_defaultRoyaltyInfo.receiver, _defaultRoyaltyInfo.royaltyFraction);
    }

    function getTokenRoyaltyInfo(uint256 _tokenId) external view override returns (address, uint96) {
        return(_tokenRoyaltyInfo[_tokenId].receiver, _tokenRoyaltyInfo[_tokenId].royaltyFraction);
    }

    function setDefaultRoyaltyInfo(address _receiver, uint96 _royaltyFraction) external override requireOwner {
        _defaultRoyaltyInfo = RoyaltyInfo(_receiver, _royaltyFraction);
    }

    function deleteDefaultRoyaltyInfo() external override requireOwner {
        delete _defaultRoyaltyInfo;
    }

    function setTokenRoyaltyInfo(uint256 _tokenId, address _receiver, uint96 _royaltyFraction) external override requireOwner {
        _tokenRoyaltyInfo[_tokenId] = RoyaltyInfo(_receiver, _royaltyFraction);
    }

    function resetTokenRoyaltyInfo(uint256 _tokenId) external override requireOwner {
        delete _tokenRoyaltyInfo[_tokenId];
    }
}

contract GovernedERC2981 is IGovernedERC2981, ERC165 {

    GovernedERC2981Storage public governedERC2981Storage;

    constructor() {
        governedERC2981Storage = new GovernedERC2981Storage();
    }

    // This function is called in order to upgrade to a new ERC1155 implementation
    function _destroyERC2981(IGovernedContract _newImplementation) internal {
        governedERC2981Storage.setOwner(_newImplementation);
    }

    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function _migrateERC2981(address _oldImplementation) internal {
        governedERC2981Storage = GovernedERC2981Storage(
            IGovernedERC2981(_oldImplementation).governedERC2981Storage()
        );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165)
        returns (bool)
    {
        return interfaceId == type(IGovernedERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IGovernedERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        (address receiver, uint96 royaltyFraction) = governedERC2981Storage.getTokenRoyaltyInfo(_tokenId);

        if (receiver == address(0)) {
            (receiver, royaltyFraction) = governedERC2981Storage.getDefaultRoyaltyInfo();
        }

        uint256 royaltyAmount = (_salePrice * royaltyFraction) / _feeDenominator();

        return (receiver, royaltyAmount);
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
        require(
            feeNumerator <= _feeDenominator(),
            'GovernedERC2981::_setDefaultRoyalty: royalty fee will exceed salePrice'
        );
        require(
            receiver != address(0),
            'GovernedERC2981::_setDefaultRoyalty: zero address can not receive royalties'
        );

        governedERC2981Storage.setDefaultRoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        governedERC2981Storage.deleteDefaultRoyaltyInfo();
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(
            feeNumerator <= _feeDenominator(),
            'GovernedERC2981::_setTokenRoyalty: royalty fee will exceed salePrice'
        );
        require(
            receiver != address(0),
            'GovernedERC2981::_setTokenRoyalty: zero address can not receive royalties'
        );

        governedERC2981Storage.setTokenRoyaltyInfo(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        governedERC2981Storage.resetTokenRoyaltyInfo(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IGovernedERC2981Storage {

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    function getDefaultRoyaltyInfo() external view returns (address, uint96);

    function getTokenRoyaltyInfo(uint256 _tokenId) external view returns (address, uint96);

    function setDefaultRoyaltyInfo(address _receiver, uint96 _royaltyFraction) external;

    function deleteDefaultRoyaltyInfo() external;

    function setTokenRoyaltyInfo(uint256 _tokenId, address _receiver, uint96 _royaltyFraction) external;

    function resetTokenRoyaltyInfo(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { IERC165 } from './IERC165.sol';

import { GovernedERC2981Storage } from '../GovernedERC2981.sol';

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IGovernedERC2981 is IERC165 {

    function governedERC2981Storage()
        external
        view
        returns (GovernedERC2981Storage governedERC2981Storage);

    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * Genesis version of GovernedContract interface.
 *
 * Base Consensus interface for upgradable contracts.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */

interface IGovernedContract {
    // Return actual proxy address for secure validation
    function proxy() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

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

pragma solidity 0.8.15;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * Base for contract storage (SC-14).
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */

contract StorageBase {
    address payable internal owner;

    modifier requireOwner() {
        require(msg.sender == address(owner), 'StorageBase: Not owner!');
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function setOwner(IGovernedContract _newOwner) external requireOwner {
        owner = payable(address(uint160(address(_newOwner))));
    }

    function kill() external requireOwner {
        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { IERC165 } from './interfaces/IERC165.sol';

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
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}