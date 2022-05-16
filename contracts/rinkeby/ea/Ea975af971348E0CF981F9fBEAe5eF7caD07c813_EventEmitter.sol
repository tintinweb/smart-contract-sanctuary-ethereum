pragma solidity >= 0.7;

contract EventEmitter {
    event Message(string Topic, uint256 hash, address sender);

    function emitEvent(string calldata _topic, uint256  _hash) public {
        emit Message(_topic, _hash, msg.sender);
    }
    
}