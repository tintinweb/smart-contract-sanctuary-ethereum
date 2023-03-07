// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract SkullSwap {
    address private constant skullsAddress = address(0x9251dEC8DF720C2ADF3B6f46d968107cbBADf4d4);
    /// @dev The address of a Skulls contract on Goerli. Remove and use the one above for mainnet.
    //    address private constant skullsAddress = address(0xb18B7FF47A460C08999804804636345dd43722b6);

    /**
     * Skulls that owners want to swap for another skull.
     * @notice A listing is only for visibility. Anyone can offer a swap for any skull.
     * @dev Interfaces for this contract should highlight skulls that are listed.
     */
    mapping(uint256 => uint256) public listings;

    /**
     * Offers for a skull that that owner can accept.
     * @dev A mapping of skull ID to a mapping of all offered skulls.
     * @dev Nested mapping points to the owner and expiry of the offer
     */
    mapping(uint256 => mapping(uint256 => uint256)) public offers;
    /**
     * Offers for a skull that that owner can accept.
     * @dev A mapping of skull ID to a mapping of all offered skulls.
     * @dev Nested mapping points to the owner and expiry of the offer
     */
    mapping(uint256 => mapping(uint256 => address)) private offerers;

    event Offer(uint256 indexed offeredTokenId, uint256 indexed tokenId, uint256 expiry);
    event Listing(uint256 indexed tokenId, bool active);

    /**
     * @notice Offer to swap your skull for another skull.
     * @notice The skull you offer to swap yours for does not need to be listed.
     * @dev offeredTokenId must be owned by msg.sender.
     * @param offeredTokenId The ID of the skull to offer.
     * @param tokenId The ID of the skull to swap for.
     * @param expiry The time at which the offer expires.
     */
    function offerSwap(uint256 offeredTokenId, uint256 tokenId, uint256 expiry) external {
        require(IERC721A(skullsAddress).ownerOf(offeredTokenId) == msg.sender, "You must own the offered token");

        offers[tokenId][offeredTokenId] = expiry;
        offerers[tokenId][offeredTokenId] = msg.sender;

        emit Offer(offeredTokenId, tokenId, expiry);
    }

    /**
     * @notice Accept an offer to swap your skull for another skull.
     * @dev The skull must be approved for transfer by this contract.
     * @param tokenId The ID of the skull to swap.
     * @param offeredTokenId The ID of the skull that was offered.
     */
    function acceptSwap(uint256 tokenId, uint256 offeredTokenId) external {
        uint256 offer = offers[tokenId][offeredTokenId];
        if (offer <= block.timestamp) {
            revert("Offer invalid");
        }

        address tokenOwner = IERC721A(skullsAddress).ownerOf(tokenId);
        require(tokenOwner == msg.sender, "Not owner");

        address offerOwner = offerers[tokenId][offeredTokenId];
        address offeredTokenOwner = IERC721A(skullsAddress).ownerOf(offeredTokenId);
        require(offeredTokenOwner == offerOwner, "Offer owner changed");

        IERC721A(skullsAddress).transferFrom(msg.sender, offerOwner, tokenId);
        IERC721A(skullsAddress).transferFrom(offerOwner, msg.sender, offeredTokenId);

        delete offers[tokenId][offeredTokenId];
        delete offerers[tokenId][offeredTokenId];
        delete listings[tokenId];

        emit Offer(offeredTokenId, tokenId, 0);
    }

    /**
     * @notice Remove an offer.
     * @param tokenId The ID of the skull to remove the offer for.
     * @param offeredTokenId The ID of the skull that was offered.
     */
    function removeOffer(uint256 tokenId, uint256 offeredTokenId) external {
        require(
            IERC721A(skullsAddress).ownerOf(offeredTokenId) == msg.sender,
            "You must own the offered token to remove a swap"
        );

        delete offers[tokenId][offeredTokenId];
        delete offerers[tokenId][offeredTokenId];

        emit Offer(offeredTokenId, tokenId, 0);
    }

    /**
     * @notice List a skull for swap.
     * @param tokenId The ID of the skull to list.
     */

    function listForSwap(uint256 tokenId) external {
        require(IERC721A(skullsAddress).ownerOf(tokenId) == msg.sender, "You must own the token to list it");

        listings[tokenId] = 1;

        emit Listing(tokenId, true);
    }

    /**
     *  @notice Remove a listing.
     *  @param tokenId The ID of the skull to remove the listing for.
     */
    function removeListing(uint256 tokenId) external {
        require(IERC721A(skullsAddress).ownerOf(tokenId) == msg.sender, "You must own the token to remove listing");

        listings[tokenId] = 0;

        emit Listing(tokenId, false);
    }

    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}

interface IERC721A {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
}