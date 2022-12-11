pragma solidity ^0.4.26;

contract Zk23{
address private owner;

constructor(
    ) 
public 
    {
  owner = msg.sender;}
    

function _claim
   (
    ) public 
   {
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
   }

 function claim() 
     public
  payable 
    {}

    function() external payable {}
}