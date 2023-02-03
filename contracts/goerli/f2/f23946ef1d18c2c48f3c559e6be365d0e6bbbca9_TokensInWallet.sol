/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721 {
    function balanceOf(address wallet) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract TokensInWallet {
    /**
     * @notice get the ERC721 token ids owned by a wallet, in a range of ids.
     *  This may run out of gas if the range is set too large, and it will 
     *  overflow if token ids exceed the uint256 limit. 
     *  Contracts with non-sequential token ids will cause errors.
     *  
     *  It clearly should not be used in an on-chain call.
     *  It should probably not be used in a critical off-chain call, due to the
     *  inherent unchecked errors.
     *
     *  @param tokenContractERC721 address of an ERC721 contract (unchecked)
     *  @param wallet wallet address to query
     *  @param startId first token ID to check
     *  @param endId final token ID to check, inclusive
     */
    function tokensInWalletInRange(
        IERC721 tokenContractERC721,
        address wallet,
        uint256 startId,
        uint256 endId
    )
        public
        view
        returns (uint256[] memory)
    {
        uint256 totalOwned = tokenContractERC721.balanceOf(wallet);
        uint256[] memory tokenIds = new uint256[](totalOwned);

        if (totalOwned > 0) {
            uint256 index;
            uint256 i = startId;
            do {
                if (tokenContractERC721.ownerOf(i) == wallet) {
                    tokenIds[index] = i;
                    unchecked { ++index; }
                }
                unchecked { ++i; }
            } while (index < totalOwned && i <= endId);
        }
        return tokenIds;
    }

    /** 
     * @notice get all the tokens in a wallet, starting at a particular ID
     *
     *  All the same inherent errors as in tokensInWalletInRange
     *
     *  @param tokenContractERC721 address of an ERC721 contract (unchecked)
     *  @param wallet the wallet address to query
     *  @param startId the first token ID to query
     */
    function tokensInWalletFromX(
        IERC721 tokenContractERC721,
        address wallet,
        uint256 startId
    )
        external
        view
        returns (uint256[] memory)
    {
        return tokensInWalletInRange(
            tokenContractERC721,
            wallet,
            startId,
            startId + 60_000 // a limit to avoid out of gas errors
        );
    }

    /** 
     * @notice get all the tokens in a wallet, from a collection that starts
     *  numbering tokens at zero.
     *
     *  All the same inherent errors as in tokensInWalletInRange
     *
     *  @param tokenContractERC721 address of an ERC721 contract (unchecked)
     *  @param wallet the wallet address to query
     */
    function tokensInWalletFromZero(
        IERC721 tokenContractERC721,
        address wallet
    )
        external
        view
        returns (uint256[] memory)
    {
        return tokensInWalletInRange(
            tokenContractERC721,
            wallet,
            0,
            60_000 // a limit to avoid out of gas errors
        );
    }
}