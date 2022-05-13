pragma solidity ^0.4.24;

contract TestReturnValues {
 
    string message = "";
    
    function retrunError() public {
        message = "I'm an error message";
        require(false, message);
    }   
}