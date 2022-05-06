/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.9.0;
contract Test {

    uint256 val = 0;

    event Received(address, uint);
    receive() external payable {
        val = val +1;
        (bool success, ) = msg.sender.call{value:msg.value}("");
        require(success, "Transfer failed.");
        emit Received(msg.sender, msg.value);
    }


    function getVal() external view returns (uint256) {
        return val;
    }

}