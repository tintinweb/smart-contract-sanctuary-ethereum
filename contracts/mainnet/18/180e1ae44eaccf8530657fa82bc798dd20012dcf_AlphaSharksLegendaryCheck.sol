/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct Locker {
    bool locked;  // 0 -> Unlocked, 1 -> Locked
    uint256 tokenNumber;
    address lockerOwner;
}

interface IAlphaLocker {
    function nftLocked(address owner) external view returns (uint256);
    function nftLocker(uint256 tokenId) external view returns (Locker memory);
}

contract AlphaSharksLegendaryCheck {
  uint[] legendaryTokenIdsArr = [158, 217, 599, 879, 1312, 1447, 3671, 4504, 4511, 4825, 4892, 4903, 5419, 5659, 5932, 5939];

   function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        uint256 balance = IAlphaLocker(0xbD3041cdc089cDDcc609ceb1B149D55DAE7491C5).nftLocked(owner);

        if (balance >= 5) {
            return 1;
        }

        for (uint i = 0; i < legendaryTokenIdsArr.length; i++) {
            uint token_id = legendaryTokenIdsArr[i];
            Locker memory _locker = IAlphaLocker(0xbD3041cdc089cDDcc609ceb1B149D55DAE7491C5).nftLocker(token_id);
            if(_locker.lockerOwner == owner) {
                return 1;
            }
         }

        return 0;
    }
}