//SPDX License Identifier:MIT
pragma solidity 0.8.17;

contract Message {
    string public callMessage;
    constructor() {
        printMessage();
    }
    function printMessage() public returns(string memory) {
        return callMessage = "Hi contract is integerated";
    }
}