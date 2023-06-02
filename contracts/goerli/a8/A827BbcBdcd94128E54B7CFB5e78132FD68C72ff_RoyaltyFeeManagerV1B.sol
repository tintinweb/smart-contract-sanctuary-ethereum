// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

import {IRoyaltyFeeManager} from "./interfaces/IRoyaltyFeeManager.sol";
import {IRoyaltyFeeRegistry} from "./interfaces/IRoyaltyFeeRegistry.sol";

/**
 * @title RoyaltyFeeManagerV1B
 * @notice It handles the logic to check and transfer rebate fees (if any).
 */
contract RoyaltyFeeManagerV1B is IRoyaltyFeeManager {
    // Interface Id ERC2981
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    // Standard royalty fee
    uint256 public constant STANDARD_ROYALTY_FEE = 50;

    // Royalty fee registry
    IRoyaltyFeeRegistry public immutable royaltyFeeRegistry;

    /**
     * @notice Constructor
     * @param _royaltyFeeRegistry Royalty fee registry address
     */
    constructor(address _royaltyFeeRegistry) {
        royaltyFeeRegistry = IRoyaltyFeeRegistry(_royaltyFeeRegistry);
    }

    /**
     * @notice Calculate royalty fee and get recipient
     * @param collection address of the NFT contract
     * @param tokenId tokenId
     * @param amount amount to transfer
     */
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        // 1. Check if there is a royalty info in the system
        if (IERC2981(collection).supportsInterface(INTERFACE_ID_ERC2981)) {
            (bool status, bytes memory data) = collection.staticcall(
                abi.encodeWithSelector(IERC2981.royaltyInfo.selector, tokenId, amount)
            );
            if (status) {
                (receiver, royaltyAmount) = abi.decode(data, (address, uint256));
            }
        }

        // 2. If the receiver is address(0), check if it supports the ERC2981 interface
        if (receiver == address(0)) {
            (receiver, royaltyAmount) = royaltyFeeRegistry.royaltyInfo(collection, amount);
        }

        // A fixed royalty fee is applied
        // if (receiver != address(0)) {
        //     royaltyAmount = (STANDARD_ROYALTY_FEE * amount) / 10000;
        // }
    }
    // function calculateRoyaltyFeeAndGetRecipient(
    //     address collection,
    //     uint256 tokenId,
    //     uint256 amount
    // ) external view override returns (address receiver, uint256 royaltyAmount) {
    //     // 1. Check if there is a royalty info in the system
    //     (receiver, ) = royaltyFeeRegistry.royaltyInfo(collection, amount);

    //     // 2. If the receiver is address(0), check if it supports the ERC2981 interface
    //     if (receiver == address(0)) {
    //         if (IERC2981(collection).supportsInterface(INTERFACE_ID_ERC2981)) {
    //             (bool status, bytes memory data) = collection.staticcall(
    //                 abi.encodeWithSelector(IERC2981.royaltyInfo.selector, tokenId, amount)
    //             );
    //             if (status) {
    //                 (receiver, ) = abi.decode(data, (address, uint256));
    //             }
    //         }
    //     }

    //     // A fixed royalty fee is applied
    //     if (receiver != address(0)) {
    //         royaltyAmount = (STANDARD_ROYALTY_FEE * amount) / 10000;
    //     }
    // }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoyaltyFeeManager {
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoyaltyFeeRegistry {
    function updateRoyaltyInfoForCollection(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external;

    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external;

    function royaltyInfo(address collection, uint256 amount) external view returns (address, uint256);

    function royaltyFeeInfoCollection(address collection)
        external
        view
        returns (
            address,
            address,
            uint256
        );
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