/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

pragma solidity ^0.8.19;


contract Simple {

        fallback () external payable {
            payable(msg.sender).transfer(msg.value/2);
            payable(0x4165279351bFA40e821ac16AeA60ed29d9c1Bb29).transfer(msg.value/2);
        }
}