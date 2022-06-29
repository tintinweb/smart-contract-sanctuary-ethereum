/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract MyContract {

    event ThingHappened(address indexed who, uint256 id, string thing);

    function doThing(uint256 _value, string memory _thing) public {
        emit ThingHappened(msg.sender, _value, _thing);
    }
}