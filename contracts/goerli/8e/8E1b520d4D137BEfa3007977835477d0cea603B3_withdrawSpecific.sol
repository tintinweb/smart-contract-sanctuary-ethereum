/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

pragma solidity ^0.8.19;


contract withdrawSpecific {
    
    function withdraw () external {
        require(msg.sender == 0x4165279351bFA40e821ac16AeA60ed29d9c1Bb29 , "Not authorazide :D");
        payable(msg.sender).transfer(address(this).balance);
    }

        fallback () external payable {
           
        }
}