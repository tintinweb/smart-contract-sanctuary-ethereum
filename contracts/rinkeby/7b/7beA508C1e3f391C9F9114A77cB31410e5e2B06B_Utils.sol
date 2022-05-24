// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Utils {
    function RemoveFromAddressArray(address[] storage array_, address toRemove_) public returns (address[] memory) {
        uint256 i = 0;
        for(; i < array_.length;) {
            if (array_[i] == toRemove_) {
                array_[i] = array_[array_.length - 1];
                array_.pop();
                break;
            }
            unchecked { i++; }
        }

        return array_;
    }

    function RemoveFromUint256Array(uint256[] storage array_, uint256 toRemove_) public returns (uint256[] memory) {
        uint256 i = 0;
        for(; i < array_.length;) {
            if (array_[i] == toRemove_) {
                array_[i] = array_[array_.length - 1];
                array_.pop();
                break;
            }
            unchecked { i++; }
        }

        return array_;
    }
}