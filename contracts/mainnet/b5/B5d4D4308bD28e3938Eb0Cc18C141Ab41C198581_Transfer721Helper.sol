/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

contract Transfer721Helper {
    function validTokenIds(
        address c,
        address tokenOwner,
        uint256[] memory ids
    ) public view returns (uint256[] memory) {
        IERC721 token = IERC721(c);
        uint256 _ownedCount = 0;
        uint256[] memory _tempExistIds = new uint256[](ids.length);
        for (uint256 index = 0; index < ids.length; index++) {
            uint256 _id = ids[index];
            bool _isOwned = false;
            try token.ownerOf(_id) returns (address o) {
                _isOwned = tokenOwner == o;
            } catch {}
            if (_isOwned) {
                _tempExistIds[_ownedCount] = _id;
                _ownedCount++;
            }
        }

        uint256[] memory existIds = new uint256[](_ownedCount);
        for (uint256 index = 0; index < _ownedCount; index++) {
            existIds[index] = _tempExistIds[index];
        }
        return existIds;
    }

    function multiTransfer(
        address c,
        address from,
        address to,
        uint256[] memory ids
    ) public returns (bool) {
        require(validTokenIds(c, from, ids).length == ids.length, "no valid");
        IERC721 token = IERC721(c);
        for (uint256 index = 0; index < ids.length; index++) {
            token.safeTransferFrom(from, to, ids[index]);
        }
        return true;
    }
}