pragma solidity >=0.7.0 <0.9.0;

contract a{
    uint a = 1;
    uint b = 2;
    function add() public view returns(uint){
        uint c = a+b;
        return(c);
    }
}
contract Voter is a{
    
    uint counter;
    address msgsender;
    
    constructor() 
    {
        msgsender = msg.sender;
        counter = 0;
    }

    function check_a() public view returns(uint){
        return(a);
    }
    
    function vote() public
    {
    require(msgsender != msg.sender,"You have already voted!");    
     msgsender = msg.sender;
     counter ++;
        
    }
    
    function getcounter() public view returns(uint) 
    {
     return counter;  
        
    }
    
    function getmsgsender() public view returns(address) 
    {
     return msgsender;  
        
    }
    
    
}