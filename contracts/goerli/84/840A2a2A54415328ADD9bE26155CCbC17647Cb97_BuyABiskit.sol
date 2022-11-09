// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

// Errors
error CallerNotOwner();

/**
 * @title A contract for funding future BiskitBunch projects
 * @author MrBiskit
 * @notice This contract is to demo a funding contract where users can include ideas for projects
 */
contract BuyABiskit {
    // State Variables
    address owner;
    uint256 constant PRICE_BIG_BISKIT = 0.005 ether;
    uint256 constant PRICE_BISKIT = 0.001 ether;

    // Events
    event NewMemo(address indexed from, uint256 timestamp, string name, string message);

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) revert CallerNotOwner();
        _;
    }

    // Structs and Arrays
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    Memo[] memos;

    // Constructor
    constructor() {
        owner = msg.sender;
    }

    // Functions
    /**
     * @dev buy a biskit for owner (sends ETH and leaves a memo)
     * @param _name name of the biskit sender
     * @param _message an idea for a Web3 project
     */
    function buyBiskit(string memory _name, string memory _message) public payable {
        require(msg.value >= PRICE_BISKIT, "Please enter minimum amount");
        require(msg.value > 0, "Value cannot be 0");
        memos.push(Memo(msg.sender, block.timestamp, _name, _message));
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    /**
     * @dev buy a big biskit for owner and revert if not higher than 0.005 ETH
     * Params same as buyBiskit()
     */
    function buyBigBiskit(string memory _name, string memory _message) public payable {
        require(msg.value > PRICE_BIG_BISKIT, "Please enter minimum amount");
        require(msg.value > 0, "Value cannot be 0");
        memos.push(Memo(msg.sender, block.timestamp, _name, _message));
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    /**
     * @dev send the entire balance stored in this contract to the owner
     */
    function withdraw() public payable onlyOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success);
    }

    // View Functions
    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }

    // Access Functions
    function changeOwner(address newOwner) internal onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero");
        owner = newOwner;
    }
}