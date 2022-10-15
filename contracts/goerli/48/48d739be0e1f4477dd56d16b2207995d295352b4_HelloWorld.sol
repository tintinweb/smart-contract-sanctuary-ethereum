/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

pragma solidity ^0.8.0;
contract HelloWorld {
 
 string private hellowWorld="test passs re baba";
 function getHello() public view returns (string memory) {
    return hellowWorld;

 }

 function getTotal(uint a,uint b) public pure returns (uint c) {
      c=a+b;

 }


}