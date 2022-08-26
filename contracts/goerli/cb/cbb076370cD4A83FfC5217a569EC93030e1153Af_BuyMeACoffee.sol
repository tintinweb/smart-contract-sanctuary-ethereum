/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


/** @title Buy Me a Coffee */
/** @author Seva Rybakov<[email protected]> */
contract BuyMeACoffee {
    /**
     * @dev Event triggered when memo is created
     */
    event NewMemoEvent(
        address indexed from,
        uint256 amount,
        uint256 timestamp,
        string name,
        string message
    );

    /**
     * @dev Struct representing the memo
     */
    struct Memo {
        address from;
        uint256 timestamp;
        uint256 amount;
        string name;
        string message;
    }

    /**
     * @dev List of all the memos left
     */
    Memo[] memos;

    /**
     * @dev Address of the contract owner
     */
    address payable owner;

    // Deploy logic
    constructor() {
        owner = payable(msg.sender);
    }

    /**
     * @dev Buys a coffee for the contract owner and leaves a memo
     * @param _name Name of the coffee buyer
     * @param _message Message left by the coffee buyer
     */
    function buyCoffee(string memory _name, string memory _message)
        public
        payable
    {
        require(msg.value > 0, "can't buy coffee with 0 ETH");
        memos.push(
            Memo(msg.sender, block.timestamp, msg.value, _name, _message)
        );
        emit NewMemoEvent(
            msg.sender,
            block.timestamp,
            msg.value,
            _name,
            _message
        );
    }

    /**
     * @dev send the whole contract balance to the contract owner
     */
    function withdrawTips() public {
        require(
            owner.send(address(this).balance),
            "error sending the money to the contract owner"
        );
    }

    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }
}