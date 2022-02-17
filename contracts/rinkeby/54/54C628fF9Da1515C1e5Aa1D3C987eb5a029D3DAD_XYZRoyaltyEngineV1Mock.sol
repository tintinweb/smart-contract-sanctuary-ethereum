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
    function getRoyalty(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    ) external returns (address payable[] memory recipients, uint256[] memory amounts);

    /**
     * View only version of getRoyalty
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyaltyView(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    ) external view returns (address payable[] memory recipients, uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IRoyaltyEngineV1} from "../interfaces/external/IRoyaltyEngineV1.sol";

struct RoyaltyReceiver {
    address payable receiver;
    uint256 percentage; // 500 -> 5 %
}

contract XYZRoyaltyEngineV1Mock is IRoyaltyEngineV1 {
    mapping(address => RoyaltyReceiver[]) public royalties;

    /**
     * Interface functions
     */
    function getRoyalty(
        address tokenAddress,
        uint256,
        uint256 value
    ) external view returns (address payable[] memory recipients, uint256[] memory amounts) {
        return _getRoyalties(tokenAddress, value);
    }

    function getRoyaltyView(
        address tokenAddress,
        uint256,
        uint256 value
    ) external view returns (address payable[] memory recipients, uint256[] memory amounts) {
        return _getRoyalties(tokenAddress, value);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IRoyaltyEngineV1).interfaceId;
    }

    /**
     * Custom setters
     */
    function addRoyaltyReceiver(
        address _collection,
        address _receiver,
        uint256 _percentage
    ) external {
        RoyaltyReceiver memory receiverToAdd = RoyaltyReceiver({receiver: payable(_receiver), percentage: _percentage});
        uint256 nextIndex = royalties[_collection].length;
        royalties[_collection][nextIndex] = receiverToAdd;
    }

    function removeRoyalyReceiver(address _collection, uint256 _index) external {
        uint256 receiversCount = royalties[_collection].length;
        require(_index < receiversCount, "Non extistend index");
        royalties[_collection][_index] = RoyaltyReceiver({receiver: payable(address(0)), percentage: 0});
    }

    function _getRoyalties(address tokenAddress, uint256 value)
        private
        view
        returns (address payable[] memory, uint256[] memory)
    {
        RoyaltyReceiver[] memory collectionRoyalties = royalties[tokenAddress];
        address payable[] memory receivers = new address payable[](collectionRoyalties.length);
        uint256[] memory amounts = new uint256[](collectionRoyalties.length);

        for (uint256 i = 0; i < collectionRoyalties.length; i++) {
            address payable royaltyReceiver = collectionRoyalties[i].receiver;
            uint256 percentage = collectionRoyalties[i].percentage;
            uint256 royaltyAmount;

            if (percentage != type(uint8).max) royaltyAmount = (value * percentage) / 1000;
            receivers[i] = royaltyReceiver;
            amounts[i] = royaltyAmount;
        }

        return (receivers, amounts);
    }
}