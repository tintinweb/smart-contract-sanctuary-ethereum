// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ERC2981Storage } from './ERC2981Storage.sol';
import { ERC2981Internal } from './ERC2981Internal.sol';

/**
 * @title ERC2981 implementation
 */
abstract contract ERC2981 is ERC2981Internal {
    /**
     * @notice inheritdoc IERC2981
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address, uint256) {
        return _royaltyInfo(tokenId, salePrice);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ERC2981Storage } from './ERC2981Storage.sol';

/**
 * @title ERC2981 internal functions
 */
abstract contract ERC2981Internal {
    /**
     * @notice calculate how much royalty is owed and to whom
     * @dev royalty must be paid in addition to, rather than deducted from, salePrice
     * @param tokenId the ERC721 or ERC1155 token id to query for royalty information
     * @param salePrice the sale price of the given asset
     * @return royaltyReceiver rightful recipient of royalty
     * @return royalty amount of royalty owed
     */
    function _royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) internal view virtual returns (address royaltyReceiver, uint256 royalty) {
        uint256 royaltyBPS = _getRoyaltyBPS(tokenId);

        // intermediate multiplication overflow is theoretically possible here, but
        // not an issue in practice because of practical constraints of salePrice
        return (_getRoyaltyReceiver(tokenId), (royaltyBPS * salePrice) / 10000);
    }

    /**
     * @notice query the royalty rate (denominated in basis points) for given token id
     * @dev implementation supports per-token-id values as well as a global default
     * @param tokenId token whose royalty rate to query
     * @return royaltyBPS royalty rate
     */
    function _getRoyaltyBPS(
        uint256 tokenId
    ) internal view virtual returns (uint16 royaltyBPS) {
        ERC2981Storage.Layout storage l = ERC2981Storage.layout();
        royaltyBPS = l.royaltiesBPS[tokenId];

        if (royaltyBPS == 0) {
            royaltyBPS = l.defaultRoyaltyBPS;
        }
    }

    /**
     * @notice query the royalty receiver for given token id
     * @dev implementation supports per-token-id values as well as a global default
     * @param tokenId token whose royalty receiver to query
     * @return royaltyReceiver royalty receiver
     */
    function _getRoyaltyReceiver(
        uint256 tokenId
    ) internal view virtual returns (address royaltyReceiver) {
        ERC2981Storage.Layout storage l = ERC2981Storage.layout();
        royaltyReceiver = l.royaltyReceivers[tokenId];

        if (royaltyReceiver == address(0)) {
            royaltyReceiver = l.defaultRoyaltyReceiver;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC2981Storage {
    struct Layout {
        // token id -> royalty (denominated in basis points)
        mapping(uint256 => uint16) royaltiesBPS;
        uint16 defaultRoyaltyBPS;
        // token id -> receiver address
        mapping(uint256 => address) royaltyReceivers;
        address defaultRoyaltyReceiver;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC2981');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC2981} from "./ERC2981/ERC2981.sol";

contract ERC2981Facet is ERC2981 {}