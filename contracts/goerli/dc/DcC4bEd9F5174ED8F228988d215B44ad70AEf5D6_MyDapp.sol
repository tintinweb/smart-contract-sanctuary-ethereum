/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MyDapp{
    uint num = 0;

    // Declaring an event
    event myEvent(
        uint256 newNum,
        address from
    );


    function getMyNum() public view returns(uint){
        return num;
    }

    function setMyNum(uint _setnum) public{
        num = _setnum;
        emit myEvent(num, msg.sender);
    }


}