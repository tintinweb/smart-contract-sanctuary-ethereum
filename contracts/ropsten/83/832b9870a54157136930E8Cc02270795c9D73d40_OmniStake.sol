/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;



interface IERC721 {
    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

contract OmniStake {
    // fired when NFT stake created
    event StakeCreated(address staker, address asset, uint256[] tokenIds);

    // fired when NFT stake cancelled
    event StakeWithdrawn(address staker, address asset, uint256[] tokenIds);

    /**
     * NFT stakes map
     * key: keccak256(abi.encodePacked(stacker,asset,tokenId))
     * value: true if stake exists
     */
    mapping(bytes32 => bool) private Stake;

    /**
     * @dev calculate stakeMap key

     */
    function getStakeKey(
        address staker,
        address asset,
        uint256 tokenId
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(staker, asset, tokenId));
    }

    /**
     * @dev true if stake exists
     * @param stakeKey keccak256(abi.encodePacked(stacker,asset,tokenId))
     */
    function StakeExists(bytes32 stakeKey) external view returns (bool) {
        return Stake[stakeKey];
    }

    /**
     * @dev create a new NFT stake
     * @param asset NFT address
     * @param tokenIds tokenIds of the NFT
     *
     * Emits a {StakeCreated} event.
     */
    function createStake(address asset, uint256[] calldata tokenIds) public {
        require(tokenIds.length > 0, "Stake: No tokens provided");
        address sender = msg.sender;
        IERC721 ERC721 = IERC721(asset);
        require(
            ERC721.isApprovedForAll(sender, address(this)),
            "Stake: Not approved for all"
        );

        for (uint256 i = 0; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            try ERC721.transferFrom(sender, address(this), tokenId) {
                Stake[getStakeKey(sender, asset, tokenId)] = true;
            } catch {
                revert("Stake: Transfer failed");
            }
            unchecked {
                i++;
            }
        }

        emit StakeCreated(sender, asset, tokenIds);
    }

    /**
     * @dev withdraw a NFT stake
     * @param asset NFT address
     * @param tokenIds tokenIds of the NFT
     *
     * Emits a {StakeWithdrawn} event.
     */
    function withdrawStake(address asset, uint256[] calldata tokenIds) public {
        require(tokenIds.length > 0, "Stake: No tokens provided");
        address sender = msg.sender;
        IERC721 ERC721 = IERC721(asset);
        for (uint256 i = 0; i < tokenIds.length; ) {
            uint256 _tokenId = tokenIds[i];
            bytes32 key = getStakeKey(sender, asset, _tokenId);
            require(Stake[key], "Stake: Not staked");

            try ERC721.transferFrom(address(this), sender, _tokenId) {
                delete Stake[key];
            } catch {
                revert("Stake: Transfer failed");
            }
            unchecked {
                i++;
            }
        }
        emit StakeWithdrawn(sender, asset, tokenIds);
    }
}