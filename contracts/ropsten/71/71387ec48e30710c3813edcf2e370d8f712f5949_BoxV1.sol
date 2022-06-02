/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract BoxV1{
    uint public val;

    function initialize(uint _val) external {
        val = _val;
    }

    function get_time() public view returns(uint256){
        return block.timestamp;
    }
}