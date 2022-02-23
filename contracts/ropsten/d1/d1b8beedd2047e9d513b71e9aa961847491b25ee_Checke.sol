/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

pragma solidity >=0.7.0 <0.9.0;

contract Checke {

      uint[3] public  Count ;
      uint[3] public  MaxCount ;
      uint[3] public  Price ;
      uint[3] public  ApprovalCount ;
      
      mapping (address => uint[3]) public AddressCount ;

    
      function Plus( uint num, uint cnt) public {
         Count[num] +=  cnt;
         AddressCount[msg.sender][num] += cnt;
      }
      
      function Reset(uint num) public {
         Count[num]  = 0;
         AddressCount[msg.sender][num]  = 0;
      }
      
      function Set( uint num, uint price ,uint maxcount ,uint approvalcount ) public {
         MaxCount[num] =  maxcount;
         Price[num] =  price;
         ApprovalCount[num] =  approvalcount;
      }
}