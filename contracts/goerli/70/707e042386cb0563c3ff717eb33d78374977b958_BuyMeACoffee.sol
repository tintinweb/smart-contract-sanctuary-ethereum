/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BuyMeACoffee {
    // Event to emit when a Memo is created
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    // Memo struct
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    // List of all memos received
    Memo[] memos;

    // Address of contract deployer
    address payable public  owner;

    // Deploy logic
    constructor() {
        owner = payable(msg.sender);
    }

    function transferOwnership(address payable _newOwner) public {
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /**
      * @dev buy a coffee for contract owner
      * @param _name name of the coffee buyer
      * @param _message message from the coffee buyer
     */
    function buyCoffee(string memory _name, string memory _message) public payable {
        require(msg.value > 0, "can't buy coffee for nothing");

        // Add the memo to storage
        memos.push(Memo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));

        // Emit a log event when memo is created
        emit NewMemo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        );
    }

    /**
      * @dev send the contract balance to owner
     */
    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }

    /**
      * @dev retrieve all memos received
     */
    function getMemos() public view returns(Memo[] memory) {
        return memos;
    }
}