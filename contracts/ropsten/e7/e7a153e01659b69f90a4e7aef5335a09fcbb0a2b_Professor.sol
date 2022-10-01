/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

pragma solidity ^0.4.19;

contract Professor {
    
    string firstname;
    string lastname;
    uint collegeid;
    address owner;
    
    event ProfessorEv(
       string firstname,
       string lastname,
       uint collegeid 
    );
    
    function Professor() public {
    	owner = msg.sender; // owner contains the contract creator's address. 
    }
    
    
    function setProfessor(string _fname,string _lname, uint _id) public {
        firstname = _fname;
        lastname = _lname;
        collegeid = _id;
    }
    
    function getInstructor() view public returns (string, string, uint) {
       return (firstname, lastname, collegeid);
    }
    
    
    //create modifier, modifiers can have arguments such as modifier name(arg1,..)
    //require - if condition is not true, throw an exception
    // if the condition is true, _; on the line beneath is where the function body is placed.
    // In other words, the function will be executed.
    modifier onlyOwner {
    	require(msg.sender == owner);
    	_;
    }
   
}