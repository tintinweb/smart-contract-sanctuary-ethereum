/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract SmartSpeaker{

    address developer;

    constructor(){
        developer = msg.sender;
    }

    function currentTime() public view returns(uint32){
        if(msg.sender==developer){
            return uint32(block.timestamp);
        }
        else{
            return uint32(0);
        }
        
    }
}