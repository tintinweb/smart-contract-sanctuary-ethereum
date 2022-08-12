/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// BuyMeACoffee deployed to  0x8774Db42152516E7910858207693590cd9E6d23F on Goerli

contract BuyMeACoffee {
    // Event to emit when a memo is created
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );

    // Memo struct
    struct Memo{
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    // List of all memos received from friends
    Memo[] memos;
    
    // Address of contract deployer
    address payable owner;
    address payable public receiver;

    // Deploy logic
    constructor(){
        owner = payable(msg.sender);
        receiver = payable(msg.sender);
    }

    /**
    * @dev by a coffee for contract owner
    * @param _name name of the coffee buyer
    * @param _message a nice message from the coffe buyer
     */
    function buyCoffee(string memory _name, string memory _message) payable public{
        require(msg.value > 0, "can't buy coffee with 0 eth");

        // Add the memo to storage:
        memos.push(Memo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));

        // Emit a log event when a new memo is created:
        emit NewMemo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        );
    }

    /**
    * @dev send the entire balance stored in this contract to the owner
     */
    function withdrawTips() public {
        require(receiver.send(address(this).balance));
    }

    /**
    * @dev retrieve all the memos stored on the contract
     */
    function getMemos() public view returns(Memo[] memory){
        return memos;
    }

    /**
    * @dev change the contract address of the tip receiver
    * @param _toAddress address of the person that will be receiving tips
     */
    function changeReceiver(address _toAddress) public {
        require(owner == msg.sender);
        receiver = payable(_toAddress);
    }
}