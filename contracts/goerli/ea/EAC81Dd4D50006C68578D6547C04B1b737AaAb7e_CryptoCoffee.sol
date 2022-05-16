// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract CryptoCoffee {
    // Event to emit a Memo
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );

    // Memo structure
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    // Address of contract deployer
    address payable owner;

    // List of memos
    Memo[] Memos;

    // Constructor to assign owner
    constructor() {
        owner = payable(msg.sender);
    }

    /**
     * @dev Returns all the memos
     */
    function getMemos() public view returns (Memo[] memory) {
        return Memos;
    }

    /**
     * @dev Buy a coffee
     * @param _name Name of the buyer
     * @param _message Message from the buyer
     */
    function buyCoffee(string memory _name, string memory _message)
        public
        payable
    {
        // Minimum value sent should be greater than 0
        require(msg.value > 0, "Insufficient Amount!");

        // Adding memo to Memos
        Memos.push(Memo(msg.sender, block.timestamp, _name, _message));

        // Emitting the event
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    /**
     * @dev Modifier for only owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner.");
        _;
    }

    /**
     * @dev Withdraw contract balance
     */
    function withdrawBalance() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    /**
     * @dev Change the owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        owner = payable(newOwner);
    }
}