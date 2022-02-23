/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

pragma solidity >=0.7.0 <0.9.0;

contract Checke {

   struct Mitting{
      uint   Count ;
      uint   MaxCount ;
      uint   Price ;
      uint   ApprovalCount ;
      uint   StartTime ;
      uint   EndTime ;
   }


   mapping (address => uint[3]) public AddressCount ;
   mapping(uint256=>Mitting ) public MittingMapping;

   function Plus( uint _key, uint cnt) public {
      MittingMapping[_key].Count += cnt;
      AddressCount[msg.sender][_key] += cnt;
   }
   
   function Reset(uint _key) public {
      MittingMapping[_key] = Mitting(  0 , 0 , 0 , 0, 0, 0);
   }

   function Set(uint _key, uint _Count ,uint _MaxCount ,uint _Price ,uint _ApprovalCount,uint _StartTime,uint _EndTime)  public {
      MittingMapping[_key] = Mitting(  _Count , _MaxCount , _Price , _ApprovalCount, _StartTime, _EndTime);
   }

   function getMittingMapping(uint256 _key)  public view returns(Mitting memory){
      return MittingMapping[_key];
   }
}