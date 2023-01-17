/**
 *Submitted for verification at Etherscan.io on 2023-01-16
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

    // Memo Struct
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    // List of memos received from friends
    Memo[] memos;

    // Address of contract deployer
    address payable owner;

    // Deploy logic
    constructor() {
        owner = payable(msg.sender);
    }

    /**
    |* @dev buy a coffee for contract owner
    |* @param _name name of the coffee buyer
    |* @param _message a nice message from the coffee buyer
    |*/
    function buyCoffee(string memory _name, string memory _message) public payable {
        require(msg.value > 0, "can't buy a coffee with 0 eth");

        memos.push(Memo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));

        // Emit a log event when a new memo is created!
        emit NewMemo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        );
    }

    /**
    |* @dev send the entire balance stored in this contract to the owner
    |*/
    function withdrawTips() public {
        address(this).balance;
        require(owner.send(address(this).balance));
    }

    /**
    |* @dev retrieve all the memos received and stored on the blockchain
    |*/
    function getMemos() public view returns(Memo[] memory) {
        return memos;
    }

}