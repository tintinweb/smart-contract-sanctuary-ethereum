/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.16;

contract Factory {
    uint256 internal _count;

    function count() external view returns(uint256)  {
        return _count;
    }
    
    function add(uint256 count_) external {
        _count = count_;
    }
}