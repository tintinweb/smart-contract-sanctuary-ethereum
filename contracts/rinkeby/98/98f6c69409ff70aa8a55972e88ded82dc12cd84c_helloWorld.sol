/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

contract helloWorld{
    string public message;

    constructor(string memory displayMessage){
        message = displayMessage;
    }
    function setMessage(string memory newMessage) public{
        message = newMessage;
    }
    function viewMessage() public view returns (string memory){
        return message;
    }
}