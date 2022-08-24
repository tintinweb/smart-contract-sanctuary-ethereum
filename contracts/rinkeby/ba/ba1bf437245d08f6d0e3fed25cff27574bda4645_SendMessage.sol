pragma solidity ^0.8.10;


contract SendMessage {
    address public victim;

    function trySend (string memory message) public {
        (bool sent, ) = address(this).call{value:0}(bytes(message));
        require(sent, "Failed to send message");
    }    
}