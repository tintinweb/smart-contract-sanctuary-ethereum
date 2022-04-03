/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract TestPayable {

    
    function buySomething() external payable {
        require(msg.value == 0.01 ether, "Not enough Ether");
    }

    function retrieve(uint256 _x, uint256 _y) external pure returns (uint256){
        require(_x + _y < 25, "Too large");
        return _x + _y;
    }
}