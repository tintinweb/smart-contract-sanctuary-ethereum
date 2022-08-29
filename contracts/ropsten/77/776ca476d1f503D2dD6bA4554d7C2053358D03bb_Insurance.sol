/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
contract Insurance{
    struct company{
        uint CompanyID;
        string CompanyName;
        uint BALANCE;
    }
   company[] public companydetails;
   function setCompany(uint id,string memory name,uint amount) public{
       require(amount==10000,"Not prescbribed amount");
       companydetails.push(company(id,name,amount));
       
   }
    struct Passenger{
      uint CompanyID;
      uint passengerid;
      string passengerName;
      uint balance;
    }
    Passenger[] public passengerdetails;
    function setpaasenger(uint _id,uint pid,string memory _name,uint charge) public{
        require(charge==500,"Not prescribed charge");
        passengerdetails.push(Passenger(_id,pid,_name,charge));
    }
    function check(uint CompanyID,uint passengerid,bool status) public{
        if(status==true){
          passengerdetails[passengerid].balance+=companydetails[CompanyID].BALANCE;
          companydetails[CompanyID].BALANCE=0;
        }
        else{
            companydetails[CompanyID].BALANCE+=passengerdetails[passengerid].balance;
            passengerdetails[passengerid].balance=0;
        }
    }
}