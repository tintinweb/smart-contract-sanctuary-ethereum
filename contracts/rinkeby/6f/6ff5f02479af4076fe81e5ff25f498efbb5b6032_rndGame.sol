/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract rndGame {
    mapping(address => uint) public win;
    mapping(address => uint) public result;
   
   function random() private view returns(uint){
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, tx.origin)));
}

    function setRnd() public{
        result[msg.sender] = random();
    }

    function compare(address target) public{
        uint sender_rnd =  result[msg.sender];
        uint target_rnd = result[target];
        if (sender_rnd > target_rnd){
            win[msg.sender] += 1; 
        }
        else{
            win[target] += 1; 
        }
    }

}