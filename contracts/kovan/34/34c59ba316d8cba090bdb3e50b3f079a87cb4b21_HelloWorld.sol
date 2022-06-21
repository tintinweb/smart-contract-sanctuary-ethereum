/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld {
    string handsomeGuy = "Nawat";

    function seeWhoHandsome() public view returns(string memory) {
        return handsomeGuy;
    }

    function changeHandsomeGuy(string memory _newHandsomeGuy) public {
        handsomeGuy = _newHandsomeGuy;
    }
}