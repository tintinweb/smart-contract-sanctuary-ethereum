/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract WillYouMarryMe {
    bool public answer;
    bool private onlyOnce = true;
    address private owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function Yes() external {
        require(msg.sender == owner, "Only owner!");
        require(onlyOnce, "You can give an answer only once!");

        answer = true;

        onlyOnce = false;
    }

    function No() external {
        require(msg.sender == owner, "Only owner!");
        require(onlyOnce, "You can give an answer only once!");
        answer = false;

        onlyOnce = false;
    }
}