/**
 *Submitted for verification at Etherscan.io on 2023-02-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IERC721 {
    function balanceOf(address wallet) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract TokensInWallet {
    
    error InvalidSearchRange();

    /**
     * @notice get the ERC721 token ids owned by a wallet, in a range of ids.
     *
     * @dev This may run out of gas if the range is set very large, and it will
     *  revert if it comes across a non-existent token ID.
     *
     *  It is not intended to be used in an on-chain call.
     *  If using in a critical call, be sure the tokens in the range are
     *  sequential and all in existence.
     *
     *  If you need to check a colllection with some non-existent tokens (e.g.
     *  burned) you should try checkedTokensInWalletInRange()
     *
     *  @param tokenContractERC721 address of an ERC721 contract (unchecked)
     *  @param wallet wallet address to query
     *  @param startId first token ID to check
     *  @param endId final token ID to check, inclusive
     */
    function tokensInWalletInRange( // 84951 - 20 tokens
        IERC721 tokenContractERC721,
        address wallet,
        uint256 startId,
        uint256 endId
    )
        public
        view
        returns (uint256[] memory)
    {
        uint256 maxTokens = _getSearchLimit(
            tokenContractERC721,
            wallet,
            startId,
            endId
        );
        uint256[] memory tokenIds = new uint256[](maxTokens);

        if (maxTokens > 0) {
            uint256 index;
            uint256 i = startId;
            do {
                if (tokenContractERC721.ownerOf(i) == wallet) {
                    tokenIds[index] = i;
                    unchecked { ++index; }
                }
                unchecked { ++i; }
            } while (index < maxTokens && i <= endId);

            // trim array
            unchecked {
                uint256 extraZeros = maxTokens - index;
                assembly{
                    mstore(tokenIds, sub(mload(tokenIds), extraZeros))
                }
            }
        }
        return tokenIds;
    }
    
    /** 
    * @notice get all the tokens in a wallet in a range, allowing for
    *  non-existent ids in the range. Use this if tokensInWalletInRange
    *  throws errors like "ERC721: invalid token ID".
    *
    *  It may fail if the range is too large
    *
    *  @param tokenContractERC721 address of an ERC721 contract (unchecked)
    *  @param wallet the wallet address to query
    *  @param startId first token ID to check
    *  @param endId final token ID to check, inclusive
    */
    function checkedTokensInWalletInRange(
        IERC721 tokenContractERC721,
        address wallet,
        uint256 startId,
        uint256 endId
    )
        public
        view
        returns (uint256[] memory)
    {
        uint256 maxTokens = _getSearchLimit(
            tokenContractERC721,
            wallet,
            startId,
            endId
        );
        uint256[] memory tokenIds = new uint256[](maxTokens);

        if (maxTokens > 0) {
            uint256 index;
            uint256 i = startId;
            do {
                // try/catch to prevent non-sequential token sequences reverting
                try tokenContractERC721.ownerOf(i) returns (address addr) {
                    if (addr == wallet) {
                        tokenIds[index] = i;
                        unchecked { ++index; }
                    }
                } catch {}
                unchecked { ++i; }
            } while (index < maxTokens && i <= endId);

            // trim array
            unchecked {
                uint256 extraZeros = maxTokens - index;
                assembly{
                    mstore(tokenIds, sub(mload(tokenIds), extraZeros))
                }
            }
        }
        return tokenIds;
    }

    /** 
     * @notice get all the tokens in a wallet, from a collection that starts
     *  numbering tokens at zero. Does not check for non-existent token ids.
     *
     *  All the same inherent errors as in tokensInWalletInRange.
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
            50_000 // a limit to avoid out of gas errors
        );
    }

    /**
     * @dev helper to get the amount of tokens to search for
     */
    function _getSearchLimit(
        IERC721 tokenContractERC721,
        address wallet,
        uint256 startId,
        uint256 endId
    )
        internal
        view
        returns (uint256)
    {
        if (endId < startId) revert InvalidSearchRange();

        uint256 maxTokens = tokenContractERC721.balanceOf(wallet);
        unchecked {
            if (endId - startId + 1 < maxTokens) {
                maxTokens = endId - startId + 1;
            }
        }
        return maxTokens;
    }
}