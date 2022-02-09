// contracts/Hello.sol
pragma solidity ^0.8.1;

contract Hello {
    string private message;

    // Emitted when the stored message changes
    event MessageChanged(string newMessage);

    // Stores a new message in the contract
    function store(string memory newMessage) public {
        message = newMessage;
        emit MessageChanged(newMessage);
    }

    // Reads the last stored message
    function retrieve() public view returns (string memory) {
        return message;
    }
}