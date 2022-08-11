/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface iMartians {
    function walletOfOwner(address address_) external view returns (uint256[] memory);
}

interface iCS {

    struct Character {
        // general info
        uint8 race_;
        uint8 renderType_;

        // equipment
        uint16 transponderId_;
        uint16 spaceCapsuleId_;

        // stats
        uint8 augments_;
        uint16 basePoints_;
        uint16 totalEquipmentBonus_;
    }

    function characters(uint256 tokenId_) external view returns (Character memory);
}

contract maxAugmentBalance {

    // Interfaces
    iMartians public Martians = iMartians(0x075854b315F2cd7eC490853Bc5589B09E546449f);
    iCS public CS = iCS(0xC7C40032E952F52F1ce7472913CDd8EeC89521c4);

    // BalanceOf
    function balanceOf(address address_) external view returns (uint256) {
        // First, we grab an uint256[] array from Martians
        uint256[] memory _wallet = Martians.walletOfOwner(address_);

        // Then, we create a local uint256 tracker and add to it for each case
        uint256 _maxAugmentBalance;
        for (uint256 i = 0; i < _wallet.length; i++) {
            // Grab the data of the character from CS
            iCS.Character memory _Character = CS.characters(_wallet[i]);
            if (_Character.augments_ == 10) { _maxAugmentBalance++; }
        }

        // After running the loop, return the amount.
        return _maxAugmentBalance;
    }
}