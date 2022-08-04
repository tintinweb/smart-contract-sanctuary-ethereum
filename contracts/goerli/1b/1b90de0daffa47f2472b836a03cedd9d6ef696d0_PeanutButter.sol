pragma solidity ^0.8.5;

contract PeanutButter {
    Jelly jelly;
    constructor(address _jelly) {
       jelly = Jelly(_jelly); 

    } 

    function callJelly() public {
       jelly.log(); 

   }

}


contract Jelly {
   event Log(string message);

   function log() public{
   emit Log("Jelly function was called");
   
   }  

}