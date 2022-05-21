/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

contract OverflowContract {

    string public name;
    uint256 public uint256MaxValue;

    constructor() {
        name = 'OverflowContract';
        uint256MaxValue = uint256(-1);
    }

    // ethers.BigNumber.from(`2`).pow(256).sub(1)
    function getMaxNumber(uint256 _overflowNumber) public view virtual returns (uint256) {
        return _overflowNumber;
    }

    receive() external payable {}
    
}