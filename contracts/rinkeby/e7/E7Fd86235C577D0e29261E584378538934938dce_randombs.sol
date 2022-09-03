// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract randombs{

    function getTokenState() public view returns(uint256){
        return block.number;
    }

}