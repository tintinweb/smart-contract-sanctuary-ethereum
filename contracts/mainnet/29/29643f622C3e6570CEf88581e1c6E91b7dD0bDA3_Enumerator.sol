// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9 <0.9.0;

import "@divergencetech/ethier/contracts/erc721/ERC721Enumerator.sol";

contract Enumerator is ERC721Enumerator {}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

interface IERC721NotQuiteEnumerable {
    function balanceOf(address) external view returns (uint256);

    function ownerOf(uint256) external view returns (address);

    function totalSupply() external view returns (uint256);
}

error NonExistentOwnerToken(address owner, uint256 index);

contract ERC721Enumerator {
    function tokenOfOwnerByIndex(
        IERC721NotQuiteEnumerable token,
        uint256 totalSupply,
        address owner,
        uint256 index
    ) public view returns (uint256 tokenId) {
        uint256 skip = index;
        for (uint256 i = 0; i < totalSupply; i++) {
            if (token.ownerOf(i) != owner) {
                continue;
            }
            if (skip == 0) {
                return i;
            }
            --skip;
        }
        revert NonExistentOwnerToken(owner, index);
    }

    function tokenOfOwnerByIndex(
        IERC721NotQuiteEnumerable token,
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId) {
        return tokenOfOwnerByIndex(token, token.totalSupply(), owner, index);
    }

    function allTokensOwnedBy(
        IERC721NotQuiteEnumerable token,
        uint256 totalSupply,
        address owner
    ) public view returns (uint256[] memory) {
        uint256 balance = token.balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);

        uint256 idx;
        for (uint256 i = 0; i < totalSupply; i++) {
            if (token.ownerOf(i) != owner) {
                continue;
            }
            tokenIds[idx] = i;
            idx++;
        }
        return tokenIds;
    }

    function allTokensOwnedBy(IERC721NotQuiteEnumerable token, address owner)
        external
        view
        returns (uint256[] memory)
    {
        return allTokensOwnedBy(token, token.totalSupply(), owner);
    }
}