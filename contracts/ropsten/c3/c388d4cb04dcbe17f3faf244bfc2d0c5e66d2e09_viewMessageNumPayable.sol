pragma solidity ^0.4.18;

contract viewMessageNumPayable{
    string message;
    string message2;
    address public owner;
    uint amount;
    uint specialNumber;

    constructor() public {
        message = "This is the initial Message";
        message2 = "This is the second Initial message";
        owner = msg.sender;
        specialNumber = 100;
        amount = 0;
    }
    
    
    function setNewMessage(string newMsg) public payable
    {
        
        //msg.value is a special variable that holds the number of wei sent with the transaction (gas is counted separately)
        message = newMsg;
        amount += msg.value;
        
        
    }
    
    function setNewMessageNumber(string m, uint num) public payable {
        message = m;
        specialNumber = num;
        amount += msg.value;
    }
    
    function setNewMessage2(string meg) public payable {
        message2 = meg;
        amount += msg.value;
    }
    
    function getMessage() constant public returns (string)
    {
        return message;
    }
    
    
}