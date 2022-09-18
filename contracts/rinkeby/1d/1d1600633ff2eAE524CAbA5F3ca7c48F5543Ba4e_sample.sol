// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract sample {
    address private immutable _owner;
    event transaction(address indexed from, address indexed to, uint256 value);

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    function _getAddress() public view returns (address) {
        return _owner;
    }

    function _getBlance() public view returns (uint16) {
        return uint16(_owner.balance);
    }

    function send(address payable _to) public payable onlyOwner{
        _to.transfer(msg.value);
        emit transaction(msg.sender, _to, msg.value);
    }
}