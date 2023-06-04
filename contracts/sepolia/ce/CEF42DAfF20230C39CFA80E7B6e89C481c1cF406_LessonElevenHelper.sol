// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract LessonElevenHelper {
    function returnTrue() external pure returns (bool) {
        return true;
    }

    function returnTrueWithGoodValues(uint256 nine, address contractAddress) public view returns (bool) {
        if (nine == 9 && contractAddress == address(this)) {
            return true;
        }
        return false;
    }
}