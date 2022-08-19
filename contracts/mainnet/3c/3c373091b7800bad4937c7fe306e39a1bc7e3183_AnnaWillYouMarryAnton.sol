/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract AnnaWillYouMarryAnton {
    bool public answer;
    bool private onlyOnce = true;
    address private owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function Yes() external {
        require(msg.sender == owner, "Only Anna!");
        require(onlyOnce, "You can give an answer only once!");

        answer = true;

        onlyOnce = false;
    }

    function No() external {
        require(msg.sender == owner, "Only Anna!");
        require(onlyOnce, "You can give an answer only once!");

        answer = false;

        onlyOnce = false;
    }
}