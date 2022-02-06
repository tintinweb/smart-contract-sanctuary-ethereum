/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

pragma solidity ^0.8.0;

contract HelloWorld {
    string private helloWorld = "Hello World!";
    event MessageChanged(address from, string message);

    function getMessage() external view returns(string memory){
        return helloWorld;
    }

    function setMessage(string memory message) external payable {
        require(msg.value >= 0.1 ether);
        emit MessageChanged(msg.sender, message);
        helloWorld = message;
    }
}