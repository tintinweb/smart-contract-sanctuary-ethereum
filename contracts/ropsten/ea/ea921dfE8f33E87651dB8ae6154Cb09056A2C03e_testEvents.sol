pragma solidity ^0.8.13;

contract testEvents{
    event event1 (uint256 angka, address caller);
    event event2 (string huruf, address caller);

    function emitEvent1(uint256 _angka) public {
        emit event1(_angka, msg.sender);
    }
    function emitEvent2(string memory _huruf) public {
        emit event2(_huruf, msg.sender);
    }
}