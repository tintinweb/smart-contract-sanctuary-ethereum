// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract StructMap {
   struct Auditor{
    address AuditorAddress;
    mapping(string=>bool) roles;
   }

   mapping(uint256=>Auditor) private _auditorid;

   constructor(){
    Auditor storage _auditor=_auditorid[1];

    _auditor.AuditorAddress=msg.sender;
    _auditor.roles["admin"]=true;

   }

   function deleteAuditor(uint256 auditorid)external{
    delete _auditorid[auditorid];
   }

   function getAuditorInfo(uint256 auditorid)external view returns(address,bool){
     Auditor storage auditor=_auditorid[auditorid];
     return (auditor.AuditorAddress,auditor.roles["admin"]);
   }

   
}