/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

// File: contracts/Quickie/detailsStorage.sol

 //SPDX-License-Identifier: MIT;
 pragma solidity 0.8.0;
 
 
 
 struct DetailsLib {
        uint256 x;
        uint256 y;
        uint256 z;
    }
// File: contracts/Quickie/Details.sol


contract Details {
    DetailsLib public l;

    function setDetails(
        uint256 _x,
        uint256 _y,
        uint256 _z
    ) external {
        l.x = _x;
        l.y = _y;
        l.z = _z;
    }

    function sumDetails() external view returns (uint256 sum_) {
        sum_ = l.x + l.y + l.z;
    }
}