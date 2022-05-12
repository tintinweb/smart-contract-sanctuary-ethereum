// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Barista {
    error Barista__NotEnough();
    error Barista__WithdrawFailed();

    address payable public immutable owner;
    uint256 public total;

    event NewCoffee(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );

    struct Coffee {
        address from; 
        uint256 timestamp;
        string name;
        string message;
    }

    Coffee[] internal coffees;

    constructor() {
        owner = payable(msg.sender);
    }

    function getAll() public view returns (Coffee[] memory) {
        return coffees;
    }

    /// @dev Returns list of coffees purchased.
    function getTotalCoffee() public view returns (uint256) {
        return coffees.length;
    }

    /// @dev Buy coffee for contract owner
    /// @param name Name of sender
    /// @param message Message included in purchase
    function buy(
        string memory name,
        string memory message
    ) public payable {
        if (0.001 ether > msg.value) revert Barista__NotEnough();
        coffees.push(Coffee(msg.sender, block.timestamp, name, message));
        emit NewCoffee(msg.sender, block.timestamp, name, message);
    }

    /// @dev Sends balance of contract to owner.
    function withdraw() public {
        if (!owner.send(address(this).balance))
             revert Barista__WithdrawFailed();
    }

    receive() external payable {}
}