// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

/**
 * ERC721QueryableProxy by marcelc63.eth
 * https://twitter.com/marcelc63
 *
 * Version 1
 *
 * Proxy contract to enumerate any ERC721 tokens
 * Implementation taken from ERC721AQueryable, modified by marcelc63.eth
 *
 * Credit to ERC721A authors: https://github.com/chiru-labs/ERC721A
 * 
 */

error InvalidQueryRange();
error TotalSupplyNotFound();

interface IERC721 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function ownerOf(uint256 tokenId) external view returns (address);
}

contract ERC721QueryableProxy {
  constructor() {}

  /**
   * @dev Returns an array of token IDs owned by `owner`.
   *
   * This function scans the ownership mapping and is O(totalSupply) in complexity.
   * It is meant to be called off-chain.
   *
   * See {ERC721QueryableProxy-tokensOfOwnerIn} for splitting the scan into
   * multiple smaller scans if the collection is large enough to cause
   * an out-of-gas error (10K pfp collections should be fine).
   *
   * Modified by marcelc63.eth from ERC721AQueryable
   */
  function tokensOfOwner(address contractAddress, address owner)
    external
    view
    returns (uint256[] memory)
  {
    unchecked {
      uint256 tokenIdsIdx;
      uint256 tokenIdsLength = IERC721(contractAddress).balanceOf(owner);
      uint256[] memory tokenIds = new uint256[](tokenIdsLength);

      // Index starts at 0. Try/catch will skip over index 0 for contracts starting with index 1.
      for (uint256 i = 0; tokenIdsIdx != tokenIdsLength; ++i) {
        // Try get token owner. Skip if token doesn't exist.
        try IERC721(contractAddress).ownerOf(i) returns (address tokenOwner) {
          if (tokenOwner == owner) {
            tokenIds[tokenIdsIdx++] = i;
          }
        } catch {
          continue;
        }
      }

      return tokenIds;
    }
  }

  /**
   * @dev Returns an array of token IDs owned by `owner`,
   * in the range [`start`, `stop`)
   * (i.e. `start <= tokenId < stop`).
   *
   * This function allows for tokens to be queried if the collection
   * grows too big for a single call of {ERC721QueryableProxy-tokensOfOwner}.
   *
   * Requirements:
   *
   * - `start` < `stop`
   *
   * Modified by marcelc63.eth from ERC721AQueryable
   */
  function tokensOfOwnerIn(
    address contractAddress,
    address owner,
    uint256 start,
    uint256 stop
  ) external view returns (uint256[] memory) {
    unchecked {
      if (start >= stop) revert InvalidQueryRange();

      // Try get token totalSupply. Fail if contract doesn't implement totalSupply.
      try IERC721(contractAddress).totalSupply() returns (uint256 stopLimit) {
        uint256 tokenIdsIdx;

        // Set `start = max(start, _startTokenId())`.
        if (start < 0) {
          start = 0;
        }
        // Set `stop = min(stop, _currentIndex)`.
        if (stop > stopLimit) {
          stop = stopLimit;
        }
        uint256 tokenIdsMaxLength = IERC721(contractAddress).balanceOf(owner);
        // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
        // to cater for cases where `balanceOf(owner)` is too big.
        if (start < stop) {
          uint256 rangeLength = stop - start;
          if (rangeLength < tokenIdsMaxLength) {
            tokenIdsMaxLength = rangeLength;
          }
        } else {
          tokenIdsMaxLength = 0;
        }
        uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
        if (tokenIdsMaxLength == 0) {
          return tokenIds;
        }

        for (
          uint256 i = start;
          i != stop && tokenIdsIdx != tokenIdsMaxLength;
          ++i
        ) {
          // Try get token owner. Skip if token doesn't exist.
          try IERC721(contractAddress).ownerOf(i) returns (address tokenOwner) {
            if (tokenOwner == owner) {
              tokenIds[tokenIdsIdx++] = i;
            }
          } catch {
            continue;
          }
        }
        // Downsize the array to fit.
        assembly {
          mstore(tokenIds, tokenIdsIdx)
        }
        return tokenIds;
      } catch {
        revert TotalSupplyNotFound();
      }
    }
  }
}