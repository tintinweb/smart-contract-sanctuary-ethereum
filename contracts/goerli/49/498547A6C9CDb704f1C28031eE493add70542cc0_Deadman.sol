/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Deadman {
    address payable preset = payable(0x081729b7D226e9619B161ADE7BFaBB5B02d8cab9);
    uint public blocknumber;
    constructor(){
        blocknumber = block.number + 10;
    }
    function still_alive() public{
      blocknumber = block.number+10;
    }

    function transfer()payable public returns(bool){
        require(msg.sender == preset,"You are not allowed to withdraw funds!");
        require(blocknumber < block.number,"Owner can still be alive!");
        (bool sent, ) = preset.call{value: address(this).balance}("");
        require(sent, "Fail to transfer balance");
        return sent;
    }
}