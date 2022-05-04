/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

pragma solidity ^0.4.18;

contract PersonalPage_Stax {
    
      
    
    struct info {
        address Address;
        string Handle;
        string First_name;
        string Last_name;
        string Email;
        int Phone_number;
        string Gender;
        
    }
    
     event Datastored (
        address Address,
        string id,
        string Handle,
        string First_name,
        string Last_name,
        string Email,
        int Phone_number,
        string Gender
    );
    
    
    
   
    
    mapping(address => mapping(string => info)) private infos;
   
    
    
     function setInfo(address Address, string id, string Handle, string First_name, string Last_name, string Email,  int Phone_number,  string Gender) public {
        var info = infos[Address][id];
        info.Handle = Handle;
        info.First_name = First_name;
        info.Last_name = Last_name;
        info.Email = Email;
        info.Phone_number = Phone_number;
        info.Gender = Gender;
      
        emit Datastored(Address, id, Handle, First_name, Last_name, Email, Phone_number, Gender);
    }

    function getInfo(address Address, string _id) view public returns (string, string, string, string, int, string ) {
        return (infos[Address][_id].Handle, infos[Address][_id].First_name, infos[Address][_id].Last_name, infos[Address][_id].Email, infos[Address][_id].Phone_number, infos[Address][_id].Gender);
       
    }
}