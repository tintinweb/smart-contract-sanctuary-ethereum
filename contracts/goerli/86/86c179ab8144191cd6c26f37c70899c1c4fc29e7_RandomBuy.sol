/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RandomBuy {
    // 0 = 眼睛
    // 1 = 耳朵
    // 2 = 鼻子
    // 3 = 嘴巴
    // 4 = 眉毛
    mapping(address => bool[5]) private isBuy;

    function generateRandom() private view returns (uint256) {
        return uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
        );
    }
    
    function RandomType() public returns (uint256) {
        uint256 randomNumber=generateRandom() % 5;
        if(isBuy[msg.sender][randomNumber]==false){
            isBuy[msg.sender][randomNumber]=true;
            return randomNumber;
        }else{
            RandomType();
        }
        
    }

    function addressBuyInfo(uint256 index) public view returns(bool){
        return isBuy[msg.sender][index];
    }




}