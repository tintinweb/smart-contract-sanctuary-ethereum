/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

pragma solidity ^0.8.0;

contract Hello_leon{
    uint  data;
    constructor()  {
        data = 1;
        
        
    }
    function leon() public view returns(uint){
      
      return data; //access the local variable
   }
}