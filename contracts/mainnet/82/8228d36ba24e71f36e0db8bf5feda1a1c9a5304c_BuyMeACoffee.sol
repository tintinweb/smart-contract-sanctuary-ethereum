//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";

// Switch this to your own contract address once deployed, for bookkeeping!
// Example Contract Address on Goerli: 0xDBa03676a2fBb6711CB652beF5B7416A53c1421D

contract BuyMeACoffee is Ownable, ReentrancyGuard {
    // Event to emit when a Tip is created.
    event NewTip(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );
    
    // Tip struct.
    struct Tip {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }
    
    // List of all tips received from coffee purchases.
    Tip[] tips;

    constructor() {}

    /**
     * @dev fetches all stored tips
     */
    function getTips() public view returns (Tip[] memory) {
        return tips;
    }

    /**
     * @dev buy a coffee for owner (sends an ETH tip and leaves a memo)
     * @param _name name of the coffee purchaser
     * @param _message a nice message from the purchaser
     */
    function buyCoffee(string memory _name, string memory _message) public payable {
        // Must accept more than 0 ETH for a coffee.
        require(msg.value > 0, "can't buy coffee for free!");

        // Add the tip to storage!
        tips.push(Tip(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));

        // Emit a NewTip event with details about the tip.
        emit NewTip(
            msg.sender,
            block.timestamp,
            _name,
            _message
        );
    }

    /**
     * @dev send the entire balance stored in this contract to the owner
     */
    function withdrawTips() external nonReentrant onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transaction failed");
    }
}