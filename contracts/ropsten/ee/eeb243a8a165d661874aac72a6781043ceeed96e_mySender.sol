/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

pragma solidity 0.8.10;
 contract mySender { 

    function multyTx(address payable [2] memory addrs, uint[2] memory values) public {
        
         for(uint256 i = 0; i < addrs.length; i++) {
              addrs[i].transfer(values[i]); 
              } 
            } 
 }