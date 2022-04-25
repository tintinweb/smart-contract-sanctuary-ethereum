/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX LICENCE  Identifier :GPL-3.0
pragma solidity >= 0.4.0<0.9.0 ;
contract Demo {  
         struct Employee{ 
             uint empid ;
             string name ;
             string department ;
             string designation ;
            
         }
         //mapping(address=>Employee)employes;
        Employee[]public Emps;
        // set employee detail
         function setemp(uint Empid, string memory nm,string memory deprt,string memory dign)public{
        // Employee memory Emp=Employee(Empid,nm,deprt,dign);
        Emps.push(Employee(Empid,nm,deprt,dign));
         }
      //find employee detail using employee id
function getemployee(uint id)public view returns(string memory ,string memory,string memory)
{
    
    for(uint i=0;i<Emps.length;i++){
  
    if(Emps[i].empid==id)
    {return(Emps[i].name,Emps[i].department,Emps[i].designation);}}
    
return ("not found","not found","not found");
}

}