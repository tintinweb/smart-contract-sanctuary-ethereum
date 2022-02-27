/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

pragma solidity =0.8.7;
contract MyFirstContract {

   uint256 number;


   function setNumber(uint256 _num) public {
       number = _num;
   }


   function getNumber() public view returns (uint256){
       return number;
   }
}