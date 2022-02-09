/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {
    bytes32 image = "";
 
    function updateImage(bytes32 newImage) public{
        image = newImage;
    }

    function _updateImage(bytes32 newImage) private{
        return _updateImage(newImage);
    }

}