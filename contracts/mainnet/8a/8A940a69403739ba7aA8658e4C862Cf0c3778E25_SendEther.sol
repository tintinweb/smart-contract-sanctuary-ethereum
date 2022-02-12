pragma solidity ^0.8.0;
pragma abicoder v2;

contract SendEther {
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function sendToAddresses(address payable[] memory addresses, uint256 amount) public payable {
        require(msg.sender == admin, "only admin");

        for (uint256 i = 0; i < addresses.length; i++) {
            (bool sent, bytes memory data) = addresses[i].call{value: amount}("");
            require(sent, "Failed to send Ether");
        }
    }
}