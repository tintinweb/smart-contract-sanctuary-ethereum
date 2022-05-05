/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld{
    address private _owner = 0x22A5AAE0a1Bd6860Ce68de397307C666ab0dDC06;
    event Greeting(address sender, string name);
    
    constructor(){
        emit Greeting(_owner, "The owner decided the world should be greeted");
    }

    function GreetWorld(string memory name) public {
        string memory greeting;
        if(msg.sender == _owner){
            greeting = "The owner greets all of the world";
        }
        else{
            greeting = string(abi.encodePacked(name, " greets the world"));
        }
        emit Greeting(msg.sender, greeting);
    }

}