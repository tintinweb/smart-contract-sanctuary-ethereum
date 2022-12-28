// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
pragma solidity 0.7.5;

import {IERC165} from "@openzeppelin/contracts/introspection/IERC165.sol";

import {IRoyaltyFeeRegistry} from "./interfaces/IRoyaltyFeeRegistry.sol";
import {IOwnable} from "./interfaces/IOwnable.sol";

/**
 * @title RoyaltyFeeSetter
 * @notice It is used to allow creators to set royalty parameters in the RoyaltyFeeRegistry.
 */
contract RoyaltyFeeSetter {
    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    address public immutable royaltyFeeRegistry;

    /**
     * @notice Constructor
     * @param _royaltyFeeRegistry address of the royalty fee registry
     */
    constructor(address _royaltyFeeRegistry) {
        royaltyFeeRegistry = _royaltyFeeRegistry;
    }

    /**
     * @notice Update royalty info for collection if owner
     * @dev Only to be called if there is no setter address
     * @param collection address of the NFT contract
     * @param setter address that sets the receiver
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForCollectionIfOwner(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external {
        require(
            msg.sender == IOwnable(collection).owner(),
            "Owner: Not the owner"
        );

        _updateRoyaltyInfoForCollectionIfOwner(
            collection,
            setter,
            receiver,
            fee
        );
    }

    /**
     * @notice Update information and perform checks before updating royalty fee registry
     * @param collection address of the NFT contract
     * @param setter address that sets the receiver
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function _updateRoyaltyInfoForCollectionIfOwner(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) internal {
        require(
            (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721) ||
                IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)),
            "Setter: Not ERC721/ERC1155"
        );

        IRoyaltyFeeRegistry(royaltyFeeRegistry).updateRoyaltyInfoForCollection(
            collection,
            setter,
            receiver,
            fee
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IOwnable {
    function owner() external view returns (address);

    function admin() external view returns (address);

    function transferOwnership(address _newOwner) external returns (bool);

    function renounceOwnership() external returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IRoyaltyFeeRegistry {
    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external;

    function updateRoyaltyInfoForCollection(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external;

    function royaltyInfo(address collection, uint256 amount)
        external
        view
        returns (address, uint256);

    function royaltyFeeInfoCollection(address collection)
        external
        view
        returns (
            address,
            address,
            uint256
        );
}