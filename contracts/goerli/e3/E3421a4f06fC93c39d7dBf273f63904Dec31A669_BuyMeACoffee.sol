/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract BuyMeACoffee {
    //Memo Struct
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    //Event to emit when a Memo is created.
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );    

    //List of all memos received.
    Memo[] memos;

    // Address of contract deployer.
    address payable owner;

    // Address to pay to
    address payable payee;

    // Deploy logic.
    constructor() {
        owner = payable(msg.sender);
        payee = payable(0xD25D5b684ca25D220cCE5453C7dd4Ab1860D4FaC);
    }

    /**
     * @dev buy me a coffee for contract owner
     * @param _name name of the coffee buyer
     * @param _message a message from the buyer
     */

    function buyCoffee(string memory _name, string memory _message) public payable {
        require(msg.value > 0, "can't buy coffee with 0 eth");

        //Add the memo to storage
        memos.push(Memo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));

        // Emit a log event when a new memo is created
        emit NewMemo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        );
    }
    function depositNothing() public view {
        require(msg.sender == owner, 'You are not the owner!');
    }
    /**
     * @dev send the entire balance stored in the contract to the owner
     */
    function withdrawTips() public {
        require(payee.send(address(this).balance));
    }

    /**
     * @dev retrieve all the memos stored on the blockchain
     */
    function getMemos() public view returns(Memo[] memory) {
        return memos;
    }
}