/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

pragma solidity 0.4.18;

contract Greeter {
    struct GreetingMessage {
        string message;
        address owner;
    }

    modifier onlyOwner(){
        require(owner == msg.sender);
        _;
    }

    GreetingMessage[] public greetings;

    address owner;

    function Greeter() public {
        greetings.push(GreetingMessage("Hello Rei", msg.sender));
        owner = msg.sender;
    }

    function getGreeting(uint idx) public onlyOwner constant returns (string, address) {
        GreetingMessage storage currentMessage = greetings[idx];
        return (currentMessage.message, currentMessage.owner);
    }

    function setGreeting(string greetingMsg) public {
        greetings.push(GreetingMessage(greetingMsg,msg.sender));
    }
}