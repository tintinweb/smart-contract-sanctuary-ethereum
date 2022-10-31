// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BatchBalance {

    function balanceOfBatched(
        address token,
        address account,
        uint from,
        uint to,
        uint maxLen
    ) public view returns (int[] memory) {
        uint length = 0;
        int[] memory balance = new int[](maxLen);
        for (uint i = from; i < to; i++) {
            if (length == maxLen - 1) {
                break;
            }
            try IERC721owner(token).ownerOf(i) returns (address owner) {
                if (owner == account) {
                    balance[length] = int(i);
                    length++;
                }
            } catch (bytes memory) {
            }
        }
        balance[length] = - 1;
        return balance;
    }
}

interface IERC721owner {
    function ownerOf(uint tokenId) external view returns (address);
}