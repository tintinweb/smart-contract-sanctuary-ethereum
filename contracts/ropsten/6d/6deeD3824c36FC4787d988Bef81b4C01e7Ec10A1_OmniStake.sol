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

    // fired when NFT stake created
    event MultiStakeCreated(
        address staker,
        address[] asset,
        uint256[][] tokenIds
    );

    // fired when NFT stake cancelled
    event MultiStakeWithdrawn(
        address staker,
        address[] asset,
        uint256[][] tokenIds
    );

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
     * @dev create a new NFT stake
     * @param asset NFT address
     * @param tokenIds tokenIds of the NFT
     *
     * Emits a {MultiStakeCreated} event.
     */
    function createMultiStake(
        address[] calldata asset,
        uint256[][] calldata tokenIds
    ) public {
        require(tokenIds.length > 0, "Stake: No tokens provided");
        require(asset.length == tokenIds.length, "Stake: Invalid input");
        address sender = msg.sender;
        for (uint256 i = 0; i < asset.length; ) {
            IERC721 ERC721 = IERC721(asset[i]);
            uint256[] memory _tokenIds = tokenIds[i];
            require(_tokenIds.length > 0, "Stake: No tokens provided");
            require(
                ERC721.isApprovedForAll(sender, address(this)),
                "Stake: Not approved for all"
            );
            for (uint256 j = 0; j < _tokenIds.length; ) {
                uint256 tokenId = _tokenIds[j];
                try ERC721.transferFrom(sender, address(this), tokenId) {
                    Stake[getStakeKey(sender, asset[i], tokenId)] = true;
                } catch {
                    revert("Stake: Transfer failed");
                }
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }

        emit MultiStakeCreated(sender, asset, tokenIds);
    }

    /**
     * @dev withdraw NFT stake
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

    /**
     * @dev withdraw NFT stake
     * @param asset NFT address
     * @param tokenIds tokenIds of the NFT
     *
     * Emits a {MultiStakeWithdrawn} event.
     */
    function withdrawMultiStake(
        address[] calldata asset,
        uint256[][] calldata tokenIds
    ) public {
        require(tokenIds.length > 0, "Stake: No tokens provided");
        require(asset.length == tokenIds.length, "Stake: Invalid input");
        address sender = msg.sender;
        for (uint256 i = 0; i < asset.length; ) {
            IERC721 ERC721 = IERC721(asset[i]);
            uint256[] memory _tokenIds = tokenIds[i];
            require(_tokenIds.length > 0, "Stake: No tokens provided");
            for (uint256 j = 0; j < _tokenIds.length; ) {
                uint256 _tokenId = _tokenIds[j];
                bytes32 key = getStakeKey(sender, asset[i], _tokenId);
                require(Stake[key], "Stake: Not staked");

                try ERC721.transferFrom(address(this), sender, _tokenId) {
                    delete Stake[key];
                } catch {
                    revert("Stake: Transfer failed");
                }
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }

        emit MultiStakeWithdrawn(sender, asset, tokenIds);
    }

    /**
     * @dev stake withdraw at the same time
     * @param stakeAsset stake NFT address
     * @param stakeTokenIds stake tokenIds of the NFT
     * @param withdrawAsset withdraw NFT address
     * @param withdrawTokenIds withdraw tokenIds of the NFT
     * Emits {StakeWithdrawn} and {StakeCreated} event.
     */
    function createStakeAndWithdraw(
        address stakeAsset,
        uint256[] calldata stakeTokenIds,
        address withdrawAsset,
        uint256[] calldata withdrawTokenIds
    ) public {
        withdrawStake(withdrawAsset, withdrawTokenIds);
        createStake(stakeAsset, stakeTokenIds);
    }

    /**
     * @dev stake withdraw at the same time
     * @param stakeAsset stake NFT address
     * @param stakeTokenIds stake tokenIds of the NFT
     * @param withdrawAsset withdraw NFT address
     * @param withdrawTokenIds withdraw tokenIds of the NFT
     * Emits {MultiStakeWithdrawn} and {MultiStakeCreated} event.
     */
    function createMultiStakeAndWithdraw(
        address[] calldata stakeAsset,
        uint256[][] calldata stakeTokenIds,
        address[] calldata withdrawAsset,
        uint256[][] calldata withdrawTokenIds
    ) public {
        withdrawMultiStake(withdrawAsset, withdrawTokenIds);
        createMultiStake(stakeAsset, stakeTokenIds);
    }
}