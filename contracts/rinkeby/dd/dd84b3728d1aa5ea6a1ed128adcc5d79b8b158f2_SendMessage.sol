pragma solidity ^0.8.10;


contract SendMessage {
    address public victim;

    function trySend (address _to, string memory _message) public {
        (bool sent, ) = _to.call{value:0}(bytes(_message));
        require(sent, "Failed to send message");
    }    
}