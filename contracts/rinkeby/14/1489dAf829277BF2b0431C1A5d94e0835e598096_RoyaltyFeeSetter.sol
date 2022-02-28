// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "./Ownable.sol";
import {IERC165} from "./IERC165.sol";

import {IRoyaltyFeeRegistry} from "./IRoyaltyFeeRegistry.sol";
import {IOwnable} from "./IOwnable.sol";

/**
 * @title RoyaltyFeeSetter
 * @notice It is used to allow creators to set royalty parameters in the RoyaltyFeeRegistry.
 */
contract RoyaltyFeeSetter is Ownable {
    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    // ERC2981 interfaceID
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    address public immutable royaltyFeeRegistry;

    /**
     * @notice Constructor
     * @param _royaltyFeeRegistry address of the royalty fee registry
     */
    constructor(address _royaltyFeeRegistry) {
        royaltyFeeRegistry = _royaltyFeeRegistry;
    }

    /**
     * @notice Update royalty info for collection if admin
     * @dev Only to be called if there is no setter address
     * @param collection address of the NFT contract
     * @param setter address that sets the receiver
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForCollectionIfAdmin(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external {
        require(!IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981), "Admin: Must not be ERC2981");
        require(msg.sender == IOwnable(collection).admin(), "Admin: Not the admin");

        _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(collection, setter, receiver, fee);
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
        require(!IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981), "Owner: Must not be ERC2981");
        require(msg.sender == IOwnable(collection).owner(), "Owner: Not the owner");

        _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(collection, setter, receiver, fee);
    }

    /**
     * @notice Update royalty info for collection
     * @dev Only to be called if there msg.sender is the setter
     * @param collection address of the NFT contract
     * @param setter address that sets the receiver
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForCollectionIfSetter(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external {
        (address currentSetter, , ) = IRoyaltyFeeRegistry(royaltyFeeRegistry).royaltyFeeInfoCollection(collection);
        require(msg.sender == currentSetter, "Setter: Not the setter");

        IRoyaltyFeeRegistry(royaltyFeeRegistry).updateRoyaltyInfoForCollection(collection, setter, receiver, fee);
    }

    /**
     * @notice Update royalty info for collection
     * @dev Can only be called by contract owner (of this)
     * @param collection address of the NFT contract
     * @param setter address that sets the receiver
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForCollection(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external onlyOwner {
        IRoyaltyFeeRegistry(royaltyFeeRegistry).updateRoyaltyInfoForCollection(collection, setter, receiver, fee);
    }

    /**
     * @notice Update owner of royalty fee registry
     * @dev Can be used for migration of this royalty fee setter contract
     * @param _owner new owner address
     */
    function updateOwnerOfRoyaltyFeeRegistry(address _owner) external onlyOwner {
        IOwnable(royaltyFeeRegistry).transferOwnership(_owner);
    }

    /**
     * @notice Update royalty info for collection
     * @param _royaltyFeeLimit new royalty fee limit (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external onlyOwner {
        IRoyaltyFeeRegistry(royaltyFeeRegistry).updateRoyaltyFeeLimit(_royaltyFeeLimit);
    }

    /**
     * @notice Check royalty info for collection
     * @param collection collection address
     * @return (whether there is a setter (address(0 if not)),
     * Position
     * 0: Royalty setter is set in the registry
     * 1: ERC2981 and no setter
     * 2: setter can be set using owner()
     * 3: setter can be set using admin()
     * 4: setter cannot be set, nor support for ERC2981
     */
    function checkForCollectionSetter(address collection) external view returns (address, uint8) {
        (address currentSetter, , ) = IRoyaltyFeeRegistry(royaltyFeeRegistry).royaltyFeeInfoCollection(collection);

        if (currentSetter != address(0)) {
            return (currentSetter, 0);
        }

        try IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981) returns (bool interfaceSupport) {
            if (interfaceSupport) {
                return (address(0), 1);
            }
        } catch {}

        try IOwnable(collection).owner() returns (address setter) {
            return (setter, 2);
        } catch {
            try IOwnable(collection).admin() returns (address setter) {
                return (setter, 3);
            } catch {
                return (address(0), 4);
            }
        }
    }

    /**
     * @notice Update information and perform checks before updating royalty fee registry
     * @param collection address of the NFT contract
     * @param setter address that sets the receiver
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) internal {
        (address currentSetter, , ) = IRoyaltyFeeRegistry(royaltyFeeRegistry).royaltyFeeInfoCollection(collection);
        require(currentSetter == address(0), "Setter: Already set");

        require(
            (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721) ||
                IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)),
            "Setter: Not ERC721/ERC1155"
        );

        IRoyaltyFeeRegistry(royaltyFeeRegistry).updateRoyaltyInfoForCollection(collection, setter, receiver, fee);
    }
}