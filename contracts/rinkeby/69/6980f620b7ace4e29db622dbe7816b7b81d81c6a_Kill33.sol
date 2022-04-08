/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract Kill33 {

    uint256 public flag;

    constructor() payable{

    }

    function kill(address user) external {
        selfdestruct(payable(user));
    }

    function test() external pure returns(uint256) {
        return 888;
    }

    function setFlag(uint256 _flag) public {
        flag = _flag;
    }

}