/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.7.0 <=0.8.7;



contract TheEndlessStory
{
    string private txtarg; 
    string private history;

    function setText(string calldata _phrase ) public
    {
        txtarg = _phrase;
        history = string(abi.encodePacked(history," ", txtarg));
    }
    function theEndlessStoryReader() public view returns(string memory){
        return history;
    }
}