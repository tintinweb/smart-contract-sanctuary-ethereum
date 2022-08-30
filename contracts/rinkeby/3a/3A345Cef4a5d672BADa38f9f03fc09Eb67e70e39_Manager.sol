// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

contract Manager {
    address private _owner;
    string private _message;

    constructor(address owner) {
        _owner = owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call");
        _;
    }

    function setMessage(string memory message) external onlyOwner {
        _message = message;
        emit SetMessage(msg.sender, message);
    }

    function getMessage() external view returns (string memory) {
        return _message;
    }

    event SetMessage(address sender, string message);
}